<#
    .SYNOPSIS
        This function installs OpenSSH-Win64 binaries and creates the ssh-agent service.

        The code for this function is, in large part, carved out of the 'install-sshd.ps1' script bundled with
        an OpenSSH-Win64 install.

        Original authors (github accounts):
            @manojampalam
            @friism
            @manojampalam
            @bingbing8

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER UseChocolateyCmdLine
        This parameter is OPTIONAL.

        This parameter is a switch. If used, OpenSSH binaries will be installed via the Chocolatey CmdLine.
        If the Chocolatey CmdLine is not already installed, it will be installed.

    .PARAMETER UsePowerShellGet
        This parameter is OPTIONAL.

        This parameter is a switch. If used, OpenSSH binaries will be installed via PowerShellGet/PackageManagement
        Modules.

    .PARAMETER GitHubInstall
        This parameter is OPTIONAL.

        This parameter is a switch. If used, OpenSSH binaries will be installed by downloading the .zip
        from https://github.com/PowerShell/Win32-OpenSSH/releases/latest/, expanding the archive, moving
        the files to the approproiate location(s), and setting permissions appropriately.

    .PARAMETER UpdatePackageManagement
        This parameter is OPTIONAL.

        This parameter is a switch. If used, PowerShellGet/PackageManagement Modules will be updated to their
        latest version before installation of OpenSSH binaries.

        WARNING: Using this parameter could break certain PowerShellGet/PackageManagement cmdlets. Recommend
        using the dedicated function "Update-PackageManagemet" and starting a fresh PowerShell session after
        it finishes.

    .PARAMETER SkipWinCapabilityAttempt
        This parameter is OPTIONAL.

        This parameter is a switch.
        
        In more recent versions of Windows (Spring 2018), OpenSSH Client and SSHD Server can be installed as
        Windows Features using the Dism Module 'Add-WindowsCapability' cmdlet. If you run this function on
        a more recent version of Windows, it will attempt to use 'Add-WindowsCapability' UNLESS you use
        this switch.

        As of May 2018, there are reliability issues with the 'Add-WindowsCapability' cmdlet.
        Using this switch is highly recommend in order to avoid using 'Add-WindowsCapability'.

    .PARAMETER Force
        This parameter is a OPTIONAL.

        This parameter is a switch.

        If you are already running the latest version of OpenSSH, but would like to reinstall it and the
        associated ssh-agent service, use this switch.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Install-SSHAgentService

#>
function Install-SSHAgentService {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [switch]$UseChocolateyCmdLine,

        [Parameter(Mandatory=$False)]
        [switch]$GitHubInstall,

        [Parameter(Mandatory=$False)]
        [switch]$SkipWinCapabilityAttempt,

        [Parameter(Mandatory=$False)]
        [switch]$Force
    )
    ##### BEGIN Variable/Parameter Transforms and PreRun Prep #####

    if (!$(GetElevation)) {
        Write-Error "You must run PowerShell as Administrator before using this function! Halting!"
        $global:FunctionResult = "1"
        return
    }

    $OpenSSHWinPath = "$env:ProgramFiles\OpenSSH-Win64"
    $tempfile = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName())

    # NOTE: In this context, 'installing' OpenSSH simply means getting ssh.exe and all related files into $OpenSSHWinPath

    #region >> Install OpenSSH Via Windows Capability
    
    if ([Environment]::OSVersion.Version -ge [version]"10.0.17063" -and !$SkipWinCapabilityAttempt) {
        # Import the Dism Module
        if ($(Get-Module).Name -notcontains "Dism") {
            try {
                Import-Module Dism
            }
            catch {
                # Using full path to Dism Module Manifest because sometimes there are issues with just 'Import-Module Dism'
                $DismModuleManifestPaths = $(Get-Module -ListAvailable -Name Dism).Path

                foreach ($MMPath in $DismModuleManifestPaths) {
                    try {
                        Import-Module $MMPath -ErrorAction Stop
                        break
                    }
                    catch {
                        Write-Verbose "Unable to import $MMPath..."
                    }
                }
            }
        }
        if ($(Get-Module).Name -notcontains "Dism") {
            Write-Error "Problem importing the Dism PowerShell Module! Unable to proceed with Hyper-V install! Halting!"
            $global:FunctionResult = "1"
            return
        }

        $OpenSSHClientFeature = Get-WindowsCapability -Online | Where-Object {$_.Name -match 'OpenSSH\.Client'}

        if (!$OpenSSHClientFeature) {
            Write-Warning "Unable to find the OpenSSH.Client feature using the Get-WindowsCapability cmdlet!"
            $AddWindowsCapabilityFailure = $True
        }
        else {
            try {
                $SSHClientFeatureInstall = Add-WindowsCapability -Online -Name $OpenSSHClientFeature.Name -ErrorAction Stop
            }
            catch {
                Write-Warning "The Add-WindowsCapability cmdlet failed to add the $($OpenSSHClientFeature.Name)!"
                $AddWindowsCapabilityFailure = $True
            }
        }

        # Make sure the ssh-agent service exists
        try {
            $SSHDServiceCheck = Get-Service sshd -ErrorAction Stop
        }
        catch {
            $AddWindowsCapabilityFailure = $True
        }
    }

    #endregion >> Install OpenSSH Via Windows Capability


    #region >> Install OpenSSH via Traditional Methods

    if ([Environment]::OSVersion.Version -lt [version]"10.0.17063" -or $AddWindowsCapabilityFailure -or $SkipWinCapabilityAttempt -or $Force) {
        #region >> Get OpenSSH-Win64 Files
        
        if (!$GitHubInstall) {
            $InstallProgramSplatParams = @{
                ProgramName                 = "openssh"
                CommandName                 = "ssh.exe"
                ExpectedInstallLocation     = $OpenSSHWinPath
                ErrorAction                 = "SilentlyContinue"
                ErrorVariable               = "IPErr"
                WarningAction               = "SilentlyContinue"
            }

            try {
                $OpenSSHInstallResults = Install-Program @InstallProgramSplatParams
                if (!$OpenSSHInstallResults) {throw "There was a problem with the Install-Program function! Halting!"}
            }
            catch {
                Write-Error $_
                Write-Host "Errors for the Install-Program function are as follows:"
                Write-Error $($IPErr | Out-String)
                $global:FunctionResult = "1"
                return
            }
        }
        else {
            try {
                Write-Host "Finding latest version of OpenSSH for Windows..."
                $url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
                $request = [System.Net.WebRequest]::Create($url)
                $request.AllowAutoRedirect = $false
                $response = $request.GetResponse()
    
                $LatestOpenSSHWin = $($response.GetResponseHeader("Location") -split '/v')[-1]
            }
            catch {
                Write-Error "Unable to determine the latest version of OpenSSH using the Find-Package cmdlet! Try the Install-WinSSH function again using the -UsePowerShellGet switch. Halting!"
                $global:FunctionResult = "1"
                return
            }
    
            try {
                $SSHExePath = $(Get-ChildItem -Path $OpenSSHWinPath -File -Recurse -Filter "ssh.exe").FullName
            
                if (Test-Path $SSHExePath) {
                    $InstalledOpenSSHVer = [version]$(Get-Item $SSHExePath).VersionInfo.FileVersion
                }
    
                $NeedNewerVersion = $InstalledOpenSSHVer -lt [version]$($LatestOpenSSHWin -split "[a-zA-z]")[0]
                
                if ($Force) {
                    $NeedNewerVersion = $True
                }
            }
            catch {
                $NotInstalled = $True
            }
    
            $WinSSHFileNameSansExt = "OpenSSH-Win64"
            if ($NeedNewerVersion -or $NotInstalled) {
                try {
                    $WinOpenSSHDLLink = $([String]$response.GetResponseHeader("Location")).Replace('tag','download') + "/$WinSSHFileNameSansExt.zip"
                    Write-Host "Downloading OpenSSH-Win64 from $WinOpenSSHDLLink..."
                    Invoke-WebRequest -Uri $WinOpenSSHDLLink -OutFile "$HOME\Downloads\$WinSSHFileNameSansExt.zip"
                    # NOTE: OpenSSH-Win64.zip contains a folder OpenSSH-Win64, so no need to create one before extraction
                    $null = UnzipFile -PathToZip "$HOME\Downloads\$WinSSHFileNameSansExt.zip" -TargetDir "$HOME\Downloads"
                    if (Test-Path $OpenSSHWinPath) {
                        $SSHAgentService = Get-Service ssh-agent -ErrorAction SilentlyContinue
                        if ($SSHAgentService) {$SSHAgentService | Stop-Service -ErrorAction SilentlyContinue}
                        $SSHDService = Get-Service sshd -ErrorAction SilentlyContinue
                        if ($SSHDService) {Stop-Service -ErrorAction SilentlyContinue}
                        $SSHKeyGenProcess = Get-Process -name ssh-keygen -ErrorAction SilentlyContinue
                        if ($SSHKeyGenProcess) {$SSHKeyGenProcess | Stop-Process -ErrorAction SilentlyContinue}

                        Remove-Item $OpenSSHWinPath -Recurse -Force
                    }
                    Move-Item "$HOME\Downloads\$WinSSHFileNameSansExt" $OpenSSHWinPath
                    Enable-NTFSAccessInheritance -Path $OpenSSHWinPath -RemoveExplicitAccessRules
                }
                catch {
                    Write-Error $_
                    Write-Error "Installation of OpenSSH failed! Halting!"
                    $global:FunctionResult = "1"
                    return
                }
            }
            else {
                Write-Error "It appears that the newest version of $WinSSHFileNameSansExt is already installed! Halting!"
                $global:FunctionResult = "1"
                return
            }
        }

        #endregion >> Get OpenSSH-Win64 Files

        # Make sure $OpenSSHWinPath is part of $env:Path
        [System.Collections.Arraylist][array]$CurrentEnvPathArray = $env:Path -split ";" | Where-Object {![System.String]::IsNullOrWhiteSpace($_)}
        if ($CurrentEnvPathArray -notcontains $OpenSSHWinPath) {
            $CurrentEnvPathArray.Insert(0,$OpenSSHWinPath)
            $env:Path = $CurrentEnvPathArray -join ";"
        }

        # Now ssh.exe and related should be available, but the ssh-agent service has not been installed yet

        if (!$(Test-Path $OpenSSHWinPath)) {
            Write-Error "The path $OpenSSHWinPath does not exist! Halting!"
            $global:FunctionResult = "1"
            return
        }

        # If the ssh-agent service exists from a previous OpenSSH install, make sure it is Stopped
        # Also, ssh-keygen might be running too, so make sure that process is stopped. 
        $SSHAgentService = Get-Service ssh-agent -ErrorAction SilentlyContinue
        if ($SSHAgentService) {$SSHAgentService | Stop-Service -ErrorAction SilentlyContinue}
        $SSHKeyGenProcess = Get-Process -name ssh-keygen -ErrorAction SilentlyContinue
        if ($SSHKeyGenProcess) {$SSHKeyGenProcess | Stop-Process -ErrorAction SilentlyContinue}

        #$sshdpath = Join-Path $OpenSSHWinPath "sshd.exe"
        $sshagentpath = Join-Path $OpenSSHWinPath "ssh-agent.exe"
        $etwman = Join-Path $OpenSSHWinPath "openssh-events.man"
        $sshdir = "$env:ProgramData\ssh"
        $logsdir = Join-Path $sshdir "logs"

        #region >> Setup openssh Windows Event Log

        # unregister etw provider
        wevtutil um `"$etwman`"

        # adjust provider resource path in instrumentation manifest
        [XML]$xml = Get-Content $etwman
        $xml.instrumentationManifest.instrumentation.events.provider.resourceFileName = $sshagentpath.ToString()
        $xml.instrumentationManifest.instrumentation.events.provider.messageFileName = $sshagentpath.ToString()

        $streamWriter = $null
        $xmlWriter = $null
        try {
            $streamWriter = new-object System.IO.StreamWriter($etwman)
            $xmlWriter = [System.Xml.XmlWriter]::Create($streamWriter)    
            $xml.Save($xmlWriter)
        }
        finally {
            if($streamWriter) {
                $streamWriter.Close()
            }
        }

        #register etw provider
        $null = wevtutil im `"$etwman`" *>$tempfile

        #endregion >> Setup openssh Windows Event Log

        #region >> Create teh ssh-agent service

        try {
            if ([bool]$(Get-Service ssh-agent -ErrorAction SilentlyContinue)) {
                Write-Host "Recreating ssh-agent service..."
                Stop-Service ssh-agent
                $null = sc.exe delete ssh-agent
            }
            else {
                Write-Host "Creating ssh-agent service..."
            }

            $agentDesc = "Agent to hold private keys used for public key authentication."
            $null = New-Service -Name ssh-agent -DisplayName "OpenSSH Authentication Agent" -BinaryPathName $sshagentpath -Description $agentDesc -StartupType Automatic
            $null = sc.exe sdset ssh-agent "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;RP;;;AU)"
            $null = sc.exe privs ssh-agent SeImpersonatePrivilege
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }

        # IMPORTANT NOTE: Starting the sshd service is what creates the directory C:\ProgramData\ssh and
        # all of its contents
        <#
        try {
            # Create the C:\ProgramData\ssh folder and set its permissions
            if (-not (Test-Path $sshdir -PathType Container)) {
                $null = New-Item $sshdir -ItemType Directory -Force -ErrorAction Stop
            }
            # Set Permissions
            $SecurityDescriptor = Get-NTFSSecurityDescriptor -Path $sshdir
            $SecurityDescriptor | Disable-NTFSAccessInheritance -RemoveInheritedAccessRules
            $SecurityDescriptor | Clear-NTFSAccess
            $SecurityDescriptor | Add-NTFSAccess -Account "NT AUTHORITY\Authenticated Users" -AccessRights "ReadAndExecute, Synchronize" -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Add-NTFSAccess -Account SYSTEM -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Add-NTFSAccess -Account Administrators -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Set-NTFSSecurityDescriptor
            Set-NTFSOwner -Path $sshdir -Account Administrators
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }

        try {
            # Create logs folder and set its permissions
            if (-not (Test-Path $logsdir -PathType Container)) {
                $null = New-Item $logsdir -ItemType Directory -Force -ErrorAction Stop
            }
            # Set Permissions
            $SecurityDescriptor = Get-NTFSSecurityDescriptor -Path $logsdir
            $SecurityDescriptor | Disable-NTFSAccessInheritance -RemoveInheritedAccessRules
            $SecurityDescriptor | Clear-NTFSAccess
            #$SecurityDescriptor | Add-NTFSAccess -Account "NT AUTHORITY\Authenticated Users" -AccessRights "ReadAndExecute, Synchronize" -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Add-NTFSAccess -Account SYSTEM -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Add-NTFSAccess -Account Administrators -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles
            $SecurityDescriptor | Set-NTFSSecurityDescriptor
            Set-NTFSOwner -Path $logsdir -Account Administrators
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
        #>
    }

    Start-Service ssh-agent -Passthru
    Start-Sleep -Seconds 5

    if ($(Get-Service ssh-agent).Status -ne "Running") {
        Write-Error "The ssh-agent service did not start succesfully! Halting!"
        $global:FunctionResult = "1"
        return
    }
    else {
        Write-Host "The ssh-agent service was successfully installed and started!" -ForegroundColor Green
    }

    if (Test-Path $tempfile) {
        Remove-Item $tempfile -Force -ErrorAction SilentlyContinue
    }
}

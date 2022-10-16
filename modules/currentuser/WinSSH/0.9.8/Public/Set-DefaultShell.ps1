<#
    .SYNOPSIS
        This function modifies sshd_config on the local host and sets the default shell
        that Remote Users will use when they ssh to the local host.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER DefaultShell
        This parameter is MANDATORY.

        This parameter takes a string that must be one of two values: "powershell","pwsh"

        If set to "powershell", when a Remote User connects to the local host via ssh, they will enter a
        Windows PowerShell 5.1 shell.

        If set to "pwsh", when a Remote User connects to the local host via ssh, the will enter a
        PowerShell Core 6 shell.

    .PARAMETER SubsystemSymlinksDirectory
        This parameter is OPTIONAL.

        This parameter takes a string that represents the path to a directory that will contain symlinked directories
        to the directories containing powershell.exe and/or pwsh.exe

    .PARAMETER UseForceCommand
        This parameter is OPTIONAL.

        This parameter is a switch. If used, the 'ForceCommand' option will be added to sshd_config.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Set-DefaultShell -DefaultShell powershell
        
#>
function Set-DefaultShell {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("powershell","pwsh")]
        [string]$DefaultShell,

        [Parameter(Mandatory=$False)]
        [string]$SubsystemSymlinksDirectory = "C:\sshSymlinks",

        [Parameter(Mandatory=$False)]
        [switch]$UseForceCommand
    )

    if (Test-Path "$env:ProgramData\ssh\sshd_config") {
        $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
    }
    elseif (Test-Path "$env:ProgramFiles\OpenSSH-Win64\sshd_config") {
        $sshdConfigPath = "$env:ProgramFiles\OpenSSH-Win64\sshd_config"
    }
    else {
        Write-Error "Unable to find file 'sshd_config'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    # Setup the Subsystem Symlinks directory
    if ($SubsystemSymlinksDirectory -match "[\s]") {
        Write-Error "The -SubsystemSymlinksDirectory path must not contain any spaces! Halting!"
        $global:FunctionResult = "1"
        return
    }
    if (Test-Path $SubsystemSymlinksDirectory) {
        try {
            Remove-Item $SubsystemSymlinksDirectory -Recurse -Force
        }
        catch {
            try {
                Get-ChildItem -Path $SubsystemSymlinksDirectory -Recurse | foreach {$_.Delete()}
                Remove-Item $SubsystemSymlinksDirectory -Recurse -Force
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
    }
    $null = New-Item -ItemType Directory -Path $SubsystemSymlinksDirectory -Force
    $PowerShellSymlinkRoot = "$SubsystemSymlinksDirectory\powershellRoot"
    $PwshSymlinkRoot = "$SubsystemSymlinksDirectory\pwshRoot"
    #$null = New-Item -ItemType Directory -Path $PowerShellSymlinkRoot -Force
    #$null = New-Item -ItemType Directory -Path $PwshSymlinkRoot -Force


    if ($DefaultShell -eq "powershell") {
        $WindowsPowerShellPath = $(Get-Command powershell).Source
        #$WindowsPowerShellPathWithForwardSlashes = $WindowsPowerShellPath -replace "\\","/"

        # Create the powershell.exe parent directory symlink
        $null = New-Item -ItemType SymbolicLink -Path $PowerShellSymlinkRoot -Target $($(Get-Command powershell).Source | Split-Path -Parent)

        $ForceCommandOptionLine = "ForceCommand powershell.exe -NoProfile"
    }
    if ($DefaultShell -eq "pwsh") {
        # Search for pwsh.exe where we expect it to be
        [array]$PotentialPwshExes = @(Get-ChildItem "$env:ProgramFiles\Powershell" -Recurse -File -Filter "*pwsh.exe")
        if (![bool]$(Get-Command pwsh -ErrorAction SilentlyContinue)) {
            try {
                $InstallPwshSplatParams = @{
                    ProgramName                 = "powershell-core"
                    CommandName                 = "pwsh.exe"
                    ExpectedInstallLocation     = "C:\Program Files\PowerShell"
                    ErrorAction                 = "SilentlyContinue"
                    ErrorVariable               = "InstallPwshErrors"
                }
                $InstallPwshResult = Install-Program @InstallPwshSplatParams

                if (![bool]$(Get-Command pwsh -ErrorAction SilentlyContinue)) {throw}
            }
            catch {
                Write-Error $($InstallPwshErrors | Out-String)
                $global:FunctionResult = "1"
                return
            }

            [array]$PotentialPwshExes = @(Get-ChildItem "$env:ProgramFiles\Powershell" -Recurse -File -Filter "*pwsh.exe")
        }
        if (![bool]$(Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Error "Unable to find pwsh.exe! Please check your `$env:Path! Halting!"
            $global:FunctionResult = "1"
            return
        }

        $LatestLocallyAvailablePwsh = [array]$($PotentialPwshExes.VersionInfo | Sort-Object -Property ProductVersion)[-1].FileName
        $LatestPwshParentDir = [System.IO.Path]::GetDirectoryName($LatestLocallyAvailablePwsh)
        #$PowerShellCorePathWithForwardSlashes = $LatestLocallyAvailablePwsh -replace "\\","/"
        #$PowerShellCorePathWithForwardSlashes = $PowerShellCorePathWithForwardSlashes -replace [regex]::Escape("C:/Program Files"),'%PROGRAMFILES%'

        # Create the pwsh.exe parent directory symlink
        $null = New-Item -ItemType SymbolicLink -Path $PwshSymlinkRoot -Target $LatestPwshParentDir

        # Update $env:Path to include pwsh
        if ($($env:Path -split ";") -notcontains $LatestPwshParentDir) {
            # TODO: Clean out older pwsh $env:Path entries if they exist...
            $env:Path = "$LatestPwshParentDir;$env:Path"
        }
        
        # Update SYSTEM Path to include pwsh
        $CurrentSystemPath = $(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
        $CurrentSystemPathArray = $CurrentSystemPath -split ";"
        if ($CurrentSystemPathArray -notcontains $LatestPwshParentDir) {
            $UpdatedSystemPath = "$LatestPwshParentDir;$CurrentSystemPath"
            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH -Value $UpdatedSystemPath
        }

        $ForceCommandOptionLine = "ForceCommand pwsh.exe -NoProfile"
    }

    if (!$UseForceCommand) {
        # Set DefaultShell in Registry
        $OpenSSHRegistryPath = "HKLM:\SOFTWARE\OpenSSH"
        if ($(Get-Item -Path $OpenSSHRegistryPath).Property -contains "DefaultShell") {
            Remove-ItemProperty -Path $OpenSSHRegistryPath -Name DefaultShell -Force
        }
        if ($DefaultShell -eq "pwsh") {
            New-ItemProperty -Path $OpenSSHRegistryPath -Name DefaultShell -Value "$PwshSymlinkRoot\pwsh.exe" -PropertyType String -Force
        }
        else {
            New-ItemProperty -Path $OpenSSHRegistryPath -Name DefaultShell -Value "$PowerShellSymlinkRoot\powershell.exe" -PropertyType String -Force
        }
    }

    # Subsystem instructions: https://github.com/PowerShell/PowerShell/tree/master/demos/SSHRemoting#setup-on-windows-machine
    [System.Collections.ArrayList]$sshdContent = Get-Content $sshdConfigPath
    $PowerShellSymlinkRootRegex = [regex]::Escape($PowerShellSymlinkRoot)
    $PwshSymlinkRootRegex = [regex]::Escape($PwshSymlinkRoot)
    
    if (![bool]$($sshdContent -match "Subsystem[\s]+powershell")) {
        $InsertAfterThisLine = $sshdContent -match "sftp"
        $InsertOnThisLine = $sshdContent.IndexOf($InsertAfterThisLine)+1
        if ($DefaultShell -eq "pwsh") {
            $sshdContent.Insert($InsertOnThisLine, "Subsystem powershell $PwshSymlinkRoot\pwsh.exe -sshs -NoLogo -NoProfile")
        }
        else {
            $sshdContent.Insert($InsertOnThisLine, "Subsystem powershell $PowerShellSymlinkRoot\powershell.exe -sshs -NoLogo -NoProfile")
        }
    }
    elseif (![bool]$($sshdContent -match "Subsystem[\s]+powershell[\s]+$PowerShellSymlinkRootRegex") -and $DefaultShell -eq "powershell") {
        $LineToReplace = $sshdContent -match "Subsystem[\s]+powershell"
        $sshdContent = $sshdContent -replace [regex]::Escape($LineToReplace),"Subsystem powershell $PowerShellSymlinkRoot\powershell.exe -sshs -NoLogo -NoProfile"
    }
    elseif (![bool]$($sshdContent -match "Subsystem[\s]+powershell[\s]+$PwshSymlinkRootRegex") -and $DefaultShell -eq "pwsh") {
        $LineToReplace = $sshdContent -match "Subsystem[\s]+powershell"
        $sshdContent = $sshdContent -replace [regex]::Escape($LineToReplace),"Subsystem powershell $PwshSymlinkRoot\pwsh.exe -sshs -NoLogo -NoProfile"
    }

    Set-Content -Value $sshdContent -Path $sshdConfigPath

    # Determine if sshd_config already has the 'ForceCommand' option active
    $ExistingForceCommandOption = $sshdContent -match "ForceCommand" | Where-Object {$_ -notmatch "#"}

    # Determine if sshd_config already has 'Match User' option active
    $ExistingMatchUserOption = $sshdContent -match "Match User" | Where-Object {$_ -notmatch "#"}
    
    if (!$ExistingForceCommandOption) {
        if ($UseForceCommand) {
            # If sshd_config already has the 'Match User' option available, don't touch it, else add it with ForceCommand
            try {
                if (!$ExistingMatchUserOption) {
                    Add-Content -Value "Match User *`n$ForceCommandOptionLine" -Path $sshdConfigPath
                }
                else {
                    Add-Content -Value "$ForceCommandOptionLine" -Path $sshdConfigPath
                }

                try {
                    Restart-Service sshd -ErrorAction Stop
                    Write-Host "Successfully changed sshd default shell to '$DefaultShell'" -ForegroundColor Green
                }
                catch {
                    Write-Error $_
                    $global:FunctionResult = "1"
                    return
                }
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
        elseif (!$ExistingMatchUserOption) {
            Add-Content -Value "Match User *" -Path $sshdConfigPath

            try {
                Restart-Service sshd -ErrorAction Stop
                Write-Host "Successfully changed sshd default shell to '$DefaultShell'" -ForegroundColor Green
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
    }
    else {
        if ($UseForceCommand) {
            if ($ExistingForceCommandOption -ne $ForceCommandOptionLine) {
                if (!$ExistingMatchUserOption) {
                    $UpdatedSSHDConfig = $sshdContent -replace [regex]::Escape($ExistingForceCommandOption),"Match User *`n$ForceCommandOptionLine"
                }
                else {
                    $UpdatedSSHDConfig = $sshdContent -replace [regex]::Escape($ExistingForceCommandOption),"$ForceCommandOptionLine"
                }

                try {
                    Set-Content -Value $UpdatedSSHDConfig -Path $sshdConfigPath
                    Restart-Service sshd -ErrorAction Stop
                    Write-Host "Successfully changed sshd default shell to '$DefaultShell'" -ForegroundColor Green
                }
                catch {
                    Write-Error $_
                    $global:FunctionResult = "1"
                    return
                }
            }
            else {
                Write-Warning "The specified 'ForceCommand' option is already active in the the sshd_config file. No changes made."
            }
        }
        elseif (!$ExistingMatchUserOption) {
            $UpdatedSSHDConfig = $sshdContent -replace [regex]::Escape($ExistingForceCommandOption),"Match User *"

            try {
                Set-Content -Value $UpdatedSSHDConfig -Path $sshdConfigPath
                Restart-Service sshd -ErrorAction Stop
                Write-Host "Successfully changed sshd default shell to '$DefaultShell'" -ForegroundColor Green
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
    }
}

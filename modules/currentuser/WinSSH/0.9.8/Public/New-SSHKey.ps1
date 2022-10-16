<#
    .SYNOPSIS
        This function creates a new SSH Public/Private Key Pair. Optionally, add it to the ssh-agent.
        Optionally add the public key to a Remote Host's ~/.ssh/authorized_keys file.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER NewSSHKeyName
        This parameter is MANDATORY.

        This parameter takes a string that represents the file name that you would like to give to the new
        SSH User/Client Keys.

    .PARAMETER NewSSHKeyPurpose
        This parameter is OPTIONAL.

        This parameter takes a string that represents a very brief description of what the new SSH Keys
        will be used for. This description will be added to the Comment section when the new keys are
        created.

    .PARAMETER NewSSHKeyPwd
        This parameter is OPTIONAL.

        This parameter takes a SecureString that represents the password used to protect the new
        Private Key file that is created.

    .PARAMETER BlankSSHPrivateKeyPwd
        This parameter is OPTIONAL.

        This parameter is a switch. Use it to ensure that the newly created Private Key is NOT password
        protected.

    .PARAMETER AddToSSHAgent
        This parameter is OPTIONAL, but recommended.

        This parameter is a switch. If used, the new SSH Key Pair will be added to the ssh-agent service.

    .PARAMETER RemovePrivateKey
        This parameter is OPTIONAL. This parameter should only be used in conjunction with the
        -AddtoSSHAgent switch.

        This parameter is a switch. If used, the newly created Private Key will be added to the ssh-agent
        and deleted from the filesystem.

    .PARAMETER RemoteHost
        This parameter is OPTIONAL. This parameter should only be used in conjunction with the
        -AddToRemoteHostAuthKeys switch.

        This parameter takes a string that represents the IP Address of DNS-Resolvable name of a Remote Host.
        The newly created public key will be added to the Remote Host's ~/.ssh/authorized_keys file. The
        Remote Host can be either Windows or Linux (as long as you can ssh to it from the local host).

    .PARAMETER AddToRemoteHostAuthKeys
        This parameter is OPTIONAL.

        This parameter is a switch. If used, the newly created Public Key will be added to the Remote Host's
        ~/.ssh/authorized_keys file. (Specify the Remote Host using the -RemoteHost parameter)

    .PARAMETER RemoteHostUserName
        This parameter is OPTIONAL. This parameter should only be used in conjunction with the
        -AddToRemoteHostAuthKeys parameter.

        This parameter takes a string that represents the name of the user with ssh access to
        the Remote Host (specified by the -RemoteHost parameter).

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> $SplatParams = @{
            NewSSHKeyName           = "ToRHServ01"
            NewSSHKeyPurpose        = "ForSSHToRHServ01"
            AddToSSHAgent           = $True
        }
        PS C:\Users\zeroadmin> New-SSHKey @SplatParams
        
#>
function New-SSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$NewSSHKeyName,

        [Parameter(Mandatory=$False)]
        [System.Security.SecureString]$NewSSHKeyPwd,

        [Parameter(Mandatory=$False)]
        [ValidatePattern("^\w*$")] # No spaces allowed
        [string]$NewSSHKeyPurpose,

        [Parameter(Mandatory=$False)]
        [switch]$AddToSSHAgent,

        [Parameter(Mandatory=$False)]
        [switch]$RemovePrivateKey,

        #[Parameter(Mandatory=$False)]
        #[switch]$ShowNextSteps,

        [Parameter(Mandatory=$False)]
        [string]$RemoteHost,

        [Parameter(Mandatory=$False)]
        [switch]$AddToRemoteHostAuthKeys,

        [Parameter(Mandatory=$False)]
        [string]$RemoteHostUserName
    )

    ##### BEGIN Variable/Parameter Transforms and PreRun Prep #####

    if (!$(GetElevation)) {
        Write-Error "You must run PowerShell as Administrator before using this function! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if ($AddToRemoteHostAuthKeys -and !$RemoteHost) {
        $RemoteHost = Read-Host -Prompt "Please enter an IP, FQDN, or DNS-resolvable Host Name that represents the Remote Host you would like to share your new public key with."
    }
    if ($RemoteHost -and !$AddToRemoteHostAuthKeys) {
        $AddToRemoteHostAuthKeys = $True
    }

    if ($RemoteHost) {
        try {
            $RemoteHostNetworkInfo = ResolveHost -HostNameOrIP $RemoteHost -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to resolve $RemoteHost! Halting!"
            $global:FunctionResult = "1"
            return
        }
    }

    if ($RemoteHost -or $AddToRemoteHostAuthKeys -and !$RemoteHostUserName) {
        $RemoteHostUserName = Read-Host -Prompt "Please enter a UserName that has access to $RemoteHost"
    }

    $OpenSSHWinPath = "$env:ProgramFiles\OpenSSH-Win64"

    if (!$(Test-Path $OpenSSHWinPath)) {
        Write-Error "The path $OpenSSHWinPath was not found! Halting!"
        $global:FunctionResult = "1"
        return
    }

    [System.Collections.Arraylist][array]$CurrentEnvPathArray = $env:Path -split ";" | Where-Object {![System.String]::IsNullOrWhiteSpace($_)}
    if ($CurrentEnvPathArray -notcontains $OpenSSHWinPath) {
        $CurrentEnvPathArray.Insert(0,$OpenSSHWinPath)
        $env:Path = $CurrentEnvPathArray -join ";"
    }

    if (!$(Test-Path "$HOME\.ssh")) {
        $null = New-Item -Type Directory -Path "$HOME\.ssh"
    }

    $SSHKeyOutFile = "$HOME\.ssh\$NewSSHKeyName"

    if (Test-Path $SSHKeyOutFile) {
        Write-Error "$SSHKeyOutFile already exists! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if ($NewSSHKeyPurpose) {
        $NewSSHKeyPurpose = $NewSSHKeyPurpose -replace "[\s]",""

        $SSHKeyGenArgumentsString = "-t rsa -b 2048 -f `"$SSHKeyOutFile`" -q -N `"$NewSSHKeyPwd`" -C `"$NewSSHKeyPurpose`""
        $SSHKeyGenArgumentsNoPwdString = "-t rsa -b 2048 -f `"$SSHKeyOutFile`" -q -N `"`" -C `"$NewSSHKeyPurpose`""
    }
    else {
        $SSHKeyGenArgumentsString = "-t rsa -b 2048 -f `"$SSHKeyOutFile`" -q -N `"$NewSSHKeyPwd`""
        $SSHKeyGenArgumentsNoPwdString = "-t rsa -b 2048 -f `"$SSHKeyOutFile`" -q -N `"`""
    }
    
    ##### END Variable/Parameter Transforms and PreRun Prep #####


    ##### BEGIN Main Body #####

    # Create new public/private keypair
    
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.WorkingDirectory = $OpenSSHWinPath
    $ProcessInfo.FileName = $(Get-Command ssh-keygen.exe).Source
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.RedirectStandardOutput = $true
    #$ProcessInfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
    #$ProcessInfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
    $ProcessInfo.UseShellExecute = $false
    if ($NewSSHKeyPwd) {
        $ProcessInfo.Arguments = $SSHKeyGenArgumentsString
    }
    else {
        $ProcessInfo.Arguments = $SSHKeyGenArgumentsNoPwdString
    }
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null
    # Below $FinishedInAlottedTime returns boolean true/false
    $FinishedInAlottedTime = $Process.WaitForExit(5000)
    if (!$FinishedInAlottedTime) {
        $Process.Kill()
        $ProcessKilled = $True
    }
    $stdout = $Process.StandardOutput.ReadToEnd()
    $stderr = $Process.StandardError.ReadToEnd()
    $AllOutput = $stdout + $stderr

    if ($AllOutput -match "fail|error") {
        Write-Error $AllOutput
        Write-Error "The 'ssh-keygen command failed! Halting!"
        $global:FunctionResult = "1"
        return
    }

    $PubPrivKeyPairFiles = Get-ChildItem -Path "$HOME\.ssh" | Where-Object {$_.Name -match "$NewSSHKeyName"}
    $PubKey = $PubPrivKeyPairFiles | Where-Object {$_.Extension -eq ".pub"}
    $PrivKey = $PubPrivKeyPairFiles | Where-Object {$_.Extension -ne ".pub"}

    if (!$PubKey -or !$PrivKey) {
        Write-Error "The New SSH Key Pair was NOT created! Check the output of the ssh-keygen.exe command below! Halting!"
        Write-Output "##### BEGIN ssh-keygen Console Output From PSAwaitSession #####"
        Write-Output $SSHKeyGenConsoleOutput
        Write-Output "##### END ssh-keygen Console Output From PSAwaitSession #####"
        $global:FunctionResult = "1"
        return
    }

    if ($AddToSSHAgent) {
        if ($(Get-Service ssh-agent).Status -ne "Running") {
            $SSHDErrMsg = "The ssh-agent service is NOT curently running! This means that $HOME\.ssh\$NewSSHKeyName.pub cannot be added" +
            " in order to authorize remote hosts to use it to allow ssh access to this local machine! Please ensure that the sshd service" +
            " is running and try adding the new public key again using 'ssh-add.exe $HOME\.ssh\$NewSSHKeyName.pub'"
            Write-Error $SSHDErrMsg
            $global:FunctionResult = "1"
            return
        }

        # Add the New Private Key to the ssh-agent
        $SSHAddProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $SSHAddProcessInfo.WorkingDirectory = $OpenSSHWinPath
        $SSHAddProcessInfo.FileName = $(Get-Command ssh-add.exe).Source
        $SSHAddProcessInfo.RedirectStandardError = $true
        $SSHAddProcessInfo.RedirectStandardOutput = $true
        $SSHAddProcessInfo.UseShellExecute = $false
        $SSHAddProcessInfo.Arguments = "$($PrivKey.FullName)"
        $SSHAddProcess = New-Object System.Diagnostics.Process
        $SSHAddProcess.StartInfo = $SSHAddProcessInfo
        $SSHAddProcess.Start() | Out-Null
        $SSHAddProcess.WaitForExit()
        $SSHAddStdout = $SSHAddProcess.StandardOutput.ReadToEnd()
        $SSHAddStderr = $SSHAddProcess.StandardError.ReadToEnd()
        $SSHAddAllOutput = $SSHAddStdout + $SSHAddStderr
        
        if ($SSHAddAllOutput -match "fail|error") {
            Write-Error $SSHAddAllOutput
            Write-Error "The 'ssh-add $($PrivKey.FullName)' command failed!"
        }
        else {
            if ($RemovePrivateKey) {
                Remove-Item $PrivKey.FullName
            }
        }

        [System.Collections.ArrayList]$PublicKeysAccordingToSSHAgent = @()
        $(ssh-add -L) | foreach {
            $null = $PublicKeysAccordingToSSHAgent.Add($_)
        }
        $ThisPublicKeyAccordingToSSHAgent = $PublicKeysAccordingToSSHAgent | Where-Object {$_ -match "$NewSSHKeyName$"}
        [System.Collections.ArrayList]$CharacterCountArray = @()
        $ThisPublicKeyAccordingToSSHAgent -split " " | foreach {
            $null = $CharacterCountArray.Add($_.Length)
        }
        $LongestStringLength = $($CharacterCountArray | Measure-Object -Maximum).Maximum
        $ArrayPositionBeforeComment = $CharacterCountArray.IndexOf([int]$LongestStringLength)
        $PublicKeySansCommentFromSSHAgent = $($ThisPublicKeyAccordingToSSHAgent -split " ")[0..$ArrayPositionBeforeComment] -join " "

        $ThisPublicKeyAccordingToFile = Get-Content $PubKey.FullName
        [System.Collections.ArrayList]$CharacterCountArray = @()
        $ThisPublicKeyAccordingToFile -split " " | foreach {
            $null = $CharacterCountArray.Add($_.Length)
        }
        $LongestStringLength = $($CharacterCountArray | Measure-Object -Maximum).Maximum
        $ArrayPositionBeforeComment = $CharacterCountArray.IndexOf([int]$LongestStringLength)
        $PublicKeySansCommentFromFile = $($ThisPublicKeyAccordingToFile -split " ")[0..$ArrayPositionBeforeComment] -join " "

        if ($PublicKeySansCommentFromSSHAgent -ne $PublicKeySansCommentFromFile) {
            Write-Error "The public key according to the ssh-agent does NOT match the public key content in $($PubKey.FullName)! Halting!"
            $global:FunctionResult = "1"
            return
        }

        Write-Host "The Private Key $PublicKeyLocationFinal has been added to the ssh-agent service." -ForegroundColor Green
        if ($ShowNextSteps) {
            Get-PublicKeyAuthInstructions -PublicKeyLocation $PubKey.FullName -PrivateKeyLocation $PrivKey.FullName
        }
        
        if (!$RemovePrivateKey) {
            Write-Host "It is now safe to delete the private key (i.e. $($PrivKey.FullName)) since it has been added to the SSH Agent Service." -ForegroundColor Yellow
        }
    }
    else {
        if ($ShowNextSteps) {
            Get-PublicKeyAuthInstructions -PublicKeyLocation $PubKey.FullName -PrivateKeyLocation $PrivKey.FullName
        }
    }

    if ($AddToRemoteHostAuthKeys) {
        if ($RemoteHostNetworkInfo.FQDN) {
            $RemoteHostLocation = $RemoteHostNetworkInfo.FQDN
        }
        elseif ($RemoteHostNetworkInfo.HostName) {
            $RemoteHostLocation = $RemoteHostNetworkInfo.HostName
        }
        elseif ($RemoteHostNetworkInfo.IPAddressList[0]) {
            $RemoteHostLocation = $RemoteHostNetworkInfo.IPAddressList[0]
        }
        
        try {
            Add-PublicKeyToRemoteHost -PublicKeyPath $PubKey.FullName -RemoteHost $RemoteHostLocation -RemoteHostUserName $RemoteHostUserName -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to add the public key to the authorized_keys file on $RemoteHost! Halting!"
            $global:FunctionResult = "1"
            return
        }
        
        if (!$AddToSSHAgent) {
            Write-Host "You can now ssh to $RemoteHost using public key authentication using the following command:" -ForegroundColor Green
            Write-Host "    ssh -i $PubKey.FullName $RemoteHostUserName@$RemoteHostLocation" -ForegroundColor Green
        }
        else {
            Write-Host "You can now ssh to $RemoteHost using public key authentication using the following command:" -ForegroundColor Green
            Write-Host "    ssh $RemoteHostUserName@$RemoteHostLocation" -ForegroundColor Green
        }
    } 

    [pscustomobject]@{
        PublicKeyFilePath       = $PubKey.FullName
        PrivateKeyFilePath      = if (!$RemovePrivateKey) {$PrivKey.FullName} else {"PrivateKey was deleted after being added to the ssh-agent"}
        PublicKeyContent        = Get-Content "$HOME\.ssh\$NewSSHKeyName.pub"
    }

    ##### END Main Body #####

}

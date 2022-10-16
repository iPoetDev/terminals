<#
    .SYNOPSIS
        This function gets information about the specified SSH Key/Certificate file.

        Output is a PSCustomObject with the following properties...

            File                = $PathToKeyFile
            FileType            = $FileType
            Contents            = $Contents
            Info                = $Info
            FingerPrint         = $FingerPrint
            PasswordProtected   = $PasswordProtected

        ...where...
        
            - $PathToKeyFile is the path to the Key file specified by the -PathToKeyFile parameter,
            - $FileType is either "RSAPublicKey", "RSAPrivateKey", or "RSAPublicKeyCertificate"
            - $Contents is the result of: Get-Content $PathToKeyFile
            - $Info is the result of: ssh-keygen -l -f "$PathToKeyFile"
            - $FingerPrint is the fingerprint of the $PathToKeyFile
            - $PasswordProtected is a Boolean that indicates whether or not the file is password protected.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER PathToKeyFile
        This parameter is MANDATORY.

        This parameter takes a string that represents the full path to the SSH Key/Cert File you would
        like to inspect.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Get-SSHFileInfo -PathToKeyFile "$HOME\.ssh\id_rsa"
        
#>
function Get-SSHFileInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$PathToKeyFile
    )

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

    # Make sure we have access to ssh binaries
    if (![bool]$(Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Write-Error "Unable to find 'ssh-keygen.exe'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    # Make sure the path exists
    if (!$(Test-Path $PathToKeyFile)) {
        Write-Error "Unable to find the path '$PathToKeyFile'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    # This function can't validate .ppk files from putty, so just assume they're valid
    if ($(Get-Item $PathToKeyFile).Extension -eq ".ppk") {
        [pscustomobject]@{
            File                = $PathToKeyFile
            FileType            = "PuttyCombinedPublicPrivateKey"
            Contents            = $(Get-Content $PathToKeyFile)
            Info                = $(Get-Content $PathToKeyFile)
            FingerPrint         = $null
            PasswordProtected   = $null
        }
        
        return
    }

    $SSHKeyGenParentDir = $(Get-Command ssh-keygen).Source | Split-Path -Parent
    $SSHKeyGenArguments = "-l -f `"$PathToKeyFile`""

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.WorkingDirectory = $SSHKeyGenParentDir
    $ProcessInfo.FileName = $(Get-Command ssh-keygen).Source
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.RedirectStandardOutput = $true
    #$ProcessInfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
    #$ProcessInfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.Arguments = $SSHKeyGenArguments
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
    $SSHKeyGenOutput = $stdout + $stderr

    $KeyFileContent = Get-Content $PathToKeyFile
    if ($SSHKeyGenOutput -match "(RSA-CERT)") {
        $PublicKeyCertInfo = ssh-keygen -L -f "$PathToKeyFile"
        $PublicKeyCertContent = $KeyFileContent
        $FingerPrint = ssh-keygen -l -f "$PathToKeyFile"
        $IsPublicKeyCert = $True
    }
    elseif ($SSHKeyGenOutput -match "(RSA)") {
        # It could be either a Public Key or Private Key
        $PrivateKeyAttempt = Validate-SSHPrivateKey -PathToPrivateKeyFile $PathToKeyFile
        if (!$PrivateKeyAttempt.ValidSSHPrivateKeyFormat) {
            $IsPublicKey = $True
            $PublicKeyContent = $KeyFileContent
            $PublicKeyInfo = $FingerPrint = ssh-keygen -l -f "$PathToKeyFile"
        }
        else {
            $IsPrivateKey = $True
            $PrivateKeyContent = $PrivateKeyInfo = $KeyFileContent
            $FingerPrint = ssh-keygen -l -f "$PathToKeyFile"
            $PasswordProtected = $PrivateKeyAttempt.PasswordProtected
        }
    }
    elseif ($SSHKeyGenOutput -match "passphrase|pass phrase" -or $($SSHKeyGenOutput -eq $null -and $ProcessKilled)) {
        $IsPrivateKey = $True
        $PrivateKeyContent = $PrivateKeyInfo = $KeyFileContent
        $PasswordProtected = $True
    }
    elseif ($KeyFileContent.Count -gt 0) {
        if ($(Get-Content $PathToKeyFile)[0] -match "SSH2") {
            [pscustomobject]@{
                File                = $PathToKeyFile
                FileType            = "SSH2_RFC4716"
                Contents            = $(Get-Content $PathToKeyFile)
                Info                = $(Get-Content $PathToKeyFile)
                FingerPrint         = $null
                PasswordProtected   = $null
            }
        }

        return
    }
    else {
        $NotPubKeyPrivKeyOrPubCert = $True
    }

    if ($NotPubKeyPrivKeyOrPubCert) {
        Write-Warning "'$PathToKeyFile' is NOT a Public Key, Public Key Certificate, or Private Key"
    }
    else {
        if ($IsPublicKeyCert) {
            $FileType           = "RSAPublicKeyCertificate"
            $Contents           = $PublicKeyCertContent
            $Info               = $PublicKeyCertInfo
            $PasswordProtected  = $False
        }
        if ($IsPublicKey) {
            $FileType           = "RSAPublicKey"
            $Contents           = $PublicKeyContent
            $Info               = $PublicKeyInfo
            $PasswordProtected  = $False
        }
        if ($IsPrivateKey) {
            $FileType           = "RSAPrivateKey"
            $Contents           = $PrivateKeyContent
            $Info               = $PrivateKeyInfo
            $PasswordProtected  = $PrivateKeyAttempt.PasswordProtected
        }

        [pscustomobject]@{
            File                = $PathToKeyFile
            FileType            = $FileType
            Contents            = $Contents
            Info                = $Info
            FingerPrint         = $FingerPrint
            PasswordProtected   = $PasswordProtected
        }
    }
}

<#
    .SYNOPSIS
        This function is meant to determine the following:
            - Whether or not the specified file is, in fact, an SSH Private Key
            - If the SSH Private Key File is password protected
        
        In order to test if we have a valid Private Key, and if that Private Key
        is password protected, we try and generate a Public Key from it using ssh-keygen.
        Depending on the output of ssh-keygen, we can make a determination.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER PathToPrivateKeyFile
        This parameter is MANDATORY.

        This parameter takes a string that represents a full path to the file that we believe is
        a valid SSH Private Key that we want to test.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Validate-SSHPrivateKey -PathToPrivateKeyFile "$HOME\.ssh\random"
        
#>
function Validate-SSHPrivateKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$PathToPrivateKeyFile
    )

    # Make sure we have access to ssh binaries
    if (![bool]$(Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Write-Error "Unable to find 'ssh-keygen.exe'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    # Make sure the path exists
    if (!$(Test-Path $PathToPrivateKeyFile)) {
        Write-Error "Unable to find the path '$PathToPrivateKeyFile'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    $SSHKeyGenParentDir = $(Get-Command ssh-keygen).Source | Split-Path -Parent
    $SSHKeyGenArguments = "-y -f `"$PathToPrivateKeyFile`""

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

    if ($SSHKeyGenOutput -match "invalid format") {
        $ValidSSHPrivateKeyFormat = $False
        $PasswordProtected = $False
    }
    if ($SSHKeyGenOutput -match "ssh-rsa AA") {
        $ValidSSHPrivateKeyFormat = $True
        $PasswordProtected = $False
    }
    if ($SSHKeyGenOutput -match "passphrase|pass phrase" -or $($SSHKeyGenOutput -eq $null -and $ProcessKilled)) {
        $ValidSSHPrivateKeyFormat = $True
        $PasswordProtected = $True
    }

    [pscustomobject]@{
        ValidSSHPrivateKeyFormat        = $ValidSSHPrivateKeyFormat
        PasswordProtected               = $PasswordProtected
    }
}

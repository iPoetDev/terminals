<#
    .SYNOPSIS
        This function generates:
            - An ArrayList of PSCustomObjects that describes the contents of each of the files within the
            "$HOME\.ssh" directory
            - An .xml file that can be ingested by the 'Import-CliXml' cmdlet to generate
            the aforementioned ArrayList of PSCustomObjects in future PowerShell sessions.
            
            Each PSCustomObject in the ArrayList contains information similar to:

                File     : C:\Users\zeroadmin\.ssh\PwdProtectedPrivKey
                FileType : RSAPrivateKey
                Contents : {-----BEGIN RSA PRIVATE KEY-----, Proc-Type: 4,ENCRYPTED, DEK-Info: AES-128-CBC,27E137C044FC7857DAAC05C408472EF8, ...}
                Info     : {-----BEGIN RSA PRIVATE KEY-----, Proc-Type: 4,ENCRYPTED, DEK-Info: AES-128-CBC,27E137C044FC7857DAAC05C408472EF8, ...}

        By default, the .xml file is written to "$HOME\.ssh\SSHDirectoryFileInfo.xml"

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER PathToHomeDotSSHDirectory
        This parameter is OPTIONAL.

        This parameter takes a string that represents a full path to the User's .ssh directory. You should
        only use this parameter if the User's .ssh is NOT under "$HOME\.ssh" for some reason. 

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Generate-SSHUserDirFileInfo
        
#>
function Generate-SSHUserDirFileInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [string]$PathToHomeDotSSHDirectory
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

    if (!$PathToHomeDotSSHDirectory) {
        $PathToHomeDotSSHDirectory = "$HOME\.ssh"
    }

    # Get a list of all files under $HOME\.ssh
    [array]$SSHHomeFiles = Get-ChildItem -Path $PathToHomeDotSSHDirectory -File | Where-Object {$_.Name -ne "SSHDirectoryFileInfo.xml"}

    if ($SSHHomeFiles.Count -eq 0) {
        Write-Error "Unable to find any files under '$PathToHomeDotSSHDirectory'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    [System.Collections.ArrayList]$ArrayOfPSObjects = @()
    foreach ($File in $SSHHomeFiles.FullName) {
        #Write-Host "Analyzing file '$File' ..."
        try {
            $GetSSHFileInfoResult = Get-SSHFileInfo -PathToKeyFile $File -ErrorAction Stop -WarningAction SilentlyContinue
            if (!$GetSSHFileInfoResult) {
                #Write-Warning "'$File' is not a valid Public Key, Private Key, or Public Key Certificate!"
                #Write-Host "Ensuring '$File' is UTF8 encoded and trying again..." -ForegroundColor Yellow
                Set-Content -Path $File -Value $(Get-Content $File) -Encoding UTF8
            }

            $GetSSHFileInfoResult = Get-SSHFileInfo -PathToKeyFile $File -ErrorAction Stop -WarningAction SilentlyContinue
            if (!$GetSSHFileInfoResult) {
                Write-Verbose "'$File' is definitley not a valid Public Key, Private Key, or Public Key Certificate!"
            }

            # Sample Output:
            # NOTE: Possible values for the 'FileType' property are 'RSAPrivateKey','RSAPublicKey', and 'RSAPublicKeyCertificate'
            <#
                File     : C:\Users\zeroadmin\.ssh\PwdProtectedPrivKey
                FileType : RSAPrivateKey
                Contents : {-----BEGIN RSA PRIVATE KEY-----, Proc-Type: 4,ENCRYPTED, DEK-Info: AES-128-CBC,27E137C044FC7857DAAC05C408472EF8, ...}
                Info     : {-----BEGIN RSA PRIVATE KEY-----, Proc-Type: 4,ENCRYPTED, DEK-Info: AES-128-CBC,27E137C044FC7857DAAC05C408472EF8, ...}
            #>

            $null = $ArrayOfPSObjects.Add($GetSSHFileInfoResult)
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
    }

    $ArrayOfPSObjects
    $ArrayOfPSObjects | Export-CliXml "$PathToHomeDotSSHDirectory\SSHDirectoryFileInfo.xml"
}

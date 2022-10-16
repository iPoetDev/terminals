<#
    .SYNOPSIS
        This function uninstalls OpenSSH-Win64 binaries, removes ssh-agent and sshd services (if they exist),
        and deletes (recursively) the directories "C:\Program Files\OpenSSH-Win64" and "C:\ProgramData\ssh"
        (if they exist).

        Outputs an array of strings describing the actions taken. Possible string values are:
        "sshdUninstalled","sshAgentUninstalled","sshBinariesUninstalled"

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER KeepSSHAgent
        This parameter is OPTIONAL.

        This parameter is a switch. If used, ONLY the SSHD server (i.e. sshd service) is uninstalled. Nothing
        else is touched.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Uninstall-WinSSH
        
#>
function Uninstall-WinSSH {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$KeepSSHAgent
    )

    if (!$(GetElevation)) {
        Write-Error "You must run PowerShell as Administrator before using this function! Halting!"
        $global:FunctionResult = "1"
        return
    }

    #region >> Prep
    
    $OpenSSHProgramFilesPath = "C:\Program Files\OpenSSH-Win64"
    $OpenSSHProgramDataPath = "C:\ProgramData\ssh"
    <#
    $UninstallLogDir = "$HOME\OpenSSHUninstallLogs"
    $etwman = "$UninstallLogDir\openssh-events.man"
    if (!$(Test-Path $UninstallLogDir)) {
        $null = New-Item -ItemType Directory -Path $UninstallLogDir
    }
    #>

    #endregion >> Prep


    #region >> Main Body
    [System.Collections.ArrayList]$Output = @()

    if (Get-Service sshd -ErrorAction SilentlyContinue)  {
        try {
            Stop-Service sshd
            sc.exe delete sshd 1>$null
            Write-Host -ForegroundColor Green "sshd successfully uninstalled"
            $null = $Output.Add("sshdUninstalled")

            # unregister etw provider
            <#
            if (Test-Path $etwman) {
                wevtutil um `"$etwman`"
            }
            #>
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "sshd service is not installed"
    }

    if (!$KeepSSHAgent) {
        if (Get-Service ssh-agent -ErrorAction SilentlyContinue) {
            try {
                Stop-Service ssh-agent
                sc.exe delete ssh-agent 1>$null
                Write-Host -ForegroundColor Green "ssh-agent successfully uninstalled"
                $null = $Output.Add("sshAgentUninstalled")
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
        else {
            Write-Host -ForegroundColor Yellow "ssh-agent service is not installed"
        }

        if (!$(Get-Module ProgramManagement)) {
            try {
                Import-Module ProgramManagement -ErrorAction Stop
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
    
        try {
            $UninstallOpenSSHResult = Uninstall-Program -ProgramName openssh -ErrorAction Stop
            $null = $Output.Add("sshBinariesUninstalled")
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
    
        if (Test-Path $OpenSSHProgramFilesPath) {
            try {
                Remove-Item $OpenSSHProgramFilesPath -Recurse -Force
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
        if (Test-Path $OpenSSHProgramDataPath) {
            try {
                Remove-Item $OpenSSHProgramDataPath -Recurse -Force
            }
            catch {
                Write-Error $_
                $global:FunctionResult = "1"
                return
            }
        }
    }

    [System.Collections.ArrayList][array]$Output

    #endregion >> Main Body
}

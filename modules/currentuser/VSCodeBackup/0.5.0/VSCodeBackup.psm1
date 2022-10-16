Write-Verbose 'Importing from [C:\MyProjects\VSCodeBackup\VSCodeBackup\private]'
# .\VSCodeBackup\private\Close-Application.ps1
function Close-Application {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApplicationName,
        [Parameter()]
        $TimeOut = 60
    )

    begin {
    }

    process {
        $Timeout = New-TimeSpan -Seconds $TimeOut
        $StopWatch = [diagnostics.stopwatch]::StartNew()

        while ($true -and ($StopWatch.elapsed -lt $Timeout)) {
            Try {
                if ($IsMacOS) {
                    $ApplicationRunning = Get-Process $ApplicationName -ErrorAction SilentlyContinue | Where-Object path -like "*visual studio*" #I don't like this approach since it makes this function less general
                }
                else {
                    $ApplicationRunning = Get-Process $ApplicationName -ErrorAction SilentlyContinue
                }
            }
            Catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
                break;
            }
            if ($ApplicationRunning) {
                if (($IsWindows) -or ($PSVersionTable.PSVersion.Major -le 5)) {
                    $ApplicationRunning.CloseMainWindow() | Out-Null
                }
                elseif ($IsLinux -or $IsMacOS) {
                    $ApplicationRunning | Stop-Process -Force
                }
                elseif ($PSVersionTable.PSVersion.Major -le 5) {
                    $ApplicationRunning.CloseMainWindow() | Out-Null
                }
                else {
                    Write-Error "Could not determine platform"
                }
            }
            else {
                break
            }
            Start-Sleep -m 500
        }

        if ($null -ne (Get-Process $ApplicationName -ErrorAction SilentlyContinue)) {
            Write-Error "Could not close $($ApplicationName)"
        }
    }

    end {
        if ($StopWatch.IsRunning) {
            $StopWatch.Stop()
        }
    }
}
# .\VSCodeBackup\private\Get-CodeDirectory.ps1
function Get-CodeDirectory {
    <#Settings file locations

        By default VS Code shows the Settings editor, but you can still edit the underlying settings.json file by using the Open Settings (JSON) command or by changing your default settings editor with the workbench.settings.editor setting.

        Depending on your platform, the user settings file is located here:

            Windows %APPDATA%\Code\User\settings.json
            macOS $HOME/Library/Application Support/Code/User/settings.json
            Linux $HOME/.config/Code/User/settings.json
        #>
    [CmdletBinding()]
    param (

    )

    begin {
    }

    process {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            if ($IsLinux) {
                $ExtensionsDirectory = "$HOME/.vscode" | Resolve-Path -ErrorAction Stop
                $SettingsDirectory = "$HOME/.config/Code/User" | Resolve-Path -ErrorAction Stop
                $SettingsFile = "$SettingsDirectory/settings.json"
                $SnippetsDirectory = "$SettingsDirectory\Snippets" | Resolve-Path
            }
            elseif ($IsMacOS) {
                $ExtensionsDirectory = "$HOME/.vscode" | Resolve-Path -ErrorAction Stop
                $SettingsDirectory = "$HOME/Library/Application Support/Code/User" | Resolve-Path -ErrorAction Stop
                $SettingsFile = "$SettingsDirectory/settings.json"
                $SnippetsDirectory = "$SettingsDirectory\Snippets" | Resolve-Path
            }
            elseif ($IsWindows) {
                $ExtensionsDirectory = "$env:USERPROFILE\.vscode" | Resolve-Path -ErrorAction Stop
                $SettingsDirectory = "$env:APPDATA\Code\User" | Resolve-Path -ErrorAction Stop
                $SettingsFile = "$SettingsDirectory\settings.json"
                $SnippetsDirectory = "$SettingsDirectory\Snippets" | Resolve-Path
            }
        }
        elseif ($PSVersionTable.PSVersion.Major -le 5) {
            $ExtensionsDirectory = "$env:USERPROFILE\.vscode" | Resolve-Path -ErrorAction Stop
            $SettingsDirectory = "$env:APPDATA\Code\User" | Resolve-Path -ErrorAction Stop
            $SettingsFile = "$SettingsDirectory\settings.json"
            $SnippetsDirectory = "$SettingsDirectory\Snippets" | Resolve-Path
        }
        [PSCustomObject]@{
            ExtensionsDirectory = $ExtensionsDirectory
            SettingsDirectory   = $SettingsDirectory
            SettingsFile        = $SettingsFile
            SnippetsDirectory   = $SnippetsDirectory
        }
    }

    end {
    }
}

# .\VSCodeBackup\private\Test-AdminElevation.ps1
function Test-AdminElevation {
    [CmdletBinding()]
    param (

    )

    begin {
    }

    process {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent();
        (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    end {
    }
}
Write-Verbose 'Importing from [C:\MyProjects\VSCodeBackup\VSCodeBackup\public]'
# .\VSCodeBackup\public\Backup-VSCode.ps1
function Backup-VSCode {
    <#
    .SYNOPSIS
    Backup VS Code settings and extensions

    .DESCRIPTION
    Backup VS Code settings and extensions

    .PARAMETER Path
    Location to store zip file

    .PARAMETER Settings
    Switch to backup settings

    .PARAMETER Extensions
    Switch to backup extensions

    .PARAMETER Snippets
    Switch to restore snippets

    .PARAMETER CompressionLevel
    Specify compression level for zip file. Acceptable values are 'NoCompression' or 'Optimal'. Default value is 'NoCompression'.
    Compression is recommanded for extension backup.

    .EXAMPLE
    Backup-VSCode -Path c:\Users\bobby\Desktop -Settings -Extensions

    .EXAMPLE
    Backup-VSCode -Path c:\Users\bobby\Desktop -Settings -Extensions -CompressionLevel Optimal

    .NOTES
    Thanks t0rsten (https://github.com/t0rsten) for the additions
    #>

    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]
        $Path = ".\",
        # Parameter help description
        [Parameter()]
        [switch]
        $Settings,
        # Parameter help description
        [Parameter()]
        [switch]
        $Extensions,
        # Parameter help description
        [Parameter()]
        [switch]
        $Snippets,
        # Parameter help descripton
        [Parameter()]
        [ValidateSet('Optimal', 'NoCompression')]
        $CompressionLevel = 'NoCompression'
    )

    begin {
        $TimeStamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
        $Name = "VSCode-$($TimeStamp).zip"
        $Path = Resolve-Path -Path $Path
    }

    process {
        #Can't read some files while Code is running
        try {
            if ($IsMacOS) {
                Close-Application -ApplicationName "Electron" #On MacOS the process for Code is called Electron.
            }
            else {
                Close-Application -ApplicationName "code"
            }
        }
        catch {
            $_
        }

        $StartTime = Get-Date -Format o
        $CodeDir = Get-CodeDirectory

        if ($Extensions.IsPresent) {
            try {
                Compress-Archive -Path $CodeDir.ExtensionsDirectory -DestinationPath $Path\$Name -Update -CompressionLevel $CompressionLevel
            }
            catch {
                throw $_
            }
        }
        if ($Settings.IsPresent) {
            if ($CodeDir.SettingsFile | Test-Path -ErrorAction SilentlyContinue) {
                try {
                    Compress-Archive -LiteralPath $CodeDir.SettingsFile -DestinationPath $Path\$Name -Update -CompressionLevel $CompressionLevel
                }
                catch {
                    throw $_
                }
            }
            else {
                Write-Error "Settings file is missing, skipping settings file backup"
            }
        }
        if ($Snippets.IsPresent) {
            if ($CodeDir.SnippetsDirectory) {
                try {
                    Compress-Archive -Path $CodeDir.SnippetsDirectory -DestinationPath $Path\$Name -Update -CompressionLevel $CompressionLevel
                }
                catch {
                    throw $_
                }
            }
        }
        $EndTime = Get-Date -Format o
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        $ZippedSize = if (Test-Path "$Path\$Name") { [string]([math]::Round((Get-ChildItem $Path\$Name).Length / 1mb)) + "MB" }else { $null }

        if ($Extensions.IsPresent -or $Settings.IsPresent -or $Snippets.IsPresent) {
            [PSCustomObject][ordered]@{
                FileName  = [string]$Name
                FilePath  = [string]$Path
                StartTime = [datetime]$StartTime
                EndTime   = [datetime]$EndTime
                Duration  = $ElapsedTime -replace '\.\d+$'
                Size      = $ZippedSize
            }
        }
        else {
            Write-Warning -Message "Nothing to backup."
        }
    }

    end {
    }
}

# .\VSCodeBackup\public\Restore-VSCode.ps1
function Restore-VSCode {
    <#
    .SYNOPSIS
    Restore VS Code from a backup

    .DESCRIPTION
    Restore VS Code from a backup

    .PARAMETER Path
    Path to backup file

    .PARAMETER Settings
    Switch to restore settings

    .PARAMETER Extensions
    Switch to restore extensions

    .PARAMETER Snippets
    Switch to restore snippets

    .EXAMPLE
    Restore-VSCode -Path .\VSCode-2019-01-31T23.33.58.3351871+01.00.zip -Settings -Extensions

    .EXAMPLE
    Restore-VSCode -Path .\VSCode-2019-01-31T23.33.58.3351871+01.00.zip -Settings -Extensions -Snippets

    .NOTES
    General notes
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Path to zip file
        [Parameter(Mandatory)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]
        $Path,
        # Parameter help description
        [Parameter()]
        [switch]
        $Settings,
        # Parameter help description
        [Parameter()]
        [switch]
        $Extensions,
        # Parameter help description
        [Parameter()]
        [switch]
        $Snippets
    )

    begin {
        $Path = Resolve-Path -Path $Path
        $TempPath = [system.io.path]::GetTempPath()
        $CodeDir = Get-CodeDirectory
        #$CodeRunning = Get-Process -Name "code" -ErrorAction SilentlyContinue
        $StartTime = Get-Date -Format o
    }

    process {
        #Can't write some files while Code is running
        Write-Verbose "Closing VS Code"
        try {
            if ($Pscmdlet.ShouldProcess("VS Code", "Closing VS Code")) {
                if ($IsMacOS) {
                    Close-Application -ApplicationName "Electron" #On MacOS the process for Code is called Electron.
                }
                else {
                    Close-Application -ApplicationName "code"
                }
            }
        }
        catch {
            $_
        }

        try {
            if ($Pscmdlet.ShouldProcess($TempPath, "Expanding VS Code archive to temp destination")) {
                Expand-Archive -Path $Path -DestinationPath $TempPath -Force
            }
        }
        catch {
            throw $_
        }

        if ($Extensions.IsPresent) {
            if ($Pscmdlet.ShouldProcess($CodeDir.ExtensionsDirectory, "Copying extensions to extenions folder")) {
                Copy-Item -Path "$TempPath\.vscode\extensions" -Destination $CodeDir.ExtensionsDirectory -Force -Recurse
            }
        }
        if ($Settings.IsPresent) {
            if ($Pscmdlet.ShouldProcess($CodeDir.SettingsFile, "Copying settings")) {
                Copy-Item -LiteralPath "$TempPath\settings.json" -Destination $CodeDir.SettingsFile -Force
            }
        }
        if ($Snippets.IsPresent) {
            if ($Pscmdlet.ShouldProcess($CodeDir.SnippetsDirectory, "Copying Snippets Directory")) {
                Copy-Item -LiteralPath "$TempPath\Snippets" -Destination $($CodeDir.SnippetsDirectory | Split-Path -Parent) -Force -Recurse
            }
        }
        $EndTime = Get-Date -Format o
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        $ZippedSize = if (Test-Path "$Path") { [string]([math]::Round((Get-ChildItem $Path).Length / 1mb)) + "MB" }else { $null }

        if ($Extensions.IsPresent -or $Settings.IsPresent -or $Snippets.IsPresent) {
            [PSCustomObject][ordered]@{
                FilePath  = [string]$Path
                StartTime = [datetime]$StartTime
                EndTime   = [datetime]$EndTime
                Duration  = $ElapsedTime -replace '\.\d+$'
                Size      = $ZippedSize
            }
        }
        else {
            Write-Warning -Message "Nothing to restore."
        }
    }

    end {
    }
}

Write-Verbose 'Importing from [C:\MyProjects\VSCodeBackup\VSCodeBackup\classes]'


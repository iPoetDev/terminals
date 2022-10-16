[CmdletBinding()]
Param (
    [parameter(Position = 0)]
    [bool]
    $ShowLoadTime = $true
)
$env:ShowPSProfileLoadTime = $ShowLoadTime
enum PSProfileLogLevel {
    Information
    Warning
    Error
    Debug
    Verbose
    Quiet
}
enum PSProfileSecretType {
    PSCredential
    SecureString
}
class PSProfileEvent {
    hidden [datetime] $Time
    [timespan] $Total
    [timespan] $Last
    [PSProfileLogLevel] $LogLevel
    [string] $Section
    [string] $Message

    PSProfileEvent(
        [datetime] $time,
        [timespan] $last,
        [timespan] $total,
        [PSProfileLogLevel] $logLevel,
        [string] $section,
        [string] $message
    ) {
        $this.Time = $time
        $this.Last = $last
        $this.Total = $total
        $this.Section = $section
        $this.Message = $message
        $this.LogLevel = $logLevel
    }
}
class PSProfileSecret {
    [PSProfileSecretType] $Type
    hidden [pscredential] $PSCredential
    hidden [securestring] $SecureString

    PSProfileSecret([string]$userName, [securestring]$password) {
        $this.Type = [PSProfileSecretType]::PSCredential
        $this.PSCredential = [PSCredential]::new($userName,$password)
    }
    PSProfileSecret([pscredential]$psCredential) {
        $this.Type = [PSProfileSecretType]::PSCredential
        $this.PSCredential = $psCredential
    }
    PSProfileSecret([SecureString]$secureString) {
        $this.Type = [PSProfileSecretType]::SecureString
        $this.SecureString = $secureString
    }
}

class PSProfile {
    hidden [System.Collections.Generic.List[PSProfileEvent]] $Log
    [hashtable] $_internal
    [hashtable] $Settings
    [datetime] $LastRefresh
    [datetime] $LastSave
    [string] $RefreshFrequency
    [hashtable] $GitPathMap
    [hashtable] $PSBuildPathMap
    [object[]] $ModulesToImport
    [object[]] $ModulesToInstall
    [hashtable] $PathAliases
    [hashtable] $CommandAliases
    [hashtable[]] $Plugins
    [string[]] $PluginPaths
    [string[]] $ProjectPaths
    [hashtable] $Prompts
    [hashtable] $InitScripts
    [string[]] $ScriptPaths
    [string[]] $ConfigurationPaths
    [hashtable] $SymbolicLinks
    [hashtable] $Variables
    [hashtable] $Vault

    PSProfile() {
        $this.Log = [System.Collections.Generic.List[PSProfileEvent]]::new()
        $this.Vault = @{_secrets = @{}}
        $this._internal = @{ }
        $this.GitPathMap = @{ }
        $this.PSBuildPathMap = @{ }
        $this.SymbolicLinks = @{ }
        $this.Prompts = @{ }
        $this.Variables = @{
            Environment = @{}
            Global      = @{
                PathAliasDirectorySeparator    = "$([System.IO.Path]::DirectorySeparatorChar)"
                AltPathAliasDirectorySeparator = "$([char]0xe0b1)"
            }
        }
        $this.Settings = @{
            DefaultPrompt         = $null
            PSVersionStringLength = 3
            ConfigurationPath     = (Join-Path (Get-ConfigurationPath -CompanyName 'SCRT HQ' -Name PSProfile) 'Configuration.psd1')
            FontType              = 'Default'
            PromptCharacters      = @{
                GitRepo = @{
                    NerdFonts = "$([char]0xf418)"
                    PowerLine = "$([char]0xe0a0)"
                    Default   = "@"
                }
                AWS     = @{
                    NerdFonts = "$([char]0xf270)"
                    PowerLine = "$([char]0xf0e7)"
                    Default   = "AWS: "
                }
            }
            PSReadline            = @{
                Options     = @{ }
                KeyHandlers = @{ }
            }
        }
        $this.RefreshFrequency = (New-TimeSpan -Hours 1).ToString()
        $this.LastRefresh = [datetime]::Now.AddHours(-2)
        $this.LastSave = [datetime]::Now
        $this.ProjectPaths = @()
        $this.PluginPaths = @()
        $this.InitScripts = @{ }
        $this.ScriptPaths = @()
        $this.ConfigurationPaths = @()
        $this.PathAliases = @{
            '~' = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        }
        $this.CommandAliases = @{ }
        $this.Plugins = @()
    }
    [void] Load() {
        $this._internal['ProfileLoadStart'] = [datetime]::Now
        $this._log(
            "SECTION START",
            "MAIN",
            "Debug"
        )
        $this._loadConfiguration()
        $this.Prompts['SCRTHQ'] = @'
$origDollarQuestion = $global:?
$origLastExitCode = $global:LASTEXITCODE
if ($null -eq $script:PoshGitOneDotOh) {
    $script:PoshGitOneDotOh = (Get-Module posh-git).Version -ge ([System.Version]'1.0.0')
}
if ($script:PoshGitOneDotOh) {
    $origDollarQuestion = $global:?
    $origLastExitCode = $global:LASTEXITCODE
    $global:GitPromptSettings.BeforePath = '['
    $global:GitPromptSettings.AfterPath = ("+" * (Get-Location -Stack).Count) + ']'
    $lastCommandSuccessColor = if ($origDollarQuestion -eq $true) {
        0x81FFC8
    }
    else {
        0xFF81A3
    }
    $pathColor = 0xBA81FF
    $global:GitPromptSettings.DefaultPromptPath.ForegroundColor = $pathColor
    $global:GitPromptSettings.BeforePath.ForegroundColor = 'White'
    $global:GitPromptSettings.AfterPath.ForegroundColor = 'White'
    $global:GitPromptSettings.DefaultPromptPath.Text = '$(Get-PathAlias)'
    $global:GitPromptSettings.DefaultPromptSuffix = ''
    $prompt = Write-Prompt "[#$($MyInvocation.HistoryId) $("PS {0}" -f (Get-PSVersion))] " -ForegroundColor LightPink
    $prompt += Write-Prompt "[$(Get-LastCommandDuration) @ $([DateTime]::now.ToString("HH:mm:ss.ffff"))]" -ForegroundColor $lastCommandSuccessColor
    if ($env:AWS_PROFILE) {
        $str = "$($env:AWS_PROFILE)$(if($env:AWS_DEFAULT_REGION){"\\$("$env:AWS_DEFAULT_REGION".Split('-').ForEach({"$_".Substring(0,1)}) -join '')"})"
        $prompt += Write-Prompt " [$($str)]" -ForegroundColor 0xFFFC77
    }
    if ($env:CHEF_PROFILE) {
        $prompt += Write-Prompt " [$($env:CHEF_PROFILE)]" -ForegroundColor 0xFFD580
    }
    $prompt += Write-Prompt "`n"
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt "`n"
    $prompt += Write-Prompt "$('λ' * ($nestedPromptLevel + 1))" -ForegroundColor 0xDAF7A6
    $global:LASTEXITCODE = $origLastExitCode
    "$prompt "
}
else {
    $lastColor = if ($origDollarQuestion -eq $true) {
        "Green"
    }
    else {
        "Red"
    }
    $isAdmin = $false
    $isDesktop = ($PSVersionTable.PSVersion.Major -eq 5)
    if ($isDesktop -or $IsWindows) {
        $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $windowsPrincipal = New-Object "System.Security.Principal.WindowsPrincipal" $windowsIdentity
        $isAdmin = $windowsPrincipal.IsInRole("Administrators") -eq 1
    } else {
        $isAdmin = ((& id -u) -eq 0)
    }
    if ($isAdmin) {
        $idColor = "Magenta"
    }
    else {
        $idColor = "Cyan"
    }
    Write-Host "[" -NoNewline
    Write-Host -ForegroundColor $idColor "#$($MyInvocation.HistoryId)" -NoNewline
    Write-Host "] [" -NoNewline
    $verColor = @{
        ForegroundColor = if ($PSVersionTable.PSVersion.Major -eq 7) {
            "Yellow"
        }
        elseif ($PSVersionTable.PSVersion.Major -eq 6) {
            "Magenta"
        }
        else {
            "Cyan"
        }
    }
    Write-Host @verColor ("PS {0}" -f (Get-PSVersion)) -NoNewline
    Write-Host "] [" -NoNewline
    Write-Host -ForegroundColor $lastColor ("{0}" -f (Get-LastCommandDuration)) -NoNewline
    Write-Host "] [" -NoNewline
    Write-Host ("{0}" -f $(Get-PathAlias)) -NoNewline -ForegroundColor DarkYellow
    if ((Get-Location -Stack).Count -gt 0) {
        Write-Host (("+" * ((Get-Location -Stack).Count))) -NoNewLine -ForegroundColor Cyan
    }
    Write-Host "]" -NoNewline
    if ($PWD.Path -notlike "\\*" -and $env:DisablePoshGit -ne $true) {
        Write-VcsStatus
        $GitPromptSettings.EnableWindowTitle = "PS {0} @" -f (Get-PSVersion)
    }
    else {
        $Host.UI.RawUI.WindowTitle = "PS {0}" -f (Get-PSVersion)
    }
    if ($env:AWS_PROFILE) {
        Write-Host "`n[" -NoNewline
        $awsIcon = if ($global:PSProfile.Settings.ContainsKey("FontType")) {
            $global:PSProfile.Settings.PromptCharacters.AWS[$global:PSProfile.Settings.FontType]
        }
        else {
            "AWS:"
        }
        if ([String]::IsNullOrEmpty($awsIcon)) {
            $awsIcon = "AWS:"
        }
        Write-Host -ForegroundColor Yellow "$($awsIcon) $($env:AWS_PROFILE)$(if($env:AWS_DEFAULT_REGION){" @ $env:AWS_DEFAULT_REGION"})" -NoNewline
        Write-Host "]" -NoNewline
    }
    "`n>> "
}
'@
        $plugPaths = @((Join-Path $PSScriptRoot "Plugins"))
        $curVer = (Import-Metadata (Join-Path $PSScriptRoot "PSProfile.psd1")).ModuleVersion
        $this.PluginPaths | Where-Object { -not [string]::IsNullOrEmpty($_) -and ($_ -match "[\/\\](Modules|BuildOutput)[\/\\]PSProfile[\/\\]$curVer" -or $_ -notmatch "[\/\\](Modules|BuildOutput)[\/\\]PSProfile[\/\\]\d+\.\d+\.\d+") } | ForEach-Object {
            $plugPaths += $_
        }
        $this.PluginPaths = $plugPaths | Select-Object -Unique
        $plugs = @()
        $this.Plugins | Where-Object { $_.Name -ne 'PSProfile.PowerTools' } | ForEach-Object {
            $plugs += $_
        }
        if ($plugs.Count) {
            $this.Plugins = $plugs
        }
        if (([datetime]::Now - $this.LastRefresh) -gt [timespan]$this.RefreshFrequency) {
            $withRefresh = ' with refresh.'
            $this.Refresh()
        }
        else {
            $withRefresh = '.'
            $this._log(
                "Skipped full refresh! Frequency set to '$($this.RefreshFrequency)', but last refresh was: $($this.LastRefresh.ToString())",
                "MAIN",
                "Verbose"
            )
        }
        $this._invokeInitScripts()
        $this._importModules()
        $this._loadPlugins()
        $this._invokeScripts()
        $this._setVariables()
        $this._setCommandAliases()
        $this._loadPrompt()

        $this.Variables['Environment']['Home'] = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        $this.Variables['Environment']['UserName'] = [System.Environment]::UserName
        $this.Variables['Environment']['ComputerName'] = [System.Environment]::MachineName

        $this._internal['ProfileLoadEnd'] = [datetime]::Now
        $this._internal['ProfileLoadDuration'] = $this._internal.ProfileLoadEnd - $this._internal.ProfileLoadStart
        $this._log(
            "SECTION END",
            "MAIN",
            "Debug"
        )
        if ($env:ShowPSProfileLoadTime -ne $false) {
            Write-Host "Loading PSProfile alone took $([Math]::Round($this._internal.ProfileLoadDuration.TotalMilliseconds))ms$withRefresh"
        }
    }
    [void] Refresh() {
        $this._log(
            "Refreshing project map, checking for modules to install and creating symbolic links",
            "MAIN",
            "Verbose"
        )
        $this._cleanConfig()
        $this._findProjects()
        $this._installModules()
        $this._createSymbolicLinks()
        $this._formatPrompts()
        $this._formatInitScripts()
        $this.LastRefresh = [datetime]::Now
        $this.Save()
        $this._log(
            "Refresh complete",
            "MAIN",
            "Verbose"
        )
    }
    [void] Save() {
        $this._log(
            "Saving PSProfile configuration",
            "MAIN",
            "Debug"
        )
        $out = @{ }
        $this.LastSave = [DateTime]::Now
        $this.PSObject.Properties.Name | Where-Object { $_ -ne '_internal' } | ForEach-Object {
            $out[$_] = $this.$_
        }
        $out | Export-Configuration -Name PSProfile -CompanyName 'SCRT HQ'
        $this._log(
            "PSProfile configuration has been saved.",
            "MAIN",
            "Debug"
        )
    }
    hidden [string] _globalize([string]$content) {
        $noScopePattern = 'function\s+(?<Name>[\w+_-]{1,})\s+\{'
        $globalScopePattern = 'function\s+global\:'
        $noScope = [RegEx]::Matches($content, $noScopePattern, "Multiline, IgnoreCase")
        $globalScope = [RegEx]::Matches($content,$globalScopePattern,"Multiline, IgnoreCase")
        if ($noScope.Count -ge $globalScope.Count) {
            foreach ($match in $noScope) {
                $fullValue = ($match.Groups | Where-Object { $_.Name -eq 0 }).Value
                $funcName = ($match.Groups | Where-Object { $_.Name -eq 'Name' }).Value
                $content = $content.Replace($fullValue, "function global:$funcName {")
            }
        }
        $content = $content -replace '\$PSDefaultParameterValues','$global:PSDefaultParameterValues'
        return $content
    }
    hidden [void] _cleanConfig() {
        $this._log(
            "SECTION START",
            "CleanConfig",
            "Debug"
        )
        foreach ($section in @('ModulesToImport','ModulesToInstall')) {
            $this._log(
                "[$section] Cleaning section",
                "CleanConfig",
                "Verbose"
            )
            [hashtable[]]$final = @()
            $this.$section | Where-Object { $_ -is [hashtable] -and $_.Name } | ForEach-Object {
                $final += $_
            }
            $this.$section | Where-Object { $_ -is [string] } | ForEach-Object {
                $this._log(
                    "[$section] Converting module string to hashtable: $_",
                    "CleanConfig",
                    "Verbose"
                )
                $final += @{Name = $_ }
            }
            $this.$section = $final
        }
        foreach ($section in @('ScriptPaths','PluginPaths','ProjectPaths')) {
            $this._log(
                "[$section] Cleaning section",
                "CleanConfig",
                "Verbose"
            )
            [string[]]$final = @()
            $this.$section | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object {
                $final += $_
            }
            $this.$section = $final
        }
        $this._log(
            "SECTION END",
            "CleanConfig",
            "Debug"
        )
    }
    hidden [void] _loadPrompt() {
        $this._log(
            "SECTION START",
            "LoadPrompt",
            "Debug"
        )
        if (-not [String]::IsNullOrEmpty($this.Settings.DefaultPrompt)) {
            $this._log(
                "Loading default prompt: $($this.Settings.DefaultPrompt)",
                "LoadPrompt",
                "Verbose"
            )
            $function:prompt = $this.Prompts[$this.Settings.DefaultPrompt]
        }
        else {
            $this._log(
                "No default prompt name found on PSProfile. Retaining current prompt.",
                "LoadPrompt",
                "Verbose"
            )
        }
        $this._log(
            "SECTION END",
            "LoadPrompt",
            "Debug"
        )
    }
    hidden [void] _formatPrompts() {
        $this._log(
            "SECTION START",
            "FormatPrompts",
            "Debug"
        )
        $final = @{ }
        $this.Prompts.GetEnumerator() | ForEach-Object {
            $this._log(
                "Formatting prompt '$($_.Key)'",
                "FormatPrompts",
                "Verbose"
            )
            $updated = ($_.Value -split "[\r\n]" | Where-Object { $_ }).Trim() -join "`n"
            $final[$_.Key] = $updated
        }
        $this.Prompts = $final
        $this._log(
            "SECTION END",
            "FormatPrompts",
            "Debug"
        )
    }
    hidden [void] _formatInitScripts() {
        $this._log(
            "SECTION START",
            "FormatInitScripts",
            "Debug"
        )
        $final = $this.InitScripts
        $this.InitScripts.GetEnumerator() | ForEach-Object {
            $this._log(
                "Formatting InitScript '$($_.Key)'",
                "FormatInitScripts",
                "Verbose"
            )
            $updated = ($_.Value.ScriptBlock -split "[\r\n]" | Where-Object { $_ }).Trim() -join "`n"
            $final[$_.Key]['ScriptBlock'] = $updated
        }
        $this.InitScripts = $final
        $this._log(
            "SECTION END",
            "FormatInitScripts",
            "Debug"
        )
    }
    hidden [void] _loadAdditionalConfiguration([string]$configurationPath) {
        $this._log(
            "SECTION START",
            "AddlConfiguration",
            "Debug"
        )
        $this._log(
            "Importing additional file: $configurationPath",
            "AddlConfiguration",
            "Verbose"
        )
        $additional = Import-Metadata -Path $configurationPath
        $this._log(
            "Adding additional configuration to PSProfile object",
            "AddlConfiguration",
            "Verbose"
        )
        $this | Update-Object $additional
        $this._log(
            "SECTION END",
            "AddlConfiguration",
            "Debug"
        )
    }
    hidden [void] _loadConfiguration() {
        $this._log(
            "SECTION START",
            "Configuration",
            "Debug"
        )
        $this._log(
            "Importing layered Configuration",
            "Configuration",
            "Verbose"
        )
        $conf = Import-Configuration -Name PSProfile -CompanyName 'SCRT HQ' -DefaultPath (Join-Path $PSScriptRoot "Configuration.psd1")
        $this._log(
            "Adding layered configuration to PSProfile object",
            "Configuration",
            "Verbose"
        )
        $this | Update-Object $conf
        if ($this.ConfigurationPaths.Count) {
            $this.ConfigurationPaths | ForEach-Object {
                if (Test-Path $_) {
                    $this._loadAdditionalConfiguration($_)
                }
            }
        }
        $this._log(
            "SECTION END",
            "Configuration",
            "Debug"
        )
    }
    hidden [void] _setCommandAliases() {
        $this._log(
            "SECTION START",
            'SetCommandAliases',
            'Debug'
        )
        $this.CommandAliases.GetEnumerator() | ForEach-Object {
            try {
                $Name = $_.Key
                $Value = $_.Value
                if ($null -eq (Get-Alias "$Name*")) {
                    New-Alias -Name $Name -Value $Value -Scope Global -Option AllScope -ErrorAction SilentlyContinue
                    $this._log(
                        "Set command alias: $Name > $Value",
                        'SetCommandAliases',
                        'Verbose'
                    )
                }
                else {
                    $this._log(
                        "Alias already in use, skipping: $Name",
                        'SetCommandAliases',
                        'Verbose'
                    )
                }
            }
            catch {
                $this._log(
                    "Failed to set command alias: $Name > $Value :: $($_)",
                    'SetCommandAliases',
                    'Warning'
                )
            }
        }
        $this._log(
            "SECTION END",
            'SetCommandAliases',
            'Debug'
        )
    }
    hidden [void] _createSymbolicLinks() {
        $this._log(
            "SECTION START",
            'CreateSymbolicLinks',
            'Debug'
        )
        if ($null -ne $this.SymbolicLinks.Keys) {
            $null = $this.SymbolicLinks.GetEnumerator() | Start-RSJob -Name { "_PSProfile_SymbolicLinks_" + $_.Key } -ScriptBlock {
                if (-not (Test-Path $_.Key) -or ((Get-Item $_.Key).LinkType -eq 'SymbolicLink' -and (Get-Item $_.Key).Target -ne $_.Value)) {
                    New-Item -ItemType SymbolicLink -Path $_.Key -Value $_.Value -Force
                }
            }
        }
        else {
            $this._log(
                "No symbolic links specified!",
                'CreateSymbolicLinks',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'CreateSymbolicLinks',
            'Debug'
        )
    }
    hidden [void] _setVariables() {
        $this._log(
            "SECTION START",
            'SetVariables',
            'Debug'
        )
        if ($null -ne $this.Variables.Keys) {
            foreach ($varType in $this.Variables.Keys) {
                switch ($varType) {
                    Environment {
                        $this.Variables.Environment.GetEnumerator() | ForEach-Object {
                            $this._log(
                                "`$env:$($_.Key) = '$($_.Value)'",
                                'SetVariables',
                                'Verbose'
                            )
                            Set-Item "Env:\$($_.Key)" -Value $_.Value -Force
                        }
                    }
                    default {
                        $this.Variables.Global.GetEnumerator() | ForEach-Object {
                            $this._log(
                                "`$global:$($_.Key) = '$($_.Value)'",
                                'SetVariables',
                                'Verbose'
                            )
                            Set-Variable -Name $_.Key -Value $_.Value -Scope Global -Force
                        }
                    }
                }
            }
        }
        else {
            $this._log(
                "No variables key/value pairs provided!",
                'SetVariables',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'SetVariables',
            'Debug'
        )
    }
    hidden [void] _findProjects() {
        $this._log(
            "SECTION START",
            'FindProjects',
            'Debug'
        )
        if (-not [string]::IsNullOrEmpty((-join $this.ProjectPaths))) {
            $this.GitPathMap = @{ }
            $this.ProjectPaths | ForEach-Object {
                $p = $_
                $cnt = 0
                if (Test-Path $p) {
                    $p = (Resolve-Path $p).Path
                    $cnt++
                    $pInfo = [System.IO.DirectoryInfo]::new($p)
                    $this.PathAliases["@$($pInfo.Name)"] = $pInfo.FullName
                    $this._log(
                        "Added path alias: @$($pInfo.Name) >> $($pInfo.FullName)",
                        'FindProjects',
                        'Verbose'
                    )
                    $g = 0
                    $b = 0
                    $w = 0
                    $pInfo.EnumerateDirectories('.git',[System.IO.SearchOption]::AllDirectories) | ForEach-Object {
                        $PathName = $_.Parent.Name
                        $FullPathName = $_.Parent.FullName
                        $g++
                        $this._log(
                            "Found git project @ $($FullPathName)",
                            'FindProjects',
                            'Verbose'
                        )
                        $currPath = $_
                        while ($this.GitPathMap.ContainsKey($PathName)) {
                            $currPath = $currPath.Parent
                            $doublePath = [System.IO.DirectoryInfo]::new($this.GitPathMap[$PathName])
                            $this.GitPathMap["$($doublePath.Parent.Name)$([System.IO.Path]::DirectorySeparatorChar)$($doublePath.Name)"] = $doublePath.FullName
                            $this.GitPathMap.Remove($PathName)
                            if ($this.PSBuildPathMap.ContainsKey($PathName)) {
                                $PSBuildPath = [System.IO.DirectoryInfo]::new($this.PSBuildPathMap[$PathName])
                                $this.PSBuildPathMap["$($PSBuildPath.Parent.Name)$([System.IO.Path]::DirectorySeparatorChar)$($PSBuildPath.Name)"] = $doublePath.FullName
                                $this.PSBuildPathMap.Remove($PathName)
                            }
                            $PathName = "$($currPath.Parent.BaseName)$([System.IO.Path]::DirectorySeparatorChar)$PathName"
                        }
                        $this.GitPathMap[$PathName] = $FullPathName
                        $bldPath = [System.IO.Path]::Combine($FullPathName,'build.ps1')
                        if ([System.IO.File]::Exists($bldPath)) {
                            $b++
                            $this._log(
                                "Found build script @ $($bldPath)",
                                'FindProjects',
                                'Verbose'
                            )
                            $this.PSBuildPathMap[$PathName] = $FullPathName
                        }
                    }
                    $pInfo.EnumerateFiles('*.code-workspace',[System.IO.SearchOption]::AllDirectories) | ForEach-Object {
                        $PathName = $_.Name
                        $FullPathName = $_.FullName
                        $w++
                        $this._log(
                            "Found code-workspace @ $($FullPathName)",
                            'FindProjects',
                            'Verbose'
                        )
                        $currPath = $_
                        while ($this.GitPathMap.ContainsKey($PathName)) {
                            $currPath = $currPath.Parent
                            $doublePath = [System.IO.DirectoryInfo]::new($this.GitPathMap[$PathName])
                            $this.GitPathMap["$($doublePath.Parent.Name)$([System.IO.Path]::DirectorySeparatorChar)$($doublePath.Name)"] = $doublePath.FullName
                            $this.GitPathMap.Remove($PathName)
                            if ($this.PSBuildPathMap.ContainsKey($PathName)) {
                                $PSBuildPath = [System.IO.DirectoryInfo]::new($this.PSBuildPathMap[$PathName])
                                $this.PSBuildPathMap["$($PSBuildPath.Parent.Name)$([System.IO.Path]::DirectorySeparatorChar)$($PSBuildPath.Name)"] = $doublePath.FullName
                                $this.PSBuildPathMap.Remove($PathName)
                            }
                            $PathName = "$($currPath.Parent.BaseName)$([System.IO.Path]::DirectorySeparatorChar)$PathName"
                        }
                        $this.GitPathMap[$PathName] = $FullPathName
                    }
                    $this._log(
                        "$p :: Found: $g git | $w code-workspace | $b build",
                        'FindProjects',
                        'Verbose'
                    )
                }
                else {
                    $this._log(
                        "'$p' Unable to resolve path!",
                        'FindProjects',
                        'Verbose'
                    )
                }
            }
        }
        else {
            $this._log(
                "No project paths specified to search in!",
                'FindProjects',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'FindProjects',
            'Debug'
        )
    }
    hidden [void] _invokeScripts() {
        $this._log(
            "SECTION START",
            'InvokeScripts',
            'Debug'
        )
        if (-not [string]::IsNullOrEmpty((-join $this.ScriptPaths))) {
            $this.ScriptPaths | ForEach-Object {
                $p = $_
                if (Test-Path $p) {
                    $i = Get-Item $p
                    $p = $i.FullName
                    if ($p -match '\.ps1$') {
                        try {
                            $this._log(
                                "'$($i.Name)' Invoking script",
                                'InvokeScripts',
                                'Verbose'
                            )
                            $sb = [scriptblock]::Create($this._globalize(([System.IO.File]::ReadAllText($i.FullName))))
                            $newModuleArgs = @{
                                Name = "PSProfile.ScriptPath.$($i.BaseName)"
                                ScriptBlock = $sb
                                ReturnResult = $true
                            }
                            $this._log(
                                "'$($i.Name)' Importing dynamic ScriptPath module: $($newModuleArgs.Name)",
                                'InvokeScripts',
                                'Verbose'
                            )
                            New-Module @newModuleArgs | Import-Module -Global
                        }
                        catch {
                            $e = $_
                            $this._log(
                                "'$($i.Name)' Failed to invoke script! Error: $e",
                                'InvokeScripts',
                                'Warning'
                            )
                        }
                    }
                    else {
                        [System.IO.DirectoryInfo]::new($p).EnumerateFiles('*.ps1',[System.IO.SearchOption]::AllDirectories) | Where-Object { $_.BaseName -notmatch '^(profile|CONFIG|WIP)' } | ForEach-Object {
                            $s = $_
                            try {
                                $this._log(
                                    "'$($s.Name)' Invoking script",
                                    'InvokeScripts',
                                    'Verbose'
                                )
                                $sb = [scriptblock]::Create($this._globalize(([System.IO.File]::ReadAllText($s.FullName))))
                                .$sb
                            }
                            catch {
                                $e = $_
                                $this._log(
                                    "'$($s.Name)' Failed to invoke script! Error: $e",
                                    'InvokeScripts',
                                    'Warning'
                                )
                            }
                        }
                    }
                }
                else {
                    $this._log(
                        "'$p' Unable to resolve path!",
                        'FindProjects',
                        'Verbose'
                    )
                }
            }
        }
        else {
            $this._log(
                "No script paths specified to invoke!",
                'InvokeScripts',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'InvokeScripts',
            'Debug'
        )
    }
    hidden [void] _invokeInitScripts() {
        $this._log(
            "SECTION START",
            "InvokeInitScripts",
            "Debug"
        )
        $this.InitScripts.GetEnumerator() | ForEach-Object {
            $s = $_
            if ($_.Value.Enabled) {
                $this._log(
                    "Invoking Init Script: $($s.Key)",
                    "InvokeInitScripts",
                    "Verbose"
                )
                try {
                    $sb = [scriptblock]::Create($this._globalize($s.Value.ScriptBlock))
                    $newModuleArgs = @{
                        Name = "PSProfile.InitScript.$($s.Key)"
                        ScriptBlock = $sb
                        ReturnResult = $true
                    }
                    $this._log(
                        "'$($s.Key)' Importing dynamic InitScript module: $($newModuleArgs.Name)",
                        'InvokeInitScripts',
                        'Verbose'
                    )
                    New-Module @newModuleArgs | Import-Module -Global
                }
                catch {
                    $this._log(
                        "Error while invoking InitScript '$($s.Key)': $($_.Exception.Message)",
                        "InvokeInitScripts",
                        "Warning"
                    )
                }
            }
            else {
                $this._log(
                    "Skipping disabled Init Script: $($_.Key)",
                    "InvokeInitScripts",
                    "Verbose"
                )
            }
        }
        $this._log(
            "SECTION END",
            "InvokeInitScripts",
            "Debug"
        )
    }
    hidden [void] _installModules() {
        $this._log(
            "SECTION START",
            'InstallModules',
            'Debug'
        )
        if (-not [string]::IsNullOrEmpty((-join $this.ModulesToInstall))) {
            $null = $this.ModulesToInstall | Where-Object { ($_ -is [hashtable] -and $_.Name) -or ($_ -is [string] -and -not [string]::IsNullOrEmpty($_.Trim())) } | Start-RSJob -Name { "_PSProfile_InstallModule_$($_)" } -VariablesToImport this -ScriptBlock {
                Param (
                    [parameter()]
                    [object]
                    $Module
                )
                $params = if ($Module -is [string]) {
                    @{Name = $Module }
                }
                elseif ($Module -is [hashtable]) {
                    $Module
                }
                else {
                    $null
                }
                $this._log(
                    "Checking if module is installed already: $($params | ConvertTo-Json -Compress)",
                    'InstallModules',
                    'Verbose'
                )
                if ($null -eq (Get-Module $params['Name'] -ListAvailable)) {
                    $this._log(
                        "Installing missing module to CurrentUser scope: $($params | ConvertTo-Json -Compress)",
                        'InstallModules',
                        'Verbose'
                    )
                    Install-Module -Name @params -Scope CurrentUser -AllowClobber -SkipPublisherCheck
                }
                else {
                    $this._log(
                        "Module already installed, skipping: $($params | ConvertTo-Json -Compress)",
                        'InstallModules',
                        'Verbose'
                    )
                }
            }
        }
        else {
            $this._log(
                "No modules specified to install!",
                'InstallModules',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'InstallModules',
            'Debug'
        )
    }
    hidden [void] _importModules() {
        $this._log(
            "SECTION START",
            'ImportModules',
            'Debug'
        )
        if (-not [string]::IsNullOrEmpty((-join $this.ModulesToImport))) {
            $this.ModulesToImport | Where-Object { ($_ -is [hashtable] -and $_.Name) -or ($_ -is [string] -and -not [string]::IsNullOrEmpty($_.Trim())) } | ForEach-Object {
                try {
                    $params = if ($_ -is [string]) {
                        @{Name = $_ }
                    }
                    elseif ($_ -is [hashtable]) {
                        $_
                    }
                    else {
                        $null
                    }
                    if ($null -ne $params) {
                        @('ErrorAction','Verbose') | ForEach-Object {
                            if ($params.ContainsKey($_)) {
                                $params.Remove($_)
                            }
                        }
                        if ($params.Name -ne 'EditorServicesCommandSuite') {
                            Import-Module @params -Global -ErrorAction SilentlyContinue -Verbose:$false
                            $this._log(
                                "Module imported: $($params | ConvertTo-Json -Compress)",
                                'ImportModules',
                                'Verbose'
                            )
                        }
                        elseif ($params.Name -eq 'EditorServicesCommandSuite' -and $psEditor) {
                            Import-Module EditorServicesCommandSuite -ErrorAction SilentlyContinue -Global -Force -Verbose:$false
                            # Twice because: https://github.com/SeeminglyScience/EditorServicesCommandSuite/issues/40
                            Import-Module EditorServicesCommandSuite -ErrorAction SilentlyContinue -Global -Force -Verbose:$false
                            Import-EditorCommand -Module EditorServicesCommandSuite -Force -Verbose:$false
                            $this._log(
                                "Module imported: $($params | ConvertTo-Json -Compress)",
                                'ImportModules',
                                'Verbose'
                            )
                        }
                    }
                    else {
                        $this._log(
                            "Module must be either a string or a hashtable!",
                            'ImportModules',
                            'Verbose'
                        )
                    }
                }
                catch {
                    $this._log(
                        "'$($params['Name'])' Error importing module: $($_.Exception.Message)",
                        "ImportModules",
                        "Warning"
                    )
                }
            }
        }
        else {
            $this._log(
                "No modules specified to import!",
                'ImportModules',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'ImportModules',
            'Debug'
        )
    }
    hidden [void] _loadPlugins() {
        $this._log(
            "SECTION START",
            'LoadPlugins',
            'Debug'
        )
        if ($this.Plugins.Count) {
            $this.Plugins.ForEach( {
                    if ($_.Name -ne 'PSProfile.PowerTools') {
                        $plugin = $_
                        $this._log(
                            "'$($plugin.Name)' Searching for plugin",
                            'LoadPlugins',
                            'Verbose'
                        )
                        try {
                            $found = $null
                            $importParams = @{
                                ErrorAction = 'Stop'
                                Global      = $true
                            }
                            if ($plugin.ArgumentList) {
                                $importParams['ArgumentList'] = $plugin.ArgumentList
                            }
                            [string[]]$pathsToSearch = @($this.PluginPaths)
                            $env:PSModulePath.Split([System.IO.Path]::PathSeparator) | ForEach-Object {
                                $pathsToSearch += $_
                            }
                            foreach ($plugPath in $pathsToSearch) {
                                $fullPath = [System.IO.Path]::Combine($plugPath,"$($plugin.Name).ps1")
                                $paths = Get-ChildItem $plugPath -Filter "$($plugin.Name)*" | Where-Object {$_.Name -match "$($plugin.Name)\.psm*1$"}
                                if ($paths.Count -gt 1) {
                                    $fullPath = $paths.FullName | Where-Object {$_ -match 'psm1$'} | Select-Object -First 1
                                }
                                else {
                                    $fullPath = $paths.FullName | Select-Object -First 1
                                }
                                $this._log(
                                    "'$($plugin.Name)' Checking path: $fullPath",
                                    'LoadPlugins',
                                    'Debug'
                                )
                                if (Test-Path $fullPath) {
                                    $sb = [scriptblock]::Create($this._globalize(([System.IO.File]::ReadAllText($fullPath))))
                                    $newModuleArgs = @{
                                        Name = "PSProfile.Plugin.$($plugin.Name -replace '^PSProfile\.')"
                                        ScriptBlock = $sb
                                        ReturnResult = $true
                                    }
                                    if ($plugin.ArgumentList) {
                                        $newModuleArgs['ArgumentList'] = $plugin.ArgumentList
                                    }
                                    $this._log(
                                        "'$($plugin.Name)' Importing dynamic Plugin module: $($newModuleArgs.Name)",
                                        'LoadPlugins',
                                        'Verbose'
                                    )
                                    New-Module @newModuleArgs | Import-Module -Global
                                    $found = $fullPath
                                    break
                                }
                            }
                            if ($null -ne $found) {
                                $this._log(
                                    "'$($plugin.Name)' plugin loaded from path: $found",
                                    'LoadPlugins',
                                    'Verbose'
                                )
                            }
                            else {
                                if ($null -ne $plugin.Name -and $null -ne (Get-Module $plugin.Name -ListAvailable -ErrorAction SilentlyContinue)) {
                                    Import-Module $plugin.Name @importParams
                                    $this._log(
                                        "'$($plugin.Name)' plugin loaded from PSModulePath!",
                                        'LoadPlugins'
                                    )
                                }
                                else {
                                    $this._log(
                                        "'$($plugin.Name)' plugin not found! To remove this plugin from your profile, run 'Remove-PSProfilePlugin $($plugin.Name)'",
                                        'LoadPlugins',
                                        'Warning'
                                    )
                                }
                            }
                        }
                        catch {
                            throw
                        }
                    }
                })
        }
        else {
            $this._log(
                "No plugins specified to load!",
                'LoadPlugins',
                'Verbose'
            )
        }
        $this._log(
            "SECTION END",
            'LoadPlugins',
            'Debug'
        )
    }
    hidden [void] _log([string]$message,[string]$section,[PSProfileLogLevel]$logLevel) {
        $dt = Get-Date
        $shortMessage = "[$($dt.ToString('HH:mm:ss'))] $message"

        $lastCommand = if ($this.Log.Count) {
            $dt - $this.Log[-1].Time
        }
        else {
            New-TimeSpan
        }
        $this.Log.Add(
            [PSProfileEvent]::new(
                $dt,
                $lastCommand,
                ($dt - $this._internal.ProfileLoadStart),
                $logLevel,
                $section,
                $message
            )
        )
        switch ($logLevel) {
            Information {
                Write-Host $shortMessage
            }
            Verbose {
                Write-Verbose $shortMessage
            }
            Warning {
                Write-Warning $shortMessage
            }
            Error {
                Write-Error $shortMessage
            }
            Debug {
                Write-Debug $shortMessage
            }
        }
    }
    hidden [void] _log([string]$message,[string]$section) {
        $this._log($message,$section,'Quiet')
    }
}


function Get-DecryptedValue {
    param($Item)
    if ($Item -is [System.Security.SecureString]) {
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                $Item
            )
        )
    }
    else {
        $Item
    }
}


function Add-PSProfileCommandAlias {
    <#
    .SYNOPSIS
    Adds a command alias to your PSProfile configuration to set during PSProfile import.

    .DESCRIPTION
    Adds a command alias to your PSProfile configuration to set during PSProfile import.

    .PARAMETER Alias
    The alias to set for the command.

    .PARAMETER Command
    The name of the command to set the alias for.

    .PARAMETER Force
    If the alias already exists in $PSProfile.CommandAliases, use -Force to overwrite the existing value.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileCommandAlias -Alias code -Command Open-Code -Save

    Adds the command alias 'code' targeting the command 'Open-Code' and saves your PSProfile configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Alias,
        [Parameter(Mandatory,Position = 1)]
        [String]
        $Command,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($Force -or $Global:PSProfile.CommandAliases.Keys -notcontains $Alias) {
            New-Alias -Name $Alias -Value $Command -Option AllScope -Scope Global -Force
            Write-Verbose "Adding alias '$Alias' for command '$Command' to PSProfile"
            $Global:PSProfile.CommandAliases[$Alias] = $Command
            if ($Save) {
                Save-PSProfile
            }
        }
        else {
            Write-Error "Unable to add alias to `$PSProfile.CommandAliases as it already exists. Use -Force to overwrite the existing value if desired."
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileCommandAlias -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Command "$wordToComplete*").Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Add-PSProfileCommandAlias'

function Get-PSProfileCommandAlias {
    <#
    .SYNOPSIS
    Gets an alias from $PSProfile.CommandAliases.

    .DESCRIPTION
    Gets an alias from $PSProfile.CommandAliases.

    .PARAMETER Alias
    The alias to get from $PSProfile.CommandAliases.

    .EXAMPLE
    Get-PSProfileCommandAlias -Alias code

    Gets the alias 'code' from $PSProfile.CommandAliases.

    .EXAMPLE
    Get-PSProfileCommandAlias

    Gets the list of command aliases from $PSProfile.CommandAliases.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Alias
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Alias')) {
            Write-Verbose "Getting command alias '$Alias' from `$PSProfile.CommandAliases"
            $Global:PSProfile.CommandAliases.GetEnumerator() | Where-Object {$_.Key -in $Alias}
        }
        else {
            Write-Verbose "Getting all command aliases from `$PSProfile.CommandAliases"
            $Global:PSProfile.CommandAliases
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileCommandAlias -ParameterName Alias -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.CommandAliases.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileCommandAlias'

function Remove-PSProfileCommandAlias {
    <#
    .SYNOPSIS
    Removes an alias from $PSProfile.CommandAliases.

    .DESCRIPTION
    Removes an alias from $PSProfile.CommandAliases.

    .PARAMETER Alias
    The alias to remove from $PSProfile.CommandAliases.

    .PARAMETER Force
    If $true, also removes the alias itself from the session if it exists.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileCommandAlias -Alias code -Save

    Removes the alias 'code' from $PSProfile.CommandAliases then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Alias,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($al in $Alias) {
            if ($PSCmdlet.ShouldProcess("Removing '$al' from `$PSProfile.CommandAliases")) {
                Write-Verbose "Removing '$al' from `$PSProfile.CommandAliases"
                $Global:PSProfile.CommandAliases.Remove($al)
                if ($Force -and $null -ne (Get-Alias "$al*")) {
                    Write-Verbose "Removing Alias: $al"
                    Remove-Alias -Name $al -Force
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileCommandAlias -ParameterName Alias -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.CommandAliases.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileCommandAlias'

function Add-PSProfileConfigurationPath {
    <#
    .SYNOPSIS
    Adds a ConfigurationPath to your PSProfile to import during PSProfile load.

    .DESCRIPTION
    Adds a ConfigurationPath to your PSProfile to import during PSProfile load. Useful for synced configurations.

    .PARAMETER Path
    The path of the script to add to your $PSProfile.ConfigurationPaths.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileConfigurationPath -Path ~\SyncConfiguration.psd1 -Save

    Adds the configuration 'SyncConfiguration.ps1' to $PSProfile.ConfigurationPaths and saves the configuration after updating.

    .EXAMPLE
    Get-ChildItem .\PSProfileConfigurations -Recurse -File | Add-PSProfileConfigurationPath -Verbose

    Adds all psd1 files under the PSProfileConfigurations folder to $PSProfile.ConfigurationPaths but does not save to allow inspection. Call Save-PSProfile after to save the results if satisfied.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String[]]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($p in $Path) {
            if ($p -match '\.psd1$') {
                $fP = (Resolve-Path $p).Path
                if ($Global:PSProfile.ConfigurationPaths -notcontains $fP) {
                    Write-Verbose "Adding ConfigurationPath to PSProfile: $fP"
                    $Global:PSProfile.ConfigurationPaths += $fP
                }
                else {
                    Write-Verbose "ConfigurationPath already in PSProfile: $fP"
                }
            }
            else {
                Write-Verbose "Skipping non-psd1 file: $fP"
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileConfigurationPath'

function Export-PSProfileConfiguration {
    <#
    .SYNOPSIS
    Exports the PSProfile configuration as a PSD1 file to the desired path.

    .DESCRIPTION
    Exports the PSProfile configuration as a PSD1 file to the desired path.

    .PARAMETER Path
    The existing folder or file path with PSD1 extension to export the configuration to. If a folder path is provided, the configuration will be exported to the path with the file name 'PSProfile.Configuration.psd1'.

    .PARAMETER IncludeVault
    If $true, includes the Vault property as well so Secrets are also exported.

    .PARAMETER Force
    If $true and the resolved file path exists, overwrite it with the current configuration.

    .EXAMPLE
    Export-PSProfileConfiguration ~\MyPSProfileConfig.psd1

    Exports the configuration to the specified path.

    .EXAMPLE
    Export-PSProfileConfiguration ~\MyScripts -Force

    Exports the configuration to the resolved path of '~\MyScripts\PSProfile.Configuration.psd1' and overwrites the file if it already exists. The exported configuration does *not* include the Vault to prevent secrets from being migrated with the portable configuration that is exported.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [ValidateScript({
            if ($_ -like '*.psd1') {
                $true
            }
            elseif ((Test-Path $_) -and (Get-Item $_).PSIsContainer) {
                $true
            }
            else {
                throw "The path provided was not an existing folder path or a file path ending in a PSD1 extension. Please provide either an existing folder to export the PSProfile configuration to or an exact file path ending in a PSD1 extension to export the configuration to. Path provided: $_"
            }
        })]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $IncludeVault,
        [Parameter()]
        [Switch]
        $Force
    )
    Process {
        if (Test-Path $Path) {
            $item = Get-Item $Path
            if ($item.PSIsContainer) {
                $finalPath = [System.IO.Path]::Combine($item.FullName,'PSProfile.Configuration.psd1')
            }
            else {
                if ($item.Extension -ne '.psd1') {
                    Write-Error "Please provide either a file path for a psd1"
                }
                else {
                    $finalPath = $item.FullName
                }
            }
        }
        else {
            $finalPath = $Path
        }
        if ((Test-Path $finalPath) -and -not $Force) {
            Write-Error "File path already exists: $finalPath. Use the -Force parameter to overwrite the contents with the current PSProfile configuration."
        }
        else {
            try {
                if (Test-Path $finalPath) {
                    Write-Verbose "Force specified! Removing existing file: $finalPath"
                    Remove-Item $finalPath -ErrorAction Stop
                }
                Write-Verbose "Importing metadata from path: $($Global:PSProfile.Settings.ConfigurationPath)"
                $metadata = Import-Metadata -Path $Global:PSProfile.Settings.ConfigurationPath -ErrorAction Stop
                if (-not $IncludeVault -and $metadata.ContainsKey('Vault')) {
                    Write-Warning "Removing the Secrets Vault from the PSProfile configuration for safety. If you would like to export the configuration with the Vault included, use the -IncludeVault parameter with this function"
                    $metadata.Remove('Vault') | Out-Null
                    Write-Verbose "Exporting cleaned PSProfile configuration to path: $finalPath"
                }
                else {
                    Write-Verbose "Exporting PSProfile configuration to path: $finalPath"
                }
                $metadata | Export-Metadata -Path $finalPath -ErrorAction Stop
            }
            catch {
                Write-Error $_
            }
        }
    }
}


Export-ModuleMember -Function 'Export-PSProfileConfiguration'

function Get-PSProfileConfigurationPath {
    <#
    .SYNOPSIS
    Gets a configuration path from $PSProfile.ConfigurationPaths.

    .DESCRIPTION
    Gets a configuration path from $PSProfile.ConfigurationPaths.

    .PARAMETER Path
    The configuration path to get from $PSProfile.ConfigurationPaths.

    .EXAMPLE
    Get-PSProfileConfigurationPath -Path E:\Git\MyPSProfileConfig.psd1

    Gets the path 'E:\Git\MyPSProfileConfig.psd1' from $PSProfile.ConfigurationPaths

    .EXAMPLE
    Get-PSProfileConfigurationPath

    Gets the list of configuration paths from $PSProfile.ConfigurationPaths
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Path
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Path')) {
            Write-Verbose "Getting configuration path '$Path' from `$PSProfile.ConfigurationPaths"
            $Global:PSProfile.ConfigurationPaths | Where-Object {$_ -match "($(($Path | ForEach-Object {[regex]::Escape($_)}) -join '|'))"}
        }
        else {
            Write-Verbose "Getting all configuration paths from `$PSProfile.ConfigurationPaths"
            $Global:PSProfile.ConfigurationPaths
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileConfigurationPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ConfigurationPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileConfigurationPath'

function Import-PSProfile {
    <#
    .SYNOPSIS
    Reloads your PSProfile by running $PSProfile.Load()

    .DESCRIPTION
    Reloads your PSProfile by running $PSProfile.Load()

    .EXAMPLE
    Import-PSProfile

    .EXAMPLE
    Load-PSProfile
    #>
    [CmdletBinding()]
    Param()
    Process {
        Write-Verbose "Loading PSProfile configuration!"
        $global:PSProfile._loadConfiguration()
    }
}


Export-ModuleMember -Function 'Import-PSProfile'

function Import-PSProfileConfiguration {
    <#
    .SYNOPSIS
    Imports a Configuration.psd1 file from a specific path and overwrites differing values on the PSProfile, if any.

    .DESCRIPTION
    Imports a Configuration.psd1 file from a specific path and overwrites differing values on the PSProfile, if any.

    .PARAMETER Path
    The path to the PSD1 file you would like to import.

    .PARAMETER Save
    If $true, saves the updated PSProfile after importing.

    .EXAMPLE
    Import-PSProfileConfiguration -Path ~\MyProfile.psd1 -Save
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        $Path = (Resolve-Path $Path).Path
        Write-Verbose "Loading PSProfile configuration from path: $Path"
        $Global:PSProfile._loadAdditionalConfiguration($Path)
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Import-PSProfileConfiguration'

function Remove-PSProfileConfigurationPath {
    <#
    .SYNOPSIS
    Removes a configuration path from $PSProfile.ConfigurationPaths.

    .DESCRIPTION
    Removes a configuration path from $PSProfile.ConfigurationPaths.

    .PARAMETER Path
    The path to remove from $PSProfile.ConfigurationPaths.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileConfigurationPath -Name ~\PSProfile\MyConfig.psd1 -Save

    Removes the path '~\PSProfile\MyConfig.psd1' from $PSProfile.ConfigurationPaths then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Path' from `$PSProfile.ConfigurationPaths")) {
            Write-Verbose "Removing '$Path' from `$PSProfile.ConfigurationPaths"
            $Global:PSProfile.ConfigurationPaths = $Global:PSProfile.ConfigurationPaths | Where-Object {$_ -notin @($Path,(Resolve-Path $Path).Path)}
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileConfigurationPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ConfigurationPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileConfigurationPath'

function Save-PSProfile {
    <#
    .SYNOPSIS
    Saves the current PSProfile configuration by calling the $PSProfile.Save() method.

    .DESCRIPTION
    Saves the current PSProfile configuration by calling the $PSProfile.Save() method.

    .EXAMPLE
    Save-PSProfile
    #>
    [CmdletBinding()]
    Param()
    Process {
        Write-Verbose "Saving PSProfile configuration!"
        $global:PSProfile.Save()
    }
}


Export-ModuleMember -Function 'Save-PSProfile'

function Start-PSProfileConfigurationHelper {
    <#
    .SYNOPSIS
    Starts the PSProfile Configuration Helper.

    .DESCRIPTION
    Starts the PSProfile Configuration Helper.

    .EXAMPLE
    Start-PSProfileConfigurationHelper
    #>
    [CmdletBinding()]
    Param ()
    Process {
        Write-Verbose "Starting PSProfile Configuration Helper..."
        $color = @{
            Tip     = "Green"
            Command = "Cyan"
            Warning = "Yellow"
            Current = "Magenta"
        }
        $header = {
            param([string]$title)
            @(
                "----------------------------------"
                "| $($title.ToUpper())"
                "----------------------------------"
            ) -join "`n"
        }
        $changes = [System.Collections.Generic.List[string]]::new()
        $changeHash = @{ }
        $tip = {
            param([string]$text)
            "TIP: $text" | Write-Host -ForegroundColor $color['Tip']
        }
        $command = {
            param([string]$text)
            "COMMAND: $text" | Write-Host -ForegroundColor $color['Command']
        }
        $warning = {
            param([string]$text)
            Write-Warning -Message $text
        }
        $current = {
            param([string]$item)
            "EXISTING : $item" | Write-Host -ForegroundColor $color['Current']
        }
        $multi = {
            .$tip("This accepts multiple answers as comma-separated values, e.g. 1,2,5")
        }
        $exit = {
            "" | Write-Host
            .$header("Changes made to configuration")
            if ($changes.Count) {
                $changes | Write-Host
                "" | Write-Host
                "Would you like to save your updated PSProfile configuration?" | Write-Host
                $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                switch -Regex ($decision) {
                    "[Yy]" {
                        Save-PSProfile -Verbose
                    }
                }
            }
            else {
                "None!" | Write-Host
            }
            "`nExiting Configuration Helper`n" | Write-Host -ForegroundColor Yellow
            return
        }
        $legend = {
            "" | Write-Host
            .$header("Legend") | Write-Host
            .$tip("$($color['Tip']) - Helpful tips and tricks")
            .$command("$($color['Command']) - Commands to run to replicate the configuration update made")
            .$warning("$($color['Warning']) - Any warnings to be aware of")
            .$current("$($color['Current']) - Any existing configuration values for this section")
            "" | Write-Host
        }
        $menu = {
            "" | Write-Host
            .$header("Menu") | Write-Host
            $options = @(
                "Choose a PSProfile concept below to learn more and optionally update"
                "the configuration for it as well:"
                ""
                "[1]  Command Aliases"
                "[2]  Modules to Import"
                "[3]  Modules to Install"
                "[4]  Path Aliases"
                "[5]  Plugin Paths"
                "[6]  Plugins"
                "[7]  Project Paths"
                "[8]  Prompts"
                "[9]  Script Paths"
                "[10] Init Scripts"
                "[11] Secrets"
                "[12] Symbolic Links"
                "[13] Variables"
                ""
                "[14] Power Tools"
                "[15] Configuration"
                "[16] Helpers"
                "[17] Meta"
                ""
                "[*]  All concepts (Default)"
                "[H]  Hide Help Topics"
                ""
                "[X]  Exit"
                ""
            )
            $options | Write-Host
            .$multi
            "" | Write-Host
            Read-Host -Prompt "Enter your choice(s) (Default: *)"
        }

        @(
            ""
            "Welcome to PSProfile! This Configuration Helper serves as a way to jump-start"
            "your PSProfile configuration and increase your workflow productivity quickly."
            ""
            "You'll be asked a few questions to help with setting up your PSProfile,"
            "including being provided information around performing the same configuration"
            "tasks using the included functions after your initial setup is complete."
            ""
            "If you have any questions, comments or find any bugs, please open an issue"
            "on the PSProfile repo: https://github.com/scrthq/PSProfile/issues/new"
        ) | Write-Host
        .$legend
        $choices = .$menu
        if ([string]::IsNullOrEmpty($choices)) {
            $choices = '*'
        }
        $hideHelpTopics = if ($choices -match "[Hh]") {
            $true
        }
        else {
            $false
        }
        if ($choices -match "[Xx]") {
            .$exit
            return
        }
        else {
            "`nChoices:" | Write-Host
            if ($choices -match '\*') {
                $options | Select-String "^\[\*\]\s+" | Write-Host
                $resolved = @(1..17)
                if ($hideHelpTopics) {
                    $resolved += 'H'
                }
            }
            else {
                $resolved = $choices.Split(',').Trim() | Where-Object { -not [string]::IsNullOrEmpty($_) }
                $resolved | ForEach-Object {
                    $item = $_
                    $options | Select-String "^\[$item\]\s+" | Write-Host
                }
            }
            foreach ($choice in $resolved | Where-Object {$_ -ne 'H'}) {
                "" | Write-Host
                $topic = (($options | Select-String "^\[$choice\]\s+") -replace "^\[$choice\]\s+(.*$)",'$1').Trim()
                $helpTopic = 'about_PSProfile_' + ($topic -replace ' ','_')
                .$header($topic)
                if (-not $hideHelpTopics -or $choice -in 13..16) {
                    Write-Verbose "Getting the HelpTopic for this concept: $helpTopic"
                    Get-Help $helpTopic -Category HelpFile
                    .$tip("To view this conceptual HelpTopic at any time, run the following command:")
                    .$command("Get-Help $helpTopic")
                }
                "" | Write-Host
                switch ($choice) {
                    1 {
                        if ($Global:PSProfile.CommandAliases.Keys.Count) {
                            .$current("`n$(([PSCustomObject]$Global:PSProfile.CommandAliases | Format-List | Out-String).Trim())")
                        }
                        Write-Host "Would you like to add a Command Alias to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the command you would like to add an alias for (ex: Test-Path)"
                                    $item2 = Read-Host "Please enter the alias that you would like to set for the command (ex: tp)"
                                    if ($null -eq (Get-PSProfileCommandAlias -Alias $item2)) {
                                        if (-not $changeHash.ContainsKey('Command Aliases')) {
                                            $changes.Add("Command Aliases:")
                                            $changeHash['Command Aliases'] = @{ }
                                        }
                                        .$command("Add-PSProfileCommandAlias -Command '$item1' -Alias '$item2'")
                                        Add-PSProfileCommandAlias -Command $item1 -Alias $item2 -Verbose
                                        $changes.Add("  - Command: $item1")
                                        $changes.Add("    Alias: $item2")
                                        $changeHash['Command Aliases'][$item1] = $item2
                                    }
                                    else {
                                        .$warning("Command Alias '$item2' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileCommandAlias -Command '$item1' -Alias '$item2' -Force")
                                    }
                                    "`nWould you like to add another Command Alias to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    2 {
                        if ($Global:PSProfile.ModulesToImport.Count) {
                            .$current("`n- $((($Global:PSProfile.ModulesToImport|ForEach-Object{if($_ -is [hashtable]){$_.Name}else{$_}} | Sort-Object) -join "`n- "))")
                        }
                        Write-Host "Would you like to add a Module to Import to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the name of the module you would like to import during PSProfile load"
                                    if ($null -eq (Get-PSProfileModuleToImport -Name $item1)) {
                                        if (-not $changeHash.ContainsKey('Modules to Import')) {
                                            $changes.Add("Modules to Import:")
                                            $changeHash['Modules to Import'] = @()
                                        }
                                        .$command("Add-PSProfileModuleToImport -Name '$item1'")
                                        Add-PSProfileModuleToImport -Name $item1 -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Modules to Import'] += $item1
                                    }
                                    else {
                                        .$warning("Module to Import '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileModuleToImport -Name '$item1' -Force")
                                    }
                                    "`nWould you like to add another Module to Import to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    3 {
                        if ($Global:PSProfile.ModulesToInstall.Count) {
                            .$current("`n- $((($Global:PSProfile.ModulesToInstall|ForEach-Object{if($_ -is [hashtable]){$_.Name}else{$_}} | Sort-Object) -join "`n- "))")
                        }
                        Write-Host "Would you like to add a Module to Install to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the name of the module you would like to install via background job during PSProfile load"
                                    if ($null -eq (Get-PSProfileModuleToInstall -Name $item1)) {
                                        if (-not $changeHash.ContainsKey('Modules to Install')) {
                                            $changes.Add("Modules to Install:")
                                            $changeHash['Modules to Install'] = @()
                                        }
                                        .$command("Add-PSProfileModuleToInstall -Name '$item1'")
                                        Add-PSProfileModuleToInstall -Name $item1 -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Modules to Install'] += $item1
                                    }
                                    else {
                                        .$warning("Module to Install '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileModuleToInstall -Name '$item1' -Force")
                                    }
                                    "`nWould you like to add another Module to Install to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    4 {
                        if ($Global:PSProfile.PathAliases.Keys.Count) {
                            .$current("`n$(([PSCustomObject]$Global:PSProfile.PathAliases | Format-List | Out-String).Trim())")
                        }
                        Write-Host "Would you like to add a Path Alias to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path you would like to add an alias for (ex: C:\Users\$env:USERNAME)"
                                    $item2 = Read-Host "Please enter the alias that you would like to set for the path (ex: ~)"
                                    if ($null -eq (Get-PSProfilePathAlias -Alias $item2)) {
                                        if (-not $changeHash.ContainsKey('Path Aliases')) {
                                            $changes.Add("Path Aliases:")
                                            $changeHash['Path Aliases'] = @{ }
                                        }
                                        .$command("Add-PSProfilePathAlias -Path '$item1' -Alias '$item2'")
                                        Add-PSProfilePathAlias -Path $item1 -Alias $item2 -Verbose
                                        $changes.Add("  - Path: $item1")
                                        $changes.Add("    Alias: $item2")
                                        $changeHash['Path Aliases'][$item1] = $item2
                                    }
                                    else {
                                        .$warning("Path Alias '$item2' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfilePathAlias -Path '$item1' -Alias '$item2' -Force")
                                    }
                                    "`nWould you like to add another Path Alias to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    5 {
                        if ($Global:PSProfile.PluginPaths.Count) {
                            .$current("`n- $(($Global:PSProfile.PluginPaths | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add an additional Plugin Path to your PSProfile?"
                        .$tip("This is only needed if you have PSProfile plugins in a path outside of your normal PSModulePath")
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path to the additional plugin folder"
                                    if ($null -eq (Get-PSProfilePluginPath -Path $item1)) {
                                        if (-not $changeHash.ContainsKey('Plugin Paths')) {
                                            $changes.Add("Plugin Paths:")
                                            $changeHash['Plugin Paths'] = @()
                                        }
                                        .$command("Add-PSProfilePluginPath -Path '$item1'")
                                        Add-PSProfilePluginPath -Path $item1 -NoRefresh -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Plugin Paths'] += $item1
                                    }
                                    else {
                                        .$warning("Plugin Path '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfilePluginPath -Path '$item1' -Force")
                                    }
                                    "`nWould you like to add another Plugin Path to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    6 {
                        if ($Global:PSProfile.Plugins.Count) {
                            .$current("`n- $(($Global:PSProfile.Plugins.Name | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add a Plugin to your PSProfile?"
                        .$tip("Plugins can be either scripts or modules.")
                        .$tip("Use AD cmdlets? Try adding the plugin 'PSProfile.ADCompleters' to get tab-completion for the Properties parameter on Get-ADUser, Get-ADGroup, and Get-ADComputer!")
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the name of the plugin you would like to add (ex: PSProfile.ADCompleters)"
                                    if ($null -eq (Get-PSProfilePlugin -Name $item1)) {
                                        if (-not $changeHash.ContainsKey('Plugins')) {
                                            $changes.Add("Plugins:")
                                            $changeHash['Plugins'] = @()
                                        }
                                        .$command("Add-PSProfilePlugin -Name '$item1'")
                                        Add-PSProfilePlugin -Name $item1 -NoRefresh -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Plugins'] += $item1
                                    }
                                    else {
                                        .$warning("Plugin '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfilePlugin -Name '$item1' -Force")
                                    }
                                    "`nWould you like to add another Plugin to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    7 {
                        if ($Global:PSProfile.ProjectPaths.Count) {
                            .$current("`n- $(($Global:PSProfile.ProjectPaths | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add a Project Path to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path to the additional project folder"
                                    if ($null -eq (Get-PSProfileProjectPath -Path $item1)) {
                                        if (-not $changeHash.ContainsKey('Project Paths')) {
                                            $changes.Add("Project Paths:")
                                            $changeHash['Project Paths'] = @()
                                        }
                                        .$command("Add-PSProfileProjectPath -Path '$item1'")
                                        Add-PSProfileProjectPath -Path $item1 -NoRefresh -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Project Paths'] += $item1
                                    }
                                    else {
                                        .$warning("Project Path '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileProjectPath -Path '$item1' -Force")
                                    }
                                    "`nWould you like to add another Project Path to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    8 {
                        if ($Global:PSProfile.Prompts.Count) {
                            .$current("`n- $(($Global:PSProfile.Prompts.Keys | Sort-Object) -join "`n- ")")
                        }
                        if ($function:prompt -notmatch [Regex]::Escape('# https://go.microsoft.com/fwlink/?LinkID=225750')) {
                            "It looks like you are using a custom prompt! Would you like to save it to your PSProfile?" | Write-Host
                            $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                            $promptSaved = $false
                            do {
                                switch -Regex ($decision) {
                                    "[Yy]" {
                                        $item1 = Read-Host "Please enter a friendly name to save this prompt as (ex: MyPrompt)"
                                        if ($null -eq (Get-PSProfilePrompt -Name $item1)) {
                                            if (-not $changeHash.ContainsKey('Prompts')) {
                                                $changes.Add("Prompts:")
                                                $changeHash['Prompts'] = @()
                                            }
                                            .$command("Add-PSProfilePrompt -Name '$item1'")
                                            Add-PSProfilePrompt -Name $item1 -Verbose
                                            $changes.Add("  - $item1")
                                            $changeHash['Prompts'] += $item1
                                            $promptSaved = $true
                                        }
                                        else {
                                            .$warning("Prompt '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                            .$command("Add-PSProfilePrompt -Name '$item1' -Force")
                                            "`nWould you like to save your prompt as a different name?" | Write-Host
                                            $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                        }
                                    }
                                    "[Xx]" {
                                        .$exit
                                        return
                                    }
                                }
                            }
                            until ($promptSaved -or $decision -notmatch "[Yy]")
                        }
                        else {
                            "It looks like you are using the default prompt! Skipping prompt configuration for now." | Write-Host
                        }
                    }
                    9 {
                        if ($Global:PSProfile.ScriptPaths.Count) {
                            .$current("`n- $(($Global:PSProfile.ScriptPaths | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add a Script Path to your PSProfile?"
                        .$tip("Script paths are invoked during PSProfile load. If you are running any external scripts from your current profile script, this is where you would add them.")
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path of the additional script to add"
                                    if ($null -eq (Get-PSProfileScriptPath -Path $item1)) {
                                        if (-not $changeHash.ContainsKey('Script Paths')) {
                                            $changes.Add("Script Paths:")
                                            $changeHash['Script Paths'] = @()
                                        }
                                        .$command("Add-PSProfileScriptPath -Path '$item1'")
                                        Add-PSProfileScriptPath -Path $item1 -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Script Paths'] += $item1
                                    }
                                    else {
                                        .$warning("Script Path '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileScriptPath -Path '$item1' -Force")
                                    }
                                    "`nWould you like to add another Script Path to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    10 {
                        if ($Global:PSProfile.ScriptPaths.Count) {
                            .$current("`n- $(($Global:PSProfile.ScriptPaths | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add an external script as an Init Script on your PSProfile?"
                        .$tip("Init Scripts are also invoked during PSProfile load. These differ from Script Paths in that the full script is stored on the PSProfile configuration itself. Init Scripts can also be disabled without being removed from PSProfile.")
                        .$tip("During this Configuration Helper, you are limited to providing a path to a script file to import as an Init Script. While using Add-PSProfileInitScript, however, you can provide a ScriptBlock or Strings of code directly if preferred.")
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path of the script to import as Init Script"
                                    if ($null -eq (Get-PSProfileInitScript -Name (Get-Item $item1).BaseName)) {
                                        if (-not $changeHash.ContainsKey('Init Scripts')) {
                                            $changes.Add("Init Scripts:")
                                            $changeHash['Init Scripts'] = @()
                                        }
                                        .$command("Add-PSProfileInitScript -Path '$item1'")
                                        Add-PSProfileInitScript -Path $item1 -Verbose
                                        $changes.Add("  - $item1")
                                        $changeHash['Init Scripts'] += $item1
                                    }
                                    else {
                                        .$warning("Init Script '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileInitScript -Path '$item1' -Force")
                                    }
                                    "`nWould you like to import another Init Script to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    11 {
                        if (($Global:PSProfile.Vault._secrets.GetEnumerator() | Where-Object {$_.Key -ne 'GitCredentials'}).Count) {
                            .$current("`n- $((($Global:PSProfile.Vault._secrets.GetEnumerator() | Where-Object {$_.Key -ne 'GitCredentials'}).Key | Sort-Object) -join "`n- ")")
                        }
                        Write-Host "Would you like to add a Secret to your PSProfile Vault?"
                        .$tip("Vault Secrets can be either a PSCredential object or a SecureString such as an API key stored with a friendly name to recall them with.")
                        .$warning("Vault Secrets are encrypted using the Data Protection API, which is not as secure on non-Windows machines and unsupported in PowerShell 6.0-6.1. For more details, please see the Pull Request covering the topic where support was re-added in PowerShell Core: https://github.com/PowerShell/PowerShell/pull/9199")
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    do {
                                        "What type of Secret would you like to add?" | Write-Host
                                        $secretType = Read-Host "[P] PSCredential [S] SecureString [C] Cancel"
                                    }
                                    until ($secretType -match "[Pp|Ss|Cc]")
                                    if ($secretType -match "[Pp]") {
                                        "Please enter the credentials you would like to store in the Secrets Vault" | Write-Host
                                        $creds = Get-Credential
                                        if ($null -eq (Get-PSProfileSecret -Name $creds.UserName)) {
                                            if (-not $changeHash.ContainsKey('Secrets')) {
                                                $changes.Add("Secrets:")
                                                $changeHash['Secrets'] = @()
                                            }
                                            .$command("Add-PSProfileSecret -Credential (Get-Credential)")
                                            Add-PSProfileSecret -Credential $creds -Verbose
                                            $changes.Add("  - $($creds.UserName)")
                                            $changeHash['Secrets'] += $creds.UserName
                                        }
                                        else {
                                            .$warning("Secret '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                            .$command("Add-PSProfileSecret -Credential (Get-Credential) -Force")
                                        }
                                        "`nWould you like to add another Secret to your PSProfile Fault?" | Write-Host
                                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                    }
                                    elseif ($secretType -match "[Ss]") {
                                        $item1 = Read-Host "Please enter the name you would like to store the secret as (ex: SecretAPIKey)"
                                        $item2 = Read-Host -AsSecureString "Please enter the secret to store as a SecureString"
                                        if ($null -eq (Get-PSProfileSecret -Name $item1)) {
                                            if (-not $changeHash.ContainsKey('Secrets')) {
                                                $changes.Add("Secrets:")
                                                $changeHash['Secrets'] = @()
                                            }
                                            .$command("Add-PSProfileSecret -Name '$item1' -SecureString (Read-Host -AsSecureString 'Enter SecureString')")
                                            Add-PSProfileSecret -Name $item1 -SecureString $item2 -Verbose
                                            $changes.Add("  - $item1")
                                            $changeHash['Secrets'] += $item1
                                        }
                                        else {
                                            .$warning("Secret '$item1' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                            .$command("Add-PSProfileSecret -Name '$item1' -SecureString (Read-Host -AsSecureString 'Enter SecureString') -Force")
                                        }
                                        "`nWould you like to add another Secret to your PSProfile Fault?" | Write-Host
                                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                    }
                                    else {
                                        $decision = $secretType
                                    }
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    12 {
                        if ($Global:PSProfile.SymbolicLinks.Keys.Count) {
                            .$current("`n$(($Global:PSProfile.SymbolicLinks | Out-String).Trim())")
                        }
                        Write-Host "Would you like to add a Symbolic Link to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    $item1 = Read-Host "Please enter the path you would like to add an symbolic link for (ex: C:\Users\$env:USERNAME)"
                                    $item2 = Read-Host "Please enter the path of the symbolic link you would like to target the previous path with (ex: C:\Home)"
                                    if ($null -eq (Get-PSProfileSymbolicLink -LinkPath $item2)) {
                                        if (-not $changeHash.ContainsKey('Symbolic Links')) {
                                            $changes.Add("Symbolic Links:")
                                            $changeHash['Symbolic Links'] = @{ }
                                        }
                                        .$command("Add-PSProfileSymbolicLink -ActualPath '$item1' -LinkPath '$item2'")
                                        Add-PSProfileSymbolicLink -ActualPath $item1 -LinkPath $item2 -Verbose
                                        $changes.Add("  - ActualPath: $item1")
                                        $changes.Add("    LinkPath: $item2")
                                        $changeHash['Symbolic Links'][$item1] = $item2
                                    }
                                    else {
                                        .$warning("Symbolic Link '$item2' already exists on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileSymbolicLink -ActualPath '$item1' -LinkPath '$item2' -Force")
                                    }
                                    "`nWould you like to add another Symbolic Link to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    13 {
                        if ($Global:PSProfile.Variables.Environment.Keys.Count -or $Global:PSProfile.Variables.Global.Keys.Count) {
                            .$current("`n`n~~ ENVIRONMENT ~~`n$(($Global:PSProfile.Variables.Environment | Out-String).Trim())`n`n~~ GLOBAL ~~`n$(($Global:PSProfile.Variables.Global | Out-String).Trim())")
                        }
                        Write-Host "Would you like to add a Variable to your PSProfile?"
                        $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                        do {
                            switch -Regex ($decision) {
                                "[Yy]" {
                                    "Please enter the scope of the Variable to add" | Write-Host
                                    $s = Read-Host "[E] Environment [G] Global"
                                    $scope = switch -RegEx ($s) {
                                        "[Ee]" {
                                            'Environment'
                                        }
                                        "[Gg]" {
                                            'Global'
                                        }
                                    }
                                    $item1 = Read-Host "Please enter the name of the variable to add (ex: AWS_PROFILE)"
                                    $item2 = Read-Host "Please enter the value to set for variable '$item1' (ex: production)"
                                    if ($null -eq (Get-PSProfileVariable -Scope $scope -Name $item1)) {
                                        if (-not $changeHash.ContainsKey('Variables')) {
                                            $changes.Add("Variables:")
                                            $changeHash['Variables'] = @{
                                                Environment = @{}
                                                Global = @{}
                                            }
                                        }
                                        .$command("Add-PSProfileVariable -Scope '$scope' -Name '$item1' -Value '$item2'")
                                        Add-PSProfileVariable -Scope $scope -Name $item1 -Value $item2 -Verbose
                                        $changes.Add("  - Scope: $scope")
                                        $changes.Add("    Name: $item1")
                                        $changes.Add("    Value: $item2")
                                        $changeHash['Variables'][$scope][$item1] = $item2
                                    }
                                    else {
                                        .$warning("Variable '$item1' already exists at scope '$scope' on your PSProfile configuration! If you would like to overwrite it, run the following command:")
                                        .$command("Add-PSProfileVariable -Scope '$scope' -Name '$item1' -Value '$item2' -Force")
                                    }
                                    "`nWould you like to add another Variable to your PSProfile?" | Write-Host
                                    $decision = Read-Host "[Y] Yes [N] No [X] Exit"
                                }
                                "[Xx]" {
                                    .$exit
                                    return
                                }
                            }
                        }
                        until ($decision -notmatch "[Yy]")
                    }
                    14 {
                        "Power Tools functions do not alter the PSProfile configuration, so there is nothing to configure with this Helper! Please see the HelpTopic '$helpTopic' for more info:" | Write-Host
                        .$command("Get-Help $helpTopic")
                        "" | Write-Host
                        Read-Host "Press [Enter] to continue"
                    }
                    15 {
                        "Configuration functions are meant to interact with the PSProfile configuration directly, so there is nothing to configure with this Helper! Please see the HelpTopic '$helpTopic' for more info:" | Write-Host
                        .$command("Get-Help $helpTopic")
                        "" | Write-Host
                        Read-Host "Press [Enter] to continue"
                    }
                    16 {
                        "Helper functions are meant to interact for use within prompts or add Log Events to PSProfile, so there is nothing to configure with this Helper! Please see the HelpTopic '$helpTopic' for more info:" | Write-Host
                        .$command("Get-Help $helpTopic")
                        "" | Write-Host
                        Read-Host "Press [Enter] to continue"
                    }
                    17 {
                        "Meta functions are meant to provide information about PSProfile itself, so there is nothing to configure with this Helper! Please see the HelpTopic '$helpTopic' for more info:" | Write-Host
                        .$command("Get-Help $helpTopic")
                        "" | Write-Host
                        Read-Host "Press [Enter] to continue"
                    }
                }
            }
            .$exit
        }
    }
}


Export-ModuleMember -Function 'Start-PSProfileConfigurationHelper'

function Update-PSProfileConfig {
    <#
    .SYNOPSIS
    Force refreshes the current PSProfile configuration by calling the $PSProfile.Refresh() method.

    .DESCRIPTION
    Force refreshes the current PSProfile configuration by calling the $PSProfile.Refresh() method. This will update the GitPathMap with any new projects found and other tasks that don't run on every PSProfile load.

    .EXAMPLE
    Update-PSProfileConfig

    .EXAMPLE
    Refresh-PSProfile

    Uses the shorter alias command instead of the long command.
    #>
    [CmdletBinding()]
    Param()
    Process {
        Write-Verbose "Refreshing PSProfile config!"
        $global:PSProfile.Refresh()
    }
}


Export-ModuleMember -Function 'Update-PSProfileConfig'

function Update-PSProfileRefreshFrequency {
    <#
    .SYNOPSIS
    Sets the Refresh Frequency for PSProfile. The $PSProfile.Refresh() runs tasks that aren't run during every profile load, i.e. SymbolicLink creation, Git project path discovery, module installation, etc.

    .DESCRIPTION
    Sets the Refresh Frequency for PSProfile. The $PSProfile.Refresh() runs tasks that aren't run during every profile load, i.e. SymbolicLink creation, Git project path discovery, module installation, etc.

    .PARAMETER Timespan
    The frequency that you would like to refresh your PSProfile configuration. Refresh will occur during the profile load after the time since last refresh has surpassed the desired refresh frequency.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Update-PSProfileRefreshFrequency -Timespan '03:00:00' -Save

    Updates the RefreshFrequency to 3 hours and saves the PSProfile configuration after updating.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [timespan]
        $Timespan,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        Write-Verbose "Updating PSProfile RefreshFrequency to '$($Timespan.ToString())'"
        $Global:PSProfile.RefreshFrequency = $Timespan.ToString()
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Update-PSProfileRefreshFrequency'

function Update-PSProfileSetting {
    <#
    .SYNOPSIS
    Update a PSProfile property's value by tab-completing the available keys.

    .DESCRIPTION
    Update a PSProfile property's value by tab-completing the available keys.

    .PARAMETER Path
    The property path you would like to update, e.g. Settings.PSVersionStringLength

    .PARAMETER Value
    The value you would like to update for the specified setting path.

    .PARAMETER Add
    If $true, adds the value to the specified PSProfile setting value array instead of overwriting the current value.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Update-PSProfileSetting -Path Settings.PSVersionStringLength -Value 3 -Save

    Updates the PSVersionStringLength setting to 3 and saves the configuration.

    .EXAMPLE
    Update-PSProfileSetting -Path ScriptPaths -Value ~\ProfileLoad.ps1 -Add -Save

    *Adds* the 'ProfileLoad.ps1' script to the $PSProfile.ScriptPaths array of scripts to invoke during profile load, then saves the configuration.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Path,
        [Parameter(Mandatory,Position = 1)]
        [object]
        $Value,
        [Parameter()]
        [switch]
        $Add,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        Write-Verbose "Updating PSProfile.$Path with value '$Value'"
        $split = $Path.Split('.')
        switch ($split.Count) {
            5 {
                if ($Add) {
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])"."$($split[4])" += $Value
                }
                else {
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])"."$($split[4])" = $Value
                }
            }
            4 {
                if ($Add) {
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])" += $Value
                }
                else{
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])" = $Value
                }
            }
            3 {
                if ($Add) {
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])" += $Value
                }
                else{
                    $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])" = $Value
                }
            }
            2 {
                if ($Add) {
                    $Global:PSProfile."$($split[0])"."$($split[1])" += $Value
                }
                else{
                    $Global:PSProfile."$($split[0])"."$($split[1])" = $Value
                }
            }
            1 {
                if ($Add) {
                    $Global:PSProfile.$Path += $Value
                }
                else{
                    $Global:PSProfile.$Path = $Value
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Update-PSProfileSetting -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments @PSBoundParameters
}

Register-ArgumentCompleter -CommandName Update-PSProfileSetting -ParameterName Value -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    if ($fakeBoundParameter.Path -eq 'Settings.FontType') {
        @('Default','NerdFonts','PowerLine') | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}


Export-ModuleMember -Function 'Update-PSProfileSetting'

function Add-PSProfileToProfile {
    <#
    .SYNOPSIS
    Adds `Import-Module PSProfile` to the desired PowerShell profile file if not already present.

    .DESCRIPTION
    Adds `Import-Module PSProfile` to the desired PowerShell profile file if not already present.

    .PARAMETER Scope
    The profile scope to add the module import to. Defaults to CurrentUserCurrentHost (same as bare $profile).

    .PARAMETER DisableLoadTimeMessage
    If $true, adds `-ArgumentList $false` to the Import-Module call to hide the Module Load Time message.

    .EXAMPLE
    Add-PSProfileToProfile -Scope CurrentUserAllHosts

    Adds `Import-Module PSProfile` to the $profile.CurrentUserAllHosts file. Creates the parent folder if missing.

    .EXAMPLE
    Add-PSProfileToProfile -DisableLoadTimeMessage

    Adds `Import-Module PSProfile -ArgumentList $false` to the $profile file. Creates the parent folder if missing.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0)]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String]
        $Scope = 'CurrentUserCurrentHost',
        [Parameter()]
        [Switch]
        $DisableLoadTimeMessage
    )
    Process {
        $exists = $false
        foreach ($s in @('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')) {
            $sPath = $profile | Select-Object -ExpandProperty $s
            if ((Test-Path $sPath) -and (Select-String -Path $sPath -Pattern ([Regex]::Escape('Import-Module PSProfile')))) {
                Write-Warning "'Import-Module PSProfile' already exists @ profile scope '$s' ($sPath)! Skipping addition @ scope '$Scope' to prevent duplicate module imports."
                $exists = $true
            }
        }
        if (-not $exists) {
            $profilePath = $profile | Select-Object -ExpandProperty $Scope
            $profileFolder = Split-Path $profilePath
            if (-not (Test-Path $profileFolder)) {
                Write-Verbose "Creating parent folder: $profileFolder"
                New-Item $profileFolder -ItemType Directory -Force
            }
            if (-not (Test-Path $profilePath)) {
                Write-Verbose "Creating profile file: $profilePath"
                New-Item $profilePath -ItemType File -Force
            }
            $string = 'Import-Module PSProfile'
            if ($DisableLoadTimeMessage) {
                $string += ' -ArgumentList $false'
            }
            Write-Verbose "Adding line to profile @ scope '$Scope': $string"
            Add-Content -Path $profilePath -Value $string
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileToProfile'

function Copy-Parameters {
    <#
    .SYNOPSIS
    Copies parameters from a file or function and returns a RuntimeDefinedParameterDictionary with the copied parameters. Used in DynamicParam blocks.

    .DESCRIPTION
    Copies parameters from a file or function and returns a RuntimeDefinedParameterDictionary with the copied parameters. Used in DynamicParam blocks.

    .PARAMETER From
    The file or function to copy parameters from.

    .PARAMETER Exclude
    The parameter or list of parameters to exclude from replicating into the returned Dictionary.

    .EXAMPLE
    function Start-Build {
        [CmdletBinding()]
        Param ()
        DynamicParam {
            Copy-Parameters -From ".\build.ps1"
        }
        Process {
            #Function logic
        }
    }

    Replicates the parameters from the build.ps1 script into the Start-Build function.
    #>
    [OutputType('System.Management.Automation.RuntimeDefinedParameterDictionary')]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [Alias('File','Function')]
        [String]
        $From,
        [Parameter()]
        [Alias('ExcludeParameter')]
        [String[]]
        $Exclude = @()
    )
    try {
        $targetCmd = Get-Command $From
        $params = @($targetCmd.Parameters.GetEnumerator() | Where-Object { $_.Key -notin $Exclude })
        if ($params.Length -gt 0) {
            $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
            foreach ($param in $params) {
                try {
                    if (-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Key)) {
                        Write-Verbose "Copying parameter: $($param.Key)"
                        $paramVal = $param.Value
                        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                            $paramVal.Name,
                            $paramVal.ParameterType,
                            $paramVal.Attributes
                        )
                        $paramDictionary.Add($paramVal.Name, $dynParam)
                    }
                }
                catch {
                    $Global:Error.Remove($Global:Error[0])
                }
            }
            return $paramDictionary
        }
    }
    catch {
        $Global:Error.Remove($Global:Error[0])
    }
}

Register-ArgumentCompleter -CommandName Copy-Parameters -ParameterName Exclude -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $set = if (-not [String]::IsNullOrEmpty($fakeBoundParameter.From)) {
        ([System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Command $fakeBoundParameter.From).Definition, [ref]$null, [ref]$null
        )).ParamBlock.Parameters.Name.VariablePath.UserPath
    }
    else {
        @()
    }
    $set | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Copy-Parameters'

function Get-LastCommandDuration {
    <#
    .SYNOPSIS
    Gets the elapsed time of the last command via Get-History. Intended to be used in prompts.

    .DESCRIPTION
    Gets the elapsed time of the last command via Get-History. Intended to be used in prompts.

    .PARAMETER Id
    The Id of the command to get from the history.

    .PARAMETER Format
    The format string for the resulting timestamp.

    .EXAMPLE
    Get-LastCommandDuration
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]
        $Id,
        [Parameter()]
        [string]
        $Format = "{0:h\:mm\:ss\.ffff}"
    )
    $null = $PSBoundParameters.Remove("Format")
    $LastCommand = Get-History -Count 1 @PSBoundParameters
    if (!$LastCommand) {
        return "0:00:00.0000"
    }
    elseif ($null -ne $LastCommand.Duration) {
        $Format -f $LastCommand.Duration
    }
    else {
        $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
        $Format -f $Duration
    }
}


Export-ModuleMember -Function 'Get-LastCommandDuration'

function Get-PathAlias {
    <#
    .SYNOPSIS
    Gets the Path alias using either the short name from $PSProfile.GitPathMap or a path alias stored in $PSProfile.PathAliases, falls back to using a shortened version of the root drive + current directory.

    .DESCRIPTION
    Gets the Path alias using either the short name from $PSProfile.GitPathMap or a path alias stored in $PSProfile.PathAliases, falls back to using a shortened version of the root drive + current directory.

    .PARAMETER Path
    The full path to get the PathAlias for. Defaults to $PWD.Path

    .PARAMETER DirectorySeparator
    The desired DirectorySeparator character. Defaults to $global:PathAliasDirectorySeparator if present, falls back to [System.IO.Path]::DirectorySeparatorChar if not.

    .EXAMPLE
    Get-PathAlias
    #>
    [CmdletBinding()]
    Param (
        [parameter(Position = 0)]
        [string]
        $Path = $PWD.Path,
        [parameter(Position = 1)]
        [string]
        $DirectorySeparator = $(if ($null -ne $global:PathAliasDirectorySeparator) {
            $global:PathAliasDirectorySeparator
        }
        else {
            [System.IO.Path]::DirectorySeparatorChar
        })
    )
    Begin {
        try {
            $origPath = $Path
            if ($null -eq $global:PSProfile) {
                $global:PSProfile = @{
                    Settings     = @{
                        PSVersionStringLength = 3
                    }
                    PathAliasMap = @{
                        '~' = $env:USERPROFILE
                    }
                }
            }
            elseif ($null -eq $global:PSProfile._internal) {
                $global:PSProfile._internal = @{
                    PathAliasMap = @{
                        '~' = $env:USERPROFILE
                    }
                }
            }
            elseif ($null -eq $global:PSProfile._internal.PathAliasMap) {
                $global:PSProfile._internal.PathAliasMap = @{
                    '~' = $env:USERPROFILE
                }
            }
            if ($gitRepo = Test-IfGit) {
                $gitIcon = if ($global:PSProfile.Settings.ContainsKey('FontType')) {
                    $global:PSProfile.Settings.PromptCharacters.GitRepo[$global:PSProfile.Settings.FontType]
                }
                else {
                    '@'
                }
                if ([String]::IsNullOrEmpty($gitIcon)) {
                    $gitIcon = '@'
                }
                $key = $gitIcon + $gitRepo.Repo
                if (-not $global:PSProfile._internal.PathAliasMap.ContainsKey($key)) {
                    $global:PSProfile._internal.PathAliasMap[$key] = $gitRepo.TopLevel
                }
            }
            $leaf = Split-Path $Path -Leaf
            if (-not $global:PSProfile._internal.PathAliasMap.ContainsKey('~')) {
                $global:PSProfile._internal.PathAliasMap['~'] = $env:USERPROFILE
            }
            Write-Verbose "Alias map => JSON: $($global:PSProfile._internal.PathAliasMap | ConvertTo-Json -Depth 5)"
            $aliasKey = $null
            $aliasValue = $null
            foreach ($hash in $global:PSProfile._internal.PathAliasMap.GetEnumerator() | Sort-Object { $_.Value.Length } -Descending) {
                if ($Path -like "$($hash.Value)*") {
                    $Path = $Path.Replace($hash.Value,$hash.Key)
                    $aliasKey = $hash.Key
                    $aliasValue = $hash.Value
                    Write-Verbose "AliasKey [$aliasKey] || AliasValue [$aliasValue]"
                    break
                }
            }
        }
        catch {
            Write-Error $_
            return $origPath
        }
    }
    Process {
        try {
            if ($null -ne $aliasKey -and $origPath -eq $aliasValue) {
                Write-Verbose "Matched original path! Returning alias base path"
                $finalPath = $Path
            }
            elseif ($null -ne $aliasKey) {
                Write-Verbose "Matched alias key [$aliasKey]! Returning path alias with leaf"
                $drive = "$($aliasKey)\"
                $finalPath = if ((Split-Path $origPath -Parent) -eq $aliasValue) {
                    "$($drive)$($leaf)"
                }
                else {
                    "$($drive)$([char]0x2026)\$($leaf)"
                }
            }
            else {
                $drive = (Get-Location).Drive.Name + ':\'
                Write-Verbose "Matched base drive [$drive]! Returning base path"
                $finalPath = if ($Path -eq $drive) {
                    $drive
                }
                elseif ((Split-Path $Path -Parent) -eq $drive) {
                    "$($drive)$($leaf)"
                }
                else {
                    "$($drive)..\$($leaf)"
                }
            }
            if ($DirectorySeparator -notin @($null,([System.IO.Path]::DirectorySeparatorChar))) {
                $finalPath.Replace(([System.IO.Path]::DirectorySeparatorChar),$DirectorySeparator)
            }
            else {
                $finalPath
            }
        }
        catch {
            Write-Error $_
            return $origPath
        }
    }
}


Export-ModuleMember -Function 'Get-PathAlias'

function Get-PSProfileArguments {
    <#
    .SYNOPSIS
    Used for PSProfile Plugins to provide easy Argument Completers using PSProfile constructs.

    .DESCRIPTION
    Used for PSProfile Plugins to provide easy Argument Completers using PSProfile constructs.

    .PARAMETER FinalKeyOnly
    Returns only the final key of the completed argument to the list of completers. If $false, returns the full path.

    .PARAMETER WordToComplete
    The word to complete, typically passed in from the scriptblock arguments.

    .PARAMETER CommandName
    Here to allow passing @PSBoundParameters directly to this function from Register-ArgumentCompleter

    .PARAMETER ParameterName
    Here to allow passing @PSBoundParameters directly to this function from Register-ArgumentCompleter

    .PARAMETER CommandAst
    Here to allow passing @PSBoundParameters directly to this function from Register-ArgumentCompleter

    .PARAMETER FakeBoundParameter
    Here to allow passing @PSBoundParameters directly to this function from Register-ArgumentCompleter

    .EXAMPLE
    Get-PSProfileArguments -WordToComplete "Prompts.$wordToComplete" -FinalKeyOnly

    Gets the list of prompt names under the Prompts PSProfile primary key.

    .EXAMPLE
    Get-PSProfileArguments -WordToComplete "GitPathMap.$wordToComplete" -FinalKeyOnly

    Gets the list of Git Path short names under the GitPathMap PSProfile primary key.
    #>
    [OutputType('System.Management.Automation.CompletionResult')]
    [CmdletBinding()]
    Param(
        [switch]
        $FinalKeyOnly,
        [string]
        $WordToComplete,
        [object]
        $CommandName,
        [object]
        $ParameterName,
        [object]
        $CommandAst,
        [object]
        $FakeBoundParameter
    )
    Process {
        Write-Verbose "Getting PSProfile command argument completions"
        $split = $WordToComplete.Split('.')
        $setting = $null
        switch ($split.Count) {
            5 {
                $setting = $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])"
                $base = "$($split[0])"."$($split[1])"."$($split[2])"."$($split[3])"
            }
            4 {
                $setting = $Global:PSProfile."$($split[0])"."$($split[1])"."$($split[2])"
                $base = "$($split[0])"."$($split[1])"."$($split[2])"
            }
            3 {
                $setting = $Global:PSProfile."$($split[0])"."$($split[1])"
                $base = "$($split[0])"."$($split[1])"
            }
            2 {
                $setting = $Global:PSProfile."$($split[0])"
                $base = $split[0]
            }
        }
        if ($null -eq $setting) {
            $setting = $Global:PSProfile
            $base = $null
            $final = $WordToComplete
        }
        else {
            $final = $split | Select-Object -Last 1
        }
        if ($setting.GetType() -notin @([string],[int],[long],[version],[timespan],[datetime],[bool])) {
            $props = if ($setting.PSTypeNames -match 'Hashtable') {
                $setting.Keys | Where-Object {$_ -ne '_internal' -and $_ -like "$final*"} | Sort-Object
            }
            else {
                ($setting | Get-Member -MemberType Property,NoteProperty).Name | Where-Object {$_ -notmatch '^_' -and $_ -like "$final*"} | Sort-Object
            }
            $props | ForEach-Object {
                $result = if (-not $FinalKeyOnly -and $null -ne $base) {
                    @($base,$_) -join "."
                }
                else {
                    $_
                }
                $completionText = if ($result -match '[\s,]') {
                    "'$result'"
                }
                 else {
                     $result
                 }
                [System.Management.Automation.CompletionResult]::new($completionText, $result, 'ParameterValue', $result)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileArguments -ParameterName WordToComplete -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments @PSBoundParameters
}


Export-ModuleMember -Function 'Get-PSProfileArguments'

function Get-PSVersion {
    <#
    .SYNOPSIS
    Gets the short formatted PSVersion string for use in a prompt or wherever else desired.

    .DESCRIPTION
    Gets the short formatted PSVersion string for use in a prompt or wherever else desired.

    .PARAMETER Places
    How many decimal places you would like the returned version string to be. Defaults to $PSProfile.Settings.PSVersionStringLength if present.

    .EXAMPLE
    Get-PSVersion -Places 2

    Returns `6.2` when using PowerShell 6.2.2, or `5.1` when using Windows PowerShell 5.1.18362.10000
    #>

    [OutputType('System.String')]
    [CmdletBinding()]
    Param (
        [parameter(Position = 0)]
        [AllowNull()]
        [int]
        $Places = $global:PSProfile.Settings.PSVersionStringLength
    )
    Process {
        $version = $PSVersionTable.PSVersion.ToString()
        if ($null -ne $Places) {
            $split = ($version -split '\.')[0..($Places - 1)]
            if ("$($split[-1])".Length -gt 1) {
                $split[-1] = "$($split[-1])".Substring(0,1)
            }
            $joined = $split -join '.'
            if ($version -match '[a-zA-Z]+') {
                $joined += "-$(($Matches[0]).Substring(0,1))"
                if ($version -match '\d+$') {
                    $joined += $Matches[0]
                }
            }
            $joined
        }
        else {
            $version
        }
    }
}


Export-ModuleMember -Function 'Get-PSVersion'

function Test-IfGit {
    <#
    .SYNOPSIS
    Tests if the current path is in a Git repo folder and returns the basic details as an object if so. Useful in prompts when determining current folder's Git status

    .DESCRIPTION
    Tests if the current path is in a Git repo folder and returns the basic details as an object if so. Useful in prompts when determining current folder's Git status

    .EXAMPLE
    Test-IfGit
    #>
    [CmdletBinding()]
    Param ()
    Process {
        try {
            $topLevel = git rev-parse --show-toplevel *>&1
            if ($topLevel -like 'fatal: *') {
                $Global:Error.Remove($Global:Error[0])
                $false
            }
            else {
                $origin = git remote get-url origin
                $repo = Split-Path -Leaf $origin
                [PSCustomObject]@{
                    TopLevel = (Resolve-Path $topLevel).Path
                    Origin   = $origin
                    Repo     = $(if ($repo -notmatch '(\.git|\.ssh|\.tfs)$') {
                            $repo
                        }
                        else {
                            $repo.Substring(0,($repo.LastIndexOf('.')))
                        })
                }
            }
        }
        catch {
            $false
            $Global:Error.Remove($Global:Error[0])
        }
    }
}


Export-ModuleMember -Function 'Test-IfGit'

function Write-PSProfileLog {
    <#
    .SYNOPSIS
    Adds a log entry to the current PSProfile Log.

    .DESCRIPTION
    Adds a log entry to the current PSProfile Log. Used for external plugins to hook into the existing log so items like Plugin load logging are contained in one place.

    .PARAMETER Message
    The message to log.

    .PARAMETER Section
    The name of the section you are logging for, e.g. the name of the plugin or overall what action is being done.

    .PARAMETER LogLevel
    The Level of the Log event. Defaults to Debug.

    .EXAMPLE
    Write-PSProfileLog -Message "Hunting for missing KBs" -Section 'KBUpdate' -LogLevel 'Verbose'
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Message,
        [Parameter(Mandatory,Position = 1)]
        [String]
        $Section,
        [Parameter(Position = 2)]
        [PSProfileLogLevel]
        $LogLevel = 'Debug'
    )
    Process {
        $Global:PSProfile._log(
            $Message,
            $Section,
            $LogLevel
        )
    }
}


Export-ModuleMember -Function 'Write-PSProfileLog'

function Add-PSProfileInitScript {
    <#
    .SYNOPSIS
    Adds script contents to your PSProfile configuration directly. Contents will be invoked during PSProfile import. Useful for scripts that you want to include directly on your configuration for portability instead of calling as an external script via $PSProfile.ScriptPaths.

    .DESCRIPTION
    Adds script contents to your PSProfile configuration directly. Contents will be invoked during PSProfile import. Useful for scripts that you want to include directly on your configuration for portability instead of calling as an external script via $PSProfile.ScriptPaths.

    .PARAMETER Name
    The friendly name to reference the script block by.

    .PARAMETER Content
    The content of the script as a string, i.e. if using `Get-Content` against another file to pass as the value here.

    .PARAMETER ScriptBlock
    The content of the script as a scriptblock. Useful if you are adding as script manually

    .PARAMETER Path
    The path to an external PS1 file to import the contents to your $PSProfile.InitScripts directly. When using Path, the file's BaseName becomes the Name value.

    .PARAMETER State
    Whether the InitScript should be Enabled or Disabled. Defaults to Enabled.

    .PARAMETER RemoveDuplicateScriptPaths
    If a specified Path is also in $PSProfile.ScriptPaths, remove it from there to prevent duplicate scripts from being invoked during PSProfile import.

    .PARAMETER Force
    If the InitScript name already exists in $PSProfile.InitScripts, use -Force to overwrite the existing value.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Get-PSProfileScriptPath | Add-PSProfileInitScript
    #>

    [CmdletBinding(DefaultParameterSetName = 'Content')]
    Param(
        [Parameter(Mandatory,Position = 0,ParameterSetName = 'Content')]
        [Parameter(Mandatory,Position = 0,ParameterSetName = 'ScriptBlock')]
        [String]
        $Name,
        [Parameter(Mandatory,Position = 1,ParameterSetName = 'Content')]
        [String[]]
        $Content,
        [Parameter(Mandatory,Position = 1,ParameterSetName = 'ScriptBlock')]
        [ScriptBlock]
        $ScriptBlock,
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName = 'Path')]
        [Alias('FullName')]
        [String[]]
        $Path,
        [Parameter()]
        [ValidateSet('Enabled','Disabled')]
        [String]
        $State = 'Enabled',
        [Parameter(ParameterSetName = 'Path')]
        [Switch]
        $RemoveDuplicateScriptPaths,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            Content {
                if (-not $Force -and $Global:PSProfile.InitScripts.Contains($Name)) {
                    Write-Error "Unable to add Init Script '$Name' to `$PSProfile.InitScripts as it already exists. Use -Force to overwrite the existing value if desired."
                }
                else {
                    Write-Verbose "Adding InitScript '$Name' from Contents to PSProfile configuration"
                    $Global:PSProfile.InitScripts[$Name] = @{
                        Enabled = ($State -eq 'Enabled')
                        ScriptBlock = ($Content -join "`n").Trim()
                    }
                }
            }
            ScriptBlock {
                if (-not $Force -and $Global:PSProfile.InitScripts.Contains($Name)) {
                    Write-Error "Unable to add Init Script '$Name' to `$PSProfile.InitScripts as it already exists. Use -Force to overwrite the existing value if desired."
                }
                else {
                    Write-Verbose "Adding InitScript '$Name' from ScriptBlock to PSProfile configuration"
                    $Global:PSProfile.InitScripts[$Name] = @{
                        Enabled = ($State -eq 'Enabled')
                        ScriptBlock = $ScriptBlock.ToString().Trim()
                    }
                }
            }
            Path {
                $Path | Where-Object {$_ -match '\.ps1$'} | ForEach-Object {
                    $item = Get-Item $_
                    $N = $item.BaseName
                    if (-not $Force -and $Global:PSProfile.InitScripts.Contains($N)) {
                        Write-Error "Unable to add Init Script '$N' to `$PSProfile.InitScripts as it already exists. Use -Force to overwrite the existing value if desired."
                    }
                    else {
                        Write-Verbose "Adding InitScript '$N' from Path '$($item.FullName)' to PSProfile configuration"
                        $Global:PSProfile.InitScripts[$N] = @{
                            Enabled = ($State -eq 'Enabled')
                            ScriptBlock = ((Get-Content $_) -join "`n").Trim()
                        }
                        if ($RemoveDuplicateScriptPaths -and (Get-PSProfileScriptPath) -contains $item.FullName) {
                            Remove-PSProfileScriptPath -Path $item.FullName -Confirm:$false
                        }
                    }
                }
            }
        }
    }
    End {
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileInitScript'

function Disable-PSProfileInitScript {
    <#
    .SYNOPSIS
    Disables an enabled InitScript in $PSProfile.InitScripts.

    .DESCRIPTION
    Disables an enabled InitScript in $PSProfile.InitScripts.

    .PARAMETER Name
    The name of the InitScript to disable in $PSProfile.InitScripts.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Disable-PSProfileInitScript -Name PSReadlineSettings,DevOpsTools

    Disables the InitScripts 'PSReadlineSettings' and 'DevOpsTools' in $PSProfile.InitScripts.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($N in $Name) {
            Write-Verbose "Disabling InitScript '$N' in `$PSProfile.InitScripts"
            if ($Global:PSProfile.InitScripts.Contains($N)) {
                $Global:PSProfile.InitScripts[$N]['Enabled'] = $false
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Disable-PSProfileInitScript -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.InitScripts.GetEnumerator() | Where-Object {$_.Value.Enabled -and $_.Key -like "$wordToComplete*"} | Select-Object -ExpandProperty Key | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Disable-PSProfileInitScript'

function Edit-PSProfileInitScript {
    <#
    .SYNOPSIS
    Edit an InitScript from $PSProfile.InitScripts in Visual Studio Code.

    .DESCRIPTION
    Edit an InitScript from $PSProfile.InitScripts in Visual Studio Code.

    .PARAMETER Name
    The name of the InitScript to edit from $PSProfile.InitScripts.

    .PARAMETER WithInsiders
    If $true, looks for VS Code Insiders to load. If $true and code-insiders cannot be found, opens the file using VS Code stable. If $false, opens the file using VS Code stable. Defaults to $false.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileInitScript -Name PSReadlineSettings,DevOpsTools

    Removes the InitScripts 'PSReadlineSettings' and 'DevOpsTools' from $PSProfile.InitScripts.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [String[]]
        $Name,
        [Alias('wi')]
        [Alias('insiders')]
        [Switch]
        $WithInsiders,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        $code = $null
        $codeCommand = if($WithInsiders) {
            @('code-insiders','code')
        }
        else {
            @('code','code-insiders')
        }
        foreach ($cmd in $codeCommand) {
            try {
                if ($found = (Get-Command $cmd -All -ErrorAction Stop | Where-Object { $_.CommandType -notin @('Function','Alias') } | Select-Object -First 1 -ExpandProperty Source)) {
                    $code = $found
                    break
                }
            }
            catch {
                $Global:Error.Remove($Global:Error[0])
            }
        }
        if ($null -eq $code){
            throw "Editor not found!"
        }
        foreach ($initScript in $Name) {
            if ($Global:PSProfile.InitScripts.Contains($initScript)) {
                $in = @{
                    StdIn   = $Global:PSProfile.InitScripts[$initScript].ScriptBlock
                    TmpFile = [System.IO.Path]::Combine(([System.IO.Path]::GetTempPath()),"InitScript-$($initScript)-$(-join ((97..(97+25)|%{[char]$_}) | Get-Random -Count 3)).ps1")
                    Editor  = $code
                }
                $handler = {
                    Param(
                        [hashtable]
                        $in
                    )
                    try {
                        $in.StdIn | Set-Content $in.TmpFile -Force
                        & $in.Editor $in.TmpFile --wait
                    }
                    catch {
                        throw
                    }
                    finally {
                        if (Test-Path $in.TmpFile -ErrorAction SilentlyContinue) {
                            [System.IO.File]::ReadAllText($in.TmpFile)
                            Remove-Item $in.TmpFile -Force
                        }
                    }
                }
                Write-Verbose "Editing InitScript '$initScript' in Visual Studio Code, waiting for file to close"
                if ($updated = .$handler($in)) {
                    $Global:PSProfile.InitScripts[$initScript].ScriptBlock = $updated
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Edit-PSProfileInitScript -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.InitScripts.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Edit-PSProfileInitScript'

function Enable-PSProfileInitScript {
    <#
    .SYNOPSIS
    Enables a disabled InitScript in $PSProfile.InitScripts.

    .DESCRIPTION
    Enables a disabled InitScript in $PSProfile.InitScripts.

    .PARAMETER Name
    The name of the InitScript to enable in $PSProfile.InitScripts.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Enable-PSProfileInitScript -Name PSReadlineSettings,DevOpsTools

    Enables the InitScripts 'PSReadlineSettings' and 'DevOpsTools' in $PSProfile.InitScripts.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($N in $Name) {
            Write-Verbose "Enabling InitScript '$N' in `$PSProfile.InitScripts"
            if ($Global:PSProfile.InitScripts.Contains($N)) {
                $Global:PSProfile.InitScripts[$N]['Enabled'] = $true
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Enable-PSProfileInitScript -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.InitScripts.GetEnumerator() | Where-Object {-not $_.Value.Enabled -and $_.Key -like "$wordToComplete*"} | Select-Object -ExpandProperty Key | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Enable-PSProfileInitScript'

function Get-PSProfileInitScript {
    <#
    .SYNOPSIS
    Gets an InitScript from $PSProfile.InitScripts.

    .DESCRIPTION
    Gets an InitScript from $PSProfile.InitScripts.

    .PARAMETER Name
    The name of the InitScript to get from $PSProfile.InitScripts.

    .PARAMETER Full
    If $true, gets the compiled InitScript from $PSProfile.InitScripts. This only includes Enabled InitScripts. Each InitScript includes the name in a comment at the top of it for easy identification.

    .EXAMPLE
    Get-PSProfileInitScript -Name PSReadlineSettings,DevOpsTools

    Returns the information for the InitScripts 'PSReadlineSettings' and 'DevOpsTools' from $PSProfile.InitScripts

    .EXAMPLE
    Get-PSProfileInitScript -Full

    Gets the compiled InitScript from $PSProfile.InitScripts. This only includes Enabled InitScripts.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param (
        [Parameter(Position = 0,ValueFromPipeline,ParameterSetName = 'Name')]
        [String[]]
        $Name,
        [Parameter(ParameterSetName = 'Full')]
        [Switch]
        $Full
    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            Name {
                if ($PSBoundParameters.ContainsKey('Name')) {
                    Write-Verbose "Getting InitScript [ $($Name -join ', ') ] from `$PSProfile.InitScripts"
                    $Global:PSProfile.InitScripts.GetEnumerator() | Where-Object {$_.Key -in $Name} | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.Key
                            Enabled = $_.Value.Enabled
                            ScriptBlock = ([scriptblock]::Create($_.Value.ScriptBlock))
                        }
                    }
                }
                else {
                    Write-Verbose "Getting all InitScripts from `$PSProfile.InitScripts"
                    $Global:PSProfile.InitScripts.GetEnumerator() | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.Key
                            Enabled = $_.Value.Enabled
                            ScriptBlock = ([scriptblock]::Create($_.Value.ScriptBlock))
                        }
                    }
                }
            }
            Full {
                Write-Verbose "Getting the full InitScript from `$PSProfile.InitScripts"
                $f = $Global:PSProfile.InitScripts.GetEnumerator() | Where-Object {$_.Value.Enabled} | ForEach-Object {
                    "# From InitScript: $($_.Key)"
                    $_.Value.ScriptBlock
                    ""
                }
                if ($f) {
                    [scriptblock]::Create(($f -join "`n").Trim())
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileInitScript -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.InitScripts.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileInitScript'

function Remove-PSProfileInitScript {
    <#
    .SYNOPSIS
    Removes an InitScript from $PSProfile.InitScripts.

    .DESCRIPTION
    Removes an InitScript from $PSProfile.InitScripts.

    .PARAMETER Name
    The name of the InitScript to remove from $PSProfile.InitScripts.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileInitScript -Name PSReadlineSettings,DevOpsTools

    Removes the InitScripts 'PSReadlineSettings' and 'DevOpsTools' from $PSProfile.InitScripts.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($initScript in $Name) {
            if ($Global:PSProfile.InitScripts.Contains($initScript)) {
                if ($PSCmdlet.ShouldProcess("Removing InitScript '$initScript' from `$PSProfile.InitScripts")) {
                    Write-Verbose "Removing InitScript '$initScript' from `$PSProfile.InitScripts"
                    $Global:PSProfile.InitScripts.Remove($initScript)
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileInitScript -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.InitScripts.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileInitScript'

function Get-PSProfileCommand {
    <#
    .SYNOPSIS
    Gets the list of commands provided by PSProfile directly.

    .DESCRIPTION
    Gets the list of commands provided by PSProfile directly.

    .PARAMETER Command
    The command to get from the list of PSProfile commands.

    .EXAMPLE
    Get-PSProfileCommand

    Gets the full list of commands provided by PSProfile directly.
    #>
    [OutputType('System.Management.Automation.FunctionInfo')]
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Command
    )
    Begin {
        $commands = Get-Command -Module PSProfile | Where-Object {$_.Name -in (Get-Module PSProfile).ExportedCommands.Keys}
    }
    Process {
        if ($PSBoundParameters.ContainsKey('Command')) {
            Write-Verbose "Getting PSProfile command '$Command'"
            $commands | Where-Object {$_.Name -in $Command}
        }
        else {
            Write-Verbose "Getting all commands provided by PSProfile directly"
            $commands
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileCommand -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Module PSProfile).ExportedCommands.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileCommand'

function Get-PSProfileImportedCommand {
    <#
    .SYNOPSIS
    Gets the list of commands imported from scripts and plugins that are not part of PSProfile itself.

    .DESCRIPTION
    Gets the list of commands imported from scripts and plugins that are not part of PSProfile itself.

    .PARAMETER Command
    The command to get from the list of imported commands.

    .EXAMPLE
    Get-PSProfileImportedCommand

    Gets the full list of commands imported during PSProfile load.
    #>
    [OutputType('System.Management.Automation.FunctionInfo')]
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Command
    )
    Begin {
        $commands = Get-Command -Module PSProfile.* #| Where-Object {$_.Name -notin (Get-Module PSProfile).ExportedCommands.Keys}
    }
    Process {
        if ($PSBoundParameters.ContainsKey('Command')) {
            Write-Verbose "Getting imported command '$Command'"
            $commands | Where-Object {$_.Name -in $Command}
        }
        else {
            Write-Verbose "Getting commands imported during PSProfile load that are not part of PSProfile itself"
            $commands
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileImportedCommand -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Command -Module PSProfile | Where-Object {$_.Name -notin (Get-Module PSProfile).ExportedCommands.Keys} | Where-Object {$_ -like "$wordToComplete*"}).Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileImportedCommand'

function Get-PSProfileLog {
    <#
    .SYNOPSIS
    Gets the PSProfile Log events.

    .DESCRIPTION
    Gets the PSProfile Log events.

    .PARAMETER Section
    Limit results to only a specific section.

    .PARAMETER LogLevel
    Limit results to only a specific LogLevel.

    .PARAMETER Summary
    Get a high-level summary of the PSProfile Log.

    .PARAMETER Raw
    Return the raw PSProfile Events. Returns the results via Format-Table for readability otherwise.

    .EXAMPLE
    Get-PSProfileLog

    Gets the current Log in full.

    .EXAMPLE
    Get-PSProfileLog -Summary

    Gets the Log summary.

    .EXAMPLE
    Get-PSProfileLog -Section InvokeScripts,LoadPlugins -Raw

    Gets the Log Events for only sections 'InvokeScripts' and 'LoadPlugins' and returns the raw Event objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Full')]
    Param(
        [Parameter(Position = 0,ParameterSetName = 'Full')]
        [String[]]
        $Section,
        [Parameter(Position = 1,ParameterSetName = 'Full')]
        [PSProfileLogLevel[]]
        $LogLevel,
        [Parameter(ParameterSetName = 'Summary')]
        [Switch]
        $Summary,
        [Parameter(ParameterSetName = 'Full')]
        [Switch]
        $Raw
    )
    Process {
        if ($Summary) {
            Write-Verbose "Getting PSProfile Log summary"
            $Global:PSProfile.Log | Group-Object Section | ForEach-Object {
                $sectName = $_.Name
                $Group = $_.Group
                $sectCaps = $Group | Where-Object {$_.Message -match '^SECTION (START|END)$'}
                [PSCustomObject]@{
                    Name = $sectName
                    Start = $sectCaps[0].Time.ToString('HH:mm:ss.fff')
                    SectionDuration = "$([Math]::Round(($sectCaps[-1].Time - $sectCaps[0].Time).TotalMilliseconds))ms"
                    FullDuration = "$([Math]::Round(($Group[-1].Time - $Group[0].Time).TotalMilliseconds))ms"
                    RunningJobs = Get-RSJob -State Running | Where-Object {$_.Name -match $sectName} | Select-Object -ExpandProperty Name
                }
            } | Sort-Object Start | Format-Table -AutoSize
        }
        else {
            Write-Verbose "Getting PSProfile Log"
            $items = if ($Section) {
                $Global:PSProfile.Log | Where-Object {$_.Section -in $Section}
            }
            else {
                $Global:PSProfile.Log
            }
            if ($LogLevel) {
                $items = $items | Where-Object {$_.LogLevel -in $LogLevel}
            }
            if (-not $Raw) {
                $items | Format-Table -AutoSize
            }
            else {
                $items
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileLog -ParameterName 'Section' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Log.Section | Sort-Object -Unique | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileLog'

function Add-PSProfileModuleToImport {
    <#
    .SYNOPSIS
    Adds a module to import during PSProfile import.

    .DESCRIPTION
    Adds a module to import during PSProfile import.

    .PARAMETER Name
    The name of the module to import.

    .PARAMETER Prefix
    Add the specified prefix to the nouns in the names of imported module members.

    .PARAMETER MinimumVersion
    Import only a version of the module that is greater than or equal to the specified value. If no version qualifies, Import-Module generates an error.

    .PARAMETER RequiredVersion
    Import only the specified version of the module. If the version is not installed, Import-Module generates an error.

    .PARAMETER ArgumentList
    Specifies arguments (parameter values) that are passed to a script module during the Import-Module command. Valid only when importing a script module.

    .PARAMETER Force
    If the module already exists in $PSProfile.ModulesToImport, use -Force to overwrite the existing value.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileModuleToImport -Name posh-git -RequiredVersion '0.7.3' -Save

    Specifies to import posh-git version 0.7.3 during PSProfile import then saves the updated configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [String]
        $Prefix,
        [Parameter()]
        [String]
        $MinimumVersion,
        [Parameter()]
        [String]
        $RequiredVersion,
        [Parameter()]
        [Object[]]
        $ArgumentList,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($mod in $Name) {
            if (-not $Force -and $null -ne ($Global:PSProfile.ModulesToImport | Where-Object {$_.Name -eq $mod})) {
                Write-Error "Unable to add module to `$PSProfile.ModulesToImport as it already exists. Use -Force to overwrite the existing value if desired."
            }
            else {
                $moduleParams = @{
                    Name = $mod
                }
                $PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -in @('Prefix','MinimumVersion','RequiredVersion','ArgumentList')} | ForEach-Object {
                    $moduleParams[$_.Key] = $_.Value
                }
                Write-Verbose "Adding '$mod' to `$PSProfile.ModulesToImport"
                [hashtable[]]$final = @($moduleParams)
                $Global:PSProfile.ModulesToImport | Where-Object {$_.Name -ne $mod} | ForEach-Object {
                    $final += $_
                }
                $Global:PSProfile.ModulesToImport = $final
                if ($Save) {
                    Save-PSProfile
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Add-PSProfileModuleToImport -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-Module "$wordToComplete*" -ListAvailable | Select-Object -ExpandProperty Name | Sort-Object -Unique | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Add-PSProfileModuleToImport'

function Get-PSProfileModuleToImport {
    <#
    .SYNOPSIS
    Gets a module from $PSProfile.ModulesToImport.

    .DESCRIPTION
    Gets a module from $PSProfile.ModulesToImport.

    .PARAMETER Name
    The name of the module to get from $PSProfile.ModulesToImport.

    .EXAMPLE
    Get-PSProfileModuleToImport -Name posh-git

    Gets posh-git from $PSProfile.ModulesToImport

    .EXAMPLE
    Get-PSProfileModuleToImport

    Gets the list of modules to import from $PSProfile.ModulesToImport
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Name
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Name')) {
            Write-Verbose "Getting ModuleToImport '$Name' from `$PSProfile.ModulesToImport"
            $Global:PSProfile.ModulesToImport | Where-Object {$_ -in $Name -or $_.Name -in $Name}
        }
        else {
            Write-Verbose "Getting all command aliases from `$PSProfile.ModulesToImport"
            $Global:PSProfile.ModulesToImport
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileModuleToImport -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ModulesToImport | ForEach-Object {
        if ($_ -is [hashtable]) {
            $_.Name
        }
        else {
            $_
        }
    } | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileModuleToImport'

function Remove-PSProfileModuleToImport {
    <#
    .SYNOPSIS
    Removes a module from $PSProfile.ModulesToImport.

    .DESCRIPTION
    Removes a module from $PSProfile.ModulesToImport.

    .PARAMETER Name
    The name of the module to remove from $PSProfile.ModulesToImport.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileModuleToImport -Name posh-git -Save

    Removes posh-git from $PSProfile.ModulesToImport then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($mod in $Name) {
            if ($PSCmdlet.ShouldProcess("Removing '$mod' from `$PSProfile.ModulesToImport")) {
                Write-Verbose "Removing '$mod' from `$PSProfile.ModulesToImport"
                $Global:PSProfile.ModulesToImport = $Global:PSProfile.ModulesToImport | Where-Object {($_ -is [hashtable] -and $_.Name -ne $mod) -or ($_ -is [string] -and $_ -ne $mod)}
                if ($Save) {
                    Save-PSProfile
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileModuleToImport -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ModulesToImport | ForEach-Object {
        if ($_ -is [hashtable]) {
            $_.Name
        }
        else {
            $_
        }
    } | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileModuleToImport'

function Add-PSProfileModuleToInstall {
    <#
    .SYNOPSIS
    Adds a module to ensure is installed in the CurrentUser scope. Module installations are handled via background job during PSProfile import.

    .DESCRIPTION
    Adds a module to ensure is installed in the CurrentUser scope. Module installations are handled via background job during PSProfile import.

    .PARAMETER Name
    The name of the module to install.

    .PARAMETER Repository
    The repository to install the module from. Defaults to the PowerShell Gallery.

    .PARAMETER MinimumVersion
    The minimum version of the module to install.

    .PARAMETER RequiredVersion
    The required version of the module to install.

    .PARAMETER AcceptLicense
    If $true, accepts the license for the module if necessary.

    .PARAMETER AllowPrerelease
    If $true, allows installation of prerelease versions of the module.

    .PARAMETER Force
    If the module already exists in $PSProfile.ModulesToInstall, use -Force to overwrite the existing value.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileModuleToInstall -Name posh-git -RequiredVersion '0.7.3' -Save

    Specifies to install posh-git version 0.7.3 during PSProfile import if missing then saves the updated configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [String]
        $Repository,
        [Parameter()]
        [String]
        $MinimumVersion,
        [Parameter()]
        [String]
        $RequiredVersion,
        [Parameter()]
        [Switch]
        $AcceptLicense,
        [Parameter()]
        [Switch]
        $AllowPrerelease,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($mod in $Name) {
            if (-not $Force -and $null -ne ($Global:PSProfile.ModulesToInstall | Where-Object {$_.Name -eq $mod})) {
                Write-Error "Unable to add module '$mod' to `$PSProfile.ModulesToInstall as it already exists. Use -Force to overwrite the existing value if desired."
            }
            else {
                $moduleParams = @{
                    Name = $mod
                }
                $PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -in @('Repository','MinimumVersion','RequiredVersion','AcceptLicense','AllowPrerelease','Force')} | ForEach-Object {
                    $moduleParams[$_.Key] = $_.Value
                }
                Write-Verbose "Adding '$mod' to `$PSProfile.ModulesToInstall"
                [hashtable[]]$final = @($moduleParams)
                $Global:PSProfile.ModulesToInstall | Where-Object {$_.Name -ne $mod} | ForEach-Object {
                    $final += $_
                }
                $Global:PSProfile.ModulesToInstall = $final
                if ($Save) {
                    Save-PSProfile
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Add-PSProfileModuleToInstall -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-Module "$wordToComplete*" -ListAvailable | Select-Object -ExpandProperty Name | Sort-Object -Unique | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Add-PSProfileModuleToInstall'

function Get-PSProfileModuleToInstall {
    <#
    .SYNOPSIS
    Gets a module from $PSProfile.ModulesToInstall.

    .DESCRIPTION
    Gets a module from $PSProfile.ModulesToInstall.

    .PARAMETER Name
    The name of the module to get from $PSProfile.ModulesToInstall.

    .EXAMPLE
    Get-PSProfileModuleToInstall -Name posh-git

    Gets posh-git from $PSProfile.ModulesToInstall

    .EXAMPLE
    Get-PSProfileModuleToInstall

    Gets the list of modules to install from $PSProfile.ModulesToInstall
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Name
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Name')) {
            Write-Verbose "Getting ModuleToImport '$Name' from `$PSProfile.ModulesToInstall"
            $Global:PSProfile.ModulesToInstall | Where-Object {$_ -in $Name -or $_.Name -in $Name}
        }
        else {
            Write-Verbose "Getting all command aliases from `$PSProfile.ModulesToInstall"
            $Global:PSProfile.ModulesToInstall
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileModuleToInstall -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ModulesToInstall | ForEach-Object {
        if ($_ -is [hashtable]) {
            $_.Name
        }
        else {
            $_
        }
    } | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileModuleToInstall'

function Remove-PSProfileModuleToInstall {
    <#
    .SYNOPSIS
    Removes a module from $PSProfile.ModulesToInstall.

    .DESCRIPTION
    Removes a module from $PSProfile.ModulesToInstall.

    .PARAMETER Name
    The name of the module to remove from $PSProfile.ModulesToInstall.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileModuleToInstall -Name posh-git -Save

    Removes posh-git from $PSProfile.ModulesToInstall then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($mod in $Name) {
            if ($PSCmdlet.ShouldProcess("Removing '$mod' from `$PSProfile.ModulesToInstall")) {
                Write-Verbose "Removing '$mod' from `$PSProfile.ModulesToInstall"
                $Global:PSProfile.ModulesToInstall = $Global:PSProfile.ModulesToInstall | Where-Object {($_ -is [hashtable] -and $_.Name -ne $mod) -or ($_ -is [string] -and $_ -ne $mod)}
                if ($Save) {
                    Save-PSProfile
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileModuleToInstall -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ModulesToInstall | ForEach-Object {
        if ($_ -is [hashtable]) {
            $_.Name
        }
        else {
            $_
        }
    } | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileModuleToInstall'

function Add-PSProfilePathAlias {
    <#
    .SYNOPSIS
    Adds a path alias to your PSProfile configuration. Path aliases are used for path shortening in prompts via Get-PathAlias.

    .DESCRIPTION
    Adds a path alias to your PSProfile configuration. Path aliases are used for path shortening in prompts via Get-PathAlias.

    .PARAMETER Alias
    The alias to substitute the full path for in prompts via Get-PathAlias.

    .PARAMETER Path
    The full path to be substituted.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfilePathAlias -Alias ~ -Path $env:USERPROFILE -Save

    Adds a path alias of ~ for the current UserProfile folder and saves your PSProfile configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Alias,
        [Parameter(Mandatory,Position = 1)]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        Write-Verbose "Adding alias '$Alias' to path '$Path' to PSProfile"
        $Global:PSProfile.PathAliases[$Alias] = $Path
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfilePathAlias'

function Get-PSProfilePathAlias {
    <#
    .SYNOPSIS
    Gets a module from $PSProfile.PathAliases.

    .DESCRIPTION
    Gets a module from $PSProfile.PathAliases.

    .PARAMETER Alias
    The Alias to get from $PSProfile.PathAliases.

    .EXAMPLE
    Get-PSProfilePathAlias -Alias ~

    Gets the alias '~' from $PSProfile.PathAliases

    .EXAMPLE
    Get-PSProfilePathAlias

    Gets the list of path aliases from $PSProfile.PathAliases
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Alias
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Alias')) {
            Write-Verbose "Getting Path Alias '$Alias' from `$PSProfile.PathAliases"
            $Global:PSProfile.PathAliases.GetEnumerator() | Where-Object {$_.Key -in $Alias}
        }
        else {
            Write-Verbose "Getting all command aliases from `$PSProfile.PathAliases"
            $Global:PSProfile.PathAliases
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfilePathAlias -ParameterName Alias -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.PathAliases.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfilePathAlias'

function Remove-PSProfilePathAlias {
    <#
    .SYNOPSIS
    Removes an alias from $PSProfile.PathAliases.

    .DESCRIPTION
    Removes an alias from $PSProfile.PathAliases.

    .PARAMETER Alias
    The alias to remove from $PSProfile.PathAliases.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfilePathAlias -Alias Workplace -Save

    Removes the alias 'Workplace' from $PSProfile.PathAliases then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Alias,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Alias' from `$PSProfile.PathAliases")) {
            Write-Verbose "Removing '$Alias' from `$PSProfile.PathAliases"
            $Global:PSProfile.PathAliases.Remove($Alias)
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfilePathAlias -ParameterName Alias -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.PathAliases.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfilePathAlias'

function Add-PSProfilePluginPath {
    <#
    .SYNOPSIS
    Adds a PluginPath to your PSProfile to search for PSProfile plugins in during module load.

    .DESCRIPTION
    Adds a PluginPath to your PSProfile to search for PSProfile plugins in during module load.

    .PARAMETER Path
    The path of the folder to add to your $PSProfile.PluginPaths. This path should contain PSProfile.Plugins

    .PARAMETER NoRefresh
    If $true, skips reloading your PSProfile after updating.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfilePluginPath -Path ~\PSProfilePlugins -Save

    Adds the folder ~\PSProfilePlugins to $PSProfile.PluginPaths and saves the configuration after updating.

    .EXAMPLE
    Add-PSProfilePluginPath C:\PSProfilePlugins -Verbose

    Adds the path C:\PSProfilePlugins to your $PSProfile.PluginPaths, refreshes your PathDict but does not save. Call Save-PSProfile after if satisfied with the results.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({if ((Get-Item $_).PSIsContainer){$true}else{throw "$_ is not a folder! Please add only folders to this PSProfile property. If you would like to add a script, use Add-PSProfileScriptPath instead."}})]
        [Alias('FullName')]
        [String[]]
        $Path,
        [Parameter()]
        [Switch]
        $NoRefresh,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($p in $Path) {
            $fP = (Resolve-Path $p).Path
            [string[]]$base = @()
            $Global:PSProfile.PluginPaths | Where-Object {-not [string]::IsNullOrEmpty($_)} | ForEach-Object {
                $base += $_
            }
            if ($Global:PSProfile.PluginPaths -notcontains $fP) {
                Write-Verbose "Adding PluginPath to PSProfile: $fP"
                $base += $fP
            }
            else {
                Write-Verbose "PluginPath already in PSProfile: $fP"
            }
            $Global:PSProfile.PluginPaths = $base
        }
        if ($Save) {
            Save-PSProfile
        }
        if (-not $NoRefresh) {
            Import-PSProfile -Verbose:$false
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfilePluginPath'

function Get-PSProfilePluginPath {
    <#
    .SYNOPSIS
    Gets a plugin path from $PSProfile.PluginPaths.

    .DESCRIPTION
    Gets a plugin path from $PSProfile.PluginPaths.

    .PARAMETER Path
    The plugin path to get from $PSProfile.PluginPaths.

    .EXAMPLE
    Get-PSProfilePluginPath -Path E:\MyPSProfilePlugins

    Gets the path 'E:\MyPSProfilePlugins' from $PSProfile.PluginPaths

    .EXAMPLE
    Get-PSProfilePluginPath

    Gets the list of plugin paths from $PSProfile.PluginPaths
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Path
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Path')) {
            Write-Verbose "Getting plugin path '$Path' from `$PSProfile.PluginPaths"
            $Global:PSProfile.PluginPaths | Where-Object {$_ -match "($(($Path | ForEach-Object {[regex]::Escape($_)}) -join '|'))"}
        }
        else {
            Write-Verbose "Getting all plugin paths from `$PSProfile.PluginPaths"
            $Global:PSProfile.PluginPaths
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfilePluginPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.PluginPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfilePluginPath'

function Remove-PSProfilePluginPath {
    <#
    .SYNOPSIS
    Removes a Plugin Path from $PSProfile.PluginPaths.

    .DESCRIPTION
    Removes a Plugin Path from $PSProfile.PluginPaths.

    .PARAMETER Path
    The path to remove from $PSProfile.PluginPaths.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfilePluginPath -Name E:\MyPluginPaths -Save

    Removes the path 'E:\MyPluginPaths' from $PSProfile.PluginPaths then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Path' from `$PSProfile.PluginPaths")) {
            Write-Verbose "Removing '$Path' from `$PSProfile.PluginPaths"
            $Global:PSProfile.PluginPaths = $Global:PSProfile.PluginPaths | Where-Object {$_ -notin @($Path,(Resolve-Path $Path).Path)}
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfilePluginPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.PluginPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfilePluginPath'

function Add-PSProfilePlugin {
    <#
    .SYNOPSIS
    Adds a PSProfile Plugin to the list of plugins. If the plugin already exists, it will overwrite it. Re-imports your PSProfile once done to load any newly added plugins.

    .DESCRIPTION
    Adds a PSProfile Plugin to the list of plugins. If the plugin already exists, it will overwrite it. Re-imports your PSProfile once done to load any newly added plugins.

    .PARAMETER Name
    The name of the Plugin to add, e.g. 'PSProfile.PowerTools'

    .PARAMETER ArgumentList
    Any arguments that need to be passed to the plugin on import, such as a hashtable to process.

    .PARAMETER NoRefresh
    If $true, skips reloading your PSProfile after updating.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfilePlugin -Name 'PSProfile.PowerTools' -Save

    Adds the included plugin 'PSProfile.PowerTools' to your PSProfile and saves it so it persists.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String[]]
        $Name,
        [Parameter(Position = 1)]
        [Object]
        $ArgumentList,
        [Parameter()]
        [Switch]
        $NoRefresh,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($pName in $Name) {
            Write-Verbose "Adding plugin '$pName' to `$PSProfile.Plugins"
            $plugin = @{
                Name = $pName
            }
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $plugin['ArgumentList'] = $ArgumentList
            }
            $temp = @()
            $Global:PSProfile.Plugins | Where-Object {$_.Name -ne $pName} | ForEach-Object {
                $temp += $_
            }
            $temp += $plugin
            $Global:PSProfile.Plugins = $temp
        }
        if ($Save) {
            Save-PSProfile
        }
        if (-not $NoRefresh) {
            Import-PSProfile -Verbose:$false
        }
    }
}

Register-ArgumentCompleter -CommandName Add-PSProfilePlugin -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.PluginPaths | Get-ChildItem | Select-Object -ExpandProperty BaseName -Unique | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Add-PSProfilePlugin'

function Get-PSProfilePlugin {
    <#
    .SYNOPSIS
    Gets a Plugin from $PSProfile.Plugins.

    .DESCRIPTION
    Gets a Plugin from $PSProfile.Plugins.

    .PARAMETER Name
    The name of the Plugin to get from $PSProfile.Plugins.

    .EXAMPLE
    Get-PSProfilePlugin -Name PSProfile.Prompt

    Gets PSProfile.Prompt from $PSProfile.Plugins

    .EXAMPLE
    Get-PSProfilePlugin

    Gets the list of Plugins from $PSProfile.Plugins
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Name
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Name')) {
            Write-Verbose "Getting Plugin '$Name' from `$PSProfile.Plugins"
            $Global:PSProfile.Plugins | Where-Object {$_.Name -in $Name}
        }
        else {
            Write-Verbose "Getting all Plugins from `$PSProfile.Plugins"
            $Global:PSProfile.Plugins
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfilePlugin -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Plugins | ForEach-Object {$_.Name} | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfilePlugin'

function Remove-PSProfilePlugin {
    <#
    .SYNOPSIS
    Removes a PSProfile Plugin from $PSProfile.Plugins.

    .DESCRIPTION
    Removes a PSProfile Plugin from $PSProfile.Plugins.

    .PARAMETER Name
    The name of the Plugin to remove from $PSProfile.Plugins.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfilePlugin -Name 'PSProfile.PowerTools' -Save

    Removes the Plugin 'PSProfile.PowerTools' from $PSProfile.Plugins then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Name' from `$PSProfile.Plugins")) {
            Write-Verbose "Removing '$Name' from `$PSProfile.Plugins"
            $Global:PSProfile.Plugins = $Global:PSProfile.Plugins | Where-Object {$_.Name -ne $Name}
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfilePlugin -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Plugins.Name | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfilePlugin'

function Confirm-ScriptIsValid {
    <#
    .SYNOPSIS
    Uses the PSParser to check for any errors in a script file.

    .DESCRIPTION
    Uses the PSParser to check for any errors in a script file.

    .PARAMETER Path
    The path of the script to check for errors.

    .EXAMPLE
    Confirm-ScriptIsValid MyScript.ps1

    .EXAMPLE
    Get-ChildItem .\Scripts | Confirm-ScriptIsValid
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        [ValidateScript( { Test-Path $_ })]
        [String[]]
        $Path
    )
    Begin {
        $errorColl = @()
        $analyzed = 0
        $lenAnalyzed = 0
    }
    Process {
        foreach ($p in $Path | Where-Object { $_ -like '*.ps1' }) {
            $analyzed++
            $item = Get-Item $p
            $lenAnalyzed += $item.Length
            $contents = Get-Content -Path $item.FullName -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $obj = [PSCustomObject][Ordered]@{
                Name       = $item.Name
                FullName   = $item.FullName
                Length     = $item.Length
                ErrorCount = $errors.Count
                Errors     = $errors
            }
            $obj
            if ($errors.Count) {
                $errorColl += $obj
            }
        }
    }
    End {
        Write-Verbose "Total files analyzed: $analyzed"
        Write-Verbose "Total size of files analyzed: $lenAnalyzed ($([Math]::Round(($lenAnalyzed/1MB),2)) MB)"
        Write-Verbose "Files with errors:`n$($errorColl | Sort-Object FullName | Out-String)"
    }
}


Export-ModuleMember -Function 'Confirm-ScriptIsValid'

function Enter-CleanEnvironment {
    <#
    .SYNOPSIS
    Enters a clean environment with -NoProfile and sets a couple helpers, e.g. a prompt to advise you are in a clean environment and some PSReadline helper settings for convenience.

    .DESCRIPTION
    Enters a clean environment with -NoProfile and sets a couple helpers, e.g. a prompt to advise you are in a clean environment and some PSReadline helper settings for convenience.

    .PARAMETER Engine
    The engine to open the clean environment with between powershell, pwsh, and pwsh-preview. Defaults to the current engine the clean environment is opened from.

    .PARAMETER ImportModule
    If $true, imports the module found in the BuildOutput folder if present. Useful for quickly testing compiled modules after building in a clean environment to avoid assembly locking and other gotchas.

    .EXAMPLE
    Enter-CleanEnvironment

    Opens a clean environment from the current path.

    .EXAMPLE
    cln

    Does the same as Example 1, but using the shorter alias 'cln'.

    .EXAMPLE
    cln -ipmo

    Enters the clean environment and imports the built module in the BuildOutput folder, if present.
    #>
    [CmdletBinding()]
    Param (
        [parameter(Position = 0)]
        [ValidateSet('powershell','pwsh','pwsh-preview')]
        [Alias('E')]
        [String]
        $Engine = $(if ($PSVersionTable.PSVersion.ToString() -match 'preview') {
                'pwsh-preview'
            }
            elseif ($PSVersionTable.PSVersion.Major -ge 6) {
                'pwsh'
            }
            else {
                'powershell'
            }),
        [Parameter()]
        [Alias('ipmo','Import')]
        [Switch]
        $ImportModule
    )
    Begin {
        $parsedEngine = if ($Engine -eq 'pwsh-preview' -and ($PSVersionTable.PSVersion.Major -le 5 -or $IsWindows)) {
            "& '{0}'" -f (Resolve-Path ([System.IO.Path]::Combine((Split-Path (Get-Command pwsh-preview).Source -Parent),'..','pwsh.exe'))).Path
        }
        else {
            $Engine
        }
    }
    Process {
        $verboseMessage = "Creating clean environment...`n           Engine  : $Engine"
        $command = "$parsedEngine -NoProfile -NoExit -C `"```$global:CleanNumber = 0;if (```$null -ne (Get-Module PSReadline)) {Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete;Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward;Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward;Set-PSReadLineKeyHandler -Chord 'Ctrl+W' -Function BackwardKillWord;Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function MenuComplete;Set-PSReadLineKeyHandler -Chord 'Ctrl+D' -Function KillWord};"
        if ($ImportModule) {
            if (($modName = (Get-ChildItem .\BuildOutput -Directory).BaseName)) {
                $modPath = '.\BuildOutput\' + $modName
                $verboseMessage += "`n           Module  : $modName"
                $command += "Import-Module '$modPath' -Verbose:```$false;Get-Module $modName;"
            }
        }
        $newline = '`n'
        $command += "function global:prompt {```$global:CleanNumber++;'[CLN#' + ```$global:CleanNumber + '] [' + [Math]::Round((Get-History -Count 1).Duration.TotalMilliseconds,0) + 'ms] ' + (Get-Location).Path.Replace(```$env:Home,'~') + '$newline[PS ' + ```$PSVersionTable.PSVersion.ToString() + ']>> '}`""
        $verboseMessage += "`n           Command : $command"
        Write-Verbose $verboseMessage
        Invoke-Expression $command
    }
}


Export-ModuleMember -Function 'Enter-CleanEnvironment'

function Format-Syntax {
    <#
    .SYNOPSIS
    Formats a command's syntax in an easy-to-read view.

    .DESCRIPTION
    Formats a command's syntax in an easy-to-read view.

    .PARAMETER Command
    The command to get the syntax of.

    .EXAMPLE
    Format-Syntax Get-Process

    Gets the formatted syntax by parameter set for Get-Process

    .EXAMPLE
    syntax Get-Process

    Same as Example 1, but uses the alias 'syntax' instead.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position = 0)]
        [String[]]
        $Command
    )
    Process {
        foreach ($comm in $Command) {
            Write-Verbose "Getting formatted syntax for command: $comm"
            $check = Get-Command -Name $comm
            $params = @{
                Name   = if ($check.CommandType -eq 'Alias') {
                    Get-Command -Name $check.Definition
                }
                else {
                    $comm
                }
                Syntax = $true
            }
            (Get-Command @params) -replace '(\s(?=\[)|\s(?=-))', "`r`n "
        }
    }
}

Register-ArgumentCompleter -CommandName Format-Syntax -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Command "$wordToComplete*").Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Format-Syntax'

function Get-Definition {
    <#
    .SYNOPSIS
    Convenience function to easily get the defition of a function

    .DESCRIPTION
    Convenience function to easily get the defition of a function

    .PARAMETER Command
    The command or function to get the definition for

    .EXAMPLE
    Get-Definition Open-Code

    .EXAMPLE
    def Open-Code

    Uses the shorter alias to get the definition of the Open-Code function
    #>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory,Position = 0)]
        [String]
        $Command
    )
    Process {
        try {
            Write-Verbose "Getting definition for command: $Command"
            $Definition = (Get-Command $Command -ErrorAction Stop).Definition
            "function $Command {$Definition}"
        }
        catch {
            throw
        }
    }
}

Register-ArgumentCompleter -CommandName Get-Definition -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Command "$wordToComplete*").Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-Definition'

function Get-Gist {
    <#
    .SYNOPSIS
    Gets a GitHub Gist's contents using the public API

    .DESCRIPTION
    Gets a GitHub Gist's contents using the public API

    .PARAMETER Id
    The ID of the Gist to get

    .PARAMETER File
    The specific file from the Gist to get. If excluded, gets all of the files as an array of objects.

    .PARAMETER Sha
    The SHA of the specific Gist to get, if desired.

    .PARAMETER Metadata
    Any additional metadata you want to include on the resulting object, e.g. for identifying what the Gist is, add notes, etc.

    .PARAMETER Invoke
    If $true, invokes the Gist contents. If the Gist contains any PowerShell functions, it will adjust the scope to Global before invoking so the function remains available in the session after Get-Gist finishes. Useful for loading functions directly from a Gist.

    .EXAMPLE
    Get-Gist -Id f784228937183a1cf8105351872d2f8a -Invoke

    Gets the Update-Release and Test-GetGist functions from the following Gist URL and loads them into the current session for subsequent use: https://gist.github.com/scrthq/f784228937183a1cf8105351872d2f8a
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
        [String]
        $Id,
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('Files')]
        [String[]]
        $File,
        [parameter(ValueFromPipelineByPropertyName)]
        [String]
        $Sha,
        [parameter(ValueFromPipelineByPropertyName)]
        [Object]
        $Metadata,
        [parameter()]
        [Switch]
        $Invoke
    )
    Process {
        $Uri = [System.Collections.Generic.List[string]]@(
            'https://api.github.com'
            '/gists/'
            $PSBoundParameters['Id']
        )
        if ($PSBoundParameters.ContainsKey('Sha')) {
            $Uri.Add("/$($PSBoundParameters['Sha'])")
            Write-Verbose "[$($PSBoundParameters['Id'])] Getting gist info @ SHA '$($PSBoundParameters['Sha'])'"
        }
        else {
            Write-Verbose "[$($PSBoundParameters['Id'])] Getting gist info"
        }
        $gistInfo = Invoke-RestMethod -Uri ([Uri](-join $Uri)) -Verbose:$false
        $fileNames = if ($PSBoundParameters.ContainsKey('File')) {
            $PSBoundParameters['File']
        }
        else {
            $gistInfo.files.PSObject.Properties.Name
        }
        foreach ($fileName in $fileNames) {
            Write-Verbose "[$fileName] Getting gist file content"
            $fileInfo = $gistInfo.files.$fileName
            $content = if ($fileInfo.truncated) {
                (Invoke-WebRequest -Uri ([Uri]$fileInfo.raw_url)).Content
            }
            else {
                $fileInfo.content
            }
            $lines = ($content -split "`n").Count
            if ($Invoke) {
                Write-Verbose "[$fileName] Parsing gist file content ($lines lines)"
                $noScopePattern = '^function\s+(?<Name>[\w+_-]{1,})\s+\{'
                $globalScopePattern = '^function\s+global\:'
                $noScope = [RegEx]::Matches($content, $noScopePattern, "Multiline, IgnoreCase")
                $globalScope = [RegEx]::Matches($content,$globalScopePattern,"Multiline, IgnoreCase")
                if ($noScope.Count -ge $globalScope.Count) {
                    foreach ($match in $noScope) {
                        $fullValue = ($match.Groups | Where-Object { $_.Name -eq 0 }).Value
                        $funcName = ($match.Groups | Where-Object { $_.Name -eq 'Name' }).Value
                        Write-Verbose "[$fileName::$funcName] Updating function to global scope to ensure it imports correctly."
                        $content = $content.Replace($fullValue, "function global:$funcName {")
                    }
                }
                Write-Verbose "[$fileName] Invoking gist file content"
                $ExecutionContext.InvokeCommand.InvokeScript(
                    $false,
                    ([scriptblock]::Create($content)),
                    $null,
                    $null
                )
            }
            [PSCustomObject]@{
                File     = $fileName
                Sha      = $Sha
                Lines    = $lines
                Metadata = $Metadata
                Content  = $content -join "`n"
            }
        }
    }
}


Export-ModuleMember -Function 'Get-Gist'

function Get-LongPath {
    <#
    .SYNOPSIS
    Expands a short-alias from the GitPathMap to the full path

    .DESCRIPTION
    Expands a short-alias from the GitPathMap to the full path

    .PARAMETER Path
    The short path to expand

    .PARAMETER Subpaths
    Any subpaths to join to the main path before resolving.

    .EXAMPLE
    Get-LongPath MyWorkRepo

    Gets the full path to MyWorkRepo

    .EXAMPLE
    path MyWorkRepo

    Same as Example 1, but uses the short-alias 'path' instead.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param (
        [parameter(Position = 0,ParameterSetName = 'Path')]
        [String]
        $Path = $PWD.Path,
        [parameter(ValueFromRemainingArguments,Position = 1,ParameterSetName = 'Path')]
        [String[]]
        $Subpaths
    )
    DynamicParam {
        if ($global:PSProfile.GitPathMap.ContainsKey('chef-repo')) {
            $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $true
            $ParamAttrib.ParameterSetName = 'Cookbook'
            $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $AttribColl.Add($ParamAttrib)
            $set = (Get-ChildItem (Join-Path $global:PSProfile.GitPathMap['chef-repo'] 'cookbooks') -Directory).Name
            $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($set)))
            $AttribColl.Add((New-Object System.Management.Automation.AliasAttribute('c')))
            $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Cookbook',  [string], $AttribColl)
            $RuntimeParamDic.Add('Cookbook',  $RuntimeParam)
        }
        return  $RuntimeParamDic
    }
    Begin {
        if (-not $PSBoundParameters.ContainsKey('Path')) {
            $PSBoundParameters['Path'] = $PWD.Path
        }
    }
    Process {
        $target = switch ($PSCmdlet.ParameterSetName) {
            Path {
                if ($PSBoundParameters['Path'] -eq '.') {
                    $PWD.Path
                }
                elseif ($null -ne $global:PSProfile.GitPathMap.Keys) {
                    if ($global:PSProfile.GitPathMap.ContainsKey($PSBoundParameters['Path'])) {
                        $global:PSProfile.GitPathMap[$PSBoundParameters['Path']]
                    }
                    else {
                        (Resolve-Path $PSBoundParameters['Path']).Path
                    }
                }
                else {
                    (Resolve-Path $PSBoundParameters['Path']).Path
                }
            }
            Cookbook {
                [System.IO.Path]::Combine($global:PSProfile.GitPathMap['chef-repo'],'cookbooks',$PSBoundParameters['Cookbook'])
            }
        }
        if ($Subpaths) {
            $target = Join-Path $target ($Subpaths -join [System.IO.Path]::DirectorySeparatorChar)
        }
        Write-Verbose "Resolved long path: $target"
        $target
    }
}

Register-ArgumentCompleter -CommandName Get-LongPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "GitPathMap.$wordToComplete" -FinalKeyOnly
}


Export-ModuleMember -Function 'Get-LongPath'

function Install-LatestModule {
    <#
    .SYNOPSIS
    A helper function to uninstall any existing versions of the target module before installing the latest one.

    .DESCRIPTION
    A helper function to uninstall any existing versions of the target module before installing the latest one. Defaults to CurrentUser scope when installing the latest module version from the desired repository.

    .PARAMETER Name
    The name of the module to install the latest version of

    .PARAMETER Repository
    The PowerShell repository to install the latest module from. Defaults to the PowerShell Gallery.

    .PARAMETER ConfirmNotImported
    If $true, safeguards module removal if the module you are trying to update is currently imported by throwing a terminating error.

    .EXAMPLE
    Install-LatestModule PSProfile
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [String[]]
        $Name,
        [Parameter()]
        [String]
        $Repository = 'PSGallery',
        [Parameter()]
        [Switch]
        $ConfirmNotImported
    )
    Process {
        foreach ($module in $Name) {
            if ($ConfirmNotImported -and (Get-Module $module)) {
                throw "$module cannot be loaded if trying to install!"
            }
            else {
                try {
                    Write-Verbose "Uninstalling all version of module: $module"
                    Get-Module $module -ListAvailable | Uninstall-Module
                    Write-Verbose "Installing latest module version from PowerShell Gallery"
                    Install-Module $module -Repository $Repository -Scope CurrentUser -AllowClobber -SkipPublisherCheck -AcceptLicense
                }
                catch {
                    throw
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Install-LatestModule -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-Module "$wordToComplete*" -ListAvailable).Name | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Install-LatestModule'

function Open-Code {
    <#
    .SYNOPSIS
    A drop-in replacement for the Visual Studio Code CLI `code`. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    .DESCRIPTION
    A drop-in replacement for the Visual Studio Code CLI `code`. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    .PARAMETER Path
    The path of the file or folder to open with Code. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    .PARAMETER Cookbook
    If you are using Chef and have your chef-repo folder in your GitPaths, this will allow you to specify a cookbook path to open from the Cookbooks subfolder.

    .PARAMETER AddToWorkspace
    If $true, adds the folder to the current Code workspace.

    .PARAMETER InputObject
    Pipeline input to display as a temporary file in Code. Temp files are automatically cleaned up after the file is closed in Code. No need to add the `-` after `code` to specify that pipeline input is expected.

    .PARAMETER Language
    The language or extension of the temporary file created from the pipeline input. This allows specifying a file type like 'powershell' or 'csv' or an extension like 'ps1', enabling opening of the temp file with the editor file language already set correctly.

    .PARAMETER Wait
    If $true, waits for the file to be closed in Code before returning to the prompt. If $false, opens the file using a background job to allow immediately returning to the prompt. Defaults to $false.

    .PARAMETER WithInsiders
    If $true, looks for VS Code Insiders to load. If $true and code-insiders cannot be found, opens the file using VS Code stable. If $false, opens the file using VS Code stable. Defaults to $false.

    .PARAMETER ArgumentList
    Any additional arguments to be passed directly to the Code CLI command, e.g. `Open-Code --list-extensions` or `code --list-extensions` will still work the same as expected.

    .EXAMPLE
    Get-Process | ConvertTo-Csv | Open-Code -Language csv

    Gets the current running processes, converts to CSV format and opens it in Code via background job as a CSV. Easy Out-GridView!

    .EXAMPLE
    def Update-PSProfileSetting | code -l ps1

    Using shorter aliases, gets the current function definition of the Update-PSProfileSetting function and opens it in Code as a PowerShell file to take advantage of immediate syntax highlighting.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param (
        [parameter(Mandatory,Position = 0,ParameterSetName = 'Path')]
        [parameter(Position = 0,ParameterSetName = 'InputObject')]
        [AllowEmptyString()]
        [AllowNull()]
        [String]
        $Path,
        [parameter(ParameterSetName = 'Path')]
        [parameter(ParameterSetName = 'Cookbook')]
        [Alias('add','a')]
        [Switch]
        $AddToWorkspace,
        [parameter(ValueFromPipeline,ParameterSetName = 'InputObject')]
        [Object]
        $InputObject,
        [parameter(ParameterSetName = 'InputObject')]
        [Alias('l','lang','Extension')]
        [String]
        $Language = 'txt',
        [parameter(ParameterSetName = 'InputObject')]
        [Alias('w')]
        [Switch]
        $Wait,
        [Alias('wi')]
        [Alias('insiders')]
        [Switch]
        $WithInsiders,
        [parameter(ValueFromRemainingArguments)]
        [String[]]
        $ArgumentList
    )
    DynamicParam {
        if ($global:PSProfile.GitPathMap.ContainsKey('chef-repo')) {
            $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $true
            $ParamAttrib.ParameterSetName = 'Cookbook'
            $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $AttribColl.Add($ParamAttrib)
            $set = (Get-ChildItem (Join-Path $global:PSProfile.GitPathMap['chef-repo'] 'cookbooks') -Directory).Name
            $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($set)))
            $AttribColl.Add((New-Object System.Management.Automation.AliasAttribute('c')))
            $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Cookbook',  [string], $AttribColl)
            $RuntimeParamDic.Add('Cookbook',  $RuntimeParam)
        }
        return  $RuntimeParamDic
    }
    Begin {
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $collection = New-Object System.Collections.Generic.List[object]
            $codeArgs = New-Object System.Collections.Generic.List[string]
            $extDict = @{
                txt        = 'txt'
                powershell = 'ps1'
                csv        = 'csv'
                sql        = 'sql'
                xml        = 'xml'
                json       = 'json'
                yml        = 'yml'
                csharp     = 'cs'
                fsharp     = 'fs'
                ruby       = 'rb'
                html       = 'html'
                css        = 'css'
                go         = 'go'
                jsonc      = 'jsonc'
                javascript = 'js'
                typescript = 'ts'
                less       = 'less'
                log        = 'log'
                python     = 'py'
                razor      = 'cshtml'
                markdown   = 'md'
            }
        }
    }
    Process {
        $code = $null
        $codeCommand = if($WithInsiders) {
            @('code-insiders','code')
        }
        else {
            @('code','code-insiders')
        }
        foreach ($cmd in $codeCommand) {
            try {
                if ($found = (Get-Command $cmd -All -ErrorAction Stop | Where-Object { $_.CommandType -notin @('Function','Alias') } | Select-Object -First 1 -ExpandProperty Source)) {
                    $code = $found
                    break
                }
            }
            catch {
                $Global:Error.Remove($Global:Error[0])
            }
        }
        if ($null -eq $code){
            throw "Editor not found!"
        }
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $collection.Add($InputObject)
            if ($PSBoundParameters.ContainsKey('Path')) {
                $codeArgs.Add($PSBoundParameters['Path'])
            }
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $PSBoundParameters['ArgumentList'] | ForEach-Object {
                    $codeArgs.Add($_)
                }
            }
        }
        else {
            $target = switch ($PSCmdlet.ParameterSetName) {
                Path {
                    if ([String]::IsNullOrEmpty($PSBoundParameters['Path']) -or [String]::IsNullOrWhiteSpace($PSBoundParameters['Path'])) {
                        $null
                    }
                    elseif ($PSBoundParameters['Path'] -eq '.') {
                        $PWD.Path
                    }
                    elseif ($null -ne $global:PSProfile.GitPathMap.Keys) {
                        if ($global:PSProfile.GitPathMap.ContainsKey($PSBoundParameters['Path'])) {
                            $global:PSProfile.GitPathMap[$PSBoundParameters['Path']]
                        }
                        else {
                            $PSBoundParameters['Path']
                        }
                    }
                    else {
                        $PSBoundParameters['Path']
                    }
                }
                Cookbook {
                    [System.IO.Path]::Combine($global:PSProfile.GitPathMap['chef-repo'],'cookbooks',$PSBoundParameters['Cookbook'])
                }
            }
            $cmd = @()
            if ($AddToWorkspace) {
                $cmd += '--add'
            }
            if ($target) {
                $cmd += $target
            }
            if ($ArgumentList) {
                $ArgumentList | ForEach-Object {
                    $cmd += $_
                }
            }
            Write-Verbose "Running command: code $cmd"
            & $code $cmd
        }
    }
    End {
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $ext = if ($extDict.ContainsKey($Language)) {
                $extDict[$Language]
            }
            else {
                $Language
            }
            $in = @{
                StdIn    = $collection
                Wait     = $Wait -or $Path -eq '--wait' -or ($ArgumentList -join ' ') -match '(\-\-wait|\-w)'
                CodeArgs = $codeArgs
                TmpFile  = [System.IO.Path]::Combine(([System.IO.Path]::GetTempPath()),"code-stdin-$(-join ((97..(97+25) | ForEach-Object {[char]$_}) | Get-Random -Count 3)).$ext")
            }
            $handler = {
                Param(
                    [hashtable]
                    $in
                )
                try {
                    $code = (Get-Command code -All | Where-Object { $_.CommandType -notin @('Function','Alias') })[0].Source
                    $in.StdIn | Set-Content $in.TmpFile -Force
                    & $code $in.TmpFile --wait $(($in.CodeArgs | Where-Object {$_ -ne '--wait'}) -join ' ')
                }
                catch {
                    throw
                }
                finally {
                    if (Test-Path $in.TmpFile -ErrorAction SilentlyContinue) {
                        Remove-Item $in.TmpFile -Force
                    }
                }
            }
            if (-not $in.Wait) {
                Write-Verbose "Piping input to Code as a Runspace job: `$in | Start-RSJob {code -}"
                $ind = [int]((Get-RSJob).Count) + 1
                $null = Start-RSJob -Name "_PSProfile_OpenCode_$ind" -ScriptBlock $handler -ArgumentList $in
            }
            else {
                Write-Verbose "Piping input to Code and waiting for file to exit: `$in | code -"
                .$handler($in)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Open-Code -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "GitPathMap.$wordToComplete" -FinalKeyOnly
}

Register-ArgumentCompleter -CommandName Open-Code -ParameterName Language -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    @('txt','powershell','csv','sql','xml','json','yml','csharp','fsharp','ruby','html','css','go','jsonc','javascript','typescript','less','log','python','razor','markdown') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName Open-Code -ParameterName ArgumentList -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    @('--help','--version','--new-window','--reuse-window','--goto','--diff','--wait','--locale','--install-extension','--uninstall-extension','--disable-extensions','--list-extensions','--show-versions','--enable-proposed-api','--extensions-dir','--user-data-dir','--status','--performance','--disable-gpu','--verbose','--prof-startup','--upload-logs','--add') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Open-Code'

function Open-Item {
    <#
    .SYNOPSIS
    Opens the item specified using Invoke-Item. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    .DESCRIPTION
    Opens the item specified using Invoke-Item. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    .PARAMETER Path
    The path you would like to open. Supports anything that Invoke-Item normally supports, i.e. files, folders, URIs.

    .PARAMETER Cookbook
    If you are using Chef and have your chef-repo folder in your GitPaths, this will allow you to specify a cookbook path to open from the Cookbooks subfolder.

    .EXAMPLE
    Open-Item

    Opens the current path in Explorer/Finder/etc.

    .EXAMPLE
    open

    Uses the shorter alias to open the current path

    .EXAMPLE
    open MyWorkRepo

    Opens the folder for the Git Repo 'MyWorkRepo' in Explorer/Finder/etc.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param (
        [parameter(Position = 0,ParameterSetName = 'Path')]
        [String]
        $Path = $PWD.Path
    )
    DynamicParam {
        if ($global:PSProfile.GitPathMap.ContainsKey('chef-repo')) {
            $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $true
            $ParamAttrib.ParameterSetName = 'Cookbook'
            $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $AttribColl.Add($ParamAttrib)
            $set = (Get-ChildItem (Join-Path $global:PSProfile.GitPathMap['chef-repo'] 'cookbooks') -Directory).Name
            $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($set)))
            $AttribColl.Add((New-Object System.Management.Automation.AliasAttribute('c')))
            $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Cookbook',  [string], $AttribColl)
            $RuntimeParamDic.Add('Cookbook',  $RuntimeParam)
        }
        return  $RuntimeParamDic
    }
    Begin {
        if (-not $PSBoundParameters.ContainsKey('Path')) {
            $PSBoundParameters['Path'] = $PWD.Path
        }
    }
    Process {
        $target = switch ($PSCmdlet.ParameterSetName) {
            Path {
                if ($PSBoundParameters['Path'] -eq '.') {
                    $PWD.Path
                }
                elseif ($null -ne $global:PSProfile.GitPathMap.Keys) {
                    if ($global:PSProfile.GitPathMap.ContainsKey($PSBoundParameters['Path'])) {
                        $global:PSProfile.GitPathMap[$PSBoundParameters['Path']]
                    }
                    else {
                        $PSBoundParameters['Path']
                    }
                }
                else {
                    $PSBoundParameters['Path']
                }
            }
            Cookbook {
                [System.IO.Path]::Combine($global:PSProfile.GitPathMap['chef-repo'],'cookbooks',$PSBoundParameters['Cookbook'])
            }
        }
        Write-Verbose "Running command: Invoke-Item $($PSBoundParameters[$PSCmdlet.ParameterSetName])"
        Invoke-Item $target
    }
}


Register-ArgumentCompleter -CommandName Open-Item -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "GitPathMap.$wordToComplete" -FinalKeyOnly
}


Export-ModuleMember -Function 'Open-Item'

function Pop-Path {
    <#
    .SYNOPSIS
    Pops your location back the path you Push-Path'd from.

    .DESCRIPTION
    Pops your location back the path you Push-Path'd from.

    .EXAMPLE
    Pop-Path
    #>
    [CmdletBinding()]
    Param ()
    Process {
        Write-Verbose "Popping back to previous location"
        Pop-Location
    }
}


Export-ModuleMember -Function 'Pop-Path'

function Push-Path {
    <#
    .SYNOPSIS
    Pushes your current location to the path specified. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked. Use Pop-Path to return to the location pushed from, as locations pushed from this function are within the module scope.

    .DESCRIPTION
    Pushes your current location to the path specified. Allows tab-completion of GitPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked. Use Pop-Path to return to the location pushed from, as locations pushed from this function are within the module scope.

    .PARAMETER Path
    The path you would like to push your location to.

    .PARAMETER Cookbook
    If you are using Chef and have your chef-repo folder in your GitPaths, this will allow you to specify a cookbook path to push your location to from the Cookbooks subfolder.

    .EXAMPLE
    Push-Path MyWorkRepo

    Changes your current directory to your Git Repo named 'MyWorkRepo'.

    .EXAMPLE
    push MyWorkRepo

    Same as the first example but using the shorter alias.
    #>

    [CmdletBinding()]
    Param(
        [parameter(Mandatory,Position = 0,ParameterSetName = 'Path')]
        [String]
        $Path
    )
    DynamicParam {
        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        if ($global:PSProfile.GitPathMap.ContainsKey('chef-repo')) {
            $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $true
            $ParamAttrib.ParameterSetName = 'Cookbook'
            $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $AttribColl.Add($ParamAttrib)
            $set = (Get-ChildItem (Join-Path $global:PSProfile.GitPathMap['chef-repo'] 'cookbooks') -Directory).Name
            $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($set)))
            $AttribColl.Add((New-Object System.Management.Automation.AliasAttribute('c')))
            $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Cookbook',  [string], $AttribColl)
            $RuntimeParamDic.Add('Cookbook',  $RuntimeParam)
        }
        return  $RuntimeParamDic
    }
    Process {
        $target = switch ($PSCmdlet.ParameterSetName) {
            Path {
                if ($global:PSProfile.GitPathMap.ContainsKey($PSBoundParameters['Path'])) {
                    $global:PSProfile.GitPathMap[$PSBoundParameters['Path']]
                }
                else {
                    $PSBoundParameters['Path']
                }
            }
            Cookbook {
                [System.IO.Path]::Combine($global:PSProfile.GitPathMap['chef-repo'],'cookbooks',$PSBoundParameters['Cookbook'])
            }
        }
        Write-Verbose "Pushing location to: $($target.Replace($env:HOME,'~'))"
        Push-Location $target
    }
}

Register-ArgumentCompleter -CommandName Push-Path -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "GitPathMap.$wordToComplete" -FinalKeyOnly
}


Export-ModuleMember -Function 'Push-Path'

function Start-BuildScript {
    <#
    .SYNOPSIS
    For those using the typical build.ps1 build scripts for PowerShell projects, this will allow invoking the build script quickly from wherever folder you are currently in using a child process.

    .DESCRIPTION
    For those using the typical build.ps1 build scripts for PowerShell projects, this will allow invoking the build script quickly from wherever folder you are currently in using a child process. Any projects in the ProjectPaths list that were discovered during PSProfile load and have a build.ps1 file will be able to be tab-completed for convenience. Temporarily sets the path to the build folder, invokes the build.ps1 file, then returns to the original path that it was invoked from.

    .PARAMETER Project
    The path of the project to build. Allows tab-completion of PSBuildPath aliases if ProjectPaths are filled out with PSProfile that expand to the full path when invoked.

    You can also pass the path to a folder containing a build.ps1 script, or a full path to another script entirely.

    .PARAMETER Task
    The list of Tasks to specify to the Build script.

    .PARAMETER Engine
    The engine to open the clean environment with between powershell, pwsh, and pwsh-preview. Defaults to the current engine the clean environment is opened from.

    .PARAMETER NoExit
    If $true, does not exit the child process once build.ps1 has completed and imports the built module in BuildOutput (if present to allow testing of the built project in a clean environment.

    .EXAMPLE
    Start-BuildScript MyModule -NoExit

    Changes directories to the repo root of MyModule, invokes build.ps1, imports the compiled module in a clean child process and stops before exiting to allow testing of the newly compiled module.

    .EXAMPLE
    bld MyModule -ne

    Same experience as Example 1 but uses the shorter alias 'bld' to call. Also uses the parameter alias `-ne` instead of `-NoExit`
    #>
    [CmdletBinding(PositionalBinding = $false)]
    Param (
        [Parameter(Position = 0)]
        [Alias('p')]
        [String]
        $Project,
        [Parameter(Position = 1)]
        [Alias('t')]
        [String[]]
        $Task,
        [Parameter(Position = 2)]
        [ValidateSet('powershell','pwsh','pwsh-preview')]
        [Alias('e')]
        [String]
        $Engine = $(if ($PSVersionTable.PSVersion.ToString() -match 'preview') {
            'pwsh-preview'
        }
        elseif ($PSVersionTable.PSVersion.Major -ge 6) {
            'pwsh'
        }
        else {
            'powershell'
        }),
        [parameter()]
        [Alias('ne','noe')]
        [Switch]
        $NoExit
    )
    DynamicParam {
        $bldFolder = if ([String]::IsNullOrEmpty($PSBoundParameters['Project']) -or $PSBoundParameters['Project'] -eq '.') {
            $PWD.Path
        }
        elseif ($Global:PSProfile.PSBuildPathMap.ContainsKey($PSBoundParameters['Project'])) {
            Get-LongPath -Path $PSBoundParameters['Project']
        }
        else {
            (Resolve-Path $PSBoundParameters['Project']).Path
        }
        $bldFile = if ($bldFolder -like '*.ps1') {
            $bldFolder
        }
        else {
            Join-Path $bldFolder "build.ps1"
        }
        Copy-Parameters -From $bldFile -Exclude Project,Task,Engine,NoExit
    }
    Process {
        if (-not $PSBoundParameters.ContainsKey('Project')) {
            $PSBoundParameters['Project'] = '.'
        }
        $parent = switch ($PSBoundParameters['Project']) {
            '.' {
                $PWD.Path
            }
            default {
                $global:PSProfile.PSBuildPathMap[$PSBoundParameters['Project']]
            }
        }
        $command = "$Engine -NoProfile -C `""
        $command += "Set-Location '$parent'; . .\build.ps1"
        $PSBoundParameters.Keys | Where-Object {$_ -notin @('Project','Engine','NoExit','Debug','ErrorAction','ErrorVariable','InformationAction','InformationVariable','OutBuffer','OutVariable','PipelineVariable','WarningAction','WarningVariable','Verbose','Confirm','WhatIf')} | ForEach-Object {
            if ($PSBoundParameters[$_].ToString() -in @('True','False')) {
                $command += " -$($_):```$$($PSBoundParameters[$_].ToString())"
            }
            else {
                $command += " -$($_) '$($PSBoundParameters[$_] -join "','")'"
            }
        }
        $command += '"'
        Write-Verbose "Invoking expression: $command"
        Invoke-Expression $command
        if ($NoExit) {
            Push-Location $parent
            Enter-CleanEnvironment -Engine $Engine -ImportModule
            Pop-Location
        }
    }
}

Register-ArgumentCompleter -CommandName Start-BuildScript -ParameterName Project -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "PSBuildPathMap.$wordToComplete" -FinalKeyOnly
}

Register-ArgumentCompleter -CommandName Start-BuildScript -ParameterName Task -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $bldFolder = if ([String]::IsNullOrEmpty($fakeBoundParameter.Project) -or $fakeBoundParameter.Project -eq '.') {
        $PWD.Path
    }
    elseif ($Global:PSProfile.PSBuildPathMap.ContainsKey($fakeBoundParameter.Project)) {
        Get-LongPath -Path $fakeBoundParameter.Project
    }
    else {
        (Resolve-Path $fakeBoundParameter.Project).Path
    }
    $bldFile = if ($bldFolder -like '*.ps1') {
        $bldFolder
    }
    else {
        Join-Path $bldFolder "build.ps1"
    }
    $set = if (Test-Path $bldFile) {
        ((([System.Management.Automation.Language.Parser]::ParseFile(
            $bldFile, [ref]$null, [ref]$null
        )).ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Task' }).Attributes | Where-Object { $_.TypeName.Name -eq 'ValidateSet' }).PositionalArguments.Value
    }
    else {
        @('Clean','Build','Import','Test','Deploy')
    }
    $set | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Start-BuildScript'

function Test-RegEx {
    <#
    .SYNOPSIS
    Tests a RegEx pattern against a string and returns the results.

    .DESCRIPTION
    Tests a RegEx pattern against a string and returns the results.

    .PARAMETER Pattern
    The RegEx pattern to test against the string.

    .PARAMETER String
    The string to test.

    .EXAMPLE
    Test-RegEx -Pattern '^\w+' -String 'no spaces','  spaces in front'

    Matched Pattern Matches String
    ------- ------- ------- ------
       True ^\w+    {no}    no spaces
      False ^\w+              spaces in front
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory,Position = 0)]
        [RegEx]
        $Pattern,
        [parameter(Mandatory,Position = 1,ValueFromPipeline)]
        [String[]]
        $String
    )
    Process {
        foreach ($S in $String) {
            Write-Verbose "Testing RegEx pattern '$Pattern' against string '$S'"
            $Matches = $null
            [PSCustomObject][Ordered]@{
                Matched = $($S -match $Pattern)
                Pattern = $Pattern
                Matches = $Matches.Values
                String  = $S
            }
        }
    }
}


Export-ModuleMember -Function 'Test-RegEx'

function Add-PSProfileProjectPath {
    <#
    .SYNOPSIS
    Adds a ProjectPath to your PSProfile to find Git project folders under during PSProfile refresh. These will be available via tab-completion

    .DESCRIPTION
    Adds a ProjectPath to your PSProfile to find Git project folders under during PSProfile refresh.

    .PARAMETER Path
    The path of the folder to add to your $PSProfile.ProjectPaths. This path should contain Git repo folders underneath it.

    .PARAMETER NoRefresh
    If $true, skips refreshing your PSProfile after updating.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileProjectPath -Path ~\GitRepos -Save

    Adds the folder ~\GitRepos to $PSProfile.ProjectPaths and saves the configuration after updating.

    .EXAMPLE
    Add-PSProfileProjectPath C:\Git -Verbose

    Adds the path C:\Git to your $PSProfile.ProjectPaths, refreshes your PathDict but does not save. Call Save-PSProfile after if satisfied with the results.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({if ((Get-Item $_).PSIsContainer){$true}else{throw "$_ is not a folder! Please add only folders to this PSProfile property. If you would like to add a script, use Add-PSProfileScriptPath instead."}})]
        [Alias('FullName')]
        [String[]]
        $Path,
        [Parameter()]
        [Switch]
        $NoRefresh,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($p in $Path) {
            $fP = (Resolve-Path $p).Path
            if ($Global:PSProfile.ProjectPaths -notcontains $fP) {
                Write-Verbose "Adding ProjectPath to PSProfile: $fP"
                $Global:PSProfile.ProjectPaths += $fP
            }
            else {
                Write-Verbose "ProjectPath already in PSProfile: $fP"
            }
        }
        if ($Save) {
            Save-PSProfile
        }
        if (-not $NoRefresh) {
            Update-PSProfileConfig
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileProjectPath'

function Get-PSProfileProjectPath {
    <#
    .SYNOPSIS
    Gets a project path from $PSProfile.ProjectPaths.

    .DESCRIPTION
    Gets a project path from $PSProfile.ProjectPaths.

    .PARAMETER Path
    The project path to get from $PSProfile.ProjectPaths.

    .EXAMPLE
    Get-PSProfileProjectPath -Path E:\Git

    Gets the path 'E:\Git' from $PSProfile.ProjectPaths

    .EXAMPLE
    Get-PSProfileProjectPath

    Gets the list of project paths from $PSProfile.ProjectPaths
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Path
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Path')) {
            Write-Verbose "Getting project path '$Path' from `$PSProfile.ProjectPaths"
            $Global:PSProfile.ProjectPaths | Where-Object {$_ -match "($(($Path | ForEach-Object {[regex]::Escape($_)}) -join '|'))"}
        }
        else {
            Write-Verbose "Getting all project paths from `$PSProfile.ProjectPaths"
            $Global:PSProfile.ProjectPaths
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileProjectPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ProjectPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileProjectPath'

function Remove-PSProfileProjectPath {
    <#
    .SYNOPSIS
    Removes a Project Path from $PSProfile.ProjectPaths.

    .DESCRIPTION
    Removes a Project Path from $PSProfile.ProjectPaths.

    .PARAMETER Path
    The path to remove from $PSProfile.ProjectPaths.

    .PARAMETER NoRefresh
    If $true, skips refreshing your PSProfile after updating project paths.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileProjectPath -Name E:\Git -Save

    Removes the path 'E:\Git' from $PSProfile.ProjectPaths then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $NoRefresh,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Path' from `$PSProfile.ProjectPaths")) {
            Write-Verbose "Removing '$Path' from `$PSProfile.ProjectPaths"
            $Global:PSProfile.ProjectPaths = $Global:PSProfile.ProjectPaths | Where-Object {$_ -notin @($Path,(Resolve-Path $Path).Path)}
            if (-not $NoRefresh) {
                Update-PSProfileConfig
            }
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileProjectPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ProjectPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileProjectPath'

function Add-PSProfilePrompt {
    <#
    .SYNOPSIS
    Saves the Content to $PSProfile.Prompts as the Name provided for recall later.

    .DESCRIPTION
    Saves the Content to $PSProfile.Prompts as the Name provided for recall later.

    .PARAMETER Name
    The Name to save the prompt as.

    .PARAMETER Content
    The prompt content itself.

    .PARAMETER SetAsDefault
    If $true, sets the prompt as default by updated $PSProfile.Settings.DefaultPrompt.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfilePrompt -Name Demo -Content '"PS > "'

    Saves a prompt named 'Demo' with the provided content.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [String]
        $Name = $global:PSProfile.Settings.DefaultPrompt,
        [Parameter()]
        [object]
        $Content,
        [Parameter()]
        [switch]
        $SetAsDefault,
        [Parameter()]
        [switch]
        $Save
    )
    Process {
        if ($null -eq $Name) {
            throw "No value set for the Name parameter or resolved from PSProfile!"
        }
        else {
            Write-Verbose "Saving prompt '$Name' to `$PSProfile.Prompts"
            $tempContent = if ($Content) {
                $Content.ToString()
            }
            else {
                Get-PSProfilePrompt -Raw
            }
            $cleanContent = (($tempContent -split "[\r\n]" | Where-Object {$_}) -join "`n").Trim()
            $global:PSProfile.Prompts[$Name] = $cleanContent
            if ($SetAsDefault) {
                $global:PSProfile.Settings.DefaultPrompt = $Name
            }
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfilePrompt'

function Edit-PSProfilePrompt {
    <#
    .SYNOPSIS
    Enables editing the prompt from the desired editor. Once temporary file is saved, the prompt is updated in $PSProfile.Prompts.

    .DESCRIPTION
    Enables editing the prompt from the desired editor. Once temporary file is saved, the prompt is updated in $PSProfile.Prompts.

    .PARAMETER WithInsiders
    If $true, looks for VS Code Insiders to load. If $true and code-insiders cannot be found, opens the file using VS Code stable. If $false, opens the file using VS Code stable. Defaults to $false.

    .PARAMETER Save
    If $true, saves prompt back to your PSProfile after updating.

    .EXAMPLE
    Edit-PSProfilePrompt

    Opens the current prompt as a temporary file in Visual Studio Code to edit. Once the file is saved and closed, the active prompt is updated with the changes.
    #>
    [CmdletBinding()]
    Param(
        [Alias('wi')]
        [Alias('insiders')]
        [Switch]
        $WithInsiders,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        $code = $null
        $codeCommand = if($WithInsiders) {
            @('code-insiders','code')
        }
        else {
            @('code','code-insiders')
        }
        foreach ($cmd in $codeCommand) {
            try {
                if ($found = (Get-Command $cmd -All -ErrorAction Stop | Where-Object { $_.CommandType -notin @('Function','Alias') } | Select-Object -First 1 -ExpandProperty Source)) {
                    $code = $found
                    break
                }
            }
            catch {
                $Global:Error.Remove($Global:Error[0])
            }
        }
        if ($null -eq $code){
            throw "Editor not found!"
        }
        $in = @{
            StdIn   = Get-PSProfilePrompt -Global
            TmpFile = [System.IO.Path]::Combine(([System.IO.Path]::GetTempPath()),"ps-prompt-$(-join ((97..(97+25)|%{[char]$_}) | Get-Random -Count 3)).ps1")
            Editor  = $code
        }
        $handler = {
            Param(
                [hashtable]
                $in
            )
            try {
                $in.StdIn | Set-Content $in.TmpFile -Force
                & $in.Editor $in.TmpFile --wait
            }
            catch {
                throw
            }
            finally {
                if (Test-Path $in.TmpFile -ErrorAction SilentlyContinue) {
                    Invoke-Expression ([System.IO.File]::ReadAllText($in.TmpFile))
                    Remove-Item $in.TmpFile -Force
                }
            }
        }
        Write-Verbose "Opening prompt in VS Code"
        .$handler($in)
        if ($Save) {
            Add-PSProfilePrompt -Save
        }
    }
}


Export-ModuleMember -Function 'Edit-PSProfilePrompt'

function Get-PSProfilePrompt {
    <#
    .SYNOPSIS
    Gets the current prompt's definition as a string. Useful for inspection of the prompt in use. If PSScriptAnalyzer is installed, formats the prompt for readability before returning the prompt function string.

    .DESCRIPTION
    Gets the current prompt's definition as a string. Useful for inspection of the prompt in use. If PSScriptAnalyzer is installed, formats the prompt for readability before returning the prompt function string.

    .PARAMETER Name
    The Name of the prompt from $PSProfile.Prompts to get. If excluded, gets the current prompt.

    .PARAMETER Global
    If $true, adds the global scope to the returned prompt, e.g. `function global:prompt`

    .PARAMETER NoPSSA
    If $true, does not use PowerShell Script Analyzer's Invoke-Formatter to format the resulting prompt definition.

    .PARAMETER Raw
    If $true, returns only the prompt definition and does not add the `function prompt {...}` enclosure.

    .EXAMPLE
    Get-PSProfilePrompt
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [String]
        $Name,
        [Parameter()]
        [Switch]
        $Global,
        [Parameter()]
        [Switch]
        $NoPSSA,
        [Parameter()]
        [Switch]
        $Raw
    )
    Process {
        $pContents = if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Global:PSProfile.Prompts.ContainsKey($Name)) {
                $Global:PSProfile.Prompts[$Name]
            }
            else {
                return
            }
        }
        else {
            $function:prompt
        }
        $pssa = if ($NoPSSA -or $null -eq (Get-Module PSScriptAnalyzer* -ListAvailable)) {
            $false
        }
        else {
            $true
            Import-Module PSScriptAnalyzer -Verbose:$false
        }
        Write-Verbose "Getting current prompt"
        $i = 0
        $lws = $null
        $g = if ($Global) {
            'global:prompt'
        }
        else {
            'prompt'
        }
        $header = if ($Raw) {
            ''
        }
        else {
            "function $g {`n"
        }
        $content = $pContents -split "`n" | ForEach-Object {
            if (-not [String]::IsNullOrWhiteSpace($_)) {
                if ($null -eq $lws) {
                    $lws = if ($_ -match '^\s+') {
                        $Matches.Values[0].Length
                    }
                    else {
                        $null
                    }
                }
                $_ -replace "^\s{0,$lws}",'    '
                "`n"
            }
            elseif ($i) {
                $_
                "`n"
            }
            $i++
        }
        $footer = if ($Raw) {
            ''
        }
        else {
            "}"
        }
        $p = ((@($header,(($content | Where-Object {"$_".Trim()}) -join "`n"),$footer) -split "[\r\n]") | Where-Object {"$_".Trim()}) -join "`n"
        if (-not $NoPSSA -and $pssa) {
            Write-Verbose "Formatting prompt with Invoke-Formatter"
            Invoke-Formatter $p -Verbose:$false
        }
        else {
            $p
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfilePrompt -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "Prompts.$wordToComplete" -FinalKeyOnly
}


Export-ModuleMember -Function 'Get-PSProfilePrompt'

function Remove-PSProfilePrompt {
    <#
    .SYNOPSIS
    Removes a Prompt from $PSProfile.Prompts.

    .DESCRIPTION
    Removes a Prompt from $PSProfile.Prompts.

    .PARAMETER Name
    The name of the prompt to remove from $PSProfile.Prompts.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfilePrompt -Name Demo -Save

    Removes the Prompt named 'Demo' from $PSProfile.Prompts then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing prompt '$Name' from `$PSProfile.Prompts")) {
            Write-Verbose "Removing prompt '$Name' from `$PSProfile.Prompts"
            if ($Global:PSProfile.Prompts.ContainsKey($Name)) {
                $Global:PSProfile.Prompts.Remove($Name)
            }
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfilePrompt -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Prompts.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfilePrompt'

function Switch-PSProfilePrompt {
    <#
    .SYNOPSIS
    Sets the prompt to the desired prompt by either the Name of the prompt as stored in $PSProfile.Prompts or the provided prompt content.

    .DESCRIPTION
    Sets the prompt to the desired prompt by either the Name of the prompt as stored in $PSProfile.Prompts or the provided prompt content.

    .PARAMETER Name
    The Name of the prompt to set as active from $PSProfile.Prompts.

    .PARAMETER Temporary
    If $true, does not update $PSProfile.Settings.DefaultPrompt with the selected prompt so that prompt selection does not persist after the current session.

    .PARAMETER Content
    If Content is provided as either a ScriptBlock or String, sets the current prompt to that. Equivalent to passing `function prompt {$Content}`

    .EXAMPLE
    Switch-PSProfilePrompt -Name Demo

    Sets the active prompt to the prompt named 'Demo' from $PSProfile.Prompts and saves it as the Default prompt for session persistence.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(Mandatory,Position = 0,ParameterSetName = 'Name')]
        [String]
        $Name,
        [Parameter(ParameterSetName = 'Name')]
        [switch]
        $Temporary,
        [Parameter(Mandatory,ParameterSetName = 'Content')]
        [object]
        $Content
    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            Name {
                if ($global:PSProfile.Prompts.ContainsKey($Name)) {
                    Write-Verbose "Setting active prompt to '$Name'"
                    $function:prompt = $global:PSProfile.Prompts[$Name]
                    if (-not $Temporary) {
                        $global:PSProfile.Settings.DefaultPrompt = $Name
                        Save-PSProfile
                    }
                }
                else {
                    Write-Warning "Falling back to default prompt -- '$Name' not found in Configuration prompts!"
                    $function:prompt = '
                    "PS $($executionContext.SessionState.Path.CurrentLocation)$(''>'' * ($nestedPromptLevel + 1)) ";
                    # .Link
                    # https://go.microsoft.com/fwlink/?LinkID=225750
                    # .ExternalHelp System.Management.Automation.dll-help.xml
                    '
                }
            }
            Content {
                Write-Verbose "Setting active prompt to provided content directly"
                $function:prompt = $Content
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Switch-PSProfilePrompt -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    Get-PSProfileArguments -WordToComplete "Prompts.$wordToComplete" -FinalKeyOnly
}


Export-ModuleMember -Function 'Switch-PSProfilePrompt'

function Add-PSProfileScriptPath {
    <#
    .SYNOPSIS
    Adds a ScriptPath to your PSProfile to invoke during profile load.

    .DESCRIPTION
    Adds a ScriptPath to your PSProfile to invoke during profile load.

    .PARAMETER Path
    The path of the script to add to your $PSProfile.ScriptPaths.

    .PARAMETER Invoke
    If $true, invokes the script path after adding to $PSProfile.ScriptPaths to make it immediately available in the current session.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileScriptPath -Path ~\MyProfileScript.ps1 -Save

    Adds the script 'MyProfileScript.ps1' to $PSProfile.ScriptPaths and saves the configuration after updating.

    .EXAMPLE
    Get-ChildItem .\MyProfileScripts -Recurse -File | Add-PSProfileScriptPath -Verbose

    Adds all scripts under the MyProfileScripts folder to $PSProfile.ScriptPaths but does not save to allow inspection. Call Save-PSProfile after to save the results if satisfied.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String[]]
        $Path,
        [Parameter()]
        [Switch]
        $Invoke,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($p in $Path) {
            if ($p -match '\.ps1$') {
                $fP = (Resolve-Path $p).Path
                if ($Global:PSProfile.ScriptPaths -notcontains $fP) {
                    Write-Verbose "Adding ScriptPath to PSProfile: $fP"
                    $Global:PSProfile.ScriptPaths += $fP
                }
                else {
                    Write-Verbose "ScriptPath already in PSProfile: $fP"
                }
                if ($Invoke) {
                    . $fp
                }
            }
            else {
                Write-Verbose "Skipping non-ps1 file: $fP"
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileScriptPath'

function Get-PSProfileScriptPath {
    <#
    .SYNOPSIS
    Gets a script path from $PSProfile.ScriptPaths.

    .DESCRIPTION
    Gets a script path from $PSProfile.ScriptPaths.

    .PARAMETER Path
    The script path to get from $PSProfile.ScriptPaths.

    .EXAMPLE
    Get-PSProfileScriptPath -Path E:\Git\MyProfileScript.ps1

    Gets the path 'E:\Git\MyProfileScript.ps1' from $PSProfile.ScriptPaths

    .EXAMPLE
    Get-PSProfileScriptPath

    Gets the list of script paths from $PSProfile.ScriptPaths
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $Path
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Path')) {
            Write-Verbose "Getting script path '$Path' from `$PSProfile.ScriptPaths"
            $Global:PSProfile.ScriptPaths | Where-Object {$_ -match "($(($Path | ForEach-Object {[regex]::Escape($_)}) -join '|'))"}
        }
        else {
            Write-Verbose "Getting all script paths from `$PSProfile.ScriptPaths"
            $Global:PSProfile.ScriptPaths
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileScriptPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ScriptPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileScriptPath'

function Remove-PSProfileScriptPath {
    <#
    .SYNOPSIS
    Removes a Script Path from $PSProfile.ScriptPaths.

    .DESCRIPTION
    Removes a Script Path from $PSProfile.ScriptPaths.

    .PARAMETER Path
    The path to remove from $PSProfile.ScriptPaths.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileScriptPath -Name ~\Scripts\ProfileLoadScript.ps1 -Save

    Removes the path '~\Scripts\ProfileLoadScript.ps1' from $PSProfile.ScriptPaths then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
        [String]
        $Path,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Path' from `$PSProfile.ScriptPaths")) {
            Write-Verbose "Removing '$Path' from `$PSProfile.ScriptPaths"
            $Global:PSProfile.ScriptPaths = $Global:PSProfile.ScriptPaths | Where-Object {$_ -notin @($Path,(Resolve-Path $Path).Path)}
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileScriptPath -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.ScriptPaths | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileScriptPath'

function Add-PSProfileSecret {
    <#
    .SYNOPSIS
    Adds a PSCredential object or named SecureString to the PSProfile Vault then saves the current PSProfile.

    .DESCRIPTION
    Adds a PSCredential object or named SecureString to the PSProfile Vault then saves the current PSProfile.

    .PARAMETER Credential
    The PSCredential to add to the Vault. PSCredentials are recallable by the UserName from the stored PSCredential object via either `Get-MyCreds` or `Get-PSProfileSecret -UserName $UserName`.

    .PARAMETER Name
    For SecureString secrets, the friendly name to store them as for easy recall later via `Get-PSProfileSecret`.

    .PARAMETER SecureString
    The SecureString to store as the provided Name for recall later.

    .PARAMETER Force
    If $true and the PSCredential's UserName or SecureString's Name already exists, it overwrites it. Defaults to $false to prevent accidentally overwriting existing secrets in the $PSProfile.Vault.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileSecret (Get-Credential) -Save

    Opens a Get-Credential window or prompt to enable entering credentials securely, then stores it in the Vault and saves your PSProfile configuration after updating.

    .EXAMPLE
    Add-PSProfileSecret -Name HomeApiKey -Value (ConvertTo-SecureString 1234567890xxx -AsPlainText -Force) -Save

    Stores the secret value '1234567890xxx' as the name 'HomeApiKey' in $PSProfile.Vault and saves your PSProfile configuration after updating.
    #>
    [CmdletBinding(DefaultParameterSetName = "PSCredential")]
    Param (
        [Parameter(Mandatory,ValueFromPipeline,Position = 0,ParameterSetName = "PSCredential")]
        [pscredential]
        $Credential,
        [Parameter(Mandatory,ParameterSetName = "SecureString")]
        [string]
        $Name,
        [Parameter(Mandatory,ParameterSetName = "SecureString")]
        [securestring]
        $SecureString,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            PSCredential {
                if ($Force -or -not $Global:PSProfile.Vault._secrets.ContainsKey($Credential.UserName)) {
                    Write-Verbose "Adding PSCredential for user '$($Credential.UserName)' to `$PSProfile.Vault"
                    $Global:PSProfile.Vault._secrets[$Credential.UserName] = $Credential
                    if ($Save) {
                        Save-PSProfile
                    }
                }
                elseif (-not $Force -and $Global:PSProfile.Vault._secrets.ContainsKey($Credential.UserName)) {
                    Write-Error "A secret with the name '$($Credential.UserName)' already exists! Include -Force to overwrite it."
                }
            }
            SecureString {
                if ($Force -or -not $Global:PSProfile.Vault._secrets.ContainsKey($Name)) {
                    Write-Verbose "Adding SecureString secret with name '$Name' to `$PSProfile.Vault"
                    $Global:PSProfile.Vault._secrets[$Name] = $SecureString
                    if ($Save) {
                        Save-PSProfile
                    }
                }
                elseif (-not $Force -and $Global:PSProfile.Vault._secrets.ContainsKey($Name)) {
                    Write-Error "A secret with the name '$Name' already exists! Include -Force to overwrite it."
                }
            }
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileSecret'

function Get-MyCreds {
    <#
    .SYNOPSIS
    Gets a credential object from the PSProfile Vault. Defaults to getting your current user's PSCredentials if stored in the Vault.

    .DESCRIPTION
    Gets a credential object from the PSProfile Vault. Defaults to getting your current user's PSCredentials if stored in the Vault.

    .PARAMETER Item
    The name of the Secret you would like to retrieve from the Vault.

    .PARAMETER IncludeDomain
    If $true, prepends the domain found in $env:USERDOMAIN to the Username on the PSCredential object before returning it. If not currently in a domain, prepends the MachineName instead.

    .EXAMPLE
    Get-MyCreds

    Gets the current user's PSCredentials from the Vault.

    .EXAMPLE
    Invoke-Command -ComputerName Server01 -Credential (Creds)

    Passes your current user credentials via the `Creds` alias to the Credential parameter of Invoke-Command to make a call against Server01 using your PSCredential

    .EXAMPLE
    Invoke-Command -ComputerName Server01 -Credential (Get-MyCreds SvcAcct07)

    Passes the credentials for account SvcAcct07 to the Credential parameter of Invoke-Command to make a call against Server01 using a different PSCredential than your own.
    #>
    [OutputType('PSCredential')]
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $false,Position = 0)]
        [String]
        $Item = $(if ($env:USERNAME) {
                $env:USERNAME
            }
            elseif ($env:USER) {
                $env:USER
            }),
        [parameter(Mandatory = $false)]
        [Alias('d','Domain')]
        [Switch]
        $IncludeDomain
    )
    Process {
        if ($Item) {
            Write-Verbose "Checking Credential Vault for user '$Item'"
            if ($creds = $global:PSProfile.Vault._secrets[$Item]) {
                Write-Verbose "Found item in CredStore"
                if (!$env:USERDOMAIN) {
                    $env:USERDOMAIN = [System.Environment]::MachineName
                }
                if ($IncludeDomain -and $creds.UserName -notlike "$($env:USERDOMAIN)\*") {
                    $creds = New-Object PSCredential "$($env:USERDOMAIN)\$($creds.UserName)",$creds.Password
                }
                return $creds
            }
            else {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ([System.Management.Automation.ItemNotFoundException]"Could not find secret '$Item' in `$PSProfile.Vault"),
                        'PSProfile.Vault.SecretNotFound',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $global:PSProfile
                    )
                )
            }
        }
        else {
            $global:PSProfile.Vault._secrets
        }
    }
}

Register-ArgumentCompleter -CommandName Get-MyCreds -ParameterName Item -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Vault._secrets.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-MyCreds'

function Get-PSProfileSecret {
    <#
    .SYNOPSIS
    Gets a Secret from the $PSProfile.Vault.

    .DESCRIPTION
    Gets a Secret from the $PSProfile.Vault.

    .PARAMETER Name
    The name of the Secret you would like to retrieve from the Vault. If excluded, returns the entire Vault contents.

    .PARAMETER AsPlainText
    If $true and Confirm:$true, returns the decrypted password if the secret is a PSCredential object or the plain-text string if a SecureString. Requires confirmation.

    .PARAMETER Force
    If $true and AsPlainText is $true, bypasses Confirm prompt and returns the plain-text password or decrypted SecureString.

    .EXAMPLE
    Get-PSProfileSecret -Name MyApiKey

    Gets the Secret named 'MyApiKey' from the $PSProfile.Vault.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param(
        [parameter(Position = 0)]
        [String]
        $Name,
        [parameter()]
        [Switch]
        $AsPlainText,
        [parameter()]
        [Switch]
        $Force
    )
    Process {
        if ($Name) {
            Write-Verbose "Getting Secret '$Name' from `$PSProfile.Vault"
            if ($sec = $global:PSProfile.Vault._secrets[$Name]) {
                if ($AsPlainText -and ($Force -or $PSCmdlet.ShouldProcess("Return plain-text value for Secret '$Name'"))) {
                    if ($sec -is [pscredential]) {
                        [PSCustomObject]@{
                            UserName = $sec.UserName
                            Password = $sec.GetNetworkCredential().Password
                        }
                    }
                    else {
                        Get-DecryptedValue $sec
                    }
                }
                else {
                    $sec
                }
            }
        }
        else {
            Write-Verbose "Getting all Secrets"
            $global:PSProfile.Vault._secrets
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileSecret -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Vault._secrets.Keys | Where-Object {$_ -notin @('GitCredentials','PSCredentials','SecureStrings') -and $_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileSecret'

function Remove-PSProfileSecret {
    <#
    .SYNOPSIS
    Removes a Secret from $PSProfile.Vault.

    .DESCRIPTION
    Removes a Secret from $PSProfile.Vault.

    .PARAMETER Name
    The Secret's Name or UserName to remove from the Vault.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileSecret -Name $env:USERNAME -Save

    Removes the current user's stored credentials from the $PSProfile.Vault, then saves the configuration after updating.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [Alias('UserName')]
        [String]
        $Name,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Removing '$Name' from `$PSProfile.Vault")) {
            if ($Global:PSProfile.Vault._secrets.ContainsKey($Name)) {
                Write-Verbose "Removing '$Name' from `$PSProfile.Vault"
                $Global:PSProfile.Vault._secrets.Remove($Name) | Out-Null
            }
            if ($Save) {
                Save-PSProfile
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileSecret -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Vault._secrets.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileSecret'

function Add-PSProfileSymbolicLink {
    <#
    .SYNOPSIS
    Adds a SymbolicLink to set if missing during profile load via background task.

    .DESCRIPTION
    Adds a SymbolicLink to set if missing during profile load via background task.

    .PARAMETER LinkPath
    The path of the symbolic link to create if missing.

    .PARAMETER ActualPath
    The actual target path of the symbolic link to set.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileSymbolicLink -LinkPath C:\workstation -ActualPath E:\Git\workstation -Save

    Adds a symbolic link at path 'C:\workstation' targeting the actual path 'E:\Git\workstation' and saves your PSProfile configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [Alias('Path','Name')]
        [String]
        $LinkPath,
        [Parameter(Mandatory,Position = 1)]
        [Alias('Target','Value')]
        [String]
        $ActualPath,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        Write-Verbose "Adding SymbolicLink '$LinkPath' pointing at ActualPath '$ActualPath'"
        $Global:PSProfile.SymbolicLinks[$LinkPath] = $ActualPath
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileSymbolicLink'

function Get-PSProfileSymbolicLink {
    <#
    .SYNOPSIS
    Gets a module from $PSProfile.SymbolicLinks.

    .DESCRIPTION
    Gets a module from $PSProfile.SymbolicLinks.

    .PARAMETER LinkPath
    The LinkPath to get from $PSProfile.SymbolicLinks.

    .EXAMPLE
    Get-PSProfileSymbolicLink -LinkPath C:\workstation

    Gets the LinkPath 'C:\workstation' from $PSProfile.SymbolicLinks

    .EXAMPLE
    Get-PSProfileSymbolicLink

    Gets the list of LinkPaths from $PSProfile.SymbolicLinks
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0,ValueFromPipeline)]
        [String[]]
        $LinkPath
    )
    Process {
        if ($PSBoundParameters.ContainsKey('LinkPath')) {
            Write-Verbose "Getting Path LinkPath '$LinkPath' from `$PSProfile.SymbolicLinks"
            $Global:PSProfile.SymbolicLinks.GetEnumerator() | Where-Object {$_.Key -in $LinkPath}
        }
        else {
            Write-Verbose "Getting all command aliases from `$PSProfile.SymbolicLinks"
            $Global:PSProfile.SymbolicLinks
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileSymbolicLink -ParameterName LinkPath -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.SymbolicLinks.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileSymbolicLink'

function Remove-PSProfileSymbolicLink {
    <#
    .SYNOPSIS
    Removes a Symbolic Link from $PSProfile.SymbolicLinks.

    .DESCRIPTION
    Removes a PSProfile Plugin from $PSProfile.SymbolicLinks.

    .PARAMETER LinkPath
    The path of the symbolic link to remove from $PSProfile.SymbolicLinks.

    .PARAMETER Force
    If $true, also removes the SymbolicLink itself from the OS if it exists.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileSymbolicLink -LinkPath 'C:\workstation' -Force -Save

    Removes the SymbolicLink 'C:\workstation' from $PSProfile.SymbolicLinks, removes the  then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String[]]
        $LinkPath,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($path in $LinkPath) {
            if ($PSCmdlet.ShouldProcess("Removing '$path' from `$PSProfile.SymbolicLinks")) {
                Write-Verbose "Removing '$path' from `$PSProfile.SymbolicLinks"
                $paths = @($path)
                if (Test-Path $path) {
                    $paths += (Resolve-Path $path).Path
                }
                $paths | Select-Object -Unique | ForEach-Object {
                    if ($Global:PSProfile.SymbolicLinks.ContainsKey($_)) {
                        $Global:PSProfile.SymbolicLinks.Remove($_)
                    }
                }
                if ($Force -and (Test-Path $path)) {
                    Write-Verbose "Removing SymbolicLink: $path"
                    Remove-Item $path -Force
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileSymbolicLink -ParameterName LinkPath -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.SymbolicLinks.Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileSymbolicLink'

function Add-PSProfileVariable {
    <#
    .SYNOPSIS
    Adds a global or environment variable to your PSProfile configuration. Variables added to PSProfile will be set during profile load.

    .DESCRIPTION
    Adds a global or environment variable to your PSProfile configuration. Variables added to PSProfile will be set during profile load.

    .PARAMETER Name
    The name of the variable.

    .PARAMETER Value
    The value to set the variable to.

    .PARAMETER Scope
    The scope of the variable to set between Environment or Global. Defaults to Environment.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Add-PSProfileVariable -Name HomeBase -Value C:\HomeBase -Save

    Adds the environment variable named 'HomeBase' to be set to the path 'C:\HomeBase' during profile load and saves your PSProfile configuration.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position = 0)]
        [String]
        $Name,
        [Parameter(Mandatory,Position = 1)]
        [Object]
        $Value,
        [Parameter(Position = 2)]
        [ValidateSet('Environment','Global')]
        [String]
        $Scope = 'Environment',
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        if (-not ($Global:PSProfile.Variables.ContainsKey($Scope))) {
            $Global:PSProfile.Variables[$Scope] = @{}
        }
        Write-Verbose "Adding $Scope variable '$Name' to PSProfile"
        $Global:PSProfile.Variables[$Scope][$Name] = $Value
        if ($Save) {
            Save-PSProfile
        }
    }
}


Export-ModuleMember -Function 'Add-PSProfileVariable'

function Get-PSProfileVariable {
    <#
    .SYNOPSIS
    Gets a global or environment variable from your PSProfile configuration.

    .DESCRIPTION
    Gets a global or environment variable from your PSProfile configuration.

    .PARAMETER Scope
    The scope of the variable to get the variable from between Environment or Global.

    .PARAMETER Name
    The name of the variable to get.

    .EXAMPLE
    Get-PSProfileVariable -Name HomeBase

    Gets the environment variable named 'HomeBase' and its value from $PSProfile.Variables.

    .EXAMPLE
    Get-PSProfileVariable

    Gets the list of environment variables from $PSProfile.Variables.

    .EXAMPLE
    Get-PSProfileVariable -Scope Global

    Gets the list of Global variables from $PSProfile.Variables.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Environment','Global')]
        [String]
        $Scope,
        [Parameter(Position = 1)]
        [String]
        $Name
    )
    Process {
        if ($Global:PSProfile.Variables.ContainsKey($Scope)) {
            if ($PSBoundParameters.ContainsKey('Name')) {
                Write-Verbose "Getting $Scope variable '$Name' from PSProfile"
                $Global:PSProfile.Variables[$Scope].GetEnumerator() | Where-Object {$_.Key -in $Name}
            }
            else {
                Write-Verbose "Getting $Scope variable list from PSProfile"
                $Global:PSProfile.Variables[$Scope]
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-PSProfileVariable -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Variables[$fakeBoundParameter.Scope].Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Get-PSProfileVariable'

function Remove-PSProfileVariable {
    <#
    .SYNOPSIS
    Removes a Variable from $PSProfile.Variables.

    .DESCRIPTION
    Removes a Variable from $PSProfile.Variables.

    .PARAMETER Name
    The name of the Variable to remove from $PSProfile.Variables.

    .PARAMETER Scope
    The scope of the Variable to remove between Environment or Global.

    .PARAMETER Force
    If $true, also removes the variable from the current session at the specified scope.

    .PARAMETER Save
    If $true, saves the updated PSProfile after updating.

    .EXAMPLE
    Remove-PSProfileVariable -Scope Environment -Name '~' -Save

    Removes the Environment variable '~' from $PSProfile.Variables then saves the updated configuration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
    Param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Environment','Global')]
        [String]
        $Scope,
        [Parameter(Mandatory,Position = 1)]
        [String[]]
        $Name,
        [Parameter()]
        [Switch]
        $Force,
        [Parameter()]
        [Switch]
        $Save
    )
    Process {
        foreach ($item in $Name) {
            if ($PSCmdlet.ShouldProcess("Removing $Scope variable '$item' from `$PSProfile.Variables")) {
                Write-Verbose "Removing $Scope variable '$item' from `$PSProfile.Variables"
                if ($Global:PSProfile.Variables[$Scope].ContainsKey($item)) {
                    $Global:PSProfile.Variables[$Scope].Remove($item)
                }
                if ($Force) {
                    switch ($Scope) {
                        Environment {
                            Remove-Item "Env:\$item"
                        }
                        Global {
                            Remove-Variable -Name $item -Scope Global
                        }
                    }
                }
            }
        }
        if ($Save) {
            Save-PSProfile
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-PSProfileVariable -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $Global:PSProfile.Variables[$fakeBoundParameter.Scope].Keys | Where-Object {$_ -like "$wordToComplete*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Export-ModuleMember -Function 'Remove-PSProfileVariable'

New-Alias -Name 'Copy-DynamicParameters' -Value 'Copy-Parameters' -Scope Global -Force
Export-ModuleMember -Alias 'Copy-DynamicParameters'
New-Alias -Name 'Load-PSProfile' -Value 'Import-PSProfile' -Scope Global -Force
Export-ModuleMember -Alias 'Load-PSProfile'
New-Alias -Name 'bld' -Value 'Start-BuildScript' -Scope Global -Force
Export-ModuleMember -Alias 'bld'
New-Alias -Name 'open' -Value 'Open-Item' -Scope Global -Force
Export-ModuleMember -Alias 'open'
New-Alias -Name 'push' -Value 'Push-Path' -Scope Global -Force
Export-ModuleMember -Alias 'push'
New-Alias -Name 'Switch-Prompt' -Value 'Switch-PSProfilePrompt' -Scope Global -Force
Export-ModuleMember -Alias 'Switch-Prompt'
New-Alias -Name 'Save-Prompt' -Value 'Add-PSProfilePrompt' -Scope Global -Force
Export-ModuleMember -Alias 'Save-Prompt'
New-Alias -Name 'Remove-Prompt' -Value 'Remove-PSProfilePrompt' -Scope Global -Force
Export-ModuleMember -Alias 'Remove-Prompt'
New-Alias -Name 'pop' -Value 'Pop-Path' -Scope Global -Force
Export-ModuleMember -Alias 'pop'
New-Alias -Name 'path' -Value 'Get-LongPath' -Scope Global -Force
Export-ModuleMember -Alias 'path'
New-Alias -Name 'cln' -Value 'Enter-CleanEnvironment' -Scope Global -Force
Export-ModuleMember -Alias 'cln'
New-Alias -Name 'def' -Value 'Get-Definition' -Scope Global -Force
Export-ModuleMember -Alias 'def'
New-Alias -Name 'Edit-Prompt' -Value 'Edit-PSProfilePrompt' -Scope Global -Force
Export-ModuleMember -Alias 'Edit-Prompt'
New-Alias -Name 'Creds' -Value 'Get-MyCreds' -Scope Global -Force
Export-ModuleMember -Alias 'Creds'
New-Alias -Name 'syntax' -Value 'Format-Syntax' -Scope Global -Force
Export-ModuleMember -Alias 'syntax'
New-Alias -Name 'Refresh-PSProfile' -Value 'Update-PSProfileConfig' -Scope Global -Force
Export-ModuleMember -Alias 'Refresh-PSProfile'
New-Alias -Name 'Get-Prompt' -Value 'Get-PSProfilePrompt' -Scope Global -Force
Export-ModuleMember -Alias 'Get-Prompt'
$global:PSProfile = [PSProfile]::new()
$global:PSProfile.Load()
Export-ModuleMember -Variable PSProfile
$global:PSProfileConfigurationWatcher = [System.IO.FileSystemWatcher]::new($(Split-Path $global:PSProfile.Settings.ConfigurationPath -Parent),'Configuration.psd1')
$job = Register-ObjectEvent -InputObject $global:PSProfileConfigurationWatcher -EventName Changed -Action {
    [PSProfile]$conf = Import-Configuration -Name PSProfile -CompanyName 'SCRT HQ' -Verbose:$false
    $conf._internal = $global:PSProfile._internal
    $global:PSProfile = $conf
}
$PSProfile_OnRemoveScript = {
    try {
        $global:PSProfileConfigurationWatcher.Dispose()
    }
    finally {
        Remove-Variable PSProfile -Scope Global -Force
        Remove-Variable PSProfileConfigurationWatcher -Scope Global -Force
    }
}
$ExecutionContext.SessionState.Module.OnRemove += $PSProfile_OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $PSProfile_OnRemoveScript


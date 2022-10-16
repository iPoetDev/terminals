function Add-ToArrayAdvanced {
    [CmdletBinding()]
    param([System.Collections.ArrayList] $List,
        [Object] $Element,
        [switch] $SkipNull,
        [switch] $RequireUnique,
        [switch] $FullComparison,
        [switch] $Merge)
    if ($SkipNull -and $null -eq $Element) { return }
    if ($RequireUnique) {
        if ($FullComparison) {
            foreach ($ListElement in $List) {
                if ($ListElement -eq $Element) {
                    $TypeLeft = Get-ObjectType -Object $ListElement
                    $TypeRight = Get-ObjectType -Object $Element
                    if ($TypeLeft.ObjectTypeName -eq $TypeRight.ObjectTypeName) { return }
                }
            }
        } else { if ($List -contains $Element) { return } }
    }
    if ($Merge) { [void] $List.AddRange($Element) } else { [void] $List.Add($Element) }
}
function Connect-WinService {
    [CmdletBinding()]
    param ([Object] $Credentials,
        [Object] $Service,
        [string] $Type,
        [switch] $Output)
    $Object = @()
    if ($Service.Use) {
        switch ($Type) {
            'ActiveDirectory' {
                $CheckAvailabilityCommandsAD = Test-AvailabilityCommands -Commands 'Get-ADForest', 'Get-ADDomain', 'Get-ADRootDSE', 'Get-ADGroup', 'Get-ADUser', 'Get-ADComputer'
                if ($CheckAvailabilityCommandsAD -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Commands unavailable.' }
                        return $Object
                    } else {
                        Write-Warning "Active Directory documentation can't be started as commands are unavailable. Check if you have Active Directory module available (part of RSAT) and try again."
                        return
                    }
                } else { }
                if (-not (Test-ForestConnectivity)) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'No connectivity to forest/domain.' }
                        return $Object
                    } else {
                        Write-Warning 'Active Directory - No connectivity to forest/domain.'
                        return
                    }
                } else { }
                if ($Output) {
                    $Object += @{Status = $true; Output = $Service.SessionName; Extended = 'Connection Established.' }
                    return $Object
                }
            }
            'Azure' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinAzure -SessionName $Service.SessionName -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Output
                return $OutputCommand
            }
            'AzureAD' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinAzureAD -SessionName $Service.SessionName -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Output
                return $OutputCommand
            }
            'Exchange' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Document.DocumentExchange.Configuration -AllowEmptyKeys 'Username', 'Password'
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinExchange -SessionName $Service.SessionName -ConnectionURI $Service.ConnectionURI -Authentication $Service.Authentication -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Prefix $Service.Prefix -Output
                return $OutputCommand
            }
            'ExchangeOnline' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinExchange -SessionName $Service.SessionName -ConnectionURI $Service.ConnectionURI -Authentication $Service.Authentication -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Prefix $Service.Prefix -Output
                return $OutputCommand
            }
            'SecurityCompliance' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinSecurityCompliance -SessionName $Service.SessionName -ConnectionURI $Service.ConnectionURI -Authentication $Service.Authentication -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Prefix $Service.Prefix -Output
                return $OutputCommand
            }
            'SharePointOnline' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinSharePoint -SessionName $Service.SessionName -ConnectionURI $Service.ConnectionURI -Authentication $Service.Authentication -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Prefix $Service.Prefix -Output
                return $OutputCommand
            }
            'SkypeOnline' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinSkype -SessionName $Service.SessionName -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Prefix $Service.Prefix -Output
                return $OutputCommand
            }
            'MicrosoftTeams' {
                $CheckCredentials = Test-ConfigurationCredentials -Configuration $Credentials
                if ($CheckCredentials.Status -contains $false) {
                    if ($Output) {
                        $Object += @{Status = $false; Output = $Service.SessionName; Extended = 'Credentials configuration is wrong.' }
                        return $Object
                    } else { return }
                }
                $OutputCommand = Connect-WinTeams -SessionName $Service.SessionName -Username $Credentials.Username -Password $Credentials.Password -AsSecure:$Credentials.PasswordAsSecure -FromFile:$Credentials.PasswordFromFile -MultiFactorAuthentication:$Credentials.MultiFactorAuthentication -Output
                return $OutputCommand
            }
        }
    }
}
function Convert-KeyToKeyValue {
    [CmdletBinding()]
    param ([object] $Object)
    $NewHash = [ordered] @{ }
    foreach ($O in $Object.Keys) {
        $KeyName = "$O ($($Object.$O))"
        $KeyValue = $Object.$O
        $NewHash.$KeyName = $KeyValue
    }
    return $NewHash
}
function Convert-TwoArraysIntoOne {
    [CmdletBinding()]
    param ($Object,
        $ObjectToAdd)
    $Value = for ($i = 0; $i -lt $Object.Count; $i++) { "$($Object[$i]) ($($ObjectToAdd[$i]))" }
    return $Value
}
function Get-ObjectKeys {
    param([object] $Object,
        [string] $Ignore)
    $Data = $Object.Keys | where { $_ -notcontains $Ignore }
    return $Data
}
function Get-ObjectType {
    [CmdletBinding()]
    param([Object] $Object,
        [string] $ObjectName = 'Random Object Name',
        [switch] $VerboseOnly)
    $ReturnData = [ordered] @{ }
    $ReturnData.ObjectName = $ObjectName
    if ($Object -ne $null) {
        try {
            $TypeInformation = $Object.GetType()
            $ReturnData.ObjectTypeName = $TypeInformation.Name
            $ReturnData.ObjectTypeBaseName = $TypeInformation.BaseType
            $ReturnData.SystemType = $TypeInformation.UnderlyingSystemType
        } catch {
            $ReturnData.ObjectTypeName = ''
            $ReturnData.ObjectTypeBaseName = ''
            $ReturnData.SystemType = ''
        }
        try {
            $TypeInformationInsider = $Object[0].GetType()
            $ReturnData.ObjectTypeInsiderName = $TypeInformationInsider.Name
            $ReturnData.ObjectTypeInsiderBaseName = $TypeInformationInsider.BaseType
            $ReturnData.SystemTypeInsider = $TypeInformationInsider.UnderlyingSystemType
        } catch {
            $ReturnData.ObjectTypeInsiderName = ''
            $ReturnData.ObjectTypeInsiderBaseName = ''
            $ReturnData.SystemTypeInsider = ''
        }
    } else {
        $ReturnData.ObjectTypeName = ''
        $ReturnData.ObjectTypeBaseName = ''
        $ReturnData.SystemType = ''
        $ReturnData.ObjectTypeInsiderName = ''
        $ReturnData.ObjectTypeInsiderBaseName = ''
        $ReturnData.SystemTypeInsider = ''
    }
    Write-Verbose "Get-ObjectType - ObjectTypeName: $($ReturnData.ObjectTypeName)"
    Write-Verbose "Get-ObjectType - ObjectTypeBaseName: $($ReturnData.ObjectTypeBaseName)"
    Write-Verbose "Get-ObjectType - SystemType: $($ReturnData.SystemType)"
    Write-Verbose "Get-ObjectType - ObjectTypeInsiderName: $($ReturnData.ObjectTypeInsiderName)"
    Write-Verbose "Get-ObjectType - ObjectTypeInsiderBaseName: $($ReturnData.ObjectTypeInsiderBaseName)"
    Write-Verbose "Get-ObjectType - SystemTypeInsider: $($ReturnData.SystemTypeInsider)"
    if ($VerboseOnly) { return } else { return Format-TransposeTable -Object $ReturnData }
}
function New-ArrayList {
    [CmdletBinding()]
    param()
    $List = [System.Collections.ArrayList]::new()
    return , $List
}
function Send-SqlInsert {
    [CmdletBinding()]
    param([Array] $Object,
        [System.Collections.IDictionary] $SqlSettings)
    if ($SqlSettings.SqlTableTranspose) { $Object = Format-TransposeTable -Object $Object }
    $SqlTable = Get-SqlQueryColumnInformation -SqlServer $SqlSettings.SqlServer -SqlDatabase $SqlSettings.SqlDatabase -Table $SqlSettings.SqlTable
    $PropertiesFromAllObject = Get-ObjectPropertiesAdvanced -Object $Object -AddProperties 'AddedWhen', 'AddedWho'
    $PropertiesFromTable = $SqlTable.Column_name
    if ($SqlTable -eq $null) {
        if ($SqlSettings.SqlTableCreate) {
            Write-Verbose "Send-SqlInsert - SqlTable doesn't exists, table creation is allowed, mapping will be done either on properties from object or from TableMapping defined in config"
            $TableMapping = New-SqlTableMapping -SqlTableMapping $SqlSettings.SqlTableMapping -Object $Object -Properties $PropertiesFromAllObject
            $CreateTableSQL = New-SqlQueryCreateTable -SqlSettings $SqlSettings -TableMapping $TableMapping
        } else {
            Write-Verbose "Send-SqlInsert - SqlTable doesn't exists, no table creation is allowed. Terminating"
            return "Error occured: SQL Table doesn't exists. SqlTableCreate option is disabled"
        }
    } else {
        if ($SqlSettings.SqlTableAlterIfNeeded) {
            if ($SqlSettings.SqlTableMapping) {
                Write-Verbose "Send-SqlInsert - Sql Table exists, Alter is allowed, but SqlTableMapping is already defined"
                $TableMapping = New-SqlTableMapping -SqlTableMapping $SqlSettings.SqlTableMapping -Object $Object -Properties $PropertiesFromAllObject
            } else {
                Write-Verbose "Send-SqlInsert - Sql Table exists, Alter is allowed, and SqlTableMapping is not defined"
                $TableMapping = New-SqlTableMapping -SqlTableMapping $SqlSettings.SqlTableMapping -Object $Object -Properties $PropertiesFromAllObject
                $AlterTableSQL = New-SqlQueryAlterTable -SqlSettings $SqlSettings -TableMapping $TableMapping -ExistingColumns $SqlTable.Column_name
            }
        } else {
            if ($SqlSettings.SqlTableMapping) {
                Write-Verbose "Send-SqlInsert - Sql Table exists, Alter is not allowed, SqlTableMaping is already defined"
                $TableMapping = New-SqlTableMapping -SqlTableMapping $SqlSettings.SqlTableMapping -Object $Object -Properties $PropertiesFromAllObject
            } else {
                Write-Verbose "Send-SqlInsert - Sql Table exists, Alter is not allowed, SqlTableMaping is not defined, using SqlTable Columns"
                $TableMapping = New-SqlTableMapping -SqlTableMapping $SqlSettings.SqlTableMapping -Object $Object -Properties $PropertiesFromTable -BasedOnSqlTable
            }
        }
    }
    $Queries = @(if ($CreateTableSQL) { foreach ($Sql in $CreateTableSQL) { $Sql } }
        if ($AlterTableSQL) { foreach ($Sql in $AlterTableSQL) { $Sql } }
        $SqlQueries = New-SqlQuery -Object $Object -SqlSettings $SqlSettings -TableMapping $TableMapping
        foreach ($Sql in $SqlQueries) { $Sql })
    $ReturnData = foreach ($Query in $Queries) {
        try {
            if ($Query) {
                $Query
                Invoke-DbaQuery -SqlInstance "$($SqlSettings.SqlServer)" -Database "$($SqlSettings.SqlDatabase)" -Query $Query -ErrorAction Stop
            }
        } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            "Error occured (Send-SqlInsert): $ErrorMessage"
        }
    }
    return $ReturnData
}
function Start-TimeLog {
    [CmdletBinding()]
    param()
    [System.Diagnostics.Stopwatch]::StartNew()
}
function Stop-TimeLog {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline = $true)][System.Diagnostics.Stopwatch] $Time,
        [ValidateSet('OneLiner', 'Array')][string] $Option = 'OneLiner',
        [switch] $Continue)
    Begin { }
    Process { if ($Option -eq 'Array') { $TimeToExecute = "$($Time.Elapsed.Days) days", "$($Time.Elapsed.Hours) hours", "$($Time.Elapsed.Minutes) minutes", "$($Time.Elapsed.Seconds) seconds", "$($Time.Elapsed.Milliseconds) milliseconds" } else { $TimeToExecute = "$($Time.Elapsed.Days) days, $($Time.Elapsed.Hours) hours, $($Time.Elapsed.Minutes) minutes, $($Time.Elapsed.Seconds) seconds, $($Time.Elapsed.Milliseconds) milliseconds" } }
    End {
        if (-not $Continue) { $Time.Stop() }
        return $TimeToExecute
    }
}
function Write-Color {
    <#
	.SYNOPSIS
        Write-Color is a wrapper around Write-Host.

        It provides:
        - Easy manipulation of colors,
        - Logging output to file (log)
        - Nice formatting options out of the box.

	.DESCRIPTION
        Author: przemyslaw.klys at evotec.pl
        Project website: https://evotec.xyz/hub/scripts/write-color-ps1/
        Project support: https://github.com/EvotecIT/PSWriteColor

        Original idea: Josh (https://stackoverflow.com/users/81769/josh)

	.EXAMPLE
    Write-Color -Text "Red ", "Green ", "Yellow " -Color Red,Green,Yellow

    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
					"Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan

    .EXAMPLE
	Write-Color -Text "This is text in Green ",
					"followed by red ",
					"and then we have Magenta... ",
					"isn't it fun? ",
                    "Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan -StartTab 3 -LinesBefore 1 -LinesAfter 1

    .EXAMPLE
	Write-Color "1. ", "Option 1" -Color Yellow, Green
	Write-Color "2. ", "Option 2" -Color Yellow, Green
	Write-Color "3. ", "Option 3" -Color Yellow, Green
	Write-Color "4. ", "Option 4" -Color Yellow, Green
	Write-Color "9. ", "Press 9 to exit" -Color Yellow, Gray -LinesBefore 1

    .EXAMPLE
	Write-Color -LinesBefore 2 -Text "This little ","message is ", "written to log ", "file as well." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt" -TimeFormat "yyyy-MM-dd HH:mm:ss"
	Write-Color -Text "This can get ","handy if ", "want to display things, and log actions to file ", "at the same time." `
				-Color Yellow, White, Green, Red, Red -LogFile "C:\testing.txt"

    .EXAMPLE
    # Added in 0.5
    Write-Color -T "My text", " is ", "all colorful" -C Yellow, Red, Green -B Green, Green, Yellow
    wc -t "my text" -c yellow -b green
    wc -text "my text" -c red

    .NOTES
        CHANGELOG

        Version 0.5 (25th April 2018)
        -----------
        - Added backgroundcolor
        - Added aliases T/B/C to shorter code
        - Added alias to function (can be used with "WC")
        - Fixes to module publishing

        Version 0.4.0-0.4.9 (25th April 2018)
        -------------------
        - Published as module
        - Fixed small issues

        Version 0.31 (20th April 2018)
        ------------
        - Added Try/Catch for Write-Output (might need some additional work)
        - Small change to parameters

        Version 0.3 (9th April 2018)
        -----------
        - Added -ShowTime
        - Added -NoNewLine
        - Added function description
        - Changed some formatting

        Version 0.2
        -----------
        - Added logging to file

        Version 0.1
        -----------
        - First draft

        Additional Notes:
        - TimeFormat https://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
    #>
    [alias('Write-Colour')]
    [CmdletBinding()]
    param ([alias ('T')] [String[]]$Text,
        [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
        [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
        [alias ('Indent')][int] $StartTab = 0,
        [int] $LinesBefore = 0,
        [int] $LinesAfter = 0,
        [int] $StartSpaces = 0,
        [alias ('L')] [string] $LogFile = '',
        [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
        [alias ('LogTimeStamp')][bool] $LogTime = $true,
        [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
        [switch] $ShowTime,
        [switch] $NoNewLine)
    $DefaultColor = $Color[0]
    if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) { Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."; return }
    if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host -Object "`n" -NoNewline } }
    if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host -Object "`t" -NoNewLine } }
    if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host -Object ' ' -NoNewLine } }
    if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))]" -NoNewline }
    if ($Text.Count -ne 0) {
        if ($Color.Count -ge $Text.Count) { if ($null -eq $BackGroundColor) { for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewLine } } else { for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewLine } } } else {
            if ($null -eq $BackGroundColor) {
                for ($i = 0; $i -lt $Color.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
                for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
            } else {
                for ($i = 0; $i -lt $Color.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewLine }
                for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewLine }
            }
        }
    }
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host }
    if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } }
    if ($Text.Count -ne 0 -and $LogFile -ne "") {
        $TextToFile = ""
        for ($i = 0; $i -lt $Text.Length; $i++) { $TextToFile += $Text[$i] }
        try { if ($LogTime) { Write-Output -InputObject "[$([datetime]::Now.ToString($DateTimeFormat))]$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append } else { Write-Output -InputObject "$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append } } catch { $_.Exception }
    }
}
function Clear-DataInformation {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Data,
        [Array] $TypesRequired,
        [switch] $DontRemoveSupportData,
        [switch] $DontRemoveEmpty)
    foreach ($Domain in $Data.FoundDomains.Keys) {
        $RemoveDomainKeys = foreach ($Key in $Data.FoundDomains.$Domain.Keys) {
            if ($null -eq $Data.FoundDomains.$Domain.$Key) {
                if (-not $DontRemoveEmpty) { $Key }
                continue
            }
            if ($Key -notin $TypesRequired -and $DontRemoveSupportData -eq $false) { $Key }
        }
        foreach ($Key in $RemoveDomainKeys) { $Data.FoundDomains.$Domain.Remove($Key) }
    }
    $RemoveDomains = foreach ($Domain in $Data.FoundDomains.Keys) { if ($Data.FoundDomains.$Domain.Count -eq 0) { $Domain } }
    foreach ($Domain in $RemoveDomains) { $Data.FoundDomains.Remove($Domain) }
    if ($Data.FoundDomains.Count -eq 0) { $Data.Remove('FoundDomains') }
    $RemoveKeys = foreach ($Key in $Data.Keys) {
        if ($Key -eq 'FoundDomains') { continue }
        if ($null -eq $Data.$Key) {
            if (-not $DontRemoveEmpty) { $Key }
            continue
        }
        if ($Key -notin $TypesRequired -and $DontRemoveSupportData -eq $false) { $Key }
    }
    foreach ($Key in $RemoveKeys) { $Data.Remove($Key) }
}
function Connect-WinAzure {
    [CmdletBinding()]
    param([string] $SessionName = 'Azure MSOL',
        [string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [switch] $Output)
    if (-not $MultiFactorAuthentication) {
        Write-Verbose "Connect-WinAzure - Running connectivity without MFA"
        $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
        if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
    }
    try {
        Connect-MsolService -Credential $Credentials -ErrorAction Stop
        $Connected = $true
    } catch {
        $Connected = $false
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" } } else {
            Write-Warning "Connect-WinAzure - Failed with error message: $ErrorMessage"
            return
        }
    }
    if ($Connected -eq $false) { if ($Output) { return @{Status = $false; Output = $SessionName; Extended = 'Connection Failed.' } } else { return } } else { if ($Output) { return @{Status = $true; Output = $SessionName; Extended = 'Connection Established.' } } else { return } }
}
function Connect-WinAzureAD {
    [CmdletBinding()]
    param([string] $SessionName = 'Azure AD',
        [string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [switch] $Output)
    if (-not $MultiFactorAuthentication) {
        Write-Verbose "Connect-WinAzureAD - Running connectivity without MFA"
        $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
        if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
    }
    try { $Session = Connect-AzureAD -Credential $Credentials -ErrorAction Stop } catch {
        $Session = $null
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" } } else {
            Write-Warning "Connect-WinAzureAD - Failed with error message: $ErrorMessage"
            return
        }
    }
    if (-not $Session) { if ($Output) { return @{Status = $false; Output = $SessionName; Extended = 'Connection Failed.' } } else { return } }
    if ($Output) { return @{Status = $true; Output = $SessionName; Extended = 'Connection Established.' } }
}
function Connect-WinExchange {
    [CmdletBinding()]
    param([string] $SessionName = 'Exchange',
        [string] $ConnectionURI,
        [ValidateSet("Basic", "Kerberos")][String] $Authentication = 'Kerberos',
        [alias('UserPrincipalName')][string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [string] $Prefix,
        [switch] $Output)
    $Object = @()
    if ($MultiFactorAuthentication) {
        Write-Verbose 'Connect-WinExchange - Using MFA option'
        try { Import-Module -ErrorAction Stop $((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse).FullName | Where-Object { $_ -notmatch "_none_" } | Select-Object -First 1) } catch {
            if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed. Couldn't find Exchange Online module to load." } } else {
                Write-Warning -Message "Connect-WinExchange - Connection failed. Couldn't find Exchange Online module to load."
                return
            }
        }
    } else {
        Write-Verbose 'Connect-WinExchange - Using Non-MFA option'
        if ($Authentication -ne 'Kerberos') {
            $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
            if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
        } else { $Credentials = $null }
    }
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession.Availability -contains 'Available') {
        foreach ($UsedSession in $ExistingSession) {
            if ($UsedSession.Availability -eq 'Available') {
                if ($Output) { $Object += @{Status = $true; Output = $SessionName; Extended = "Will reuse established session to $($Session.ComputerName)" } } else { Write-Verbose -Message "Connect-WinExchange - reusing session $($Session.ComputerName)" }
                $Session = $UsedSession
                break
            }
        }
    } else {
        if ($MultiFactorAuthentication) {
            Write-Verbose -Message "Connect-WinExchange - Establishing MFA Connection"
            $PSSessionOption = New-PSSessionOption -ProxyAccessType IEConfig
            try {
                $Session = New-ExoPSSession -UserPrincipalName $UserName -PSSessionOption $PSSessionOption
                $Session.Name = $SessionName
            } catch {
                $Session = $null
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                if ($Output) {
                    $Object += @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" }
                    return $Object
                } else {
                    Write-Warning -Message "Connect-WinExchange - Failed with error message: $ErrorMessage"
                    return
                }
            }
        } else {
            Write-Verbose -Message "Connect-WinExchange - Creating Session to URI: $ConnectionURI"
            $SessionOption = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck -Verbose:$false
            try {
                if ($Credentials) {
                    Write-Verbose 'Connect-WinExchange - Creating new session using Credentials'
                    $Session = New-PSSession -Credential $Credentials -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionURI -Authentication $Authentication -SessionOption $sessionOption -Name $SessionName -AllowRedirection -ErrorAction Stop -Verbose:$false
                } else {
                    Write-Verbose 'Connect-WinExchange - Creating new session without Credentials'
                    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionURI -Authentication $Authentication -SessionOption $sessionOption -Name $SessionName -AllowRedirection -Verbose:$false -ErrorAction Stop
                }
            } catch {
                $Session = $null
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                if ($Output) {
                    $Object += @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" }
                    return $Object
                } else {
                    Write-Warning "Connect-WinExchange - Failed with error message: $ErrorMessage"
                    return
                }
            }
        }
    }
    if (-not $Session) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Connection failed.' }
            return $Object
        } else { return }
    }
    $CurrentVerbosePreference = $VerbosePreference; $VerbosePreference = 'SilentlyContinue'
    $CurrentWarningPreference = $WarningPreference; $WarningPreference = 'SilentlyContinue'
    if ($Prefix) { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Prefix $Prefix -Verbose:$false) -Global -Prefix $Prefix } else { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Verbose:$false) -Global }
    $VerbosePreference = $CurrentVerbosePreference
    $WarningPreference = $CurrentWarningPreference
    $CheckAvailabilityCommands = Test-AvailabilityCommands -Commands "Get-$($Prefix)MailContact", "Get-$($Prefix)Mailbox"
    if ($CheckAvailabilityCommands -contains $false) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Commands unavailable.' }
            return $Object
        } else { return }
    }
    if ($Output) {
        if ($Prefix) { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: $Prefix" } } else { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: n/a" } }
        return $Object
    } else { if ($Prefix) { Write-Verbose -Message "Connect-WinExchange - Connection established $($Session.ComputerName) - prefix: $Prefix" } else { Write-Verbose -Message "Connect-WinExchange - Connection established $($Session.ComputerName) - prefix: n/a" } }
    return $Object
}
function Connect-WinSecurityCompliance {
    [CmdletBinding()]
    param([string] $SessionName = 'Security and Compliance',
        [string] $ConnectionURI,
        [ValidateSet("Basic", "Kerberos")][String] $Authentication = 'Basic',
        [alias('UserPrincipalName')][string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [string] $Prefix,
        [switch] $Output)
    $Object = @()
    if ($MultiFactorAuthentication) {
        Write-Verbose 'Connect-WinSecurityCompliance - Using MFA option'
        try { Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse).FullName | ? { $_ -notmatch "_none_" } | select -First 1) } catch {
            if ($Output) {
                $Object += @{Status = $false; Output = $SessionName; Extended = "Connection failed. Couldn't find Exchange Online module to load." }
                return $Object
            } else {
                Write-Warning -Message "Connect-WinSecurityCompliance - Connection failed. Couldn't find Exchange Online module to load."
                return
            }
        }
    } else {
        Write-Verbose 'Connect-WinSecurityCompliance - Using Non-MFA option'
        if ($Authentication -ne 'Kerberos') {
            $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
            if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
        } else { $Credentials = $null }
    }
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession.Availability -contains 'Available') {
        foreach ($UsedSession in $ExistingSession) {
            if ($UsedSession.Availability -eq 'Available') {
                if ($Output) { $Object += @{Status = $true; Output = $SessionName; Extended = "Will reuse established session to $($Session.ComputerName)" } } else { Write-Verbose -Message "Connect-WinSecurityCompliance - reusing session $($Session.ComputerName)" }
                $Session = $UsedSession
                break
            }
        }
    } else {
        if ($MultiFactorAuthentication) {
            Write-Verbose -Message "Connect-WinSecurityCompliance - Establishing MFA Connection"
            $PSSessionOption = New-PSSessionOption -ProxyAccessType IEConfig
            try {
                $Session = New-ExoPSSession -UserPrincipalName $UserName -PSSessionOption $PSSessionOption
                $Session.Name = $SessionName
            } catch {
                $Session = $null
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                if ($Output) {
                    $Object += @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" }
                    return $Object
                } else {
                    Write-Warning -Message "Connect-WinSecurityCompliance - Failed with error message: $ErrorMessage"
                    return
                }
            }
        } else {
            Write-Verbose -Message "Connect-WinSecurityCompliance - Creating Session to URI: $ConnectionURI"
            $SessionOption = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck -Verbose:$false
            try {
                if ($Credentials) {
                    Write-Verbose 'Connect-WinSecurityCompliance - Creating new session using Credentials'
                    $Session = New-PSSession -Credential $Credentials -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionURI -Authentication $Authentication -SessionOption $sessionOption -Name $SessionName -AllowRedirection -ErrorAction Stop -Verbose:$false
                } else {
                    Write-Verbose 'Connect-WinSecurityCompliance - Creating new session without Credentials'
                    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionURI -Authentication $Authentication -SessionOption $sessionOption -Name $SessionName -AllowRedirection -Verbose:$false -ErrorAction Stop
                }
            } catch {
                $Session = $null
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                if ($Output) {
                    $Object += @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" }
                    return $Object
                } else {
                    Write-Warning "Connect-WinSecurityCompliance - Failed with error message: $ErrorMessage"
                    return
                }
            }
        }
    }
    if (-not $Session) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Connection failed.' }
            return $Object
        } else { return }
    }
    $CurrentVerbosePreference = $VerbosePreference; $VerbosePreference = 'SilentlyContinue'
    $CurrentWarningPreference = $WarningPreference; $WarningPreference = 'SilentlyContinue'
    if ($Prefix) { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Prefix $Prefix -Verbose:$false) -Global -Prefix $Prefix } else { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Verbose:$false) -Global }
    $VerbosePreference = $CurrentVerbosePreference
    $WarningPreference = $CurrentWarningPreference
    $CheckAvailabilityCommands = Test-AvailabilityCommands -Commands "Get-$($Prefix)ProtectionAlert"
    if ($CheckAvailabilityCommands -contains $false) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Commands unavailable.' }
            return $Object
        } else { return }
    }
    if ($Output) {
        if ($Prefix) { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: $Prefix" } } else { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: n/a" } }
        return $Object
    } else { if ($Prefix) { Write-Verbose -Message "Connect-WinSecurityCompliance - Connection established $($Session.ComputerName) - prefix: $Prefix" } else { Write-Verbose -Message "Connect-WinSecurityCompliance - Connection established $($Session.ComputerName) - prefix: n/a" } }
    return $Object
}
function Connect-WinSharePoint {
    [CmdletBinding()]
    param([string] $SessionName = 'Microsoft SharePoint',
        [string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [alias('uri', 'url', 'ConnectionUrl')][Uri] $ConnectionURI,
        [switch] $Output)
    if (-not $MultiFactorAuthentication) {
        $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
        if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
    }
    try {
        Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
        $Session = Connect-SPOService -Url $ConnectionURI -Credential $Credentials
    } catch {
        $Session = $null
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" } } else {
            Write-Warning "Connect-WinSharePoint - Failed with error message: $ErrorMessage"
            return
        }
    }
    if ($Output) { return @{Status = $true; Output = $SessionName; Extended = 'Connection Established.' } }
}
function Connect-WinSkype {
    [CmdletBinding()]
    param([string] $SessionName = 'Microsoft Skype',
        [string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [switch] $Output)
    $Object = @()
    if (-not $MultiFactorAuthentication) {
        Write-Verbose "Connect-WinSkype - Running connectivity without MFA"
        $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
        if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
    }
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession.Availability -contains 'Available') {
        foreach ($UsedSession in $ExistingSession) {
            if ($UsedSession.Availability -eq 'Available') {
                if ($Output) { $Object += @{Status = $true; Output = $SessionName; Extended = "Will reuse established session to $($Session.ComputerName)" } } else { Write-Verbose -Message "Connect-WinSkype - reusing session $($Session.ComputerName)" }
                $Session = $UsedSession
                break
            }
        }
    } else {
        try {
            if ($MultiFactorAuthentication) { $Session = New-CsOnlineSession -UserName $Username -ErrorAction Stop } else { $Session = New-CsOnlineSession -Credential $Credentials -ErrorAction Stop }
            $Session.Name = $SessionName
        } catch {
            $Session = $null
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" } } else {
                Write-Warning -Message "Connect-WinSkype - Failed with error message: $ErrorMessage"
                return
            }
        }
    }
    if (-not $Session) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Connection failed.' }
            return $Object
        } else { return }
    }
    $CurrentVerbosePreference = $VerbosePreference; $VerbosePreference = 'SilentlyContinue'
    $CurrentWarningPreference = $WarningPreference; $WarningPreference = 'SilentlyContinue'
    if ($Prefix) { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Prefix $Prefix -Verbose:$false) -Global -Prefix $Prefix } else { Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking -Verbose:$false) -Global }
    $VerbosePreference = $CurrentVerbosePreference
    $WarningPreference = $CurrentWarningPreference
    $CheckAvailabilityCommands = Test-AvailabilityCommands -Commands "Get-$($Prefix)CsExternalAccessPolicy"
    if ($CheckAvailabilityCommands -contains $false) {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = 'Commands unavailable.' }
            return $Object
        } else { return }
    }
    if ($Output) {
        if ($Prefix) { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: $Prefix" } } else { $Object += @{Status = $true; Output = $SessionName; Extended = "Connection established $($Session.ComputerName) - prefix: n/a" } }
        return $Object
    } else { if ($Prefix) { Write-Verbose -Message "Connect-WinSkype - Connection established $($Session.ComputerName) - prefix: $Prefix" } else { Write-Verbose -Message "Connect-WinSkype - Connection established $($Session.ComputerName) - prefix: n/a" } }
    return $Object
}
function Connect-WinTeams {
    [CmdletBinding()]
    param([string] $SessionName = 'Microsoft Teams',
        [string] $Username,
        [string] $Password,
        [alias('PasswordAsSecure')][switch] $AsSecure,
        [alias('PasswordFromFile')][switch] $FromFile,
        [alias('mfa')][switch] $MultiFactorAuthentication,
        [switch] $Output)
    if (-not $MultiFactorAuthentication) {
        $Credentials = Request-Credentials -UserName $Username -Password $Password -AsSecure:$AsSecure -FromFile:$FromFile -Service $SessionName -Output
        if ($Credentials -isnot [PSCredential]) { if ($Output) { return $Credentials } else { return } }
    }
    try { $Session = Connect-MicrosoftTeams -Credential $Credentials -ErrorAction Stop } catch {
        $Session = $null
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($Output) { return @{Status = $false; Output = $SessionName; Extended = "Connection failed with $ErrorMessage" } } else {
            Write-Warning "Connect-WinTeams - Failed with error message: $ErrorMessage"
            return
        }
    }
    if (-not $Session) { if ($Output) { return @{Status = $false; Output = $SessionName; Extended = 'Connection Failed.' } } else { return } }
    if ($Output) { return @{Status = $true; Output = $SessionName; Extended = 'Connection Established.' } }
}
function ConvertFrom-Color {
    [alias('Convert-FromColor')]
    [CmdletBinding()]
    param ([ValidateScript( { if ($($_ -in $Script:RGBColors.Keys -or $_ -match "^#([A-Fa-f0-9]{6})$" -or $_ -eq "") -eq $false) { throw "The Input value is not a valid colorname nor an valid color hex code." } else { $true } })]
        [alias('Colors')][string[]] $Color,
        [switch] $AsDecimal)
    $Colors = foreach ($C in $Color) {
        $Value = $Script:RGBColors."$C"
        if ($C -match "^#([A-Fa-f0-9]{6})$") { return $C }
        if ($null -eq $Value) { return }
        $HexValue = Convert-Color -RGB $Value
        Write-Verbose "Convert-FromColor - Color Name: $C Value: $Value HexValue: $HexValue"
        if ($AsDecimal) { [Convert]::ToInt64($HexValue, 16) } else { "#$($HexValue)" }
    }
    $Colors
}
function ConvertTo-OrderedDictionary {
    [CmdletBinding()]
    Param ([parameter(Mandatory = $true, ValueFromPipeline = $true)] $HashTable)
    $OrderedDictionary = [ordered]@{ }
    if ($HashTable -is [System.Collections.IDictionary]) {
        $Keys = $HashTable.Keys | Sort-Object
        foreach ($_ in $Keys) { $OrderedDictionary.Add($_, $HashTable[$_]) }
    } elseif ($HashTable -is [System.Collections.ICollection]) { for ($i = 0; $i -lt $HashTable.count; $i++) { $OrderedDictionary.Add($i, $HashTable[$i]) } } else { Write-Error "ConvertTo-OrderedDictionary - Wrong input type." }
    return $OrderedDictionary
}
function Find-TypesNeeded {
    [CmdletBinding()]
    param ($TypesRequired,
        $TypesNeeded)
    [bool] $Found = $False
    foreach ($Type in $TypesNeeded) {
        if ($TypesRequired -contains $Type) {
            $Found = $true
            break
        }
    }
    return $Found
}
function Format-PSTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][System.Collections.ICollection] $Object,
        [switch] $SkipTitle,
        [string[]] $Property,
        [string[]] $ExcludeProperty,
        [Object] $OverwriteHeaders,
        [switch] $PreScanHeaders,
        [string] $Splitter = ';')
    if ($Object[0] -is [System.Collections.IDictionary]) {
        $Array = @(if (-not $SkipTitle) { , @('Name', 'Value') }
            foreach ($O in $Object) {
                foreach ($Name in $O.Keys) {
                    $Value = $O[$Name]
                    if ($O[$Name].Count -gt 1) { $Value = $O[$Name] -join $Splitter } else { $Value = $O[$Name] }
                    , @($Name, $Value)
                }
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    } elseif ($Object[0].GetType().Name -match 'bool|byte|char|datetime|decimal|double|ExcelHyperLink|float|int|long|sbyte|short|string|timespan|uint|ulong|URI|ushort') { return $Object } else {
        if ($Property) { $Object = $Object | Select-Object -Property $Property }
        $Array = @(if ($PreScanHeaders) { $Titles = Get-ObjectProperties -Object $Object } elseif ($OverwriteHeaders) { $Titles = $OverwriteHeaders } else { $Titles = $Object[0].PSObject.Properties.Name }
            if (-not $SkipTitle) { , $Titles }
            foreach ($O in $Object) {
                $ArrayValues = foreach ($Name in $Titles) {
                    $Value = $O."$Name"
                    if ($Value.Count -gt 1) { $Value -join $Splitter } elseif ($Value.Count -eq 1) { if ($Value.Value) { $Value.Value } else { $Value } } else { '' }
                }
                , $ArrayValues
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    }
}
function Format-TransposeTable {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][System.Collections.ICollection] $Object,
        [ValidateSet("ASC", "DESC", "NONE")][String] $Sort = 'NONE')
    begin { $i = 0 }
    process {
        foreach ($myObject in $Object) {
            if ($myObject -is [System.Collections.IDictionary]) {
                $output = New-Object -TypeName PsObject
                Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value { Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1] }
                if ($Sort -eq 'ASC') { $myObject.Keys | Sort-Object -Descending:$false | ForEach-Object { $output.AddNote($_, $myObject.$_) } } elseif ($Sort -eq 'DESC') { $myObject.Keys | Sort-Object -Descending:$true | ForEach-Object { $output.AddNote($_, $myObject.$_) } } else { $myObject.Keys | ForEach-Object { $output.AddNote($_, $myObject.$_) } }
                $output
            } else {
                $output = [ordered] @{ }
                $myObject | Get-Member -MemberType *Property | ForEach-Object { $output.($_.name) = $myObject.($_.name) }
                $output
            }
            $i += 1
        }
    }
}
function Get-DataInformation {
    [CmdletBinding()]
    param([ScriptBlock] $Content,
        [string] $Text,
        [Array] $TypesRequired,
        [Array] $TypesNeeded)
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded $TypesNeeded) {
        Write-Verbose -Message $Text
        $Time = Start-TimeLog
        if ($null -ne $Content) { & $Content }
        $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
        Write-Verbose "$Text - Time: $EndTime"
    }
}
function Get-FileName {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Extension
    Parameter description

    .PARAMETER Temporary
    Parameter description

    .PARAMETER TemporaryFileOnly
    Parameter description

    .EXAMPLE
    Get-FileName -Temporary
    Output: 3ymsxvav.tmp

    .EXAMPLE

    Get-FileName -Temporary
    Output: C:\Users\pklys\AppData\Local\Temp\tmpD74C.tmp

    .EXAMPLE

    Get-FileName -Temporary -Extension 'xlsx'
    Output: C:\Users\pklys\AppData\Local\Temp\tmp45B6.xlsx


    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([string] $Extension = 'tmp',
        [switch] $Temporary,
        [switch] $TemporaryFileOnly)
    if ($Temporary) { return "$($([System.IO.Path]::GetTempFileName()).Replace('.tmp','')).$Extension" }
    if ($TemporaryFileOnly) { return "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).$Extension" }
}
function Get-ObjectCount {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Object]$Object)
    return $($Object | Measure-Object).Count
}
function Get-ObjectPropertiesAdvanced {
    [CmdletBinding()]
    param ([object] $Object,
        [string[]] $AddProperties,
        [switch] $Sort)
    $Data = @{ }
    $Properties = New-ArrayList
    $HighestCount = 0
    foreach ($O in $Object) {
        $ObjectProperties = $O.PSObject.Properties.Name
        $Count = $ObjectProperties.Count
        if ($Count -gt $HighestCount) {
            $Data.HighestCount = $Count
            $Data.HighestObject = $O
            $HighestCount = $Count
        }
        foreach ($Property in $ObjectProperties) { Add-ToArrayAdvanced -List $Properties -Element $Property -SkipNull -RequireUnique }
    }
    foreach ($Property in $AddProperties) { Add-ToArrayAdvanced -List $Properties -Element $Property -SkipNull -RequireUnique }
    $Data.Properties = if ($Sort) { $Properties | Sort-Object } else { $Properties }
    return $Data
}
function Get-SqlQueryColumnInformation {
    [CmdletBinding()]
    param ([string] $SqlServer,
        [string] $SqlDatabase,
        [string] $Table)
    $Table = $Table.Replace("dbo.", '').Replace('[', '').Replace(']', '')
    $SqlDatabase = $SqlDatabase.Replace('[', '').Replace(']', '')
    $SqlDatabase = "[$SqlDatabase]"
    $Query = "SELECT * FROM $SqlDatabase.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$Table'"
    $SqlReturn = @(try { Invoke-DbaQuery -ErrorAction Stop -ServerInstance $SqlServer -Query $Query } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            "Error occured (Get-SqlQueryColumnInformation): $ErrorMessage"
        })
    return $SQLReturn
}
function Get-Types {
    [CmdletBinding()]
    param ([Object] $Types)
    $TypesRequired = foreach ($Type in $Types) { $Type.GetEnumValues() }
    return $TypesRequired
}
function Get-WinADForestControllers {
    [alias('Get-WinADDomainControllers')]
    <#
    .SYNOPSIS


    .DESCRIPTION
    Long description

    .PARAMETER TestAvailability
    Parameter description

    .EXAMPLE
    Get-WinADForestControllers -TestAvailability | Format-Table

    .EXAMPLE
    Get-WinADDomainControllers

    .EXAMPLE
    Get-WinADDomainControllers | Format-Table *

    Output:

    Domain        HostName          Forest        IPV4Address     IsGlobalCatalog IsReadOnly SchemaMaster DomainNamingMasterMaster PDCEmulator RIDMaster InfrastructureMaster Comment
    ------        --------          ------        -----------     --------------- ---------- ------------ ------------------------ ----------- --------- -------------------- -------
    ad.evotec.xyz AD1.ad.evotec.xyz ad.evotec.xyz 192.168.240.189            True      False         True                     True        True      True                 True
    ad.evotec.xyz AD2.ad.evotec.xyz ad.evotec.xyz 192.168.240.192            True      False        False                    False       False     False                False
    ad.evotec.pl                    ad.evotec.xyz                                                   False                    False       False     False                False Unable to contact the server. This may be becau...

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([string[]] $Domain,
        [switch] $TestAvailability,
        [switch] $SkipEmpty)
    try {
        $Forest = Get-ADForest
        if (-not $Domain) { $Domain = $Forest.Domains }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning "Get-WinADForestControllers - Couldn't use Get-ADForest feature. Error: $ErrorMessage"
        return
    }
    $Servers = foreach ($D in $Domain) {
        try {
            $DC = Get-ADDomainController -Server $D -Filter *
            foreach ($S in $DC) {
                $Server = [ordered] @{Domain = $D
                    HostName                 = $S.HostName
                    Name                     = $S.Name
                    Forest                   = $Forest.RootDomain
                    IPV4Address              = $S.IPV4Address
                    IPV6Address              = $S.IPV6Address
                    IsGlobalCatalog          = $S.IsGlobalCatalog
                    IsReadOnly               = $S.IsReadOnly
                    Site                     = $S.Site
                    SchemaMaster             = ($S.OperationMasterRoles -contains 'SchemaMaster')
                    DomainNamingMaster       = ($S.OperationMasterRoles -contains 'DomainNamingMaster')
                    PDCEmulator              = ($S.OperationMasterRoles -contains 'PDCEmulator')
                    RIDMaster                = ($S.OperationMasterRoles -contains 'RIDMaster')
                    InfrastructureMaster     = ($S.OperationMasterRoles -contains 'InfrastructureMaster')
                    LdapPort                 = $S.LdapPort
                    SslPort                  = $S.SslPort
                    Pingable                 = $null
                    Comment                  = ''
                }
                if ($TestAvailability) { $Server['Pingable'] = foreach ($_ in $Server.IPV4Address) { Test-Connection -Count 1 -Server $_ -Quiet -ErrorAction SilentlyContinue } }
                [PSCustomObject] $Server
            }
        } catch {
            [PSCustomObject]@{Domain     = $D
                HostName                 = ''
                Name                     = ''
                Forest                   = $Forest.RootDomain
                IPV4Address              = ''
                IPV6Address              = ''
                IsGlobalCatalog          = ''
                IsReadOnly               = ''
                Site                     = ''
                SchemaMaster             = $false
                DomainNamingMasterMaster = $false
                PDCEmulator              = $false
                RIDMaster                = $false
                InfrastructureMaster     = $false
                LdapPort                 = ''
                SslPort                  = ''
                Pingable                 = $null
                Comment                  = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            }
        }
    }
    if ($SkipEmpty) { return $Servers | Where-Object { $_.HostName -ne '' } }
    return $Servers
}
function New-SqlQuery {
    [CmdletBinding()]
    param ([Object] $SqlSettings,
        [Object] $Object,
        [Object] $TableMapping)
    $ArraySQLQueries = New-ArrayList
    if ($null -ne $Object) {
        foreach ($O in $Object) {
            $ArrayMain = New-ArrayList
            $ArrayKeys = New-ArrayList
            $ArrayValues = New-ArrayList
            if (-not $O.AddedWhen) { Add-Member -InputObject $O -MemberType NoteProperty -Name "AddedWhen" -Value (Get-Date) -Force }
            if (-not $O.AddedWho) { Add-Member -InputObject $O -MemberType NoteProperty -Name "AddedWho" -Value ($Env:USERNAME) -Force }
            $DuplicateString = [System.Text.StringBuilder]::new()
            foreach ($E in $O.PSObject.Properties) {
                $FieldName = $E.Name
                $FieldValue = $E.Value
                foreach ($MapKey in $TableMapping.Keys) {
                    if ($FieldName -eq $MapKey) {
                        $MapValue = $TableMapping.$MapKey
                        $MapValueSplit = $MapValue -Split ','
                        if ($FieldValue -is [DateTime]) { $FieldValue = Get-Date $FieldValue -Format "yyyy-MM-dd HH:mm:ss" }
                        if ($FieldValue -like "*'*") { $FieldValue = $FieldValue -Replace "'", "''" }
                        Add-ToArray -List $ArrayKeys -Element "[$($MapValueSplit[0])]"
                        if ([string]::IsNullOrWhiteSpace($FieldValue)) { Add-ToArray -List $ArrayValues -Element "NULL" } else {
                            foreach ($ColumnName in $SqlSettings.SqlCheckBeforeInsert) {
                                $DuplicateColumn = $ColumnName.Replace("[", '').Replace("]", '')
                                if ($MapValueSplit[0] -eq $DuplicateColumn) {
                                    if ($DuplicateString.Length -ne 0) { $null = $DuplicateString.Append(" AND ") }
                                    $null = $DuplicateString.Append("[$DuplicateColumn] = '$FieldValue'")
                                }
                            }
                            Add-ToArray -List $ArrayValues -Element "'$FieldValue'"
                        }
                    }
                }
            }
            if ($ArrayKeys) {
                if ($null -ne $SqlSettings.SqlCheckBeforeInsert -and $DuplicateString.Length -gt 0) {
                    Add-ToArray -List $ArrayMain -Element "IF NOT EXISTS ("
                    Add-ToArray -List $ArrayMain -Element "SELECT 1 FROM "
                    Add-ToArray -List $ArrayMain -Element "$($SqlSettings.SqlTable) "
                    Add-ToArray -List $ArrayMain -Element "WHERE $($DuplicateString.ToString())"
                    Add-ToArray -List $ArrayMain -Element ")"
                }
                Add-ToArray -List $ArrayMain -Element "BEGIN"
                Add-ToArray -List $ArrayMain -Element "INSERT INTO  $($SqlSettings.SqlTable) ("
                Add-ToArray -List $ArrayMain -Element ($ArrayKeys -join ',')
                Add-ToArray -List $ArrayMain -Element ') VALUES ('
                Add-ToArray -List $ArrayMain -Element ($ArrayValues -join ',')
                Add-ToArray -List $ArrayMain -Element ')'
                Add-ToArray -List $ArrayMain -Element "END"
                Add-ToArray -List $ArraySQLQueries -Element ([string] ($ArrayMain) -replace "`n", "" -replace "`r", "")
            }
        }
    }
    return $ArraySQLQueries
}
function New-SqlQueryAlterTable {
    [CmdletBinding()]
    param ([Object]$SqlSettings,
        [Object]$TableMapping,
        [string[]] $ExistingColumns)
    $ArraySQLQueries = New-ArrayList
    $ArrayMain = New-ArrayList
    $ArrayKeys = New-ArrayList
    foreach ($MapKey in $TableMapping.Keys) {
        $MapValue = $TableMapping.$MapKey
        $Field = $MapValue -Split ','
        if ($ExistingColumns -notcontains $MapKey -and $ExistingColumns -notcontains $Field[0]) { if ($Field.Count -eq 1) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] [nvarchar](max) NULL" } elseif ($Field.Count -eq 2) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] $($Field[1]) NULL" } elseif ($Field.Count -eq 3) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] $($Field[1]) $($Field[2])" } }
    }
    if ($ArrayKeys) {
        Add-ToArray -List $ArrayMain -Element "ALTER TABLE $($SqlSettings.SqlTable) ADD"
        Add-ToArray -List $ArrayMain -Element ($ArrayKeys -join ',')
        Add-ToArray -List $ArrayMain -Element ';'
        Add-ToArray -List $ArraySQLQueries -Element ([string] ($ArrayMain) -replace "`n", "" -replace "`r", "")
    }
    return $ArraySQLQueries
}
function New-SqlQueryCreateTable {
    [CmdletBinding()]
    param ([Object]$SqlSettings,
        [Object]$TableMapping)
    $ArraySQLQueries = New-ArrayList
    $ArrayMain = New-ArrayList
    $ArrayKeys = New-ArrayList
    foreach ($MapKey in $TableMapping.Keys) {
        $MapValue = $TableMapping.$MapKey
        $Field = $MapValue -Split ','
        if ($Field.Count -eq 1) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] [nvarchar](max) NULL" } elseif ($Field.Count -eq 2) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] $($Field[1]) NULL" } elseif ($Field.Count -eq 3) { Add-ToArray -List $ArrayKeys -Element "[$($Field[0])] $($Field[1]) $($Field[2])" }
    }
    if ($ArrayKeys) {
        Add-ToArray -List $ArrayMain -Element "CREATE TABLE $($SqlSettings.SqlTable) ("
        Add-ToArray -List $ArrayMain -Element "ID int IDENTITY(1,1) PRIMARY KEY,"
        Add-ToArray -List $ArrayMain -Element ($ArrayKeys -join ',')
        Add-ToArray -List $ArrayMain -Element ')'
        Add-ToArray -List $ArraySQLQueries -Element ([string] ($ArrayMain) -replace "`n", "" -replace "`r", "")
    }
    return $ArraySQLQueries
}
function New-SqlTableMapping {
    [CmdletBinding()]
    param([Object] $SqlTableMapping,
        [Object] $Object,
        $Properties,
        [switch] $BasedOnSqlTable)
    if ($SqlTableMapping) { $TableMapping = $SqlTableMapping } else {
        $TableMapping = @{ }
        if ($BasedOnSqlTable) {
            foreach ($Property in $Properties) {
                $FieldName = $Property
                $FieldNameSql = $Property
                $TableMapping.$FieldName = $FieldNameSQL
            }
        } else {
            foreach ($O in $Properties.HighestObject) {
                foreach ($Property in $Properties.Properties) {
                    $FieldName = $Property
                    $FieldValue = $O.$Property
                    $FieldNameSQL = $FieldName.Replace(' ', '')
                    if ($FieldValue -is [DateTime]) { $TableMapping.$FieldName = "$FieldNameSQL,[datetime],null" } elseif ($FieldValue -is [int] -or $FieldValue -is [Int64]) { $TableMapping.$FieldName = "$FieldNameSQL,[bigint]" } elseif ($FieldValue -is [bool]) { $TableMapping.$FieldName = "$FieldNameSQL,[bit]" } else { $TableMapping.$FieldName = "$FieldNameSQL" }
                }
            }
        }
    }
    return $TableMapping
}
function Test-AvailabilityCommands {
    param ([string[]] $Commands)
    $CommandsStatus = foreach ($Command in $Commands) {
        $Exists = Search-Command -Command $Command
        if ($Exists) { Write-Verbose "Test-AvailabilityCommands - Command $Command is available." } else { Write-Verbose "Test-AvailabilityCommands - Command $Command is not available." }
        $Exists
    }
    return $CommandsStatus
}
function Test-ConfigurationCredentials {
    [CmdletBinding()]
    param ([Object] $Configuration,
        $AllowEmptyKeys)
    $Object = foreach ($Key in $Configuration.Keys) {
        if ($AllowEmptyKeys -notcontains $Key -and [string]::IsNullOrWhiteSpace($Configuration.$Key)) {
            Write-Verbose "Test-ConfigurationCredentials - Configuration $Key is Null or Empty! Terminating"
            @{Status = $false; Output = $User.SamAccountName; Extended = "Credentials configuration $Key is Null or Empty!" }
        }
    }
    return $Object
}
function Test-ForestConnectivity {
    [CmdletBinding()]
    param()
    Try {
        $null = Get-ADForest
        return $true
    } catch { return $False }
}
function Add-ToArray {
    [CmdletBinding()]
    param([System.Collections.ArrayList] $List,
        [Object] $Element)
    [void] $List.Add($Element)
}
function Convert-Color {
    <#
    .Synopsis
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
    .Description
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
    .Parameter RBG
    Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
    .Parameter HEX
    Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
    .Example
    .\convert-color -hex FFFFFF
    Converts hex value FFFFFF to RGB

    .Example
    .\convert-color -RGB 123,200,255
    Converts Red = 123 Green = 200 Blue = 255 to Hex value

    #>
    param([Parameter(ParameterSetName = "RGB", Position = 0)]
        [ValidateScript( { $_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$' })]
        $RGB,
        [Parameter(ParameterSetName = "HEX", Position = 0)]
        [ValidateScript( { $_ -match '[A-Fa-f0-9]{6}' })]
        [string]
        $HEX)
    switch ($PsCmdlet.ParameterSetName) {
        "RGB" {
            if ($null -eq $RGB[2]) { Write-Error "Value missing. Please enter all three values seperated by comma." }
            $red = [convert]::Tostring($RGB[0], 16)
            $green = [convert]::Tostring($RGB[1], 16)
            $blue = [convert]::Tostring($RGB[2], 16)
            if ($red.Length -eq 1) { $red = '0' + $red }
            if ($green.Length -eq 1) { $green = '0' + $green }
            if ($blue.Length -eq 1) { $blue = '0' + $blue }
            Write-Output $red$green$blue
        }
        "HEX" {
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}
function Get-ObjectProperties {
    [CmdletBinding()]
    param ([System.Collections.ICollection] $Object,
        [string[]] $AddProperties,
        [switch] $Sort,
        [bool] $RequireUnique = $true)
    $Properties = @(foreach ($O in $Object) {
            $ObjectProperties = $O.PSObject.Properties.Name
            $ObjectProperties
        }
        foreach ($Property in $AddProperties) { $Property })
    if ($Sort) { return $Properties | Sort-Object -Unique:$RequireUnique } else { return $Properties | Select-Object -Unique:$RequireUnique }
}
function Get-RandomStringName {
    [cmdletbinding()]
    param([int] $Size = 31,
        [switch] $ToLower,
        [switch] $ToUpper,
        [switch] $LettersOnly)
    [string] $MyValue = @(if ($LettersOnly) { ( -join ((1..$Size) | ForEach-Object { (65..90) + (97..122) | Get-Random } | ForEach-Object { [char]$_ })) } else { ( -join ((48..57) + (97..122) | Get-Random -Count $Size | ForEach-Object { [char]$_ })) })
    if ($ToLower) { return $MyValue.ToLower() }
    if ($ToUpper) { return $MyValue.ToUpper() }
    return $MyValue
}
function Request-Credentials {
    [CmdletBinding()]
    param([string] $UserName,
        [string] $Password,
        [switch] $AsSecure,
        [switch] $FromFile,
        [switch] $Output,
        [switch] $NetworkCredentials,
        [string] $Service)
    if ($FromFile) {
        if (($Password -ne '') -and (Test-Path $Password)) {
            Write-Verbose "Request-Credentials - Reading password from file $Password"
            $Password = Get-Content -Path $Password
        } else {
            if ($Output) { return @{Status = $false; Output = $Service; Extended = 'File with password unreadable.' } } else {
                Write-Warning "Request-Credentials - Secure password from file couldn't be read. File not readable. Terminating."
                return
            }
        }
    }
    if ($AsSecure) {
        try { $NewPassword = $Password | ConvertTo-SecureString -ErrorAction Stop } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($ErrorMessage -like '*Key not valid for use in specified state*') {
                if ($Output) { return @{Status = $false; Output = $Service; Extended = "Couldn't use credentials provided. Most likely using credentials from other user/session/computer." } } else {
                    Write-Warning -Message "Request-Credentials - Couldn't use credentials provided. Most likely using credentials from other user/session/computer."
                    return
                }
            } else {
                if ($Output) { return @{Status = $false; Output = $Service; Extended = $ErrorMessage } } else {
                    Write-Warning -Message "Request-Credentials - $ErrorMessage"
                    return
                }
            }
        }
    } else { $NewPassword = $Password }
    if ($UserName -and $NewPassword) {
        if ($AsSecure) { $Credentials = New-Object System.Management.Automation.PSCredential($Username, $NewPassword) } else {
            Try { $SecurePassword = $Password | ConvertTo-SecureString -asPlainText -Force -ErrorAction Stop } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                if ($ErrorMessage -like '*Key not valid for use in specified state*') {
                    if ($Output) { return @{Status = $false; Output = $Service; Extended = "Couldn't use credentials provided. Most likely using credentials from other user/session/computer." } } else {
                        Write-Warning -Message "Request-Credentials - Couldn't use credentials provided. Most likely using credentials from other user/session/computer."
                        return
                    }
                } else {
                    if ($Output) { return @{Status = $false; Output = $Service; Extended = $ErrorMessage } } else {
                        Write-Warning -Message "Request-Credentials - $ErrorMessage"
                        return
                    }
                }
            }
            $Credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        }
    } else {
        if ($Output) { return @{Status = $false; Output = $Service; Extended = 'Username or/and Password is empty' } } else {
            Write-Warning -Message 'Request-Credentials - UserName or Password are empty.'
            return
        }
    }
    if ($NetworkCredentials) { return $Credentials.GetNetworkCredential() } else { return $Credentials }
}
function Search-Command {
    [cmdletbinding()]
    param ([string] $CommandName)
    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}
function Get-DocumentPath {
    [CmdletBinding()]
    param ([System.Collections.IDictionary] $Document,
        [string] $FinalDocumentLocation)
    if ($Document.Configuration.Prettify.UseBuiltinTemplate) { $WordDocument = Get-WordDocument -FilePath "$($MyInvocation.MyCommand.Module.ModuleBase)\Templates\WordTemplate.docx" } else { if ($Document.Configuration.Prettify.CustomTemplatePath) { if ($(Test-File -File $Document.Configuration.Prettify.CustomTemplatePath -FileName 'CustomTemplatePath') -eq 0) { $WordDocument = Get-WordDocument -FilePath $Document.Configuration.Prettify.CustomTemplatePath } else { $WordDocument = New-WordDocument -FilePath $FinalDocumentLocation } } else { $WordDocument = New-WordDocument -FilePath $FinalDocumentLocation } }
    if ($null -eq $WordDocument) { Write-Verbose ' Null' }
    return $WordDocument
}
function Get-TypesRequired {
    [CmdletBinding()]
    param ([System.Collections.IDictionary[]] $Sections)
    $TypesRequired = New-ArrayList
    $Types = 'TableData', 'ListData', 'ChartData', 'SqlData', 'ExcelData', 'TextBasedData'
    foreach ($Section in $Sections) {
        $Keys = Get-ObjectKeys -Object $Section
        foreach ($Key in $Keys) { if ($Section.$Key.Use -eq $True) { foreach ($Type in $Types) { Add-ToArrayAdvanced -List $TypesRequired -Element $Section.$Key.$Type -SkipNull -RequireUnique -FullComparison } } }
    }
    Write-Verbose "Get-TypesRequired - FinalList: $($TypesRequired -join ', ')"
    return $TypesRequired
}
function Get-WinDataFromFile {
    [cmdletbinding()]
    param([string] $FilePath,
        [string] $Type,
        [string] $FileType = 'XML')
    try {
        if (Test-Path $FilePath) {
            if ($FileType -eq 'XML') { $Data = Import-Clixml -Path $FilePath -ErrorAction Stop } else {
                $File = Get-Content -Raw -Path $FilePath
                $Data = ConvertFrom-Json -InputObject $File
            }
        } else { Write-Warning "Couldn't load $FileType file from $FilePath for $Type data. File doesn't exists." }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning "Couldn't load $FileType file from $FilePath for $Type data. Error occured: $ErrorMessage"
    }
    return $Data
}
function Get-WinDataFromFileInChunks {
    [CmdletBinding()]
    param ([string] $FolderPath,
        [string] $FileType = 'XML',
        [Object] $Type)
    $DataInformation = @{ }
    if (Test-Path $FolderPath) {
        $Files = @(Get-ChildItem -Path "$FolderPath\*.$FileType" -ErrorAction SilentlyContinue -Recurse)
        foreach ($File in $Files) {
            $FilePath = $File.FullName
            $FieldName = $File.BaseName
            Write-Verbose -Message "Importing $FilePath as $FieldName"
            try { $DataInformation.$FieldName = Import-Clixml -Path $FilePath -ErrorAction Stop } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning "Couldn't load $FileType file from $FilePath for $Type data to match into $FieldName. Error occured: $ErrorMessage"
            }
        }
    } else { Write-Warning -Message "Couldn't load files ($FileType) from folder $FolderPath as it doesn't exists." }
    return $DataInformation
}
function Get-WinDocumentationData {
    [CmdletBinding()]
    param ([alias("Data")][Object] $DataToGet,
        [alias("Forest")][Object] $Object,
        [string] $Domain)
    if ($null -ne $DataToGet) {
        $Type = Get-ObjectType -Object $DataToGet -ObjectName 'Get-WinDocumentationData'
        if ($Type.ObjectTypeName -eq 'ActiveDirectory') { if ("$DataToGet" -like 'Forest*') { return $Object."$DataToGet" } elseif ($DataToGet.ToString() -like 'Domain*') { return $Object.FoundDomains.$Domain."$DataToGet" } } else { return $Object."$DataToGet" }
    }
    return
}
function Get-WinDocumentationText {
    [CmdletBinding()]
    param ([string[]] $Text,
        [System.Collections.IDictionary] $Forest,
        [string] $Domain)
    $Array = foreach ($T in $Text) {
        $T = $T.Replace('<CompanyName>', $Document.Configuration.Prettify.CompanyName)
        $T = $T.Replace('<ForestName>', $Forest.ForestInformation.Name)
        $T = $T.Replace('<ForestNameDN>', $Forest.ForestInformation.'Forest Distingushed Name')
        $T = $T.Replace('<Domain>', $Domain)
        $T = $T.Replace('<DomainNetBios>', $Forest.FoundDomains.$Domain.DomainInformation.NetBIOSName)
        $T = $T.Replace('<DomainDN>', $Forest.FoundDomains.$Domain.DomainInformation.DistinguishedName)
        $T = $T.Replace('<DomainPasswordWeakPasswordList>', $Forest.FoundDomains.$Domain.DomainPasswordDataPasswords.DomainPasswordWeakPasswordList)
        $T
    }
    return $Array
}
function Get-WinServiceData {
    [CmdletBinding()]
    param ([Object] $Credentials,
        [Object] $Service,
        [string] $Type,
        [Object] $TypesRequired)
    if ($Type -eq 'O365') {
        $CommandOutput = @(Connect-WinService -Type 'ExchangeOnline' -Credentials $Credentials -Service $Service -Verbose
            Connect-WinService -Type 'Azure' -Credentials $Credentials -Service $Service -Verbose)
    } else { $CommandOutput = Connect-WinService -Type $Type -Credentials $Credentials -Service $Service -Verbose }
    if ($Service.Use) {
        if ($Service.OnlineMode) {
            switch ($Type) {
                'ActiveDirectory' {
                    if ($Service.PasswordTests.Use) { $PasswordClearText = $Service.PasswordTests.PasswordFilePathClearText } else { $PasswordClearText = '' }
                    if ($Service.PasswordTests.UseHashDB) { $PasswordHashes = $Service.PasswordTests.PasswordFilePathHash } else { $PasswordHashes = '' }
                    $DataInformation = Get-WinADForestInformation -TypesRequired $TypesRequired -PathToPasswords $PasswordClearText -PathToPasswordsHashes $PasswordHashes -Verbose
                }
                'AWS' { $DataInformation = Get-WinAWSInformation -TypesRequired $TypesRequired -AWSAccessKey $Credentials.AccessKey -AWSSecretKey $Credentials.SecretKey -AWSRegion $Credentials.Region }
                'O365' { $DataInformation = Get-WinO365 -TypesRequired $TypesRequired -Prefix $Service.Prefix }
            }
            if ($Service.Export.Use) {
                $Time = Start-TimeLog
                if ($Service.Export.To -eq 'File' -or $Service.Export.To -eq 'Both') {
                    Save-WinDataToFile -Export $Service.Export.Use -FilePath $Service.Export.FilePath -Data $DataInformation -Type $Type -IsOffline:$false -FileType 'XML'
                    $TimeSummary = Stop-TimeLog -Time $Time -Option OneLiner
                    Write-Verbose "Saving data for $Type to file $($Service.Export.FilePath) took: $TimeSummary"
                }
                if ($Service.Export.To -eq 'Folder' -or $Service.Export.To -eq 'Both') {
                    $Time = Start-TimeLog
                    Save-WinDataToFileInChunks -Export $Service.Export.Use -FolderPath $Service.Export.FolderPath -Data $DataInformation -Type $Type -IsOffline:$false -FileType 'XML'
                    $TimeSummary = Stop-TimeLog -Time $Time -Option OneLiner
                    Write-Verbose "Saving data for $Type to folder $($Service.Export.FolderPath) took: $TimeSummary"
                }
            }
            return $DataInformation
        } else {
            if ($Service.Import.Use) {
                $Time = Start-TimeLog
                if ($Service.Import.From -eq 'File') {
                    Write-Verbose "Loading data for $Type in offline mode from XML File $($Service.Import.Path). Hang on..."
                    $DataInformation = Get-WinDataFromFile -FilePath $Service.Import.Path -Type $Type -FileType 'XML'
                } elseif ($Service.Import.From -eq 'Folder') {
                    Write-Verbose "Loading data for $Type in offline mode from XML File $($Service.Import.Path). Hang on..."
                    $DataInformation = Get-WinDataFromFileInChunks -FolderPath $Service.Import.Path -Type $Type -FileType 'XML'
                } else { Write-Warning "Wrong option for Import.Use. Only Folder/File is supported." }
                $TimeSummary = Stop-TimeLog -Time $Time -Option OneLiner
                Write-Verbose "Loading data for $Type in offline mode from file took $TimeSummary"
                return $DataInformation
            }
        }
    }
}
function New-DataBlock {
    [CmdletBinding()]
    param([Xceed.Document.NET.Container] $WordDocument,
        [Object] $Section,
        [alias('Object')][Object] $Forest,
        [string] $Domain,
        [OfficeOpenXml.ExcelPackage] $Excel,
        [string] $SectionName,
        [nullable[bool]] $Sql,
        [bool] $ExportWord)
    if ($Section.Use) {
        if ($Domain) { $SectionDetails = "$Domain - $SectionName" } else { $SectionDetails = $SectionName }
        $TableData = Get-WinDocumentationData -DataToGet $Section.TableData -Object $Forest -Domain $Domain
        $ExcelData = Get-WinDocumentationData -DataToGet $Section.ExcelData -Object $Forest -Domain $Domain
        $ListData = Get-WinDocumentationData -DataToGet $Section.ListData -Object $Forest -Domain $Domain
        $SqlData = Get-WinDocumentationData -DataToGet $Section.SqlData -Object $Forest -Domain $Domain
        $TextBasedData = Get-WindocumentationData -DataToGet $Section.TextBasedData -Object $Forest -Domain $Domain
        $ChartData = (Get-WinDocumentationData -DataToGet $Section.ChartData -Object $Forest -Domain $Domain)
        if ($ChartData) {
            if ($Section.ChartKeys -is [string]) {
                if ($Section.ChartKeys -eq 'Keys' -and $Section.ChartValues -eq 'Values') {
                    $ChartKeys = (Convert-KeyToKeyValue $ChartData).Keys
                    $ChartValues = (Convert-KeyToKeyValue $ChartData).Values
                } else {
                    $ChartKeys = (Convert-KeyToKeyValue $ChartData)."$($Section.ChartKeys)"
                    $ChartValues = (Convert-KeyToKeyValue $ChartData)."$($Section.ChartValues)"
                }
            } elseif ($Section.ChartKeys -is [Array]) {
                $ChartKeys = (Convert-TwoArraysIntoOne -Object $ChartData.($Section.ChartKeys[0]) -ObjectToAdd $ChartData.($Section.ChartKeys[1]))
                $ChartValues = ($ChartData.($Section.ChartValues))
            } else { }
        }
        $TocText = (Get-WinDocumentationText -Text $Section.TocText -Forest $Forest -Domain $Domain)
        $TableTitleText = (Get-WinDocumentationText -Text $Section.TableTitleText -Forest $Forest -Domain $Domain)
        $Text = (Get-WinDocumentationText -Text $Section.Text -Forest $Forest -Domain $Domain)
        $ChartTitle = (Get-WinDocumentationText -Text $Section.ChartTitle -Forest $Forest -Domain $Domain)
        $ListBuilderContent = (Get-WinDocumentationText -Text $Section.ListBuilderContent -Forest $Forest -Domain $Domain)
        $TextNoData = (Get-WinDocumentationText -Text $Section.TextNoData -Forest $Forest -Domain $Domain)
        if ($ExportWord) {
            if ($WordDocument) {
                if (($null -eq $Section.WordExport) -or ($Section.WordExport -eq $true)) {
                    Write-Verbose "Generating WORD Section for [$SectionDetails]"
                    New-WordBlock -WordDocument $WordDocument -TocGlobalDefinition $Section.TocGlobalDefinition-TocGlobalTitle $Section.TocGlobalTitle -TocGlobalSwitches $Section.TocGlobalSwitches -TocGlobalRightTabPos $Section.TocGlobalRightTabPos -TocEnable $Section.TocEnable -TocText $TocText -TocListLevel $Section.TocListLevel -TocListItemType $Section.TocListItemType -TocHeadingType $Section.TocHeadingType -TableData $TableData -TableDesign $Section.TableDesign -TableTitleMerge $Section.TableTitleMerge -TableTitleText $TableTitleText -TableMaximumColumns $Section.TableMaximumColumns -TableColumnWidths $Section.TableColumnWidths -Text $Text -TextNoData $TextNoData -EmptyParagraphsBefore $Section.EmptyParagraphsBefore -EmptyParagraphsAfter $Section.EmptyParagraphsAfter -PageBreaksBefore $Section.PageBreaksBefore -PageBreaksAfter $Section.PageBreaksAfter -TextAlignment $Section.TextAlignment -ListData $ListData -ListType $Section.ListType -ListTextEmpty $Section.ListTextEmpty -ChartEnable $Section.ChartEnable -ChartTitle $ChartTitle -ChartKeys $ChartKeys -ChartValues $ChartValues -ListBuilderContent $ListBuilderContent -ListBuilderType $Section.ListBuilderType -ListBuilderLevel $Section.ListBuilderLevel -TextBasedData $TextBasedData -TextBasedDataAlignment $Section.TextSpecialAlignment
                }
            }
        }
        if ($Excel -and $Section.ExcelExport) {
            if ($Section.ExcelWorkSheet -eq '') { $WorkSheetName = $SectionDetails } else { $WorkSheetName = (Get-WinDocumentationText -Text $Section.ExcelWorkSheet -Forest $Forest -Domain $Domain) }
            if ($ExcelData) {
                Write-Verbose "Generating EXCEL Section for [$SectionDetails]"
                $ExcelWorksheet = Add-ExcelWorksheetData -ExcelDocument $Excel -ExcelWorksheetName $WorkSheetName -DataTable $ExcelData -AutoFit -AutoFilter -PreScanHeaders
            }
        }
        if ($Sql -and $Section.SQLExport -and $SqlData) {
            Write-Verbose "Sending [$SectionDetails] to SQL Server"
            $SqlQuery = Send-SqlInsert -Object $SqlData -SqlSettings $Section -Verbose
            foreach ($Query in $SqlQuery) { Write-Color @script:WriteParameters -Text '[i] ', 'MS SQL Output: ', $Query -Color White, White, Yellow }
        }
    }
    if ($WordDocument) { return $WordDocument } else { return }
}
function Save-WinDataToFile {
    [cmdletbinding()]
    param([nullable[bool]] $Export,
        [string] $Type,
        [Object] $Data,
        [string] $FilePath,
        [switch] $IsOffline,
        [string] $FileType = 'XML')
    if ($IsOffline) {
        Write-Verbose "Save-WinDataToFile - Exporting $Type data to $FileType to path $FilePath skipped. Running in offline mode."
        return
    }
    if ($Export) {
        if ($FilePath) {
            $Split = Split-Path -Path $FilePath
            if (-not (Test-Path -Path $Split)) { New-Item -ItemType Directory -Force -Path $Split > $null }
            Write-Verbose "Save-WinDataToFile - Exporting $Type data to $FileType to path $FilePath"
            if ($FileType -eq 'XML') {
                try { $Data | Export-Clixml -Path $FilePath -ErrorAction Stop -Encoding UTF8 } catch {
                    $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                    Write-Warning "Couldn't save $FileType file to $FilePath for $Type data. Error occured: $ErrorMessage"
                }
            } else {
                try { $Data | ConvertTo-Json -ErrorAction Stop | Add-Content -Path $FilePath -Encoding UTF8 -ErrorAction Stop } catch {
                    $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                    Write-Warning "Couldn't save $FileType file to $FilePath for $Type data. Error occured: $ErrorMessage"
                }
            }
        }
    }
}
function Save-WinDataToFileInChunks {
    [CmdletBinding()]
    param([nullable[bool]] $Export,
        [string] $Type,
        [Object] $Data,
        [string] $FolderPath,
        [switch] $IsOffline,
        [string] $FileType = 'XML')
    foreach ($Key in $Data.Keys) {
        $FilePath = [IO.Path]::Combine($FolderPath, "$Key.xml")
        Save-WinDataToFile -Export $Export -Type $Type -IsOffline:$IsOffline -Data $Data.$Key -FilePath $FilePath -FileType $FileType
    }
}
$Script:DataBehaviorActiveDirectory = [ordered] @{ForestInformation = @{OnlineRequired = $true }
    ForestFSMO                                                      = @{OnlineRequired = $true }
    ForestGlobalCatalogs                                            = @{OnlineRequired = $true }
    ForestOptionalFeatures                                          = @{OnlineRequired = $true }
    ForestUPNSuffixes                                               = @{OnlineRequired = $true }
    ForestSPNSuffixes                                               = @{OnlineRequired = $true }
    ForestSites                                                     = @{OnlineRequired = $true }
    ForestSites1                                                    = @{OnlineRequired = $false }
    ForestSites2                                                    = @{OnlineRequired = $false }
    ForestSubnets                                                   = @{OnlineRequired = $true }
    ForestSubnets1                                                  = @{OnlineRequired = $true }
    ForestSubnets2                                                  = @{OnlineRequired = $true }
    ForestSiteLinks                                                 = @{OnlineRequired = $true }
    DomainRootDSE                                                   = @{OnlineRequired = $true }
    DomainRIDs                                                      = @{OnlineRequired = $true }
    DomainAuthenticationPolicies                                    = @{OnlineRequired = $true }
    DomainAuthenticationPolicySilos                                 = @{OnlineRequired = $true }
    DomainCentralAccessPolicies                                     = @{OnlineRequired = $true }
    DomainCentralAccessRules                                        = @{OnlineRequired = $true }
    DomainClaimTransformPolicies                                    = @{OnlineRequired = $true }
    DomainClaimTypes                                                = @{OnlineRequired = $true }
    DomainFineGrainedPolicies                                       = @{OnlineRequired = $true }
    DomainFineGrainedPoliciesUsers                                  = @{OnlineRequired = $true }
    DomainFineGrainedPoliciesUsersExtended                          = @{OnlineRequired = $true }
    DomainGUIDS                                                     = @{OnlineRequired = $true }
    DomainDNSSRV                                                    = @{OnlineRequired = $true }
    DomainDNSA                                                      = @{OnlineRequired = $true }
    DomainInformation                                               = @{OnlineRequired = $true }
    DomainControllers                                               = @{OnlineRequired = $true }
    DomainFSMO                                                      = @{OnlineRequired = $true }
    DomainDefaultPasswordPolicy                                     = @{OnlineRequired = $true }
    DomainGroupPolicies                                             = @{OnlineRequired = $true }
    DomainGroupPoliciesDetails                                      = @{OnlineRequired = $true }
    DomainGroupPoliciesACL                                          = @{OnlineRequired = $true }
    DomainOrganizationalUnits                                       = @{OnlineRequired = $true }
    DomainOrganizationalUnitsBasicACL                               = @{OnlineRequired = $true }
    DomainOrganizationalUnitsExtended                               = @{OnlineRequired = $true }
    DomainContainers                                                = @{OnlineRequired = $true }
    DomainTrusts                                                    = @{OnlineRequired = $true }
    DomainGroupsFullList                                            = @{OnlineRequired = $true }
    DomainGroups                                                    = @{OnlineRequired = $true }
    DomainGroupsMembers                                             = @{OnlineRequired = $true }
    DomainGroupsMembersRecursive                                    = @{OnlineRequired = $true }
    DomainGroupsSpecial                                             = @{OnlineRequired = $true }
    DomainGroupsSpecialMembers                                      = @{OnlineRequired = $true }
    DomainGroupsSpecialMembersRecursive                             = @{OnlineRequired = $true }
    DomainGroupsPriviliged                                          = @{OnlineRequired = $true }
    DomainGroupsPriviligedMembers                                   = @{OnlineRequired = $true }
    DomainGroupsPriviligedMembersRecursive                          = @{OnlineRequired = $true }
    DomainUsersFullList                                             = @{OnlineRequired = $true }
    DomainUsers                                                     = @{OnlineRequired = $true }
    DomainUsersCount                                                = @{OnlineRequired = $true }
    DomainUsersAll                                                  = @{OnlineRequired = $true }
    DomainUsersSystemAccounts                                       = @{OnlineRequired = $true }
    DomainUsersNeverExpiring                                        = @{OnlineRequired = $true }
    DomainUsersNeverExpiringInclDisabled                            = @{OnlineRequired = $true }
    DomainUsersExpiredInclDisabled                                  = @{OnlineRequired = $true }
    DomainUsersExpiredExclDisabled                                  = @{OnlineRequired = $true }
    DomainAdministrators                                            = @{OnlineRequired = $true }
    DomainAdministratorsRecursive                                   = @{OnlineRequired = $true }
    DomainEnterpriseAdministrators                                  = @{OnlineRequired = $true }
    DomainEnterpriseAdministratorsRecursive                         = @{OnlineRequired = $true }
    DomainComputersFullList                                         = @{OnlineRequired = $true }
    DomainComputersAll                                              = @{OnlineRequired = $true }
    DomainComputersAllCount                                         = @{OnlineRequired = $true }
    DomainComputers                                                 = @{OnlineRequired = $true }
    DomainComputersCount                                            = @{OnlineRequired = $true }
    DomainServers                                                   = @{OnlineRequired = $true }
    DomainServersCount                                              = @{OnlineRequired = $true }
    DomainComputersUnknown                                          = @{OnlineRequired = $true }
    DomainComputersUnknownCount                                     = @{OnlineRequired = $true }
    DomainPasswordDataUsers                                         = @{OnlineRequired = $true }
    DomainPasswordDataPasswords                                     = @{OnlineRequired = $true }
    DomainPasswordDataPasswordsHashes                               = @{OnlineRequired = $true }
    DomainPasswordClearTextPassword                                 = @{OnlineRequired = $true }
    DomainPasswordClearTextPasswordEnabled                          = @{OnlineRequired = $true }
    DomainPasswordClearTextPasswordDisabled                         = @{OnlineRequired = $true }
    DomainPasswordLMHash                                            = @{OnlineRequired = $true }
    DomainPasswordEmptyPassword                                     = @{OnlineRequired = $true }
    DomainPasswordWeakPassword                                      = @{OnlineRequired = $true }
    DomainPasswordWeakPasswordEnabled                               = @{OnlineRequired = $true }
    DomainPasswordWeakPasswordDisabled                              = @{OnlineRequired = $true }
    DomainPasswordWeakPasswordList                                  = @{OnlineRequired = $true }
    DomainPasswordDefaultComputerPassword                           = @{OnlineRequired = $true }
    DomainPasswordPasswordNotRequired                               = @{OnlineRequired = $true }
    DomainPasswordPasswordNeverExpires                              = @{OnlineRequired = $true }
    DomainPasswordAESKeysMissing                                    = @{OnlineRequired = $true }
    DomainPasswordPreAuthNotRequired                                = @{OnlineRequired = $true }
    DomainPasswordDESEncryptionOnly                                 = @{OnlineRequired = $true }
    DomainPasswordDelegatableAdmins                                 = @{OnlineRequired = $true }
    DomainPasswordDuplicatePasswordGroups                           = @{OnlineRequired = $true }
    DomainPasswordHashesWeakPassword                                = @{OnlineRequired = $true }
    DomainPasswordHashesWeakPasswordEnabled                         = @{OnlineRequired = $true }
    DomainPasswordHashesWeakPasswordDisabled                        = @{OnlineRequired = $true }
    DomainPasswordStats                                             = @{OnlineRequired = $true }
}
$Script:Document = [ordered]@{Configuration = [ordered] @{Prettify = @{CompanyName = 'Evotec'
            UseBuiltinTemplate                                                     = $true
            CustomTemplatePath                                                     = ''
            Language                                                               = 'en-US'
        }
        Options                                                    = @{OpenDocument = $false
            OpenExcel                                                               = $false
        }
        DisplayConsole                                             = @{ShowTime = $false
            LogFile                                                             = "$ENV:TEMP\PSWinDocumentationTesting.log"
            TimeFormat                                                          = 'yyyy-MM-dd HH:mm:ss'
        }
        Debug                                                      = @{Verbose = $false }
    }
    DocumentAD                              = [ordered] @{Enable = $true
        ExportWord                                               = $true
        ExportExcel                                              = $true
        FilePathWord                                             = "$Env:USERPROFILE\Desktop\PSWinDocumentation-Report.docx"
        FilePathExcel                                            = "$Env:USERPROFILE\Desktop\PSWinDocumentation-Report.xlsx"
        Sections                                                 = [ordered] @{SectionForest = [ordered] @{SectionTOC = [ordered] @{Use = $true
                    TocGlobalDefinition                                                                    = $true
                    TocGlobalTitle                                                                         = 'Table of content'
                    TocGlobalRightTabPos                                                                   = 15
                    PageBreaksAfter                                                                        = 1
                }
                SectionForestIntroduction                                                = [ordered] @{Use = $true
                    TocEnable                                                           = $True
                    TocText                                                             = 'Scope'
                    TocListLevel                                                        = 0
                    TocListItemType                                                     = 'Numbered'
                    TocHeadingType                                                      = 'Heading1'
                    Text                                                                = "This document provides a low-level design of roles and permissions for" + " the IT infrastructure team at <CompanyName> organization. This document utilizes knowledge from" + " AD General Concept document that should be delivered with this document. Having all the information" + " described in attached document one can start designing Active Directory with those principles in mind." + " It's important to know while best practices that were described are important in decision making they" + " should not be treated as final and only solution. Most important aspect is to make sure company has full" + " usability of Active Directory and is happy with how it works. Making things harder just for the sake of" + " implementation of best practices isn't always the best way to go."
                    TextAlignment                                                       = 'Both'
                    PageBreaksAfter                                                     = 1
                }
                SectionForestSummary                                                     = [ordered] @{Use = $true
                    TocEnable                                                           = $True
                    TocText                                                             = 'General Information - Forest Summary'
                    TocListLevel                                                        = 0
                    TocListItemType                                                     = 'Numbered'
                    TocHeadingType                                                      = 'Heading1'
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestInformation
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    TableTitleMerge                                                     = $true
                    TableTitleText                                                      = "Forest Summary"
                    Text                                                                = "Active Directory at <CompanyName> has a forest name <ForestName>." + " Following table contains forest summary with important information:"
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Summary'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestInformation
                }
                SectionForestFSMO                                                        = [ordered] @{Use = $true
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestFSMO
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    TableTitleMerge                                                     = $true
                    TableTitleText                                                      = 'FSMO Roles'
                    Text                                                                = 'Following table contains FSMO servers'
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest FSMO'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestFSMO
                }
                SectionForestOptionalFeatures                                            = [ordered] @{Use = $true
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestOptionalFeatures
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    TableTitleMerge                                                     = $true
                    TableTitleText                                                      = 'Optional Features'
                    Text                                                                = 'Following table contains optional forest features'
                    TextNoData                                                          = "Following section should have table containing forest features. However no data was provided."
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Optional Features'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestOptionalFeatures
                }
                SectionForestUPNSuffixes                                                 = [ordered] @{Use = $true
                    Text                                                                = "Following UPN suffixes were created in this forest:"
                    TextNoData                                                          = "No UPN suffixes were created in this forest."
                    ListType                                                            = 'Bulleted'
                    ListData                                                            = [PSWinDocumentation.ActiveDirectory]::ForestUPNSuffixes
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest UPN Suffixes'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestUPNSuffixes
                }
                SectionForesSPNSuffixes                                                  = [ordered] @{Use = $true
                    Text                                                                = "Following SPN suffixes were created in this forest:"
                    TextNoData                                                          = "No SPN suffixes were created in this forest."
                    ListType                                                            = 'Bulleted'
                    ListData                                                            = [PSWinDocumentation.ActiveDirectory]::ForestSPNSuffixes
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest SPN Suffixes'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSPNSuffixes
                }
                SectionForestSites1                                                      = [ordered] @{Use = $true
                    TocEnable                                                           = $True
                    TocText                                                             = 'General Information - Sites'
                    TocListLevel                                                        = 1
                    TocListItemType                                                     = 'Numbered'
                    TocHeadingType                                                      = 'Heading1'
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSites1
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    Text                                                                = "Forest Sites list can be found below"
                    ExcelExport                                                         = $false
                    ExcelWorkSheet                                                      = 'Forest Sites 1'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSites1
                }
                SectionForestSites2                                                      = [ordered] @{Use = $true
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSites2
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    Text                                                                = "Forest Sites list can be found below"
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $false
                    ExcelWorkSheet                                                      = 'Forest Sites 2'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSites2
                }
                SectionForestSites                                                       = [ordered] @{Use = $true
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Sites'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSites
                }
                SectionForestSubnets1                                                    = [ordered] @{Use = $true
                    TocEnable                                                           = $True
                    TocText                                                             = 'General Information - Subnets'
                    TocListLevel                                                        = 1
                    TocListItemType                                                     = 'Numbered'
                    TocHeadingType                                                      = 'Heading1'
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSubnets1
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    Text                                                                = "Table below contains information regarding relation between Subnets and sites"
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Subnets 1'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSubnets1
                }
                SectionForestSubnets2                                                    = [ordered] @{Use = $true
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSubnets2
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    Text                                                                = "Table below contains information regarding relation between Subnets and sites"
                    EmptyParagraphsBefore                                               = 1
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Subnets 2'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSubnets2
                }
                SectionForestSiteLinks                                                   = [ordered] @{Use = $true
                    TocEnable                                                           = $True
                    TocText                                                             = 'General Information - Site Links'
                    TocListLevel                                                        = 1
                    TocListItemType                                                     = 'Numbered'
                    TocHeadingType                                                      = 'Heading1'
                    TableData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSiteLinks
                    TableDesign                                                         = 'ColorfulGridAccent5'
                    Text                                                                = "Forest Site Links information is available in table below"
                    ExcelExport                                                         = $true
                    ExcelWorkSheet                                                      = 'Forest Site Links'
                    ExcelData                                                           = [PSWinDocumentation.ActiveDirectory]::ForestSiteLinks
                }
            }
            SectionDomain                                       = [ordered] @{SectionPageBreak = [ordered] @{Use = $True
                    PageBreaksBefore                                                          = 1
                }
                SectionDomainStarter                                        = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Domain <Domain>'
                    TocListLevel                                                    = 0
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading1'
                }
                SectionDomainIntroduction                                   = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Domain Summary'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading1'
                    Text                                                            = "Following domain exists within forest <ForestName>:"
                    ListBuilderContent                                              = "Domain <DomainDN>", 'Name for fully qualified domain name (FQDN): <Domain>', 'Name for NetBIOS: <DomainNetBios>'
                    ListBuilderLevel                                                = 0, 1, 1
                    ListBuilderType                                                 = 'Bulleted', 'Bulleted', 'Bulleted'
                    EmptyParagraphsBefore                                           = 0
                }
                SectionDomainControllers                                    = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Domain Controllers'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainControllers
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableMaximumColumns                                             = 8
                    Text                                                            = 'Following table contains domain controllers'
                    TextNoData                                                      = ''
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DCs'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainControllers
                }
                SectionDomainFSMO                                           = [ordered] @{Use = $true
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainFSMO
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $true
                    TableTitleText                                                  = "FSMO Roles for <Domain>"
                    Text                                                            = "Following table contains FSMO servers with roles for domain <Domain>"
                    EmptyParagraphsBefore                                           = 1
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - FSMO'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainFSMO
                }
                SectionDomainDefaultPasswordPolicy                          = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Password Policies'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDefaultPasswordPolicy
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $True
                    TableTitleText                                                  = "Default Password Policy for <Domain>"
                    Text                                                            = 'Following table contains password policies for all users within <Domain>'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DefaultPasswordPolicy'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDefaultPasswordPolicy
                }
                SectionDomainFineGrainedPolicies                            = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Fine Grained Password Policies'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPolicies
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableMaximumColumns                                             = 8
                    TableTitleMerge                                                 = $false
                    TableTitleText                                                  = "Fine Grained Password Policy for <Domain>"
                    Text                                                            = 'Following table contains fine grained password policies'
                    TextNoData                                                      = "Following section should cover fine grained password policies. " + "There were no fine grained password polices defined in <Domain>. There was no formal requirement to have " + "them set up."
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Password Policy (Grained)'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPolicies
                }
                SectionDomainGroupPolicies                                  = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Group Policies'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupPolicies
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = "Following table contains group policies for <Domain>"
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - GroupPolicies'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupPolicies
                }
                SectionDomainGroupPoliciesDetails                           = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Group Policies Details'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesDetails
                    TableMaximumColumns                                             = 6
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = "Following table contains group policies for <Domain>"
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - GroupPolicies Details'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesDetails
                }
                SectionDomainGroupPoliciesACL                               = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - GroupPoliciesACL'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesACL
                }
                SectionDomainDNSSrv                                         = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - DNS A/SRV Records'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDNSSRV
                    TableMaximumColumns                                             = 10
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = "Following table contains SRV records for Kerberos and LDAP"
                    EmptyParagraphsAfter                                            = 1
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DNSSRV'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDNSSRV
                }
                SectionDomainDNSA                                           = [ordered] @{Use = $true
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDNSA
                    TableMaximumColumns                                             = 10
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = "Following table contains A records for Kerberos and LDAP"
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DNSA'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainDNSA
                }
                SectionDomainTrusts                                         = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Trusts'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainTrusts
                    TableMaximumColumns                                             = 6
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = "Following table contains trusts established with domains..."
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainTrusts'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainTrusts
                }
                SectionDomainOrganizationalUnits                            = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Organizational Units'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnits
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableMaximumColumns                                             = 4
                    Text                                                            = "Following table contains all OU's created in <Domain>"
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - OrganizationalUnits'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnits
                }
                SectionDomainPriviligedGroup                                = [ordered] @{Use = $False
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Priviliged Groups'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following table contains list of priviliged groups and count of the members in it.'
                    ChartEnable                                                     = $True
                    ChartTitle                                                      = 'Priviliged Group Members'
                    ChartData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
                    ChartKeys                                                       = 'Group Name', 'Members Count'
                    ChartValues                                                     = 'Members Count'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - PriviligedGroupMembers'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
                }
                SectionDomainUsers                                          = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Domain Users in <Domain>'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading1'
                    PageBreaksBefore                                                = 1
                    Text                                                            = 'Following section covers users information for domain <Domain>. '
                }
                SectionDomainUsersCount                                     = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Users Count'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersCount
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $true
                    TableTitleText                                                  = 'Users Count'
                    Text                                                            = "Following table and chart shows number of users in its categories"
                    ChartEnable                                                     = $True
                    ChartTitle                                                      = 'Users Count'
                    ChartData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersCount
                    ChartKeys                                                       = 'Keys'
                    ChartValues                                                     = 'Values'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - UsersCount'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersCount
                }
                SectionDomainAdministrators                                 = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Domain Administrators'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainAdministratorsRecursive
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following users have highest priviliges and are able to control a lot of Windows resources.'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainAdministrators'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainAdministratorsRecursive
                }
                SectionEnterpriseAdministrators                             = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Enterprise Administrators'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministratorsRecursive
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following users have highest priviliges across Forest and are able to control a lot of Windows resources.'
                    TextNoData                                                      = 'No Enterprise Administrators users were defined for this domain.'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - EnterpriseAdministrators'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministratorsRecursive
                }
                SectionDomainComputers                                      = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Computer Objects in <Domain>'
                    TocListLevel                                                    = 1
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading1'
                    PageBreaksBefore                                                = 1
                    Text                                                            = 'Following section covers computers information for domain <Domain>. '
                }
                DomainComputers                                             = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Computers'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputers
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following client computers are created in <Domain>.'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainComputers'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputers
                }
                DomainComputersCount                                        = [ordered] @{Use = $true
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $true
                    TableTitleText                                                  = 'Computers Count'
                    Text                                                            = "Following table and chart shows number of computers and their versions"
                    ChartEnable                                                     = $True
                    ChartTitle                                                      = 'Computers Count'
                    ChartData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
                    ChartKeys                                                       = 'System Name', 'System Count'
                    ChartValues                                                     = 'System Count'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainComputersCount'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
                    EmptyParagraphsBefore                                           = 1
                }
                DomainServers                                               = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Servers'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainServers
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following client computers are created in <Domain>.'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainComputers'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainServers
                }
                DomainServersCount                                          = [ordered] @{Use = $true
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainServersCount
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $true
                    TableTitleText                                                  = 'Servers Count'
                    Text                                                            = "Following table and chart shows number of servers and their versions"
                    ChartEnable                                                     = $True
                    ChartTitle                                                      = 'Servers Count'
                    ChartData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainServersCount
                    ChartKeys                                                       = 'System Name', 'System Count'
                    ChartValues                                                     = 'System Count'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - DomainServersCount'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainServersCount
                    EmptyParagraphsBefore                                           = 1
                }
                DomainComputersUnknown                                      = [ordered] @{Use = $true
                    TocEnable                                                       = $True
                    TocText                                                         = 'General Information - Unknown Computer Objects'
                    TocListLevel                                                    = 2
                    TocListItemType                                                 = 'Numbered'
                    TocHeadingType                                                  = 'Heading2'
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    Text                                                            = 'Following client computers are not asisgned to clients or computers in <Domain>.'
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - ComputersUnknown'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
                }
                DomainComputersUnknownCount                                 = [ordered] @{Use = $true
                    TableData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
                    TableDesign                                                     = 'ColorfulGridAccent5'
                    TableTitleMerge                                                 = $true
                    TableTitleText                                                  = 'Unknown Computers Count'
                    Text                                                            = "Following table and chart shows number of unknown object computers in domain."
                    ExcelExport                                                     = $false
                    ExcelWorkSheet                                                  = '<Domain> - ComputersUnknownCount'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
                    EmptyParagraphsBefore                                           = 1
                }
                SectionExcelDomainOrganizationalUnitsBasicACL               = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - OU ACL Basic'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsBasicACL
                }
                SectionExcelDomainOrganizationalUnitsExtended               = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - OU ACL Extended'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtended
                }
                SectionExcelDomainUsers                                     = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Users'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsers
                }
                SectionExcelDomainUsersAll                                  = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Users All'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersAll
                }
                SectionExcelDomainUsersSystemAccounts                       = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Users System'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersSystemAccounts
                }
                SectionExcelDomainUsersNeverExpiring                        = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Never Expiring'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiring
                }
                SectionExcelDomainUsersNeverExpiringInclDisabled            = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Never Expiring incl Disabled'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiringInclDisabled
                }
                SectionExcelDomainUsersExpiredInclDisabled                  = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Expired incl Disabled'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredInclDisabled
                }
                SectionExcelDomainUsersExpiredExclDisabled                  = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Expired excl Disabled'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredExclDisabled
                }
                SectionExcelDomainUsersFullList                             = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Users List Full'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainUsersFullList
                }
                SectionExcelDomainComputersFullList                         = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Computers List'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainComputersFullList
                }
                SectionExcelDomainGroupsFullList                            = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Groups List'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsFullList
                }
                SectionExcelDomainGroupsRest                                = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Groups'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroups
                }
                SectionExcelDomainGroupsSpecial                             = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Groups Special'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecial
                }
                SectionExcelDomainGroupsPriviliged                          = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Groups Priv'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
                }
                SectionExcelDomainGroupMembers                              = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembers
                }
                SectionExcelDomainGroupMembersSpecial                       = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members Special'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembers
                }
                SectionExcelDomainGroupMembersPriviliged                    = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members Priv'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembers
                }
                SectionExcelDomainGroupMembersRecursive                     = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members Rec'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembersRecursive
                }
                SectionExcelDomainGroupMembersSpecialRecursive              = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members RecSpecial'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembersRecursive
                }
                SectionExcelDomainGroupMembersPriviligedRecursive           = [ordered] @{Use = $true
                    ExcelExport                                                     = $true
                    ExcelWorkSheet                                                  = '<Domain> - Members RecPriv'
                    ExcelData                                                       = [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembersRecursive
                }
            }
        }
    }
}
$Script:O365SKU = @{"O365_BUSINESS_ESSENTIALS" = "Office 365 Business Essentials"
    "O365_BUSINESS_PREMIUM"                    = "Office 365 Business Premium"
    "DESKLESSPACK"                             = "Office 365 (Plan K1)"
    "DESKLESSWOFFPACK"                         = "Office 365 (Plan K2)"
    "LITEPACK"                                 = "Office 365 (Plan P1)"
    "EXCHANGESTANDARD"                         = "Office 365 Exchange Online Only"
    "STANDARDPACK"                             = "Enterprise Plan E1"
    "STANDARDWOFFPACK"                         = "Office 365 (Plan E2)"
    "ENTERPRISEPACK"                           = "Enterprise Plan E3"
    "ENTERPRISEPACKLRG"                        = "Enterprise Plan E3"
    "ENTERPRISEWITHSCAL"                       = "Enterprise Plan E4"
    "STANDARDPACK_STUDENT"                     = "Office 365 (Plan A1) for Students"
    "STANDARDWOFFPACKPACK_STUDENT"             = "Office 365 (Plan A2) for Students"
    "ENTERPRISEPACK_STUDENT"                   = "Office 365 (Plan A3) for Students"
    "ENTERPRISEWITHSCAL_STUDENT"               = "Office 365 (Plan A4) for Students"
    "STANDARDPACK_FACULTY"                     = "Office 365 (Plan A1) for Faculty"
    "STANDARDWOFFPACKPACK_FACULTY"             = "Office 365 (Plan A2) for Faculty"
    "ENTERPRISEPACK_FACULTY"                   = "Office 365 (Plan A3) for Faculty"
    "ENTERPRISEWITHSCAL_FACULTY"               = "Office 365 (Plan A4) for Faculty"
    "ENTERPRISEPACK_B_PILOT"                   = "Office 365 (Enterprise Preview)"
    "STANDARD_B_PILOT"                         = "Office 365 (Small Business Preview)"
    "VISIOCLIENT"                              = "Visio Pro Online"
    "POWER_BI_ADDON"                           = "Office 365 Power BI Addon"
    "POWER_BI_INDIVIDUAL_USE"                  = "Power BI Individual User"
    "POWER_BI_STANDALONE"                      = "Power BI Stand Alone"
    "POWER_BI_STANDARD"                        = "Power-BI Standard"
    "PROJECTESSENTIALS"                        = "Project Lite"
    "PROJECTCLIENT"                            = "Project Professional"
    "PROJECTONLINE_PLAN_1"                     = "Project Online"
    "PROJECTONLINE_PLAN_2"                     = "Project Online and PRO"
    "ProjectPremium"                           = "Project Online Premium"
    "ECAL_SERVICES"                            = "ECAL"
    "EMS"                                      = "Enterprise Mobility Suite"
    "RIGHTSMANAGEMENT_ADHOC"                   = "Windows Azure Rights Management"
    "MCOMEETADV"                               = "PSTN conferencing"
    "SHAREPOINTSTORAGE"                        = "SharePoint storage"
    "PLANNERSTANDALONE"                        = "Planner Standalone"
    "CRMIUR"                                   = "CMRIUR"
    "BI_AZURE_P1"                              = "Power BI Reporting and Analytics"
    "INTUNE_A"                                 = "Windows Intune Plan A"
    "PROJECTWORKMANAGEMENT"                    = "Office 365 Planner Preview"
    "ATP_ENTERPRISE"                           = "Exchange Online Advanced Threat Protection"
    "EQUIVIO_ANALYTICS"                        = "Office 365 Advanced eDiscovery"
    "AAD_BASIC"                                = "Azure Active Directory Basic"
    "RMS_S_ENTERPRISE"                         = "Azure Active Directory Rights Management"
    "AAD_PREMIUM"                              = "Azure Active Directory Premium"
    "MFA_PREMIUM"                              = "Azure Multi-Factor Authentication"
    "STANDARDPACK_GOV"                         = "Microsoft Office 365 (Plan G1) for Government"
    "STANDARDWOFFPACK_GOV"                     = "Microsoft Office 365 (Plan G2) for Government"
    "ENTERPRISEPACK_GOV"                       = "Microsoft Office 365 (Plan G3) for Government"
    "ENTERPRISEWITHSCAL_GOV"                   = "Microsoft Office 365 (Plan G4) for Government"
    "DESKLESSPACK_GOV"                         = "Microsoft Office 365 (Plan K1) for Government"
    "ESKLESSWOFFPACK_GOV"                      = "Microsoft Office 365 (Plan K2) for Government"
    "EXCHANGESTANDARD_GOV"                     = "Microsoft Office 365 Exchange Online (Plan 1) only for Government"
    "EXCHANGEENTERPRISE_GOV"                   = "Microsoft Office 365 Exchange Online (Plan 2) only for Government"
    "SHAREPOINTDESKLESS_GOV"                   = "SharePoint Online Kiosk"
    "EXCHANGE_S_DESKLESS_GOV"                  = "Exchange Kiosk"
    "RMS_S_ENTERPRISE_GOV"                     = "Windows Azure Active Directory Rights Management"
    "OFFICESUBSCRIPTION_GOV"                   = "Office ProPlus"
    "MCOSTANDARD_GOV"                          = "Lync Plan 2G"
    "SHAREPOINTWAC_GOV"                        = "Office Online for Government"
    "SHAREPOINTENTERPRISE_GOV"                 = "SharePoint Plan 2G"
    "EXCHANGE_S_ENTERPRISE_GOV"                = "Exchange Plan 2G"
    "EXCHANGE_S_ARCHIVE_ADDON_GOV"             = "Exchange Online Archiving"
    "EXCHANGE_S_DESKLESS"                      = "Exchange Online Kiosk"
    "SHAREPOINTDESKLESS"                       = "SharePoint Online Kiosk"
    "SHAREPOINTWAC"                            = "Office Online"
    "YAMMER_ENTERPRISE"                        = "Yammer for the Starship Enterprise"
    "EXCHANGE_L_STANDARD"                      = "Exchange Online (Plan 1)"
    "MCOLITE"                                  = "Lync Online (Plan 1)"
    "SHAREPOINTLITE"                           = "SharePoint Online (Plan 1)"
    "OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ"       = "Office ProPlus"
    "EXCHANGE_S_STANDARD_MIDMARKET"            = "Exchange Online (Plan 1)"
    "MCOSTANDARD_MIDMARKET"                    = "Lync Online (Plan 1)"
    "SHAREPOINTENTERPRISE_MIDMARKET"           = "SharePoint Online (Plan 1)"
    "OFFICESUBSCRIPTION"                       = "Office ProPlus"
    "YAMMER_MIDSIZE"                           = "Yammer"
    "DYN365_ENTERPRISE_PLAN1"                  = "Dynamics 365 Customer Engagement Plan Enterprise Edition"
    "ENTERPRISEPREMIUM_NOPSTNCONF"             = "Enterprise E5 (without Audio Conferencing)"
    "ENTERPRISEPREMIUM"                        = "Enterprise E5 (with Audio Conferencing)"
    "MCOSTANDARD"                              = "Skype for Business Online Standalone Plan 2"
    "PROJECT_MADEIRA_PREVIEW_IW_SKU"           = "Dynamics 365 for Financials for IWs"
    "STANDARDWOFFPACK_IW_STUDENT"              = "Office 365 Education for Students"
    "STANDARDWOFFPACK_IW_FACULTY"              = "Office 365 Education for Faculty"
    "EOP_ENTERPRISE_FACULTY"                   = "Exchange Online Protection for Faculty"
    "EXCHANGESTANDARD_STUDENT"                 = "Exchange Online (Plan 1) for Students"
    "OFFICESUBSCRIPTION_STUDENT"               = "Office ProPlus Student Benefit"
    "STANDARDWOFFPACK_FACULTY"                 = "Office 365 Education E1 for Faculty"
    "STANDARDWOFFPACK_STUDENT"                 = "Microsoft Office 365 (Plan A2) for Students"
    "DYN365_FINANCIALS_BUSINESS_SKU"           = "Dynamics 365 for Financials Business Edition"
    "DYN365_FINANCIALS_TEAM_MEMBERS_SKU"       = "Dynamics 365 for Team Members Business Edition"
    "FLOW_FREE"                                = "Microsoft Flow Free"
    "POWER_BI_PRO"                             = "Power BI Pro"
    "O365_BUSINESS"                            = "Office 365 Business"
    "DYN365_ENTERPRISE_SALES"                  = "Dynamics Office 365 Enterprise Sales"
    "RIGHTSMANAGEMENT"                         = "Rights Management"
    "PROJECTPROFESSIONAL"                      = "Project Professional"
    "VISIOONLINE_PLAN1"                        = "Visio Online Plan 1"
    "EXCHANGEENTERPRISE"                       = "Exchange Online Plan 2"
    "DYN365_ENTERPRISE_P1_IW"                  = "Dynamics 365 P1 Trial for Information Workers"
    "DYN365_ENTERPRISE_TEAM_MEMBERS"           = "Dynamics 365 For Team Members Enterprise Edition"
    "CRMSTANDARD"                              = "Microsoft Dynamics CRM Online Professional"
    "EXCHANGEARCHIVE_ADDON"                    = "Exchange Online Archiving For Exchange Online"
    "EXCHANGEDESKLESS"                         = "Exchange Online Kiosk"
    "SPZA_IW"                                  = "App Connect"
    "WINDOWS_STORE"                            = "Windows Store for Business"
    "MCOEV"                                    = "Microsoft Phone System"
    "VIDEO_INTEROP"                            = "Polycom Skype Meeting Video Interop for Skype for Business"
    "SPE_E5"                                   = "Microsoft 365 E5"
    "SPE_E3"                                   = "Microsoft 365 E3"
    "ATA"                                      = "Advanced Threat Analytics"
    "MCOPSTN2"                                 = "Domestic and International Calling Plan"
    "FLOW_P1"                                  = "Microsoft Flow Plan 1"
    "FLOW_P2"                                  = "Microsoft Flow Plan 2"
    "POWERAPPS_VIRAL"                          = "Microsoft PowerApps Plan 2"
}
$Script:Services = @{OnPremises = [ordered] @{Credentials = [ordered] @{Username = ''
            Password                                                             = ''
            PasswordAsSecure                                                     = $true
            PasswordFromFile                                                     = $true
        }
        ActiveDirectory                                   = [ordered] @{Use = $true
            OnlineMode                                                      = $true
            Import                                                          = @{Use = $false
                From                              = 'Folder'
                Path                              = "$Env:USERPROFILE\Desktop\PSWinDocumentation"
            }
            Export                                                          = @{Use = $false
                To                                = 'Folder'
                FolderPath                        = "$Env:USERPROFILE\Desktop\PSWinDocumentation"
                FilePath                          = "$Env:USERPROFILE\Desktop\PSWinDocumentation\PSWinDocumentation.xml"
            }
            Prefix                                                          = ''
            SessionName                                                     = 'ActiveDirectory'
            PasswordTests                                                   = @{Use = $false
                PasswordFilePathClearText         = 'C:\Support\GitHub\PSWinDocumentation\Ignore\Passwords.txt'
                UseHashDB                         = $false
                PasswordFilePathHash              = 'C:\Support\GitHub\PSWinDocumentation\Ignore\Passwords-Hashes.txt'
            }
        }
    }
}
$Script:ServicesAWS = @{Amazon = [ordered] @{Credentials = [ordered] @{AccessKey = ''
            SecretKey                                                            = ''
            Region                                                               = 'eu-west-1'
        }
        AWS                                              = [ordered] @{Use = $true
            OnlineMode                                                     = $true
            Import                                                         = @{Use = $false
                From                  = 'Folder'
                Path                  = "$Env:USERPROFILE\Desktop\PSWinDocumentation"
            }
            Export                                                         = @{Use = $false
                To                    = 'Folder'
                FolderPath            = "$Env:USERPROFILE\Desktop\PSWinDocumentation"
                FilePath              = "$Env:USERPROFILE\Desktop\PSWinDocumentation\PSWinDocumentation.xml"
            }
            Prefix                                                         = ''
            SessionName                                                    = 'AWS'
        }
    }
}
$Script:ServicesO365 = @{Office365 = [ordered] @{Credentials = [ordered] @{Username = 'przemyslaw.klys@evotec.pl'
            Password                                                                = 'C:\Support\Important\Password-O365-Evotec.txt'
            PasswordAsSecure                                                        = $true
            PasswordFromFile                                                        = $true
        }
        Azure                                                = [ordered] @{Use = $true
            OnlineMode                                                         = $true
            Import                                                             = @{Use = $false
                From                    = 'Folder'
                Path                    = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365Azure"
            }
            Export                                                             = @{Use = $false
                To                      = 'Folder'
                FolderPath              = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365Azure"
                FilePath                = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365Azure\PSWinDocumentation.xml"
            }
            ExportXML                                                          = $false
            FilePathXML                                                        = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365Azure.xml"
            Prefix                                                             = ''
            SessionName                                                        = 'O365Azure'
        }
        AzureAD                                              = [ordered] @{Use = $true
            OnlineMode                                                         = $true
            Import                                                             = @{Use = $false
                From                      = 'Folder'
                Path                      = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365AzureAD"
            }
            Export                                                             = @{Use = $false
                To                        = 'Folder'
                FolderPath                = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365AzureAD"
                FilePath                  = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365AzureAD\PSWinDocumentation.xml"
            }
            ExportXML                                                          = $false
            FilePathXML                                                        = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365AzureAD.xml"
            SessionName                                                        = 'O365AzureAD'
            Prefix                                                             = ''
        }
        ExchangeOnline                                       = [ordered] @{Use = $true
            OnlineMode                                                         = $true
            Import                                                             = @{Use = $false
                From                             = 'Folder'
                Path                             = "$Env:USERPROFILE\Desktop\PSWinDocumentation"
            }
            Export                                                             = @{Use = $false
                To                               = 'Folder'
                FolderPath                       = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365ExchangeOnline"
                FilePath                         = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365ExchangeOnline\PSWinDocumentation.xml"
            }
            ExportXML                                                          = $false
            FilePathXML                                                        = "$Env:USERPROFILE\Desktop\PSWinDocumentation-O365ExchangeOnline.xml"
            Authentication                                                     = 'Basic'
            ConnectionURI                                                      = 'https://outlook.office365.com/powershell-liveid/'
            Prefix                                                             = 'O365'
            SessionName                                                        = 'O365Exchange'
        }
    }
}
$script:WriteParameters = @{ShowTime = $true
    LogFile                          = ""
    TimeFormat                       = "yyyy-MM-dd HH:mm:ss"
}
function Start-DocumentationAD {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Document)
    $TimeDataOnly = [System.Diagnostics.Stopwatch]::StartNew()
    $TypesRequired = Get-TypesRequired -Sections $Document.DocumentAD.Sections.SectionForest, $Document.DocumentAD.Sections.SectionDomain
    $DataInformationAD = Get-WinServiceData -Credentials $Document.DocumentAD.Services.OnPremises.Credentials -Service $Document.DocumentAD.Services.OnPremises.ActiveDirectory -TypesRequired $TypesRequired -Type 'ActiveDirectory'
    $TimeDataOnly.Stop()
    $TimeDocuments = [System.Diagnostics.Stopwatch]::StartNew()
    if ($Document.DocumentAD.ExportExcel -or $Document.DocumentAD.ExportWord -or $Document.DocumentAD.ExportSQL) {
        if ($Document.DocumentAD.ExportWord) { $WordDocument = Get-DocumentPath -Document $Document -FinalDocumentLocation $Document.DocumentAD.FilePathWord }
        if ($Document.DocumentAD.ExportExcel) { $ExcelDocument = New-ExcelDocument }
        $ADSectionsForest = ($Document.DocumentAD.Sections.SectionForest).Keys
        $ADSectionsDomain = ($Document.DocumentAD.Sections.SectionDomain).Keys
        foreach ($DataInformation in $DataInformationAD) {
            foreach ($Section in $ADSectionsForest) { if ($WordDocument) { $WordDocument = New-DataBlock -WordDocument $WordDocument -Section $Document.DocumentAD.Sections.SectionForest.$Section -Object $DataInformationAD -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentAD.ExportSQL -ExportWord $Document.DocumentAD.ExportWord } else { New-DataBlock -Section $Document.DocumentAD.Sections.SectionForest.$Section -Object $DataInformationAD -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentAD.ExportSQL -ExportWord $Document.DocumentAD.ExportWord } }
            foreach ($Domain in $DataInformationAD.FoundDomains.Keys) { foreach ($Section in $ADSectionsDomain) { if ($WordDocument) { $WordDocument = New-DataBlock -WordDocument $WordDocument -Section $Document.DocumentAD.Sections.SectionDomain.$Section -Object $DataInformationAD -Domain $Domain -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentAD.ExportSQL -ExportWord $Document.DocumentAD.ExportWord } else { New-DataBlock -Section $Document.DocumentAD.Sections.SectionDomain.$Section -Object $DataInformationAD -Domain $Domain -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentAD.ExportSQL -ExportWord $Document.DocumentAD.ExportWord } } }
        }
        if ($Document.DocumentAD.ExportWord) { $FilePath = Save-WordDocument -WordDocument $WordDocument -Language $Document.Configuration.Prettify.Language -FilePath $Document.DocumentAD.FilePathWord -Supress $True -OpenDocument:$Document.Configuration.Options.OpenDocument }
        if ($Document.DocumentAD.ExportExcel) { $ExcelData = Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $Document.DocumentAD.FilePathExcel -OpenWorkBook:$Document.Configuration.Options.OpenExcel }
    }
    $TimeDocuments.Stop()
    Write-Verbose "Time to gather data: $($TimeDataOnly.Elapsed)"
    Write-Verbose "Time to create documents: $($TimeDocuments.Elapsed)"
}
function Start-DocumentationAWS {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Document)
    $TimeDataOnly = [System.Diagnostics.Stopwatch]::StartNew()
    $DataSections = ($Document.DocumentAWS.Sections).Keys
    $TypesRequired = Get-TypesRequired -Sections $Document.DocumentAWS.Sections
    $DataInformation = Get-WinServiceData -Credentials $Document.DocumentAWS.Services.Amazon.Credentials -Service $Document.DocumentAWS.Services.Amazon.AWS -TypesRequired $TypesRequired -Type 'AWS'
    $TimeDataOnly.Stop()
    $TimeDocuments = [System.Diagnostics.Stopwatch]::StartNew()
    if ($DataInformation.Count -gt 0) {
        if ($Document.DocumentAWS.ExportWord) { $WordDocument = Get-DocumentPath -Document $Document -FinalDocumentLocation $Document.DocumentAWS.FilePathWord }
        if ($Document.DocumentAWS.ExportExcel) { $ExcelDocument = New-ExcelDocument }
        foreach ($Section in $DataSections) { $WordDocument = New-DataBlock -WordDocument $WordDocument -Section $Document.DocumentAWS.Sections.$Section -Forest $DataInformation -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentAWS.ExportSQL -ExportWord $Document.DocumentAWS.ExportWord }
        if ($Document.DocumentAWS.ExportWord) { $FilePath = Save-WordDocument -WordDocument $WordDocument -Language $Document.Configuration.Prettify.Language -FilePath $Document.DocumentAWS.FilePathWord -Supress $True -OpenDocument:$Document.Configuration.Options.OpenDocument }
        if ($Document.DocumentAWS.ExportExcel) { $ExcelData = Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $Document.DocumentAWS.FilePathExcel -OpenWorkBook:$Document.Configuration.Options.OpenExcel }
    } else { Write-Warning "There was no data to process AWS documentation. Check configuration." }
    $TimeDocuments.Stop()
    Write-Verbose "Time to gather data: $($TimeDataOnly.Elapsed)"
    Write-Verbose "Time to create documents: $($TimeDocuments.Elapsed)"
}
function Start-DocumentationExchange {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Document)
    $DataSections = ($Document.DocumentExchange.Sections).Keys
    $TypesRequired = Get-TypesRequired -Sections $Document.DocumentExchange.Sections
    $TimeDataOnly = [System.Diagnostics.Stopwatch]::StartNew()
    $DataInformation = Get-WinServiceData -Credentials $Document.DocumentExchange.Services.OnPremises.Credentials -Service $Document.DocumentExchange.Services.OnPremises.Exchange -TypesRequired $TypesRequired -Type 'Exchange'
    $TimeDataOnly.Stop()
    $TimeDocuments = [System.Diagnostics.Stopwatch]::StartNew()
    if ($DataInformation.Count -gt 0) {
        if ($Document.DocumentExchange.ExportWord) { $WordDocument = Get-DocumentPath -Document $Document -FinalDocumentLocation $Document.DocumentExchange.FilePathWord }
        if ($Document.DocumentExchange.ExportExcel) { $ExcelDocument = New-ExcelDocument }
        foreach ($Section in $DataSections) { $WordDocument = New-DataBlock -WordDocument $WordDocument -Section $Document.DocumentExchange.Sections.$Section -Forest $DataInformation -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentExchange.ExportSQL -ExportWord $Document.DocumentExchange.ExportWord }
        if ($Document.DocumentExchange.ExportWord) { $FilePath = Save-WordDocument -WordDocument $WordDocument -Language $Document.Configuration.Prettify.Language -FilePath $Document.DocumentExchange.FilePathWord -Supress $True -OpenDocument:$Document.Configuration.Options.OpenDocument }
        if ($Document.DocumentExchange.ExportExcel) { $ExcelData = Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $Document.DocumentExchange.FilePathExcel -OpenWorkBook:$Document.Configuration.Options.OpenExcel }
    } else { Write-Warning "There was no data to process Exchange documentation. Check configuration." }
    $TimeDocuments.Stop()
    Write-Verbose "Time to gather data: $($TimeDataOnly.Elapsed)"
    Write-Verbose "Time to create documents: $($TimeDocuments.Elapsed)"
}
function Start-DocumentationO365 {
    [CmdletBinding()]
    param([System.Collections.IDictionary] $Document)
    $TypesRequired = Get-TypesRequired -Sections $Document.DocumentOffice365.Sections
    $DataSections = ($Document.DocumentOffice365.Sections).Keys
    $TimeDataOnly = [System.Diagnostics.Stopwatch]::StartNew()
    $DataInformation = Get-WinServiceData -Credentials $Document.DocumentOffice365.Services.Office365.Credentials -Service $Document.DocumentOffice365.Services.Office365.ExchangeOnline -TypesRequired $TypesRequired -Type 'O365'
    $TimeDataOnly.Stop()
    $TimeDocuments = [System.Diagnostics.Stopwatch]::StartNew()
    if ($DataInformation.Count -gt 0) {
        if ($Document.DocumentOffice365.ExportWord) { $WordDocument = Get-DocumentPath -Document $Document -FinalDocumentLocation $Document.DocumentOffice365.FilePathWord }
        if ($Document.DocumentOffice365.ExportExcel) { $ExcelDocument = New-ExcelDocument }
        foreach ($Section in $DataSections) { $WordDocument = New-DataBlock -WordDocument $WordDocument -Section $Document.DocumentOffice365.Sections.$Section -Forest $DataInformation -Excel $ExcelDocument -SectionName $Section -Sql $Document.DocumentOffice365.ExportSQL -ExportWord $Document.DocumentOffice365.ExportWord }
        if ($Document.DocumentOffice365.ExportWord) { $FilePath = Save-WordDocument -WordDocument $WordDocument -Language $Document.Configuration.Prettify.Language -FilePath $Document.DocumentOffice365.FilePathWord -Supress $True -OpenDocument:$Document.Configuration.Options.OpenDocument }
        if ($Document.DocumentOffice365.ExportExcel) { $ExcelData = Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $Document.DocumentOffice365.FilePathExcel -OpenWorkBook:$Document.Configuration.Options.OpenExcel }
    } else { Write-Warning "There was no data to process Office 365 documentation. Check configuration." }
    $TimeDocuments.Stop()
    Write-Verbose "Time to gather data: $($TimeDataOnly.Elapsed)"
    Write-Verbose "Time to create documents: $($TimeDocuments.Elapsed)"
}
function Test-Configuration {
    [CmdletBinding()]
    param ([System.Collections.IDictionary] $Document)
    [int] $ErrorCount = 0
    $Script:WriteParameters = $Document.Configuration.DisplayConsole
    $Keys = Get-ObjectKeys -Object $Document -Ignore 'Configuration'
    foreach ($Key in $Keys) {
        $ErrorCount += Test-File -File $Document.$Key.FilePathWord -FileName 'FilePathWord' -Skip:(-not $Document.$Key.ExportWord)
        $ErrorCount += Test-File -File $Document.$Key.FilePathExcel -FileName 'FilePathExcel' -Skip:(-not $Document.$Key.ExportExcel)
    }
    if ($ErrorCount -ne 0) { Exit }
}
function Test-File {
    [CmdletBinding()]
    param ([string] $File,
        [string] $FileName,
        [switch] $Require,
        [switch] $Skip)
    [int] $ErrorCount = 0
    if ($Skip) { return $ErrorCount }
    if ($File -ne '') {
        if ($Require) {
            if (Test-Path $File) { return $ErrorCount } else {
                Write-Color @Script:WriteParameters '[e] ', $FileName, " doesn't exists (", $File, "). It's required if you want to use this feature." -Color Red, Yellow, Yellow, White
                $ErrorCount++
            }
        }
    } else {
        $ErrorCount++
        Write-Color @Script:WriteParameters '[e] ', $FileName, " was empty. It's required if you want to use this feature." -Color Red, Yellow, White
    }
    return $ErrorCount
}
function Start-Documentation {
    [CmdletBinding()]
    param ([System.Collections.IDictionary] $Document)
    $TimeTotal = [System.Diagnostics.Stopwatch]::StartNew()
    Test-Configuration -Document $Document
    if ($Document.DocumentAD.Enable) {
        if ($null -eq $Document.DocumentAD.Services) {
            $Document.DocumentAD.Services = ($Script:Services).Clone()
            $Document.DocumentAD.Services.OnPremises.ActiveDirectory.PasswordTests = @{Use = $Document.DocumentAD.Configuration.PasswordTests.Use
                PasswordFilePathClearText                                                  = $Document.DocumentAD.Configuration.PasswordTests.PasswordFilePathClearText
                UseHashDB                                                                  = $Document.DocumentAD.Configuration.PasswordTests.UseHashDB
                PasswordFilePathHash                                                       = $Document.DocumentAD.Configuration.PasswordTests.PasswordFilePathHash
            }
        }
        Start-DocumentationAD -Document $Document
    }
    if ($Document.DocumentAWS.Enable) {
        if ($null -eq $Document.DocumentAWS.Services) {
            $Document.DocumentAWS.Services = ($Script:ServicesAWS).Clone()
            $Document.DocumentAWS.Services.Amazon.Credentials.AccessKey = $Document.DocumentAWS.Configuration.AWSAccessKey
            $Document.DocumentAWS.Services.Amazon.Credentials.SecretKey = $Document.DocumentAWS.Configuration.AWSSecretKey
            $Document.DocumentAWS.Services.Amazon.Credentials.Region = $Document.DocumentAWS.Configuration.AWSRegion
        }
        Start-DocumentationAWS -Document $Document
    }
    if ($Document.DocumentOffice365.Enable) {
        if ($null -eq $Document.DocumentOffice365.Services) {
            $Document.DocumentOffice365.Services = ($Script:ServicesO365).Clone()
            $Document.DocumentOffice365.Services.Office365.Credentials = [ordered] @{Username = $Document.DocumentOffice365.Configuration.O365Username
                Password                                                                      = $Document.DocumentOffice365.Configuration.O365Password
                PasswordAsSecure                                                              = $Document.DocumentOffice365.Configuration.O365PasswordAsSecure
                PasswordFromFile                                                              = $Document.DocumentOffice365.Configuration.O365PasswordFromFile
            }
            $Document.DocumentOffice365.Services.Office365.Azure.Use = $Document.DocumentOffice365.Configuration.O365AzureADUse
            $Document.DocumentOffice365.Services.Office365.Azure.Prefix = ''
            $Document.DocumentOffice365.Services.Office365.Azure.SessionName = 'O365Azure'
            $Document.DocumentOffice365.Services.Office365.AzureAD.Use = $Document.DocumentOffice365.Configuration.O365AzureADUse
            $Document.DocumentOffice365.Services.Office365.AzureAD.SessionName = 'O365AzureAD'
            $Document.DocumentOffice365.Services.Office365.AzureAD.Prefix = ''
            $Document.DocumentOffice365.Services.Office365.ExchangeOnline.Use = $Document.DocumentOffice365.Configuration.O365ExchangeUse
            $Document.DocumentOffice365.Services.Office365.ExchangeOnline.Authentication = $Document.DocumentOffice365.Configuration.O365ExchangeAuthentication
            $Document.DocumentOffice365.Services.Office365.ExchangeOnline.ConnectionURI = $Document.DocumentOffice365.Configuration.O365ExchangeURI
            $Document.DocumentOffice365.Services.Office365.ExchangeOnline.Prefix = ''
            $Document.DocumentOffice365.Services.Office365.ExchangeOnline.SessionName = $Document.DocumentOffice365.Configuration.O365ExchangeSessionName
        }
        Start-DocumentationO365 -Document $Document
    }
    $TimeTotal.Stop()
    Write-Verbose "Time total: $($TimeTotal.Elapsed)"
}
Export-ModuleMember -Function @('Start-Documentation') -Alias @()
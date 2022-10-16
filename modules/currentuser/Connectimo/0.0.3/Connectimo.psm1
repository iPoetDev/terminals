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
function Connect-WinConnectivity {
    [CmdletBinding()]
    param([string] $UserName,
        [string] $Password,
        [string] $FilePath,
        [switch] $AsSecure,
        [switch] $MultiFactorAuthentication,
        [Parameter(Mandatory = $true)][ValidateSet('All', 'AzureAD', 'ExchangeOnline', 'MSOnline', 'SecurityCompliance', 'SharePointOnline', 'SkypeOnline', 'Teams')][string[]] $Service,
        [string] $Tenant)
    if ($FilePath) {
        $PasswordFromFile = $true
        if (Test-Path -LiteralPath $FilePath) { $Password = $FilePath } else {
            Write-Verbose "File with password doesn't exists. Path doesn't exists: $FilePath"
            return
        }
    } else { $PasswordFromFile = $false }
    $Configuration = @{Options = @{LogsPath = 'C:\Support\Logs\Automated.log' }
        Office365 = [ordered] @{Credentials = [ordered] @{Username = $UserName
                Password = $Password
                PasswordAsSecure = $AsSecure.IsPresent
                PasswordFromFile = $PasswordFromFile
                MultiFactorAuthentication = $MultiFactorAuthentication.IsPresent
            }
            MSOnline = [ordered] @{Use = $false
                SessionName = 'O365 Azure MSOL'
            }
            AzureAD = [ordered] @{Use = $false
                SessionName = 'O365 Azure AD'
                Prefix = ''
            }
            ExchangeOnline = [ordered] @{Use = $false
                Authentication = 'Basic'
                ConnectionURI = 'https://outlook.office365.com/powershell-liveid/'
                Prefix = 'O365'
                SessionName = 'O365 Exchange'
            }
            SecurityCompliance = [ordered] @{Use = $false
                Authentication = 'Basic'
                ConnectionURI = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
                Prefix = 'O365'
                SessionName = 'O365 Security And Compliance'
            }
            SharePointOnline = [ordered] @{Use = $false
                ConnectionURI = "https://$($Tenant)-admin.sharepoint.com"
            }
            SkypeOnline = [ordered] @{Use = $false
                SessionName = 'O365 Skype'
            }
            Teams = [ordered] @{Use = $false
                Prefix = ''
                SessionName = 'O365 Teams'
            }
        }
        OnPremises = @{Credentials = [ordered] @{Username = 'przemyslaw.klys@evotec.pl'
                Password = 'C:\Support\Important\Password-O365-Evotec.txt'
                PasswordAsSecure = $true
                PasswordFromFile = $true
            }
            Exchange = [ordered] @{Use = $false
                Authentication = 'Kerberos'
                ConnectionURI = 'http://PLKATO365Exch.evotec.pl/PowerShell'
                Prefix = ''
                SessionName = 'Exchange'
            }
        }
    }
    if ($Service -eq 'All') {
        foreach ($_ in $Configuration.Office365.Keys | Where-Object { $_ -ne 'Credentials' }) {
            if ($_ -eq 'SharePointOnline') {
                if (-not $Tenant) {
                    Write-Verbose "Tenant parameter not provided. Skipping connection to SharePoint Online."
                    continue
                }
            }
            $Configuration.Office365.($_).Use = $true
        }
    } else { foreach ($_ in $Service) { $Configuration.Office365.($_).Use = $true } }
    $BundleCredentials = $Configuration.Office365.Credentials
    $BundleCredentialsOnPremises = $Configuration.OnPremises.Credentials
    $Connected = @(if ($Configuration.Office365.MSOnline.Use) { Connect-WinAzure @BundleCredentials -Output -SessionName $Configuration.Office365.MSOnline.SessionName -Verbose }
        if ($Configuration.Office365.AzureAD.Use) { Connect-WinAzureAD @BundleCredentials -Output -SessionName $Configuration.Office365.AzureAD.SessionName -Verbose }
        if ($Configuration.Office365.ExchangeOnline.Use) { Connect-WinExchange @BundleCredentials -Output -SessionName $Configuration.Office365.ExchangeOnline.SessionName -ConnectionURI $Configuration.Office365.ExchangeOnline.ConnectionURI -Authentication $Configuration.Office365.ExchangeOnline.Authentication -Verbose }
        if ($Configuration.Office365.SecurityCompliance.Use) { Connect-WinSecurityCompliance @BundleCredentials -Output -SessionName $Configuration.Office365.SecurityCompliance.SessionName -ConnectionURI $Configuration.Office365.SecurityCompliance.ConnectionURI -Authentication $Configuration.Office365.SecurityCompliance.Authentication -Verbose }
        if ($Configuration.Office365.SkypeOnline.Use) { Connect-WinSkype @BundleCredentials -Output -SessionName $Configuration.Office365.SkypeOnline.SessionName -Verbose }
        if ($Configuration.Office365.SharePointOnline.Use) { Connect-WinSharePoint @BundleCredentials -Output -SessionName $Configuration.Office365.SharePointOnline.SessionName -ConnectionURI $Configuration.Office365.SharePointOnline.ConnectionURI -Verbose }
        if ($Configuration.Office365.Teams.Use) { Connect-WinTeams @BundleCredentials -Output -SessionName $Configuration.Office365.Teams.SessionName -Verbose }
        if ($Configuration.OnPremises.Exchange.Use) { Connect-WinExchange @BundleCredentialsOnPremises -Output -SessionName $Configuration.OnPremises.Exchange.SessionName -ConnectionURI $Configuration.OnPremises.Exchange.ConnectionURI -Authentication $Configuration.OnPremises.Exchange.Authentication -Verbose })
    if ($Connected.Status -contains $false) {
        foreach ($C in $Connected | Where-Object { $_.Status -eq $false }) { Write-Verbose "Connecting to tenant failed for $($C.Output) with error $($Connected.Extended)" }
        return
    }
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
function Disconnect-WinSkype {
    [CmdletBinding()]
    param([string] $SessionName = "Microsoft Skype",
        [switch] $Output)
    $Object = @()
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession) {
        try { Remove-PSSession -Name $SessionName -ErrorAction Stop } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($Output) {
                $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. Error: $ErrorMessage" }
                return $Object
            } else {
                Write-Warning "Disconnect-WinSkype - Failed with error message: $ErrorMessage"
                return
            }
        }
        if ($Output) {
            $Object += @{Status = $true; Output = $SessionName; Extended = "Disconnection succeeded." }
            return $Object
        }
    } else {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. No connection exists." }
            return $Object
        }
    }
}
function Disconnect-WinAzure {
    [CmdletBinding()]
    param([string] $SessionName = 'Azure MSOL',
        [switch] $Output,
        [switch] $Force)
    $Object = @()
    if (-not $Force) {
        if ($Output) {
            $Object += @{Status = $true; Output = $SessionName; Extended = "No way to do this. Kill PowerShell session manually." }
            return $Object
        } else {
            Write-Warning "Disconnect-WinAzure - There is no other way to disconnect from $Session then killing PowerShell session. Do this manually!"
            return
        }
    } else { Exit }
}
function Disconnect-WinAzureAD {
    [CmdletBinding()]
    param([string] $SessionName = 'Azure AD',
        [switch] $Output)
    $Object = @()
    try { Disconnect-AzureAD -ErrorAction Stop } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($ErrorMessage -like "*Object reference not set to an instance of an object.*") { $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. No connection exists." } } else { $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. Error: $ErrorMessage" } }
        if ($Output) { return $Object } else {
            Write-Warning "Disconnect-WinAzureAD - Failed with error message: $ErrorMessage"
            return
        }
    }
    if ($Output) {
        $Object += @{Status = $true; Output = $SessionName; Extended = "Disconnection succeeded." }
        return $Object
    }
}
function Disconnect-WinExchange {
    [CmdletBinding()]
    param([string] $SessionName = "Exchange",
        [switch] $Output)
    $Object = @()
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession) {
        try { Remove-PSSession -Name $SessionName -ErrorAction Stop } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($Output) {
                $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. Error: $ErrorMessage" }
                return $Object
            } else {
                Write-Warning "Disconnect-WinExchange - Failed with error message: $ErrorMessage"
                return
            }
        }
        if ($Output) {
            $Object += @{Status = $true; Output = $SessionName; Extended = "Disconnection succeeded." }
            return $Object
        }
    } else {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. No connection exists." }
            return $Object
        }
    }
}
function Disconnect-WinSecurityCompliance {
    [CmdletBinding()]
    param([string] $SessionName = 'Security and Compliance',
        [switch] $Output)
    $Object = @()
    $ExistingSession = Get-PSSession -Name $SessionName -ErrorAction SilentlyContinue
    if ($ExistingSession) {
        try { Remove-PSSession -Name $SessionName -ErrorAction Stop } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($Output) {
                $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. Error: $ErrorMessage" }
                return $Object
            } else {
                Write-Warning "Disconnect-WinSecurityCompliance - Failed with error message: $ErrorMessage"
                return
            }
        }
        if ($Output) {
            $Object += @{Status = $true; Output = $SessionName; Extended = "Disconnection succeeded." }
            return $Object
        }
    } else {
        if ($Output) {
            $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. No connection exists." }
            return $Object
        }
    }
}
function Disconnect-WinService {
    [CmdletBinding()]
    param()
    Get-PSSession | Remove-PSSession
}
function Disconnect-WinTeams {
    [CmdletBinding()]
    param([string] $SessionName = 'Microsoft Teams',
        [switch] $Output)
    $Object = @()
    try { Disconnect-MicrosoftTeams -ErrorAction Stop } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($ErrorMessage -like "*Object reference not set to an instance of an object.*") { $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. No connection exists." } } else { $Object += @{Status = $false; Output = $SessionName; Extended = "Disconnection failed. Error: $ErrorMessage" } }
        if ($Output) { return $Object } else {
            Write-Warning "Disconnect-MicrosoftTeams - Failed with error message: $ErrorMessage"
            return
        }
    }
    if ($Output) {
        $Object += @{Status = $true; Output = $SessionName; Extended = "Disconnection succeeded." }
        return $Object
    }
}
function Get-InstalledApplication {
    <#
    .EXAMPLE
    Get-InstalledApplication -Type UserInstalled -DisplayName 'JetBrains dotCover 2017.1.1'
    #>
    [CmdletBinding()]
    Param([string[]] $DisplayName,
        [ValidateSet('UserInstalled', 'SystemWide', 'ClickOnce')][string] $Type = 'UserInstalled',
        [switch] $All)
    if ($Type -eq 'UserInstalled' -or $Type -eq 'ClickOnce') { $Registry = 'HKCU' } else { $Registry = 'HKLM' }
    $InstalledApplications = Get-ChildItem -Path "$Registry`:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PsPath }
    if ($DisplayName) { $InstalledApplications | Where-Object { $DisplayName -contains $_.DisplayName } } else { $InstalledApplications }
}
function Install-ApplicationClickOnce {
    [CmdletBinding()]
    Param([string] $Manifest,
        [switch] $ElevatePermissions)
    Try {
        Add-Type -AssemblyName System.Deployment
        Write-Verbose "Install-ApplicationClickOnce - Start installation of ClickOnce Application $Manifest"
        $RemoteURI = [URI]::New($Manifest , [UriKind]::Absolute)
        if (-not $Manifest) {
            Write-Warning "Invalid Manifest (URL) parameter $RemoteURI"
            return
        }
        $HostingManager = New-Object System.Deployment.Application.InPlaceHostingManager -ArgumentList $RemoteURI , $False
        $null = Register-ObjectEvent -InputObject $HostingManager -EventName GetManifestCompleted -Action { New-Event -SourceIdentifier "ManifestDownloadComplete" }
        $null = Register-ObjectEvent -InputObject $HostingManager -EventName DownloadApplicationCompleted -Action { New-Event -SourceIdentifier "DownloadApplicationCompleted" }
        $HostingManager.GetManifestAsync()
        $event = Wait-Event -SourceIdentifier "ManifestDownloadComplete" -Timeout 5
        if ($event) {
            $event | Remove-Event
            Write-Verbose "Install-ApplicationClickOnce - ClickOnce Manifest Download Completed"
            $HostingManager.AssertApplicationRequirements($ElevatePermissions)
            $HostingManager.DownloadApplicationAsync()
            $event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 15
            if ($event) {
                $event | Remove-Event
                Write-Verbose "Install-ApplicationClickOnce - ClickOnce Application Download Completed"
            } else { Write-Error "Install-ApplicationClickOnce - ClickOnce Application Download did not complete in time (15s)" }
        } else { Write-Error "Install-ApplicationClickOnce - ClickOnce Manifest Download did not complete in time (5s)" }
    } finally { Get-EventSubscriber | Where-Object { $_.SourceObject.ToString() -eq 'System.Deployment.Application.InPlaceHostingManager' } | Unregister-Event }
}
function Install-WinConnectity {
    [CmdletBinding()]
    param([ValidateSet('MSOnline', 'AzureAD', 'SharePoint', 'ExchangeOnline', 'SkypeOnline', 'Teams')][string[]] $Module,
        [switch] $All,
        [switch] $Force)
    $Splat = @{Force = $Force }
    if ($Module -eq 'MSOnline' -or $All) {
        Write-Verbose "Installing MSOnline Powershell Module"
        Install-Module -Name MSOnline @Splat
    }
    if ($Module -eq 'AzureAD' -or $All) {
        Write-Verbose "Installing AzureAD Powershell Module"
        Install-Module -Name AzureAD @Splat
    }
    if ($Module -eq 'SharePoint' -or $All) {
        Write-Verbose "Installing Microsoft SharePoint Online Powershell Module"
        Install-Module -Name Microsoft.Online.SharePoint.PowerShell @Splat
    }
    if ($Module -eq 'ExchangeOnline' -or $All) {
        Write-Verbose "Checking for Microsoft Exchange Online Powershell Module"
        $App = Test-InstalledApplication -DisplayName "Microsoft Exchange Online Powershell Module"
        if ($null -eq $App) {
            Write-Verbose "Installing Microsoft Exchange Online Powershell Module"
            Install-ApplicationClickOnce -Manifest "https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application" -ElevatePermissions
        }
    }
    if ($Module -eq 'Teams' -or $All) {
        Write-Verbose "Installing Microsoft Teams Powershell Module"
        Install-Module -Name MicrosoftTeams @Splat
    }
    if ($Module -eq 'SkypeOnline' -or $All) { Write-Verbose "Installing Microsoft Skype Online PowerShell Module" }
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
function Test-AvailabilityCommands {
    param ([string[]] $Commands)
    $CommandsStatus = foreach ($Command in $Commands) {
        [bool] $Exists = Get-Command -Name $Command -ErrorAction SilentlyContinue
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
Function Test-InstalledApplication {
    [CmdletBinding()]
    Param([alias('ApplicationName')] [string] $DisplayName)
    $App = Get-InstalledApplication -DisplayName $DisplayName -Type UserInstalled
    return $App
}
function Uninstall-ApplicationClickOnce {
    [CmdletBinding()]
    Param([alias('ApplicationName')] $DisplayName)
    $App = Get-InstalledApplication -DisplayName $DisplayName -Type UserInstalled
    if ($App) {
        $selectedUninstallString = $App.UninstallString
        $parts = $selectedUninstallString.Split(' ', 2)
        Start-Process -FilePath $parts[0] -ArgumentList $parts[1] -Wait
        $app = Get-InstalledApplication -DisplayName $DisplayName -Type UserInstalled
        if ($app) {
            Write-Verbose 'Uninstall-ApplicationClickOnce - Uninstallation was not successfull.'
            return $false
        } else {
            Write-Verbose 'Uninstall-ApplicationClickOnce - Uninstallation was not successfull.'
            return $true
        }
    } else { return }
}
Export-ModuleMember -Function @('Connect-WinAzure', 'Connect-WinAzureAD', 'Connect-WinConnectivity', 'Connect-WinExchange', 'Connect-WinSecurityCompliance', 'Connect-WinService', 'Connect-WinSharePoint', 'Connect-WinSkype', 'Connect-WinTeams', 'Disconnect-WinAzure', 'Disconnect-WinAzureAD', 'Disconnect-WinExchange', 'Disconnect-WinSecurityCompliance', 'Disconnect-WinService', 'Disconnect-WinSkype', 'Disconnect-WinTeams', 'Install-WinConnectity', 'Request-Credentials') -Alias @()
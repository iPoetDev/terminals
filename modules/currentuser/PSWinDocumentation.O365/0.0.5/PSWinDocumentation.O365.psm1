function Convert-ExchangeEmail {
    <#
    .SYNOPSIS
    Function that helps converting Exchange email address list into readable, exportable format.
    
    .DESCRIPTION
        Function that helps converting Exchange email address list into readable, exportable format.
    
    .PARAMETER Emails
    List of emails as available in Exchange or Exchange Online, otherwise known as proxy addresses list
    
    .PARAMETER Separator
    
    .PARAMETER RemoveDuplicates
    
    .PARAMETER RemovePrefix
    
    .PARAMETER AddSeparator
    
    .EXAMPLE
    
    $Emails = @()
    $Emails += 'SIP:test@email.com'
    $Emails += 'SMTP:elo@maiu.com'
    $Emails += 'sip:elo@maiu.com'
    $Emails += 'Spo:dfte@sdsd.com'
    $Emails += 'SPO:myothertest@sco.com'

    Convert-ExchangeEmail -Emails $Emails -RemovePrefix -RemoveDuplicates -AddSeparator
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([string[]] $Emails,
        [string] $Separator = ', ',
        [switch] $RemoveDuplicates,
        [switch] $RemovePrefix,
        [switch] $AddSeparator)
    if ($RemovePrefix) { $Emails = $Emails -replace 'smtp:', '' -replace 'sip:', '' -replace 'spo:', '' }
    if ($RemoveDuplicates) { $Emails = $Emails | Sort-Object -Unique }
    if ($AddSeparator) { $Emails = $Emails -join $Separator }
    return $Emails
}
function Convert-ExchangeItems {
    [cmdletbinding()]
    param($Count,
        [string] $Default = 'N/A')
    if ($null -eq $Count) { return $Default } else { return $Count }
}
function Convert-ExchangeSize {
    [cmdletbinding()]
    param([validateset("Bytes", "KB", "MB", "GB", "TB")][string]$To = 'MB',
        [string]$Size,
        [int]$Precision = 4,
        [switch]$Display,
        [string]$Default = 'N/A')
    if ([string]::IsNullOrWhiteSpace($Size)) { return $Default }
    $Pattern = [Regex]::new('(?<=\()([0-9]*[,.].*[0-9])')
    $Value = ($Size | Select-String $Pattern -AllMatches).Matches.Value
    if ($null -ne $Value) { $Value = $Value.Replace(',', '').Replace('.', '') }
    switch ($To) {
        "Bytes" { return $value }
        "KB" { $Value = $Value / 1KB }
        "MB" { $Value = $Value / 1MB }
        "GB" { $Value = $Value / 1GB }
        "TB" { $Value = $Value / 1TB }
    }
    if ($Display) { return "$([Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)) $To" } else { return [Math]::Round($value, $Precision, [MidPointRounding]::AwayFromZero) }
}
function Convert-Office365License {
    <#
    .SYNOPSIS
    This function helps converting Office 365 licenses from/to their SKU equivalent

    .DESCRIPTION
    This function helps converting Office 365 licenses from/to their SKU equivalent

    .PARAMETER License
    License SKU or License Name. Takes multiple values.

    .PARAMETER ToSku
    Converts license name to SKU

    .PARAMETER Separator

    .PARAMETER ReturnArray

    .EXAMPLE
    Convert-Office365License -License 'VISIOCLIENT','PROJECTONLINE_PLAN_1','test','tenant:VISIOCLIENT'

    .EXAMPLE
    Convert-Office365License -License "Office 365 (Plan A3) for Faculty","Office 365 (Enterprise Preview)", 'test' -ToSku
    #>
    [CmdletBinding()]
    param([string[]] $License,
        [alias('SKU')][switch] $ToSku,
        [string] $Separator = ', ',
        [switch] $ReturnArray)
    $O365SKU = @{"O365_BUSINESS_ESSENTIALS"  = "Office 365 Business Essentials"
        "O365_BUSINESS_PREMIUM"              = "Office 365 Business Premium"
        "DESKLESSPACK"                       = "Office 365 (Plan F1)"
        "DESKLESSWOFFPACK"                   = "Office 365 (Plan F2)"
        "LITEPACK"                           = "Office 365 (Plan P1)"
        "EXCHANGESTANDARD"                   = "Office 365 Exchange Online Only"
        "STANDARDPACK"                       = "Office 365 Enterprise E1"
        "STANDARDWOFFPACK"                   = "Office 365 (Plan E2)"
        "ENTERPRISEPACK"                     = "Office 365 Enterprise E3"
        "ENTERPRISEPACKLRG"                  = "Office 365 Enterprise E3"
        "ENTERPRISEWITHSCAL"                 = "Office 365 Enterprise E4"
        "STANDARDPACK_STUDENT"               = "Office 365 (Plan A1) for Students"
        "STANDARDWOFFPACKPACK_STUDENT"       = "Office 365 (Plan A2) for Students"
        "ENTERPRISEPACK_STUDENT"             = "Office 365 (Plan A3) for Students"
        "ENTERPRISEWITHSCAL_STUDENT"         = "Office 365 (Plan A4) for Students"
        "STANDARDPACK_FACULTY"               = "Office 365 (Plan A1) for Faculty"
        "STANDARDWOFFPACKPACK_FACULTY"       = "Office 365 (Plan A2) for Faculty"
        "ENTERPRISEPACK_FACULTY"             = "Office 365 (Plan A3) for Faculty"
        "ENTERPRISEWITHSCAL_FACULTY"         = "Office 365 (Plan A4) for Faculty"
        "ENTERPRISEPACK_B_PILOT"             = "Office 365 (Enterprise Preview)"
        "STANDARD_B_PILOT"                   = "Office 365 (Small Business Preview)"
        "VISIOCLIENT"                        = "Visio Online Plan 2"
        "POWER_BI_ADDON"                     = "Office 365 Power BI Addon"
        "POWER_BI_INDIVIDUAL_USE"            = "Power BI Individual User"
        "POWER_BI_STANDALONE"                = "Power BI Stand Alone"
        "POWER_BI_STANDARD"                  = "Power BI (free)"
        "PROJECTESSENTIALS"                  = "Project Online Essentials"
        "PROJECTCLIENT"                      = "Project Professional"
        "PROJECTONLINE_PLAN_1"               = "Project Online"
        "PROJECTONLINE_PLAN_2"               = "Project Online and PRO"
        "ProjectPremium"                     = "Project Online Premium"
        "ECAL_SERVICES"                      = "ECAL"
        "EMS"                                = "Enterprise Mobility + Security E3"
        "RIGHTSMANAGEMENT_ADHOC"             = "Windows Azure Rights Management"
        "MCOMEETADV"                         = "Audio Conferencing"
        "SHAREPOINTSTORAGE"                  = "SharePoint Storage"
        "PLANNERSTANDALONE"                  = "Planner Standalone"
        "CRMIUR"                             = "CMRIUR"
        "BI_AZURE_P1"                        = "Power BI Reporting and Analytics"
        "INTUNE_A"                           = "Windows Intune Plan A"
        "PROJECTWORKMANAGEMENT"              = "Office 365 Planner Preview"
        "ATP_ENTERPRISE"                     = "Exchange Online Advanced Threat Protection"
        "EQUIVIO_ANALYTICS"                  = "Office 365 Advanced eDiscovery"
        "AAD_BASIC"                          = "Azure Active Directory Basic"
        "RMS_S_ENTERPRISE"                   = "Azure Active Directory Rights Management"
        "AAD_PREMIUM"                        = "Azure Active Directory Premium"
        "MFA_PREMIUM"                        = "Azure Multi-Factor Authentication"
        "STANDARDPACK_GOV"                   = "Microsoft Office 365 (Plan G1) for Government"
        "STANDARDWOFFPACK_GOV"               = "Microsoft Office 365 (Plan G2) for Government"
        "ENTERPRISEPACK_GOV"                 = "Microsoft Office 365 (Plan G3) for Government"
        "ENTERPRISEWITHSCAL_GOV"             = "Microsoft Office 365 (Plan G4) for Government"
        "DESKLESSPACK_GOV"                   = "Microsoft Office 365 (Plan F1) for Government"
        "ESKLESSWOFFPACK_GOV"                = "Microsoft Office 365 (Plan F2) for Government"
        "EXCHANGESTANDARD_GOV"               = "Microsoft Office 365 Exchange Online (Plan 1) only for Government"
        "EXCHANGEENTERPRISE_GOV"             = "Microsoft Office 365 Exchange Online (Plan 2) only for Government"
        "SHAREPOINTDESKLESS_GOV"             = "SharePoint Online Kiosk"
        "EXCHANGE_S_DESKLESS_GOV"            = "Exchange Kiosk"
        "RMS_S_ENTERPRISE_GOV"               = "Windows Azure Active Directory Rights Management"
        "OFFICESUBSCRIPTION_GOV"             = "Office ProPlus"
        "MCOSTANDARD_GOV"                    = "Lync Plan 2G"
        "SHAREPOINTWAC_GOV"                  = "Office Online for Government"
        "SHAREPOINTENTERPRISE_GOV"           = "SharePoint Plan 2G"
        "EXCHANGE_S_ENTERPRISE_GOV"          = "Exchange Plan 2G"
        "EXCHANGE_S_ARCHIVE_ADDON_GOV"       = "Exchange Online Archiving"
        "EXCHANGE_S_DESKLESS"                = "Exchange Online Kiosk"
        "SHAREPOINTDESKLESS"                 = "SharePoint Online Kiosk"
        "SHAREPOINTWAC"                      = "Office Online"
        "YAMMER_ENTERPRISE"                  = "Yammer for the Starship Enterprise"
        "EXCHANGE_L_STANDARD"                = "Exchange Online (Plan 1)"
        "MCOLITE"                            = "Lync Online (Plan 1)"
        "SHAREPOINTLITE"                     = "SharePoint Online (Plan 1)"
        "OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ" = "Office ProPlus"
        "EXCHANGE_S_STANDARD_MIDMARKET"      = "Exchange Online (Plan 1)"
        "MCOSTANDARD_MIDMARKET"              = "Lync Online (Plan 1)"
        "SHAREPOINTENTERPRISE_MIDMARKET"     = "SharePoint Online (Plan 1)"
        "OFFICESUBSCRIPTION"                 = "Office ProPlus"
        "YAMMER_MIDSIZE"                     = "Yammer"
        "DYN365_ENTERPRISE_PLAN1"            = "Dynamics 365 Customer Engagement Plan Enterprise Edition"
        "ENTERPRISEPREMIUM_NOPSTNCONF"       = "Enterprise E5 (without Audio Conferencing)"
        "ENTERPRISEPREMIUM"                  = "Enterprise E5 (with Audio Conferencing)"
        "MCOSTANDARD"                        = "Skype for Business Online Standalone Plan 2"
        "PROJECT_MADEIRA_PREVIEW_IW_SKU"     = "Dynamics 365 for Financials for IWs"
        "STANDARDWOFFPACK_IW_STUDENT"        = "Office 365 Education for Students"
        "STANDARDWOFFPACK_IW_FACULTY"        = "Office 365 Education for Faculty"
        "EOP_ENTERPRISE_FACULTY"             = "Exchange Online Protection for Faculty"
        "EXCHANGESTANDARD_STUDENT"           = "Exchange Online (Plan 1) for Students"
        "OFFICESUBSCRIPTION_STUDENT"         = "Office ProPlus Student Benefit"
        "STANDARDWOFFPACK_FACULTY"           = "Office 365 Education E1 for Faculty"
        "STANDARDWOFFPACK_STUDENT"           = "Microsoft Office 365 (Plan A2) for Students"
        "DYN365_FINANCIALS_BUSINESS_SKU"     = "Dynamics 365 for Financials Business Edition"
        "DYN365_FINANCIALS_TEAM_MEMBERS_SKU" = "Dynamics 365 for Team Members Business Edition"
        "FLOW_FREE"                          = "Microsoft Flow Free"
        "POWER_BI_PRO"                       = "Power BI Pro"
        "O365_BUSINESS"                      = "Office 365 Business"
        "DYN365_ENTERPRISE_SALES"            = "Dynamics Office 365 Enterprise Sales"
        "RIGHTSMANAGEMENT"                   = "Rights Management"
        "PROJECTPROFESSIONAL"                = "Project Online Professional"
        "VISIOONLINE_PLAN1"                  = "Visio Online Plan 1"
        "EXCHANGEENTERPRISE"                 = "Exchange Online Plan 2"
        "DYN365_ENTERPRISE_P1_IW"            = "Dynamics 365 P1 Trial for Information Workers"
        "DYN365_ENTERPRISE_TEAM_MEMBERS"     = "Dynamics 365 For Team Members Enterprise Edition"
        "CRMSTANDARD"                        = "Microsoft Dynamics CRM Online Professional"
        "EXCHANGEARCHIVE_ADDON"              = "Exchange Online Archiving For Exchange Online"
        "EXCHANGEDESKLESS"                   = "Exchange Online Kiosk"
        "SPZA_IW"                            = "App Connect"
        "WINDOWS_STORE"                      = "Windows Store for Business"
        "MCOEV"                              = "Phone System"
        "VIDEO_INTEROP"                      = "Polycom Skype Meeting Video Interop for Skype for Business"
        "SPE_E5"                             = "Microsoft 365 E5"
        "SPE_E3"                             = "Microsoft 365 E3"
        "ATA"                                = "Advanced Threat Analytics"
        "MCOPSTN2"                           = "Domestic and International Calling Plan"
        "FLOW_P1"                            = "Microsoft Flow Plan 1"
        "FLOW_P2"                            = "Microsoft Flow Plan 2"
        "POWERAPPS_VIRAL"                    = "Microsoft PowerApps Plan 2"
        "MIDSIZEPACK"                        = "Office 365 Midsize Business"
        "AAD_PREMIUM_P2"                     = "Azure Active Directory Premium P2"
        "RIGHTSMANAGEMENT_STANDARD_FACULTY"  = "Information Rights Management for Faculty"
        "PROJECTONLINE_PLAN_1_FACULTY"       = "Project Online for Faculty Plan 1"
        "PROJECTONLINE_PLAN_2_FACULTY"       = "Project Online for Faculty Plan 2"
        "PROJECTONLINE_PLAN_1_STUDENT"       = "Project Online for Students Plan 1"
        "PROJECTONLINE_PLAN_2_STUDENT"       = "Project Online for Students Plan 2"
        "TEAMS1"                             = "Microsoft Teams"
        "RIGHTSMANAGEMENT_STANDARD_STUDENT"  = "Information Rights Management for Students"
        "EXCHANGEENTERPRISE_FACULTY"         = "Exchange Online Plan 2 for Faculty"
        "SHAREPOINTSTANDARD"                 = "SharePoint Online Plan 1"
        "CRMPLAN2"                           = "Dynamics CRM Online Plan 2"
        "CRMSTORAGE"                         = "Microsoft Dynamics CRM Online Additional Storage"
        "EMSPREMIUM"                         = "Enterprise Mobility + Security E5"
        "POWER_BI_INDIVIDUAL_USER"           = "Power BI for Office 365 Individual"
        "DESKLESSPACK_YAMMER"                = "Office 365 Enterprise F1 with Yammer"
        "MICROSOFT_BUSINESS_CENTER"          = "Microsoft Business Center"
        "STREAM"                             = "Microsoft Stream"
        "OFFICESUBSCRIPTION_FACULTY"         = "Office 365 ProPlus for Faculty"
        "WACSHAREPOINTSTD"                   = "Office Online STD"
        "POWERAPPS_INDIVIDUAL_USER"          = "Microsoft PowerApps and Logic flows"
        "IT_ACADEMY_AD"                      = "Microsoft Imagine Academy"
        "SHAREPOINTENTERPRISE"               = "SharePoint Online (Plan 2)"
        "MCOPSTN1"                           = "Skype for Business PSTN Domestic Calling"
        "MEE_FACULTY"                        = "Minecraft Education Edition Faculty"
        "LITEPACK_P2"                        = "Office 365 Small Business Premium"
        "EXCHANGE_S_ENTERPRISE"              = "Exchange Online Plan 2 S"
        "INTUNE_A_VL"                        = "Intune (Volume License)"
        "ENTERPRISEPACKWITHOUTPROPLUS"       = "Office 365 Enterprise E3 without ProPlus Add-on"
        "ATP_ENTERPRISE_FACULTY"             = "Exchange Online Advanced Threat Protection"
        "EXCHANGE_S_STANDARD"                = "Exchange Online (Plan 2)"
        "MEE_STUDENT"                        = "Minecraft Education Edition Student"
        "EQUIVIO_ANALYTICS_FACULTY"          = "Office 365 Advanced Compliance for faculty"
        "MFA_STANDALONE"                     = "Microsoft Azure Multi-Factor Authentication"
        "MS_TEAMS_IW"                        = "Microsoft Teams"
    }
    if (-not $ToSku) {
        $ConvertedLicenses = foreach ($L in $License) {
            $L = $L -replace '.*(:)'
            $Conversion = $O365SKU[$L]
            if ($null -eq $Conversion) { $L } else { $Conversion }
        }
    } else {
        $ConvertedLicenses = foreach ($L in $License) {
            $Conversion = foreach ($_ in $O365SKU.GetEnumerator()) {
                if ($_.Value -eq $L) {
                    $_
                    continue
                }
            }
            if ($null -eq $Conversion) { $L } else { $Conversion.Name }
        }
    }
    if ($ReturnArray) { return $ConvertedLicenses } else { return $ConvertedLicenses -join $Separator }
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
function Format-AddSpaceToSentence {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Text
    Parameter description

    .EXAMPLE


    $test = @(
        'OnceUponATime',
        'OnceUponATime1',
        'Money@Risk',
        'OnceUponATime123',
        'AHappyMan2014'
        'OnceUponATime_123'
    )

    Format-AddSpaceToSentence -Text $Test

    $Test | Format-AddSpaceToSentence -ToLowerCase

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)][string[]] $Text,
        [switch] $ToLowerCase)
    Begin { }
    Process {
        $Value = foreach ($T in $Text) { ($T -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').trim() }
        if ($ToLowerCase) { $Value.ToLower() } else { $Value }
    }
    End { }
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
function Get-Types {
    [CmdletBinding()]
    param ([Object] $Types)
    $TypesRequired = foreach ($Type in $Types) { $Type.GetEnumValues() }
    return $TypesRequired
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
function Test-AvailabilityCommands {
    param ([string[]] $Commands)
    $CommandsStatus = foreach ($Command in $Commands) {
        $Exists = Search-Command -Command $Command
        if ($Exists) { Write-Verbose "Test-AvailabilityCommands - Command $Command is available." } else { Write-Verbose "Test-AvailabilityCommands - Command $Command is not available." }
        $Exists
    }
    return $CommandsStatus
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
function Search-Command {
    [cmdletbinding()]
    param ([string] $CommandName)
    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}
Add-Type -TypeDefinition @"
    using System;

    namespace PSWinDocumentation
    {
        [Flags]
        public enum O365 {
            AzureADGroupMembers,
            AzureADUsers,
            AzureADGuests,
            AzureADUsersMFA,
            AzureADUsersStatisticsByCity,
            AzureADUsersStatisticsByCountry,
            AzureADUsersStatisticsByCountryCity,
            AzureLicensing,
            AzureRoles,
            AzureRolesActiveOnly,
            AzureRolesMembers,
            AzureSubscription,
            AzureTenantDomains,

            ExchangeAcceptedDomains,
            ExchangeConnectorsInbound,
            ExchangeConnectorsOutbound,
            ExchangeDistributionGroups,
            ExchangeDistributionGroupsMembers,
            ExchangeMailboxes,
            ExchangeMailboxesStatistics,
            ExchangeMailboxesStatisticsArchive,
            ExchangeMailboxesPermissions,
            ExchangeMailboxesPermissionsIncludingInherited,
            ExchangeMailboxesInboxRulesForwarding,
            ExchangeUnifiedGroups,
            ExchangeUnifiedGroupsMembers,
            ExchangeTransportConfig,

            TeamsSettings,
            TeamsSettingsBroadcasting,
            TeamsSettingsCalling,
            TeamsSettingsChannels,
            TeamsSettingsEducationAppPolicy,
            TeamsSettingsFileSharing,
            TeamsSettingsGuests,
            TeamsSettingsMeetings,
            TeamsSettingsMeetingsTechnical,
            TeamsSettingsUpgrade,
            TeamsSettingsUsers,


            UAzureADContacts,
            UAzureADGroups,
            UAzureADUsers,
            UAzureADUsersDeleted,
            UAzureLicensing,
            UAzureRoles,
            UAzureSubscription,
            UAzureTenantDomains,
            UExchangeContacts,
            UExchangeContactsMail,
            UExchangeEquipmentCalendarProcessing,
            UExchangeGroupsDistribution,
            UExchangeGroupsDistributionDynamic,
            UExchangeGroupsDistributionMembers,
            UExchangeMailBoxes,
            UExchangeMailboxesEquipment,
            UExchangeMailboxesInboxRules,
            UExchangeMailboxesJunk,
            UExchangeMailboxesPermissions,
            UExchangeMailboxesRooms,
            UExchangeMailUsers,
            UExchangeRecipients,
            UExchangeRecipientsPermissions,
            UExchangeRoomsCalendarProcessing,
            UExchangeUnifiedGroups,
            UExchangeUsers,

            UTeamsConfiguration,
            UTeamsVideoInteropService
        }
    }
"@
function Get-WinAzureGuests {
    [CmdletBinding()]
    param([Array] $MsolUsers,
        [string] $Prefix,
        [string] $Splitter = ', ',
        [switch] $Formatted,
        [System.Collections.IDictionary] $Users)
    if (-not $MsolUsers) { $MsolUsers = & "Get-$($prefix)MsolUser" }
    $AzureUsers = foreach ($User in $MsolUsers) {
        if ($User.UserType -eq 'Member') { continue }
        $MFAOptions = @{ }
        $MFAOptions.AuthAvailable = @(foreach ($Auth in $User.StrongAuthenticationMethods) { if ($Auth.IsDefault) { $MFAOptions.AuthDefault = $Auth.MethodType } else { $Auth.MethodType } })
        if ($Formatted) {
            [pscustomobject] @{'UserPrincipalName'   = $User.UserPrincipalName
                'Display Name'                       = $User.DisplayName
                'First Name'                         = $User.FirstName
                'Last Name'                          = $User.LastName
                'Licenses'                           = Convert-Office365License -License $User.Licenses.AccountSkuID -Separator $Splitter
                'Title'                              = $User.Title
                'Emails'                             = Convert-ExchangeEmail -Emails $User.ProxyAddresses -Separator $Splitter -RemoveDuplicates -RemovePrefix -AddSeparator
                'Last Dir Sync Time'                 = $User.LastDirSyncTime
                'Last Password Change'               = $User.LastPasswordChangeTimestamp
                'Password Never Expires'             = $User.PasswordNeverExpires
                'Mobile Phone'                       = $User.MobilePhone
                'Phone Number'                       = $User.PhoneNumber
                'Office'                             = $User.Office
                'Department'                         = $User.Department
                'Portal Settings'                    = $User.PortalSettings
                'Preferred Data Location'            = $User.PreferredDataLocation
                'Preferred Language'                 = $User.PreferredLanguage
                'Release Track'                      = $User.ReleaseTrack
                'Service Information'                = $User.ServiceInformation
                'Street Address'                     = $User.StreetAddress
                'Postal Code'                        = $User.PostalCode
                'State'                              = $User.State
                'City'                               = $User.City
                'Country'                            = $User.Country
                'BlockCredential'                    = $User.BlockCredential
                'CloudExchangeRecipientDisplayType'  = $User.CloudExchangeRecipientDisplayType
                'Usage Location'                     = $User.UsageLocation
                'Method Default'                     = $MFAOptions.AuthDefault
                'Method Alternative'                 = ($MFAOptions.AuthAvailable | Sort-Object) -join $Splitter
                'App Authentication Type'            = $User.StrongAuthenticationPhoneAppDetails.AuthenticationType
                'App Device Name'                    = $User.StrongAuthenticationPhoneAppDetails.DeviceName
                'App Device Tag'                     = $User.StrongAuthenticationPhoneAppDetails.DeviceTag
                'App Device Token'                   = $User.StrongAuthenticationPhoneAppDetails.DeviceToken
                'App Notification Type'              = $User.StrongAuthenticationPhoneAppDetails.NotificationType
                'App Oath Secret Key'                = $User.StrongAuthenticationPhoneAppDetails.OathSecretKey
                'App Oath Token Time Drift'          = $User.StrongAuthenticationPhoneAppDetails.OathTokenTimeDrift
                'App Version'                        = $User.StrongAuthenticationPhoneAppDetails.PhoneAppVersion
                'User Details Email'                 = $User.StrongAuthenticationUserDetails.Email
                'User Details Phone'                 = $User.StrongAuthenticationUserDetails.PhoneNumber
                'User Details Phone Alt'             = $User.StrongAuthenticationUserDetails.AlternativePhoneNumber
                'User Details Pin'                   = $User.StrongAuthenticationUserDetails.Pin
                'User Details OldPin'                = $User.StrongAuthenticationUserDetails.OldPin
                'Strong Password Required'           = $User.StrongPasswordRequired
                'Requirement Relying Party'          = $User.StrongAuthenticationRequirements.RelyingParty
                'Requirement Not Issued Before'      = $User.StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
                'Requirement State'                  = $User.StrongAuthenticationRequirements.State
                'Strong Authentication Proofup Time' = $User.StrongAuthenticationProofupTime
                'ObjectId'                           = $User.ObjectId.Guid
                'UserType'                           = $User.UserType
            }
        } else {
            [pscustomobject] @{'UserPrincipalName'  = $User.UserPrincipalName
                'Display Name'                      = $User.DisplayName
                FirstName                           = $User.FirstName
                LastName                            = $User.LastName
                Licenses                            = $User.Licenses
                Title                               = $User.Title
                LastDirSyncTime                     = $User.LastDirSyncTime
                LastPasswordChange                  = $User.LastPasswordChangeTimestamp
                PasswordNeverExpires                = $User.PasswordNeverExpires
                MobilePhone                         = $User.MobilePhone
                PhoneNumber                         = $User.PhoneNumber
                'Office'                            = $User.Office
                'Department'                        = $User.Department
                PortalSettings                      = $User.PortalSettings
                PreferredDataLocation               = $User.PreferredDataLocation
                PreferredLanguage                   = $User.PreferredLanguage
                'Emails'                            = $User.ProxyAddresses
                ReleaseTrack                        = $User.ReleaseTrack
                ServiceInformation                  = $User.ServiceInformation
                'StreetAddress'                     = $User.StreetAddress
                'PostalCode'                        = $User.PostalCode
                'State'                             = $User.State
                'City'                              = $User.City
                'Country'                           = $User.Country
                'BlockCredential'                   = $User.BlockCredential
                'CloudExchangeRecipientDisplayType' = $User.CloudExchangeRecipientDisplayType
                'UsageLocation'                     = $User.UsageLocation
                'MethodDefault'                     = $MFAOptions.AuthDefault
                'MethodAlternative'                 = ($MFAOptions.AuthAvailable | Sort-Object)
                'AppAuthentication Type'            = $User.StrongAuthenticationPhoneAppDetails.AuthenticationType
                'AppDeviceName'                     = $User.StrongAuthenticationPhoneAppDetails.DeviceName
                'AppDeviceTag'                      = $User.StrongAuthenticationPhoneAppDetails.DeviceTag
                'AppDeviceToken'                    = $User.StrongAuthenticationPhoneAppDetails.DeviceToken
                'AppNotificationType'               = $User.StrongAuthenticationPhoneAppDetails.NotificationType
                'AppOathSecretKey'                  = $User.StrongAuthenticationPhoneAppDetails.OathSecretKey
                'AppOathTokenTimeDrift'             = $User.StrongAuthenticationPhoneAppDetails.OathTokenTimeDrift
                'AppVersion'                        = $User.StrongAuthenticationPhoneAppDetails.PhoneAppVersion
                'UserDetailsEmail'                  = $User.StrongAuthenticationUserDetails.Email
                'UserDetailsPhone'                  = $User.StrongAuthenticationUserDetails.PhoneNumber
                'UserDetailsPhoneAlt'               = $User.StrongAuthenticationUserDetails.AlternativePhoneNumber
                'UserDetailsPin'                    = $User.StrongAuthenticationUserDetails.Pin
                'UserDetailsOldPin'                 = $User.StrongAuthenticationUserDetails.OldPin
                'StrongPasswordRequired'            = $User.StrongPasswordRequired
                'RequirementRelyingParty'           = $User.StrongAuthenticationRequirements.RelyingParty
                'RequirementNotIssuedBefore'        = $User.StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
                'RequirementState'                  = $User.StrongAuthenticationRequirements.State
                'StrongAuthenticationProofupTime'   = $User.StrongAuthenticationProofupTime
                'ObjectId'                          = $User.ObjectId.Guid
                'UserType'                          = $User.UserType
            }
        }
    }
    foreach ($_ in $AzureUsers) { $Users[$_.ObjectId] = $_ }
    return $AzureUsers | Sort-Object 'UserPrincipalName'
}
function Get-WinAzureLicensing {
    [CmdletBinding()]
    param([Array] $UAzureLicensing,
        [switch] $Formatted)
    if ($null -eq $UAzureLicensing) { $UAzureLicensing = Get-MsolAccountSku }
    $Licenses = foreach ($License in $UAzureLicensing) {
        $LicensesTotal = $License.ActiveUnits + $License.WarningUnits
        $LicensesUsed = $License.ConsumedUnits
        $LicensesLeft = $LicensesTotal - $LicensesUsed
        $LicenseName = Convert-Office365License -License $License.SkuPartNumber
        if ($null -eq $LicenseName) { $LicenseName = $License.SkuPartNumber }
        if ($Formatted) {
            [PSCustomObject] @{Name  = $LicenseName
                'Licenses Total'     = $LicensesTotal
                'Licenses Used'      = $LicensesUsed
                'Licenses Left'      = $LicensesLeft
                'Licenses Active'    = $License.ActiveUnits
                'Licenses Trial'     = $License.WarningUnits
                'Licenses LockedOut' = $License.LockedOutUnits
                'Licenses Suspended' = $License.SuspendedUnits
                'Percent Used'       = if ($LicensesTotal -eq 0) { '100%' } else { ($LicensesUsed / $LicensesTotal).ToString("P") }
                'Percent Left'       = if ($LicensesTotal -eq 0) { '0%' } else { ($LicensesLeft / $LicensesTotal).ToString("P") }
                SKU                  = $License.SkuPartNumber
                SKUAccount           = $License.AccountSkuId
                SKUID                = $License.SkuId
            }
        } else {
            [PSCustomObject] @{Name = $LicenseName
                'LicensesTotal'     = $LicensesTotal
                'LicensesUsed'      = $LicensesUsed
                'LicensesLeft'      = $LicensesLeft
                'LicensesActive'    = $License.ActiveUnits
                'LicensesTrial'     = $License.WarningUnits
                'LicensesLockedOut' = $License.LockedOutUnits
                'LicensesSuspended' = $License.SuspendedUnits
                'PercentUsed'       = if ($LicensesTotal -eq 0) { '100%' } else { ($LicensesUsed / $LicensesTotal).ToString("P") }
                'PercentLeft'       = if ($LicensesTotal -eq 0) { '0%' } else { ($LicensesLeft / $LicensesTotal).ToString("P") }
                SKU                 = $License.SkuPartNumber
                SKUAccount          = $License.AccountSkuId
                SKUID               = $License.SkuId
            }
        }
    }
    return $Licenses | Sort-Object Name
}
function Get-WinAzureRoles {
    [CmdletBinding()]
    param([Array] $MsolRoles,
        [Array] $AzureRolesMembers,
        [string] $Prefix,
        [switch] $Formatted)
    if (-not $MsolRoles) { $MsolRoles = & "Get-$($prefix)MsolRole" | Sort-Object -Property Name }
    $Roles = foreach ($_ in $MsolRoles) {
        [Array] $Members = foreach ($Member in $AzureRolesMembers) {
            if ($Member.Role -eq $_.Name -and $Member.UserType -eq 'Member') {
                $Member
                Continue
            }
        }
        [Array] $MembersGuests = foreach ($Member in $AzureRolesMembers) {
            if ($Member.Role -eq $_.Name -and $Member.UserType -eq 'Guest') {
                $Member
                Continue
            }
        }
        if ($Formatted) {
            [PSCustomObject] @{'Name' = $_.Name
                'Member Count'        = $Members.Count
                'Guests Count'        = $MembersGuests.Count
                'Description'         = $_.Description
            }
        } else {
            [PSCustomObject] @{Name = $_.Name
                MemberCount         = $Members.Count
                GuestsCount         = $MembersGuests.Count
                Description         = $_.Description
            }
        }
    }
    $Roles
}
function Get-WinAzureRolesActiveOnly {
    [CmdletBinding()]
    param([Array] $AzureRoles,
        [switch] $Formatted)
    $Roles = foreach ($_ in $AzureRoles) {
        if ($Formatted) { if ($_.'Member Count' -eq 0 -and $_.'Guests Count' -eq 0) { continue } } else { if ($_.'MemberCount' -eq 0 -and $_.'GuestsCount' -eq 0) { continue } }
        $_
    }
    $Roles
}
function Get-WinAzureRolesMembers {
    [CmdletBinding()]
    param([Array] $MsolRoles,
        [string] $Prefix,
        [switch] $Formatted,
        [System.Collections.IDictionary] $Users)
    if (-not $MsolRoles) { $MsolRoles = & "Get-$($prefix)MsolRole" | Sort-Object -Property Name }
    $Roles = foreach ($_ in $MsolRoles) {
        $MsolRolesMembers = & "Get-$($prefix)MsolRoleMember" -RoleObjectId $_.ObjectID.Guid
        foreach ($Member in $MsolRolesMembers) {
            $U = $Users[$Member.ObjectID.Guid]
            if ($null -eq $U) { } else {
                Add-Member -InputObject $U -MemberType NoteProperty -Name 'Role' -Value $_.Name
                $U
            }
        }
    }
    $Roles
}
function Get-WinAzureSubscription {
    [CmdletBinding()]
    param([Array] $UAzureSubscription,
        [switch] $Formatted)
    if ($null -eq $UAzureSubscription) { $UAzureSubscription = Get-MsolSubscription }
    $Licenses = foreach ($Subscription in $UAzureSubscription) {
        foreach ($Plan in $Subscription.ServiceStatus) {
            if ($Formatted) {
                [PSCustomObject] @{'Licenses Name' = Convert-Office365License -License $Subscription.SkuPartNumber
                    'Licenses SKU'                 = $Subscription.SkuPartNumber
                    'Service Plan Name'            = Convert-Office365License -License $Plan.ServicePlan.ServiceName
                    'Service Plan SKU'             = $Plan.ServicePlan.ServiceName
                    'Service Plan ID'              = $Plan.ServicePlan.ServicePlanId
                    'Service Plan Type'            = $Plan.ServicePlan.ServiceType
                    'Service Plan Class'           = $Plan.ServicePlan.TargetClass
                    'Service Plan Status'          = $Plan.ProvisioningStatus
                    'Licenses Total'               = $Subscription.TotalLicenses
                    'Licenses Status'              = $Subscription.Status
                    'Licenses SKUID'               = $Subscription.SkuId
                    'Licenses Are Trial'           = $Subscription.IsTrial
                    'Licenses Created'             = $Subscription.DateCreated
                    'Next Lifecycle Date'          = $Subscription.NextLifecycleDate
                    'ObjectID'                     = $Subscription.ObjectId
                    'Ocp SubscriptionID'           = $Subscription.OcpSubscriptionId
                }
            } else {
                [PSCustomObject] @{'LicensesName' = Convert-Office365License -License $Subscription.SkuPartNumber
                    'LicensesSKU'                 = $Subscription.SkuPartNumber
                    'ServicePlanName'             = Convert-Office365License -License $Plan.ServicePlan.ServiceName
                    'ServicePlanSKU'              = $Plan.ServicePlan.ServiceName
                    'ServicePlanID'               = $Plan.ServicePlan.ServicePlanId
                    'ServicePlanType'             = $Plan.ServicePlan.ServiceType
                    'ServicePlanClass'            = $Plan.ServicePlan.TargetClass
                    'ServicePlanStatus'           = $Plan.ProvisioningStatus
                    'LicensesTotal'               = $Subscription.TotalLicenses
                    'LicensesStatus'              = $Subscription.Status
                    'LicensesSKUID'               = $Subscription.SkuId
                    'LicensesAreTrial'            = $Subscription.IsTrial
                    'LicensesCreated'             = $Subscription.DateCreated
                    'NextLifecycleDate'           = $Subscription.NextLifecycleDate
                    'ObjectID'                    = $Subscription.ObjectId
                    'OcpSubscriptionID'           = $Subscription.OcpSubscriptionId
                }
            }
        }
    }
    return $Licenses | Sort-Object 'Licenses Name'
}
function Get-WinAzureTenantDomains {
    [CmdletBinding()]
    param([Array] $UAzureTenantDomains,
        [switch] $Formatted)
    if ($null -eq $UAzureTenantDomains) { $UAzureTenantDomains = Get-MsolDomain }
    foreach ($Domain in $UAzureTenantDomains) {
        if ($Formatted) {
            [PsCustomObject] @{'Domain Name' = $Domain.Name
                'Default'                    = $Domain.IsDefault
                'Initial'                    = $Domain.IsInitial
                'Status'                     = $Domain.Status
                'Verification Method'        = Format-AddSpaceToSentence -Text $Domain.VerificationMethod
                'Capabilities'               = $Domain.Capabilities
                'Authentication'             = $Domain.Authentication
            }
        } else {
            [PsCustomObject] @{'DomainName' = $Domain.Name
                'Default'                   = $Domain.IsDefault
                'Initial'                   = $Domain.IsInitial
                'Status'                    = $Domain.Status
                'VerificationMethod'        = $Domain.VerificationMethod
                'Capabilities'              = $Domain.Capabilities
                'Authentication'            = $Domain.Authentication
            }
        }
    }
}
function Get-WinAzureUsers {
    [CmdletBinding()]
    param([Array] $MsolUsers,
        [string] $Prefix,
        [string] $Splitter = ', ',
        [switch] $Formatted,
        [System.Collections.IDictionary] $Users)
    if (-not $MsolUsers) { $MsolUsers = & "Get-$($prefix)MsolUser" }
    $AzureUsers = foreach ($User in $MsolUsers) {
        if ($User.UserType -eq 'Guest') { continue }
        $MFAOptions = @{ }
        $MFAOptions.AuthAvailable = @(foreach ($Auth in $User.StrongAuthenticationMethods) { if ($Auth.IsDefault) { $MFAOptions.AuthDefault = $Auth.MethodType } else { $Auth.MethodType } })
        if ($Formatted) {
            [pscustomobject] @{'UserPrincipalName'   = $User.UserPrincipalName
                'Display Name'                       = $User.DisplayName
                'First Name'                         = $User.FirstName
                'Last Name'                          = $User.LastName
                'Licenses'                           = Convert-Office365License -License $User.Licenses.AccountSkuID -Separator $Splitter
                'Title'                              = $User.Title
                'Emails'                             = Convert-ExchangeEmail -Emails $User.ProxyAddresses -Separator $Splitter -RemoveDuplicates -RemovePrefix -AddSeparator
                'Last Dir Sync Time'                 = $User.LastDirSyncTime
                'Last Password Change'               = $User.LastPasswordChangeTimestamp
                'Password Never Expires'             = $User.PasswordNeverExpires
                'Mobile Phone'                       = $User.MobilePhone
                'Phone Number'                       = $User.PhoneNumber
                'Office'                             = $User.Office
                'Department'                         = $User.Department
                'Portal Settings'                    = $User.PortalSettings
                'Preferred Data Location'            = $User.PreferredDataLocation
                'Preferred Language'                 = $User.PreferredLanguage
                'Release Track'                      = $User.ReleaseTrack
                'Service Information'                = $User.ServiceInformation
                'Street Address'                     = $User.StreetAddress
                'Postal Code'                        = $User.PostalCode
                'State'                              = $User.State
                'City'                               = $User.City
                'Country'                            = $User.Country
                'BlockCredential'                    = $User.BlockCredential
                'CloudExchangeRecipientDisplayType'  = $User.CloudExchangeRecipientDisplayType
                'Usage Location'                     = $User.UsageLocation
                'Method Default'                     = $MFAOptions.AuthDefault
                'Method Alternative'                 = ($MFAOptions.AuthAvailable | Sort-Object) -join $Splitter
                'App Authentication Type'            = $User.StrongAuthenticationPhoneAppDetails.AuthenticationType
                'App Device Name'                    = $User.StrongAuthenticationPhoneAppDetails.DeviceName
                'App Device Tag'                     = $User.StrongAuthenticationPhoneAppDetails.DeviceTag
                'App Device Token'                   = $User.StrongAuthenticationPhoneAppDetails.DeviceToken
                'App Notification Type'              = $User.StrongAuthenticationPhoneAppDetails.NotificationType
                'App Oath Secret Key'                = $User.StrongAuthenticationPhoneAppDetails.OathSecretKey
                'App Oath Token Time Drift'          = $User.StrongAuthenticationPhoneAppDetails.OathTokenTimeDrift
                'App Version'                        = $User.StrongAuthenticationPhoneAppDetails.PhoneAppVersion
                'User Details Email'                 = $User.StrongAuthenticationUserDetails.Email
                'User Details Phone'                 = $User.StrongAuthenticationUserDetails.PhoneNumber
                'User Details Phone Alt'             = $User.StrongAuthenticationUserDetails.AlternativePhoneNumber
                'User Details Pin'                   = $User.StrongAuthenticationUserDetails.Pin
                'User Details OldPin'                = $User.StrongAuthenticationUserDetails.OldPin
                'Strong Password Required'           = $User.StrongPasswordRequired
                'Requirement Relying Party'          = $User.StrongAuthenticationRequirements.RelyingParty
                'Requirement Not Issued Before'      = $User.StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
                'Requirement State'                  = $User.StrongAuthenticationRequirements.State
                'Strong Authentication Proofup Time' = $User.StrongAuthenticationProofupTime
                'ObjectId'                           = $User.ObjectId.Guid
                'UserType'                           = $User.UserType
            }
        } else {
            [pscustomobject] @{'UserPrincipalName'  = $User.UserPrincipalName
                'Display Name'                      = $User.DisplayName
                FirstName                           = $User.FirstName
                LastName                            = $User.LastName
                Licenses                            = $User.Licenses
                Title                               = $User.Title
                LastDirSyncTime                     = $User.LastDirSyncTime
                LastPasswordChange                  = $User.LastPasswordChangeTimestamp
                PasswordNeverExpires                = $User.PasswordNeverExpires
                MobilePhone                         = $User.MobilePhone
                PhoneNumber                         = $User.PhoneNumber
                'Office'                            = $User.Office
                'Department'                        = $User.Department
                PortalSettings                      = $User.PortalSettings
                PreferredDataLocation               = $User.PreferredDataLocation
                PreferredLanguage                   = $User.PreferredLanguage
                'Emails'                            = $User.ProxyAddresses
                ReleaseTrack                        = $User.ReleaseTrack
                ServiceInformation                  = $User.ServiceInformation
                'StreetAddress'                     = $User.StreetAddress
                'PostalCode'                        = $User.PostalCode
                'State'                             = $User.State
                'City'                              = $User.City
                'Country'                           = $User.Country
                'BlockCredential'                   = $User.BlockCredential
                'CloudExchangeRecipientDisplayType' = $User.CloudExchangeRecipientDisplayType
                'UsageLocation'                     = $User.UsageLocation
                'MethodDefault'                     = $MFAOptions.AuthDefault
                'MethodAlternative'                 = ($MFAOptions.AuthAvailable | Sort-Object)
                'AppAuthentication Type'            = $User.StrongAuthenticationPhoneAppDetails.AuthenticationType
                'AppDeviceName'                     = $User.StrongAuthenticationPhoneAppDetails.DeviceName
                'AppDeviceTag'                      = $User.StrongAuthenticationPhoneAppDetails.DeviceTag
                'AppDeviceToken'                    = $User.StrongAuthenticationPhoneAppDetails.DeviceToken
                'AppNotificationType'               = $User.StrongAuthenticationPhoneAppDetails.NotificationType
                'AppOathSecretKey'                  = $User.StrongAuthenticationPhoneAppDetails.OathSecretKey
                'AppOathTokenTimeDrift'             = $User.StrongAuthenticationPhoneAppDetails.OathTokenTimeDrift
                'AppVersion'                        = $User.StrongAuthenticationPhoneAppDetails.PhoneAppVersion
                'UserDetailsEmail'                  = $User.StrongAuthenticationUserDetails.Email
                'UserDetailsPhone'                  = $User.StrongAuthenticationUserDetails.PhoneNumber
                'UserDetailsPhoneAlt'               = $User.StrongAuthenticationUserDetails.AlternativePhoneNumber
                'UserDetailsPin'                    = $User.StrongAuthenticationUserDetails.Pin
                'UserDetailsOldPin'                 = $User.StrongAuthenticationUserDetails.OldPin
                'StrongPasswordRequired'            = $User.StrongPasswordRequired
                'RequirementRelyingParty'           = $User.StrongAuthenticationRequirements.RelyingParty
                'RequirementNotIssuedBefore'        = $User.StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
                'RequirementState'                  = $User.StrongAuthenticationRequirements.State
                'StrongAuthenticationProofupTime'   = $User.StrongAuthenticationProofupTime
                'ObjectId'                          = $User.ObjectId.Guid
                'UserType'                          = $User.UserType
            }
        }
    }
    foreach ($_ in $AzureUsers) { $Users[$_.ObjectId] = $_ }
    return $AzureUsers | Sort-Object 'UserPrincipalName'
}
function Get-WinExchangeAcceptedDomains {
    [CmdletBinding()]
    param([string] $Prefix,
        [switch] $Formatted)
    $AcceptedDomains = & "Get-$($prefix)AcceptedDomain"
    foreach ($_ in $AcceptedDomains) {
        if ($Formatted) {
            [PSCustomObject]@{'Name'                  = $_.Name
                'Domain Name'                         = $_.DomainName
                'Domain Type'                         = $_.DomainType
                'Default'                             = $_.Default
                'Match SubDomains'                    = $_.MatchSubDomains
                'Catch All Recipient ID'              = $_.CatchAllRecipientID
                'Address Book Enabled'                = $_.AddressBookEnabled
                'Email Only'                          = $_.EmailOnly
                'Externally Managed'                  = $_.ExternallyManaged
                'Authentication Type'                 = $_.AuthenticationType
                'LiveId InstanceType'                 = $_.LiveIdInstanceType
                'Pending Removal'                     = $_.PendingRemoval
                'Pending Completion'                  = $_.PendingCompletion
                'Federated Organization Link'         = $_.FederatedOrganizationLink
                'Mailflow Partner'                    = $_.MailFlowPartner
                'Outbound Only'                       = $_.OutboundOnly
                'Pending Federated Account Namespace' = $_.PendingFederatedAccountNamespace
                'Pending Federated Domain'            = $_.PendingFederatedDomain
                'Is Coexistence Domain'               = $_.IsCoexistenceDomain
                'Perimeter Duplicate Detected'        = $_.PerimeterDuplicateDetected
                'Is Default FederatedDomain'          = $_.IsDefaultFederatedDomain
                'Enable Nego2Authentication'          = $_.EnableNego2Authentication
                'Initial Domain'                      = $_.InitialDomain
                'Admin Display Name'                  = $_.AdminDisplayName
                'When Changed'                        = $_.WhenChanged
                'When Created'                        = $_.WhenCreated
            }
        } else {
            [PSCustomObject]@{Name               = $_.Name
                DomainName                       = $_.DomainName
                DomainType                       = $_.DomainType
                Default                          = $_.Default
                MatchSubDomains                  = $_.MatchSubDomains
                CatchAllRecipientID              = $_.CatchAllRecipientID
                AddressBookEnabled               = $_.AddressBookEnabled
                EmailOnly                        = $_.EmailOnly
                ExternallyManaged                = $_.ExternallyManaged
                AuthenticationType               = $_.AuthenticationType
                LiveIdInstanceType               = $_.LiveIdInstanceType
                PendingRemoval                   = $_.PendingRemoval
                PendingCompletion                = $_.PendingCompletion
                FederatedOrganizationLink        = $_.FederatedOrganizationLink
                MailFlowPartner                  = $_.MailFlowPartner
                OutboundOnly                     = $_.OutboundOnly
                PendingFederatedAccountNamespace = $_.PendingFederatedAccountNamespace
                PendingFederatedDomain           = $_.PendingFederatedDomain
                IsCoexistenceDomain              = $_.IsCoexistenceDomain
                PerimeterDuplicateDetected       = $_.PerimeterDuplicateDetected
                IsDefaultFederatedDomain         = $_.IsDefaultFederatedDomain
                EnableNego2Authentication        = $_.EnableNego2Authentication
                InitialDomain                    = $_.InitialDomain
                AdminDisplayName                 = $_.AdminDisplayName
                WhenChanged                      = $_.WhenChanged
                WhenCreated                      = $_.WhenCreated
            }
        }
    }
}
function Get-WinExchangeConnectorsInbound {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Splitter = ', ',
        [switch] $Formatted)
    $InboundConnector = & "Get-$($prefix)InboundConnector"
    foreach ($_ in $InboundConnector) {
        if ($Formatted) {
            [PSCustomObject]@{'Name'                          = $_.Name
                'Enabled'                                     = $_.Enabled
                'Connector Type'                              = Format-AddSpaceToSentence -Text $_.ConnectorType
                'Sender Domains'                              = $_.SenderDomains
                'Sender IP Addresses'                         = $_.SenderIPAddresses -join $Splitter
                'Treat Messages As Internal'                  = $_.TreatMessagesAsInternal
                'Associated Accepted Domains'                 = $_.AssociatedAcceptedDomains
                'Require Tls'                                 = $_.RequireTls
                'Restrict DomainsToIPAddresses'               = $_.RestrictDomainsToIPAddresses
                'Restrict DomainsToCertificate'               = $_.RestrictDomainsToCertificate
                'Comment'                                     = $_.Comment
                'Cloud Services Mail Enabled'                 = $_.CloudServicesMailEnabled
                'Tls Sender Certificate Name'                 = $_.TlsSenderCertificateName
                'Detect SenderIP By Skipping LastIP'          = $_.DetectSenderIPBySkippingLastIP
                'Detect SenderIP By Skipping These IPs'       = $_.DetectSenderIPBySkippingTheseIPs
                'Detect SenderIP By Skipping These Providers' = $_.DetectSenderIPBySkippingTheseProviders
                'Scan And Drop Recipients'                    = $_.ScanAndDropRecipients
                'Detect SenderIP Recipient List'              = $_.DetectSenderIPRecipientList
                'EF Test Mode'                                = $_.EFTestMode
                'EF Skip Last IP'                             = $_.EFSkipLastIP
                'EF Skip IPs'                                 = $_.EFSkipIPs
                'EF Skip Mail Gateway'                        = $_.EFSkipMailGateway
                'EF Users'                                    = $_.EFUsers
                'Connector Source'                            = $_.ConnectorSource
                'When Changed'                                = $_.WhenChanged
                'When Created'                                = $_.WhenCreated
            }
        } else {
            [PSCustomObject]@{Name                     = $_.Name
                Enabled                                = $_.Enabled
                SenderDomains                          = $_.SenderDomains
                SenderIPAddresses                      = $_.SenderIPAddresses
                AssociatedAcceptedDomains              = $_.AssociatedAcceptedDomains
                RequireTls                             = $_.RequireTls
                RestrictDomainsToIPAddresses           = $_.RestrictDomainsToIPAddresses
                RestrictDomainsToCertificate           = $_.RestrictDomainsToCertificate
                ConnectorType                          = $_.ConnectorType
                Comment                                = $_.Comment
                CloudServicesMailEnabled               = $_.CloudServicesMailEnabled
                TreatMessagesAsInternal                = $_.TreatMessagesAsInternal
                TlsSenderCertificateName               = $_.TlsSenderCertificateName
                DetectSenderIPBySkippingLastIP         = $_.DetectSenderIPBySkippingLastIP
                EFTestMode                             = $_.EFTestMode
                DetectSenderIPBySkippingTheseIPs       = $_.DetectSenderIPBySkippingTheseIPs
                DetectSenderIPBySkippingTheseProviders = $_.DetectSenderIPBySkippingTheseProviders
                ScanAndDropRecipients                  = $_.ScanAndDropRecipients
                DetectSenderIPRecipientList            = $_.DetectSenderIPRecipientList
                EFSkipLastIP                           = $_.EFSkipLastIP
                EFSkipIPs                              = $_.EFSkipIPs
                EFSkipMailGateway                      = $_.EFSkipMailGateway
                EFUsers                                = $_.EFUsers
                ConnectorSource                        = $_.ConnectorSource
                WhenChanged                            = $_.WhenChanged
                WhenCreated                            = $_.WhenCreated
            }
        }
    }
}
function Get-WinExchangeConnectorsOutbound {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Splitter = ', ',
        [switch] $Formatted)
    $OutboundConnector = & "Get-$($prefix)OutboundConnector"
    foreach ($_ in $OutboundConnector) {
        if ($Formatted) {
            [PSCustomObject]@{'Name'                = $_.Name
                'Enabled'                           = $_.Enabled
                'Recipient Domains'                 = $_.RecipientDomains -join $Splitter
                'Smart Hosts'                       = $_.SmartHosts -join $Splitter
                'Use MX Record'                     = $_.UseMXRecord
                'Connector Type'                    = Format-AddSpaceToSentence -Text $_.ConnectorType
                'Comment'                           = $_.Comment
                'Tls Domain'                        = $_.TlsDomain
                'Tls Settings'                      = $_.TlsSettings
                'Is Transport Rule Scoped'          = $_.IsTransportRuleScoped
                'Route AllMessages Via On Premises' = $_.RouteAllMessagesViaOnPremises
                'Cloud Services Mail Enabled'       = $_.CloudServicesMailEnabled
                'All Accepted Domains'              = $_.AllAcceptedDomains
                'TestMode'                          = $_.TestMode
                'Validation Recipients'             = $_.ValidationRecipients -join $Splitter
                'Is Validated'                      = $_.IsValidated
                'Last Validation Timestamp'         = $_.LastValidationTimestamp
                'Connector Source'                  = $_.ConnectorSource
                'When Changed'                      = $_.WhenChanged
                'When Created'                      = $_.WhenCreated
            }
        } else {
            [PSCustomObject]@{Name            = $_.Name
                Enabled                       = $_.Enabled
                RecipientDomains              = $_.RecipientDomains
                SmartHosts                    = $_.SmartHosts
                UseMXRecord                   = $_.UseMXRecord
                ConnectorType                 = $_.ConnectorType
                Comment                       = $_.Comment
                TlsDomain                     = $_.TlsDomain
                TlsSettings                   = $_.TlsSettings
                IsTransportRuleScoped         = $_.IsTransportRuleScoped
                RouteAllMessagesViaOnPremises = $_.RouteAllMessagesViaOnPremises
                CloudServicesMailEnabled      = $_.CloudServicesMailEnabled
                AllAcceptedDomains            = $_.AllAcceptedDomains
                TestMode                      = $_.TestMode
                ValidationRecipients          = $_.ValidationRecipients
                IsValidated                   = $_.IsValidated
                LastValidationTimestamp       = $_.LastValidationTimestamp
                ConnectorSource               = $_.ConnectorSource
                WhenChanged                   = $_.WhenChanged
                WhenCreated                   = $_.WhenCreated
            }
        }
    }
}
function Get-WinExchangeMxRecord {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted,
        [Array] $ExchangeAcceptedDomains,
        [string] $Splitter = ', ')
    if (-not $ExchangeAcceptedDomains) { $ExchangeAcceptedDomains = & "Get-$($prefix)AcceptedDomain" }
    foreach ($_ in $ExchangeAcceptedDomains.Name) {
        $MxRecordReport = & "Get-$($prefix)MxRecordReport" -Domain $_
        foreach ($Mx in $MxRecordReport) {
            if ($Formatted) {
                [PSCustomObject]@{'Domain' = $Mx.Domain
                    'Is Accepted Domain'   = $Mx.IsAcceptedDomain
                    'Record Exists'        = $Mx.RecordExists
                    'Points to Service'    = $Mx.PointsToService
                    'Mailhost'             = $Mx.HighestPriorityMailhost
                    'Ip Addresses'         = $MxRecordReport.HighestPriorityMailhostIpAddress -join ', '
                }
            } else {
                [PSCustomObject]@{Domain = $Mx.Domain
                    IsAcceptedDomain     = $Mx.IsAcceptedDomain
                    RecordExists         = $Mx.RecordExists
                    PointsToService      = $Mx.PointsToService
                    Mailhost             = $Mx.HighestPriorityMailhost
                    IpAddresses          = $MxRecordReport.HighestPriorityMailhostIpAddress
                }
            }
            break
        }
    }
}
function Get-WinExchangeRemoteDomains {
    [CmdletBinding()]
    param([string] $Prefix,
        [switch] $Formatted)
    $RemoteDomains = & "Get-$($Prefix)RemoteDomain"
    foreach ($Domain in $RemoteDomains) {
        if ($Formatted) {
            [PSCustomObject]@{'Name'                        = $Domain.Name
                'Domain Name'                               = $Domain.DomainName
                'Is Internal'                               = $Domain.IsInternal
                'Target Delivery Domain'                    = $Domain.TargetDeliveryDomain
                'Byte Encoder Type For 7Bit Charsets'       = $Domain.ByteEncoderTypeFor7BitCharsets
                'Character Set'                             = $Domain.CharacterSet
                'Non Mime CharacterSet'                     = $Domain.NonMimeCharacterSet
                'Allowed OOF Type'                          = $Domain.AllowedOOFType
                'Auto Reply Enabled'                        = $Domain.AutoReplyEnabled
                'Auto Forward Enabled'                      = $Domain.AutoForwardEnabled
                'Delivery Report Enabled'                   = $Domain.DeliveryReportEnabled
                'NDR Enabled'                               = $Domain.NDREnabled
                'Meeting Forward Notification Enabled'      = $Domain.MeetingForwardNotificationEnabled
                'Content Type'                              = $Domain.ContentType
                'Display Sender Name'                       = $Domain.DisplaySenderName
                'Preferred Internet CodePage For Shift Jis' = $Domain.PreferredInternetCodePageForShiftJis
                'Required Charset Coverage'                 = $Domain.RequiredCharsetCoverage
                'TNEF Enabled'                              = $Domain.TNEFEnabled
                'Line WrapSize'                             = $Domain.LineWrapSize
                'Trusted Mail Outbound Enabled'             = $Domain.TrustedMailOutboundEnabled
                'Trusted Mail Inbound Enabled'              = $Domain.TrustedMailInboundEnabled
                'Use Simple Display Name'                   = $Domain.UseSimpleDisplayName
                'NDR Diagnostic Info Enabled'               = $Domain.NDRDiagnosticInfoEnabled
                'Message Count Threshold'                   = $Domain.MessageCountThreshold
                'WhenCreated'                               = $Domain.WhenCreated
                'WhenChanged'                               = $Domain.WhenChanged
            }
        } else {
            [PSCustomObject]@{Name                   = $Domain.Name
                DomainName                           = $Domain.DomainName
                IsInternal                           = $Domain.IsInternal
                TargetDeliveryDomain                 = $Domain.TargetDeliveryDomain
                ByteEncoderTypeFor7BitCharsets       = $Domain.ByteEncoderTypeFor7BitCharsets
                CharacterSet                         = $Domain.CharacterSet
                NonMimeCharacterSet                  = $Domain.NonMimeCharacterSet
                AllowedOOFType                       = $Domain.AllowedOOFType
                AutoReplyEnabled                     = $Domain.AutoReplyEnabled
                AutoForwardEnabled                   = $Domain.AutoForwardEnabled
                DeliveryReportEnabled                = $Domain.DeliveryReportEnabled
                NDREnabled                           = $Domain.NDREnabled
                MeetingForwardNotificationEnabled    = $Domain.MeetingForwardNotificationEnabled
                ContentType                          = $Domain.ContentType
                DisplaySenderName                    = $Domain.DisplaySenderName
                PreferredInternetCodePageForShiftJis = $Domain.PreferredInternetCodePageForShiftJis
                RequiredCharsetCoverage              = $Domain.RequiredCharsetCoverage
                TNEFEnabled                          = $Domain.TNEFEnabled
                LineWrapSize                         = $Domain.LineWrapSize
                TrustedMailOutboundEnabled           = $Domain.TrustedMailOutboundEnabled
                TrustedMailInboundEnabled            = $Domain.TrustedMailInboundEnabled
                UseSimpleDisplayName                 = $Domain.UseSimpleDisplayName
                NDRDiagnosticInfoEnabled             = $Domain.NDRDiagnosticInfoEnabled
                MessageCountThreshold                = $Domain.MessageCountThreshold
                WhenCreated                          = $Domain.WhenCreated
                WhenChanged                          = $Domain.WhenChanged
            }
        }
    }
}
function Get-WinExchangeTransportConfig {
    [CmdletBinding()]
    param([string] $Prefix,
        [switch] $Formatted,
        [string] $Splitter = ', ')
    $TransportConfig = & "Get-$($prefix)TransportConfig"
    if ($Formatted) {
        [ordered]@{'Address Book Policy Routing Enabled' = $TransportConfig.AddressBookPolicyRoutingEnabled
            'Anonymous SenderToRecipientRatePerHour'     = $TransportConfig.AnonymousSenderToRecipientRatePerHour
            'Clear Categories'                           = $TransportConfig.ClearCategories
            'Convert DisclaimerWrapperToEml'             = $TransportConfig.ConvertDisclaimerWrapperToEml
            'DSN Conversion Mode'                        = Format-AddSpaceToSentence -Text $TransportConfig.DSNConversionMode
            'Journal Archiving Enabled'                  = $TransportConfig.JournalArchivingEnabled
            'External Delay Dsn Enabled'                 = $TransportConfig.ExternalDelayDsnEnabled
            'External Dsn Default Language'              = $TransportConfig.ExternalDsnDefaultLanguage
            'External Dsn Language DetectionEnabled'     = $TransportConfig.ExternalDsnLanguageDetectionEnabled
            'External Dsn MaxMessage Attach Size'        = $TransportConfig.ExternalDsnMaxMessageAttachSize
            'External Dsn Reporting Authority'           = $TransportConfig.ExternalDsnReportingAuthority
            'External Dsn SendHtml'                      = $TransportConfig.ExternalDsnSendHtml
            'External Postmaster Address'                = $TransportConfig.ExternalPostmasterAddress
            'Generate Copy Of DSN For'                   = $TransportConfig.GenerateCopyOfDSNFor -join $Splitter
            'SafetyNet Hold Time'                        = $TransportConfig.SafetyNetHoldTime
            'Shadow Heartbeat Frequency'                 = $TransportConfig.ShadowHeartbeatFrequency
            'Shadow Message Auto Discard Interval'       = $TransportConfig.ShadowMessageAutoDiscardInterval
            'Shadow Message Preference Setting'          = $TransportConfig.ShadowMessagePreferenceSetting
            'Shadow Redundancy Enabled'                  = $TransportConfig.ShadowRedundancyEnabled
            'Shadow Resubmit TimeSpan'                   = $TransportConfig.ShadowResubmitTimeSpan
            'Smtp Client Authentication Disabled'        = $TransportConfig.SmtpClientAuthenticationDisabled
            'Supervision Tags'                           = $TransportConfig.SupervisionTags -join $Splitter
            'TLS Receive Domain Secure List'             = $TransportConfig.TLSReceiveDomainSecureList -join $Splitter
            'TLS SendDomain Secure List'                 = $TransportConfig.TLSSendDomainSecureList -join $Splitter
            'Verify Secure Submit Enabled'               = $TransportConfig.VerifySecureSubmitEnabled
            'Voicemail Journaling Enabled'               = $TransportConfig.VoicemailJournalingEnabled
            'Header Promotion Mode Setting'              = $TransportConfig.HeaderPromotionModeSetting
            'Xexch50Enabled'                             = $TransportConfig.Xexch50Enabled
        }
    } else {
        [ordered]@{AddressBookPolicyRoutingEnabled = $TransportConfig.AddressBookPolicyRoutingEnabled
            AnonymousSenderToRecipientRatePerHour  = $TransportConfig.AnonymousSenderToRecipientRatePerHour
            ClearCategories                        = $TransportConfig.ClearCategories
            ConvertDisclaimerWrapperToEml          = $TransportConfig.ConvertDisclaimerWrapperToEml
            DSNConversionMode                      = $TransportConfig.DSNConversionMode
            JournalArchivingEnabled                = $TransportConfig.JournalArchivingEnabled
            ExternalDelayDsnEnabled                = $TransportConfig.ExternalDelayDsnEnabled
            ExternalDsnDefaultLanguage             = $TransportConfig.ExternalDsnDefaultLanguage
            ExternalDsnLanguageDetectionEnabled    = $TransportConfig.ExternalDsnLanguageDetectionEnabled
            ExternalDsnMaxMessageAttachSize        = $TransportConfig.ExternalDsnMaxMessageAttachSize
            ExternalDsnReportingAuthority          = $TransportConfig.ExternalDsnReportingAuthority
            ExternalDsnSendHtml                    = $TransportConfig.ExternalDsnSendHtml
            ExternalPostmasterAddress              = $TransportConfig.ExternalPostmasterAddress
            GenerateCopyOfDSNFor                   = $TransportConfig.GenerateCopyOfDSNFor
            SafetyNetHoldTime                      = $TransportConfig.SafetyNetHoldTime
            ShadowHeartbeatFrequency               = $TransportConfig.ShadowHeartbeatFrequency
            ShadowMessageAutoDiscardInterval       = $TransportConfig.ShadowMessageAutoDiscardInterval
            ShadowMessagePreferenceSetting         = $TransportConfig.ShadowMessagePreferenceSetting
            ShadowRedundancyEnabled                = $TransportConfig.ShadowRedundancyEnabled
            ShadowResubmitTimeSpan                 = $TransportConfig.ShadowResubmitTimeSpan
            SmtpClientAuthenticationDisabled       = $TransportConfig.SmtpClientAuthenticationDisabled
            SupervisionTags                        = $TransportConfig.SupervisionTags
            TLSReceiveDomainSecureList             = $TransportConfig.TLSReceiveDomainSecureList
            TLSSendDomainSecureList                = $TransportConfig.TLSSendDomainSecureList
            VerifySecureSubmitEnabled              = $TransportConfig.VerifySecureSubmitEnabled
            VoicemailJournalingEnabled             = $TransportConfig.VoicemailJournalingEnabled
            HeaderPromotionModeSetting             = $TransportConfig.HeaderPromotionModeSetting
            Xexch50Enabled                         = $TransportConfig.Xexch50Enabled
        }
    }
}
function Get-WinAzureADGroupMembers {
    [CmdletBinding()]
    param([Array] $UAzureADGroups,
        [System.Collections.IDictionary] $Users,
        [switch] $Formatted)
    $GroupMembers = foreach ($Group in $UAzureADGroups) {
        $Object = Get-MsolGroupMember -GroupObjectId $Group.ObjectId -All
        foreach ($_ in $Object) {
            if ($Formatted) {
                $GroupMember = [ordered] @{"Group Display Name" = $Group.DisplayName
                    "Group Email"                               = $Group.EmailAddress
                    "Group Email Secondary"                     = $Group.ProxyAddresses -replace 'smtp:', '' -join ','
                    "Group Type"                                = $Group.GroupType
                }
                $CurrentUser = $Users[$_.ObjectId.Guid]
                if ($CurrentUser) { foreach ($Property in $CurrentUser.psobject.Properties) { $GroupMember[$Property.Name] = $Property.value } } else { Write-Warning 'Problem' }
                $GroupMember["Group Last Dir Sync Time"] = $Group.LastDirSyncTime
                $GroupMember["Group Managed By"] = $Group.ManagedBy
                $GroupMember["Group EmailA ddresses"] = $Group.ProxyAddresses
            } else {
                $GroupMember = [ordered] @{"GroupDisplayName" = $Group.DisplayName
                    "GroupEmail"                              = $Group.EmailAddress
                    "GroupEmailSecondary"                     = $Group.ProxyAddresses -replace 'smtp:', '' -join ','
                    "GroupType"                               = $Group.GroupType
                }
                $CurrentUser = $Users[$_.ObjectId.Guid]
                if ($CurrentUser) { foreach ($Property in $CurrentUser.psobject.Properties) { $GroupMember[$Property.Name] = $Property.value } } else { Write-Warning 'Problem' }
                $GroupMember["GroupLastDirSyncTime"] = $Group.LastDirSyncTime
                $GroupMember["GroupManagedBy"] = $Group.ManagedBy
                $GroupMember["GroupEmailAddresses"] = $Group.ProxyAddresses
            }
            [PSCustomObject] $GroupMember
        }
    }
    $GroupMembers
}
function Get-WinAzureADUsersMFA {
    [CmdletBinding()]
    param([Array] $UAzureADUsers)
    $AzureUsers = foreach ($User in $UAzureADUsers) {
        $MFAOptions = @{ }
        $MFAOptions.AuthAvailable = @(foreach ($Auth in $User.StrongAuthenticationMethods) { if ($Auth.IsDefault) { $MFAOptions.AuthDefault = $Auth.MethodType } else { $Auth.MethodType } })
        [pscustomobject] @{'UserPrincipalName' = $User.UserPrincipalName
            'Display Name'                     = $User.DisplayName
            'Method Default'                   = $MFAOptions.AuthDefault
            'Method Alternative'               = ($MFAOptions.AuthAvailable | Sort-Object) -join ','
            'App Authentication Type'          = $User.StrongAuthenticationPhoneAppDetails.AuthenticationType
            'App Device Name'                  = $User.StrongAuthenticationPhoneAppDetails.DeviceName
            'App Device Tag'                   = $User.StrongAuthenticationPhoneAppDetails.DeviceTag
            'App Device Token'                 = $User.StrongAuthenticationPhoneAppDetails.DeviceToken
            'App Notification Type'            = $User.StrongAuthenticationPhoneAppDetails.NotificationType
            'App Oath Secret Key'              = $User.StrongAuthenticationPhoneAppDetails.OathSecretKey
            'App Oath Token Time Drift'        = $User.StrongAuthenticationPhoneAppDetails.OathTokenTimeDrift
            'App Version'                      = $User.StrongAuthenticationPhoneAppDetails.PhoneAppVersion
            'User Details Email'               = $User.StrongAuthenticationUserDetails.Email
            'User Details Phone'               = $User.StrongAuthenticationUserDetails.PhoneNumber
            'User Details Phone Alt'           = $User.StrongAuthenticationUserDetails.AlternativePhoneNumber
            'User Details Pin'                 = $User.StrongAuthenticationUserDetails.Pin
            'User Details OldPin'              = $User.StrongAuthenticationUserDetails.OldPin
            'Strong Password Required'         = $User.StrongPasswordRequired
            'Requirement Relying Party'        = $User.StrongAuthenticationRequirements.RelyingParty
            'Requirement Not Issued Before'    = $User.StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
            'Requirement State'                = $User.StrongAuthenticationRequirements.State
            'StrongAuthenticationProofupTime'  = $User.StrongAuthenticationProofupTime
        }
    }
    return $AzureUsers | Sort-Object 'UserPrincipalName'
}
function Get-WinAzureADUsersStatisticsByCity {
    [CmdletBinding()]
    param([Array] $UAzureADUsers)
    $UAzureADUsers | Group-Object City | Select-Object @{L = 'City'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'Unknown' } } } , @{L = 'Users Count'; Expression = { $_.Count } } | Sort-Object 'City'
}
function Get-WinAzureADUsersStatisticsByCountry {
    [CmdletBinding()]
    param([Array] $UAzureADUsers)
    $UAzureADUsers | Group-Object Country | Select-Object @{L = 'Country'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'Unknown' } } } , @{L = 'Users Count'; Expression = { $_.Count } } | Sort-Object 'Country'
}
function Get-WinAzureADUsersStatisticsByCountryCity {
    [CmdletBinding()]
    param([Array] $UAzureADUsers)
    $UAzureADUsers | Group-Object Country, City | Select-Object @{L = 'Country, City'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'Unknown' } } } , @{L = 'Users Count'; Expression = { $_.Count } } | Sort-Object 'Country, City'
}
function Get-WinExchangeDistributionGroups {
    [CmdletBinding()]
    param([Array] $UExchangeGroupsDistribution)
    $Output = foreach ($O365Group in $UExchangeGroupsDistribution) {
        [PSCustomObject] @{"Group Name"        = $O365Group.DisplayName
            "Group Owners"                     = $O365Group.ManagedBy -join ', '
            "Group Primary Email"              = $O365Group.PrimarySmtpAddress
            "Group Emails"                     = Convert-ExchangeEmail -Emails $O365Group.EmailAddresses -AddSeparator -RemoveDuplicates -RemovePrefix
            IsDirSynced                        = $O365Group.IsDirSynced
            MemberJoinRestriction              = $O365Group.MemberJoinRestriction
            MemberDepartRestriction            = $O365Group.MemberDepartRestriction
            GrantSendOnBehalfTo                = $O365Group.GrantSendOnBehalfTo
            MailTip                            = $O365Group.MailTip
            Identity                           = $O365Group.Identity
            SamAccountName                     = $O365Group.SamAccountName
            GroupType                          = $O365Group.GroupType
            WhenCreated                        = $O365Group.WhenCreated
            WhenChanged                        = $O365Group.WhenChanged
            Alias                              = $O365Group.Alias
            ModeratedBy                        = $O365Group.ModeratedBy
            ModerationEnabled                  = $O365Group.ModerationEnabled
            HiddenGroupMembershipEnabled       = $O365Group.HiddenGroupMembershipEnabled
            HiddenFromAddressListsEnabled      = $O365Group.HiddenFromAddressListsEnabled
            RequireSenderAuthenticationEnabled = $O365Group.RequireSenderAuthenticationEnabled
            RecipientTypeDetails               = $O365Group.RecipientTypeDetails
        }
    }
    $Output
}
function Get-WinExchangeDistributionGroupsMembers {
    [CmdletBinding()]
    param([Array] $UExchangeGroupsDistribution)
    $Output = foreach ($O365Group in $UExchangeGroupsDistribution) {
        $O365GroupPeople = Get-DistributionGroupMember -Identity $O365Group.GUID.GUID
        foreach ($O365Member in $O365GroupPeople) {
            [PSCustomObject] @{"Group Name" = $O365Group.DisplayName
                "Group Primary Email"       = $O365Group.PrimarySmtpAddress
                "Group Emails"              = Convert-ExchangeEmail -Emails $O365Group.EmailAddresses -AddSeparator -RemoveDuplicates -RemovePrefix
                "Group Owners"              = $O365Group.ManagedBy -join ', '
                "Member Name"               = $O365Member.Name
                "Member E-Mail"             = $O365Member.PrimarySMTPAddress
                "Recipient Type"            = $O365Member.RecipientType
            }
        }
    }
    $Output
}
function Get-WinExchangeMailboxes {
    [CmdletBinding()]
    param([Array] $AzureUsers,
        [Array] $ExchangeMailboxes,
        [Array] $MailboxStatistics,
        [Array] $MailboxStatisticsArchive)
    $Mailboxes = foreach ($Mailbox in $ExchangeMailboxes) {
        $Azure = $AzureUsers | Where-Object { $_.UserPrincipalName -eq $Mailbox.UserPrincipalName }
        $MailboxStats = $MailboxStatistics | Where-Object { $_.MailboxGuid.Guid -eq $Mailbox.ExchangeGuid.Guid }
        $MailboxStatsArchive = $MailboxStatisticsArchive | Where-Object { $_.MailboxGuid.Guid -eq $Mailbox.ArchiveGuid.Guid }
        [PSCustomObject][ordered] @{DisplayName = $Mailbox.DisplayName
            UserPrincipalName                   = $Mailbox.UserPrincipalName
            FirstName                           = $Azure.FirstName
            LastName                            = $Azure.LastName
            Country                             = $Azure.Country
            City                                = $Azure.City
            Department                          = $Azure.Department
            Office                              = $Azure.Office
            UsageLocation                       = $Azure.UsageLocation
            License                             = Convert-Office365License -License $Azure.Licenses.AccountSkuID
            UserCreated                         = $Azure.WhenCreated
            Blocked                             = $Azure.BlockCredential
            LastSynchronized                    = $azure.LastDirSyncTime
            LastPasswordChange                  = $Azure.LastPasswordChangeTimestamp
            PasswordNeverExpires                = $Azure.PasswordNeverExpires
            RecipientType                       = $Mailbox.RecipientTypeDetails
            PrimaryEmailAddress                 = $Mailbox.PrimarySmtpAddress
            AllEmailAddresses                   = Convert-ExchangeEmail -Emails $Mailbox.EmailAddresses -Separator ', ' -RemoveDuplicates -RemovePrefix -AddSeparator
            MailboxLogOn                        = $MailboxStats.LastLogonTime
            MailboxLogOff                       = $MailboxStats.LastLogoffTime
            MailboxSize                         = Convert-ExchangeSize -Size $MailboxStats.TotalItemSize -To $SizeIn -Default '' -Precision $SizePrecision
            MailboxItemCount                    = $MailboxStats.ItemCount
            MailboxDeletedSize                  = Convert-ExchangeSize -Size $MailboxStats.TotalDeletedItemSize -To $SizeIn -Default '' -Precision $SizePrecision
            MailboxDeletedItemsCount            = $MailboxStats.DeletedItemCount
            MailboxHidden                       = $Mailbox.HiddenFromAddressListsEnabled
            MailboxCreated                      = $Mailbox.WhenCreated
            MailboxChanged                      = $Mailbox.WhenChanged
            ArchiveStatus                       = $Mailbox.ArchiveStatus
            ArchiveQuota                        = Convert-ExchangeSize -Size $Mailbox.ArchiveQuota -To $SizeIn -Default '' -Display
            ArchiveSize                         = Convert-ExchangeSize -Size $MailboxStatsArchive.TotalItemSize -To $SizeIn -Default '' -Precision $SizePrecision
            ArchiveItemCount                    = Convert-ExchangeItems -Count $MailboxStatsArchive.ItemCount -Default ''
            ArchiveDeletedSize                  = Convert-ExchangeSize -Size $MailboxStatsArchive.TotalDeletedItemSize -To $SizeIn -Default '' -Precision $SizePrecision
            ArchiveDeletedItemsCount            = Convert-ExchangeItems -Count $MailboxStatsArchive.DeletedItemCount -Default ''
            OverallProvisioningStatus           = $Azure.OverallProvisioningStatus
            ImmutableID                         = $Azure.ImmutableID
            Guid                                = $Mailbox.Guid.Guid
            ObjectID                            = $Mailbox.ExternalDirectoryObjectId
        }
    }
    $Mailboxes
}
function Get-WinExchangeMailboxesInboxRulesForwarding {
    [CmdletBinding()]
    param([Array] $InboxRules,
        [Array] $Mailboxes)
    $InboxRulesForwarding = @(foreach ($Mailbox in $Mailboxes) {
            $UserRules = $InboxRules | Where-Object { ($Mailbox.Identity -eq $_.MailboxOwnerID) -and (($null -ne $_.ForwardTo) -or ($null -ne $_.ForwardAsAttachmentTo) -or ($null -ne $_.RedirectsTo)) }
            foreach ($Rule in $UserRules) {
                [pscustomobject][ordered] @{UserPrincipalName = $Mailbox.UserPrincipalName
                    DisplayName                               = $Mailbox.DisplayName
                    RuleName                                  = $Rule.Name
                    Description                               = $Rule.Description
                    Enabled                                   = $Rule.Enabled
                    Priority                                  = $Rule.Priority
                    ForwardTo                                 = $Rule.ForwardTo
                    ForwardAsAttachmentTo                     = $Rule.ForwardAsAttachmentTo
                    RedirectTo                                = $Rule.RedirectTo
                    DeleteMessage                             = $Rule.DeleteMessage
                }
            }
        })
    $InboxRulesForwarding
}
function Get-WinExchangeMailboxesPermissions {
    [CmdletBinding()]
    param([Array] $ExchangeMailboxes,
        [Array] $MailboxPermissions)
    $Permissions = foreach ($Mailbox in $ExchangeMailboxes) {
        $MailboxPermission = $MailboxPermissions | Where-Object { $_.UserPrincipalName -eq $Mailbox.UserPrincipalName }
        if (-not $MailboxPermissions) { continue }
        foreach ($Permission in ($MailboxPermission | Where-Object { ($_."User With Access" -ne "NT AUTHORITY\SELF") -and ($_.Inherited -ne $true) })) { $Permission }
    }
    $Permissions
}
function Get-WinExchangeMailboxesPermissionsIncludingInherited {
    [CmdletBinding()]
    param([Array] $AzureUsers,
        [Array] $ExchangeMailboxes)
    $Permissions = foreach ($Mailbox in $ExchangeMailboxes) {
        $Azure = $AzureUsers | Where-Object { $_.UserPrincipalName -eq $Mailbox.UserPrincipalName }
        $MailboxPermissions = Get-MailboxPermission -Identity $Mailbox.PrimarySmtpAddress.ToString()
        $PermissionsAll = foreach ($Permission in $MailboxPermissions) {
            [PSCustomObject] @{DiplayName = $Mailbox.DisplayName
                UserPrincipalName         = $Mailbox.UserPrincipalName
                FirstName                 = $Azure.FirstName
                LastName                  = $Azure.LastName
                RecipientType             = $Mailbox.RecipientTypeDetails
                PrimaryEmailAddress       = $Mailbox.PrimarySmtpAddress
                "User With Access"        = $Permission.User
                "User Access Rights"      = ($Permission.AccessRights -join ",")
                "Inherited"               = $Permission.IsInherited
                "Deny"                    = $Permission.Deny
                "InheritanceType"         = $Permission.InheritanceType
            }
        }
        if ($null -ne $PermissionsAll) { $PermissionsAll }
    }
    $Permissions
}
function Get-WinExchangeMailboxesStatistics {
    [CmdletBinding()]
    param([Array] $ExchangeMailboxes)
    $PropertiesMailboxStats = 'DisplayName', 'LastLogonTime', 'LastLogoffTime', 'TotalItemSize', 'ItemCount', 'TotalDeletedItemSize', 'DeletedItemCount', 'OwnerADGuid', 'MailboxGuid'
    $MailboxStatistics = foreach ($_ in $ExchangeMailboxes) { & "Get-$($Prefix)MailboxStatistics" -Identity $_.Guid.Guid | Select-Object -Property $PropertiesMailboxStats }
    $MailboxStatistics
}
function Get-WinExchangeMailboxesStatisticsArchive {
    [CmdletBinding()]
    param([Array] $ExchangeMailboxes)
    $PropertiesMailboxStatsArchive = 'DisplayName', 'TotalItemSize', 'ItemCount', 'TotalDeletedItemSize', 'DeletedItemCount', 'OwnerADGuid', 'MailboxGuid'
    $MailboxStatisticsArchive = foreach ($_ in $ExchangeMailboxes) { if ($Mailbox.ArchiveStatus -eq "Active") { & "Get-$($Prefix)MailboxStatistics" -Identity $_.Guid.Guid -Archive | Select-Object -Property $PropertiesMailboxStatsArchive } }
    $MailboxStatisticsArchive
}
function Get-WinExchangeUnifiedGroups {
    [CmdletBinding()]
    param([Array] $ExchangeUnifiedGroups)
    $Output = foreach ($O365Group in $ExchangeUnifiedGroups) {
        [PSCustomObject] @{"Group Name"            = $O365Group.DisplayName
            "Group Owners"                         = $O365Group.ManagedBy -join ', '
            "Group Primary Email"                  = $O365Group.PrimarySmtpAddress
            "Group Emails"                         = Convert-ExchangeEmail -Emails $O365Group.EmailAddresses -AddSeparator -RemoveDuplicates -RemovePrefix
            Identity                               = $O365Group.Identity
            WhenCreated                            = $O365Group.WhenCreated
            WhenChanged                            = $O365Group.WhenChanged
            Alias                                  = $O365Group.Alias
            ModerationEnabled                      = $O365Group.ModerationEnabled
            AccessType                             = $O365Group.AccessType
            AutoSubscribeNewMembers                = $O365Group.AutoSubscribeNewMembers
            AlwaysSubscribeMembersToCalendarEvents = $O365Group.AlwaysSubscribeMembersToCalendarEvents
            CalendarMemberReadOnly                 = $O365Group.CalendarMemberReadOnly
            HiddenGroupMembershipEnabled           = $O365Group.HiddenGroupMembershipEnabled
            SubscriptionEnabled                    = $O365Group.SubscriptionEnabled
            HiddenFromExchangeClientsEnabled       = $O365Group.HiddenFromExchangeClientsEnabled
            InboxUrl                               = $O365Group.InboxUrl
            SharePointSiteUrl                      = $O365Group.SharePointSiteUrl
            SharePointDocumentsUrl                 = $O365Group.SharePointDocumentsUrl
            SharePointNotebookUrl                  = $O365Group.SharePointNotebookUrl
        }
    }
    $Output
}
function Get-WinExchangeUnifiedGroupsMembers {
    [CmdletBinding()]
    param([Array] $ExchangeUnifiedGroups)
    $Output = foreach ($O365Group in $ExchangeUnifiedGroups) {
        $O365GroupPeople = Get-UnifiedGroupLinks -Identity $O365Group.Guid.Guid -LinkType Members
        foreach ($O365Member in $O365GroupPeople) {
            [PSCustomObject] @{"Group Name" = $O365Group.DisplayName
                "Group Primary Email"       = $O365Group.PrimarySmtpAddress
                "Group Emails"              = Convert-ExchangeEmail -Emails $O365Group.EmailAddresses -AddSeparator -RemoveDuplicates -RemovePrefix
                "Group Owners"              = $O365Group.ManagedBy -join ', '
                "Member Name"               = $O365Member.Name
                "Member E-Mail"             = $O365Member.PrimarySMTPAddress
                "Recipient Type"            = $O365Member.RecipientType
            }
        }
    }
    $Output
}
function Get-WinUAzureADContacts {
    param()
    Get-MsolContact -All
}
function Get-WinUAzureADGroups {
    [CmdletBinding()]
    param([switch] $Formatted)
    $Groups = Get-MsolGroup -All
    foreach ($_ in $Groups) {
        if ($Formatted) {
            [PSCustomObject]@{DisplayName    = $_.DisplayName
                Description                  = $_.Description
                DirSyncProvisioningErrors    = $_.DirSyncProvisioningErrors
                EmailAddress                 = $_.EmailAddress
                Errors                       = $_.Errors
                GroupLicenseProcessingDetail = $_.GroupLicenseProcessingDetail
                GroupType                    = $_.GroupType
                IsSystem                     = $_.IsSystem
                LastDirSyncTime              = $_.LastDirSyncTime
                Licenses                     = $_.Licenses
                ManagedBy                    = $_.ManagedBy
                ObjectId                     = $_.ObjectId
                ProxyAddresses               = $_.ProxyAddresses
                ValidationStatus             = $_.ValidationStatus
                AssignedLicenses             = $_.AssignedLicenses
            }
        } else {
            [PSCustomObject]@{DisplayName    = $_.DisplayName
                Description                  = $_.Description
                DirSyncProvisioningErrors    = $_.DirSyncProvisioningErrors
                EmailAddress                 = $_.EmailAddress
                Errors                       = $_.Errors
                GroupLicenseProcessingDetail = $_.GroupLicenseProcessingDetail
                GroupType                    = $_.GroupType
                IsSystem                     = $_.IsSystem
                LastDirSyncTime              = $_.LastDirSyncTime
                Licenses                     = $_.Licenses
                ManagedBy                    = $_.ManagedBy
                ObjectId                     = $_.ObjectId
                ProxyAddresses               = $_.ProxyAddresses
                ValidationStatus             = $_.ValidationStatus
                AssignedLicenses             = $_.AssignedLicenses
            }
        }
    }
}
function Get-WinO365UAzureCompanyInformation {
    [CmdletBinding()]
    param([string] $Prefix)
    $CompanyInformation = Get-MsolCompanyInformation
    return $CompanyInformation
}
function Get-WinUAzureTenantDomains {
    [CmdletBinding()]
    param()
    $UAzureTenantDomains = Get-MsolDomain
    return $UAzureTenantDomains
}
function Get-WinUExchangeContacts {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeContacts = & "Get-$($prefix)Contact" -ResultSize unlimited
    $UExchangeContacts
}
function Get-WinUExchangeContactsMail {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeContactsMail = & "Get-$($prefix)MailContact" -ResultSize unlimited
    return $UExchangeContactsMail
}
function Get-WinUExchangeEquipmentCalendarProcessing {
    [CmdletBinding()]
    param([string] $Prefix,
        [Array] $UExchangeMailboxesEquipment)
    $Output = @(foreach ($Mailbox in $UExchangeMailboxesEquipment) {
            $Object = & "Get-$($prefix)CalendarProcessing" -Identity $Mailbox.PrimarySmtpAddress -ResultSize unlimited
            if ($Object) {
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxPrimarySmtpAddress" -Value $Mailbox.PrimarySmtpAddress
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxAlias" -Value $Mailbox.Alias
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxGUID" -Value $Mailbox.GUID
                $Object
            }
        })
    $Output
}
function Get-WinUExchangeGroupsDistribution {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeGroupsDistribution = & "Get-$($prefix)DistributionGroup" -ResultSize unlimited
    return $UExchangeGroupsDistribution
}
function Get-WinUExchangeGroupsDistributionDynamic {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeGroupsDistributionDynamic = & "Get-$($prefix)DynamicDistributionGroup" -ResultSize unlimited
    $UExchangeGroupsDistributionDynamic
}
function Get-WinUExchangeGroupsDistributionMembers {
    [CmdletBinding()]
    param([Array] $UExchangeGroupsDistribution,
        [string] $Prefix)
    $GroupMembers = @(foreach ($Group in $UExchangeGroupsDistribution) {
            $Object = & "Get-$($prefix)DistributionGroupMember" -Identity $Group.PrimarySmtpAddress -ResultSize unlimited
            $Object | Add-Member -MemberType NoteProperty -Name "GroupGUID" -Value $Group.GUID
            $Object | Add-Member -MemberType NoteProperty -Name "GroupPrimarySmtpAddress" -Value $Group.PrimarySmtpAddress
            $Object | Add-Member -MemberType NoteProperty -Name "GroupIdentity" -Value $Group.Identity
            $Object
        })
    return $GroupMembers
}
function Get-WinUExchangeMailBoxes {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeMailBoxes = & "Get-$($prefix)Mailbox" -ResultSize unlimited
    return $UExchangeMailBoxes
}
function Get-WinUExchangeMailboxesEquipment {
    [CmdletBinding()]
    param([Array] $UExchangeMailBoxes)
    $UExchangeMailBoxes | Where-Object { $_.RecipientTypeDetails -eq 'EquipmentMailbox' }
}
function Get-WinUExchangeMailboxesInboxRules {
    [CmdletBinding()]
    param([string] $Prefix,
        [Array] $UExchangeMailBoxes)
    $InboxRules = @(foreach ($Mailbox in $UExchangeMailBoxes) { & "Get-$($prefix)InboxRule" -Mailbox $Mailbox.UserPrincipalName })
    return $InboxRules
}
function Get-WinUExchangeMailboxesJunk {
    [CmdletBinding()]
    param([Array] $UExchangeMailBoxes,
        [string] $Prefix)
    $Output = @(foreach ($Mailbox in $UExchangeMailBoxes) {
            if ($null -eq $Mailbox.PrimarySmtpAddress) {
                $Object = & "Get-$($prefix)MailboxJunkEmailConfiguration" -Identity $Mailbox.PrimarySmtpAddress -ResultSize unlimited
                if ($Object) {
                    $Object | Add-Member -MemberType NoteProperty -Name "MailboxPrimarySmtpAddress" -Value $Mailbox.PrimarySmtpAddress
                    $Object | Add-Member -MemberType NoteProperty -Name "MailboxAlias" -Value $Mailbox.Alias
                    $Object | Add-Member -MemberType NoteProperty -Name "MailboxGUID" -Value $Mailbox.GUID
                    $Object
                }
            }
        })
    return $Output
}
function Get-WinUExchangeMailboxesRooms {
    [CmdletBinding()]
    param([Array] $UExchangeMailBoxes)
    $UExchangeMailBoxes | Where-Object { $_.RecipientTypeDetails -eq 'RoomMailbox' }
}
function Get-WinUExchangeRecipientsPermissions {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeRecipientsPermissions = & "Get-$($prefix)RecipientPermission" -ResultSize unlimited
    return $UExchangeRecipientsPermissions
}
function Get-WinUExchangeRecipientsPermissions1 {
    [CmdletBinding()]
    param([Array] $ExchangeRecipientsPermissions)
    foreach ($_ in $ExchangeRecipientsPermissions) {
        [PSCustomObject]@{Identity = $_.Identity
            Trustee                = $_.Trustee
            AccessControlType      = $_.AccessControlType
            AccessRights           = $_.AccessRights
            IsInherited            = $_.IsInherited
            InheritanceType        = $_.InheritanceType
        }
    }
}
function Get-WinUExchangeRecipientsPermissionsLimited {
    [CmdletBinding()]
    param([Array] $ExchangeRecipientsPermissions)
    $ExchangeRecipientsPermissions | Where-Object { ($_.Trustee -ne 'NT AUTHORITY\SELF') }
}
function Get-WinTeamsSettings {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [Array] $TeamsConfiguration,
        [switch] $Formatted)
    if (-not $TeamsConfiguration) { if ($Tenant) { $TeamsConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Tenant $Tenant -Identity Global } else { $TeamsConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Identity Global } }
    if ($Formatted) {
        [ordered]@{'Allow Email into Channel'     = $TeamsConfiguration.AllowEmailIntoChannel
            'Restricted Sender List'              = $TeamsConfiguration.RestrictedSenderList
            'Allow Organization Tab'              = $TeamsConfiguration.AllowOrganizationTab
            'Allow Skype for Business Interop'    = $TeamsConfiguration.AllowSkypeBusinessInterop
            'Content Pin'                         = Format-AddSpaceToSentence -Text $TeamsConfiguration.ContentPin
            'Allow Resource Account Send Message' = $TeamsConfiguration.AllowResourceAccountSendMessage
            'Resource Account Content Access'     = Format-AddSpaceToSentence -Text $TeamsConfiguration.ResourceAccountContentAccess
            'Allow Guest User'                    = $TeamsConfiguration.AllowGuestUser
            'Allow Scoped People Search'          = $TeamsConfiguration.AllowScopedPeopleSearchandAccess
        }
    } else {
        [ordered]@{AllowEmailIntoChannel     = $TeamsConfiguration.AllowEmailIntoChannel
            RestrictedSenderList             = $TeamsConfiguration.RestrictedSenderList
            AllowOrganizationTab             = $TeamsConfiguration.AllowOrganizationTab
            AllowSkypeBusinessInterop        = $TeamsConfiguration.AllowSkypeBusinessInterop
            ContentPin                       = $TeamsConfiguration.ContentPin
            AllowResourceAccountSendMessage  = $TeamsConfiguration.AllowResourceAccountSendMessage
            ResourceAccountContentAccess     = $TeamsConfiguration.ResourceAccountContentAccess
            AllowGuestUser                   = $TeamsConfiguration.AllowGuestUser
            AllowScopedPeopleSearchandAccess = $TeamsConfiguration.AllowScopedPeopleSearchandAccess
        }
    }
}
function Get-WInTeamsSettingsBroadcasting {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsMeetingBroadcastPolicy = & "Get-$($prefix)CsTeamsMeetingBroadcastPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsMeetingBroadcastPolicy = & "Get-$($prefix)CsTeamsMeetingBroadcastPolicy" -Identity Global }
    if ($Tenant) { $CsTeamsMeetingBroadcastConfiguration = & "Get-$($prefix)CsTeamsMeetingBroadcastConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsMeetingBroadcastConfiguration = & "Get-$($prefix)CsTeamsMeetingBroadcastConfiguration" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Allow Broadcast Scheduling'       = $CsTeamsMeetingBroadcastPolicy.AllowBroadcastScheduling
            'Allow Broadcast Transcription'           = $CsTeamsMeetingBroadcastPolicy.AllowBroadcastTranscription
            'Allow Sdn Provider For BroadcastMeeting' = $CsTeamsMeetingBroadcastConfiguration.AllowSdnProviderForBroadcastMeeting
            'Broadcast Attendee Visibility Mode'      = Format-AddSpaceToSentence -Text $CsTeamsMeetingBroadcastPolicy.BroadcastAttendeeVisibilityMode
            'Broadcast Recording Mode'                = Format-AddSpaceToSentence -Text $CsTeamsMeetingBroadcastPolicy.BroadcastRecordingMode
            'Description'                             = $CsTeamsMeetingBroadcastPolicy.Description
        }
    } else {
        [ordered]@{AllowBroadcastScheduling     = $CsTeamsMeetingBroadcastPolicy.AllowBroadcastScheduling
            AllowBroadcastTranscription         = $CsTeamsMeetingBroadcastPolicy.AllowBroadcastTranscription
            AllowSdnProviderForBroadcastMeeting = $CsTeamsMeetingBroadcastConfiguration.AllowSdnProviderForBroadcastMeeting
            BroadcastAttendeeVisibilityMode     = $CsTeamsMeetingBroadcastPolicy.BroadcastAttendeeVisibilityMode
            BroadcastRecordingMode              = $CsTeamsMeetingBroadcastPolicy.BroadcastRecordingMode
            Description                         = $CsTeamsMeetingBroadcastPolicy.Description
        }
    }
}
function Get-WinTeamsSettingsCalling {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsCallingPolicy = & "Get-$($prefix)CsTeamsCallingPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsCallingPolicy = & "Get-$($prefix)CsTeamsCallingPolicy" -Identity Global }
    if ($Tenant) { $CsTeamsCallParkPolicy = & "Get-$($prefix)CsTeamsCallParkPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsCallParkPolicy = & "Get-$($prefix)CsTeamsCallParkPolicy" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Allow Private Calling'   = $CsTeamsCallingPolicy.AllowPrivateCalling
            'Allow Voicemail'                = Format-AddSpaceToSentence -Text $CsTeamsCallingPolicy.AllowVoicemail
            'Allow Call Groups'              = $CsTeamsCallingPolicy.AllowCallGroups
            'Allow Delegation'               = $CsTeamsCallingPolicy.AllowDelegation
            'Allow Call Forwarding to User'  = $CsTeamsCallingPolicy.AllowCallForwardingToUser
            'Allow Call Forwarding to Phone' = $CsTeamsCallingPolicy.AllowCallForwardingToPhone
            'Prevent Toll Bypass'            = $CsTeamsCallingPolicy.PreventTollBypass
            'Busy on Busy EnabledType'       = $CsTeamsCallingPolicy.BusyOnBusyEnabledType
            'Allow Call Park'                = $CsTeamsCallParkPolicy.AllowCallPark
            'Description'                    = $CsTeamsCallingPolicy.Description
        }
    } else {
        [ordered]@{AllowPrivateCalling = $CsTeamsCallingPolicy.AllowPrivateCalling
            AllowVoicemail             = $CsTeamsCallingPolicy.AllowVoicemail
            AllowCallGroups            = $CsTeamsCallingPolicy.AllowCallGroups
            AllowDelegation            = $CsTeamsCallingPolicy.AllowDelegation
            AllowCallForwardingToUser  = $CsTeamsCallingPolicy.AllowCallForwardingToUser
            AllowCallForwardingToPhone = $CsTeamsCallingPolicy.AllowCallForwardingToPhone
            PreventTollBypass          = $CsTeamsCallingPolicy.PreventTollBypass
            BusyOnBusyEnabledType      = $CsTeamsCallingPolicy.BusyOnBusyEnabledType
            AllowCallPark              = $CsTeamsCallParkPolicy.AllowCallPark
            Description                = $CsTeamsCallingPolicy.Description
        }
    }
}
function Get-WinTeamsSettingsChannels {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $ChannelsPolicy = & "Get-$($prefix)CsTeamsChannelsPolicy" -Tenant $Tenant -Identity Global } else { $ChannelsPolicy = & "Get-$($prefix)CsTeamsChannelsPolicy" -Identity Global }
    foreach ($_ in $ChannelsPolicy) {
        if ($Formatted) {
            [ordered]@{'Allow Teams Creation'    = $_.AllowOrgWideTeamCreation
                'Allow Private Team Discovery'   = $_.AllowPrivateTeamDiscovery
                'Allow Private Channel Creation' = $_.AllowPrivateChannelCreation
                'Scope Class'                    = $_.ScopeClass
                'Description'                    = $_.Description
            }
        } else {
            [ordered]@{AllowOrgWideTeamCreation = $_.AllowOrgWideTeamCreation
                AllowPrivateTeamDiscovery       = $_.AllowPrivateTeamDiscovery
                AllowPrivateChannelCreation     = $_.AllowPrivateChannelCreation
                ScopeClass                      = $_.ScopeClass
                Description                     = $_.Description
            }
        }
    }
}
function Get-WinTeamsSettingsEducationAppPolicy {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsEducationAssignmentsAppPolicy = & "Get-$($prefix)CsTeamsEducationAssignmentsAppPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsEducationAssignmentsAppPolicy = & "Get-$($prefix)CsTeamsEducationAssignmentsAppPolicy" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Parent Digest Enabled Type' = $CsTeamsEducationAssignmentsAppPolicy.ParentDigestEnabledType
            'Make Code Enabled Type'            = $CsTeamsEducationAssignmentsAppPolicy.MakeCodeEnabledType
            'Turn It In Enabled Type'           = $CsTeamsEducationAssignmentsAppPolicy.TurnItInEnabledType
            'Turn It In Api Url'                = $CsTeamsEducationAssignmentsAppPolicy.TurnItInApiUrl
            'Turn It In Api Key'                = $CsTeamsEducationAssignmentsAppPolicy.TurnItInApiKey
        }
    } else {
        [ordered]@{ParentDigestEnabledType = $CsTeamsEducationAssignmentsAppPolicy.ParentDigestEnabledType
            MakeCodeEnabledType            = $CsTeamsEducationAssignmentsAppPolicy.MakeCodeEnabledType
            TurnItInEnabledType            = $CsTeamsEducationAssignmentsAppPolicy.TurnItInEnabledType
            TurnItInApiUrl                 = $CsTeamsEducationAssignmentsAppPolicy.TurnItInApiUrl
            TurnItInApiKey                 = $CsTeamsEducationAssignmentsAppPolicy.TurnItInApiKey
        }
    }
}
function Get-WinTeamsSettingsFileSharing {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [Array] $TeamsConfiguration,
        [switch] $Formatted)
    if (-not $TeamsConfiguration) { if ($Tenant) { $TeamsConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Tenant $Tenant -Identity Global } else { $TeamsConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Identity Global } }
    foreach ($_ in $TeamsConfiguration) {
        if ($Formatted) {
            [ordered]@{'Allow DropBox' = $_.AllowDropBox
                'Allow Box'            = $_.AllowBox
                'Allow GoogleDrive'    = $_.AllowGoogleDrive
                'Allow Share File'     = $_.AllowShareFile
            }
        } else {
            [ordered]@{AllowDropBox = $_.AllowDropBox
                AllowBox            = $_.AllowBox
                AllowGoogleDrive    = $_.AllowGoogleDrive
                AllowShareFile      = $_.AllowShareFile
            }
        }
    }
}
function Get-WinTeamsSettingsGuests {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsGuestMessagingConfiguration = & "Get-$($prefix)CsTeamsGuestMessagingConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsGuestMessagingConfiguration = & "Get-$($prefix)CsTeamsGuestMessagingConfiguration" -Identity Global }
    if ($Tenant) { $CsTeamsGuestMeetingConfiguration = & "Get-$($prefix)CsTeamsGuestMeetingConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsGuestMeetingConfiguration = & "Get-$($prefix)CsTeamsGuestMeetingConfiguration" -Identity Global }
    if ($Tenant) { $CsTeamsGuestCallingConfiguration = & "Get-$($prefix)CsTeamsGuestCallingConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsGuestCallingConfiguration = & "Get-$($prefix)CsTeamsGuestCallingConfiguration" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Allow User Edit Message' = $CsTeamsGuestMessagingConfiguration.AllowUserEditMessage
            'Allow User Delete Message'      = $CsTeamsGuestMessagingConfiguration.AllowUserDeleteMessage
            'Allow User Chat'                = $CsTeamsGuestMessagingConfiguration.AllowUserChat
            'Allow Giphy'                    = $CsTeamsGuestMessagingConfiguration.AllowGiphy
            'Giphy Rating Type'              = Format-AddSpaceToSentence -Text $CsTeamsGuestMessagingConfiguration.GiphyRatingType
            'Allow Memes'                    = $CsTeamsGuestMessagingConfiguration.AllowMemes
            'Allow Immersive Reader'         = $CsTeamsGuestMessagingConfiguration.AllowImmersiveReader
            'Allow Stickers'                 = $CsTeamsGuestMessagingConfiguration.AllowStickers
            'Allow IPVideo'                  = $CsTeamsGuestMeetingConfiguration.AllowIPVideo
            'Screen Sharing Mode'            = Format-AddSpaceToSentence -Text $CsTeamsGuestMeetingConfiguration.ScreenSharingMode
            'Allow MeetNow'                  = $CsTeamsGuestMeetingConfiguration.AllowMeetNow
            'Allow Private Calling'          = $CsTeamsGuestCallingConfiguration.AllowPrivateCalling
        }
    } else {
        [ordered]@{AllowUserEditMessage = $CsTeamsGuestMessagingConfiguration.AllowUserEditMessage
            AllowUserDeleteMessage      = $CsTeamsGuestMessagingConfiguration.AllowUserDeleteMessage
            AllowUserChat               = $CsTeamsGuestMessagingConfiguration.AllowUserChat
            AllowGiphy                  = $CsTeamsGuestMessagingConfiguration.AllowGiphy
            GiphyRatingType             = $CsTeamsGuestMessagingConfiguration.GiphyRatingType
            AllowMemes                  = $CsTeamsGuestMessagingConfiguration.AllowMemes
            AllowImmersiveReader        = $CsTeamsGuestMessagingConfiguration.AllowImmersiveReader
            AllowStickers               = $CsTeamsGuestMessagingConfiguration.AllowStickers
            AllowIPVideo                = $CsTeamsGuestMeetingConfiguration.AllowIPVideo
            ScreenSharingMode           = $CsTeamsGuestMeetingConfiguration.ScreenSharingMode
            AllowMeetNow                = $CsTeamsGuestMeetingConfiguration.AllowMeetNow
            AllowPrivateCalling         = $CsTeamsGuestCallingConfiguration.AllowPrivateCalling
        }
    }
}
function Get-WinTeamsSettingsMeetings {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsMeetingPolicy = & "Get-$($prefix)CsTeamsMeetingPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsMeetingPolicy = & "Get-$($prefix)CsTeamsMeetingPolicy" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Allow Channel Meeting Scheduling'         = $CsTeamsMeetingPolicy.AllowChannelMeetingScheduling
            'Allow MeetNow'                                   = $CsTeamsMeetingPolicy.AllowMeetNow
            'Allow Private MeetNow'                           = $CsTeamsMeetingPolicy.AllowPrivateMeetNow
            'Meeting Chat Enabled Type'                       = $CsTeamsMeetingPolicy.MeetingChatEnabledType
            'Live Captions Enabled Type'                      = $CsTeamsMeetingPolicy.LiveCaptionsEnabledType
            'Allow IPVideo'                                   = $CsTeamsMeetingPolicy.AllowIPVideo
            'Allow Anonymous Users To DialOut'                = $CsTeamsMeetingPolicy.AllowAnonymousUsersToDialOut
            'Allow Anonymous Users To StartMeeting'           = $CsTeamsMeetingPolicy.AllowAnonymousUsersToStartMeeting
            'Allow Private Meeting Scheduling'                = $CsTeamsMeetingPolicy.AllowPrivateMeetingScheduling
            'Auto Admitted Users'                             = Format-AddSpaceToSentence -Text $CsTeamsMeetingPolicy.AutoAdmittedUsers
            'Allow Cloud Recording'                           = $CsTeamsMeetingPolicy.AllowCloudRecording
            'Allow Outlook AddIn'                             = $CsTeamsMeetingPolicy.AllowOutlookAddIn
            'Allow PowerPoint Sharing'                        = $CsTeamsMeetingPolicy.AllowPowerPointSharing
            'Allow Participant Give Request Control'          = $CsTeamsMeetingPolicy.AllowParticipantGiveRequestControl
            'Allow External Participant Give Request Control' = $CsTeamsMeetingPolicy.AllowExternalParticipantGiveRequestControl
            'Allow Shared Notes'                              = $CsTeamsMeetingPolicy.AllowSharedNotes
            'Allow Whiteboard'                                = $CsTeamsMeetingPolicy.AllowWhiteboard
            'Allow Transcription'                             = $CsTeamsMeetingPolicy.AllowTranscription
            'Media Bit RateKb'                                = $CsTeamsMeetingPolicy.MediaBitRateKb
            'Screen Sharing Mode'                             = Format-AddSpaceToSentence -Text $CsTeamsMeetingPolicy.ScreenSharingMode
            'Allow PSTN Users To Bypass Lobby'                = $CsTeamsMeetingPolicy.AllowPSTNUsersToBypassLobby
            'Allow Organizers To Override Lobby Settings'     = $CsTeamsMeetingPolicy.AllowOrganizersToOverrideLobbySettings
            'Description'                                     = $CsTeamsMeetingPolicy.Description
        }
    } else {
        [ordered]@{AllowChannelMeetingScheduling       = $CsTeamsMeetingPolicy.AllowChannelMeetingScheduling
            AllowMeetNow                               = $CsTeamsMeetingPolicy.AllowMeetNow
            AllowPrivateMeetNow                        = $CsTeamsMeetingPolicy.AllowPrivateMeetNow
            MeetingChatEnabledType                     = $CsTeamsMeetingPolicy.MeetingChatEnabledType
            LiveCaptionsEnabledType                    = $CsTeamsMeetingPolicy.LiveCaptionsEnabledType
            AllowIPVideo                               = $CsTeamsMeetingPolicy.AllowIPVideo
            AllowAnonymousUsersToDialOut               = $CsTeamsMeetingPolicy.AllowAnonymousUsersToDialOut
            AllowAnonymousUsersToStartMeeting          = $CsTeamsMeetingPolicy.AllowAnonymousUsersToStartMeeting
            AllowPrivateMeetingScheduling              = $CsTeamsMeetingPolicy.AllowPrivateMeetingScheduling
            AutoAdmittedUsers                          = $CsTeamsMeetingPolicy.AutoAdmittedUsers
            AllowCloudRecording                        = $CsTeamsMeetingPolicy.AllowCloudRecording
            AllowOutlookAddIn                          = $CsTeamsMeetingPolicy.AllowOutlookAddIn
            AllowPowerPointSharing                     = $CsTeamsMeetingPolicy.AllowPowerPointSharing
            AllowParticipantGiveRequestControl         = $CsTeamsMeetingPolicy.AllowParticipantGiveRequestControl
            AllowExternalParticipantGiveRequestControl = $CsTeamsMeetingPolicy.AllowExternalParticipantGiveRequestControl
            AllowSharedNotes                           = $CsTeamsMeetingPolicy.AllowSharedNotes
            AllowWhiteboard                            = $CsTeamsMeetingPolicy.AllowWhiteboard
            AllowTranscription                         = $CsTeamsMeetingPolicy.AllowTranscription
            MediaBitRateKb                             = $CsTeamsMeetingPolicy.MediaBitRateKb
            ScreenSharingMode                          = $CsTeamsMeetingPolicy.ScreenSharingMode
            AllowPSTNUsersToBypassLobby                = $CsTeamsMeetingPolicy.AllowPSTNUsersToBypassLobby
            AllowOrganizersToOverrideLobbySettings     = $CsTeamsMeetingPolicy.AllowOrganizersToOverrideLobbySettings
            Description                                = $CsTeamsMeetingPolicy.Description
        }
    }
}
function Get-WinTeamsSettingsMeetingsTechnical {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsMeetingConfiguration = & "Get-$($prefix)CsTeamsMeetingConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsMeetingConfiguration = & "Get-$($prefix)CsTeamsMeetingConfiguration" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Disable Anonymous Join'   = $CsTeamsMeetingConfiguration.DisableAnonymousJoin
            'Enable QoS'                      = $CsTeamsMeetingConfiguration.EnableQoS
            'Client Audio Port'               = $CsTeamsMeetingConfiguration.ClientAudioPort
            'Client Audio Port Range'         = $CsTeamsMeetingConfiguration.ClientAudioPortRange
            'Client Video Port'               = $CsTeamsMeetingConfiguration.ClientVideoPort
            'Client Video Port Range'         = $CsTeamsMeetingConfiguration.ClientVideoPortRange
            'Client AppSharing Port'          = $CsTeamsMeetingConfiguration.ClientAppSharingPort
            'Client AppSharing Port Range'    = $CsTeamsMeetingConfiguration.ClientAppSharingPortRange
            'Client Media Port Range Enabled' = $CsTeamsMeetingConfiguration.ClientMediaPortRangeEnabled
            'Logo URL'                        = $CsTeamsMeetingConfiguration.LogoURL
            'Legal URL'                       = $CsTeamsMeetingConfiguration.LegalURL
            'Help URL'                        = $CsTeamsMeetingConfiguration.HelpURL
            'Custom Footer Text'              = $CsTeamsMeetingConfiguration.CustomFooterText
        }
    } else {
        [ordered]@{DisableAnonymousJoin = $CsTeamsMeetingConfiguration.DisableAnonymousJoin
            EnableQoS                   = $CsTeamsMeetingConfiguration.EnableQoS
            ClientAudioPort             = $CsTeamsMeetingConfiguration.ClientAudioPort
            ClientAudioPortRange        = $CsTeamsMeetingConfiguration.ClientAudioPortRange
            ClientVideoPort             = $CsTeamsMeetingConfiguration.ClientVideoPort
            ClientVideoPortRange        = $CsTeamsMeetingConfiguration.ClientVideoPortRange
            ClientAppSharingPort        = $CsTeamsMeetingConfiguration.ClientAppSharingPort
            ClientAppSharingPortRange   = $CsTeamsMeetingConfiguration.ClientAppSharingPortRange
            ClientMediaPortRangeEnabled = $CsTeamsMeetingConfiguration.ClientMediaPortRangeEnabled
            LogoURL                     = $CsTeamsMeetingConfiguration.LogoURL
            LegalURL                    = $CsTeamsMeetingConfiguration.LegalURL
            HelpURL                     = $CsTeamsMeetingConfiguration.HelpURL
            CustomFooterText            = $CsTeamsMeetingConfiguration.CustomFooterText
        }
    }
}
function Get-WinTeamsSettingsUpgrade {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $TeamsUpgradePolicy = & "Get-$($prefix)CsTeamsUpgradePolicy" -Tenant $Tenant -Identity Global } else { $TeamsUpgradePolicy = & "Get-$($prefix)CsTeamsUpgradePolicy" -Identity Global }
    if ($Tenant) { $CsTeamsUpgradeConfiguration = & "Get-$($prefix)CsTeamsUpgradeConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsUpgradeConfiguration = & "Get-$($prefix)CsTeamsUpgradeConfiguration" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Description'    = $TeamsUpgradePolicy.Description
            'Mode'                  = Format-AddSpaceToSentence -Text $TeamsUpgradePolicy.Mode
            'Notify Skype Users'    = $TeamsUpgradePolicy.NotifySfbUsers
            'Download Teams'        = $CsTeamsUpgradeConfiguration.DownloadTeams
            'Skype Meeting Join Ux' = Format-AddSpaceToSentence -Text $CsTeamsUpgradeConfiguration.SfBMeetingJoinUx
        }
    } else {
        [ordered]@{Description = $TeamsUpgradePolicy.Description
            Mode               = $TeamsUpgradePolicy.Mode
            NotifySfbUsers     = $TeamsUpgradePolicy.NotifySfbUsers
            DownloadTeams      = $CsTeamsUpgradeConfiguration.DownloadTeams
            SfBMeetingJoinUx   = $CsTeamsUpgradeConfiguration.SfBMeetingJoinUx
        }
    }
}
function Get-WinTeamsSettingsUsers {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant,
        [switch] $Formatted)
    if ($Tenant) { $CsTeamsMessagingPolicy = & "Get-$($prefix)CsTeamsMessagingPolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsMessagingPolicy = & "Get-$($prefix)CsTeamsMessagingPolicy" -Identity Global }
    if ($Formatted) {
        [ordered]@{'Description'                 = $CsTeamsMessagingPolicy.Description
            'Allow Url Previews'                 = $CsTeamsMessagingPolicy.AllowUrlPreviews
            'Allow Owner Delete Message'         = $CsTeamsMessagingPolicy.AllowOwnerDeleteMessage
            'Allow User EditMessage'             = $CsTeamsMessagingPolicy.AllowUserEditMessage
            'Allow User DeleteMessage'           = $CsTeamsMessagingPolicy.AllowUserDeleteMessage
            'Allow User Chat'                    = $CsTeamsMessagingPolicy.AllowUserChat
            'Allow Remove User'                  = $CsTeamsMessagingPolicy.AllowRemoveUser
            'Allow Giphy'                        = $CsTeamsMessagingPolicy.AllowGiphy
            'Giphy Rating Type'                  = $CsTeamsMessagingPolicy.GiphyRatingType
            'Allow Memes'                        = $CsTeamsMessagingPolicy.AllowMemes
            'Allow Immersive Reader'             = $CsTeamsMessagingPolicy.AllowImmersiveReader
            'Allow Stickers'                     = $CsTeamsMessagingPolicy.AllowStickers
            'Allow User Translation'             = $CsTeamsMessagingPolicy.AllowUserTranslation
            'Read Receipts Enabled Type'         = Format-AddSpaceToSentence -Text $CsTeamsMessagingPolicy.ReadReceiptsEnabledType
            'Allow Priority Messages'            = $CsTeamsMessagingPolicy.AllowPriorityMessages
            'Channels In Chat List Enabled Type' = Format-AddSpaceToSentence -Text $CsTeamsMessagingPolicy.ChannelsInChatListEnabledType
            'Audio Message Enabled Type'         = Format-AddSpaceToSentence -Text $CsTeamsMessagingPolicy.AudioMessageEnabledType
        }
    } else {
        [ordered]@{Description            = $CsTeamsMessagingPolicy.Description
            AllowUrlPreviews              = $CsTeamsMessagingPolicy.AllowUrlPreviews
            AllowOwnerDeleteMessage       = $CsTeamsMessagingPolicy.AllowOwnerDeleteMessage
            AllowUserEditMessage          = $CsTeamsMessagingPolicy.AllowUserEditMessage
            AllowUserDeleteMessage        = $CsTeamsMessagingPolicy.AllowUserDeleteMessage
            AllowUserChat                 = $CsTeamsMessagingPolicy.AllowUserChat
            AllowRemoveUser               = $CsTeamsMessagingPolicy.AllowRemoveUser
            AllowGiphy                    = $CsTeamsMessagingPolicy.AllowGiphy
            GiphyRatingType               = $CsTeamsMessagingPolicy.GiphyRatingType
            AllowMemes                    = $CsTeamsMessagingPolicy.AllowMemes
            AllowImmersiveReader          = $CsTeamsMessagingPolicy.AllowImmersiveReader
            AllowStickers                 = $CsTeamsMessagingPolicy.AllowStickers
            AllowUserTranslation          = $CsTeamsMessagingPolicy.AllowUserTranslation
            ReadReceiptsEnabledType       = $CsTeamsMessagingPolicy.ReadReceiptsEnabledType
            AllowPriorityMessages         = $CsTeamsMessagingPolicy.AllowPriorityMessages
            ChannelsInChatListEnabledType = $CsTeamsMessagingPolicy.ChannelsInChatListEnabledType
            AudioMessageEnabledType       = $CsTeamsMessagingPolicy.AudioMessageEnabledType
        }
    }
}
function Get-WinUAzureADUsers {
    [CmdletBinding()]
    param([string] $Tenant,
        [string] $Prefix)
    if ($Tenant) { $MsolUsers = & "Get-$($prefix)MsolUser" -All -TenantId $Tenant } else { $MsolUsers = & "Get-$($prefix)MsolUser" -All }
    $MsolUsers
}
function Get-WinUAzureADUsersDeleted {
    [CmdletBinding()]
    param([string] $Tenant,
        [string] $Prefix)
    if ($Tenant) { $MsolUsers = & "Get-$($prefix)MsolUser" -ReturnDeletedUsers -TenantId $Tenant } else { $MsolUsers = & "Get-$($prefix)MsolUser" -ReturnDeletedUsers }
    $MsolUsers
}
function Get-WinUAzureLicensing {
    [CmdletBinding()]
    param([string] $Tenant,
        [string] $Prefix)
    if ($Tenant) { $UAzureLicensing = & "Get-$($Prefix)MsolAccountSku" -TenantId $Tenant } else { $UAzureLicensing = & "Get-$($Prefix)MsolAccountSku" }
    $UAzureLicensing
}
function Get-WinUAzureRoles {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant)
    if ($Tenant) { $MsolRoles = & "Get-$($prefix)MsolRole" -TenantId $Tenant | Sort-Object -Property Name } else { $MsolRoles = & "Get-$($prefix)MsolRole" | Sort-Object -Property Name }
    $MsolRoles
}
function Get-WinUAzureSubscription {
    [CmdletBinding()]
    param([string] $Tenant,
        [string] $Prefix)
    if ($Tenant) { $UAzureSubscription = & "Get-$($prefix)MsolSubscription" -TenantId $Tenant } else { $UAzureSubscription = & "Get-$($prefix)MsolSubscription" }
    $UAzureSubscription
}
function Get-WinUExchangeMailUsers {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeMailUsers = & "Get-$($Prefix)MailUser" -ResultSize unlimited
    return $UExchangeMailUsers
}
function Get-WinUExchangeRecipients {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeRecipients = & "Get-$($prefix)Recipient" -ResultSize unlimited
    return $UExchangeRecipients
}
function Get-WinUExchangeRoomsCalendarProcessing {
    [CmdletBinding()]
    param([string] $Prefix,
        [Array] $UExchangeMailboxesRooms)
    $Output = @(foreach ($Mailbox in $UExchangeMailboxesRooms) {
            $Object = & "Get-$($prefix)CalendarProcessing" -Identity $Mailbox.PrimarySmtpAddress -ResultSize unlimited
            if ($Object) {
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxPrimarySmtpAddress" -Value $Mailbox.PrimarySmtpAddress
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxAlias" -Value $Mailbox.Alias
                $Object | Add-Member -MemberType NoteProperty -Name "MailboxGUID" -Value $Mailbox.GUID
                $Object
            }
        })
    $Output
}
function Get-WinUExchangeUnifiedGroups {
    [CmdletBinding()]
    param()
    $ExchangeUnifiedGroups = Get-UnifiedGroup -ResultSize Unlimited -IncludeAllProperties
    $ExchangeUnifiedGroups
}
function Get-WinUExchangeUsers {
    [CmdletBinding()]
    param([string] $Prefix)
    $UExchangeUsers = & "Get-$($prefix)User" -ResultSize unlimited
    return $UExchangeUsers
}
function Get-WinUTeamsConfiguration {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant)
    if ($Tenant) { $CsTeamsClientConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Tenant $Tenant -Identity Global } else { $CsTeamsClientConfiguration = & "Get-$($prefix)CsTeamsClientConfiguration" -Identity Global }
    return $CsTeamsClientConfiguration
}
function Get-WinUTeamsVideoInteropService {
    [CmdletBinding()]
    param([string] $Prefix,
        [string] $Tenant)
    if ($Tenant) { $CsTeamsVideoInteropServicePolicy = & "Get-$($prefix)CsTeamsVideoInteropServicePolicy" -Tenant $Tenant -Identity Global } else { $CsTeamsVideoInteropServicePolicy = & "Get-$($prefix)CsTeamsVideoInteropServicePolicy" -Identity Global }
    return $CsTeamsVideoInteropServicePolicy
}
function Get-WinO365 {
    [CmdletBinding()]
    param([PSWinDocumentation.O365[]] $TypesRequired,
        [string] $Prefix,
        [validateset("Bytes", "KB", "MB", "GB", "TB")][string]$SizeIn = 'MB',
        [alias('Precision')][int]$SizePrecision = 2,
        [switch] $Formatted,
        [switch] $SkipAvailability,
        [string] $Splitter = ', ',
        [string] $Tenant)
    $PSDefaultParameterValues["Get-DataInformation:Verbose"] = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
    $TimeToGenerate = Start-TimeLog
    if ($null -eq $TypesRequired) {
        Write-Verbose 'Get-WinO365 - TypesRequired is null. Getting all.'
        $TypesRequired = Get-Types -Types ([PSWinDocumentation.O365])
    }
    if (-not $SkipAvailability) {
        $Commands = Test-AvailabilityCommands -Commands "Get-$($Prefix)Mailbox", "Get-$($Prefix)MsolUser", "Get-$($Prefix)MailboxStatistics"
        if ($Commands -contains $false) {
            Write-Warning "Get-WinO365 - One of commands Get-$($Prefix)Mailbox, Get-$($Prefix)MsolUser, Get-$($Prefix)MailboxStatistics is not available. Make sure connectivity to Office 365 exists."
            return
        }
    }
    $Data = @{ }
    $Data.Objects = [ordered]@{ }
    $Data.UAzureADUsers = Get-DataInformation -Text "Getting O365 information - UAzureADUsers" { Get-WinUAzureADUsers -Tenant $Tenant } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureADUsers
        [PSWinDocumentation.O365]::AzureADUsers
        [PSWinDocumentation.O365]::AzureADUsersMFA
        [PSWinDocumentation.O365]::AzureADUsersStatisticsByCountry
        [PSWinDocumentation.O365]::AzureADUsersStatisticsByCity
        [PSWinDocumentation.O365]::AzureADUsersStatisticsByCountryCity
        [PSWinDocumentation.O365]::ExchangeMailboxes
        [PSWinDocumentation.O365]::AzureRolesMembers
        [PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly
        [PSWinDocumentation.O365]::AzureADGuests)
    $Data.UAzureADUsersDeleted = Get-DataInformation -Text "Getting O365 information - UAzureADUsersDeleted" { Get-WinUAzureADUsersDeleted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureADUsersDeleted)
    $Data.UAzureADContacts = Get-DataInformation -Text "Getting O365 information - UAzureADContacts" { Get-WinUAzureADContacts } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureADContacts)
    $Data.UAzureLicensing = Get-DataInformation -Text "Getting O365 information - UAzureLicensing" { Get-WinUAzureLicensing } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureLicensing
        [PSWinDocumentation.O365]::AzureLicensing)
    $Data.UAzureSubscription = Get-DataInformation -Text "Getting O365 information - UAzureSubscription" { Get-WinUAzureSubscription } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureSubscription)
    $Data.UAzureTenantDomains = Get-DataInformation -Text "Getting O365 information - UAzureTenantDomains" { Get-WinUAzureTenantDomains } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureTenantDomains
        [PSWinDocumentation.O365]::AzureTenantDomains)
    $Data.UAzureADGroups = Get-DataInformation -Text "Getting O365 information - UAzureADGroups" { Get-WinUAzureADGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureADGroups
        [PSWinDocumentation.O365]::AzureADGroupMembers)
    $Data.AzureADUsersMFA = Get-DataInformation -Text "Getting O365 information - AzureADUsersMFA" { Get-WinAzureADUsersMFA -UAzureADUsers $Data.UAzureADUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADUsersMFA)
    $Data.AzureADUsers = Get-DataInformation -Text "Getting O365 information - AzureADUsers" { Get-WinAzureUsers -MsolUsers $Data.UAzureADUsers -Prefix $Prefix -Formatted:$Formatted -Splitter $Splitter -Users $Data.Objects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADUsers
        [PSWinDocumentation.O365]::AzureRolesMembers
        [PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly
        [PSWinDocumentation.O365]::AzureADGroupMembers)
    $Data.AzureADGuests = Get-DataInformation -Text "Getting O365 information - AzureADGuests" { Get-WinAzureGuests -MsolUsers $Data.UAzureADUsers -Prefix $Prefix -Formatted:$Formatted -Splitter $Splitter -Users $Data.Objects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADGuests
        [PSWinDocumentation.O365]::AzureRolesMembers
        [PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly
        [PSWinDocumentation.O365]::AzureADGroupMembers)
    $Data.AzureADGroupMembers = Get-DataInformation -Text "Getting O365 information - AzureADGroupMembers" { Get-WinAzureADGroupMembers -UAzureADGroups $Data.UAzureADGroups -Users $Data.Objects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADGroupMembers)
    $Data.UAzureRoles = Get-DataInformation -Text "Getting O365 information - UAzureRoles" { Get-WinUAzureRoles -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UAzureRoles
        [PSWinDocumentation.O365]::AzureRolesMembers
        [PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly)
    $Data.AzureRolesMembers = Get-DataInformation -Text "Getting O365 information - AzureRolesMembers" { Get-WinAzureRolesMembers -MsolRoles $Data.UAzureRoles -Prefix $Prefix -Formatted:$Formatted -Users $Data.Objects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureRolesMembers
        [PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly)
    $Data.AzureRoles = Get-DataInformation -Text "Getting O365 information - AzureRoles" { Get-WinAzureRoles -MsolRoles $Data.UAzureRoles -AzureRolesMembers $Data.AzureRolesMembers -Prefix $Prefix -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureRoles
        [PSWinDocumentation.O365]::AzureRolesActiveOnly)
    $Data.AzureRolesActiveOnly = Get-DataInformation -Text "Getting O365 information - AzureRolesActiveOnly" { Get-WinAzureRolesActiveOnly -AzureRoles $Data.AzureRoles -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureRolesActiveOnly)
    $Data.AzureADUsersStatisticsByCountry = Get-DataInformation -Text "Getting O365 information - AzureADUsersStatisticsByCountry" { Get-WinAzureADUsersStatisticsByCountry -UAzureADUsers $Data.UAzureADUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADUsersStatisticsByCountry)
    $Data.AzureADUsersStatisticsByCity = Get-DataInformation -Text "Getting O365 information - AzureADUsersStatisticsByCity" { Get-WinAzureADUsersStatisticsByCity -UAzureADUsers $Data.UAzureADUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADUsersStatisticsByCity)
    $Data.AzureADUsersStatisticsByCountryCity = Get-DataInformation -Text "Getting O365 information - AzureADUsersStatisticsByCountryCity" { Get-WinAzureADUsersStatisticsByCountryCity -UAzureADUsers $Data.UAzureADUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureADUsersStatisticsByCountryCity)
    $Data.UExchangeMailBoxes = Get-DataInformation -Text "Getting O365 information - UExchangeMailBoxes" { Get-WinUExchangeMailBoxes -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailBoxes
        [PSWinDocumentation.O365]::UExchangeMailboxesJunk
        [PSWinDocumentation.O365]::UExchangeMailboxesRooms
        [PSWinDocumentation.O365]::UExchangeMailboxesEquipment
        [PSWinDocumentation.O365]::UExchangeMailboxesInboxRules
        [PSWinDocumentation.O365]::ExchangeMailboxesInboxRulesForwarding
        [PSWinDocumentation.O365]::ExchangeMailboxesStatistics
        [PSWinDocumentation.O365]::ExchangeMailboxesStatisticsArchive
        [PSWinDocumentation.O365]::ExchangeMailboxes)
    $Data.UExchangeMailUsers = Get-DataInformation -Text "Getting O365 information - UExchangeMailUsers" { Get-WinUExchangeMailUsers -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailUsers)
    $Data.UExchangeUsers = Get-DataInformation -Text "Getting O365 information - UExchangeUsers" { Get-WinUExchangeUsers -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeUsers)
    $Data.UExchangeRecipients = Get-DataInformation -Text "Getting O365 information - UExchangeRecipients" { Get-WinUExchangeRecipients -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeRecipients)
    $Data.UExchangeRecipientsPermissions = Get-DataInformation -Text "Getting O365 information - UExchangeRecipientsPermissions" { Get-WinUExchangeRecipientsPermissions -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeRecipientsPermissions)
    $Data.UExchangeGroupsDistribution = Get-DataInformation -Text "Getting O365 information - UExchangeGroupsDistribution" { Get-WinUExchangeGroupsDistribution -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeGroupsDistribution
        [PSWinDocumentation.O365]::UExchangeGroupsDistributionMembers
        [PSWinDocumentation.O365]::ExchangeDistributionGroups
        [PSWinDocumentation.O365]::ExchangeDistributionGroupsMembers)
    $Data.UExchangeGroupsDistributionDynamic = Get-DataInformation -Text "Getting O365 information - UExchangeGroupsDistributionDynamic" { Get-WinUExchangeGroupsDistributionDynamic -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeGroupsDistributionDynamic)
    $Data.UExchangeGroupsDistributionMembers = Get-DataInformation -Text "Getting O365 information - UExchangeGroupsDistributionMembers" { Get-WinUExchangeGroupsDistributionMembers -Prefix $Prefix -UExchangeGroupsDistribution $Data.UExchangeGroupsDistribution } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeGroupsDistributionMembers)
    $Data.UExchangeMailboxesJunk = Get-DataInformation -Text "Getting O365 information - UExchangeMailboxesJunk" { Get-WinUExchangeMailboxesJunk -Prefix $Prefix -UExchangeMailBoxes $Data.UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailboxesJunk)
    $Data.UExchangeContacts = Get-DataInformation -Text "Getting O365 information - UExchangeContacts" { Get-WinUExchangeContacts -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeContacts)
    $Data.UExchangeMailboxesInboxRules = Get-DataInformation -Text "Getting O365 information - UExchangeMailboxesInboxRules" { Get-WinUExchangeMailboxesInboxRules -Prefix $Prefix -UExchangeMailBoxes $Data.UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailboxesInboxRules
        [PSWinDocumentation.O365]::ExchangeMailboxesInboxRulesForwarding)
    $Data.UExchangeContactsMail = Get-DataInformation -Text "Getting O365 information - UExchangeContactsMail" { Get-WinUExchangeContactsMail -Prefix $Prefix } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeContactsMail)
    $Data.UExchangeMailboxesRooms = Get-DataInformation -Text "Getting O365 information - UExchangeMailboxesRooms" { Get-WinUExchangeMailboxesRooms -UExchangeMailBoxes $UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailboxesRooms
        [PSWinDocumentation.O365]::UExchangeRoomsCalendarProcessing)
    $Data.UExchangeMailboxesEquipment = Get-DataInformation -Text "Getting O365 information - UExchangeMailboxesEquipment" { Get-WinUExchangeMailboxesEquipment -UExchangeMailBoxes $UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeMailboxesEquipment
        [PSWinDocumentation.O365]::UExchangeEquipmentCalendarProcessing)
    $Data.UExchangeRoomsCalendarProcessing = Get-DataInformation -Text "Getting O365 information - UExchangeMailboxesRooms" { Get-WinUExchangeRoomsCalendarProcessing -Prefix $Prefix -UExchangeMailboxesRooms $Data.UExchangeMailboxesRooms } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeRoomsCalendarProcessing)
    $Data.UExchangeEquipmentCalendarProcessing = Get-DataInformation -Text "Getting O365 information - UExchangeEquipmentCalendarProcessing" { Get-WinUExchangeEquipmentCalendarProcessing -Prefix $Prefix -UExchangeMailboxesEquipment $Data.UExchangeMailboxesEquipment } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeEquipmentCalendarProcessing)
    $Data.UTeamsConfiguration = Get-DataInformation -Text "Getting O365 information - UTeamsConfiguration" { Get-WinUTeamsConfiguration -Prefix $Prefix -Tenant $Tenant } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UTeamsConfiguration
        [PSWinDocumentation.O365]::TeamsSettings
        [PSWinDocumentation.O365]::TeamsSettingsFileSharing)
    $Data.TeamsSettings = Get-DataInformation -Text "Getting O365 information - TeamsSettings" { Get-WinTeamsSettings -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted -TeamsConfiguration $Data.TeamsConfiguration } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettings)
    $Data.TeamsSettingsBroadcasting = Get-DataInformation -Text "Getting O365 information - TeamsSettingsBroadcasting" { Get-WinTeamsSettingsBroadcasting -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsBroadcasting)
    $Data.TeamsSettingsCalling = Get-DataInformation -Text "Getting O365 information - TeamsSettingsCalling" { Get-WinTeamsSettingsCalling -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsCalling)
    $Data.TeamsSettingsChannels = Get-DataInformation -Text "Getting O365 information - TeamsSettingsChannels" { Get-WinTeamsSettingsChannels -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsChannels)
    $Data.TeamsSettingsEducationAppPolicy = Get-DataInformation -Text "Getting O365 information - TeamsSettingsEducationAppPolicy" { Get-WinTeamsSettingsEducationAppPolicy -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsEducationAppPolicy)
    $Data.TeamsSettingsFileSharing = Get-DataInformation -Text "Getting O365 information - TeamsSettingsFileSharing" { Get-WinTeamsSettingsFileSharing -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted -TeamsConfiguration $Data.TeamsConfiguration } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsFileSharing)
    $Data.TeamsSettingsGuests = Get-DataInformation -Text "Getting O365 information - TeamsSettingsGuests" { Get-WinTeamsSettingsGuests -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsGuests)
    $Data.TeamsSettingsMeetings = Get-DataInformation -Text "Getting O365 information - TeamsSettingsMeetings" { Get-WinTeamsSettingsMeetings -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsMeetings)
    $Data.TeamsSettingsMeetingsTechnical = Get-DataInformation -Text "Getting O365 information - TeamsSettingsMeetingsTechnical" { Get-WinTeamsSettingsMeetingsTechnical -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsMeetingsTechnical)
    $Data.TeamsSettingsUpgrade = Get-DataInformation -Text "Getting O365 information - TeamsSettingsUpgrade" { Get-WinTeamsSettingsUpgrade -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsUpgrade)
    $Data.TeamsSettingsUsers = Get-DataInformation -Text "Getting O365 information - TeamsSettingsUsers" { Get-WinTeamsSettingsUsers -Prefix $Prefix -Tenant $Tenant -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::TeamsSettingsUsers)
    $Data.AzureLicensing = Get-DataInformation -Text "Getting O365 information - AzureLicensing" { Get-WinAzureLicensing -UAzureLicensing $Data.UAzureLicensing -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureLicensing)
    $Data.AzureSubscription = Get-DataInformation -Text "Getting O365 information - AzureSubscription" { Get-WinAzureSubscription -UAzureSubscription $Data.UAzureSubscription -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureSubscription)
    $Data.AzureTenantDomains = Get-DataInformation -Text "Getting O365 information - AzureTenantDomains" { Get-WinAzureTenantDomains -UAzureTenantDomains $Data.UAzureTenantDomains -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::AzureTenantDomains)
    $Data.ExchangeDistributionGroups = Get-DataInformation -Text "Getting O365 information - ExchangeDistributionGroups" { Get-WinExchangeDistributionGroups -UExchangeGroupsDistribution $Data.UExchangeGroupsDistribution } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeDistributionGroups)
    $Data.ExchangeDistributionGroupsMembers = Get-DataInformation -Text "Getting O365 information - ExchangeDistributionGroupsMembers" { Get-WinExchangeDistributionGroupsMembers -UExchangeGroupsDistribution $Data.UExchangeGroupsDistribution } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeDistributionGroupsMembers)
    $Data.UExchangeUnifiedGroups = Get-DataInformation -Text "Getting O365 information - UExchangeUnifiedGroups" { Get-WinUExchangeUnifiedGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::UExchangeUnifiedGroups
        [PSWinDocumentation.O365]::ExchangeUnifiedGroups
        [PSWinDocumentation.O365]::ExchangeUnifiedGroupsMembers)
    $Data.ExchangeUnifiedGroups = Get-DataInformation -Text "Getting O365 information - ExchangeUnifiedGroups" { Get-WinExchangeUnifiedGroups -ExchangeUnifiedGroups $Data.UExchangeUnifiedGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeUnifiedGroups)
    $Data.ExchangeUnifiedGroupsMembers = Get-DataInformation -Text "Getting O365 information - ExchangeUnifiedGroupsMembers" { Get-WinExchangeUnifiedGroupsMembers -ExchangeUnifiedGroups $Data.UExchangeUnifiedGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeUnifiedGroupsMembers)
    $Data.ExchangeMailboxesInboxRulesForwarding = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxesInboxRulesForwarding" { Get-WinExchangeMailboxesInboxRulesForwarding -InboxRules $UExchangeMailboxesInboxRules -Mailboxes $UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxesInboxRulesForwarding)
    $Data.ExchangeMailboxesStatistics = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxesStatistics" { Get-WinExchangeMailboxesStatistics -ExchangeMailboxes $Data.UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxesStatistics
        [PSWinDocumentation.O365]::ExchangeMailboxes)
    $Data.ExchangeMailboxesStatisticsArchive = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxesStatisticsArchive" { Get-WinExchangeMailboxesStatisticsArchive -ExchangeMailboxes $Data.UExchangeMailBoxes } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxesStatisticsArchive
        [PSWinDocumentation.O365]::ExchangeMailboxes)
    $Data.ExchangeMailboxes = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxes" { Get-WinExchangeMailboxes -ExchangeMailboxes $Data.UExchangeMailBoxes -AzureUsers $Data.UAzureADUsers -MailboxStatistics $Data.ExchangeMailboxesStatistics -MailboxStatisticsArchive $Data.ExchangeMailboxesStatisticsArchive } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxes)
    $Data.ExchangeMailboxesPermissionsIncludingInherited = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxesPermissionsIncludingInherited" { Get-WinExchangeMailboxesPermissionsIncludingInherited -ExchangeMailboxes $Data.UExchangeMailBoxes -AzureUsers $Data.UAzureADUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxesPermissionsIncludingInherited
        [PSWinDocumentation.O365]::ExchangeMailboxesPermissions)
    $Data.ExchangeMailboxesPermissions = Get-DataInformation -Text "Getting O365 information - ExchangeMailboxesPermissions" { Get-WinExchangeMailboxesPermissions -ExchangeMailboxes $Data.UExchangeMailBoxes -MailboxPermissions $Data.ExchangeMailboxesPermissionsIncludingInherited } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMailboxesPermissions)
    $Data.ExchangeAcceptedDomains = Get-DataInformation -Text "Getting O365 information - ExchangeAcceptedDomains" { Get-WinExchangeAcceptedDomains -Prefix $Prefix -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeAcceptedDomains
        [PSWinDocumentation.O365]::ExchangeMxRecords)
    $Data.ExchangeMxRecords = Get-DataInformation -Text "Getting O365 information - ExchangeMxRecords" { Get-WinExchangeMxRecord -Prefix $Prefix -Formatted:$Formatted -ExchangeAcceptedDomains $Data.ExchangeAcceptedDomains } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeMxRecords)
    $Data.ExchangeTransportConfig = Get-DataInformation -Text "Getting O365 information - ExchangeTransportConfig" { Get-WinExchangeTransportConfig -Prefix $Prefix -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeTransportConfig)
    $Data.ExchangeConnectorsInbound = Get-DataInformation -Text "Getting O365 information - ExchangeConnectorsInbound" { Get-WinExchangeConnectorsInbound -Prefix $Prefix -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeConnectorsInbound)
    $Data.ExchangeConnectorsOutbound = Get-DataInformation -Text "Getting O365 information - ExchangeConnectorsOutbound" { Get-WinExchangeConnectorsOutbound -Prefix $Prefix -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.O365]::ExchangeConnectorsOutbound)
    $EndTime = Stop-TimeLog -Time $TimeToGenerate
    Write-Verbose "Getting domain information - $Domain - Time to generate: $EndTime"
    return ConvertTo-OrderedDictionary -HashTable $Data
}
Export-ModuleMember -Function @('Get-WinO365') -Alias @()
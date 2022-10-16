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
function ConvertFrom-DistinguishedName {
    [CmdletBinding()]
    param([string[]] $DistinguishedName)
    $Regex = '^CN=(?<cn>.+?)(?<!\\),(?<ou>(?:(?:OU|CN).+?(?<!\\),)+(?<dc>DC.+?))$'
    $Output = foreach ($_ in $DistinguishedName) {
        $_ -match $Regex
        $Matches
    }
    $Output.cn
}
function Convert-TimeToDays {
    [CmdletBinding()]
    param ($StartTime,
        $EndTime,
        [string] $Ignore = '*1601*')
    if ($null -ne $StartTime -and $null -ne $EndTime) { try { if ($StartTime -notlike $Ignore -and $EndTime -notlike $Ignore) { $Days = (New-TimeSpan -Start $StartTime -End $EndTime).Days } } catch { } } elseif ($null -ne $EndTime) { if ($StartTime -notlike $Ignore -and $EndTime -notlike $Ignore) { $Days = (New-TimeSpan -Start (Get-Date) -End ($EndTime)).Days } } elseif ($null -ne $StartTime) { if ($StartTime -notlike $Ignore -and $EndTime -notlike $Ignore) { $Days = (New-TimeSpan -Start $StartTime -End (Get-Date)).Days } }
    return $Days
}
function Convert-ToDateTime {
    [CmdletBinding()]
    param ([string] $Timestring,
        [string] $Ignore = '*1601*')
    Try { $DateTime = ([datetime]::FromFileTime($Timestring)) } catch { $DateTime = $null }
    if ($null -eq $DateTime -or $DateTime -like $Ignore) { return $null } else { return $DateTime }
}
function ConvertTo-OperatingSystem {
    [CmdletBinding()]
    param([string] $OperatingSystem,
        [string] $OperatingSystemVersion)
    if ($OperatingSystem -like '*Windows 10*') {
        $Systems = @{'10.0 (18362)' = "Windows 10 1903"
            '10.0 (17763)'          = "Windows 10 1809"
            '10.0 (17134)'          = "Windows 10 1803"
            '10.0 (16299)'          = "Windows 10 1709"
            '10.0 (15063)'          = "Windows 10 1703"
            '10.0 (14393)'          = "Windows 10 1607"
            '10.0 (10586)'          = "Windows 10 1511"
            '10.0 (10240)'          = "Windows 10 1507"
            '10.0 (18898)'          = 'Windows 10 Insider Preview'
            '10.0.18362'            = "Windows 10 1903"
            '10.0.17763'            = "Windows 10 1809"
            '10.0.17134'            = "Windows 10 1803"
            '10.0.16299'            = "Windows 10 1709"
            '10.0.15063'            = "Windows 10 1703"
            '10.0.14393'            = "Windows 10 1607"
            '10.0.10586'            = "Windows 10 1511"
            '10.0.10240'            = "Windows 10 1507"
            '10.0.18898'            = 'Windows 10 Insider Preview'
        }
        $System = $Systems[$OperatingSystemVersion]
    } elseif ($OperatingSystem -like '*Windows Server*') {
        $Systems = @{'10.0 (18362)' = "Windows Server, version 1903 (Semi-Annual Channel) 1903"
            '10.0 (17763)'          = "Windows Server 2019 (Long-Term Servicing Channel) 1809"
            '10.0 (17134)'          = "Windows Server, version 1803 (Semi-Annual Channel) 1803"
            '10.0 (14393)'          = "Windows Server 2016 (Long-Term Servicing Channel) 1607"
            '10.0.18362'            = "Windows Server, version 1903 (Semi-Annual Channel) 1903"
            '10.0.17763'            = "Windows Server 2019 (Long-Term Servicing Channel) 1809"
            '10.0.17134'            = "Windows Server, version 1803 (Semi-Annual Channel) 1803"
            '10.0.14393'            = "Windows Server 2016 (Long-Term Servicing Channel) 1607"
        }
        $System = $Systems[$OperatingSystemVersion]
    } elseif ($OperatingSystem -notlike 'Windows 10*') { $System = $OperatingSystem }
    if ($System) { $System } else { 'Unknown' }
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
function Get-ObjectCount {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Object]$Object)
    return $($Object | Measure-Object).Count
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
function Merge-Objects {
    [CmdletBinding()]
    param ([Object] $Object1,
        [Object] $Object2)
    $Object = [ordered] @{ }
    foreach ($Property in $Object1.PSObject.Properties) { $Object.($Property.Name) = $Property.Value }
    foreach ($Property in $Object2.PSObject.Properties) { $Object.($Property.Name) = $Property.Value }
    return [pscustomobject] $Object
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
Add-Type -TypeDefinition @"
    using System;

    namespace PSWinDocumentation
    {
        [Flags]
        public enum ActiveDirectory {
            // Forest Information - Section Main
            ForestInformation,
            ForestFSMO,
            ForestRoles,
            ForestGlobalCatalogs,
            ForestOptionalFeatures,
            ForestUPNSuffixes,
            ForestSPNSuffixes,
            ForestSites,
            ForestSites1,
            ForestSites2,
            ForestSubnets,
            ForestSubnets1,
            ForestSubnets2,
            ForestSiteLinks,
            ForestDomainControllers,
            ForestRootDSE,
            ForestSchemaPropertiesUsers,
            ForestSchemaPropertiesComputers,
            ForestReplication,

            // Domain Information - Section Main
            DomainRootDSE,
            DomainRIDs,
            DomainAuthenticationPolicies, // Not yet tested
            DomainAuthenticationPolicySilos, // Not yet tested
            DomainCentralAccessPolicies, // Not yet tested
            DomainCentralAccessRules, // Not yet tested
            DomainClaimTransformPolicies, // Not yet tested
            DomainClaimTypes, // Not yet tested
            DomainFineGrainedPolicies,
            DomainFineGrainedPoliciesUsers,
            DomainFineGrainedPoliciesUsersExtended,
            DomainGUIDS,
            DomainDNSSRV,
            DomainDNSA,
            DomainInformation,
            DomainControllers,
            DomainFSMO,
            DomainDefaultPasswordPolicy,
            DomainGroupPolicies,
            DomainGroupPoliciesDetails,
            DomainGroupPoliciesACL,
            DomainOrganizationalUnits,
            DomainOrganizationalUnitsBasicACL,
            DomainOrganizationalUnitsExtendedACL,
            DomainContainers,
            DomainTrustsClean,
            DomainTrusts,

            DomainBitlocker,
            DomainLAPS,

            // Domain Information - Group Data
            DomainGroupsFullList, // Contains all data

            DomainGroups,
            DomainGroupsMembers,
            DomainGroupsMembersRecursive,

            DomainGroupsSpecial,
            DomainGroupsSpecialMembers,
            DomainGroupsSpecialMembersRecursive,

            DomainGroupsPriviliged,
            DomainGroupsPriviligedMembers,
            DomainGroupsPriviligedMembersRecursive,

            // Domain Information - User Data
            DomainUsersFullList, // Contains all data
            DomainUsers,
            DomainUsersCount,
            DomainUsersAll,
            DomainUsersSystemAccounts,
            DomainUsersNeverExpiring,
            DomainUsersNeverExpiringInclDisabled,
            DomainUsersExpiredInclDisabled,
            DomainUsersExpiredExclDisabled,
            DomainAdministrators,
            DomainAdministratorsRecursive,
            DomainEnterpriseAdministrators,
            DomainEnterpriseAdministratorsRecursive,

            // Domain Information - Computer Data
            DomainComputersFullList, // Contains all data
            DomainComputersAll,
            DomainComputersAllBuildCount,
            DomainComputersAllCount,
            DomainComputers,
            DomainComputersCount,
            DomainServers,
            DomainServersCount,
            DomainComputersUnknown,
            DomainComputersUnknownCount,

            // This requires DSInstall PowerShell Module
            DomainPasswordDataUsers, // Gathers users data and their passwords
            DomainPasswordDataPasswords, // Compares Users Password with File
            DomainPasswordDataPasswordsHashes, // Compares Users Password with File HASH
            DomainPasswordClearTextPassword, // include both enabled / disabled accounts
            DomainPasswordClearTextPasswordEnabled,  // include only enabled
            DomainPasswordClearTextPasswordDisabled, // include only disabled
            DomainPasswordLMHash,
            DomainPasswordEmptyPassword,
            DomainPasswordWeakPassword,
            DomainPasswordWeakPasswordEnabled,
            DomainPasswordWeakPasswordDisabled,
            DomainPasswordWeakPasswordList, // Password List from file..
            DomainPasswordDefaultComputerPassword,
            DomainPasswordPasswordNotRequired,
            DomainPasswordPasswordNeverExpires,
            DomainPasswordAESKeysMissing,
            DomainPasswordPreAuthNotRequired,
            DomainPasswordDESEncryptionOnly,
            DomainPasswordDelegatableAdmins,
            DomainPasswordDuplicatePasswordGroups,
            DomainPasswordHashesWeakPassword,
            DomainPasswordHashesWeakPasswordEnabled,
            DomainPasswordHashesWeakPasswordDisabled,
            DomainPasswordStats
        }
    }
"@
function Get-WinADDomain {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN)
    try { Get-ADDomain -Server $Domain -ErrorAction Stop } catch { $null }
}
function Get-WinADDomainControllersInternal {
    [CmdletBinding()]
    param([string] $Domain)
    $DomainControllersClean = Get-ADDomainController -Server $Domain -Filter *
    foreach ($DC in $DomainControllersClean) {
        [PsCustomObject] @{'Name' = $DC.Name
            'Host Name'           = $DC.HostName
            'Operating System'    = $DC.OperatingSystem
            'Site'                = $DC.Site
            'Ipv4'                = $DC.Ipv4Address
            'Ipv6'                = $DC.Ipv6Address
            'Global Catalog?'     = $DC.IsGlobalCatalog
            'Read Only?'          = $DC.IsReadOnly
            'Ldap Port'           = $DC.LdapPort
            'SSL Port'            = $DC.SSLPort
        }
    }
}
function Get-WinADDomainDefaultPasswordPolicy {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN)
    $Policy = Get-ADDefaultDomainPasswordPolicy -Server $Domain
    [ordered] @{'Complexity Enabled'    = $Policy.ComplexityEnabled
        'Lockout Duration'              = ($Policy.LockoutDuration).TotalMinutes
        'Lockout Observation Window'    = ($Policy.LockoutObservationWindow).TotalMinutes
        'Lockout Threshold'             = $Policy.LockoutThreshold
        'Max Password Age'              = $($Policy.MaxPasswordAge).TotalDays
        'Min Password Length'           = $Policy.MinPasswordLength
        'Min Password Age'              = $($Policy.MinPasswordAge).TotalDays
        'Password History Count'        = $Policy.PasswordHistoryCount
        'Reversible Encryption Enabled' = $Policy.ReversibleEncryptionEnabled
        'Distinguished Name'            = $Policy.DistinguishedName
    }
}
function Get-WinADDomainDNSData {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN)
    $DnsRecords = "_kerberos._tcp.$Domain", "_ldap._tcp.$Domain"
    $DNSData = foreach ($DnsRecord in $DnsRecords) {
        $Value = Resolve-DnsName -Name $DnsRecord -Type SRV -Verbose:$false -ErrorAction SilentlyContinue
        if ($null -eq $Value) { Write-Warning 'Getting domain information - DomainDNSSRV / DomainDNSA - Failed!' }
        $Value
    }
    $ReturnData = @{ }
    $ReturnData.Srv = foreach ($V in $DNSData) { if ($V.QueryType -eq 'SRV') { $V | Select-Object Target, NameTarget, Priority, Weight, Port, Name } }
    $ReturnData.A = foreach ($V in $DNSData) { if ($V.QueryType -ne 'SRV') { $V | Select-Object Address, IPAddress, IP4Address, Name, Type, DataLength, TTL } }
    return $ReturnData
}
function Get-WinADDomainFineGrainedPolicies {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN)
    $FineGrainedPoliciesData = Get-ADFineGrainedPasswordPolicy -Filter * -Server $Domain
    $FineGrainedPolicies = foreach ($Policy in $FineGrainedPoliciesData) {
        [PsCustomObject] @{'Name'           = $Policy.Name
            'Complexity Enabled'            = $Policy.ComplexityEnabled
            'Lockout Duration'              = $Policy.LockoutDuration
            'Lockout Observation Window'    = $Policy.LockoutObservationWindow
            'Lockout Threshold'             = $Policy.LockoutThreshold
            'Max Password Age'              = $Policy.MaxPasswordAge
            'Min Password Length'           = $Policy.MinPasswordLength
            'Min Password Age'              = $Policy.MinPasswordAge
            'Password History Count'        = $Policy.PasswordHistoryCount
            'Reversible Encryption Enabled' = $Policy.ReversibleEncryptionEnabled
            'Precedence'                    = $Policy.Precedence
            'Applies To'                    = $Policy.AppliesTo
            'Distinguished Name'            = $Policy.DistinguishedName
        }
    }
    return $FineGrainedPolicies
}
function Get-WinADDomainFineGrainedPoliciesUsers {
    [CmdletBinding()]
    param([Array] $DomainFineGrainedPolicies,
        [hashtable] $DomainObjects)
    $PolicyUsers = foreach ($Policy in $DomainFineGrainedPolicies) {
        $AllObjects = foreach ($U in $Policy.'Applies To') { Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $U }
        foreach ($_ in $AllObjects) {
            [PsCustomObject] @{'Policy Name' = $Policy.Name
                Name                         = $_.Name
                SamAccountName               = $_.SamAccountName
                Type                         = $_.ObjectClass
                SID                          = $_.SID
            }
        }
    }
    return $PolicyUsers
}
function Get-WinADDomainFineGrainedPoliciesUsersExtended {
    [CmdletBinding()]
    param([Array] $DomainFineGrainedPolicies,
        [string] $Domain = ($Env:USERDNSDOMAIN).ToLower(),
        [hashtable] $DomainObjects)
    $CurrentDate = Get-Date
    $PolicyUsers = @(foreach ($Policy in $DomainFineGrainedPolicies) {
            $Objects = foreach ($U in $Policy.'Applies To') { Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $U }
            $Users = foreach ($_ in $Objects) { if ($_.ObjectClass -eq 'user') { $_ } }
            $Groups = foreach ($_ in $Objects) { if ($_.ObjectClass -eq 'group') { $_ } }
            foreach ($User in $Users) {
                $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $User.Manager
                [PsCustomObject] @{'Policy Name'        = $Policy.Name
                    Name                                = $User.Name
                    SamAccountName                      = $User.SamAccountName
                    Type                                = $User.ObjectClass
                    SID                                 = $User.SID
                    'High Privileged Group'             = 'N/A'
                    'Display Name'                      = $User.DisplayName
                    'Member Name'                       = $Member.Name
                    'User Principal Name'               = $User.UserPrincipalName
                    'Sam Account Name'                  = $User.SamAccountName
                    'Email Address'                     = $User.EmailAddress
                    'PasswordExpired'                   = $User.PasswordExpired
                    'PasswordLastSet'                   = $User.PasswordLastSet
                    'PasswordNotRequired'               = $User.PasswordNotRequired
                    'PasswordNeverExpires'              = $User.PasswordNeverExpires
                    'Enabled'                           = $User.Enabled
                    'MemberSID'                         = $Member.SID.Value
                    'Manager'                           = $Manager.Name
                    'ManagerEmail'                      = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
                    'DateExpiry'                        = Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")
                    "DaysToExpire"                      = (Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring $($User."msDS-UserPasswordExpiryTimeComputed")))
                    "AccountExpirationDate"             = $User.AccountExpirationDate
                    "AccountLockoutTime"                = $User.AccountLockoutTime
                    "AllowReversiblePasswordEncryption" = $User.AllowReversiblePasswordEncryption
                    "BadLogonCount"                     = $User.BadLogonCount
                    "CannotChangePassword"              = $User.CannotChangePassword
                    "CanonicalName"                     = $User.CanonicalName
                    'Given Name'                        = $User.GivenName
                    'Surname'                           = $User.Surname
                    "Description"                       = $User.Description
                    "DistinguishedName"                 = $User.DistinguishedName
                    "EmployeeID"                        = $User.EmployeeID
                    "EmployeeNumber"                    = $User.EmployeeNumber
                    "LastBadPasswordAttempt"            = $User.LastBadPasswordAttempt
                    "LastLogonDate"                     = $User.LastLogonDate
                    "Created"                           = $User.Created
                    "Modified"                          = $User.Modified
                    "Protected"                         = $User.ProtectedFromAccidentalDeletion
                    "Domain"                            = $Domain
                }
            }
            foreach ($Group in $Groups) {
                $GroupMembership = Get-ADGroupMember -Server $Domain -Identity $Group.SID -Recursive
                foreach ($Member in $GroupMembership) {
                    $Object = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Member.DistinguishedName
                    $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Object.Manager
                    [PsCustomObject] @{'Policy Name'        = $Policy.Name
                        Name                                = $Group.Name
                        SamAccountName                      = $Group.SamAccountName
                        Type                                = $Group.ObjectClass
                        SID                                 = $Group.SID
                        'High Privileged Group'             = if ($Group.adminCount -eq 1) { $True } else { $False }
                        'Display Name'                      = $Object.DisplayName
                        'Member Name'                       = $Member.Name
                        'User Principal Name'               = $Object.UserPrincipalName
                        'Sam Account Name'                  = $Object.SamAccountName
                        'Email Address'                     = $Object.EmailAddress
                        'PasswordExpired'                   = $Object.PasswordExpired
                        'PasswordLastSet'                   = $Object.PasswordLastSet
                        'PasswordNotRequired'               = $Object.PasswordNotRequired
                        'PasswordNeverExpires'              = $Object.PasswordNeverExpires
                        'Enabled'                           = $Object.Enabled
                        'MemberSID'                         = $Member.SID.Value
                        'Manager'                           = $Manager.Name
                        'ManagerEmail'                      = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
                        'DateExpiry'                        = Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")
                        "DaysToExpire"                      = (Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")))
                        "AccountExpirationDate"             = $Object.AccountExpirationDate
                        "AccountLockoutTime"                = $Object.AccountLockoutTime
                        "AllowReversiblePasswordEncryption" = $Object.AllowReversiblePasswordEncryption
                        "BadLogonCount"                     = $Object.BadLogonCount
                        "CannotChangePassword"              = $Object.CannotChangePassword
                        "CanonicalName"                     = $Object.CanonicalName
                        'Given Name'                        = $Object.GivenName
                        'Surname'                           = $Object.Surname
                        "Description"                       = $Object.Description
                        "DistinguishedName"                 = $Object.DistinguishedName
                        "EmployeeID"                        = $Object.EmployeeID
                        "EmployeeNumber"                    = $Object.EmployeeNumber
                        "LastBadPasswordAttempt"            = $Object.LastBadPasswordAttempt
                        "LastLogonDate"                     = $Object.LastLogonDate
                        "Created"                           = $Object.Created
                        "Modified"                          = $Object.Modified
                        "Protected"                         = $Object.ProtectedFromAccidentalDeletion
                        "Domain"                            = $Domain
                    }
                }
            }
        })
    return $PolicyUsers
}
function Get-WinADDomainFSMO {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Microsoft.ActiveDirectory.Management.ADDomain] $DomainInformation)
    [ordered] @{'PDC Emulator'  = $DomainInformation.PDCEmulator
        'RID Master'            = $DomainInformation.RIDMaster
        'Infrastructure Master' = $DomainInformation.InfrastructureMaster
    }
}
function Get-WinADDomainGroupPolicies {
    [CmdletBinding()]
    param([Array] $GroupPolicies,
        [string] $Domain = $Env:USERDNSDOMAIN)
    if ($null -eq $GroupPolicies) { $GroupPolicies = Get-GPO -Domain $Domain -All }
    foreach ($gpo in $GroupPolicies) {
        [PsCustomObject] @{'Display Name' = $gpo.DisplayName
            'Gpo Status'                  = $gpo.GPOStatus
            'Creation Time'               = $gpo.CreationTime
            'Modification Time'           = $gpo.ModificationTime
            'Description'                 = $gpo.Description
            'Wmi Filter'                  = $gpo.WmiFilter
        }
    }
}
function Get-WinADDomainGroupPoliciesACL {
    [CmdletBinding()]
    param([Array] $GroupPolicies,
        [string] $Domain = $Env:USERDNSDOMAIN)
    if ($null -eq $GroupPolicies) { $GroupPolicies = Get-GPO -Domain $Domain -All }
    $Output = ForEach ($GPO in $GroupPolicies) {
        [xml]$XmlGPReport = $GPO.generatereport('xml')
        $ACLs = $XmlGPReport.GPO.SecurityDescriptor.Permissions.TrusteePermissions
        foreach ($ACL in $ACLS) {
            [PsCustomObject] @{'GPO Name' = $GPO.DisplayName
                'User'                    = $ACL.trustee.name.'#Text'
                'Permission Type'         = $ACL.type.PermissionType
                'Inherited'               = $ACL.Inherited
                'Permissions'             = $ACL.Standard.GPOGroupedAccessEnum
            }
        }
    }
    return $Output
}
function Get-WinADDomainGroupPoliciesDetails {
    [CmdletBinding()]
    param([Array] $GroupPolicies,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [string] $Splitter)
    if ($null -eq $GroupPolicies) { $GroupPolicies = Get-GPO -Domain $Domain -All }
    ForEach ($GPO in $GroupPolicies) {
        [xml]$XmlGPReport = $GPO.generatereport('xml')
        if ($XmlGPReport.GPO.Computer.VersionDirectory -eq 0 -and $XmlGPReport.GPO.Computer.VersionSysvol -eq 0) { $ComputerSettings = "NeverModified" } else { $ComputerSettings = "Modified" }
        if ($XmlGPReport.GPO.User.VersionDirectory -eq 0 -and $XmlGPReport.GPO.User.VersionSysvol -eq 0) { $UserSettings = "NeverModified" } else { $UserSettings = "Modified" }
        if ($null -eq $XmlGPReport.GPO.User.ExtensionData) { $UserSettingsConfigured = $false } else { $UserSettingsConfigured = $true }
        if ($null -eq $XmlGPReport.GPO.Computer.ExtensionData) { $ComputerSettingsConfigured = $false } else { $ComputerSettingsConfigured = $true }
        [PsCustomObject] @{'Name'    = $XmlGPReport.GPO.Name
            'Links'                  = $XmlGPReport.GPO.LinksTo | Select-Object -ExpandProperty SOMPath
            'Has Computer Settings'  = $ComputerSettingsConfigured
            'Has User Settings'      = $UserSettingsConfigured
            'User Enabled'           = $XmlGPReport.GPO.User.Enabled
            'Computer Enabled'       = $XmlGPReport.GPO.Computer.Enabled
            'Computer Settings'      = $ComputerSettings
            'User Settings'          = $UserSettings
            'Gpo Status'             = $GPO.GpoStatus
            'Creation Time'          = $GPO.CreationTime
            'Modification Time'      = $GPO.ModificationTime
            'WMI Filter'             = $GPO.WmiFilter.name
            'WMI Filter Description' = $GPO.WmiFilter.Description
            'Path'                   = $GPO.Path
            'GUID'                   = $GPO.Id
            'SDDL'                   = if ($Splitter -ne '') { $XmlGPReport.GPO.SecurityDescriptor.SDDL.'#text' -join $Splitter } else { $XmlGPReport.GPO.SecurityDescriptor.SDDL.'#text' }
        }
    }
}
function Get-WinADDomainGUIDs {
    [cmdletbinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Microsoft.ActiveDirectory.Management.ADEntity] $RootDSE)
    if ($null -eq $RootDSE) { $RootDSE = Get-ADRootDSE -Server $Domain }
    $GUID = @{ }
    $Schema = Get-ADObject -SearchBase $RootDSE.schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID
    foreach ($S in $Schema) { if ($GUID.Keys -notcontains $S.schemaIDGUID) { $GUID.add([System.GUID]$S.schemaIDGUID, $S.name) } }
    $Extended = Get-ADObject -SearchBase "CN=Extended-Rights,$($RootDSE.configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID
    foreach ($S in $Extended) { if ($GUID.Keys -notcontains $S.rightsGUID) { $GUID.add([System.GUID]$S.rightsGUID, $S.name) } }
    return $GUID
}
function Get-WinADDomainOrganizationalUnits {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Array] $OrgnaizationalUnits,
        [hashtable] $DomainObjects)
    if ($null -eq $OrgnaizationalUnits) { $OrgnaizationalUnits = $(Get-ADOrganizationalUnit -Server $Domain -Properties * -Filter *) }
    $Output = foreach ($_ in $OrgnaizationalUnits) {
        $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $_.ManagedBy
        [PSCustomObject] @{'Canonical Name' = $_.CanonicalName
            'Managed'                       = $Manager.Name
            'Manager Email'                 = $Manager.EmailAddress
            'Protected'                     = $_.ProtectedFromAccidentalDeletion
            Description                     = $_.Description
            Created                         = $_.Created
            Modified                        = $_.Modified
            Deleted                         = $_.Deleted
            'PostalCode'                    = $_.PostalCode
            City                            = $_.City
            Country                         = $_.Country
            State                           = $_.State
            'StreetAddress'                 = $_.StreetAddress
            DistinguishedName               = $_.DistinguishedName
            ObjectGUID                      = $_.ObjectGUID
        }
    }
    $Output | Sort-Object 'Canonical Name'
}
function Get-WinADDomainOrganizationalUnitsACL {
    [cmdletbinding()]
    param([Array] $DomainOrganizationalUnitsClean,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [string] $NetBiosName,
        [string] $RootDomainNamingContext)
    $OUs = @(foreach ($OU in $DomainOrganizationalUnitsClean) { @{Name = 'Organizational Unit'; Value = $OU.DistinguishedName } })
    $null = New-PSDrive -Name $NetBiosName -Root '' -PsProvider ActiveDirectory -Server $Domain
    @(foreach ($OU in $OUs) {
            $ACL = Get-Acl -Path "$NetBiosName`:\$($OU.Value)"
            [PsCustomObject] @{'Distinguished Name' = $OU.Value
                'Type'                              = $OU.Name
                'Owner'                             = $ACL.Owner
                'Group'                             = $ACL.Group
                'Are AccessRules Protected'         = $ACL.AreAccessRulesProtected
                'Are AuditRules Protected'          = $ACL.AreAuditRulesProtected
                'Are AccessRules Canonical'         = $ACL.AreAccessRulesCanonical
                'Are AuditRules Canonical'          = $ACL.AreAuditRulesCanonical
            }
        })
}
function Get-WinADDomainOrganizationalUnitsACLExtended {
    [cmdletbinding()]
    param([Array] $DomainOrganizationalUnitsClean,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [string] $NetBiosName,
        [string] $RootDomainNamingContext,
        [hashtable] $GUID)
    $OUs = @(foreach ($OU in $DomainOrganizationalUnitsClean) { @{Name = 'Organizational Unit'; Value = $OU.DistinguishedName } })
    $null = New-PSDrive -Name $NetBiosName -Root '' -PsProvider ActiveDirectory -Server $Domain
    @(foreach ($OU in $OUs) {
            $ACLs = Get-Acl -Path "$NetBiosName`:\$($OU.Value)" | Select-Object -ExpandProperty Access
            foreach ($ACL in $ACLs) {
                [PSCustomObject] @{'Distinguished Name' = $OU.Value
                    'Type'                              = $OU.Name
                    'AccessControlType'                 = $ACL.AccessControlType
                    'ObjectType Name'                   = if ($ACL.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') { 'All' } Else { $GUID.Item($ACL.objectType) }
                    'Inherited ObjectType Name'         = $GUID.Item($ACL.inheritedObjectType)
                    'ActiveDirectoryRights'             = $ACL.ActiveDirectoryRights
                    'InheritanceType'                   = $ACL.InheritanceType
                    'ObjectType'                        = $ACL.ObjectType
                    'InheritedObjectType'               = $ACL.InheritedObjectType
                    'ObjectFlags'                       = $ACL.ObjectFlags
                    'IdentityReference'                 = $ACL.IdentityReference
                    'IsInherited'                       = $ACL.IsInherited
                    'InheritanceFlags'                  = $ACL.InheritanceFlags
                    'PropagationFlags'                  = $ACL.PropagationFlags
                }
            }
        })
}
function Get-WinADDomainRIDs {
    [CmdletBinding()]
    param([Microsoft.ActiveDirectory.Management.ADDomain] $DomainInformation,
        [string] $Domain = $Env:USERDNSDOMAIN)
    if ($null -eq $DomainInformation) { $DomainInformation = Get-ADDomain -Server $Domain }
    $rID = [ordered] @{ }
    $rID.'rIDs Master' = $DomainInformation.RIDMaster
    $Property = Get-ADObject "cn=rid manager$,cn=system,$($DomainInformation.DistinguishedName)" -Property RidAvailablePool -Server $rID.'rIDs Master'
    [int32]$totalSIDS = $($Property.RidAvailablePool) / ([math]::Pow(2, 32))
    [int64]$temp64val = $totalSIDS * ([math]::Pow(2, 32))
    [int32]$currentRIDPoolCount = $($Property.RidAvailablePool) - $temp64val
    [int64]$RidsRemaining = $totalSIDS - $currentRIDPoolCount
    $Rid.'rIDs Available Pool' = $Property.RidAvailablePool
    $rID.'rIDs Total SIDs' = $totalSIDS
    $rID.'rIDs Issued' = $CurrentRIDPoolCount
    $rID.'rIDs Remaining' = $RidsRemaining
    $rID.'rIDs Percentage' = if ($RidsRemaining -eq 0) { $RidsRemaining.ToString("P") } else { ($currentRIDPoolCount / $RidsRemaining * 100).ToString("P") }
    return $rID
}
function Get-WinADDomainTrusts {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [string] $DomainPDC,
        [Array] $Trusts)
    if ($null -eq $Trusts) { $Trusts = Get-ADTrust -Server $Domain -Filter * -Properties * }
    if ($DomainPDC -eq '') { $DomainPDC = (Get-ADDomain -Server $Domain).PDCEmulator }
    $PropertiesTrustWMI = @('FlatName',
        'SID',
        'TrustAttributes',
        'TrustDirection',
        'TrustedDCName',
        'TrustedDomain',
        'TrustIsOk',
        'TrustStatus',
        'TrustStatusString',
        'TrustType')
    $TrustStatatuses = Get-CimInstance -ClassName Microsoft_DomainTrustStatus -Namespace root\MicrosoftActiveDirectory -ComputerName $DomainPDC -ErrorAction SilentlyContinue -Verbose:$false -Property $PropertiesTrustWMI
    $ReturnData = foreach ($Trust in $Trusts) {
        $TrustWMI = $TrustStatatuses | & { process { if ($_.TrustedDomain -eq $Trust.Target) { $_ } } }
        [PsCustomObject] @{'Trust Source' = $Domain
            'Trust Target'                = $Trust.Target
            'Trust Direction'             = $Trust.Direction
            'Trust Attributes'            = if ($Trust.TrustAttributes -is [int]) { Set-TrustAttributes -Value $Trust.TrustAttributes } else { 'Error - needs fixing' }
            'Trust Status'                = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatusString } else { 'N/A' }
            'Forest Transitive'           = $Trust.ForestTransitive
            'Selective Authentication'    = $Trust.SelectiveAuthentication
            'SID Filtering Forest Aware'  = $Trust.SIDFilteringForestAware
            'SID Filtering Quarantined'   = $Trust.SIDFilteringQuarantined
            'Disallow Transivity'         = $Trust.DisallowTransivity
            'Intra Forest'                = $Trust.IntraForest
            'Tree Parent?'                = $Trust.IsTreeParent
            'Tree Root?'                  = $Trust.IsTreeRoot
            'TGTDelegation'               = $Trust.TGTDelegation
            'TrustedPolicy'               = $Trust.TrustedPolicy
            'TrustingPolicy'              = $Trust.TrustingPolicy
            'TrustType'                   = $Trust.TrustType
            'UplevelOnly'                 = $Trust.UplevelOnly
            'UsesAESKeys'                 = $Trust.UsesAESKeys
            'UsesRC4Encryption'           = $Trust.UsesRC4Encryption
            'Trust Source DC'             = if ($null -ne $TrustWMI) { $TrustWMI.PSComputerName } else { '' }
            'Trust Target DC'             = if ($null -ne $TrustWMI) { $TrustWMI.TrustedDCName.Replace('\\', '') } else { '' }
            'Trust Source DN'             = $Trust.Source
            'ObjectGUID'                  = $Trust.ObjectGUID
            'Created'                     = $Trust.Created
            'Modified'                    = $Trust.Modified
            'Deleted'                     = $Trust.Deleted
            'SID'                         = $Trust.securityIdentifier
            'TrustOK'                     = if ($null -ne $TrustWMI) { $TrustWMI.TrustIsOK } else { $false }
            'TrustStatus'                 = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatus } else { -1 }
        }
    }
    return $ReturnData
}
function Get-WinADDomainTrustsClean {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN)
    Get-ADTrust -Server $Domain -Filter * -Properties * -ErrorAction SilentlyContinue
}
function Get-WinADKerberosUnconstrainedDelegation {
    param()
    Get-ADObject -filter { (UserAccountControl -BAND 0x0080000) -OR (UserAccountControl -BAND 0x1000000) -OR (msDS-AllowedToDelegateTo -like '*') } -Properties Name, ObjectClass, PrimaryGroupID, UserAccountControl, ServicePrincipalName, msDS-AllowedToDelegateTo
}
function Get-WinADRootDSE {
    [CmdletBinding()]
    param([string] $Domain = ($Env:USERDNSDOMAIN).ToLower())
    try { if ($Domain -ne '') { Get-ADRootDSE -Properties * -Server $Domain } else { Get-ADRootDSE -Properties * } } catch { Write-Warning "Getting forest/domain information - $Domain RootDSE Error: $($_.Error)" }
}
Function Set-TrustAttributes {
    [cmdletbinding()]
    Param([parameter(Mandatory = $false, ValueFromPipeline = $True)][int32]$Value)
    [String[]]$TrustAttributes = @(Foreach ($V in $Value) {
            if ([int32]$V -band 0x00000001) { "Non Transitive" }
            if ([int32]$V -band 0x00000002) { "UpLevel" }
            if ([int32]$V -band 0x00000004) { "Quarantaine (SID Filtering enabled)" }
            if ([int32]$V -band 0x00000008) { "Forest Transitive" }
            if ([int32]$V -band 0x00000010) { "Cross Organization (Selective Authentication enabled)" }
            if ([int32]$V -band 0x00000020) { "Within Forest" }
            if ([int32]$V -band 0x00000040) { "Treat as External" }
            if ([int32]$V -band 0x00000080) { "Uses RC4 Encryption" }
        })
    return $TrustAttributes
}
function Get-WinADDomainBitlocker {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Array] $Computers)
    $Properties = @('Name',
        'OperatingSystem',
        'DistinguishedName')
    if ($null -eq $Computers) { $Computers = Get-ADComputer -Filter * -Properties $Properties -Server $Domain }
    foreach ($Computer in $Computers) {
        try { $Bitlockers = Get-ADObject -Filter 'objectClass -eq "msFVE-RecoveryInformation"' -SearchBase $Computer.DistinguishedName -Properties 'WhenCreated', 'msFVE-RecoveryPassword' } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            if ($ErrorMessage -like "*The supplied distinguishedName must belong to one of the following partition(s)*") { Write-Warning "Getting domain information - $Domain - Couldn't get Bitlocker information. Most likely not enabled." } else { Write-Warning "Getting domain information - $Domain - Couldn't get Bitlocker information. Error: $ErrorMessage" }
            return
        }
        foreach ($Bitlocker in $Bitlockers) {
            [PSCustomObject] @{'Name'         = $Computer.Name
                'Operating System'            = $Computer.'OperatingSystem'
                'Bitlocker Recovery Password' = $Bitlocker.'msFVE-RecoveryPassword'
                'Bitlocker When'              = $Bitlocker.WhenCreated
                'DistinguishedName'           = $Computer.'DistinguishedName'
            }
        }
    }
}
function Get-WinADDomainComputers {
    [CmdletBinding()]
    param([Array] $DomainComputersAll)
    foreach ($_ in $DomainComputersAll) { if ($_.OperatingSystem -notlike 'Windows Server*' -and $null -ne $_.OperatingSystem) { $_ } }
}
function Get-WinADDomainComputersAll {
    [CmdletBinding()]
    param([Array] $DomainComputersFullList,
        [string] $Splitter,
        [hashtable] $DomainObjects)
    [DateTime] $CurrentDate = Get-Date
    foreach ($_ in $DomainComputersFullList) {
        $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $_.ManagedBy
        [PSCustomObject] @{SamAccountName = $_.SamAccountName
            Enabled                       = $_.Enabled
            OperatingSystem               = $_.OperatingSystem
            PasswordLastSet               = $_.PasswordLastSet
            'PasswordLastChanged(Days)'   = if ($null -ne $_.PasswordLastSet) { "$(-$($_.PasswordLastSet - $CurrentDate).Days)" } else { }
            IPv4Address                   = $_.IPv4Address
            IPv6Address                   = $_.IPv6Address
            Name                          = $_.Name
            DNSHostName                   = $_.DNSHostName
            'Manager'                     = $Manager.Name
            'ManagerEmail'                = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
            OperatingSystemVersion        = $_.OperatingSystemVersion
            OperatingSystemHotfix         = $_.OperatingSystemHotfix
            OperatingSystemServicePack    = $_.OperatingSystemServicePack
            OperatingSystemBuild          = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
            PasswordNeverExpires          = $_.PasswordNeverExpires
            PasswordNotRequired           = $_.PasswordNotRequired
            UserPrincipalName             = $_.UserPrincipalName
            LastLogonDate                 = $_.LastLogonDate
            'LastLogonDate(Days)'         = if ($null -ne $_.LastLogonDate) { "$(-$($_.LastLogonDate - $CurrentDate).Days)" } else { }
            LockedOut                     = $_.LockedOut
            LogonCount                    = $_.LogonCount
            CanonicalName                 = $_.CanonicalName
            SID                           = $_.SID
            Created                       = $_.Created
            Modified                      = $_.Modified
            Deleted                       = $_.Deleted
            "Protected"                   = $_.ProtectedFromAccidentalDeletion
            "PrimaryGroup"                = (Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $_.PrimaryGroup -Type 'SamAccountName')
            "MemberOf"                    = (Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $_.MemberOf -Type 'SamAccountName' -Splitter $Splitter)
        }
    }
}
function Get-WinADDomainComputersAllBuildSummary {
    [CmdletBinding()]
    param([Array] $DomainComputers,
        [switch] $Formatted)
    if ($Formatted) { $DomainComputers | Group-Object -Property OperatingSystemBuild | Sort-Object -Property Name | Select-Object @{L = 'System Name'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'N/A' } } } , @{L = 'System Count'; Expression = { $_.Count } } } else { $DomainComputers | Group-Object -Property OperatingSystemBuild | Sort-Object -Property Name }
}
function Get-WinADDomainComputersAllCount {
    [CmdletBinding()]
    param([Array] $DomainComputersAll)
    $DomainComputersAll | Group-Object -Property OperatingSystem | Select-Object @{L = 'System Name'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'Unknown' } } } , @{L = 'System Count'; Expression = { $_.Count } }
}
function Get-WinADDomainComputersCount {
    [CmdletBinding()]
    param([Array] $DomainComputers)
    $DomainComputers | Group-Object -Property OperatingSystem | Select-Object @{L = 'System Name'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'N/A' } } } , @{L = 'System Count'; Expression = { $_.Count } }
}
function Get-WinADDomainComputersFullList {
    [cmdletbinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Array] $ForestSchemaComputers,
        [HashTable] $DomainObjects,
        [int] $ResultPageSize = 500000)
    if ($Extended) { [string] $Properties = '*' } else {
        [string[]] $Properties = @('SamAccountName', 'Enabled', 'OperatingSystem',
            'PasswordLastSet', 'IPv4Address', 'IPv6Address', 'Name', 'DNSHostName',
            'ManagedBy', 'OperatingSystemVersion', 'OperatingSystemHotfix',
            'OperatingSystemServicePack' , 'PasswordNeverExpires',
            'PasswordNotRequired', 'UserPrincipalName',
            'LastLogonDate', 'LockedOut', 'LogonCount',
            'CanonicalName', 'SID', 'Created', 'Modified',
            'Deleted', 'MemberOf', 'PrimaryGroup', 'ProtectedFromAccidentalDeletion'
            if ($ForestSchemaComputers.Name -contains 'ms-Mcs-AdmPwd') {
                'ms-Mcs-AdmPwd'
                'ms-Mcs-AdmPwdExpirationTime'
            })
    }
    $Computers = Get-ADComputer -Server $Domain -Filter * -ResultPageSize $ResultPageSize -Properties $Properties -ErrorAction SilentlyContinue
    foreach ($_ in $Computers) { $DomainObjects.Add($_.DistinguishedName, $_) }
    $Computers
}
function Get-WinADDomainComputersUnknown {
    [CmdletBinding()]
    param([Array] $DomainComputersAll)
    foreach ($_ in $DomainComputersAll) { if ($null -eq $_.OperatingSystem) { $_ } }
}
function Get-WinADDomainComputersUnknownCount {
    [CmdletBinding()]
    param([Array] $DomainComputersUnknown)
    $DomainComputersUnknown | Group-Object -Property OperatingSystem | Select-Object @{L = 'System Name'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'Unknown' } } } , @{L = 'System Count'; Expression = { $_.Count } }
}
function Get-WinADDomainLAPS {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [Array] $Computers,
        [string] $Splitter)
    $Properties = @('Name',
        'OperatingSystem',
        'DistinguishedName',
        'ms-Mcs-AdmPwd',
        'ms-Mcs-AdmPwdExpirationTime')
    [DateTime] $CurrentDate = Get-Date
    if ($null -eq $Computers -or $Computers.Count -eq 0) { $Computers = Get-ADComputer -Filter * -Properties $Properties }
    foreach ($Computer in $Computers) {
        [PSCustomObject] @{'Name' = $Computer.Name
            'Operating System'    = $Computer.'OperatingSystem'
            'LapsPassword'        = if ($Splitter -ne '') { $Computer.'ms-Mcs-AdmPwd' -join $Splitter } else { $Computer.'ms-Mcs-AdmPwd' }
            'LapsExpire(days)'    = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($Computer.'ms-Mcs-AdmPwdExpirationTime'))
            'LapsExpirationTime'  = Convert-ToDateTime -Timestring ($Computer.'ms-Mcs-AdmPwdExpirationTime')
            'DistinguishedName'   = $Computer.'DistinguishedName'
        }
    }
}
function Get-WinADDomainServersCount {
    [CmdletBinding()]
    param([Array] $DomainServers)
    $DomainServers | Group-Object -Property OperatingSystem | Select-Object @{L = 'System Name'; Expression = { if ($_.Name -ne '') { $_.Name } else { 'N/A' } } } , @{L = 'System Count'; Expression = { $_.Count } }
}
function Get-WinADDomainServers {
    [CmdletBinding()]
    param([Array] $DomainComputersAll)
    foreach ($_ in $DomainComputersAll) { if ($_.OperatingSystem -like 'Windows Server*') { $_ } }
}
function Get-WinADDomainAdministrators {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembers,
        $DomainInformation)
    $Members = foreach ($_ in $DomainGroupsMembers) { if ($_.'Group SID' -eq $('{0}-512' -f $DomainInformation.DomainSID.Value)) { $_ } }
    $Members | Select-Object * -Exclude Group*, 'High Privileged Group'
}
function Get-WinADDomainAdministratorsRecursive {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembersRecursive,
        $DomainInformation)
    $Members = foreach ($_ in $DomainGroupsMembersRecursive) { if ($_.'Group SID' -eq $('{0}-512' -f $DomainInformation.DomainSID.Value)) { $_ } }
    $Members | Select-Object * -Exclude Group*, 'High Privileged Group'
}
function Get-WinADDomainEnterpriseAdministrators {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembers,
        $DomainInformation)
    $Members = foreach ($_ in $DomainGroupsMembers) { if ($_.'Group SID' -eq $('{0}-519' -f $DomainInformation.DomainSID.Value)) { $_ } }
    $Members | Select-Object * -Exclude Group*, 'High Privileged Group'
}
function Get-WinADDomainEnterpriseAdministratorsRecursive {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembersRecursive,
        $DomainInformation)
    $Members = foreach ($_ in $DomainGroupsMembersRecursive) { if ($_.'Group SID' -eq $('{0}-519' -f $DomainInformation.DomainSID.Value)) { $_ } }
    $Members | Select-Object * -Exclude Group*, 'High Privileged Group'
}
function Get-WinADDomainGroupsFullList {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [HashTable] $DomainObjects,
        [int] $ResultPageSize = 500000)
    if ($Extended) { [string] $Properties = '*' } else {
        [string[]] $Properties = @('adminCount'
            'CanonicalName'
            'CN'
            'Created'
            'createTimeStamp'
            'Deleted'
            'Description'
            'DisplayName'
            'DistinguishedName'
            'GroupCategory'
            'GroupScope'
            'groupType'
            'HomePage'
            'instanceType'
            'isCriticalSystemObject'
            'isDeleted'
            'LastKnownParent'
            'ManagedBy'
            'member'
            'MemberOf'
            'Members'
            'Modified'
            'modifyTimeStamp'
            'Name'
            'ObjectCategory'
            'ObjectClass'
            'ObjectGUID'
            'objectSid'
            'ProtectedFromAccidentalDeletion'
            'SamAccountName'
            'sAMAccountType'
            'sDRightsEffective'
            'SID'
            'SIDHistory'
            'systemFlags'
            'uSNChanged'
            'uSNCreated'
            'whenChanged'
            'whenCreated')
    }
    $Groups = Get-ADGroup -Server $Domain -Filter * -ResultPageSize $ResultPageSize -Properties $Properties
    foreach ($_ in $Groups) { $DomainObjects.Add($_.DistinguishedName, $_) }
    $Groups
}
function Get-DomainGroupsPriviliged {
    [cmdletbinding()]
    param([Microsoft.ActiveDirectory.Management.ADDomain] $DomainInformation,
        [Array] $DomainGroups)
    $PrivilegedGroupsSID = @("S-1-5-32-544"
        "S-1-5-32-548"
        "S-1-5-32-549"
        "S-1-5-32-550"
        "S-1-5-32-551"
        "S-1-5-32-552"
        "S-1-5-32-556"
        "S-1-5-32-557"
        "S-1-5-32-573"
        "S-1-5-32-578"
        "S-1-5-32-580"
        "$($DomainInformation.DomainSID.Value)-512"
        "$($DomainInformation.DomainSID.Value)-518"
        "$($DomainInformation.DomainSID.Value)-519"
        "$($DomainInformation.DomainSID.Value)-520")
    foreach ($_ in $DomainGroups) { if ($PrivilegedGroupsSID -contains $_.'Group SID') { $_ } }
}
function Get-WinADDomainGroupsPriviligedMembers {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembers,
        [Array] $DomainGroupsPriviliged)
    foreach ($_ in $DomainGroupsMembers) { if ($DomainGroupsPriviliged.'Group SID' -contains ($_.'Group SID')) { $_ } }
}
function Get-WinADDomainGroupsPriviligedMembersRecursive {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembersRecursive,
        [Array] $DomainGroupsPriviliged)
    foreach ($_ in $DomainGroupsMembersRecursive) { if ($DomainGroupsPriviliged.'Group SID' -contains ($_.'Group SID')) { $_ } }
}
function Get-WinADDomainGroupsSpecial {
    [CmdletBinding()]
    param([Array] $DomainGroups)
    foreach ($_ in $DomainGroups) { if (($_.'Group SID').Length -eq 12) { $_ } }
}
function Get-WinADDomainGroupsSpecialMembers {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembers)
    foreach ($_ in $DomainGroupsMembers) { if (($_.'Group SID').Length -eq 12) { $_ } }
}
function Get-WinADDomainGroupsSpecialMembersRecursive {
    [CmdletBinding()]
    param([Array] $DomainGroupsMembersRecursive)
    foreach ($_ in $DomainGroupsMembersRecursive) { if (($_.'Group SID').Length -eq 12) { $_ } }
}
function Get-WinGroupMembers {
    [CmdletBinding()]
    param([Array] $Groups,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [ValidateSet("Recursive", "Standard")][String] $Option,
        [hashtable] $DomainObjects,
        [string] $Splitter)
    [DateTime] $CurrentDate = Get-Date
    if ($Option -eq 'Recursive') {
        [Array] $GroupMembersRecursive = foreach ($Group in $Groups) {
            try { $GroupMembership = Get-ADGroupMember -Server $Domain -Identity $Group.'Group SID' -Recursive -ErrorAction Stop } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning "Couldn't get information about group $($Group.Name) with SID $($Group.'Group SID') error: $ErrorMessage"
                continue
            }
            foreach ($Member in $GroupMembership) {
                $Object = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Member.DistinguishedName
                $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Object.Manager
                [PsCustomObject] @{'Group Name'         = $Group.'Group Name'
                    'Group SID'                         = $Group.'Group SID'
                    'Group Category'                    = $Group.'Group Category'
                    'Group Scope'                       = $Group.'Group Scope'
                    'High Privileged Group'             = if ($Group.adminCount -eq 1) { $True } else { $False }
                    'Display Name'                      = $Object.DisplayName
                    'Name'                              = $Member.Name
                    'User Principal Name'               = $Object.UserPrincipalName
                    'Sam Account Name'                  = $Object.SamAccountName
                    'Email Address'                     = $Object.EmailAddress
                    'PasswordExpired'                   = $Object.PasswordExpired
                    'PasswordLastSet'                   = $Object.PasswordLastSet
                    'PasswordNotRequired'               = $Object.PasswordNotRequired
                    'PasswordNeverExpires'              = $Object.PasswordNeverExpires
                    'Enabled'                           = $Object.Enabled
                    'SID'                               = $Member.SID.Value
                    'Manager'                           = $Manager.Name
                    'ManagerEmail'                      = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
                    'DateExpiry'                        = Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")
                    "DaysToExpire"                      = (Convert-TimeToDays -StartTime $CurrentDate -EndTime (Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")))
                    "AccountExpirationDate"             = $Object.AccountExpirationDate
                    "AccountLockoutTime"                = $Object.AccountLockoutTime
                    "AllowReversiblePasswordEncryption" = $Object.AllowReversiblePasswordEncryption
                    "BadLogonCount"                     = $Object.BadLogonCount
                    "CannotChangePassword"              = $Object.CannotChangePassword
                    "CanonicalName"                     = $Object.CanonicalName
                    'Given Name'                        = $Object.GivenName
                    'Surname'                           = $Object.Surname
                    "Description"                       = $Object.Description
                    "DistinguishedName"                 = $Object.DistinguishedName
                    "EmployeeID"                        = $Object.EmployeeID
                    "EmployeeNumber"                    = $Object.EmployeeNumber
                    "LastBadPasswordAttempt"            = $Object.LastBadPasswordAttempt
                    "LastLogonDate"                     = $Object.LastLogonDate
                    "Created"                           = $Object.Created
                    "Modified"                          = $Object.Modified
                    "Protected"                         = $Object.ProtectedFromAccidentalDeletion
                    "Domain"                            = $Domain
                }
            }
        }
        if ($GroupMembersRecursive.Count -eq 1) { return , $GroupMembersRecursive }
        return $GroupMembersRecursive
    }
    if ($Option -eq 'Standard') {
        [Array] $GroupMembersDirect = foreach ($Group in $Groups) {
            foreach ($Member in $Group.'Group Members DN') {
                $Object = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Member
                $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Object.Manager
                [PsCustomObject] @{'Group Name'         = $Group.'Group Name'
                    'Group SID'                         = $Group.'Group SID'
                    'Group Category'                    = $Group.'Group Category'
                    'Group Scope'                       = $Group.'Group Scope'
                    'DisplayName'                       = $Object.DisplayName
                    'High Privileged Group'             = if ($Group.adminCount -eq 1) { $True } else { $False }
                    'UserPrincipalName'                 = $Object.UserPrincipalName
                    'SamAccountName'                    = $Object.SamAccountName
                    'EmailAddress'                      = $Object.EmailAddress
                    'PasswordExpired'                   = $Object.PasswordExpired
                    'PasswordLastSet'                   = $Object.PasswordLastSet
                    'PasswordNotRequired'               = $Object.PasswordNotRequired
                    'PasswordNeverExpires'              = $Object.PasswordNeverExpires
                    'Enabled'                           = $Object.Enabled
                    'Manager'                           = $Manager.Name
                    'ManagerEmail'                      = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
                    'DateExpiry'                        = Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")
                    "DaysToExpire"                      = (Convert-TimeToDays -StartTime $CurrentDate -EndTime (Convert-ToDateTime -Timestring $($Object."msDS-UserPasswordExpiryTimeComputed")))
                    "AccountExpirationDate"             = $Object.AccountExpirationDate
                    "AccountLockoutTime"                = $Object.AccountLockoutTime
                    "AllowReversiblePasswordEncryption" = $Object.AllowReversiblePasswordEncryption
                    "BadLogonCount"                     = $Object.BadLogonCount
                    "CannotChangePassword"              = $Object.CannotChangePassword
                    "CanonicalName"                     = $Object.CanonicalName
                    "Description"                       = $Object.Description
                    "DistinguishedName"                 = $Object.DistinguishedName
                    "EmployeeID"                        = $Object.EmployeeID
                    "EmployeeNumber"                    = $Object.EmployeeNumber
                    "LastBadPasswordAttempt"            = $Object.LastBadPasswordAttempt
                    "LastLogonDate"                     = $Object.LastLogonDate
                    'Name'                              = $Object.Name
                    'SID'                               = $Object.SID.Value
                    'GivenName'                         = $Object.GivenName
                    'Surname'                           = $Object.Surname
                    "Created"                           = $Object.Created
                    "Modified"                          = $Object.Modified
                    "Protected"                         = $Object.ProtectedFromAccidentalDeletion
                    "Domain"                            = $Domain
                }
            }
        }
        if ($GroupMembersDirect.Count -eq 1) { return , $GroupMembersDirect }
        return $GroupMembersDirect
    }
}
function Get-WinGroups {
    [CmdletBinding()]
    param ([Array] $Groups,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [string] $Splitter,
        [hashtable] $DomainObjects)
    $ReturnGroups = foreach ($Group in $Groups) {
        $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Group.ManagedBy
        [PsCustomObject] @{'Group Name' = [string] $Group.Name
            'Group Category'            = [string] $Group.GroupCategory
            'Group Scope'               = [string] $Group.GroupScope
            'Group SID'                 = [string] $Group.SID.Value
            'High Privileged Group'     = if ($Group.adminCount -eq 1) { $True } else { $False }
            'Member Count'              = $Group.Members.Count
            'MemberOf Count'            = $Group.MemberOf.Count
            'Manager'                   = $Manager.Name
            'Manager Email'             = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
            'Group Members'             = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $Group.Members -Splitter $Splitter -Type 'SamAccountName'
            'Group Members DN'          = $Group.Members
            "Domain"                    = $Domain
        }
    }
    return $ReturnGroups
}
function Get-WinADDomainPassword {
    [CmdletBinding()]
    param($DnsRoot,
        $DistinguishedName)
    try { Get-ADReplAccount -All -Server $DnsRoot -NamingContext $DistinguishedName } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($ErrorMessage -like '*is not recognized as the name of a cmdlet*') { Write-Warning "Get-ADReplAccount - Please install module DSInternals (Install-Module DSInternals) - Error: $ErrorMessage" } else { Write-Warning "Get-ADReplAccount - Error occured: $ErrorMessage" }
    }
}
function Get-WinADDomainPasswordQuality {
    [CmdletBinding()]
    param ([string] $DnsRoot,
        [Array] $DomainUsersAll,
        [Array] $DomainComputersAll,
        [string] $DomainDistinguishedName,
        [Array] $PasswordQualityUsers,
        [string] $FilePath,
        [switch] $UseHashes,
        [switch] $PasswordQuality)
    if ($FilePath -eq '' -and $PasswordQuality.IsPresent -eq $true) { $FilePath = "$PSScriptRoot\Resources\PasswordList.txt" }
    if ($FilePath -eq '') {
        Write-Verbose "Get-WinADDomainPasswordQuality - File path not given, using hashes set to $UseHashes"
        return $null
    }
    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Verbose "Get-WinADDomainPasswordQuality - File path doesn't exists, using hashes set to $UseHashes"
        return $null
    }
    $Data = [ordered] @{ }
    if ($PasswordQualityUsers) { $Data.PasswordQualityUsers = $PasswordQualityUsers } else { $Data.PasswordQualityUsers = Get-ADReplAccount -All -Server $DnsRoot -NamingContext $DomainDistinguishedName }
    $Data.PasswordQuality = Invoke-Command -ScriptBlock { if ($UseHashes) { $Results = $Data.PasswordQualityUsers | Test-PasswordQuality -WeakPasswordHashesFile $FilePath -IncludeDisabledAccounts } else { $Results = $Data.PasswordQualityUsers | Test-PasswordQuality -WeakPasswordsFile $FilePath -IncludeDisabledAccounts }
        return $Results }
    $Data.DomainPasswordClearTextPassword = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.ClearTextPassword -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordClearTextPasswordEnabled = Invoke-Command -ScriptBlock { return $Data.DomainPasswordClearTextPassword | Where-Object { $_.Enabled -eq $true } }
    $Data.DomainPasswordClearTextPasswordDisabled = Invoke-Command -ScriptBlock { return $Data.DomainPasswordClearTextPassword | Where-Object { $_.Enabled -eq $false } }
    $Data.DomainPasswordLMHash = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.LMHash -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordEmptyPassword = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.EmptyPassword -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordWeakPassword = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.WeakPassword -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordWeakPasswordEnabled = Invoke-Command -ScriptBlock { return $Data.DomainPasswordWeakPassword | Where-Object { $_.Enabled -eq $true } }
    $Data.DomainPasswordWeakPasswordDisabled = Invoke-Command -ScriptBlock { return $Data.DomainPasswordWeakPassword | Where-Object { $_.Enabled -eq $false } }
    $Data.DomainPasswordWeakPasswordList = Invoke-Command -ScriptBlock { if ($UseHashes) { return '' } else {
            $Passwords = Get-Content -Path $FilePath
            return $Passwords -join ', '
        } }
    $Data.DomainPasswordDefaultComputerPassword = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.DefaultComputerPassword -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordPasswordNotRequired = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.PasswordNotRequired -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordPasswordNeverExpires = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.PasswordNeverExpires -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordAESKeysMissing = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.AESKeysMissing -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordPreAuthNotRequired = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.PreAuthNotRequired -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordDESEncryptionOnly = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.DESEncryptionOnly -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordDelegatableAdmins = Invoke-Command -ScriptBlock { $ADAccounts = Get-WinADAccounts -UserNameList $Data.PasswordQuality.DelegatableAdmins -ADCatalog $DomainUsersAll, $DomainComputersAll
        return $ADAccounts | Select-Object 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    $Data.DomainPasswordDuplicatePasswordGroups = Invoke-Command -ScriptBlock { $DuplicateGroups = $Data.PasswordQuality.DuplicatePasswordGroups.ToArray()
        $Count = 0
        $Value = foreach ($DuplicateGroup in $DuplicateGroups) {
            $Count++
            $Name = "Duplicate $Count"
            foreach ($User in $DuplicateGroup) {
                $FoundUser = [pscustomobject] @{'Duplicate Group' = $Name }
                $FullUserInformation = foreach ($_ in $DomainUsersAll) { if ($_.SamAccountName -eq $User) { $_ } }
                $FullComputerInformation = foreach ($_ in $DomainComputersAll) { if ($_.SamAccountName -eq $User) { $_ } }
                if ($FullUserInformation) { $MergedObject = Merge-Objects -Object1 $FoundUser -Object2 $FullUserInformation }
                if ($FullComputerInformation) { $MergedObject = Merge-Objects -Object1 $MergedObject -Object2 $FullComputerInformation }
                $MergedObject
            }
        }
        return $Value | Select-Object 'Duplicate Group', 'Name', 'UserPrincipalName', 'Enabled', 'Password Last Changed', "DaysToExpire", 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'DateExpiry', 'PasswordLastSet', 'SamAccountName', 'EmailAddress', 'Display Name', 'Given Name', 'Surname', 'Manager', 'Manager Email', "AccountExpirationDate", "AccountLockoutTime", "AllowReversiblePasswordEncryption", "BadLogonCount", "CannotChangePassword", "CanonicalName", "Description", "DistinguishedName", "EmployeeID", "EmployeeNumber", "LastBadPasswordAttempt", "LastLogonDate", "Created", "Modified", "Protected", "Primary Group", "Member Of", "Domain" }
    return $Data
}
function Get-WinADDomainPasswordStats {
    [CmdletBinding()]
    param($PasswordsQuality,
        $TypesRequired,
        $DomainPasswordHashesWeakPassword,
        $DomainPasswordHashesWeakPasswordEnabled,
        $DomainPasswordHashesWeakPasswordDisabled)
    $Stats = [ordered] @{ }
    $Stats.'Clear Text Passwords' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordClearTextPassword
    $Stats.'LM Hashes' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordLMHash
    $Stats.'Empty Passwords' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordEmptyPassword
    $Stats.'Weak Passwords' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordWeakPassword
    $Stats.'Weak Passwords Enabled' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordWeakPasswordEnabled
    $Stats.'Weak Passwords Disabled' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordWeakPasswordDisabled
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword)) { $Stats.'Weak Passwords (HASH)' = Get-ObjectCount -Object $DomainPasswordHashesWeakPassword }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled)) { $Stats.'Weak Passwords (HASH) Enabled' = Get-ObjectCount -Object $DomainPasswordHashesWeakPasswordEnabled }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled)) { $Stats.'Weak Passwords (HASH) Disabled' = Get-ObjectCount -Object $DomainPasswordHashesWeakPasswordDisabled }
    $Stats.'Default Computer Passwords' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordDefaultComputerPassword
    $Stats.'Password Not Required' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordPasswordNotRequired
    $Stats.'Password Never Expires' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordPasswordNeverExpires
    $Stats.'AES Keys Missing' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordAESKeysMissing
    $Stats.'PreAuth Not Required' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordPreAuthNotRequired
    $Stats.'DES Encryption Only' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordDESEncryptionOnly
    $Stats.'Delegatable Admins' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordDelegatableAdmins
    $Stats.'Duplicate Password Users' = Get-ObjectCount -Object $PasswordsQuality.DomainPasswordDuplicatePasswordGroups
    $Stats.'Duplicate Password Grouped' = Get-ObjectCount ($PasswordsQuality.DomainPasswordDuplicatePasswordGroups.'Duplicate Group' | Sort-Object -Unique)
    return $Stats
}
function Get-WinADDomainAllUsersCount {
    [CmdletBinding()]
    param([Array] $DomainUsers,
        [Array] $DomainUsersAll,
        [Array] $DomainUsersExpiredExclDisabled,
        [Array] $DomainUsersExpiredInclDisabled,
        [Array] $DomainUsersNeverExpiring,
        [Array] $DomainUsersNeverExpiringInclDisabled,
        [Array] $DomainUsersSystemAccounts)
    $DomainUsersCount = [ordered] @{'Users Count Incl. System' = $DomainUsers.Count
        'Users Count'                                          = $DomainUsersAll.Count
        'Users Expired'                                        = $DomainUsersExpiredExclDisabled.Count
        'Users Expired Incl. Disabled'                         = $DomainUsersExpiredInclDisabled.Count
        'Users Never Expiring'                                 = $DomainUsersNeverExpiring.Count
        'Users Never Expiring Incl. Disabled'                  = $DomainUsersNeverExpiringInclDisabled.Count
        'Users System Accounts'                                = $DomainUsersSystemAccounts.Count
    }
    return $DomainUsersCount
}
function Get-WinADDomainUsersAll {
    [CmdletBinding()]
    param([Array] $Users,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [HashTable] $DomainObjects,
        [string] $Splitter)
    [DateTime] $CurrentDate = Get-Date
    $UserList = foreach ($U in $Users) {
        $Manager = Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $U.Manager
        [PsCustomObject] @{'Name'               = $U.Name
            'UserPrincipalName'                 = $U.UserPrincipalName
            'SamAccountName'                    = $U.SamAccountName
            'DisplayName'                       = $U.DisplayName
            'GivenName'                         = $U.GivenName
            'Surname'                           = $U.Surname
            'EmailAddress'                      = $U.EmailAddress
            'PasswordExpired'                   = $U.PasswordExpired
            'PasswordLastSet'                   = $U.PasswordLastSet
            'PasswordLastChanged(Days)'         = if ($null -ne $U.PasswordLastSet) { "$(-$($U.PasswordLastSet - $CurrentDate).Days)" } else { }
            'PasswordNotRequired'               = $U.PasswordNotRequired
            'PasswordNeverExpires'              = $U.PasswordNeverExpires
            'Enabled'                           = $U.Enabled
            'Manager'                           = $Manager.Name
            'ManagerEmail'                      = if ($Splitter -ne '') { $Manager.EmailAddress -join $Splitter } else { $Manager.EmailAddress }
            'DateExpiry'                        = Convert-ToDateTime -Timestring $($U."msDS-UserPasswordExpiryTimeComputed")
            "DaysToExpire"                      = (Convert-TimeToDays -StartTime $CurrentDate -EndTime (Convert-ToDateTime -Timestring $($U."msDS-UserPasswordExpiryTimeComputed")))
            "AccountExpirationDate"             = $U.AccountExpirationDate
            "AccountLockoutTime"                = $U.AccountLockoutTime
            "AllowReversiblePasswordEncryption" = $U.AllowReversiblePasswordEncryption
            "BadLogonCount"                     = $U.BadLogonCount
            "CannotChangePassword"              = $U.CannotChangePassword
            "CanonicalName"                     = $U.CanonicalName
            "Description"                       = $U.Description
            "DistinguishedName"                 = $U.DistinguishedName
            "EmployeeID"                        = $U.EmployeeID
            "EmployeeNumber"                    = $U.EmployeeNumber
            "LastBadPasswordAttempt"            = $U.LastBadPasswordAttempt
            "LastLogonDate"                     = $U.LastLogonDate
            "Created"                           = $U.Created
            "Modified"                          = $U.Modified
            "Protected"                         = $U.ProtectedFromAccidentalDeletion
            "Primary Group"                     = (Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $U.PrimaryGroup -Type 'SamAccountName')
            "Member Of"                         = (Get-ADObjectFromDNHash -ADCatalog $DomainObjects -DistinguishedName $U.MemberOf -Type 'SamAccountName' -Splitter $Splitter)
            "Domain"                            = $Domain
        }
    }
    return $UserList
}
function Get-WinADDomainUsersAllFiltered {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNotRequired -eq $False) { $_ } }
}
function Get-WinADDomainUsersExpiredExclDisabled {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNeverExpires -eq $false -and $_.DaysToExpire -le 0 -and $_.Enabled -eq $true -and $_.PasswordNotRequired -eq $false) { $_ } }
}
function Get-WinADDomainUsersExpiredInclDisabled {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNeverExpires -eq $false -and $_.DaysToExpire -le 0 -and $_.PasswordNotRequired -eq $false) { $_ } }
}
function Get-WinADDomainUsersFullList {
    [CmdletBinding()]
    param([string] $Domain = $Env:USERDNSDOMAIN,
        [switch] $Extended,
        [Array] $ForestSchemaUsers,
        [System.Collections.IDictionary] $DomainObjects,
        [int] $ResultPageSize = 500000)
    if ($null -eq $ForestSchemaUsers) {
        $ForestSchemaUsers = @($Schema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
            @($Schema.FindClass("user").MandatoryProperties
                $Schema.FindClass("user").OptionalProperties
                $Schema.FindClass("user").PossibleSuperiors
                $Schema.FindClass("user").PossibleInferiors
                $Schema.FindClass("user").AuxiliaryClasses))
    }
    if ($Extended) { [string] $Properties = '*' } else {
        $Properties = @('Name'
            'UserPrincipalName'
            'SamAccountName'
            'DisplayName'
            'GivenName'
            'Surname'
            'EmailAddress'
            'PasswordExpired'
            'PasswordLastSet'
            'PasswordNotRequired'
            'PasswordNeverExpires'
            'Enabled'
            'Manager'
            'msDS-UserPasswordExpiryTimeComputed'
            'AccountExpirationDate'
            'AccountLockoutTime'
            'AllowReversiblePasswordEncryption'
            'BadLogonCount'
            'CannotChangePassword'
            'CanonicalName'
            'Description'
            'DistinguishedName'
            'EmployeeID'
            'EmployeeNumber'
            'LastBadPasswordAttempt'
            'LastLogonDate'
            'Created'
            'Modified'
            'ProtectedFromAccidentalDeletion'
            'PrimaryGroup'
            'MemberOf'
            if ($ForestSchemaUsers.Name -contains 'ExtensionAttribute1') {
                'ExtensionAttribute1'
                'ExtensionAttribute2'
                'ExtensionAttribute3'
                'ExtensionAttribute4'
                'ExtensionAttribute5'
                'ExtensionAttribute6'
                'ExtensionAttribute7'
                'ExtensionAttribute8'
                'ExtensionAttribute9'
                'ExtensionAttribute10'
                'ExtensionAttribute11'
                'ExtensionAttribute12'
                'ExtensionAttribute13'
                'ExtensionAttribute14'
                'ExtensionAttribute15'
            })
    }
    $Users = Get-ADUser -Server $Domain -ResultPageSize $ResultPageSize -Filter * -Properties $Properties
    if ($null -ne $DomainObjects) { foreach ($_ in $Users) { $DomainObjects.Add($_.DistinguishedName, $_) } }
    $Users
}
function Get-WinADDomainUsersNeverExpiring {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNeverExpires -eq $true -and $_.Enabled -eq $true -and $_.PasswordNotRequired -eq $false) { $_ } }
}
function Get-WinADDomainUsersNeverExpiringInclDisabled {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNeverExpires -eq $true -and $_.PasswordNotRequired -eq $false) { $_ } }
}
function Get-WinADDomainUsersSystemAccounts {
    [CmdletBinding()]
    param([Array] $DomainUsers)
    foreach ($_ in $DomainUsers) { if ($_.PasswordNotRequired -eq $true) { $_ } }
}
function Get-WinADForest {
    [CmdletBinding()]
    param()
    try { Get-ADForest -ErrorAction Stop } catch { $null }
}
function Get-WinADForestFSMO {
    [CmdletBinding()]
    param([PSCustomObject] $Forest)
    [ordered] @{'Domain Naming Master' = $Forest.DomainNamingMaster
        'Schema Master'                = $Forest.SchemaMaster
    }
}
function Get-WinADForestInfo {
    [CmdletBinding()]
    param([PSCustomObject] $Forest,
        [Microsoft.ActiveDirectory.Management.ADRootDSE] $RootDSE)
    [ordered] @{'Name'             = $Forest.Name
        'Root Domain'              = $Forest.RootDomain
        'Forest Distingushed Name' = $RootDSE.defaultNamingContext
        'Forest Functional Level'  = $Forest.ForestMode
        'Domains Count'            = ($Forest.Domains).Count
        'Sites Count'              = ($Forest.Sites).Count
        'Domains'                  = ($Forest.Domains) -join ", "
        'Sites'                    = ($Forest.Sites) -join ", "
    }
}
function Get-WinADForestOptionalFeatures {
    [CmdletBinding()]
    param([Array] $ComputerProperties)
    if (-not $ComputerProperties) { $ComputerProperties = Get-WinADForestSchemaPropertiesComputers }
    $LapsProperties = 'ms-Mcs-AdmPwd'
    $OptionalFeatures = $(Get-ADOptionalFeature -Filter *)
    $Optional = [ordered]@{'Recycle Bin Enabled'       = $false
        'Privileged Access Management Feature Enabled' = $false
        'Laps Enabled'                                 = ($ComputerProperties.Name -contains $LapsProperties)
    }
    foreach ($Feature in $OptionalFeatures) {
        if ($Feature.Name -eq 'Recycle Bin Feature') { $Optional.'Recycle Bin Enabled' = $Feature.EnabledScopes.Count -gt 0 }
        if ($Feature.Name -eq 'Privileged Access Management Feature') { $Optional.'Privileged Access Management Feature Enabled' = $Feature.EnabledScopes.Count -gt 0 }
    }
    return $Optional
}
function Get-WinADForestRoles {
    [alias('Get-WinADRoles', 'Get-WinADDomainRoles')]
    param([string] $Domain,
        [switch] $Formatted,
        [string] $Splitter = ', ')
    $DomainControllers = Get-WinADForestControllers -Domain $Domain
    $Roles = [ordered] @{SchemaMaster = $null
        DomainNamingMaster            = $null
        PDCEmulator                   = $null
        RIDMaster                     = $null
        InfrastructureMaster          = $null
        IsReadOnly                    = $null
        IsGlobalCatalog               = $null
    }
    foreach ($_ in $DomainControllers) {
        if ($_.SchemaMaster -eq $true) { $Roles['SchemaMaster'] = if ($null -ne $Roles['SchemaMaster']) { @($Roles['SchemaMaster']) + $_.HostName } else { $_.HostName } }
        if ($_.DomainNamingMaster -eq $true) { $Roles['DomainNamingMaster'] = if ($null -ne $Roles['DomainNamingMaster']) { @($Roles['DomainNamingMaster']) + $_.HostName } else { $_.HostName } }
        if ($_.PDCEmulator -eq $true) { $Roles['PDCEmulator'] = if ($null -ne $Roles['PDCEmulator']) { @($Roles['PDCEmulator']) + $_.HostName } else { $_.HostName } }
        if ($_.RIDMaster -eq $true) { $Roles['RIDMaster'] = if ($null -ne $Roles['RIDMaster']) { @($Roles['RIDMaster']) + $_.HostName } else { $_.HostName } }
        if ($_.InfrastructureMaster -eq $true) { $Roles['InfrastructureMaster'] = if ($null -ne $Roles['InfrastructureMaster']) { @($Roles['InfrastructureMaster']) + $_.HostName } else { $_.HostName } }
        if ($_.IsReadOnly -eq $true) { $Roles['IsReadOnly'] = if ($null -ne $Roles['IsReadOnly']) { @($Roles['IsReadOnly']) + $_.HostName } else { $_.HostName } }
        if ($_.IsGlobalCatalog -eq $true) { $Roles['IsGlobalCatalog'] = if ($null -ne $Roles['IsGlobalCatalog']) { @($Roles['IsGlobalCatalog']) + $_.HostName } else { $_.HostName } }
    }
    if ($Formatted) { foreach ($_ in ([string[]] $Roles.Keys)) { $Roles[$_] = $Roles[$_] -join $Splitter } }
    $Roles
}
function Get-WinADForestSchemaPropertiesComputers {
    [CmdletBinding()]
    param()
    $Schema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
    @($Schema.FindClass("computer").mandatoryproperties | Select-Object name, commonname, description, syntax
        $Schema.FindClass("computer").optionalproperties | Select-Object name, commonname, description, syntax)
}
function Get-WinADForestSchemaPropertiesUsers {
    [CmdletBinding()]
    param()
    $Schema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
    @($Schema.FindClass("user").mandatoryproperties | Select-Object name, commonname, description, syntax
        $Schema.FindClass("user").optionalproperties | Select-Object name, commonname, description, syntax)
}
function Get-WinADForestSiteLinks {
    [CmdletBinding()]
    param()
    $ExludedProperties = @('PropertyNames', 'AddedProperties', 'RemovedProperties', 'ModifiedProperties', 'PropertyCount')
    $Properties = @('Name', 'Cost', 'ReplicationFrequencyInMinutes', 'ReplInterval',
        'ReplicationSchedule', 'Created', 'Modified', 'Deleted', 'InterSiteTransportProtocol',
        'DistinguishedName', 'ProtectedFromAccidentalDeletion')
    return Get-ADReplicationSiteLink -Filter * -Properties $Properties | Select-Object -Property $Properties -ExcludeProperty $ExludedProperties
}
function Get-WinADForestSites {
    [CmdletBinding()]
    param([switch] $Formatted,
        [string] $Splitter)
    $DomainControllers = Get-WinADForestControllers
    $Sites = Get-ADReplicationSite -Filter * -Properties *
    foreach ($Site in $Sites) {
        [Array] $DCs = $DomainControllers | Where-Object { $_.Site -eq $Site.Name }
        [Array] $Subnets = ConvertFrom-DistinguishedName -DistinguishedName $Site.'Subnets'
        if ($Formatted) {
            [PSCustomObject] @{'Name'                                     = $Site.Name
                'Display Name'                                            = $Site.'DisplayName'
                'Description'                                             = $Site.'Description'
                'CanonicalName'                                           = $Site.'CanonicalName'
                'DistinguishedName'                                       = $Site.'DistinguishedName'
                'Location'                                                = $Site.'Location'
                'ManagedBy'                                               = $Site.'ManagedBy'
                'Protected From Accidental Deletion'                      = $Site.'ProtectedFromAccidentalDeletion'
                'Redundant Server Topology Enabled'                       = $Site.'RedundantServerTopologyEnabled'
                'Automatic Inter-Site Topology Generation Enabled'        = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'Automatic Topology Generation Enabled'                   = $Site.'AutomaticTopologyGenerationEnabled'
                'Subnets'                                                 = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'Subnets Count'                                           = $Subnets.Count
                'Domain Controllers'                                      = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'Domain Controllers Count'                                = $DCs.Count
                'sDRightsEffective'                                       = $_.'sDRightsEffective'
                'Topology Cleanup Enabled'                                = $_.'TopologyCleanupEnabled'
                'Topology Detect Stale Enabled'                           = $_.'TopologyDetectStaleEnabled'
                'Topology Minimum Hops Enabled'                           = $_.'TopologyMinimumHopsEnabled'
                'Universal Group Caching Enabled'                         = $_.'UniversalGroupCachingEnabled'
                'Universal Group Caching Refresh Site'                    = $_.'UniversalGroupCachingRefreshSite'
                'Windows Server 2000 Bridgehead Selection Method Enabled' = $_.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'Windows Server 2000 KCC ISTG Selection Behavior Enabled' = $_.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'Windows Server 2003 KCC Behavior Enabled'                = $_.'WindowsServer2003KCCBehaviorEnabled'
                'Windows Server 2003 KCC Ignore Schedule Enabled'         = $_.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'Windows Server 2003 KCC SiteLink Bridging Enabled'       = $_.'WindowsServer2003KCCSiteLinkBridgingEnabled'
                'Created'                                                 = $Site.Created
                'Modified'                                                = $Site.Modified
                'Deleted'                                                 = $Site.Deleted
            }
        } else {
            [PSCustomObject] @{'Name'                               = $Site.Name
                'DisplayName'                                       = $Site.'DisplayName'
                'Description'                                       = $Site.'Description'
                'CanonicalName'                                     = $Site.'CanonicalName'
                'DistinguishedName'                                 = $Site.'DistinguishedName'
                'Location'                                          = $Site.'Location'
                'ManagedBy'                                         = $Site.'ManagedBy'
                'ProtectedFromAccidentalDeletion'                   = $Site.'ProtectedFromAccidentalDeletion'
                'RedundantServerTopologyEnabled'                    = $Site.'RedundantServerTopologyEnabled'
                'AutomaticInterSiteTopologyGenerationEnabled'       = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'AutomaticTopologyGenerationEnabled'                = $Site.'AutomaticTopologyGenerationEnabled'
                'Subnets'                                           = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'SubnetsCount'                                      = $Subnets.Count
                'DomainControllers'                                 = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'DomainControllersCount'                            = $DCs.Count
                'sDRightsEffective'                                 = $_.'sDRightsEffective'
                'TopologyCleanupEnabled'                            = $_.'TopologyCleanupEnabled'
                'TopologyDetectStaleEnabled'                        = $_.'TopologyDetectStaleEnabled'
                'TopologyMinimumHopsEnabled'                        = $_.'TopologyMinimumHopsEnabled'
                'UniversalGroupCachingEnabled'                      = $_.'UniversalGroupCachingEnabled'
                'UniversalGroupCachingRefreshSite'                  = $_.'UniversalGroupCachingRefreshSite'
                'WindowsServer2000BridgeheadSelectionMethodEnabled' = $_.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'WindowsServer2000KCCISTGSelectionBehaviorEnabled'  = $_.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'WindowsServer2003KCCBehaviorEnabled'               = $_.'WindowsServer2003KCCBehaviorEnabled'
                'WindowsServer2003KCCIgnoreScheduleEnabled'         = $_.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'WindowsServer2003KCCSiteLinkBridgingEnabled'       = $_.'WindowsServer2003KCCSiteLinkBridgingEnabled'
                'Created'                                           = $Site.Created
                'Modified'                                          = $Site.Modified
                'Deleted'                                           = $Site.Deleted
            }
        }
    }
}
function Get-WinADForestSPNSuffixes {
    [CmdletBinding()]
    param([PSCustomObject] $Forest)
    @(foreach ($SPN in $Forest.SPNSuffixes) { [PSCustomObject] @{Name = $SPN } })
}
function Get-WinADForestSubnets {
    [CmdletBinding()]
    param()
    $ExludedProperties = @('PropertyNames', 'AddedProperties', 'RemovedProperties', 'ModifiedProperties', 'PropertyCount')
    $Properties = @('Name', 'DisplayName', 'Description', 'Site', 'ProtectedFromAccidentalDeletion', 'Created', 'Modified', 'Deleted')
    return Get-ADReplicationSubnet -Filter * -Properties $Properties | Select-Object -Property $Properties -ExcludeProperty $ExludedProperties
}
function Get-WinADForestSubnets1 {
    [CmdletBinding()]
    param([Array] $ForestSubnets)
    foreach ($Subnets in $ForestSubnets) {
        [PsCustomObject] @{'Name' = $Subnets.Name
            'Description'         = $Subnets.Description
            'Protected'           = $Subnets.ProtectedFromAccidentalDeletion
            'Modified'            = $Subnets.Modified
            'Created'             = $Subnets.Created
            'Deleted'             = $Subnets.Deleted
        }
    }
}
function Get-WinADForestSubnets2 {
    param([Array] $ForestSubnets)
    @(foreach ($Subnets in $ForestSubnets) {
            [PsCustomObject] @{'Name' = $Subnets.Name
                'Site'                = $Subnets.Site
            }
        })
}
function Get-WinADForestUPNSuffixes {
    param([PSCustomObject] $Forest)
    @([PSCustomObject] @{Name = $Forest.RootDomain
            Type              = 'Primary / Default UPN'
        }
        foreach ($UPN in $Forest.UPNSuffixes) {
            [PSCustomObject] @{Name = $UPN
                Type                = 'Secondary'
            }
        })
}
function Get-ADObjectFromDNHash {
    [CmdletBinding()]
    param ([string[]] $DistinguishedName,
        [hashtable] $ADCatalog,
        [string] $Type = '',
        [string] $Splitter)
    if ($null -eq $DistinguishedName) { return }
    $FoundObjects = foreach ($DN in $DistinguishedName) { if ($Type -eq '') { $ADCatalog.$DN } else { $ADCatalog.$DN.$Type } }
    if ($Splitter) { return ($FoundObjects | Sort-Object) -join $Splitter } else { return $FoundObjects | Sort-Object }
}
function Get-WinADAccounts {
    [CmdletBinding()]
    param([Array] $UserNameList,
        [Array[]] $ADCatalog)
    $Accounts = foreach ($User in $UserNameList) { foreach ($Catalog in $ADCatalog) { foreach ($_ in $Catalog) { if ($_.SamAccountName -eq $User) { $_ } } } }
    return $Accounts
}
function Get-WinADDomainInformation {
    [CmdletBinding()]
    param ([string] $Domain,
        [PSWinDocumentation.ActiveDirectory[]] $TypesRequired,
        [string] $PathToPasswords,
        [string] $PathToPasswordsHashes,
        [switch] $Extended,
        [switch] $Formatted,
        [Array] $ForestSchemaComputers,
        [Array] $ForestSchemaUsers,
        [switch] $PasswordQuality,
        [alias('Joiner')][string] $Splitter,
        [switch] $Parallel,
        [int] $ResultPageSize = 500000)
    $Formatted = $true
    $PSDefaultParameterValues["Get-DataInformation:Verbose"] = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
    $Data = [ordered] @{ }
    if ($Domain -eq '') {
        Write-Warning 'Get-WinADDomainInformation - $Domain parameter is empty. Try your domain name like ad.evotec.xyz. Skipping for now...'
        return
    }
    if ($null -eq $TypesRequired) {
        Write-Verbose 'Get-WinADDomainInformation - TypesRequired is null. Getting all.'
        $TypesRequired = Get-Types -Types ([PSWinDocumentation.ActiveDirectory])
    }
    $TimeToGenerate = Start-TimeLog
    if ($null -eq $ForestSchemaComputers) {
        $ForestSchemaComputers = Get-DataInformation -Text "Getting domain information - ForestSchemaPropertiesComputers" { Get-WinADForestSchemaPropertiesComputers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSchemaPropertiesComputers
            [PSWinDocumentation.ActiveDirectory]::DomainComputersFullList
            [PSWinDocumentation.ActiveDirectory]::DomainComputersAll
            [PSWinDocumentation.ActiveDirectory]::DomainComputersAllCount
            [PSWinDocumentation.ActiveDirectory]::DomainServers
            [PSWinDocumentation.ActiveDirectory]::DomainServersCount
            [PSWinDocumentation.ActiveDirectory]::DomainComputers
            [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
            [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
            [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
            [PSWinDocumentation.ActiveDirectory]::DomainBitlocker
            [PSWinDocumentation.ActiveDirectory]::DomainLAPS)
    }
    if ($null -eq $ForestSchemaUsers) {
        $ForestSchemaUsers = Get-DataInformation -Text "Getting domain information - ForestSchemaPropertiesUsers" { Get-WinADForestSchemaPropertiesUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSchemaPropertiesUsers
            [PSWinDocumentation.ActiveDirectory]::DomainUsersFullList)
    }
    $Data.DomainObjects = @{ }
    $Data.DomainRootDSE = Get-DataInformation -Text "Getting domain information - $Domain DomainRootDSE" { Get-WinADRootDSE -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainRootDSE
        [PSWinDocumentation.ActiveDirectory]::DomainGUIDS
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsBasicACL
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtendedACL)
    $Data.DomainInformation = Get-DataInformation -Text "Getting domain information - $Domain DomainInformation" { Get-WinADDomain -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainInformation
        [PSWinDocumentation.ActiveDirectory]::DomainRIDs
        [PSWinDocumentation.ActiveDirectory]::DomainFSMO
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsDN
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsBasicACL
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtendedACL
        [PSWinDocumentation.ActiveDirectory]::DomainAdministrators
        [PSWinDocumentation.ActiveDirectory]::DomainAdministratorsRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministrators
        [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministratorsRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDataPasswords
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordClearTextPassword
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordLMHash
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordEmptyPassword
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPassword
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordEnabled
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordList
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDefaultComputerPassword
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNotRequired
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNeverExpires
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordAESKeysMissing
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPreAuthNotRequired
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDESEncryptionOnly
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDelegatableAdmins
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDuplicatePasswordGroups
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordStats
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged)
    $Data.DomainGroupsFullList = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsFullList" { Get-WinADDomainGroupsFullList -Domain $Domain -DomainObjects $Data.DomainObjects -ResultPageSize $ResultPageSize } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsFullList
        [PSWinDocumentation.ActiveDirectory]::DomainUsers
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsers
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsersExtended
        [PSWinDocumentation.ActiveDirectory]::DomainGroups
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembersRecursive)
    $Data.DomainUsersFullList = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersFullList" { Get-WinADDomainUsersFullList -Domain $Domain -Extended:$Extended -ForestSchemaUsers $ForestSchemaUsers -DomainObjects $Data.DomainObjects -ResultPageSize $ResultPageSize } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersFullList
        [PSWinDocumentation.ActiveDirectory]::DomainUsers
        [PSWinDocumentation.ActiveDirectory]::DomainUsersAll
        [PSWinDocumentation.ActiveDirectory]::DomainUsersSystemAccounts
        [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiring
        [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiringInclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredInclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredExclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersCount
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsers
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsersExtended
        [PSWinDocumentation.ActiveDirectory]::DomainGroups
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembersRecursive)
    $Data.DomainComputersFullList = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersFullList" { Get-WinADDomainComputersFullList -Domain $Domain -ForestSchemaComputers $ForestSchemaComputers -DomainObjects $Data.DomainObjects -ResultPageSize $ResultPageSize } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersFullList
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAll
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAllCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAllBuildCount
        [PSWinDocumentation.ActiveDirectory]::DomainServers
        [PSWinDocumentation.ActiveDirectory]::DomainServersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
        [PSWinDocumentation.ActiveDirectory]::DomainBitlocker
        [PSWinDocumentation.ActiveDirectory]::DomainLAPS
        [PSWinDocumentation.ActiveDirectory]::DomainUsers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsMembersRecursive)
    $Data.DomainComputersAll = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersAll" { Get-WinADDomainComputersAll -DomainComputersFullList $Data.DomainComputersFullList -Splitter $Splitter -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersAll
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAllCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAllBuildCount
        [PSWinDocumentation.ActiveDirectory]::DomainServers
        [PSWinDocumentation.ActiveDirectory]::DomainServersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDataPasswords)
    $Data.DomainComputersAllCount = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersAllCount" { Get-WinADDomainComputersAllCount -DomainComputersAll $Data.DomainComputersAll } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersAllCount)
    $Data.DomainComputersAllBuildCount = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersAllBuildCount" { Get-WinADDomainComputersAllBuildSummary -DomainComputers $Data.DomainComputersAll -Formatted:$Formatted } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersAllBuildCount)
    $Data.DomainServers = Get-DataInformation -Text "Getting domain information - $Domain DomainServers" { Get-WinADDomainServers -DomainComputersAll $Data.DomainComputersAll } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainServers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAll)
    $Data.DomainServersCount = Get-DataInformation -Text "Getting domain information - $Domain DomainServersCount" { Get-WinADDomainServersCount -DomainServers $Data.DomainServers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainServersCount
        [PSWinDocumentation.ActiveDirectory]::DomainServers)
    $Data.DomainComputers = Get-DataInformation -Text "Getting domain information - $Domain DomainComputers" { Get-WinADDomainComputers -DomainComputersAll $Data.DomainComputersAll } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAll)
    $Data.DomainComputersCount = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersCount" { Get-WinADDomainComputersCount -DomainComputers $Data.DomainComputers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputers)
    $Data.DomainComputersUnknown = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersUnknown" { Get-WinADDomainComputersUnknown -DomainComputersAll $Data.DomainComputersAll } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAll)
    $Data.DomainComputersUnknownCount = Get-DataInformation -Text "Getting domain information - $Domain DomainComputersUnknownCount" { Get-WinADDomainComputersUnknownCount -DomainComputersUnknown $Data.DomainComputersUnknown } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown)
    $Data.DomainRIDs = Get-DataInformation -Text "Getting domain information - $Domain DomainRIDs" { Get-WinADDomainRIDs -DomainInformation $Data.DomainInformation -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainRIDs)
    $Data.DomainGUIDS = Get-DataInformation -Text "Getting domain information - $Domain DomainGUIDS" { Get-WinADDomainGUIDs -RootDSE $Data.DomainRootDSE -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGUIDS
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtendedACL)
    $Data.DomainAuthenticationPolicies = Get-DataInformation -Text "Getting domain information - $Domain DomainAuthenticationPolicies" { Get-ADAuthenticationPolicy -Server $Domain -LDAPFilter '(name=AuthenticationPolicy*)' } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainAuthenticationPolicies)
    $Data.DomainAuthenticationPolicySilos = Get-DataInformation -Text "Getting domain information - $Domain DomainAuthenticationPolicySilos" { Get-ADAuthenticationPolicySilo -Server $Domain -Filter 'Name -like "*AuthenticationPolicySilo*"' } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainAuthenticationPolicySilos)
    $Data.DomainCentralAccessPolicies = Get-DataInformation -Text "Getting domain information - $Domain DomainCentralAccessPolicies" { Get-ADCentralAccessPolicy -Server $Domain -Filter * } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainCentralAccessPolicies)
    $Data.DomainCentralAccessRules = Get-DataInformation -Text "Getting domain information - $Domain DomainCentralAccessRules" { Get-ADCentralAccessRule -Server $Domain -Filter * } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainCentralAccessRules)
    $Data.DomainClaimTransformPolicies = Get-DataInformation -Text "Getting domain information - $Domain DomainClaimTransformPolicies" { Get-ADClaimTransformPolicy -Server $Domain -Filter * } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainClaimTransformPolicies)
    $Data.DomainClaimTypes = Get-DataInformation -Text "Getting domain information - $Domain DomainClaimTypes" { Get-ADClaimType -Server $Domain -Filter * } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainClaimTypes)
    $DomainDNSData = Get-DataInformation -Text "Getting domain information - $Domain DomainDNSData" { Get-WinADDomainDNSData -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainDNSSRV
        [PSWinDocumentation.ActiveDirectory]::DomainDNSA)
    $Data.DomainDNSSrv = Get-DataInformation -Text "Getting domain information - $Domain DomainDNSSrv" { $DomainDNSData.SRV } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainDNSSrv)
    $Data.DomainDNSA = Get-DataInformation -Text "Getting domain information - $Domain DomainDNSA" { $DomainDNSData.A } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainDNSA)
    $Data.DomainFSMO = Get-DataInformation -Text "Getting domain information - $Domain DomainFSMO" { Get-WinADDomainFSMO -Domain $Domain -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainFSMO
        [PSWinDocumentation.ActiveDirectory]::DomainTrusts)
    $Data.DomainTrustsClean = Get-DataInformation -Text "Getting domain information - $Domain DomainTrustsClean" { Get-WinADDomainTrustsClean -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainTrustsClean
        [PSWinDocumentation.ActiveDirectory]::DomainTrusts)
    $Data.DomainTrusts = Get-DataInformation -Text "Getting domain information - $Domain DomainTrusts" { Get-WinADDomainTrusts -DomainPDC $Data.DomainFSMO.'PDC Emulator' -Trusts $Data.DomainTrustsClean -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainTrusts)
    $Data.DomainGroupPoliciesClean = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupPoliciesClean" { Get-GPO -Domain $Domain -All } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesClean
        [PSWinDocumentation.ActiveDirectory]::DomainGroupPolicies
        [PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesDetails
        [PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesACL)
    $Data.DomainGroupPolicies = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupPolicies" { Get-WinADDomainGroupPolicies -GroupPolicies $Data.DomainGroupPoliciesClean -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupPolicies)
    $Data.DomainGroupPoliciesDetails = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupPoliciesDetails" { Get-WinADDomainGroupPoliciesDetails -GroupPolicies $Data.DomainGroupPoliciesClean -Domain $Domain -Splitter $Splitter } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesDetails)
    $Data.DomainGroupPoliciesACL = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupPoliciesACL" { Get-WinADDomainGroupPoliciesACL -GroupPolicies $Data.DomainGroupPoliciesClean -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupPoliciesACL)
    $Data.DomainBitlocker = Get-DataInformation -Text "Getting domain information - $Domain DomainBitlocker" { Get-WinADDomainBitlocker -Domain $Domain -Computers $Data.DomainComputersFullList } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainBitlocker)
    $Data.DomainLAPS = Get-DataInformation -Text "Getting domain information - $Domain DomainLAPS" { Get-WinADDomainLAPS -Domain $Domain -Computers $Data.DomainComputersFullList -Splitter $Splitter } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainLAPS)
    $Data.DomainDefaultPasswordPolicy = Get-DataInformation -Text "Getting domain information - $Domain DomainDefaultPasswordPolicy" { Get-WinADDomainDefaultPasswordPolicy -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainDefaultPasswordPolicy)
    $Data.DomainOrganizationalUnitsClean = Get-DataInformation -Text "Getting domain information - $Domain DomainOrganizationalUnitsClean" { Get-ADOrganizationalUnit -Server $Domain -Properties * -Filter * } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsClean
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnits
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsDN
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsBasicACL
        [PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtendedACL)
    $Data.DomainOrganizationalUnits = Get-DataInformation -Text "Getting domain information - $Domain DomainOrganizationalUnits" { Get-WinADDomainOrganizationalUnits -Domain $Domain -OrgnaizationalUnits $Data.DomainOrganizationalUnitsClean -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnits)
    $Data.DomainOrganizationalUnitsDN = Get-DataInformation -Text "Getting domain information - $Domain DomainOrganizationalUnitsDN" { @($Data.DomainInformation.DistinguishedName
            $Data.DomainOrganizationalUnitsClean.DistinguishedName
            $Data.DomainContainers.DistinguishedName) } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsDN)
    $Data.DomainOrganizationalUnitsBasicACL = Get-DataInformation -Text "Getting domain information - $Domain DomainOrganizationalUnitsBasicACL" { Get-WinADDomainOrganizationalUnitsACL -DomainOrganizationalUnitsClean $Data.DomainOrganizationalUnitsClean -Domain $Domain -NetBiosName $Data.DomainInformation.NetBIOSName -RootDomainNamingContext $Data.DomainRootDSE.rootDomainNamingContext } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsBasicACL)
    $Data.DomainOrganizationalUnitsExtendedACL = Get-DataInformation -Text "Getting domain information - $Domain DomainOrganizationalUnitsExtendedACL" { Get-WinADDomainOrganizationalUnitsACLExtended -DomainOrganizationalUnitsClean $Data.DomainOrganizationalUnitsClean -Domain $Domain -NetBiosName $Data.DomainInformation.NetBIOSName -RootDomainNamingContext $Data.DomainRootDSE.rootDomainNamingContext -GUID $Data.DomainGUIDS } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainOrganizationalUnitsExtendedACL)
    $Data.DomainUsers = Get-DataInformation -Text "Getting domain information - $Domain DomainUsers" { Get-WinADDomainUsersAll -Users $Data.DomainUsersFullList -Domain $Domain -DomainObjects $Data.DomainObjects -Splitter $Splitter } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsers
        [PSWinDocumentation.ActiveDirectory]::DomainUsersAll
        [PSWinDocumentation.ActiveDirectory]::DomainUsersSystemAccounts
        [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiring
        [PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiringInclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredInclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredExclDisabled
        [PSWinDocumentation.ActiveDirectory]::DomainUsersCount
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDataPasswords)
    $Data.DomainUsersAll = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersAll" { Get-WinADDomainUsersAllFiltered -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersAll)
    $Data.DomainUsersSystemAccounts = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersSystemAccounts" { Get-WinADDomainUsersSystemAccounts -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersSystemAccounts)
    $Data.DomainUsersNeverExpiring = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersNeverExpiring" { Get-WinADDomainUsersNeverExpiring -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiring)
    $Data.DomainUsersNeverExpiringInclDisabled = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersNeverExpiringInclDisabled" { Get-WinADDomainUsersNeverExpiringInclDisabled -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersNeverExpiringInclDisabled)
    $Data.DomainUsersExpiredInclDisabled = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersExpiredInclDisabled" { Get-WinADDomainUsersExpiredInclDisabled -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredInclDisabled)
    $Data.DomainUsersExpiredExclDisabled = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersExpiredExclDisabled" { Get-WinADDomainUsersExpiredExclDisabled -DomainUsers $Data.DomainUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersExpiredExclDisabled)
    $Data.DomainUsersCount = Get-DataInformation -Text "Getting domain information - $Domain DomainUsersCount" { Get-WinADDomainAllUsersCount -DomainUsers $Data.DomainUsers -DomainUsersAll $Data.DomainUsersAll -DomainUsersExpiredExclDisabled $Data.DomainUsersExpiredExclDisabled -DomainUsersExpiredInclDisabled $Data.DomainUsersExpiredInclDisabled -DomainUsersNeverExpiring $Data.DomainUsersNeverExpiring -DomainUsersNeverExpiringInclDisabled $Data.DomainUsersNeverExpiringInclDisabled -DomainUsersSystemAccounts $Data.DomainUsersSystemAccounts } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainUsersCount)
    $Data.DomainControllers = Get-DataInformation -Text "Getting domain information - $Domain DomainControllers" { Get-WinADDomainControllersInternal -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainControllers)
    $Data.DomainFineGrainedPolicies = Get-DataInformation -Text "Getting domain information - $Domain DomainFineGrainedPolicies" { Get-WinADDomainFineGrainedPolicies -Domain $Domain } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPolicies
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsers
        [PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsersExtended)
    $Data.DomainFineGrainedPoliciesUsers = Get-DataInformation -Text "Getting domain information - $Domain DomainFineGrainedPoliciesUsers" { Get-WinADDomainFineGrainedPoliciesUsers -DomainFineGrainedPolicies $Data.DomainFineGrainedPolicies -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsers)
    $Data.DomainFineGrainedPoliciesUsersExtended = Get-DataInformation -Text "Getting domain information - $Domain DomainFineGrainedPoliciesUsersExtended" { Get-WinADDomainFineGrainedPoliciesUsersExtended -DomainFineGrainedPolicies $Data.DomainFineGrainedPolicies -Domain $Domain -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainFineGrainedPoliciesUsersExtended)
    $Data.DomainGroups = Get-DataInformation -Text "Getting domain information - $Domain DomainGroups" { Get-WinGroups -Groups $Data.DomainGroupsFullList -Domain $Domain -Splitter $Splitter -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroups
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecial)
    $Data.DomainGroupsMembers = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsMembers" { Get-WinGroupMembers -Groups $Data.DomainGroups -Domain $Domain -Option Standard -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembers
        [PSWinDocumentation.ActiveDirectory]::DomainAdministrators
        [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministrators)
    $Data.DomainGroupsMembersRecursive = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsMembersRecursive" { Get-WinGroupMembers -Groups $Data.DomainGroups -Domain $Domain -Option Recursive -DomainObjects $Data.DomainObjects } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsMembersRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembersRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembersRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainAdministratorsRecursive
        [PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministratorsRecursive)
    $Data.DomainGroupsPriviliged = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsPriviliged" { Get-DomainGroupsPriviliged -DomainGroups $Data.DomainGroups -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviliged
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembers
        [PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembersRecursive)
    $Data.DomainGroupsSpecial = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsSpecial" { Get-WinADDomainGroupsSpecial -DomainGroups $Data.DomainGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecial
        [PSWinDocumentation.ActiveDirectory]::DomainGroupMembersRecursiveSpecial)
    $Data.DomainGroupsSpecialMembers = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsSpecialMembers" { Get-WinADDomainGroupsSpecialMembers -DomainGroupsMembers $Data.DomainGroupsMembers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembers)
    $Data.DomainGroupsSpecialMembersRecursive = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsSpecialMembersRecursive" { Get-WinADDomainGroupsSpecialMembersRecursive -DomainGroupsMembersRecursive $Data.DomainGroupsMembersRecursive } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsSpecialMembersRecursive)
    $Data.DomainGroupsPriviligedMembers = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsPriviligedMembers" { Get-WinADDomainGroupsPriviligedMembers -DomainGroupsMembers $Data.DomainGroupsMembers -DomainGroupsPriviliged $Data.DomainGroupsPriviliged } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembers)
    $Data.DomainGroupsPriviligedMembersRecursive = Get-DataInformation -Text "Getting domain information - $Domain DomainGroupsPriviligedMembersRecursive" { Get-WinADDomainGroupsPriviligedMembersRecursive -DomainGroupsMembersRecursive $Data.DomainGroupsMembersRecursive -DomainGroupsPriviliged $Data.DomainGroupsPriviliged } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainGroupsPriviligedMembersRecursive)
    $Data.DomainAdministrators = Get-DataInformation -Text "Getting domain information - $Domain DomainAdministrators" { Get-WinADDomainAdministrators -DomainGroupsMembers $Data.DomainGroupsMembers -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainAdministrators)
    $Data.DomainAdministratorsRecursive = Get-DataInformation -Text "Getting domain information - $Domain DomainAdministratorsRecursive" { Get-WinADDomainAdministratorsRecursive -DomainGroupsMembersRecursive $Data.DomainGroupsMembersRecursive -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainAdministratorsRecursive)
    $Data.DomainEnterpriseAdministrators = Get-DataInformation -Text "Getting domain information - $Domain DomainEnterpriseAdministrators" { Get-WinADDomainEnterpriseAdministrators -DomainGroupsMembers $Data.DomainGroupsMembers -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministrators)
    $Data.DomainEnterpriseAdministratorsRecursive = Get-DataInformation -Text "Getting domain information - $Domain DomainEnterpriseAdministratorsRecursive" { Get-WinADDomainEnterpriseAdministratorsRecursive -DomainGroupsMembersRecursive $Data.DomainGroupsMembersRecursive -DomainInformation $Data.DomainInformation } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainEnterpriseAdministratorsRecursive)
    $Data.DomainPasswordDataUsers = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDataUsers" { Get-WinADDomainPassword -DnsRoot $Data.DomainInformation.DNSRoot -DistinguishedName $Data.DomainInformation.DistinguishedName } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDataUsers,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDataPasswords,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordClearTextPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordLMHash,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordEmptyPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordEnabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordDisabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordList,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDefaultComputerPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNotRequired,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNeverExpires,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordAESKeysMissing,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPreAuthNotRequired,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDESEncryptionOnly,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDelegatableAdmins,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDuplicatePasswordGroups,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordStats,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled)
    $Data.DomainPasswordDataPasswords = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDataPasswords" { Get-WinADDomainPasswordQuality -FilePath $PathToPasswords -DomainComputersAll $Data.DomainComputersAll -DomainUsersAll $Data.DomainUsersAll -DomainDistinguishedName $Data.DomainInformation.DistinguishedName -DnsRoot $Data.DomainInformation.DnsRoot -Verbose:$false -PasswordQualityUsers $Data.DomainPasswordDataUsers -PasswordQuality:$PasswordQuality } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDataPasswords,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordClearTextPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordLMHash,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordEmptyPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordEnabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordDisabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordList,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDefaultComputerPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNotRequired,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNeverExpires,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordAESKeysMissing,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordPreAuthNotRequired,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDESEncryptionOnly,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDelegatableAdmins,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordDuplicatePasswordGroups,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordStats,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled)
    $Data.DomainPasswordDataPasswordsHashes = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDataPasswordsHashes" { Get-WinADDomainPasswordQuality -FilePath $PathToPasswordsHashes -DomainComputersAll $Data.DomainComputersAll -DomainUsersAll $Data.DomainUsersAll -DomainDistinguishedName $Data.DomainInformation.DistinguishedName -DnsRoot $DomainInformation.DnsRoot -UseHashes -Verbose:$false -PasswordQualityUsers $Data.DomainPasswordDataUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled,
        [PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled)
    if ($Data.DomainPasswordDataPasswords) { $PasswordsQuality = $Data.DomainPasswordDataPasswords } elseif ($Data.DomainPasswordDataPasswordsHashes) { $PasswordsQuality = $Data.DomainPasswordDataPasswordsHashes } else { $PasswordsQuality = $null }
    $Data.DomainPasswordClearTextPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordClearTextPassword" { $PasswordsQuality.DomainPasswordClearTextPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordClearTextPassword)
    $Data.DomainPasswordLMHash = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordLMHash" { $PasswordsQuality.DomainPasswordLMHash } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordLMHash)
    $Data.DomainPasswordEmptyPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordEmptyPassword" { $PasswordsQuality.DomainPasswordEmptyPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordEmptyPassword)
    $Data.DomainPasswordEmptyPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordEmptyPassword" { $PasswordsQuality.DomainPasswordEmptyPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordEmptyPassword)
    $Data.DomainPasswordWeakPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordWeakPassword" { $PasswordsQuality.DomainPasswordWeakPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPassword)
    $Data.DomainPasswordWeakPasswordEnabled = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordWeakPasswordEnabled" { $PasswordsQuality.DomainPasswordWeakPasswordEnabled } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordEnabled)
    $Data.DomainPasswordWeakPasswordDisabled = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordWeakPasswordDisabled" { $PasswordsQuality.DomainPasswordWeakPasswordDisabled } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordDisabled)
    $Data.DomainPasswordWeakPasswordList = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordWeakPasswordList" { $PasswordsQuality.DomainPasswordWeakPasswordList } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordWeakPasswordList)
    $Data.DomainPasswordDefaultComputerPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDefaultComputerPassword" { $PasswordsQuality.DomainPasswordDefaultComputerPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDefaultComputerPassword)
    $Data.DomainPasswordPasswordNotRequired = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordPasswordNotRequired" { $PasswordsQuality.DomainPasswordPasswordNotRequired } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNotRequired)
    $Data.DomainPasswordPasswordNeverExpires = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordPasswordNeverExpires" { $PasswordsQuality.DomainPasswordPasswordNeverExpires } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordPasswordNeverExpires)
    $Data.DomainPasswordAESKeysMissing = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordAESKeysMissing" { $PasswordsQuality.DomainPasswordAESKeysMissing } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordAESKeysMissing)
    $Data.DomainPasswordPreAuthNotRequired = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordPreAuthNotRequired" { $PasswordsQuality.DomainPasswordPreAuthNotRequired } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordPreAuthNotRequired)
    $Data.DomainPasswordDESEncryptionOnly = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDESEncryptionOnly" { $PasswordsQuality.DomainPasswordDESEncryptionOnly } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDESEncryptionOnly)
    $Data.DomainPasswordDelegatableAdmins = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDelegatableAdmins" { $PasswordsQuality.DomainPasswordDelegatableAdmins } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDelegatableAdmins)
    $Data.DomainPasswordDuplicatePasswordGroups = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordDuplicatePasswordGroups" { $PasswordsQuality.DomainPasswordDuplicatePasswordGroups } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordDuplicatePasswordGroups)
    $Data.DomainPasswordHashesWeakPassword = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordHashesWeakPassword" { $PasswordsQuality.DomainPasswordHashesWeakPassword } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPassword)
    $Data.DomainPasswordHashesWeakPasswordEnabled = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordHashesWeakPasswordEnabled" { $PasswordsQuality.DomainPasswordHashesWeakPasswordEnabled } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordEnabled)
    $Data.DomainPasswordHashesWeakPasswordDisabled = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordHashesWeakPasswordDisabled" { $Data.DomainPasswordDataPasswordsHashes.DomainPasswordWeakPasswordDisabled } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordHashesWeakPasswordDisabled)
    $Data.DomainPasswordStats = Get-DataInformation -Text "Getting domain information - $Domain DomainPasswordStats" { Get-WinADDomainPasswordStats -PasswordsQuality $PasswordsQuality -TypesRequired $TypesRequired -DomainPasswordHashesWeakPassword $Data.DomainPasswordHashesWeakPassword -DomainPasswordHashesWeakPasswordEnabled $Data.DomainPasswordHashesWeakPasswordEnabled -DomainPasswordHashesWeakPasswordDisabled $Data.DomainPasswordHashesWeakPasswordDisabled } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::DomainPasswordStats)
    $EndTime = Stop-TimeLog -Time $TimeToGenerate
    Write-Verbose "Getting domain information - $Domain - Time to generate: $EndTime"
    return $Data
}
function Get-WinADForestInformation {
    [CmdletBinding()]
    param ([PSWinDocumentation.ActiveDirectory[]] $TypesRequired,
        [switch] $RequireTypes,
        [string] $PathToPasswords,
        [string] $PathToPasswordsHashes,
        [switch] $PasswordQuality,
        [switch] $DontRemoveSupportData,
        [switch] $DontRemoveEmpty,
        [switch] $Formatted,
        [string] $Splitter,
        [switch] $Parallel,
        [switch] $Extended,
        [int] $ResultPageSize = 500000)
    $PSDefaultParameterValues["Get-DataInformation:Verbose"] = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
    Write-Verbose -Message "Getting all information - Start"
    Write-Verbose -Message "Getting forest information - Start"
    $TimeToGenerateForest = Start-TimeLog
    if ($null -eq $TypesRequired) {
        Write-Verbose 'Getting forest information - TypesRequired is null. Getting all.'
        $TypesRequired = Get-Types -Types ([PSWinDocumentation.ActiveDirectory])
    }
    $Forest = Get-WinADForest
    if ($null -eq $Forest) {
        Write-Warning "Getting forest information - Failed to get information. This may mean that RSAT is not available or you can't connect to Active Directory."
        return
    }
    $Data = [ordered] @{ }
    $Data.ForestRootDSE = Get-DataInformation -Text 'Getting forest information - ForestRootDSE' { Get-WinADRootDSE } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestRootDSE
        [PSWinDocumentation.ActiveDirectory]::ForestInformation)
    $Data.ForestInformation = Get-DataInformation -Text 'Getting forest information - Forest' { Get-WinADForestInfo -Forest $Forest -RootDSE $Data.ForestRootDSE } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestInformation)
    $Data.ForestSchemaPropertiesComputers = Get-DataInformation -Text "Getting forest information - ForestSchemaPropertiesComputers" { Get-WinADForestSchemaPropertiesComputers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSchemaPropertiesComputers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersFullList
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAll
        [PSWinDocumentation.ActiveDirectory]::DomainComputersAllCount
        [PSWinDocumentation.ActiveDirectory]::DomainServers
        [PSWinDocumentation.ActiveDirectory]::DomainServersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputers
        [PSWinDocumentation.ActiveDirectory]::DomainComputersCount
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknown
        [PSWinDocumentation.ActiveDirectory]::DomainComputersUnknownCount
        [PSWinDocumentation.ActiveDirectory]::DomainBitlocker
        [PSWinDocumentation.ActiveDirectory]::DomainLAPS
        [PSWinDocumentation.ActiveDirectory]::ForestOptionalFeatures)
    $Data.ForestSchemaPropertiesUsers = Get-DataInformation -Text "Getting forest information - ForestSchemaPropertiesUsers" { Get-WinADForestSchemaPropertiesUsers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSchemaPropertiesUsers
        [PSWinDocumentation.ActiveDirectory]::DomainUsersFullList)
    $Data.ForestUPNSuffixes = Get-DataInformation -Text 'Getting forest information - ForestUPNSuffixes' { Get-WinADForestUPNSuffixes -Forest $Forest } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestUPNSuffixes)
    $Data.ForestSPNSuffixes = Get-DataInformation -Text 'Getting forest information - ForestSPNSuffixes' { Get-WinADForestSPNSuffixes -Forest $Forest } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSPNSuffixes)
    $Data.ForestGlobalCatalogs = Get-DataInformation -Text 'Getting forest information - ForestGlobalCatalogs' { $Forest.GlobalCatalogs } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestGlobalCatalogs)
    $Data.ForestFSMO = Get-DataInformation -Text 'Getting forest information - ForestFSMO' { Get-WinADForestFSMO -Forest $Forest } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestFSMO)
    $Data.ForestDomainControllers = Get-DataInformation -Text 'Getting forest information - ForestDomainControllers' { Get-WinADForestControllers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestDomainControllers)
    $Data.ForestSites = Get-DataInformation -Text 'Getting forest information - ForestSites' { Get-WinADForestSites -Formatted:$Formatted -Splitter $Splitter } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSites
        [PSWinDocumentation.ActiveDirectory]::ForestSites1
        [PSWinDocumentation.ActiveDirectory]::ForestSites2)
    $Data.ForestSites1 = Get-DataInformation -Text 'Getting forest information - ForestSites1' { if ($Formatted) { $Data.ForestSites | Select-Object -Property Name, Description, Protected, 'Subnets Count', 'Domain Controllers Count', Modified } else { $Data.ForestSites | Select-Object -Property Name, Description, Protected, 'SubnetsCount', 'DomainControllersCount', Modified } } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSites1)
    $Data.ForestSites2 = Get-DataInformation -Text 'Getting forest information - ForestSites2' { if ($Formatted) { $Data.ForestSites | Select-Object -Property 'Topology Cleanup Enabled', 'Topology DetectStale Enabled', 'Topology MinimumHops Enabled', 'Universal Group Caching Enabled', 'Universal Group Caching Refresh Site' } else { $Data.ForestSites | Select-Object -Property TopologyCleanupEnabled, TopologyDetectStaleEnabled, TopologyMinimumHopsEnabled, UniversalGroupCachingEnabled, UniversalGroupCachingRefreshSite } } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSites2)
    $Data.ForestSubnets = Get-DataInformation -Text 'Getting forest information - ForestSubnets' { Get-WinADForestSubnets } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSubnets
        [PSWinDocumentation.ActiveDirectory]::ForestSubnets1
        [PSWinDocumentation.ActiveDirectory]::ForestSubnets2)
    $Data.ForestSubnets1 = Get-DataInformation -Text 'Getting forest information - ForestSubnets1' { Get-WinADForestSubnets1 -ForestSubnets $Data.ForestSubnets } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSubnets1)
    $Data.ForestSubnets2 = Get-DataInformation -Text 'Getting forest information - ForestSubnets2' { Get-WinADForestSubnets2 -ForestSubnets $Data.ForestSubnets } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSubnets2)
    $Data.ForestSiteLinks = Get-DataInformation -Text 'Getting forest information - ForestSiteLinks' { Get-WinADForestSiteLinks } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestSiteLinks)
    $Data.ForestOptionalFeatures = Get-DataInformation -Text 'Getting forest information - ForestOptionalFeatures' { Get-WinADForestOptionalFeatures -ComputerProperties $ForestSchemaPropertiesComputers } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestOptionalFeatures)
    $Data.ForestReplication = Get-DataInformation -Text 'Getting forest information - ForestReplication' { Get-WinADForestReplication -Extended:$Extended } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory]::ForestReplication)
    $EndTimeForest = Stop-TimeLog -Time $TimeToGenerateForest -Continue
    $Data.FoundDomains = Get-DataInformation -Text 'Getting forest information - Domains' { $FoundDomains = @{ }
        foreach ($Domain in $Forest.Domains) { $FoundDomains.$Domain = Get-WinADDomainInformation -Domain $Domain -TypesRequired $TypesRequired -PathToPasswords $PathToPasswords -PathToPasswordsHashes $PathToPasswordsHashes -ForestSchemaComputers $Data.ForestSchemaPropertiesComputers -ForestSchemaUsers $Data.ForestSchemaPropertiesUsers -PasswordQuality:$PasswordQuality -Splitter $Splitter -Parallel:$Parallel -ResultPageSize $ResultPageSize -Formatted:$formatted }
        $FoundDomains } -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.ActiveDirectory].GetEnumValues() | Where-Object { $_ -like 'Domain*' })
    $EndTimeAll = Stop-TimeLog -Time $TimeToGenerateForest
    Clear-DataInformation -Data $Data -TypesRequired $TypesRequired -DontRemoveSupportData:$DontRemoveSupportData -DontRemoveEmpty:$DontRemoveEmpty
    Write-Verbose "Getting forest information - Stop - Time to generate: $EndTimeForest"
    Write-Verbose "Getting all information - Stop - Time to generate: $EndTimeAll"
    return $Data
}
Export-ModuleMember -Function @('Get-WinADDomainInformation', 'Get-WinADForestInformation') -Alias @()
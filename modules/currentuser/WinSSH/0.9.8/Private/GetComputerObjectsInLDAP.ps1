function GetComputerObjectsInLDAP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [int]$ObjectCount = 0,

        [Parameter(Mandatory=$False)]
        [string]$Domain,

        [Parameter(Mandatory=$False)]
        [pscredential]$LDAPCreds
    )

    #region >> Prep
    
    if ($PSVersionTable.Platform -eq "Unix" -and !$LDAPCreds) {
        Write-Error "On this Platform (i.e. $($PSVersionTable.Platform)), you must provide credentials with access to LDAP/Active Directory using the -LDAPCreds parameter! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if ($LDAPCreds) {
        # Make sure the $LDAPCreds.UserName is in the correct format
        if ($LDAPCreds.UserName -notmatch "\\") {
            Write-Error "The -LDAPCreds UserName is NOT in the correct format! The format must be: <Domain>\<User>"
            $global:FunctionResult = "1"
            return
        }
    }

    if ($PSVersionTable.Platform -eq "Unix") {
        # Determine if we have the required Linux commands
        [System.Collections.ArrayList]$LinuxCommands = @(
            "echo"
            "host"
            "hostname"
            "ldapsearch"
            #"expect"
        )
        if (!$Domain) {
            $null = $LinuxCommands.Add("domainname")
        }
        [System.Collections.ArrayList]$CommandsNotPresent = @()
        foreach ($CommandName in $LinuxCommands) {
            $CommandCheckResult = command -v $CommandName
            if (!$CommandCheckResult) {
                $null = $CommandsNotPresent.Add($CommandName)
            }
        }

        if ($CommandsNotPresent.Count -gt 0) {
            [System.Collections.ArrayList]$FailedInstalls = @()
            if ($CommandsNotPresent -contains "echo" -or $CommandsNotPresent -contains "whoami") {
                try {
                    $null = InstallLinuxPackage -PossiblePackageNames "coreutils" -CommandName "echo"
                }
                catch {
                    $null = $FailedInstalls.Add("coreutils")
                }
            }
            if ($CommandsNotPresent -contains "host" -or $CommandsNotPresent -contains "hostname" -or $CommandsNotPresent -contains "domainname") {
                try {
                    $null = InstallLinuxPackage -PossiblePackageNames @("dnsutils","bindutils","bind-utils","bind-tools") -CommandName "nslookup"
                }
                catch {
                    $null = $FailedInstalls.Add("dnsutils_bindutils_bind-utils_bind-tools")
                }
            }
            if ($CommandsNotPresent -contains "ldapsearch") {
                try {
                    $null = InstallLinuxPackage -PossiblePackageNames "openldap-clients" -CommandName "ldapsearch"
                }
                catch {
                    $null = $FailedInstalls.Add("openldap-clients")
                }
            }
            <#
            if ($CommandsNotPresent -contains "expect") {
                try {
                    $null = InstallLinuxPackage -PossiblePackageNames "expect" -CommandName "expect"
                }
                catch {
                    $null = $FailedInstalls.Add("expect")
                }
            }
            #>
    
            if ($FailedInstalls.Count -gt 0) {
                Write-Error "The following Linux packages are required, but were not able to be installed:`n$($FailedInstalls -join "`n")`nHalting!"
                $global:FunctionResult = "1"
                return
            }
        }

        [System.Collections.ArrayList]$CommandsNotPresent = @()
        foreach ($CommandName in $LinuxCommands) {
            $CommandCheckResult = command -v $CommandName
            if (!$CommandCheckResult) {
                $null = $CommandsNotPresent.Add($CommandName)
            }
        }
    
        if ($CommandsNotPresent.Count -gt 0) {
            Write-Error "The following Linux commands are required, but not present on $env:ComputerName:`n$($CommandsNotPresent -join "`n")`nHalting!"
            $global:FunctionResult = "1"
            return
        }
    }

    # Below $LDAPInfo Output is PSCustomObject with properties: DirectoryEntryInfo, LDAPBaseUri,
    # GlobalCatalogConfigured3268, GlobalCatalogConfiguredForSSL3269, Configured389, ConfiguredForSSL636,
    # PortsThatWork
    try {
        if ($Domain) {
            $DomainControllerInfo = GetDomainController -Domain $Domain -ErrorAction Stop
        }
        else {
            $DomainControllerInfo = GetDomainController -ErrorAction Stop
        }

        if ($DomainControllerInfo.PrimaryDomainController -eq "unknown") {
            $PDC = $DomainControllerInfo.FoundDomainControllers[0]
        }
        else {
            $PDC = $DomainControllerInfo.PrimaryDomainController
        }

        $LDAPInfo = TestLDAP -ADServerHostNameOrIP $PDC -ErrorAction Stop
        if (!$DomainControllerInfo) {throw "Problem with GetDomainController function! Halting!"}
        if (!$LDAPInfo) {throw "Problem with TestLDAP function! Halting!"}
    }
    catch {
        Write-Error $_
        $global:FunctionResult = "1"
        return
    }

    if (!$LDAPInfo.PortsThatWork) {
        Write-Error "Unable to access LDAP on $PDC! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if ($LDAPInfo.PortsThatWork -contains "389") {
        $Port = "389"
        $LDAPUri = $LDAPInfo.LDAPBaseUri + ":$Port"
    }
    elseif ($LDAPInfo.PortsThatWork -contains "3268") {
        $Port = "3268"
        $LDAPUri = $LDAPInfo.LDAPBaseUri + ":$Port"
    }
    elseif ($LDAPInfo.PortsThatWork -contains "636") {
        $Port = "636"
        $LDAPUri = $LDAPInfo.LDAPBaseUri + ":$Port"
    }
    elseif ($LDAPInfo.PortsThatWork -contains "3269") {
        $Port = "3269"
        $LDAPUri = $LDAPInfo.LDAPBaseUri + ":$Port"
    }

    #endregion >> Prep

    #region >> Main

    if ($PSVersionTable.Platform -eq "Unix") {
        $SimpleDomainPrep = $PDC -split "\."
        $SimpleDomain = $SimpleDomainPrep[1..$($SimpleDomainPrep.Count-1)] -join "."
        [System.Collections.ArrayList]$DomainLDAPContainersPrep = @()
        foreach ($Section in $($SimpleDomain -split "\.")) {
            $null = $DomainLDAPContainersPrep.Add($Section)
        }
        $DomainLDAPContainers = $($DomainLDAPContainersPrep | foreach {"DC=$_"}) -join ","
        $BindUserName = $LDAPCreds.UserName
        $BindUserNameForExpect = $BindUserName -replace [regex]::Escape('\'),'\\\'
        $BindPassword = $LDAPCreds.GetNetworkCredential().Password

        $ldapSearchOutput = ldapsearch -x -h $PDC -D $BindUserName -w $BindPassword -b $DomainLDAPContainers -s sub "(objectClass=computer)" cn
        
        <#
        $ldapSearchCmdForExpect = "ldapsearch -x -h $PDC -D $BindUserNameForExpect -W -b `"$DomainLDAPContainers`" -s sub `"(objectClass=computer)`" cn"

        [System.Collections.ArrayList]$ExpectScriptPrep = @(
            'expect - << EOF'
            'set timeout 120'
            "set password $BindPassword"
            'set prompt \"(>|:|#|\\\\\\$)\\\\s+\\$\"'
            "spawn $ldapSearchCmdForExpect"
            'match_max 100000'
            'expect \"Enter LDAP Password:\"'
            'send -- \"\$password\r\"'
            'expect -re \"\$prompt\"'
            'send -- \"exit\r\"'
            'expect eof'
            'EOF'
        )

        $ExpectScript = $ExpectScriptPrep -join "`n"

        #Write-Host "`$ExpectScript is:`n$ExpectScript"
        #$ExpectScript | Export-CliXml "$HOME/ExpectScript2.xml"
        
        # The below $ExpectOutput is an array of strings
        $ExpectOutput = $ldapSearchOutput = bash -c "$ExpectScript"
        #>

        $Computers = $ldapSearchOutput -match "cn:" | foreach {$_ -replace 'cn:[\s]+'}
        if ($ObjectCount -gt 0) {
            $Computers = $Computers[0..$($ObjectCount-1)]
        }
    }
    else {
        try {
            if ($LDAPCreds) {
                $LDAPUserName = $LDAPCreds.UserName
                $LDAPPassword = $LDAPCreds.GetNetworkCredential().Password
                $LDAPSearchRoot = [System.DirectoryServices.DirectoryEntry]::new($LDAPUri,$LDAPUserName,$LDAPPassword)
            }
            else {
                $LDAPSearchRoot = [System.DirectoryServices.DirectoryEntry]::new($LDAPUri)
            }
            $LDAPSearcher = [System.DirectoryServices.DirectorySearcher]::new($LDAPSearchRoot)
            $LDAPSearcher.Filter = "(objectClass=computer)"
            $LDAPSearcher.SizeLimit = 0
            $LDAPSearcher.PageSize = 250
            $Computers = $LDAPSearcher.FindAll() | foreach {$_.GetDirectoryEntry()}

            if ($ObjectCount -gt 0) {
                $Computers = $Computers[0..$($ObjectCount-1)]
            }
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
    }

    $Computers

    #endregion >> Main
}

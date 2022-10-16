function TestLDAP {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$ADServerHostNameOrIP
    )

    #region >> Prep

    if ($PSVersionTable.Platform -eq "Unix") {
        # If we're on Linux, we need the Novell .Net Core library
        try {
            $CurrentlyLoadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
            if (![bool]$($CurrentlyLoadedAssemblies -match [regex]::Escape("Novell.Directory.Ldap.NETStandard"))) {
                $NovellDownloadDir = "$HOME/Novell.Directory.Ldap.NETStandard"
                if (Test-Path $NovellDownloadDir) {
                    $AssemblyToLoadPath = Get-NativePath @(
                        $HOME
                        "Novell.Directory.Ldap.NETStandard"
                        "Novell.Directory.Ldap.NETStandard"
                        "lib"
                        "netstandard1.3"
                        "Novell.Directory.Ldap.NETStandard.dll"
                    )

                    if (!$(Test-Path $AssemblyToLoadPath)) {
                        $null = Remove-Item -Path $NovellDownloadDir -Recurse -Force
                        $NovellPackageInfo = DownloadNuGetPackage -AssemblyName "Novell.Directory.Ldap.NETStandard" -NuGetPkgDownloadDirectory $NovellDownloadDir -Silent
                        $AssemblyToLoadPath = $NovellPackageInfo.AssemblyToLoad
                    }
                }
                else {
                    $NovellPackageInfo = DownloadNuGetPackage -AssemblyName "Novell.Directory.Ldap.NETStandard" -NuGetPkgDownloadDirectory $NovellDownloadDir -Silent
                    $AssemblyToLoadPath = $NovellPackageInfo.AssemblyToLoad
                }

                if (![bool]$($CurrentlyLoadedAssemblies -match [regex]::Escape("Novell.Directory.Ldap.NETStandard"))) {
                    $null = Add-Type -Path $AssemblyToLoadPath
                }
            }
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }
    }

    try {
        $ADServerNetworkInfo = ResolveHost -HostNameOrIP $ADServerHostNameOrIP -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to resolve $ADServerHostNameOrIP! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if (!$ADServerNetworkInfo.FQDN) {
        Write-Error "Unable to determine FQDN of $ADServerHostNameOrIP! Halting!"
        $global:FunctionResult = "1"
        return
    }

    #endregion >> Prep

    #region >> Main

    $ADServerFQDN = $ADServerNetworkInfo.FQDN

    $LDAPPrep = "LDAP://" + $ADServerFQDN

    # Try Global Catalog First - It's faster and you can execute from a different domain and
    # potentially still get results
    try {
        $Port = "3269"
        $LDAP = $LDAPPrep + ":$Port"
        if ($PSVersionTable.Platform -eq "Unix") {
            $Connection = [Novell.Directory.Ldap.LdapConnection]::new()
            $Connection.Connect($ADServerFQDN,$Port)
            $Connection.Dispose()
        }
        else {
            $Connection = [System.DirectoryServices.DirectoryEntry]($LDAP)
            $Connection.Close()
        }
        $GlobalCatalogConfiguredForSSL = $True
    } 
    catch {
        if ($_.Exception.ToString() -match "The server is not operational") {
            Write-Warning "Either can't find LDAP Server or SSL on Global Catalog (3269) is not operational!"
        }
        elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
            Write-Warning "The current user $(whoami) does not have access!"
        }
        else {
            Write-Error $_
        }
    }

    try {
        $Port = "3268"
        $LDAP = $LDAPPrep + ":$Port"
        if ($PSVersionTable.Platform -eq "Unix") {
            $Connection = [Novell.Directory.Ldap.LdapConnection]::new()
            $Connection.Connect($ADServerFQDN,$Port)
            $Connection.Dispose()
        }
        else {
            $Connection = [System.DirectoryServices.DirectoryEntry]($LDAP)
            $Connection.Close()
        }
        $GlobalCatalogConfigured = $True
    } 
    catch {
        if ($_.Exception.ToString() -match "The server is not operational") {
            Write-Warning "Either can't find LDAP Server or Global Catalog (3268) is not operational!"
        }
        elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
            Write-Warning "The current user $(whoami) does not have access!"
        }
        else {
            Write-Error $_
        }
    }
  
    # Try the normal ports
    try {
        $Port = "636"
        $LDAP = $LDAPPrep + ":$Port"
        if ($PSVersionTable.Platform -eq "Unix") {
            $Connection = [Novell.Directory.Ldap.LdapConnection]::new()
            $Connection.Connect($ADServerFQDN,$Port)
            $Connection.Dispose()
        }
        else {
            $Connection = [System.DirectoryServices.DirectoryEntry]($LDAP)
            $Connection.Close()
        }
        $ConfiguredForSSL = $True
    } 
    catch {
        if ($_.Exception.ToString() -match "The server is not operational") {
            Write-Warning "Can't find LDAP Server or SSL (636) is NOT configured! Check the value provided to the -ADServerHostNameOrIP parameter!"
        }
        elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
            Write-Warning "The current user $(whoami) does not have access! Halting!"
        }
        else {
            Write-Error $_
        }
    }

    try {
        $Port = "389"
        $LDAP = $LDAPPrep + ":$Port"
        if ($PSVersionTable.Platform -eq "Unix") {
            $Connection = [Novell.Directory.Ldap.LdapConnection]::new()
            $Connection.Connect($ADServerFQDN,$Port)
            $Connection.Dispose()
        }
        else {
            $Connection = [System.DirectoryServices.DirectoryEntry]($LDAP)
            $Connection.Close()
        }
        $Configured = $True
    }
    catch {
        if ($_.Exception.ToString() -match "The server is not operational") {
            Write-Warning "Can't find LDAP Server (389)! Check the value provided to the -ADServerHostNameOrIP parameter!"
        }
        elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
            Write-Warning "The current user $(whoami) does not have access!"
        }
        else {
            Write-Error $_
        }
    }

    if (!$GlobalCatalogConfiguredForSSL -and !$GlobalCatalogConfigured -and !$ConfiguredForSSL -and !$Configured) {
        Write-Error "Unable to connect to $LDAPPrep! Halting!"
        $global:FunctionResult = "1"
        return
    }

    [System.Collections.ArrayList]$PortsThatWork = @()
    if ($GlobalCatalogConfigured) {$null = $PortsThatWork.Add("3268")}
    if ($GlobalCatalogConfiguredForSSL) {$null = $PortsThatWork.Add("3269")}
    if ($Configured) {$null = $PortsThatWork.Add("389")}
    if ($ConfiguredForSSL) {$null = $PortsThatWork.Add("636")}

    [pscustomobject]@{
        DirectoryEntryInfo                  = $Connection
        LDAPBaseUri                         = $LDAPPrep
        GlobalCatalogConfigured3268         = if ($GlobalCatalogConfigured) {$True} else {$False}
        GlobalCatalogConfiguredForSSL3269   = if ($GlobalCatalogConfiguredForSSL) {$True} else {$False}
        Configured389                       = if ($Configured) {$True} else {$False}
        ConfiguredForSSL636                 = if ($ConfiguredForSSL) {$True} else {$False}
        PortsThatWork                       = $PortsThatWork
    }

    #endregion >> Main
}

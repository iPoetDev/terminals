function GetDomainName {
    [CmdletBinding()]
    Param()

    if (!$PSVersionTable.Platform -or $PSVersionTable.Platform -eq "Win32NT") {
        $Domain = $(Get-CimInstance Win32_ComputerSystem).Domain
    }
    if ($PSVersionTable.Platform -eq "Unix") {
        $Domain = domainname
        if (!$Domain -or $Domain -eq "(none)") {
            $ThisHostNamePrep = hostname
            if ($ThisHostNamePrep -match "\.") {
                $HostNameArray = $ThisHostNamePrep -split "\."
                $ThisHostName = $HostNameArray[0]
                $Domain = $HostNameArray[1..$HostNameArray.Count] -join '.'
            }
        }
            
        if (!$Domain) {
            $EtcHostsContent = Get-Content "/etc/hosts"
            $EtcHostsContentsArray = $(foreach ($HostLine in $EtcHostsContent) {
                $HostLine -split "[\s]" | foreach {$_.Trim()}
            }) | Where-Object {![System.String]::IsNullOrWhiteSpace($_)}
            $PotentialStringsWithDomainName = $EtcHostsContentsArray | Where-Object {
                $_ -notmatch "localhost" -and
                $_ -notmatch "localdomain" -and
                $_ -match "\." -and
                $_ -match "[a-zA-Z]"
            } | Sort-Object | Get-Unique

            if ($PotentialStringsWithDomainName.Count -eq 0) {
                Write-Error "Unable to determine domain for $(hostname)! Please use the -DomainName parameter and try again. Halting!"
                $global:FunctionResult = "1"
                return
            }
            
            [System.Collections.ArrayList]$PotentialDomainsPrep = @()
            foreach ($Line in $PotentialStringsWithDomainName) {
                if ($Line -match "^\.") {
                    $null = $PotentialDomainsPrep.Add($Line.Substring(1,$($Line.Length-1)))
                }
                else {
                    $null = $PotentialDomainsPrep.Add($Line)
                }
            }
            [System.Collections.ArrayList]$PotentialDomains = @()
            foreach ($PotentialDomain in $PotentialDomainsPrep) {
                $RegexDomainPattern = "^([a-zA-Z0-9][a-zA-Z0-9-_]*\.)*[a-zA-Z0-9]*[a-zA-Z0-9-_]*[[a-zA-Z0-9]+$"
                if ($PotentialDomain -match $RegexDomainPattern) {
                    $FinalPotentialDomain = $PotentialDomain -replace $ThisHostName,""
                    if ($FinalPotentialDomain -match "^\.") {
                        $null = $PotentialDomains.Add($FinalPotentialDomain.Substring(1,$($FinalPotentialDomain.Length-1)))
                    }
                    else {
                        $null = $PotentialDomains.Add($FinalPotentialDomain)
                    }
                }
            }

            if ($PotentialDomains.Count -eq 1) {
                $Domain = $PotentialDomains
            }
            else {
                $Domain = $PotentialDomains[0]
            }
        }
    }

    if ($Domain) {
        $Domain
    }
    else {
        Write-Error "Unable to determine Domain Name! Halting!"
        $global:FunctionResult = "1"
        return
    }
}

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
function Get-Types {
    [CmdletBinding()]
    param ([Object] $Types)
    $TypesRequired = foreach ($Type in $Types) { $Type.GetEnumValues() }
    return $TypesRequired
}
Add-Type -TypeDefinition @"
    using System;

    namespace PSWinDocumentation
    {
        [Flags]
        public enum AWS {
            AWSEC2Details,
            AWSElasticIpDetails,
            AWSIAMDetails,
            AWSLBDetails,
            AWSRDSDetails,
            AWSSubnetDetails
        }
    }
"@
function Get-AWSEC2Details {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try { $EC2Instances = Get-EC2Instance -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSEC2Details - Error: $ErrorMessage"
        return
    }
    $EC2DetailsList = foreach ($instance in $EC2Instances) {
        $ec2 = [pscustomobject] @{'Instance ID' = $instance[0].Instances[0].InstanceId
            "Instance Name"                     = $instance[0].Instances[0].Tags | Where-Object { $_.key -eq "Name" } | Select-Object -Expand Value
            "Environment"                       = $instance[0].Instances[0].Tags | Where-Object { $_.key -eq "Environment" } | Select-Object -Expand Value
            "Instance Type"                     = $instance[0].Instances[0].InstanceType
            "Private IP"                        = $instance[0].Instances[0].PrivateIpAddress
            "Public IP"                         = $instance[0].Instances[0].PublicIpAddress
        }
        $ec2
    }
    return $EC2DetailsList
}
function Get-AWSElasticIpDetails {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try { $EIPs = Get-EC2Address -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSElasticIpDetails - Error: $ErrorMessage"
        return
    }
    $EIPDetailsList = foreach ($eip in $EIPs) {
        $ElasticIP = [pscustomobject] @{"Name" = $eip.Tags | Where-Object { $_.key -eq "Name" } | Select-Object -Expand Value
            "IP"                               = $eip.PublicIp
            "Assigned to"                      = $eip.InstanceId
            "Network Interface"                = $eip.NetworkInterfaceId
        }
        $ElasticIP
    }
    return $EIPDetailsList
}
function Get-AWSIAMDetails {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try { $IAMUsers = Get-IAMUsers -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSIAMDetails - Error: $ErrorMessage"
        return
    }
    $IAMDetailsList = foreach ($user in $IAMUsers) {
        $groupsTemp = (Get-IAMGroupForUser -UserName $user.UserName -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion).GroupName
        $mfaTemp = (Get-IAMMFADevice -UserName $user.UserName -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion).EnableDate
        $accessKeysCreationDateTemp = (Get-IAMAccessKey -UserName $user.UserName -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion).CreateDate
        $IAMUser = [pscustomobject] @{"User Name" = $user.UserName
            "Groups"                              = if ([string]::IsNullOrEmpty($groupsTemp)) { "No groups assigned" } Else { $groupsTemp -join ", " }
            "MFA Since"                           = if ([string]::IsNullOrEmpty($mfaTemp)) { "Missing MFA" } Else { $mfaTemp }
            "Access Keys Count"                   = $accessKeysCreationDateTemp.Count
            "Access Keys Creation Date"           = $accessKeysCreationDateTemp -join ", "
        }
        $IAMUser
    }
    return $IAMDetailsList
}
function Get-AWSLBDetails {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try {
        $ELBs = Get-ELBLoadBalancer -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion
        $ALBs = Get-ELB2LoadBalancer -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSLBDetails - Error: $ErrorMessage"
        return
    }
    $LBDetailsList = @(foreach ($lb in $ELBs) {
            $LB = [pscustomobject] @{"Name" = $lb.LoadBalancerName
                "Type"                      = "ELB"
                "Scheme"                    = $lb.Scheme
                "DNS Name"                  = $lb.DNSName
                "Targets"                   = $lb.Instances.InstanceId -join ", "
            }
            $LB
        }
        foreach ($lb in $ALBs) {
            $LB = [pscustomobject] @{"Name" = $lb.LoadBalancerName
                "Type"                      = "ALB"
                "Scheme"                    = $lb.Scheme
                "DNS Name"                  = $lb.DNSName
                "Targets"                   = "Dynamic Routing"
            }
            $LB
        })
    return $LBDetailsList
}
function Get-AWSRDSDetails {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try { $RDSInstances = Get-RDSDBInstance -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSRDSDetails - Error: $ErrorMessage"
        return
    }
    $RDSDetailsList = foreach ($instance in $RDSInstances) {
        $RDS = [pscustomobject] @{"Name" = $instance.DBInstanceIdentifier
            "Class"                      = $instance.DBInstanceClass
            "MutliAz"                    = if ($instance.Engine.StartsWith("aurora")) { "not applicable" } Else { $instance.MultiAz }
            "Engine"                     = $instance.Engine
            "Engine Version"             = $instance.EngineVersion
            "Storage"                    = if ($instance.Engine.StartsWith("aurora")) { "Dynamic" } Else { [string]::Format("{0} GB", $instance.AllocatedStorage) }
            "Environment"                = Get-RDSTagForResource -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion -ResourceName $instance.DBInstanceArn | Where-Object { $_.key -eq "Environment" } | Select-Object -Expand Value
        }
        $RDS
    }
    return $RDSDetailsList
}
function Get-AWSSubnetDetails {
    [CmdletBinding()]
    param ([string] $AWSAccessKey,
        [string] $AWSSecretKey,
        [string] $AWSRegion)
    try { $Subnets = Get-EC2Subnet -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSSubnetDetails - Error: $ErrorMessage"
        return
    }
    try { $VPCID = (Get-EC2Vpc -AccessKey $AWSAccessKey -SecretKey $AWSSecretKey -Region $AWSRegion) } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "Get-AWSSubnetDetails - Error: $ErrorMessage"
        return
    }
    $NetworkDetailsList = foreach ($subnet in $Subnets) {
        $SN = [pscustomobject] @{"Subnet ID" = $subnet.SubnetId
            "Subnet Name"                    = $subnet.Tags | Where-Object { $_.key -eq "Name" } | Select-Object -Expand Value
            "CIDR"                           = $subnet.CidrBlock
            "Available IP"                   = $subnet.AvailableIpAddressCount
            "VPC"                            = ($VPCID | Where-Object { $_.VpcId -eq $Subnet.VpcId }).Tags | Where-Object { $_.key -eq "Name" } | Select-Object -Expand Value
        }
        $SN
    }
    return $NetworkDetailsList
}
function Get-WinAWSInformation {
    [CmdletBinding()]
    param([alias('AccessKey')][string] $AWSAccessKey,
        [alias('SecretKey')][string] $AWSSecretKey,
        [alias('Region')][string] $AWSRegion,
        [PSWinDocumentation.AWS[]] $TypesRequired)
    $Data = [ordered] @{ }
    if ($null -eq $TypesRequired) {
        Write-Verbose 'Get-AWSInformation - TypesRequired is null. Getting all AWS types.'
        $TypesRequired = Get-Types -Types ([PSWinDocumentation.AWS])
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSEC2Details)) {
        Write-Verbose "Getting AWS information - AWSEC2Details"
        $Data.AWSEC2Details = Get-AWSEC2Details -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSRDSDetails)) {
        Write-Verbose "Getting AWS information - AWSRDSDetails"
        $Data.AWSRDSDetails = Get-AWSRDSDetails -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSLBDetails)) {
        Write-Verbose "Getting AWS information - AWSLBDetails"
        $Data.AWSLBDetails = Get-AWSLBDetails -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSSubnetDetails)) {
        Write-Verbose "Getting AWS information - AWSSubnetDetails"
        $Data.AWSSubnetDetails = Get-AWSSubnetDetails -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSElasticIpDetails)) {
        Write-Verbose "Getting AWS information - AWSElasticIpDetails"
        $Data.AWSElasticIpDetails = Get-AWSElasticIpDetails -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    if (Find-TypesNeeded -TypesRequired $TypesRequired -TypesNeeded @([PSWinDocumentation.AWS]::AWSIAMDetails)) {
        Write-Verbose "Getting AWS information - AWSIAMDetails"
        $Data.AWSIAMDetails = Get-AWSIAMDetails -AWSAccessKey $AWSAccessKey -AWSSecretKey $AWSSecretKey -AWSRegion $AWSRegion -Verbose:$False
    }
    return $Data
}
Export-ModuleMember -Function @('Get-WinAWSInformation') -Alias @()
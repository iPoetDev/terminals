# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Internal Function

# ++++++++++++++++++++++++++++++++
# Get-RegistryConfiguration
function Get-RegistryConfiguration
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [String]$Name
    )

    Try
    {
        $ConfigJson = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Config.json") -Raw
        $ReturnObject = $ConfigJson | ConvertFrom-Json

        If(-not([string]::IsNullOrEmpty($Name)))
        {
            $ReturnObject = $ReturnObject | Where-Object { $_.Name -eq $Name}
        }
        return $ReturnObject
    }
    Catch
    {
        throw "Unable to load configuration : $_"
    }
}

# ++++++++++++++++++++++++++++++++
# Get-RegistryData
Function Get-RegistryData
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [Object]$Item,

        [Parameter(Mandatory = $true)]
        [String]$Data
    )

    If($Item.ValueData.Count -eq 0)
    {
        $ReturnValue = $Data
    }
    Else
    {
         $ReturnValue = ($Item.ValueData | where-object {$_.Name -eq $Data}).Value
         If([string]::IsNullOrEmpty($ReturnValue)) {
            throw "Unable to find Data in '$($Item.Name)' object"
         }
    }
    return $ReturnValue
}


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DSC Function

# ++++++++++++++++++++++++++++++++
# Get-TargetResource
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter(Mandatory = $false)]
        [String]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure='Present'
    )

    $ItemConfiguration = Get-RegistryConfiguration -Name $Name
    $RegistryValue = (Get-ItemProperty "Registry::$($ItemConfiguration.Key)").($ItemConfiguration.ValueName)

    $ReturnValue = @{
        Name = [String]$Name
        Data = [String]$RegistryValue
        Ensure = [String]$Ensure
    }

    $ReturnValue
}

# ++++++++++++++++++++++++++++++++
# Set-TargetResource
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter(Mandatory = $false)]
        [String]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure='Present'
    )

    $ItemConfiguration = Get-RegistryConfiguration -Name $Name
    If($Ensure -eq 'Present')
    {
        $RegistryValue = (Get-ItemProperty "Registry::$($ItemConfiguration.Key)").($ItemConfiguration.ValueName)
        $DataValue = Get-RegistryData -Item $ItemConfiguration -Data $Data
        If([string]::IsNullOrEmpty($RegistryValue))
        {
            New-ItemProperty -Path "Registry::$($ItemConfiguration.Key)" -Name $ItemConfiguration.ValueName -Value $DataValue -PropertyType $ItemConfiguration.ValueType
        }
        else
        {
            Set-ItemProperty -Path "Registry::$($ItemConfiguration.Key)" -Name $ItemConfiguration.ValueName -Value $DataValue
        }
    }
    Else
    {
        Remove-ItemProperty -Path "Registry::$($ItemConfiguration.Key)" -Name $ItemConfiguration.ValueName
    }
}

# ++++++++++++++++++++++++++++++++
# Test-TargetResource
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $True)]
        [String]$Name,

        [Parameter(Mandatory = $False)]
        [String]$Data,

        [Parameter(Mandatory = $False)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure='Present'
    )

    # Get Registry Configuration
    $ItemConfiguration = Get-RegistryConfiguration -Name $Name
    $RegistryValue = (Get-ItemProperty "Registry::$($ItemConfiguration.Key)").($ItemConfiguration.ValueName)

    If($Ensure -eq 'Present')
    {
        If(-not([string]::IsNullOrEmpty($RegistryValue)))
        {
            If(-not([string]::IsNullOrEmpty($Data)))
            {
                $ItemValue = Get-RegistryData -Item $ItemConfiguration -Data $Data
                If($RegistryValue -eq $ItemValue)
                {
                    Write-Verbose "Item Value is well configured"
                    return $True
                }
                Else
                {
                    Write-Verbose "Item Value is not well configured"
                    return $False
                }
            }
            else {
                throw "Data value must not be empty"
            }
        }
        Else {
            Write-Verbose "Item is not present"
            return $False
        }
    }
    Else
    {
        If([string]::IsNullOrEmpty($RegistryValue))
        {
            Write-Verbose "Item is not present"
            return $True
        }
        Else
        {
            Write-Verbose "Item exists"
            return $False
        }
    }
}
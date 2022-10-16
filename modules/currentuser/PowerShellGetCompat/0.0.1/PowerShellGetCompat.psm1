# PROXY HELPER
# used to determine if we have a semantic version
$semVerRegex = '^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

# try to convert the string into a version (semantic or system)
function Get-VersionType
{
    param ( $versionString )

    # if this can be converted into a version, simple return it
    $version = $versionString -as [version]
    if ( $version ) {
        return $version
    }

    # if the string matches a semantic version, return it, but also return a lossy conversion to system.version
    if ( $versionString -match $semVerRegex ) {
        return [pscustomobject]@{
            Major = [int]$Matches['major']
            Minor = [int]$Matches['Minor']
            Patch = [int]$Matches['patch']
            PreReleaseLabel = [string]$matches['prerelease']
            BuildLabel = [string]$matches['buildmetadata']
            originalString = $versionString
            Version = [version]("{0}.{1}.{2}" -f $Matches['major'],$Matches['minor'],$Matches['patch'])
            }
    }
    return $null
}

# this handles comparison of version with semantic versions
# this is all needed as semantic version exists only in core
function Compare-Version
{
    param ([string]$minimum, [string]$maximum)

    # this is done so we can use version to do our comparison
    $reference = Get-VersionType $minimum
    if ( ! $reference ) {
        throw "Cannot convert '$minimum' to version type"
    }
    $difference= Get-VersionType $maximum
    if ( ! $difference ) {
        throw "Cannot convert '$maximum' to version type"
    }

    if ( $reference -is [version] -and $difference -is [version] ) {
        if ( $reference -gt $difference ) {
            return 1
        }
        elseif ( $reference -lt $difference ) {
            return -1
        }
    }
    elseif ( $reference.version -is [version] -and $difference.version -is [version] ) {
        # two semantic versions
        if ( $reference.version -gt $difference.version ) {
            return 1
        }
        elseif ( $reference.version -lt $difference.version ) {
            return -1
        }
    }
    elseif ( $reference -is [version] -and $difference.version -is [version] ) {
        # one semantic version
        if ( $reference -gt $difference.version ) {
            return 1
        }
        elseif ( $reference -lt $difference.version ) {
            return -1
        }
        elseif ( $reference -eq $difference.version ) {
            # 1.0.0 is greater than 1.0.0-preview
            return 1
        }
    }
    elseif ( $reference.version -is [version] -and $difference -is [version] ) {
        # one semantic version
        if ( $reference.version -gt $difference ) {
            return 1
        }
        elseif ( $reference.version -lt $difference ) {
            return -1
        }
        elseif ( $reference.version -eq $difference ) {
            # 1.0.0 is greater than 1.0.0-preview
            return -1
        }
    }
    # Fall through

    if ( $reference.PreReleaseLabel -gt $difference.PreReleaseLabel ) {
        return 1
    }
    if ( $reference.PreReleaseLabel -lt $difference.PreReleaseLabel ) {
        return -1
    }
    # Fall through

    if ( $reference.BuildLabel -gt $difference.BuildLabel ) {
        return 1
    }
    if ( $reference.BuildLabel -lt $difference.BuildLabel ) {
        return -1
    }

    # Fall through, they are equivalent
    return 0
}


# Convert-VersionsToNugetVersion -RequiredVersion $RequiredVersion  -MinimumVersion $MinimumVersion -MaximumVersion $MaximumVersion
# this tries to figure out whether we have an improper use of version parameters
# such as RequiredVersion with MinimumVersion or MaximumVersion
function Convert-VersionsToNugetVersion
{
    param ( $RequiredVersion, $MinimumVersion, $MaximumVersion )
    # validate that required is not used with minimum or maximum version
    if ( $RequiredVersion -and ($MinimumVersion -or $MaximumVersion) ) {
        throw "RequiredVersion may not be used with MinimumVersion or MaximumVersion"
    }
    elseif ( ! $RequiredVersion -and ! $MinimuVersion -and ! $MaximumVersion ) {
        return $null
    }
    if ( $RequiredVersion -eq '*' ) { return $RequiredVersion }

    # validate that we can actually convert the received version to an allowed either a system.version or semanticversion
    foreach ( $version in "RequiredVersion","MinimumVersion", "MaximumVersion" ) {
        if ( $PSBoundParameters[$version] ) {
            $v = $PSBoundParameters[$version] -as [System.Version]
            $sv = $PSBoundParameters[$version] -match $semVerRegex
            if ( ! ($v -or $sv) ) {
                $val = $PSBoundParameters[$version]
                throw "'$version' ($val) cannot be converted to System.Version or System.Management.Automation.SemanticVersion"
            }
        }
    }

    # we've made sure that we've validated the string we got is correct, so just pass it back
    # we've also made sure that we didn't mix min/max with required
    if ( $RequiredVersion ) {
        return "$RequiredVersion"
    }

    # now return the appropriate string
    if ( $MinimumVersion -and ! $MaximumVersion ) {
        if ( Get-VersionType $MinimumVersion ) {
            return "$MinimumVersion"
        }
    }
    elseif ( ! $MinimumVersion -and $MaximumVersion ) {
        # no minimum version
        if ( Get-VersionType $MaximumVersion ) {
            return "(,${MaximumVersion}]"
        }
    }
    else {
        $result = Compare-Version $MinimumVersion $MaximumVersion
        if ( $result -ge 0 ) {
            throw "'$MaximumVersion' must be greater than '$MinimumVersion'"
        }
        return "[${MinimumVersion},${MaximumVersion}]"

    }
}

# we attempt to convert the location to a uri
# that way the user can do Register-PSRepository /tmp
function Convert-ToUri ( [string]$location ) {
    $locationAsUri = $location -as [System.Uri]
    if ( $locationAsUri.Scheme ) {
        return $locationAsUri
    }
    # now determine if the path exists and is a directory
    # if it exists, return it as a file uri
    if ( Test-Path -PathType Container -LiteralPath $location ) {
        $locationAsUri = "file://${location}" -as [System.Uri]
        if( $locationAsUri.Scheme ) {
            return $locationAsUri
        }
    }
    throw "Cannot convert '$location' to System.Uri"
}


####
####
# Proxy functions
# This is where we map the parameters from v2 to v3
# In some cases we have the same parameters
# In some cases we have parameters which are not used in v3 - these we will silently ignore
#  the goal in ignoring them is to provide ways for automation to succeed without error rather than provide exact
#  semantic behavior between v2 and v3
# In some cases we have a way to map a v2 parameter into a v3 parameter
#  In those cases, we need to remove the parameter from the bound parameters and apply the value to the newly mapped parameter
# In some cases we have a completely new parameter which we need to set.
####
####
function Find-CommandProxy {
[Alias('Find-Command')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=733636')]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ModuleName},

    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${AllowPrerelease},

    [ValidateNotNull()]
    [string[]]
    ${Tag},

    [ValidateNotNull()]
    [string]
    ${Filter},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository})

begin
{
    Write-Warning -Message "The cmdlet 'Find-Command' is deprecated, please use 'Find-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    $PSBoundParameters['Type'] = 'command'
    # Parameter translations
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    if ( $PSBoundParameters['Tag'] )                 { $null = $PSBoundParameters.Remove('Tag'); $PSBoundParameters['Tags'] = $Tag }
    if ( $PSBoundParameters['DscResource'] )         { $null = $PSBoundParameters.Remove('DscResource'); $PSBoundParameters['Type'] = "DscResource" }
    if ( $PSBoundParameters['RoleCapability'] )      { $null = $PSBoundParameters.Remove('RoleCapability') ; $PSBoundParameters['Type'] = "RoleCapability"}
    if ( $PSBoundParameters['Command'] )             { $null = $PSBoundParameters.Remove('Command') ; $PSBoundParameters['Type'] = "command" }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Includes'] )            { $null = $PSBoundParameters.Remove('Includes') }
    if ( $PSBoundParameters['Proxy'] )               { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )     { $null = $PSBoundParameters.Remove('ProxyCredential') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Find-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Find-Command
.ForwardHelpCategory Function

#>

}


function Find-DscResourceProxy {
[Alias('Find-DscResource')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=517196')]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ModuleName},

    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${AllowPrerelease},

    [ValidateNotNull()]
    [string[]]
    ${Tag},

    [ValidateNotNull()]
    [string]
    ${Filter},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository})

begin
{
    Write-Warning -Message "The cmdlet 'Find-DscResource' is deprecated, please use 'Find-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        # PARAMETER MAP
        # add new specifier 
        $PSBoundParameters['Type'] = 'DscResource'
        # Parameter translations
        $verArgs = @{}
        if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
        if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
        if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
        if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
        $ver = Convert-VersionsToNugetVersion @verArgs
        if ( $ver ) {
            $PSBoundParameters['Version'] = $ver
        }

        # Parameter Deletions (unsupported in v3)
        if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
        if ( $PSBoundParameters['Tag'] )                 { $null = $PSBoundParameters.Remove('Tag'); $PSBoundParameters['Tags'] = $Tag }
        if ( $PSBoundParameters['Filter'] )              { $null = $PSBoundParameters.Remove('Filter') }
        if ( $PSBoundParameters['Proxy'] )               { $null = $PSBoundParameters.Remove('Proxy') }
        if ( $PSBoundParameters['ProxyCredential'] )     { $null = $PSBoundParameters.Remove('ProxyCredential') }
        # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Find-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Find-DscResource
.ForwardHelpCategory Function

#>

}

function Find-ModuleProxy {
[Alias('Find-Module')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=398574')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${IncludeDependencies},

    [ValidateNotNull()]
    [string]
    ${Filter},

    [ValidateNotNull()]
    [string[]]
    ${Tag},

    [ValidateSet('DscResource','Cmdlet','Function','RoleCapability')]
    [ValidateNotNull()]
    [string[]]
    ${Includes},

    [ValidateNotNull()]
    [string[]]
    ${DscResource},

    [ValidateNotNull()]
    [string[]]
    ${RoleCapability},

    [ValidateNotNull()]
    [string[]]
    ${Command},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Find-Module' is deprecated, please use 'Find-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    $PSBoundParameters['Type'] = 'module'
    # Parameter translations
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    if ( $PSBoundParameters['Tag'] )                 { $null = $PSBoundParameters.Remove('Tag'); $PSBoundParameters['Tags'] = $Tag }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    if ( $PSBoundParameters['DscResource'] )         { $null = $PSBoundParameters.Remove('DscResource'); $PSBoundParameters['Type'] = "DscResource" }
    if ( $PSBoundParameters['RoleCapability'] )      { $null = $PSBoundParameters.Remove('RoleCapability'); $PSBoundParameters['Type'] = "RoleCapability" }
    if ( $PSBoundParameters['Command'] )             { $null = $PSBoundParameters.Remove('Command'); $PSBoundParameters['Type'] = "command" }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Includes'] )            { $null = $PSBoundParameters.Remove('Includes') }
    if ( $PSBoundParameters['Proxy'] )               { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )     { $null = $PSBoundParameters.Remove('ProxyCredential') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Find-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Find-Module
.ForwardHelpCategory Function

#>

}

function Find-RoleCapabilityProxy {
[Alias('Find-RoleCapability')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=718029')]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ModuleName},

    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${AllowPrerelease},

    [ValidateNotNull()]
    [string[]]
    ${Tag},

    [ValidateNotNull()]
    [string]
    ${Filter},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    $PSBoundParameters['Type'] = 'RoleCapability'
    # Parameter translations
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    if ( $PSBoundParameters['Tag'] )                 { $null = $PSBoundParameters.Remove('Tag'); $PSBoundParameters['Tags'] = $Tag }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Filter'] )     { $null = $PSBoundParameters.Remove('Filter') }
    if ( $PSBoundParameters['Proxy'] )     { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )     { $null = $PSBoundParameters.Remove('ProxyCredential') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Find-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Find-RoleCapability
.ForwardHelpCategory Function

#>

}

function Find-ScriptProxy {
[Alias('Find-Script')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=619785')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${IncludeDependencies},

    [ValidateNotNull()]
    [string]
    ${Filter},

    [ValidateNotNull()]
    [string[]]
    ${Tag},

    [ValidateSet('Function','Workflow')]
    [ValidateNotNull()]
    [string[]]
    ${Includes},

    [ValidateNotNull()]
    [string[]]
    ${Command},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Find-Script' is deprecated, please use 'Find-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    $PSBoundParameters['Type'] = 'script'
    # Parameter translations
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    if ( $PSBoundParameters['Tag'] )                 { $null = $PSBoundParameters.Remove('Tag'); $PSBoundParameters['Tags'] = $Tag }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }

    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Filter'] )              { $null = $PSBoundParameters.Remove('Filter') }
    if ( $PSBoundParameters['Includes'] )            { $null = $PSBoundParameters.Remove('Includes') }
    if ( $PSBoundParameters['Command'] )             { $null = $PSBoundParameters.Remove('Command') }
    if ( $PSBoundParameters['Proxy'] )               { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )     { $null = $PSBoundParameters.Remove('ProxyCredential') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Find-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Find-Script
.ForwardHelpCategory Function

#>

}

function Get-InstalledModuleProxy {
[Alias('Get-InstalledModule')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=526863')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [switch]
    ${AllVersions},

    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Get-InstalledModule' is deprecated, please use 'Get-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['MinimumVersion'] )  { $null = $PSBoundParameters.Remove('MinimumVersion') }
    if ( $PSBoundParameters['RequiredVersion'] ) { $null = $PSBoundParameters.Remove('RequiredVersion') }
    if ( $PSBoundParameters['MaximumVersion'] )  { $null = $PSBoundParameters.Remove('MaximumVersion') }
    if ( $PSBoundParameters['AllVersions'] )     { $null = $PSBoundParameters.Remove('AllVersions') }
    if ( $PSBoundParameters['AllowPrerelease'] ) { $null = $PSBoundParameters.Remove('AllowPrerelease') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Get-InstalledModule
.ForwardHelpCategory Function

#>

}

function Get-InstalledScriptProxy {
[Alias('Get-InstalledScript')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=619790')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Get-InstalledScript' is deprecated, please use 'Get-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # Parameter translations
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['MinimumVersion'] )     { $null = $PSBoundParameters.Remove('MinimumVersion') }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion') }
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion') }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Get-InstalledScript
.ForwardHelpCategory Function

#>

}

function Get-PSRepositoryProxy {
[Alias('Get-PSRepository')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=517127')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name})

begin
{
    Write-Warning -Message "The cmdlet 'Get-PSRepository' is deprecated, please use 'Get-PSResourceRepository'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-PSResourceRepository', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Get-PSRepository
.ForwardHelpCategory Function

#>

}

function Install-ModuleProxy {
[Alias('Install-Module')]
[CmdletBinding(DefaultParameterSetName='NameParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkID=398573')]
param(
    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [ValidateSet('CurrentUser','AllUsers')]
    [string]
    ${Scope},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [switch]
    ${AllowClobber},

    [switch]
    ${SkipPublisherCheck},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense},

    [switch]
    ${PassThru})

begin
{
    Write-Warning -Message "The cmdlet 'Install-Module' is deprecated, please use 'Install-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )     { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )    { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }

    # Parameter translations
    if ( $PSBoundParameters['AllowClobber'] )       { $null = $PSBoundParameters.Remove('AllowClobber') }
    $PSBoundParameters['NoClobber'] = ! $AllowClobber
    if ( $PSBoundParameters['AllowPrerelease'] )    { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }

    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Proxy'] )              { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )    { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['SkipPublisherCheck'] ) { $null = $PSBoundParameters.Remove('SkipPublisherCheck') }
    if ( $PSBoundParameters['InputObject'] )        { $null = $PSBoundParameters.Remove('InputObject') }
    if ( $PSBoundParameters['PassThru'] )           { $null = $PSBoundParameters.Remove('PassThru') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Install-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Install-Module
.ForwardHelpCategory Function

#>

}

function Install-ScriptProxy {
[Alias('Install-Script')]
[CmdletBinding(DefaultParameterSetName='NameParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=619784')]
param(
    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [ValidateSet('CurrentUser','AllUsers')]
    [string]
    ${Scope},

    [switch]
    ${NoPathUpdate},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense},

    [switch]
    ${PassThru})

begin
{
    Write-Warning -Message "The cmdlet 'Install-Script' is deprecated, please use 'Install-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )     { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )    { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    # Parameter translations
    if ( $PSBoundParameters['AllowPrerelease'] )    { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['InputObject'] )      { $null = $PSBoundParameters.Remove('InputObject') }
    if ( $PSBoundParameters['NoPathUpdate'] )     { $null = $PSBoundParameters.Remove('NoPathUpdate') }
    if ( $PSBoundParameters['Proxy'] )            { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )  { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['PassThru'] )         { $null = $PSBoundParameters.Remove('PassThru') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Install-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Install-Script
.ForwardHelpCategory Function

#>

}

function Publish-ModuleProxy {
[Alias('Publish-Module')]
[CmdletBinding(DefaultParameterSetName='ModuleNameParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', PositionalBinding=$false, HelpUri='https://go.microsoft.com/fwlink/?LinkID=398575')]
param(
    [Parameter(ParameterSetName='ModuleNameParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='ModulePathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RequiredVersion},

    [ValidateNotNullOrEmpty()]
    [string]
    ${NuGetApiKey},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [ValidateSet('2.0')]
    [version]
    ${FormatVersion},

    [string[]]
    ${ReleaseNotes},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Tags},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${LicenseUri},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${IconUri},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${ProjectUri},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Exclude},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='ModuleNameParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${SkipAutomaticTags})

begin
{
    Write-Warning -Message "The cmdlet 'Publish-Module' is deprecated, please use 'Publish-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # Parameter translations
    if ( $PSBoundParameters['NuGetApiKey'] )       { $null = $PSBoundParameters.Remove('NuGetApiKey'); $PSBoundParameters['APIKey'] = $NuGetApiKey }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Name'] )              { $null = $PSBoundParameters.Remove('Name') }
    if ( $PSBoundParameters['RequiredVersion'] )   { $null = $PSBoundParameters.Remove('RequiredVersion') }
    if ( $PSBoundParameters['Repository'] )        { $null = $PSBoundParameters.Remove('Repository') }
    if ( $PSBoundParameters['FormatVersion'] )     { $null = $PSBoundParameters.Remove('FormatVersion') }
    if ( $PSBoundParameters['Force'] )             { $null = $PSBoundParameters.Remove('Force') }
    if ( $PSBoundParameters['AllowPrerelease'] )   { $null = $PSBoundParameters.Remove('AllowPrerelease') }
    if ( $PSBoundParameters['SkipAutomaticTags'] ) { $null = $PSBoundParameters.Remove('SkipAutomaticTags') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Publish-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Publish-Module
.ForwardHelpCategory Function

#>

}

function Publish-ScriptProxy {
[Alias('Publish-Script')]
[CmdletBinding(DefaultParameterSetName='PathParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', PositionalBinding=$false, HelpUri='https://go.microsoft.com/fwlink/?LinkId=619788')]
param(
    [Parameter(ParameterSetName='PathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(ParameterSetName='LiteralPathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${LiteralPath},

    [ValidateNotNullOrEmpty()]
    [string]
    ${NuGetApiKey},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Repository},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${Force})

begin
{
    Write-Warning -Message "The cmdlet 'Publish-Script' is deprecated, please use 'Publish-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # Parameter translations
    if ( $PSBoundParameters['NuGetApiKey'] )  { $null = $PSBoundParameters.Remove('NuGetApiKey'); $PSBoundParameters['APIKey'] = $NuGetApiKey }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Force'] )        { $null = $PSBoundParameters.Remove('Force') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Publish-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Publish-Script
.ForwardHelpCategory Function

#>

}

function Register-PSRepositoryProxy {
[Alias('Register-PSRepository')]
[CmdletBinding(DefaultParameterSetName='NameParameterSet', HelpUri='https://go.microsoft.com/fwlink/?LinkID=517129')]
param(
    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${SourceLocation},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${PublishLocation},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${ScriptSourceLocation},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${ScriptPublishLocation},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [Parameter(ParameterSetName='PSGalleryParameterSet', Mandatory=$true)]
    [switch]
    ${Default},

    [ValidateSet('Trusted','Untrusted')]
    [string]
    ${InstallationPolicy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [Parameter(ParameterSetName='NameParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${PackageManagementProvider})

begin
{
    Write-Warning -Message "The cmdlet 'Register-PSRepository' is deprecated, please use 'Register-PSResourceRepository'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # Parameter translations
    if ( $PSBoundParameters['InstallationPolicy'] ) {
        $null = $PSBoundParameters.Remove('InstallationPolicy')
        if  ( $InstallationPolicy -eq "Trusted" ) {
            $PSBoundParameters['Trusted'] = $true
        }
    }
    if ( $PSBoundParameters['SourceLocation'] )            { $null = $PSBoundParameters.Remove('SourceLocation'); $PSBoundParameters['Url'] = Convert-ToUri -location $SourceLocation }
    if ( $PSBoundParameters['Default'] )                   { $null = $PSBoundParameters.Remove('Default'); $PSBoundParameters['PSGallery'] = $Default }
    
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['PublishLocation'] )           { $null = $PSBoundParameters.Remove('PublishLocation') }
    if ( $PSBoundParameters['ScriptSourceLocation'] )      { $null = $PSBoundParameters.Remove('ScriptSourceLocation') }
    if ( $PSBoundParameters['ScriptPublishLocation'] )     { $null = $PSBoundParameters.Remove('ScriptPublishLocation') }
    if ( $PSBoundParameters['Proxy'] )                     { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )           { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['PackageManagementProvider'] ) { $null = $PSBoundParameters.Remove('PackageManagementProvider') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Register-PSResourceRepository', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Register-PSRepository
.ForwardHelpCategory Function

#>

}

function Save-ModuleProxy {
[Alias('Save-Module')]
[CmdletBinding(DefaultParameterSetName='NameAndPathParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=531351')]
param(
    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObjectAndLiteralPathParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='InputObjectAndPathParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [Parameter(ParameterSetName='InputObjectAndPathParameterSet', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Path},

    [Parameter(ParameterSetName='InputObjectAndLiteralPathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string]
    ${LiteralPath},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet')]
    [Parameter(ParameterSetName='NameAndPathParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense})

begin
{
    Write-Warning -Message "The cmdlet 'Save-Module' is deprecated, please use 'Save-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # remove until available
    if ( $PSBoundParameters['InputObject'] )     { $null = $PSBoundParameters.Remove('InputObject') }

    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )   { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )   { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )  { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }

    # Parameter translations
    if ( $PSBoundParameters['AllowPrerelease'] )  { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    if ( $PSBoundParameters['LiteralPath'] )      { $null = $PSBoundParameters.Remove('LiteralPath'); $PSBoundParameters['Path'] = $LiteralPath }

    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Proxy'] )            { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )  { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['Force'] )            { $null = $PSBoundParameters.Remove('Force') }
    if ( $PSBoundParameters['AcceptLicense'] )    { $null = $PSBoundParameters.Remove('AcceptLicense') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Save-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Save-Module
.ForwardHelpCategory Function

#>

}

function Save-ScriptProxy {
[Alias('Save-Script')]
[CmdletBinding(DefaultParameterSetName='NameAndPathParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=619786')]
param(
    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObjectAndLiteralPathParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='InputObjectAndPathParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Repository},

    [Parameter(ParameterSetName='InputObjectAndPathParameterSet', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndPathParameterSet', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Path},

    [Parameter(ParameterSetName='InputObjectAndLiteralPathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string]
    ${LiteralPath},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameAndLiteralPathParameterSet')]
    [Parameter(ParameterSetName='NameAndPathParameterSet')]
    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense})

begin
{
    Write-Warning -Message "The cmdlet 'Save-Script' is deprecated, please use 'Save-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifiers

    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MinimumVersion'] )     { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )    { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }

    # Parameter translations
    # LiteralPath needs to be converted to Path - we know they won't be used together because they're in different parameter sets 
    if ( $PSBoundParameters['LiteralPath'] )        { $null = $PSBoundParameters.Remove('LiteralPath'); $PSBoundParameters['Path'] = $LiteralPath }
    if ( $PSBoundParameters['AllowPrerelease'] )    { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }

    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['InputObject'] )     { $null = $PSBoundParameters.Remove('InputObject') }
    if ( $PSBoundParameters['Proxy'] )           { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] ) { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['Force'] )          { $null = $PSBoundParameters.Remove('Force') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Save-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Save-Script
.ForwardHelpCategory Function

#>

}

function Set-PSRepositoryProxy {
[Alias('Set-PSRepository')]
[CmdletBinding(PositionalBinding=$false, HelpUri='https://go.microsoft.com/fwlink/?LinkID=517128')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${SourceLocation},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${PublishLocation},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${ScriptSourceLocation},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${ScriptPublishLocation},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [ValidateSet('Trusted','Untrusted')]
    [string]
    ${InstallationPolicy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [ValidateNotNullOrEmpty()]
    [string]
    ${PackageManagementProvider})

begin
{
    Write-Warning -Message "The cmdlet 'Set-PSRepository' is deprecated, please use 'Set-PSResourceRepository'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # Parameter translations
    if ( $PSBoundParameters['InstallationPolicy'] ) {
        $null = $PSBoundParameters.Remove('InstallationPolicy')
        if  ( $InstallationPolicy -eq "Trusted" ) {
            $PSBoundParameters['Trusted'] = $true
        }
        else {
            $PSBoundParameters['Trusted'] = $false
        }
    }
    if ( $PSBoundParameters['SourceLocation'] )            { $null = $PSBoundParameters.Remove('SourceLocation'); $PSBoundParameters['Url'] = Convert-ToUri -location $SourceLocation }
    if ( $PSBoundParameters['Default'] )                   { $null = $PSBoundParameters.Remove('Default'); $PSBoundParameters['PSGallery'] = $Default }
    
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['PublishLocation'] )           { $null = $PSBoundParameters.Remove('PublishLocation') }
    if ( $PSBoundParameters['ScriptSourceLocation'] )      { $null = $PSBoundParameters.Remove('ScriptSourceLocation') }
    if ( $PSBoundParameters['ScriptPublishLocation'] )     { $null = $PSBoundParameters.Remove('ScriptPublishLocation') }
    if ( $PSBoundParameters['Proxy'] )                     { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )           { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['PackageManagementProvider'] ) { $null = $PSBoundParameters.Remove('PackageManagementProvider') }

    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Set-PSResourceRepository', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Set-PSRepository
.ForwardHelpCategory Function

#>

}

function Uninstall-ModuleProxy {
[Alias('Uninstall-Module')]
[CmdletBinding(DefaultParameterSetName='NameParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=526864')]
param(
    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ParameterSetName='NameParameterSet')]
    [switch]
    ${AllVersions},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameParameterSet')]
    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Uninstall-Module' is deprecated, please use 'Uninstall-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # add new specifier 
    # Parameter translations
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['InputObject'] )         { $null = $PSBoundParameters.Remove('InputObject') }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Uninstall-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Uninstall-Module
.ForwardHelpCategory Function

#>

}

function Uninstall-ScriptProxy {
[Alias('Uninstall-Script')]
[CmdletBinding(DefaultParameterSetName='NameParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=619789')]
param(
    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ParameterSetName='InputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [psobject[]]
    ${InputObject},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MinimumVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ParameterSetName='NameParameterSet', ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='NameParameterSet')]
    [switch]
    ${AllowPrerelease})

begin
{
    Write-Warning -Message "The cmdlet 'Uninstall-Script' is deprecated, please use 'Uninstall-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # Parameter translations
    if ( $PSBoundParameters['MinimumVersion'] )      { $null = $PSBoundParameters.Remove('MinimumVersion'); $verArgs['MinimumVersion'] = $MinumumVersion }
    if ( $PSBoundParameters['MaximumVersion'] )      { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )     { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    if ( $PSBoundParameters['AllVersions'] )         { $null = $PSBoundParameters.Remove('AllVersions'); $verArgs['RequiredVersion'] = '*' }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['InputObject'] )     { $null = $PSBoundParameters.Remove('InputObject') }
    if ( $PSBoundParameters['AllowPrerelease'] )     { $null = $PSBoundParameters.Remove('AllowPrerelease') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Uninstall-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Uninstall-Script
.ForwardHelpCategory Function

#>

}

function Unregister-PSRepositoryProxy {
[Alias('Unregister-PSRepository')]
[CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=517130')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name})

begin
{
    Write-Warning -Message "The cmdlet 'Unregister-PSRepository' is deprecated, please use 'Unregister-PSResourceRepository'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    # No changes between Unregister-PSRepository and Unregister-PSResourceRepository
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Unregister-PSResourceRepository', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Unregister-PSRepository
.ForwardHelpCategory Function

#>

}

function Update-ModuleProxy {
[Alias('Update-Module')]
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkID=398576')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [ValidateSet('CurrentUser','AllUsers')]
    [string]
    ${Scope},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [switch]
    ${Force},

    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense},

    [switch]
    ${PassThru})

begin
{
    Write-Warning -Message "The cmdlet 'Update-Module' is deprecated, please use 'Update-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    $PSBoundParameters['Type'] = 'module'
    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )    { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }

    # Parameter translations
    if ( $PSBoundParameters['AllowPrerelease'] )    { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }

    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Proxy'] )              { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )    { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['PassThru'] )           { $null = $PSBoundParameters.Remove('PassThru') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Update-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Update-Module
.ForwardHelpCategory Function

#>

}

function Update-ScriptProxy {
[Alias('Update-Script')]
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=619787')]
param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${RequiredVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string]
    ${MaximumVersion},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Proxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${ProxyCredential},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential},

    [switch]
    ${Force},

    [switch]
    ${AllowPrerelease},

    [switch]
    ${AcceptLicense},

    [switch]
    ${PassThru})

begin
{
    Write-Warning -Message "The cmdlet 'Update-Script' is deprecated, please use 'Update-PSResource'."
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

    # PARAMETER MAP
    $PSBoundParameters['Type'] = 'script'
    # handle version changes
    $verArgs = @{}
    if ( $PSBoundParameters['MaximumVersion'] )     { $null = $PSBoundParameters.Remove('MaximumVersion'); $verArgs['MaximumVersion'] = $MaximumVersion }
    if ( $PSBoundParameters['RequiredVersion'] )    { $null = $PSBoundParameters.Remove('RequiredVersion'); $verArgs['RequiredVersion'] = $RequiredVersion }
    $ver = Convert-VersionsToNugetVersion @verArgs
    if ( $ver ) {
        $PSBoundParameters['Version'] = $ver
    }

    # Parameter translations
    if ( $PSBoundParameters['AllowPrerelease'] )    { $null = $PSBoundParameters.Remove('AllowPrerelease'); $PSBoundParameters['Prerelease'] = $AllowPrerelease }
    # Parameter Deletions (unsupported in v3)
    if ( $PSBoundParameters['Proxy'] )             { $null = $PSBoundParameters.Remove('Proxy') }
    if ( $PSBoundParameters['ProxyCredential'] )   { $null = $PSBoundParameters.Remove('ProxyCredential') }
    if ( $PSBoundParameters['PassThru'] )          { $null = $PSBoundParameters.Remove('PassThru') }
    # END PARAMETER MAP

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Update-PSResource', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline()
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Update-Script
.ForwardHelpCategory Function

#>

}

$functionsToExport = @(
    "Find-CommandProxy", 
    "Find-DscResourceProxy", 
    "Find-ModuleProxy",
    "Find-RoleCapabilityProxy",
    "Find-ScriptProxy",
    "Get-InstalledModuleProxy",
    "Get-InstalledScriptProxy",
    "Get-PSRepositoryProxy",
    "Install-ModuleProxy",
    "Install-ScriptProxy",
    "Publish-ModuleProxy",
    "Publish-ScriptProxy",
    "Register-PSRepositoryProxy",
    "Save-ModuleProxy",
    "Save-ScriptProxy",
    "Set-PSRepositoryProxy",
    "Uninstall-ModuleProxy",
    "Uninstall-ScriptProxy",
    "Unregister-PSRepositoryProxy",
    "Update-ModuleProxy",
    "Update-ScriptProxy"
)

$aliasesToExport = @(
    "Find-Command",
    "Find-DscResource",
    "Find-Module",
    "Find-RoleCapability",
    "Find-Script",
    "Get-InstalledModule",
    "Get-InstalledScript",
    "Get-PSRepository",
    "Install-Module",
    "Install-Script",
    "Publish-Module",
    "Publish-Script",
    "Register-PSRepository",
    "Save-Module",
    "Save-Script",
    "Set-PSRepository",
    "Uninstall-Module",
    "Uninstall-Script",
    "Unregister-PSRepository",
    "Update-Module",
    "Update-Script"
)

export-ModuleMember -Function $functionsToExport -Alias $aliasesToExport

# SIG # Begin signature block
# MIIjiQYJKoZIhvcNAQcCoIIjejCCI3YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC9mM2C3x9HTl4h
# +xhHyYZyGsEZuvOIVo69/2h3AgYRtaCCDYUwggYDMIID66ADAgECAhMzAAABiK9S
# 1rmSbej5AAAAAAGIMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjAwMzA0MTgzOTQ4WhcNMjEwMzAzMTgzOTQ4WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCSCNryE+Cewy2m4t/a74wZ7C9YTwv1PyC4BvM/kSWPNs8n0RTe+FvYfU+E9uf0
# t7nYlAzHjK+plif2BhD+NgdhIUQ8sVwWO39tjvQRHjP2//vSvIfmmkRoML1Ihnjs
# 9kQiZQzYRDYYRp9xSQYmRwQjk5hl8/U7RgOiQDitVHaU7BT1MI92lfZRuIIDDYBd
# vXtbclYJMVOwqZtv0O9zQCret6R+fRSGaDNfEEpcILL+D7RV3M4uaJE4Ta6KAOdv
# V+MVaJp1YXFTZPKtpjHO6d9pHQPZiG7NdC6QbnRGmsa48uNQrb6AfmLKDI1Lp31W
# MogTaX5tZf+CZT9PSuvjOCLNAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUj9RJL9zNrPcL10RZdMQIXZN7MG8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ1ODM4NjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# ACnXo8hjp7FeT+H6iQlV3CcGnkSbFvIpKYafgzYCFo3UHY1VHYJVb5jHEO8oG26Q
# qBELmak6MTI+ra3WKMTGhE1sEIlowTcp4IAs8a5wpCh6Vf4Z/bAtIppP3p3gXk2X
# 8UXTc+WxjQYsDkFiSzo/OBa5hkdW1g4EpO43l9mjToBdqEPtIXsZ7Hi1/6y4gK0P
# mMiwG8LMpSn0n/oSHGjrUNBgHJPxgs63Slf58QGBznuXiRaXmfTUDdrvhRocdxIM
# i8nXQwWACMiQzJSRzBP5S2wUq7nMAqjaTbeXhJqD2SFVHdUYlKruvtPSwbnqSRWT
# GI8s4FEXt+TL3w5JnwVZmZkUFoioQDMMjFyaKurdJ6pnzbr1h6QW0R97fWc8xEIz
# LIOiU2rjwWAtlQqFO8KNiykjYGyEf5LyAJKAO+rJd9fsYR+VBauIEQoYmjnUbTXM
# SY2Lf5KMluWlDOGVh8q6XjmBccpaT+8tCfxpaVYPi1ncnwTwaPQvVq8RjWDRB7Pa
# 8ruHgj2HJFi69+hcq7mWx5nTUtzzFa7RSZfE5a1a5AuBmGNRr7f8cNfa01+tiWjV
# Kk1a+gJUBSP0sIxecFbVSXTZ7bqeal45XSDIisZBkWb+83TbXdTGMDSUFKTAdtC+
# r35GfsN8QVy59Hb5ZYzAXczhgRmk7NyE6jD0Ym5TKiW5MIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCFVowghVWAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAGIr1LWuZJt6PkAAAAA
# AYgwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICFu
# Wm96ykFZmmb3B0gRUkJgE9Ty90qIlD9AIJDfj31HMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAPo8MNezm67nNtjFYphB/U5rF84MFT8kbBhwx
# 1iIf42Cx329wFqTtmV+wVwbE8GPkm4m+Iptg+13rEiyFg6EtuqxYvh/515ZMOMaM
# imC1xVWZMCMZeT755PQM2fgT24Gu8/3Qw5vC91bNGhDDcaKvMj8aBain6b7Uh/z+
# GxU/XxhUGPzeZlz5NPmCr16ODNV+R3Is4/bjDwu5mCtA0xFT0fF+CwT+S9Ecojvy
# tNAJugpZdxyAneGkJ1XeGSQHrNQL2wrhXKMNNFstUSRcXL9shQyHCP3GA8nbPFX3
# fp/iT3t9kJcyNy4YgujRP/F8q89vfABQmXUBnZ2dY/mtMaiFmaGCEuQwghLgBgor
# BgEEAYI3AwMBMYIS0DCCEswGCSqGSIb3DQEHAqCCEr0wghK5AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFQBgsqhkiG9w0BCRABBKCCAT8EggE7MIIBNwIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCB72Bz9lxTjrWZ7HmVpH4HvBiiRAmJljWZm
# A4hnCXDETAIGXxYKF24bGBIyMDIwMDcyMzE5MzIwMi45OFowBIACAfSggdCkgc0w
# gcoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
# HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBU
# U1MgRVNOOjEyQkMtRTNBRS03NEVCMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1T
# dGFtcCBTZXJ2aWNloIIOPDCCBPEwggPZoAMCAQICEzMAAAEh97GBmyNE1wwAAAAA
# ASEwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAw
# HhcNMTkxMTEzMjE0MDQyWhcNMjEwMjExMjE0MDQyWjCByjELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MTJCQy1FM0FF
# LTc0RUIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDQCHhpfx2GygASmkk36b/lhYA4
# pR/Uy13RRupY6dzUpVeHJ9RORDtLhG+AnEeWrJcXj2K1tN0YfdJIqIIFwRwuPlqY
# RIvMGWSoa8g9OfMMoZPZhm06limLuJ+X4QlVHgyJ0Kh2mEB+Tp55jTf5OHhWYdGE
# nyCXGMJcj5MkC9UB0uuudHy+hu5HwvW1oXGcBcQEazrLtzG2t4lm6jwoxYjaDF9/
# 0W4CHqapxD/8oPEcGCjnrNmcMc0Xt9aHdngTKIV/TL8UOs5pYTL+X9NaYDO6FFgA
# SvfWvkrP42zoxE36pBhAWax8UhT67Km4+2Xrz+FN9RMukAOt+Lg1lKsGo2fHAgMB
# AAGjggEbMIIBFzAdBgNVHQ4EFgQUgm2ixcxt3F/nuAwdE6nddtJe9BwwHwYDVR0j
# BBgwFoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0
# cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljVGltU3Rh
# UENBXzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNUaW1TdGFQQ0Ff
# MjAxMC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcD
# CDANBgkqhkiG9w0BAQsFAAOCAQEAmchnoJ9VlIo1/w0OQTqq3GJb4BtOtNb3fIW1
# JlU5x80+QOP2JCzR+wHy+eha4OfeSbrBaI4+XKVv7ZWbX9DBYX2NJjpTMgEw1H80
# FhyqghJPMXp/mQbhkb6UpCQ4KldVlsvA1e18P7xft6Y7miM+ZYm+GIZztMkQizn0
# hAGVMnZ6hWDIA8Fa/1ZwxHMiHlzAYPA7JYpvVnfpnYJIfx0mue9BI40SsQWNiTrQ
# 7tTIqd9M5IlPZ/Gy7ApXDTJWrw+qYDjL5ylN+v6uGsC+FXOfAzS4B1xj3KDpz/DR
# ao82W4Gb5ILAKBWsvbi+M7l+TjPguE++tEXAcEJYwDsW+bBiTzCCBnEwggRZoAMC
# AQICCmEJgSoAAAAAAAIwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENl
# cnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTEwMDcwMTIxMzY1NVoXDTI1MDcw
# MTIxNDY1NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpHQ28dxGKOiDs/BOX9fp/aZRrdFQQ1aUK
# AIKF++18aEssX8XD5WHCdrc+Zitb8BVTJwQxH0EbGpUdzgkTjnxhMFmxMEQP8WCI
# hFRDDNdNuDgIs0Ldk6zWczBXJoKjRQ3Q6vVHgc2/JGAyWGBG8lhHhjKEHnRhZ5Ff
# gVSxz5NMksHEpl3RYRNuKMYa+YaAu99h/EbBJx0kZxJyGiGKr0tkiVBisV39dx89
# 8Fd1rL2KQk1AUdEPnAY+Z3/1ZsADlkR+79BL/W7lmsqxqPJ6Kgox8NpOBpG2iAg1
# 6HgcsOmZzTznL0S6p/TcZL2kAcEgCZN4zfy8wMlEXV4WnAEFTyJNAgMBAAGjggHm
# MIIB4jAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU1WM6XIoxkPNDe3xGG8Uz
# aFqFbVUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8G
# A1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQw
# VgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUF
# BwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwgaAGA1UdIAEB/wSB
# lTCBkjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUFBwIBFjFodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1bHQuaHRtMEAGCCsGAQUFBwIC
# MDQeMiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5AF8AUwB0AGEAdABlAG0AZQBu
# AHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAH5ohRDeLG4Jg/gXEDPZ2joSFvs+um
# zPUxvs8F4qn++ldtGTCzwsVmyWrf9efweL3HqJ4l4/m87WtUVwgrUYJEEvu5U4zM
# 9GASinbMQEBBm9xcF/9c+V4XNZgkVkt070IQyK+/f8Z/8jd9Wj8c8pl5SpFSAK84
# Dxf1L3mBZdmptWvkx872ynoAb0swRCQiPM/tA6WWj1kpvLb9BOFwnzJKJ/1Vry/+
# tuWOM7tiX5rbV0Dp8c6ZZpCM/2pif93FSguRJuI57BlKcWOdeyFtw5yjojz6f32W
# apB4pm3S4Zz5Hfw42JT0xqUKloakvZ4argRCg7i1gJsiOCC1JeVk7Pf0v35jWSUP
# ei45V3aicaoGig+JFrphpxHLmtgOR5qAxdDNp9DvfYPw4TtxCd9ddJgiCGHasFAe
# b73x4QDf5zEHpJM692VHeOj4qEir995yfmFrb3epgcunCaw5u+zGy9iCtHLNHfS4
# hQEegPsbiSpUObJb2sgNVZl6h3M7COaYLeqN4DMuEin1wC9UJyH3yKxO2ii4sanb
# lrKnQqLJzxlBTeCG+SqaoxFmMNO7dDJL32N79ZmKLxvHIa9Zta7cRDyXUHHXodLF
# VeNp3lfB0d4wwP3M5k37Db9dT+mdHhk4L7zPWAUu7w2gUDXa7wknHNWzfjUeCLra
# NtvTX4/edIhJEqGCAs4wggI3AgEBMIH4oYHQpIHNMIHKMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmlj
# YSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoxMkJDLUUzQUUt
# NzRFQjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEB
# MAcGBSsOAwIaAxUAr8ajO2jqA+vCGdK+EdBXUKpju2mggYMwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOLD1EgwIhgP
# MjAyMDA3MjMxNzE4MDBaGA8yMDIwMDcyNDE3MTgwMFowdzA9BgorBgEEAYRZCgQB
# MS8wLTAKAgUA4sPUSAIBADAKAgEAAgIi3AIB/zAHAgEAAgISMTAKAgUA4sUlyAIB
# ADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQow
# CAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAB1ivkDya5vMG/LPyp29YOOL09EC
# yidrokyhl0lYA7OA2De5DGRvwJMgg+O7eoZLIcfwRk9VRYNFTdwDT4Mkk7KL5XPk
# 4LrUpqvsqsn1QL7SukSof+g0EBJ7V3rck0XU9B7TOslyeZ/QgmCD+6cJ7owx25kV
# oUULC2xbs/UYqwlsMYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAAEh97GBmyNE1wwAAAAAASEwDQYJYIZIAWUDBAIBBQCgggFK
# MBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgAXof
# tyYyr5y0af5ZbTEM/5uFu3Sj09tPFVSWY4g1MXkwgfoGCyqGSIb3DQEJEAIvMYHq
# MIHnMIHkMIG9BCD+EWyTV+m7ADABlfBFNTu+ajQt8d5kp47taXho+rTnYDCBmDCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABIfexgZsjRNcM
# AAAAAAEhMCIEINLrJ/hHF+v/woMiMbwOHthuNyYMyH7WJbWmh68UoRrxMA0GCSqG
# SIb3DQEBCwUABIIBADQjdKJF0jzDo8e3x/odD6dp+eYrlqV3PQZpoSXk3Kl1FRr5
# x2YQHc+5/JnYaDdPw+UYSD0mp6m+PsHKA5mcYo37IjXJ3NWi8+btqk9X36m9Kud6
# 3Sjeiojs7eZmYQBNE5DR8LapoE/AwR7+CVHqocenTefIqBRGQBwAF/EOh/tHrDWV
# YWL6zWgAbK1Yk2M6eDHo3PQEkASWFxBsSsE+5AeII7xF1qI7G2q3/MKYNiktVvYD
# xcXbvVwiBz9gFB3/j1Acb8YmzC/V1XXRAneGb4QC5bCsVC2W6Dfs94Zb1NnHvRr+
# 1ZuxYyEyHJjXoZ/pHNREwXEeEqi9SEc4azKg6DI=
# SIG # End signature block

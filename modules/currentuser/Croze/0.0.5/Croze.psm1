# Module created by Microsoft.PowerShell.Crescendo
Function Get-HomebrewTap
{
[CmdletBinding()]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ($output)
                        if ($output) {
                            $output | ForEach-Object {
                                [PSCustomObject]@{
                                    Name = $_
                                }
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "tap"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Return Homebrew taps

#>
}

Function Register-HomebrewTap
{
[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[string]$Name,
[Parameter()]
[string]$Location
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Location = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "tap"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Register a new Homebrew tap

.PARAMETER Name
Source Name


.PARAMETER Location
Source Location



#>
}

Function Unregister-HomebrewTap
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
[string]$Name
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "untap"
        "-f"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Unregister an existing Homebrew tap

.PARAMETER Name
Source Name



#>
}

Function Install-HomebrewPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask,
[Parameter()]
[switch]$Force
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Force = @{ OriginalName = '--force'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )

        if ($output -match 'Pouring') {
            # Formula output - capture package and dependency name and version
            $output | Select-String 'Pouring (?<name>\S+)(?<=\w)(-+)(?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -in 'name','version').Value

                [PSCustomObject]@{
                    Name = $match[0]
                    Version = $match[1]
                }
            }
        } elseif ($output -match 'was successfully') {
            # Cask output - capture package only
            $output | Select-String '(?<name>\S+) was successfully' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -eq 'name').Value
                [PSCustomObject]@{
                    Name = $match
                }
            }
        }
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "install"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Install a new package with Homebrew

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask


.PARAMETER Force
Force



#>
}

Function Get-HomebrewPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ( $output )

                        if ($output) {
                            $output | ConvertFrom-StringData -Delimiter ' ' | ForEach-Object {
                                # Brew supports installing multiple versions side-by-side, but instead of listing them as separate rows, it puts multiple versions on the same row. 
                                # To present this package data in a way that's idiomatic to PowerShell, we need to list each version as a separate object:
                                $_.GetEnumerator() | ForEach-Object {
                                    $name = $_.Name
                                    $_.Value -split ' ' | Select-Object -Property @{
                                        Name = 'Name'
                                        Expression = {$name}
                                    },
                                    @{
                                        Name = 'Version'
                                        Expression = {$_}
                                    }
                                }
                            } | Select-Object Name,Version
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "list"
        "--versions"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Get a list of installed Homebrew packages

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask



#>
}

Function Find-HomebrewPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ( $output )

                        if ($output) {

                            $output | Select-String '==>' | Select-Object -ExpandProperty LineNumber | ForEach-Object {
                                # The line numbers from Select-Object start at 1 instead of 0
                                $index = $_ - 1
                                switch -WildCard ($output[$index]) {
                                    '*Formulae*' {
                                        $formulaeStartIndex = $index
                                    }
                                    '*Casks*' {
                                        $casksStartIndex = $index
                                    }
                                }   
                            }
                            
                            # Determine the range of formulae output based on whether we also have cask output
                            $formulaeEndIndex = $(
                                # Cant use a standard check here, because a valid value could be '0', which would evaluate to $false
                                if ($formulaeStartIndex -ne $null) {
                                    if ($casksStartIndex) {
                                        # Stop capturing formulae output two rows before the start of the Cask index
                                        $casksStartIndex-2
                                    }
                                    else {
                                        # Capture to the entire output
                                        $output.Length
                                    }
                                }
                            )
                            
                            # Cant use a standard check here, because a valid value could be '0', which would evaluate to $false
                            if ($formulaeStartIndex -ne $null) {
                                $output[($formulaeStartIndex+1)..$formulaeEndIndex] | ForEach-Object {
                                    [PSCustomObject]@{
                                        Name = $_
                                        Type = 'Formula'
                                    }
                                }
                            }
                            
                            if ($casksStartIndex -ne $null) {
                                $output[($casksStartIndex+1)..($output.Length)] | ForEach-Object {
                                    [PSCustomObject]@{
                                        Name = $_
                                        Type = 'Cask'
                                    }
                                }
                            }
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "search"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Find a list of available Homebrew packages

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask



#>
}

Function Update-HomebrewPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )

        if ($output -match 'Pouring') {
            # Formula output - capture package and dependency name and version
            $output | Select-String 'Pouring (?<name>\S+)(?<=\w)(-+)(?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -in 'name','version').Value

                [PSCustomObject]@{
                    Name = $match[0]
                    Version = $match[1]
                }
            }
        } elseif ($output -match 'was successfully') {
            # Cask output - capture package only
            $output | Select-String '(?<name>\S+) was successfully' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -eq 'name').Value
                [PSCustomObject]@{
                    Name = $match
                }
            }
        }
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "upgrade"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Updates an installed package to the latest version

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask



#>
}

Function Uninstall-HomebrewPackage
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
        param ( $output )
     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "uninstall"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Uninstall an existing package with Homebrew

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask



#>
}

Function Get-HomebrewPackageInfo
{
[CmdletBinding()]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name,
[Parameter()]
[switch]$Formula,
[Parameter()]
[switch]$Cask
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
        Formula = @{ OriginalName = '--formula'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Cask = @{ OriginalName = '--cask'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ( $output )

                        $output | ConvertFrom-Json | ForEach-Object {
                            $_.formulae
                            $_.casks
                        }
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "info"
        "--json=v2"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Shows information on a specific Homebrew package

.PARAMETER Name
Package Name


.PARAMETER Formula
Formula


.PARAMETER Cask
Cask



#>
}

Function Get-HomebrewTapInfo
{
[CmdletBinding(DefaultParameterSetName='Default')]

param(
[Parameter(ValueFromPipelineByPropertyName=$true)]
[string]$Name
    )

BEGIN {
    $__PARAMETERMAP = @{
        Name = @{ OriginalName = ''; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $False }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { 
                        param ( $output )

                        $output | ConvertFrom-Json
                     } }
    }
}
PROCESS {
    $__commandArgs = @(
        "tap-info"
        "--json"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message brew
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("brew")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "brew" $__commandArgs | & $__handler
        }
        else {
            $result = & "brew" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Shows information on a specific Homebrew package

.PARAMETER Name
Package Name



#>
}

Export-ModuleMember -Function Get-HomebrewTap, Register-HomebrewTap, Unregister-HomebrewTap, Install-HomebrewPackage, Get-HomebrewPackage, Find-HomebrewPackage, Update-HomebrewPackage, Uninstall-HomebrewPackage, Get-HomebrewPackageInfo, Get-HomebrewTapInfo

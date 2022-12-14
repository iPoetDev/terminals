<#
.SYNOPSIS
Adds an environment variable item for given Name, Item, Scope (default; 'Process') and Separator (';') and optional Index.

.EXAMPLE

Add 'C:\tmp' to $env:Path user environment variable

PS> Add-EnvironmentVariableItem -Name path -Item C:\tmp -Scope User -WhatIf
What if:
    Current Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin
    New Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin;C:\tmp

.EXAMPLE

Insert 'C:\tmp' as first item in $env:Path user environment variable

PS> Add-EnvironmentVariableItem -Name path -Item C:\tmp -Scope User -Index 0 -WhatIf
What if:
    Current Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin
    New Value:
        C:\tmp;C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin

.EXAMPLE

Insert 'C:\tmp' as second last item in $env:Path process environment variable

PS> Add-EnvironmentVariableItem -Name path -Item C:\tmp -Scope Process -Index -2 -WhatIf
What if:
    Current Value:
        C:\Program Files\PowerShell\7;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files (x86)\ATI Technologies\ATI.ACE\Core-Static;C:\ProgramData\chocolatey\bin;C:\Program Files\PowerShell\7\;C:\Program Files\Git\cmd;C:\Program Files\Microsoft VS Code\bin;C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps
    New Value:
        C:\Program Files\PowerShell\7;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files (x86)\ATI Technologies\ATI.ACE\Core-Static;C:\ProgramData\chocolatey\bin;C:\Program Files\PowerShell\7\;C:\Program Files\Git\cmd;C:\Program Files\Microsoft VS Code\bin;C:\tmp;C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps

.EXAMPLE

PS > Add 'cake' as second item of $env:foo user environment variable

PS> aevi foo cake -sc user -in 1 -se '#' -wh
What if:
    Current Value:
        foo#bar#cup
    New Value:
        foo#cake#bar#cup
#>
function Add-EnvironmentVariableItem {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(
            Mandatory,
            Position = 0
        )]
            [ValidatePattern("[^=]+")]
            [String] $Name,        
        [Parameter(
            Mandatory,
            Position = 1
        )] 
            [String] $Item,        
        [Parameter()]
            [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
        [Parameter()]
            [String] $Separator = ';',
        [Parameter()] 
            [int] $Index
    )    
    process {

        $evis = Get-EnvironmentVariableItems -Name $Name -Scope $Scope -Separator $Separator

        if ($PSBoundParameters.ContainsKey('Index')) {
            $result = $evis.AddItem($Item, $Index)
        } else {
            $result = $evis.AddItem($Item)
        }

        if ($result -eq $True) {
                $s = GetWhatIf
            if ($PSCmdlet.ShouldProcess($s, '', '')){
                #$evis.UpdateEnvironmentVariable()
                $evis.SetEnvironmentVariable($evis.Name, $evis.ToString(), $evis.Scope)
                $evis
            }
        } else { 
            return
        }
    }
}


<#
.SYNOPSIS
Gets an EnvironmentVariableItems object for a given Name, Scope (default; 'Process') and Separator (';').

.EXAMPLE

Get current process $env:Path EnvironmentVariableItems object

PS> Get-EnvironmentVariableItems -Name Path 

Name      : Path
Scope     : Process
Separator : ;
Value     : C:\Program Files\PowerShell\7;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.
            0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files (x86)\ATI
            Technologies\ATI.ACE\Core-Static;C:\ProgramData\chocolatey\bin;C:\Program Files\PowerShell\7\;C:\Program
            Files\Git\cmd;C:\Program Files\Microsoft VS Code\bin;C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps
Items     : {C:\Program Files\PowerShell\7, C:\WINDOWS\system32, C:\WINDOWS, C:\WINDOWS\System32\Wbem???}

.EXAMPLE

Get user $env:Path EnvironmentVariableItems object

PS> Get-EnvironmentVariableItems -Name Path -Scope User

Name      : Path
Scope     : User
Separator : ;
Value     : C:\tmp;C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps
Items     : {C:\tmp, C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps}

.EXAMPLE

Get user $env:foo EnvironmentVariableItems object

PS> gevis foo -sc user -se '#'

Name      : foo
Scope     : User
Separator : #
Value     : foo#cake#bar#cup
Items     : {foo, cake, bar, cup}

#>
function Get-EnvironmentVariableItems {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
            [String] $Name,
        [Parameter()]
            #[System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
            [System.EnvironmentVariableTarget] $Scope,
        [Parameter()]
            [String] $Separator = ';'
    )    
    process {

        # preserve user provided Scope value before setting default
        $Script:ScopePreDefault = $Scope
        if ($null -eq $Scope) {
            $Scope = [System.EnvironmentVariableTarget]::Process
        } 

        $evis = New-EnvironmentVariableItems-Object $Name $Scope $Separator
        $evis.Value = $evis.GetEnvironmentVariable($Name, $Scope)
        $evis.SetItems($Name, $Scope, $Separator)

        $evis
    }
}

function GetWhatIf() {
    @"

    Current Value: 
        $($evis.Value)
    New Value: 
        $($evis.ToString())

"@
}

function New-EnvironmentVariableItems-Object {
    param (
        [String] $Name,
        [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
        [String] $Separator = ';'
    )
    process {
        $obj = [PSCustomObject]@{}

        $obj | Add-Member ScriptMethod AddItem { 
            param (
                [String] $Item,        
                [int] $Index
            )    
            process {
                if ($PSBoundParameters.ContainsKey('Index')) {
                    # Add 1 to items count reflecting length after addition
                    if (($ind = $this.GetPositiveIndex($Index, $this.Items.count + 1)) -is [int]) {
                        $this.Items.insert($ind, $Item)
                        return $True
                    }                    
                } else {
                    $this.Items.add($Item)
                    return $True
                }
            }
         } -Force
        
         $obj | Add-Member ScriptMethod GetEnvironmentVariable { 
            param (
                [String] $Name,        
                [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process
            )
            process {
                [Environment]::GetEnvironmentVariable($Name, $Scope)
            }
         }

         $obj | Add-Member ScriptMethod GetItems { 
            param (
                [String] $Name,
                [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
                [String] $Separator = ';'
            )
            process {
                $value = $this.GetEnvironmentVariable($Name, $Scope)

                if ($null -ne $value) {$value = $value.Trim($Separator)}
        
                $items = @()
                if ($null -ne $value) {        
                    $items = $value -split $Separator
                }

                $items
            }
         }
            
         # check index is within range and return (as positive value if required)
        $obj | Add-Member ScriptMethod GetPositiveIndex { 
            param (
                [int] $Index,
                [int] $ItemsCount
            )

            if ($Index -lt $ItemsCount -and $(-($Index) -le $ItemsCount)) {
                if ($Index -lt 0) {
                    $ItemsCount + $Index
                } else {
                    $Index
                }
            } else {
                Write-Host
                Write-Host  -ForegroundColor Red "Index $Index is out of range"
                Write-Host
            }
            
        } -Force

        $obj | Add-Member ScriptMethod RemoveItemByIndex { 
            param (
                [int] $Index
            )    
            process {
                if (($ind = $this.GetPositiveIndex($Index, $this.Items.count)) -is [int]) {
                    $this.Items.RemoveAt($ind)
                } else {
                    return $False
                }                    
            }
         } -Force
        
         $obj | Add-Member ScriptMethod RemoveItemByItem { 
            param (
                [String] $Item
            )    
            process {
                if (($this.Items.IndexOf($Item)) -ge 0) {
                    $this.Items.Remove($Item)
                } else {
                    Write-Host
                    Write-Host  -ForegroundColor Red "Item $Item not found"
                    Write-Host
                    return $False
                }                    
            }
         } -Force

         $obj | Add-Member ScriptMethod SetItems { 
            param (
                [String] $Name = $this.Name,
                [System.EnvironmentVariableTarget] $Scope = $this.Scope,
                [String] $Separator = $this.Separator
            )
            process {
                $this.Items = [System.Collections.ArrayList] @($this.GetItems($Name, $Scope, $Separator))
            }
         }

        $obj | Add-Member ScriptMethod ShowIndex { 

            process {
                Write-Host 
                if ($null -eq $Script:ScopePreDefault) {
                    $this.ShowIndexForScope([System.EnvironmentVariableTarget]::Machine)
                    $this.ShowIndexForScope([System.EnvironmentVariableTarget]::User)
                    $this.ShowIndexForScope([System.EnvironmentVariableTarget]::Process)
                } else {
                    $this.ShowIndexForScope($this.Scope)
                }
                Write-Host
                Write-Host
            }
         } -Force

         $obj | Add-Member ScriptMethod ShowIndexForScope { 
            param (
                [System.EnvironmentVariableTarget] $Scope
            )
            process {
                Write-Host $Scope
                $items = @($this.GetItems($this.Name, $Scope, $this.Separator))
                for ($i = 0; $i -lt $items.count; $i++) {
                    Write-Host -ForegroundColor Blue "${i}: $($items[$i].ToString())"
                }
                Write-Host
            }
         } -Force



         $obj | Add-Member ScriptMethod SetEnvironmentVariable { 
            param (
                [String] $Name,        
                [String] $Value,        
                [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process
            )
            process {
                [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
                $this.Value = $Value
            }
         }

         $obj | Add-Member ScriptMethod ToString { 
            $s = ''
            for ($i = 0; $i -lt $this.Items.count; $i++) {
                if ($i) { $s += $this.Separator}
                $s += $this.Items[$i]
            }
            $s
         } -Force

         $obj | Add-Member -NotePropertyName Name -NotePropertyValue $Name
         $obj | Add-Member -NotePropertyName Scope -NotePropertyValue $Scope
         $obj | Add-Member -NotePropertyName Separator -NotePropertyValue $Separator

         $obj | Add-Member -NotePropertyName Value -NotePropertyValue $Item

     $items = [System.Collections.ArrayList]@()
        $obj | Add-Member -NotePropertyName Items -NotePropertyValue $items 
 
        return $obj
    }
}

<#
.SYNOPSIS
Removes an environment variable item for given Name, Item and Scope (default; 'Process') and Separator (';') and optional Index.

.EXAMPLE

Remove 'C:\tmp' from $env:Path user environment variable

PS> Remove-EnvironmentVariableItem -Name path -Item 'C:\tmp' -Scope User -WhatIf

What if:
    Current Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\tmp;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin
    New Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin

.EXAMPLE

Remove last item from $env:Path user environment variable

PS> Remove-EnvironmentVariableItem -Name path -Scope User -Index -1 -WhatIf

What if:

    Current Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps;C:\Users\michaelf\AppData\Local\Programs\Microsoft VS Code\bin
    New Value:
        C:\Users\michaelf\AppData\Local\Microsoft\WindowsApps

.EXAMPLE

Remove second item from $env:foo user environment variable

PS> sevis foo

Machine
0: mat#mop

User
0: foo#cake#bar#cup

Process
0: foo#cake#bar#cup

PS> sevis foo -sc user -se '#'

User
0: foo
1: cake
2: bar
3: cup

PS> revi foo -in 1 -sc user -se '#'

Confirm
Are you sure you want to perform this action?

    Current Value:
        foo#cake#bar#cup
    New Value:
        foo#bar#cup
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

Name      : foo
Scope     : User
Separator : #
Value     : foo#bar#cup
Items     : {foo, bar, cup}

PS> sevis foo

Machine
0: mat#mop

User
0: foo#bar#cup

Process
0: foo#cake#bar#cup

PS> $env:foo
foo#cake#bar#cup

PS> [Environment]::GetEnvironmentVariable('foo', 'User')
foo#bar#cup
#>
function Remove-EnvironmentVariableItem {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(
            Mandatory,
            Position = 0
        )]
            [ValidatePattern("[^=]+")]
            [String] $Name,        
        [Parameter(
            Mandatory,
            ParameterSetName = 'ByItem',
            Position = 1 
        )] 
            [String] $Item,        
        [Parameter(
            ParameterSetName = 'ByIndex',
            Position = 1, 
            Mandatory
        )] [int] $Index,
        [Parameter()]
            [System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
        [Parameter()] 
            [String] $Separator = ";"

    ) 
    process {

        $evis = Get-EnvironmentVariableItems -Name $Name -Scope $Scope -Separator $Separator

        if ($PSCmdlet.ParameterSetName -eq 'ByIndex') {
            $result = $evis.RemoveItemByIndex($Index) -ne $False
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByItem') {
            $result = $evis.RemoveItemByItem($Item) -ne $False
        }

        if ($result -ne $False) {
            $s = GetWhatIf
            if ($PSCmdlet.ShouldProcess($s, '', '')){
                #$evis.UpdateEnvironmentVariable()
                $evis.SetEnvironmentVariable($evis.Name, $evis.ToString(), $evis.Scope)
                $evis
            }
        } else { 
            return
        }


    }
}

<#
.SYNOPSIS
Show indexed list of environment variable items for given Name, Scope and Separator (default: ';').  Omitting Scope parameter shows list for all, ie., Machine, User and Process.

.EXAMPLE

Show $env:PSModulePath items

PS> Show-EnvironmentVariableItems PSModulePath

Machine
0: C:\Program Files\WindowsPowerShell\Modules
1: C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
2: N:\lib\pow\mod

User
0: H:\lib\pow\mod

Process
0: C:\Users\michaelf\Documents\PowerShell\Modules
1: C:\Program Files\PowerShell\Modules
2: c:\program files\powershell\7\Modules
3: H:\lib\pow\mod
4: C:\Program Files\WindowsPowerShell\Modules
5: C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
6: N:\lib\pow\mod

.EXAMPLE

Show PSModulePath system variable items

PS> Show-EnvironmentVariableItems PSModulePath -Scope Machine

Machine
0: C:\Program Files\WindowsPowerShell\Modules
1: C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
2: N:\lib\pow\mod

.EXAMPLE

Show system, user and process items for $env:TMP environment variable

PS> Show-EnvironmentVariableItems TMP

Machine
0: C:\WINDOWS\TEMP

User
0: C:\Users\michaelf\AppData\Local\Temp

Process
0: C:\Users\michaelf\AppData\Local\Temp
#>
function Show-EnvironmentVariableItems {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
            [String] $Name,
        [Parameter()]
            #[System.EnvironmentVariableTarget] $Scope = [System.EnvironmentVariableTarget]::Process,
            [System.EnvironmentVariableTarget] $Scope,
        [Parameter()]
            [String] $Separator = ';'
    )    
    process {

        if ($null -eq $Scope) {
            $evis = Get-EnvironmentVariableItems -Name $Name -Separator $Separator
        } else {
            $evis = Get-EnvironmentVariableItems -Name $Name -Scope $Scope -Separator $Separator
        }

        $evis.ShowIndex()
    }
}

New-Alias -Name aevi -Value Add-EnvironmentVariableItem
New-Alias -Name gevis -Value Get-EnvironmentVariableItems
New-Alias -Name revi -Value Remove-EnvironmentVariableItem
New-Alias -Name sevis -Value Show-EnvironmentVariableItems

Export-ModuleMember -Alias * -Function *
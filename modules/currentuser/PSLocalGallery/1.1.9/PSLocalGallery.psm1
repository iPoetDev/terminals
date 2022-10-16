Class PSLocalGalleryInformation {
    [string]$Name
    [string]$Path
    [bool]$Exists
    [int]$PackageTotal
    [int]$PackageUnique
    [bool]$IsRegistered

    PSLocalGalleryInformation ([string]$Name, [string]$Path, [bool]$Exists, [int]$PackageTotal, [int]$PackageUnique, [bool]$IsRegistered) {
        $this.Name = $Name
        $this.Path = $Path
        $this.Exists = $Exists
        $this.PackageTotal = $PackageTotal
        $this.PackageUnique = $PackageUnique
        $this.IsRegistered = $IsRegistered
    }

    [string]ToString() {
        return ("{0}" -f $this.Name)
    }
}
Function Test-PSLocalGalleryRegistration {
    [CmdletBinding()]
    Param()

    $A = Get-PSRepository -Name 'PSLocalGallery' -ErrorAction SilentlyContinue
    If ($A) {Write-Output $True} Else {Write-Output $False}
}
Function Get-PSLocalGallery {
    <#
    .EXTERNALHELP PSLocalGallery-help.xml
    #>
    [CmdletBinding()]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    $IsRegistered = $(Test-PSLocalGalleryRegistration)
    $Exists = $(Test-Path -Path $PSLocalGalleryPath)
    If ($Exists) {
        $Packages = Get-ChildItem -Path $PSLocalGalleryPath -File | Where-Object {$_.Extension -eq '.nupkg'}
        $PackageCount = $Packages.Count
        If ($PackageCount -ne 0) {
            $Names = $Packages.name
            $Unique = $Names | ForEach-Object {
                $_.split('.')[0]
            } | Select-Object -Unique
            $UniqueCount = $Unique.count
        } Else {
            $UniqueCount = 0
        }
    } Else {
        $PackageCount = 0
        $UniqueCount = 0
    }
    Write-Output $(New-Object -TypeName PSLocalGalleryInformation -ArgumentList 'PSLocalGallery',
                                                                        $PSLocalGalleryPath,
                                                                        $Exists,
                                                                        $PackageCount,
                                                                        $UniqueCount,
                                                                        $IsRegistered)
}
Function New-PSLocalGallery {
    <#
    .EXTERNALHELP PSLocalGallery-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        If ((Test-Path -Path "$PSLocalGalleryPath") -eq $False) {
            Try {
                If ($PSCmdlet.ShouldProcess("Creating PSLocalGalleryPath: $PSLocalGalleryPath")) {
                    [void](New-Item -Path $PSLocalGalleryPath -ItemType Directory -Force -ErrorAction Stop)
                }
            } Catch {
                Throw "$($_.Exception.Message)"
            }
        } Else {
            Write-Verbose "PSLocalGallery path already exists: $PSLocalGalleryPath"
        }
    } Else {
        Throw "This function requires Administrator permissions"
    }
}
Function Register-PSLocalGallery {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    $RegParams = @{
        Name = 'PSLocalGallery'
        SourceLocation = $PSLocalGalleryPath
        PublishLocation = $PSLocalGalleryPath
        InstallationPolicy = 'Trusted'
    }
    Try {
        If ($PSCmdlet.ShouldProcess("Registering PSLocalGallery")) {
            Register-PSRepository @RegParams -ErrorAction Stop
        }
    } Catch {
        Throw "$($_.Exception.Message)"
    }
}

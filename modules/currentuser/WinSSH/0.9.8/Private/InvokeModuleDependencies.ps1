function InvokeModuleDependencies {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [pscustomobject[]]$RequiredModules,

        [Parameter(Mandatory=$False)]
        [switch]$InstallModulesNotAvailableLocally
    )

    if ($InstallModulesNotAvailableLocally) {
        if ($PSVersionTable.PSEdition -ne "Core") {
            $null = Install-PackageProvider -Name Nuget -Force -Confirm:$False
            $null = Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        else {
            $null = Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
        $InvPSCompatSplatParams = @{
            ErrorAction                         = "SilentlyContinue"
            #WarningAction                       = "SilentlyContinue"
        }

        $MyInvParentScope = Get-Variable "MyInvocation" -Scope 1 -ValueOnly
        $PathToFile = $MyInvParentScope.MyCommand.Source
        $FunctionName = $MyInvParentScope.MyCommand.Name

        if ($PathToFile) {
            $InvPSCompatSplatParams.Add("InvocationMethod",$PathToFile)
        }
        elseif ($FunctionName) {
            $InvPSCompatSplatParams.Add("InvocationMethod",$FunctionName)
        }
        else {
            Write-Error "Unable to determine MyInvocation Source or Name! Halting!"
            $global:FunctionResult = "1"
            return
        }

        if ($PSBoundParameters['InstallModulesNotAvailableLocally']) {
            $InvPSCompatSplatParams.Add("InstallModulesNotAvailableLocally",$True)
        }
        if ($PSBoundParameters['RequiredModules']) {
            $InvPSCompatSplatParams.Add("RequiredModules",$RequiredModules.Name)
        }

        $Output = InvokePSCompatibility @InvPSCompatSplatParams
    }
    else {
        [System.Collections.ArrayList]$SuccessfulModuleImports = @()
        [System.Collections.ArrayList]$FailedModuleImports = @()

        foreach ($ModuleObj in $RequiredModules) {
            $ModuleInfo = [pscustomobject]@{
                ModulePSCompatibility   = "WinPS"
                ModuleName              = $ModuleObj.Name
                Version                 = $ModuleObj.Version
            }

            if (![bool]$(Get-Module -ListAvailable $ModuleObj.Name) -and $InstallModulesNotAvailableLocally) {
                $searchUrl = "https://www.powershellgallery.com/api/v2/Packages?`$filter=Id eq '$($ModuleObj.Name)' and IsLatestVersion"
                $PSGalleryCheck = Invoke-RestMethod $searchUrl
                if (!$PSGalleryCheck -or $PSGalleryCheck.Count -eq 0 -or $ModuleObj.Version -eq "PreRelease") {
                    $searchUrl = "https://www.powershellgallery.com/api/v2/Packages?`$filter=Id eq '$($ModuleObj.Name)'"
                    $PSGalleryCheck = Invoke-RestMethod $searchUrl

                    if (!$PSGalleryCheck -or $PSGalleryCheck.Count -eq 0) {
                        Write-Warning "Unable to find Module '$($ModuleObj.Name)' in the PSGallery! Skipping..."
                        continue
                    }

                    $PreRelease = $True
                }

                try {
                    if ($PreRelease) {
                        try {
                            Install-Module $ModuleObj.Name -AllowPrerelease -AllowClobber -Force -ErrorAction Stop -WarningAction SilentlyContinue
                        }
                        catch {
                            ManualPSGalleryModuleInstall -ModuleName $ModuleObj.Name -DownloadDirectory "$HOME\Downloads" -PreRelease -ErrorAction Stop -WarningAction SilentlyContinue
                        }
                    }
                    else {
                        Install-Module $ModuleObj.Name -AllowClobber -Force -ErrorAction Stop -WarningAction SilentlyContinue
                    }

                    if ($PSVersionTable.Platform -eq "Unix" -or $PSVersionTable.OS -match "Darwin") {
                        # Make sure the Module Manifest file name and the Module Folder name are exactly the same case
                        $env:PSModulePath -split ':' | foreach {
                            Get-ChildItem -Path $_ -Directory | Where-Object {$_ -match $ModuleObj.Name}
                        } | foreach {
                            $ManifestFileName = $(Get-ChildItem -Path $_ -Recurse -File | Where-Object {$_.Name -match "$($ModuleObj.Name)\.psd1"}).BaseName
                            if (![bool]$($_.Name -cmatch $ManifestFileName)) {
                                Rename-Item $_ $ManifestFileName
                            }
                        }
                    }
                }
                catch {
                    Write-Error $_
                    $global:FunctionResult = "1"
                    return
                }
            }

            if (![bool]$(Get-Module -ListAvailable $ModuleObj.Name)) {
                $ErrMsg = "The Module '$($ModuleObj.Name)' is not available on the localhost! Did you " +
                "use the -InstallModulesNotAvailableLocally switch? Halting!"
                Write-Error $ErrMsg
                continue
            }

            $ManifestFileItem = Get-Item $(Get-Module -ListAvailable $ModuleObj.Name).Path
            $ModuleInfo | Add-Member -Type NoteProperty -Name ManifestFileItem -Value $ManifestFileItem

            # Import the Module
            try {
                Import-Module $ModuleObj.Name -Scope Global -ErrorAction Stop -WarningAction SilentlyContinue
                $null = $SuccessfulModuleImports.Add($ModuleInfo)
            }
            catch {
                Write-Warning "Problem importing the $($ModuleObj.Name) Module!"
                $null = $FailedModuleImports.Add($ModuleInfo)
            }
        }

        $UnacceptableUnloadedModules = $FailedModuleImports

        $Output = [pscustomobject]@{
            SuccessfulModuleImports         = $SuccessfulModuleImports
            FailedModuleImports             = $FailedModuleImports
            UnacceptableUnloadedModules     = $UnacceptableUnloadedModules
        }
    }

    $Output
}

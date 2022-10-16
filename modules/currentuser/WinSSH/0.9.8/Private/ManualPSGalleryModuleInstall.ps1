function ManualPSGalleryModuleInstall {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$ModuleName,

        [Parameter(Mandatory=$False)]
        [switch]$PreRelease,

        [Parameter(Mandatory=$False)]
        [string]$DownloadDirectory
    )

    if (!$DownloadDirectory) {
        $DownloadDirectory = $(Get-Location).Path
    }

    if (!$(Test-Path $DownloadDirectory)) {
        Write-Error "The path $DownloadDirectory was not found! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if (![bool]$($($env:PSModulePath -split ";") -match [regex]::Escape("$HOME\Documents\WindowsPowerShell\Modules"))) {
        $env:PSModulePath = "$HOME\Documents\WindowsPowerShell\Modules;$env:PSModulePath"
    }
    if (!$(Test-Path "$HOME\Documents\WindowsPowerShell\Modules")) {
        $null = New-Item -ItemType Directory "$HOME\Documents\WindowsPowerShell\Modules" -Force
    }

    if ($PreRelease) {
        $searchUrl = "https://www.powershellgallery.com/api/v2/Packages?`$filter=Id eq '$ModuleName'"
    }
    else {
        $searchUrl = "https://www.powershellgallery.com/api/v2/Packages?`$filter=Id eq '$ModuleName' and IsLatestVersion"
    }
    $ModuleInfo = Invoke-RestMethod $searchUrl
    if (!$ModuleInfo -or $ModuleInfo.Count -eq 0) {
        Write-Error "Unable to find Module Named $ModuleName! Halting!"
        $global:FunctionResult = "1"
        return
    }
    if ($PreRelease) {
        if ($ModuleInfo.Count -gt 1) {
            $ModuleInfo = $($ModuleInfo | Sort-Object -Property Updated | Where-Object {$_.properties.isPrerelease.'#text' -eq 'true'})[-1]
        }
    }
    
    $OutFilePath = Join-Path $DownloadDirectory $($ModuleInfo.title.'#text' + $ModuleInfo.properties.version + '.zip')
    if (Test-Path $OutFilePath) {Remove-Item $OutFilePath -Force}

    try {
        #Invoke-WebRequest $ModuleInfo.Content.src -OutFile $OutFilePath
        # Download via System.Net.WebClient is a lot faster than Invoke-WebRequest...
        $WebClient = [System.Net.WebClient]::new()
        $WebClient.Downloadfile($ModuleInfo.Content.src, $OutFilePath)
    }
    catch {
        Write-Error $_
        $global:FunctionResult = "1"
        return
    }
    
    if (Test-Path "$DownloadDirectory\$ModuleName") {Remove-Item "$DownloadDirectory\$ModuleName" -Recurse -Force}
    Expand-Archive $OutFilePath -DestinationPath "$DownloadDirectory\$ModuleName"

    if ($DownloadDirectory -ne "$HOME\Documents\WindowsPowerShell\Modules") {
        if (Test-Path "$HOME\Documents\WindowsPowerShell\Modules\$ModuleName") {
            Remove-Item "$HOME\Documents\WindowsPowerShell\Modules\$ModuleName" -Recurse -Force
        }
        Copy-Item -Path "$DownloadDirectory\$ModuleName" -Recurse -Destination "$HOME\Documents\WindowsPowerShell\Modules"

        Remove-Item "$DownloadDirectory\$ModuleName" -Recurse -Force
    }

    Remove-Item $OutFilePath -Force
}

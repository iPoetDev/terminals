function Get-GitModule {

    [CmdletBinding(HelpUri='https://github.com/iricigor/InstallModuleFromGit/blob/master/Docs/Get-GitModule.md')]

    param (
        
        
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,Position=0,ParameterSetName='ByUri')]
        [string[]]$ProjectUri,
        # https://github.com/dfinke/InstallModuleFromGitHub
        # https://github.com/iricigor/FIFA2018
        
        [Parameter(Mandatory,ParameterSetName='ByName')]
        [string[]]$Name,

        [string]$Branch = "master",
        [switch]$KeepTempCopy

    )

    BEGIN {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        if (!(Test-Prerequisites)) {
            throw "$FunctionName prerequisites not met"
            # TODO: Add more details
        }

        if ($env:AGENT_TEMPDIRECTORY) {
            $tmpRoot = $env:AGENT_TEMPDIRECTORY    
        } else {
            $tmpRoot = [System.IO.Path]::GetTempPath()
        }     
        
        if ($Name) {$ProjectUri = ConvertTo-Uri -Name $Name}

    }

    PROCESS {

        foreach ($P1 in $ProjectUri) {

            Write-Verbose -Message "$(Get-Date -f T)   processing $P1"

            $ModuleName = ($P1 -split '/')[-1]
            $tempDir = Join-Path $tmpRoot $ModuleName
            if (!(Test-Path $tempDir)) {
                Write-Verbose -Message "$(Get-Date -f T)   creating directory $tempDir"
                New-Item $tempDir -ItemType Directory -Force | Out-Null
            } elseif (Get-ChildItem $tempDir -Force) {
                Write-Verbose -Message "$(Get-Date -f T)   deleting content of temp directory $tempDir"
                Remove-Item (Join-Path $tempDir '*') -Recurse -Force
            }
            Write-Verbose -Message "$(Get-Date -f T)   cloning repository to $tempDir"
            git clone $P1 --branch $Branch --single-branch $tempDir --quiet
            $psd1 = Get-ChildItem $tempDir -Include *.psd1 -Recurse
            if (!$psd1) {
                # try to make manifest from psm1 file
                Write-Verbose -Message "$(Get-Date -f T)   manifest not found, searching for root module"
                $psm1 = Get-ChildItem $tempDir -Include *.psm1 -Recurse
                if ($psm1.FullName -is [string]) {
                    Write-Verbose -Message "$(Get-Date -f T)   root module $($psm1.Name) found"
                    $psd1File = $psm1.FullName -replace 'psm1$','psd1'
                    New-ModuleManifest -Path $psd1File -RootModule $psm1.Name -ModuleVersion ([version]::new()) | Out-Null
                    $psd1 = Get-ChildItem $tempDir -Include *.psd1 -Recurse
                }
            }

            $psd0 = $psd1 | ? BaseName -eq $ModuleName
            if (($psd1 -is [array]) -and (@($psd0).Count -ne 1)) {
                $errorText = "$FunctionName found multiple module manifests for $ModuleName"
            } elseif (($psd1 -is [array]) -and (@($psd0).Count -eq 1)) {
                $ModuleVersion = (Get-Content -Raw $psd0.FullName | Invoke-Expression).ModuleVersion
                $errorText = $null
                $psd1 = $psd0
            } elseif (!($psd1.FullName -is [string])) {
                $errorText = "$FunctionName found no module manifest for $ModuleName"
            } else {
                $ModuleVersion = (Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                $errorText = $null
            }

            if ($KeepTempCopy) {
                Write-Verbose -Message "$(Get-Date -f T)   not deleting temp copy"
            } else {
                Write-Verbose -Message "$(Get-Date -f T)   deleting temp copy"
                Remove-Item $tempDir -Force -Recurse -ea 0 | Out-Null
            }

            if ($errorText) {
                # we need to throw the error after deleting temp directory
                Write-Error $errorText
                continue
            }

            # return value
            Write-Verbose -Message "$(Get-Date -f T)   preparing return value"
            [PSCustomObject]@{
                Name = $ModuleName
                Version = $ModuleVersion
                LocalPath = if ($KeepTempCopy) {$tempDir} else {$null}
                Root = ((Split-Path $psd1.FullName -Parent) -eq $tempDir)
                SameName = ($psd1.BaseName -eq $ModuleName)
                ManifestName = $psd1.BaseName
                GitPath = $P1
            }
        }
    }

    END {
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName completed"
    }

}
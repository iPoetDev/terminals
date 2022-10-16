# This is a locally sourced Imports file for local development.
# It can be imported by the psm1 in local development to add script level variables.
# It will merged in the build process. This is for local development only.

# region script variables
$script:resourcePath = "$PSScriptRoot\Resources"


<#
.EXTERNALHELP Catesta-help.xml
#>
function New-PowerShellProject {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = 'CICD Platform Choice')]
        [ValidateSet('AWS', 'GitHubActions', 'Azure', 'AppVeyor', 'ModuleOnly')]
        [string]
        $CICDChoice,

        [Parameter(Mandatory = $true,
            HelpMessage = 'File path where PowerShell Module project will be created')]
        [string]
        $DestinationPath,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Skip confirmation')]
        [switch]$Force
    )
    Begin {

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        Write-Verbose -Message ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)

    } #begin
    Process {
        # -Confirm --> $ConfirmPreference = 'Low'
        # ShouldProcess intercepts WhatIf* --> no need to pass it on
        if ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")) {
            Write-Verbose -Message ('[{0}] Reached command' -f $MyInvocation.MyCommand)
            $ConfirmPreference = 'None'

            Write-Verbose -Message 'Importing Plaster...'
            try {
                Import-Module -Name Plaster -ErrorAction Stop
                Write-Verbose 'Plaster Imported.'
            }
            catch {
                throw $_
            }

            Write-Verbose -Message 'Sourcing correct template...'
            switch ($CICDChoice) {
                'AWS' {
                    Write-Verbose -Message 'AWS Template Selected.'
                    $path = '\AWS'
                } #aws
                'GitHubActions' {
                    Write-Verbose -Message 'GitHub Actions Template Selected.'
                    $path = '\GitHubActions'
                } #githubactions
                'Azure' {
                    Write-Verbose -Message 'Azure Pipelines Template Selected.'
                    $path = '\Azure'
                } #azure
                'AppVeyor' {
                    Write-Verbose -Message 'AppVeyor Template Selected.'
                    $path = '\AppVeyor'
                } #appveyor
                'ModuleOnly' {
                    Write-Verbose -Message 'Module Only Template Selected.'
                    $path = '\Vanilla'
                } #moduleonly
            } #switch

            Write-Verbose -Message 'Deploying template...'
            try {
                Write-Verbose -Message "Template Path: $script:resourcePath\$path"
                $invokePlasterSplat = @{
                    TemplatePath    = "$script:resourcePath\$path"
                    DestinationPath = $DestinationPath
                    VAULT           = 'NOTVAULT'
                    PassThru        = $true
                    ErrorAction     = 'Stop'
                }

                $results = Invoke-Plaster @invokePlasterSplat
                Write-Verbose -Message 'Template Deployed.'
            }
            catch {
                Write-Error $_
                $results = [PSCustomObject]@{
                    Success = $false
                }
            }
        } #if_Should
    } #process
    End {
        return $results
    } #end
} #New-PowerShellProject



<#
.EXTERNALHELP Catesta-help.xml
#>
function New-VaultProject {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = 'CICD Platform Choice')]
        [ValidateSet('AWS', 'GitHubActions', 'Azure', 'AppVeyor', 'ModuleOnly')]
        [string]
        $CICDChoice,

        [Parameter(Mandatory = $true,
            HelpMessage = 'File path where PowerShell SecretManagement vault module project will be created')]
        [string]
        $DestinationPath,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Skip confirmation')]
        [switch]$Force
    )
    Begin {

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        Write-Verbose -Message ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    } #begin
    Process {
        # -Confirm --> $ConfirmPreference = 'Low'
        # ShouldProcess intercepts WhatIf* --> no need to pass it on
        if ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")) {
            Write-Verbose -Message ('[{0}] Reached command' -f $MyInvocation.MyCommand)
            $ConfirmPreference = 'None'

            Write-Verbose -Message 'Importing Plaster...'
            try {
                Import-Module -Name Plaster -ErrorAction Stop
                Write-Verbose 'Plaster Imported.'
            }
            catch {
                throw $_
            }

            Write-Verbose -Message 'Sourcing correct template...'
            switch ($CICDChoice) {
                'AWS' {
                    Write-Verbose -Message 'AWS Template Selected.'
                    $path = '\AWS\Vault'
                } #aws
                'GitHubActions' {
                    Write-Verbose -Message 'GitHub Actions Template Selected.'
                    $path = '\GitHubActions\Vault'
                } #githubactions
                'Azure' {
                    Write-Verbose -Message 'Azure Pipelines Template Selected.'
                    $path = '\Azure\Vault'
                } #azure
                'AppVeyor' {
                    Write-Verbose -Message 'AppVeyor Template Selected.'
                    $path = '\AppVeyor\Vault'
                } #appveyor
                'ModuleOnly' {
                    Write-Verbose -Message 'Module Only Template Selected.'
                    $path = '\Vanilla\Vault'
                } #moduleonly
            } #switch

            Write-Verbose -Message 'Deploying template...'
            try {
                Write-Verbose -Message "Template Path: $script:resourcePath\$path"
                $invokePlasterSplat = @{
                    TemplatePath    = "$script:resourcePath\$path"
                    DestinationPath = $DestinationPath
                    VAULT           = 'VAULT'
                    PassThru        = $true
                    ErrorAction     = 'Stop'
                }
                $results = Invoke-Plaster @invokePlasterSplat
                Write-Verbose -Message 'Template Deployed.'
            }
            catch {
                Write-Error $_
                $results = [PSCustomObject]@{
                    Success = $false
                }
            }
        } #if_Should
    } #process
    End {
        return $results
    } #end
} #New-VaultProject





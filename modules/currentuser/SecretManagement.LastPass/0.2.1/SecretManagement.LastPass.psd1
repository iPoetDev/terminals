#
# Module manifest for module 'asdf'
#
# Generated by: tyleonha
#
# Generated on: 9/20/2020
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'SecretManagement.LastPass.psm1'

    # Version number of this module.
    ModuleVersion     = '0.2.1'

    # ID used to uniquely identify this module
    GUID              = '3d07be57-4898-4c8a-82cd-dbe06ec67e48'

    # Author of this module
    Author            = 'TylerLeonhardt'

    # Company or vendor of this module
    CompanyName       = 'TylerLeonhardt'

    # Copyright statement for this module
    Copyright         = '(c) Tyler Leonhardt. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'SecretManagement extension for LastPass!'

    # Minimum version of the PowerShell engine required by this module
    # PowerShellVersion = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = './SecretManagement.LastPass.Extension'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Connect-LastPass', 'Disconnect-Lastpass', 'Register-LastPassVault', 'Unregister-LastPassVault','Sync-LastPassVault','Show-LastPassGridView')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'SecretManagement', 'Secrets', 'LastPass', 'MacOS', 'Linux', 'Windows'

            # A URL to the license for this module.
            LicenseUri   = 'https://raw.githubusercontent.com/TylerLeonhardt/SecretManagement.LastPass/master/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/TylerLeonhardt/SecretManagement.LastPass'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
## 0.2.1

* Bug fix

## 0.2.0

Check out the docs in the README or use `Get-Help <command>`.

Huge thanks to GitHub user @itfranck! (again!)

### New vault parameters:

* Wsl
* OutputType

### New commands:

* Register-LastPassVault
* Unregister-LastPassVault
* Connect-LastPass
* Disconnect-LastPass
* Sync-LastPassVault
* Show-LastPassGridView

### Extras:

* Support for complex LastPass types (credit cards, bank accounts, etc)

## 0.1.0

Huge thanks to GitHub user @itfranck!

* Change the output format of `Get-SecretInfo`
* Handle shared folders better
* Support specifying your own path for lpass (also used to support WSL)

## 0.0.2

Have accounts return as PSCredentials.

## 0.0.1

Initial release.
'@

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
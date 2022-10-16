#
# Module manifest for module 'Parcel'
#
# Generated by: Matthew Kelly (Badgerati)
#
# Generated on: 23/09/2019
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Parcel.psm1'

    # Version number of this module.
    ModuleVersion = '0.2.0'

    # ID used to uniquely identify this module
    GUID = 'f9c84a02-ce1a-4512-be6e-18cb5bd9a803'

    # Author of this module
    Author = 'Matthew Kelly (Badgerati)'

    # Copyright statement for this module
    Copyright = 'Copyright (c) 2019 Matthew Kelly (Badgerati), licensed under the MIT License.'

    # Description of the functionality provided by this module
    Description = 'A Cross-Platform PowerShell package/module installation and provisioning tool.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this Module
    FunctionsToExport = @('Install-ParcelPackages', 'Uninstall-ParcelPackages')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('powershell', 'powershell-core', 'windows', 'unix', 'linux', 'PSEdition_Core',
                'PSEdition_Desktop', 'cross-platform', 'packages', 'software', 'modules', 'provision')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/Badgerati/Parcel/master/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Badgerati/Parcel'

        }
    }
}
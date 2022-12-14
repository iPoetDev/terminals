@{
RootModule = 'EnvironmentVariableItems.psm1'
ModuleVersion = '1.4.3'
GUID = 'f5ed8644-7f61-49cb-b4e5-fe24e5e85262'
Author = 'a1publishing\michaelf'
CompanyName = 'a1publishing.com'
Copyright = '(c) a1publishing.com'
Description = "Module with cmdlets to easily add or remove items from `'collection type`' Windows environment variables.  For example, adding `'C:\foo`' to `$env:Path."
PowerShellVersion = '3.0'
FunctionsToExport = @('Add-EnvironmentVariableItem', 'Get-EnvironmentVariableItems', 'Remove-EnvironmentVariableItem', 'Show-EnvironmentVariableItems')
AliasesToExport = @('aevi', 'gevis', 'revi', 'sevis')
PrivateData = @{
    PSData = @{
        Tags = @('environment', 'variable', 'EnvironmentVariable', 'Windows', 'path', 'scope', 'item', 'split')
        LicenseUri = 'https://github.com/a1publishing/Powershell_Module_EnvironmentVariableItems/blob/master/LICENSE'
        ProjectUri = 'https://github.com/a1publishing/Powershell_Module_EnvironmentVariableItems'
        ReleaseNotes = "1.4.3: Renamed parameter 'Value' to 'Item' in each cmdlet"
    } 
}
}

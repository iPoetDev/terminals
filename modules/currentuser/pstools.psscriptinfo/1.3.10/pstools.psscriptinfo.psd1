@{
  RootModule = 'pstools.psscriptinfo.psm1'
  ModuleVersion = '1.3.10'
  CompatiblePSEditions = @('Desktop','Core')
  GUID = 'f49be34c-e1a9-4e1e-9a98-ed2b72b78efa'
  Author = 'Hannes Palmquist'
  CompanyName = ''
  Copyright = '(c) 2021 Hannes Palmquist. All rights reserved.'
  Description = 'Tools for generating and updating psscriptinfo on scripts'
  RequiredModules = @()
  FunctionsToExport = @('Add-PSScriptInfo','Get-PSScriptInfo','Remove-PSScriptInfo','Update-PSScriptInfo')
  FileList = @('.\data\appicon.ico','.\data\banner.ps1','.\docs\pstools.psscriptinfo.md','.\en-US\Add-PSScriptInfo.md','.\en-US\Get-PSScriptInfo.md','.\en-US\pstools.psscriptinfo-help.xml','.\en-US\Remove-PSScriptInfo.md','.\en-US\Update-PSScriptInfo.md','.\include\module.utility.functions.ps1','.\private\Get-PSScriptInfoLegacy.ps1','.\private\Set-PSScriptInfo.ps1','.\public\Add-PSScriptInfo.ps1','.\public\Get-PSScriptInfo.ps1','.\public\Remove-PSScriptInfo.ps1','.\public\Update-PSScriptInfo.ps1','.\settings\config.json','.\LICENSE.txt','.\pstools.psscriptinfo.psd1','.\pstools.psscriptinfo.psm1')
  PrivateData = @{
    ModuleName = 'pstools.psscriptinfo.psm1'
    DateCreated = '2021-03-27'
    LastBuildDate = '2021-12-13'
    PSData = @{
      Tags = @('PSEdition_Desktop','PSEdition_Core','Windows','Linux','MacOS')
      ProjectUri = 'https://getps.dev/modules/pstools.psscriptinfo/quickstart'
      LicenseUri = 'https://github.com/hanpq/pstools.psscriptinfo/blob/main/LICENSE'
      ReleaseNotes = 'https://getps.dev/modules/pstools.psscriptinfo/changelog'
      IsPrerelease = 'False'
      IconUri = ''
      PreRelease = ''
      RequireLicenseAcceptance = $False
      ExternalModuleDependencies = @()
    }
  }
  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()
  DscResourcesToExport = @()
  ModuleList = @()
  RequiredAssemblies = @()
  ScriptsToProcess = @()
  TypesToProcess = @()
  FormatsToProcess = @()
  NestedModules = @()
  HelpInfoURI = ''
  DefaultCommandPrefix = ''
  PowerShellVersion = '5.1'
  PowerShellHostName = ''
  PowerShellHostVersion = ''
  DotNetFrameworkVersion = ''
  CLRVersion = ''
  ProcessorArchitecture = ''
}

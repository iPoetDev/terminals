This is a slightly modified version of the CredManStore example implementation to change the Credman prefix from __PS_ to ps:
https://github.com/PowerShell/SecretManagement/tree/master/ExtensionModules/CredManStore

# Quick Start
**This only works on Windows**
```powershell
Install-Module JustinGrote.SecretManagement.CredMan

Register-SecretVault -Name CredMan -Module 'JustinGrote.SecretManagement.CredMan'

Set-Secret -Vault CredMan -Name 'MyTestCredential' -Secret (Get-PSCredential)

Get-Secret -Vault CredMan
```
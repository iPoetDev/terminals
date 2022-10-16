# Display Profile in Use
# Start Console Logging 
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript | Out-File D:\Code\PowerShell.log -Append
Set-PSDebug -trace 0
Get-ExecutionPolicy -List
Get-PSSession
#Import All Commans into Global Session State, avail to all command 
Import-Module posh-sshell -Scope Global
Import-Module posh-git -Scope Global
Import-Module oh-my-posh -Scope Global
Import-Module PSReadLine -Scope Global
Import-Module npm-upgrade
Import-Module -Name Terminal-Icons -Scope Global

Set-Alias lst Get-ChildItem

#Import-Module XWrite
#Import All Commands into Local/Current Session State scope for Scripts/Scriptt Block scope -Scope Local

#Update Components
#Update-NPM
#scoop update --all #--quiet
#scoop cleanup -a
#choco upgrade all --only-upgrade-installed #--exitwhenrebootdetected

#Clean Up Apps
#scoop cleanup -a

#Import-Module PSScriptAnalyzer -Scope Local

# Display Profile in Use
$PROFILE.CurrentUserCurrentHost

#(Get-PSReadLineOption | select -ExpandProperty HistorySavePath -HistorySaveStyle SaveIncrementally) 

#Start the SSH Agent 
# Enable a POSHProfile Vault
# Check if not disabled
Get-Service -Name ssh-agent | Select-Object Status, Name, StartType
# Start Up agent to Automatic | Manual and in the current Scope and Noisy | Quiet
Start-SshAgent -StartupType "Automatic" -Scope "User" #-Quiet
#Add Keys: Default is .ssh\id_rsa
#Add-SshKey
#Add-SshKey C:User\charl\.ssh\.github\id_ecdsa_github
#Add-SshKey ~\.ssh\.gitlab\id_ed25519_gitlab
#Add-SshKey C:\User\charl\.ssh\.bitbuck\id_ecdsa_bitbuck

# Add the Keys
# 1. Add Git Key from a Vault Secret on a) OnLoad, [b) Check if it exists, else add key and update new key to vault] and load  
# 2. Add GitLab Key from Vault Secret and .... (above)
# 3. Add BitBucket Key from Vault Secret
# 4.. && 5. Azure and Aws
# Add above to a Script
# Add above to a Module and Import a Function on Load

# Ensure TLS 12 is mandatory for each Session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Theme 

# External Customisations
Set-Location $env:codespace
# oh-my-posh init pwsh | Invoke-Expression.
#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/pixelrobots.omp.json" | Invoke-Expression
(@(& 'oh-my-posh.exe' init pwsh --config='D:\.Tools\.scoop\apps\oh-my-posh\current\themes\ohmyposhv3-v2.json' --print) -join "`n") | Invoke-Expression

# Add this into your profile AFTER posh-git has been loaded and the SSH agent

# Write to Process Registry  #MarkEmbling
#[void][Environment]::SetEnvironmentVariable("SSH_AGENT_PID", [Environment]::GetEnvironmentVariable("SSH_AGENT_PID"), [EnvironmentVariableTarget]::Process)
#[void][Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", [Environment]::GetEnvironmentVariable("SSH_AUTH_SOCK"), [EnvironmentVariableTarget]::Process)

# Write to User Registry  
#[void][Environment]::SetEnvironmentVariable("SSH_AGENT_PID", [Environment]::GetEnvironmentVariable("SSH_AGENT_PID"), [EnvironmentVariableTarget]::User)
#[void][Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", [Environment]::GetEnvironmentVariable("SSH_AUTH_SOCK"), [EnvironmentVariableTarget]::User)

# It may make it a little slower (as apparently writing to the user environment
# is slow), but will mean the SSH agent is visible to other processes.
Enable-XWrite -ForAll -Format "%source%: %caller%: %date%: %time%: "
Enable-XWrite -ForWarning #-ForHost -ForDebug -ForVerbose -ForInformation 

# Command Memory
#Get-Command -Module PowerSSH,WinSSH

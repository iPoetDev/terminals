# SSH Agent Functions
# Mark Embling (http://www.markembling.info/)
#
# How to use:
# - Place this file into %HOME%\.ssh\ (or location of choice)
# - Import into your profile.ps1:
#   . (Resolve-Path ~/.ssh/SSH-Agent-Functions.ps1)
# - Enjoy

# Retrieve the current SSH agent PID (or zero). Can be used to determine if there
# is an agent already starting.

<#
 .Synopsis
  Starts and manages the ssh-agent.

 .Description
  Starts and manages the ssh-agent. This set of functions supports if the SSH Agent is running in the background, as it stores the private key and passphrase one time, once the ssh-agent is started.

    Once the ssh-agent has started

 .NOTES
    # Source: https://markembling.info/2009/09/ssh-agent-in-powershell

    #SSH Agent Functions
    # Mark Embling (http://www.markembling.info/)

    # How to use:
    # - Place this file into %USERPROFILE%\Documents\WindowsPowershell (or location of choice)

    # - Import into your profile.ps1:
    #   e.g. ". (Resolve-Path ~/Documents/WindowsPowershell/ssh-agent-utils.ps1)" [without quotes]
    
    # Note: ensure you have ssh and ssh-agent available on your path, from Git's Unix tools or Cygwin.

    # Retrieve the current SSH agent PID (or zero). Can be used to determine if there is an agent already starting.


 .Example
   # Returns the process ID of the running agent, or zero if there is not one currently running.
   Get-SHHAgent

 .Example
   # Starts an ssh-agent, gathers the feedback info and removes env vars, returning 0 for no agent. 
   Start-SSHAgent

 .Example
   # Stops the process if there is one and unsets the variables.
   Stop-SSHAgent

 .Example
   # Instructs the agent to add the given key to itself. This will cause you to be prompted for the passphrase.
   Add-SSHAgent
 
#>

# Hard Coded Values
# TODO 
<# 

TODO Use Exlicit Defined Parameters: $CommonParams, and remove splatted @args

Use a Dedicated SSH_PATH Environmental Variable for C:\Users\char\.ssh for User Context, Not Machine or Process
Or Use a commonparams object and remove a potential issues/attacker for locating Private key storage on ENVVar

$commonParams = @{
    ssh_path = C:\Users\charl\.ssh\.github\
    GitHubKey = "id_ecdsa_github"
    GitLabKey = "id_ed25519_gitlab"
    GitLabKey = "id_ed25519_gitlab"
    BitBuckKey = "id_ecdsa_bitbuck"
}

#TODO: [SECOPS-4] Build a ; separated Enviromental Variable of all repoHosts in use in system and then add them into common variable. - Configuration.

Function RetrieveRepo()
{
$repoConfig = [Environment]::GetEnvironmentVariable("REPO_IN_USE", "User")

foreach ($repoEnv in $reporConfig)
{
    if ($repoEnv.Count -eq = 0)
    {
        Write-Host: "You need to configure User Environmental Variables for $REPO_IN_USE and adding ";" after each entry."
        Write-Host: "For GitHub.com, enter github /n
                     For GitLab.com, enter gitlab /n
                     For BitBucket.org, enter bitbuck /n
                     For Azure, enter azure
                     For Aws, enter aws"
    }
    else 
    {
        $allRepoHosts = @() // How do you initiate and build a commonParams dyanamicall, or use @Args and Splat
        $allRepoHosts = $repoEnv
    }    
    Write-Host $allRepoHosts
}

}//end Function and make $allRepoHosts a global variable in function.

$allRepoHosts = @('github','gitlab',`bitbuck`,`azure`,`aws`,) # Have this dyanamically populated

#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_switch?view=powershell-7.2

#Switch use regex 
#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions?view=powershell-7.2

foreach ($repo in $allRepoHosts)
{

    # Switch and text if  repo -eq (equals) [string]repoHost
    switch ($repo) -Exact
    {
       "github" { statement }
       "gitlab" { statement }
       "bitbuck" { statement }
       "bitbucket" { statement } # {$_.(property) -eq "bitbucket", $._(property) -eq "bitbuck"}, 
       "azure" { statement }
       "aws" { statement }
       "default" { statement }
       Default {error/none ||break}

    }
}

function Build_File_Path()
{
    commonParams = @{
    ssh_path = C:\Users\charl\.ssh\
    prefix = "id"
    separator = "_" 
    }

$pk_algorithms = @('rsa','ecdsa','ed25519','dsa')

 foreach ($aglorithm -eq $pk_algorithms)
 {
     Build a string to the path to the location of the identity file
     switch (test allRepoHost)

 }
  Output a filepath name
  Use Powrshell filepath commands to validate file
}
}
     
}

#>
$GitHubKey = C:\Users\charl\.ssh\.github\id_ecdsa_github
$GitLabKey = C:\Users\charl\.ssh\.gitlab\id_ecdsa_gitlab
$BitBuckKey = C:\Users\charl\.ssh\.bitbuck\id_ecdsa_bitbuck

# TODO Describe the function Get-SSH-AGENT

function Get-SSHAgent() {
    $agentPid = [Environment]::GetEnvironmentVariable("SSH_AGENT_PID",  "User")
    if ([int]$agentPid -eq 0) {
        $agentPid = [Environment]::GetEnvironmentVariable("SSH_AGENT_PID", "Process")
    }
    
    if ([int]$agentPid -eq 0) {
        0
    } else {
        # Make sure the process is actually running
        $process = Get-Process -Id $agentPid -ErrorAction SilentlyContinue
		
        if(($process -eq $null) -or ($process.ProcessName -ne "ssh-agent")) {
            # It is not running (this is an error). Remove env vars and return 0 for no agent.
            [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "Process")
            [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "User")
            [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "Process")
            [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "User")
            0
        } else {
            # It is running. Return the PID.
            $agentPid
        }
    }
}

# Start the SSH agent.
# TODO Describe the function Get-SSH-AGENT
function Start-SSHAgent() {
    # Start the agent and gather its feedback info
    [string]$output = ssh-agent

    if ($null -eq $output) {

        $agentPid = 0

    } else { 
        #out-host $output    
        $lines = $output.Split(";")
        $agentPid = 0
    
        foreach ($line in $lines) {
            #out-host $line
            if (([string]$line).Trim() -match "(.+)=(.*)") {
                # Set environment variables for user and current process.            
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "User")
            
                if ($matches[1] -eq "SSH_AGENT_PID") {
                    $agentPid = $matches[2]
                    #out-host = $agentPid
                }
            }
	    }
    } #endElse
    # Show the agent's PID as expected.
    Write-Host "SSH agent PID:", $agentPid
}

# Stop a running SSH agent
function Stop-SSHAgent() {
    [int]$agentPid = Get-SshAgent
    if ([int]$agentPid -gt 0) {
        # Stop agent process
        $proc = Get-Process -Id $agentPid
        if ($proc -ne $null) {
            Stop-Process $agentPid
        }
        
        # Remove all enviroment variables
        [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "Process")
        [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "User")
        [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "Process")
        [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "User")
    }
}

# Add a key to the SSH agent
function Add-SSHKey() {
    # - ArgumentList: Array of Arguements/Param Values 
    #   TODO: Import-Module https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/import-module?view=powershell-7.2#-argumentlist
        # Splatting with arrays: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.2#splatting-with-arrays
    if ($args.Count -eq 0) {
        # Add the default key (~/id_rsa)
        Write-Host "No Private Keys available to load."    
    } else {
        foreach ($value in $args) {
            ssh-add $value
        }
    }
}


# Start the agent if not already running; provide feedback

function Start-AddKeys()
{
    $local:agent = Get-SshAgent

    if ($agent -eq 0) {
        Write-Host "Executing SSH agent..."
        Start-SshAgent		# Start agent
        Write-Host "Adding Keys..."
        Add-SshKey			# Add my default key

        Write-Host "SSH agent is initalising (PID $agent) /n
                    Logging ssh access for each repo host for the first time"
        ssh -T git@bitbucket.org -E C:\Users\charl\.ssh\.bitbuck\bit-ssh.log
        ssh -T git@gitlab.com -E C:\Users\charl\.ssh\.gitlab\lab-ssh.log
        ssh -T git@github.com -E C:\Users\charl\.ssh\.bitbuck\hub-ssh.log
    } else {
        Write-Host "SSH agent is running (PID $agent) /n
                    Logging ssh access for each repo"
        ssh -T git@bitbucket.org -E C:\Users\charl\.ssh\.bitbuck\bit-ssh.log
        ssh -T git@gitlab.com -E C:\Users\charl\.ssh\.gitlab\lab-ssh.log
        ssh -T git@github.com -E C:\Users\charl\.ssh\.bitbuck\hub-ssh.log
    }
}
<#
  1. Configure NewAliases for SSH-Agent-Functions
  2. Export Aliass to a File?/
  3. Import Alises in current session for Powershell
#>

#Set the Modules Aliases, Export them and load them into Powershell
# Get-Help Alias for Alias provider
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_aliases?view=powershell-7.2

function Set-Aliases()
{
    #Set-Location Alias:
    New-Alias -Name fetchagent -Vale Get-SshAgent
    New-Alias -Name startagent -Vale Start-ShhAgent
    New-Alias -Name stopagent -Value Stop-ShhAgent
    New-Alias -Name addsshkey -Value Add-ShhKey

    #Export-Alias fetchagent,startagent,stopagent,addsshkey
    Import-Alias fetchagent,startagent,stopagent,addsshkey

    #Get-Alias -Name fetchagent | Format-List -Property *
    #Get-Alias -Name startagent | Format-List -Property *
    #Get-Alias -Name stopagent | Format-List -Property *
    #Get-Alias -Name addsshkey | Format-List -Property *
    #Get-Alias -Name dir | Format-List -Property *

    #Get-ChildItem -Path Alias:
}
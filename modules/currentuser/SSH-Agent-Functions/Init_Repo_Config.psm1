# Initialse Repository Configuration
# Charles Fowler
# Type: Module
Import-Module . (Resolve-Path -Path D:\OneDrive\Documents\PowerShell\Modules\SSH-Agent-Function.psm1)


<#
 .Synopsis
  Initalised and sets the repos in use, in case of multiple providers or accounts in use. Used as a precurors script/funcional dependency to initialising SSH-Agent-Functions. Removes need to hard code variable file paths and file names of the Private identity keys in scripts

 .Description
  Initalised and sets the repos in use, in case of multiple providers or accounts in use. Used as a precurors script/funcional dependency to initialising SSH-Agent-Functions. Removes need to hard code variable file paths and file names of the Private identity keys in scripts

 .NOTES


    #SSH Agent Functions
    # Mark Embling (http://www.markembling.info/)

 .Example
   # 

 .Example
   # 

 .Example
   # 

 .Example
   # 
#>

<# 
 TODO Use Exlicit Defined Parameters: $CommonParams, and remove splatted @args

#Use a Dedicated SSH_PATH Environmental Variable for C:\Users\char\.ssh for User Context, Not Machine or Process
Or Use a commonparams object and remove a potential issues/attacker for locating Private key storage on ENVVar
#>
# https://4sysops.com/archives/validating-file-and-folder-paths-in-powershell-parameters/
    #[ValidateScript({
    #        if( -Not ($_ | Test-Path) ){
    #            throw "Deafult User SSH File or folder does not exist"
    #        }
    #        return $true
    #    })]
    #[System.IO.FileInfo]$local:default_path = $Home\.ssh\
    

#CmdletBinding()]  # Add cmdlet features.

 param {

     ShhHash = @{
    #[Parameter(Mandatory=$True)]
    #$local:default_path = $Home\.ssh\
    #[ValidateSet("$Home\.ssh\","C:\Users\'$User\.ssh",ErrorMessage="Value '{0}' is invalid. Try the path to users ssh: '{1}'")]
    [string]$SshPath = $Home\.ssh\
    #$local:default_path = $Home\.ssh\
    #[Parameter(Mandatory=$False)]
 }

# Build a HashTable as a look up table, ref: splating, 

# SshParams = [pscustomobjet]@{} or PS:\> [pscustomobject]$person
# HashTabels https://powershellexplained.com/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/

$ShhHash = @{
    #[Parameter(Mandatory=$True)]
    #$local:default_path = $Home\.ssh\
    #[ValidateSet("$Home\.ssh\","C:\Users\'$User\.ssh",ErrorMessage="Value '{0}' is invalid. Try the path to users ssh: '{1}'")]
    $SshPath = $Home\.ssh\
    #[Parameter(Mandatory=$False)]

    GitHub = @{ 
        Host = "github"
        defaultHostname = ""
        subFolder = ".github\"
        filePrefix = "id"
        fileSpacer = "_"
        pkAlgorithms = @{
            ECDSA = "ecdsa"
            ED25519 = "ed"
            RSA = "rsa"
            DSA = "dsa"
            }
        Hostn = @{
            COM = "github.com"
            IO = "github.io"
        }
    }
    
    #eg GitLab.HostN.IO = "gitlab.io"
    GitLab = @{ 
        Host = "gitlab"
        defaultHostname = ""
        subFolder = ".gitlab\"
        filePrefix = "id"
        fileSpacer = "_"
        pkAlgorithms = @{
            ED25519 = "ed25519"
            ECDSA = "ecdsa"
            RSA = "rsa"
            DSA = "dsa"
            }
        hasPrefPk = "true"
        prefPK = "ed25519"
        HostN = @{
            COM = "gitlab.com"
            IO = "gitlab.io"
            ORG = ""
        }
    }

    #eg BitBucket.pkAlgorithm.RSA = "rsa"
    BitBucket = @{ 
        Host = "bitbucket"
        defaultHostname = ""
        subFolder = ".gitlab\"
        filePrefix = "id"
        fileSpacer = "_"
        pkAlgorithm = @{
            ED25519 = "ed25519"
            ECDSA = "ecdsa"
            RSA = "rsa"
            DSA = "dsa"
            }
        hasPrefPk = true
        prefPK = "ecdsa"
        HostNames = @{
            COM = ""
            IO = ""
            ORG = "bitbucket.org"

        }
    }

    #eg Azure.prefPK = "edcsa" 
    Azure = @{ 
        Host = "azure"
        defaultHostname = "azure.com"
        subFolder = ".azure\"
        filePrefix = "id"
        fileSpacer = "_"
        pkAlgorithm = @{
            ED25519 = "ed25519"
            ECDSA = "ecdsa"
            RSA = "rsa"
            DSA = "dsa"
            }
        hasPrefPk = true
        prefPK = "ecdsa"
        HostNames = @{
            COM = "azure.com"
            IO = ""
            ORG = ""
        }
    } #End of Azure

     #eg Azure.prefPK = "edcsa" 
    Aws = @{ 
        Host = "aws"
        defaultHostname = "aws.com"
        subFolder = ".aws\"
        filePrefix = "id"
        fileSpacer = "_"
        pkAlgorithm = @{
            ED25519 = "ed25519"
            ECDSA = "ecdsa"
            RSA = "rsa"
            DSA = "dsa"
            }
        hasPrefPk = true
        prefPK = "ecdsa"
        HostNames = @{
            COM = "aws.com"
            IO = ""
            ORG = ""
        }
    } #End of AWS
} # End SshHash

function Build-FilePaths()
{
       $filepath = System.Text.StringBuilder::new()
       $filename = System.Text.StringBuilder::new()
       $path = System.Text.StringBuilder::new()

    switch ($SshHash) -Exact {

        SshHash.GitHub.Host = "github" {
            #Build the FilePaths and SubFolder
            [void]$filepath.Append($SshHash.SshPath) 
            [void]$filepath.Append($SshHash.Github.subFolder)
            $filepath.ToString()    
            #Build the FileName
            [void]$filename.Append($SshHash.Github.filePrefix)
            [void]$filename.Append($SshHash.Github.fileSpacer)
            [void]$filename.Append($Sshhash.Github.pkAlgorium.EDCSA)
            [void]$filename.Append($SshHash.Github.fileSpacer)
            [void]$filename.Append($SshHash.Github.host)
            $filepath.ToString()
            [void]$path.Append($filepath)
            [void]$path.Append($filenanme)
            $path.ToString()
            

        }
        SshHash.GitLab.Host = "gitlab" {


        }
        SshHash.Bitbucket.Host = "bitbucket" {


        }
        SshHash.GitLab.Host = "azure" {


        }
        SshHash.Aws.Host = "aws" {


        }
        default {}
    }
}

$AcceptedIdFileNames = @{

    #File name conventions
    #GitHub Accepted PK Algorithms          Preferential Order
    [string]GitHubECDSA = "id_ecdsa_github"        #1
    [string]GitHubED25519 = "id_ed25519_github"    #2
    [string]GitHubRSA = "id_rsa_github"            #3 SSH default
    [string]GitHubDSA = "id_dsa_github"            #4 Likely deprecated

    [string]GitLabEd25119 = "id_ed25519_gitlab"    #1 
    [string]GitLabECDSA = "id_ecdsa_gitlab"        #2
    [string]GitLabRSA = "id_rsa_gitlab"            #3 SSH default

    [string]BitBuckECDSA = "id_ecdsa_bitbuck"      #1
    [string]BitBuckRSA = "id_rsa_bitbuck"          #2 SSH default
    #BitBuckKey = "id_ed25519_bitbuck"             #3 Not Supported

    [string]AzureECDSA = "id_ecdsa_azure"          #1
    [string]AzureRSA = "id_rsa_azure"              #2 SSH default

    [string]AwsECDSA = "id_ecdsa_aws"              #1
    [string]AwsRSA = "id_rsa_aws"                  #2 SSH default

    WhatIf = $true
}






        $gitHubPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ".gitlab\"
        $gitLabPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ".gitlab\"
        $bitBuckPath =Join-Path -Name ShhHash['SshPath'] -ChildPath ".bitbuck\"
        $azurePath =Join-Path -Name ShhHash['SshPath'] -ChildPath ".azure\"
        $awsPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ".aws\"

        $gitHubPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Github']
        $gitLabPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Gitlab']
        $bitBuckPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_BitBuck']
        $azurePath = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Azure']
        $awsPath = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Aws']

        $sshSubFolders = @{$gitHubPath,$gitLabPath,$bitBuckPath,$azurePath,$awsPath}

        $gitHubIdent = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Github'] -AdditionalChildPath ShhHash['GitHubECDSA']
        $gitLabIdent = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Gitlab'] -AdditionalChildPath ShhHash['GitLabEd25119']
        $bitBuckIdent = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_BitBuck'] -AdditionalChildPath ShhHash['GitLabECDSA']
        $azureIdent = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Azure'] -AdditionalChildPath ShhHash['AzureECDSA']
        $awsIdent = Join-Path -Name ShhHash['SshPath'] -ChildPath ShhHash['sf_Aws'] -AdditionalChildPath ShhHash['AwsECDSA']

        $AcceptedIdents = @{$gitHubIdent,$gitLabIdent,$bitBuckIdent,$azureIdent,$awsIdent}

        foreach ($ident in $AcceptedIdent)
        {
           Add-SSH()


        }

    }


#TODO: [SECOPS-4] Build a ; separated Enviromental Variable of all repoHosts in use in system and then add them into common variable. - Configuration.

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes?view=powershell-7.2
# $Global:RepoHosts = ""
# $Local:RepoHosts = ""
New-Variable -Name RepoHosts -Option Public -Description "Fixed Shortcodes for Configured Repos in ENV"
$Local:RepoHosts = ""

Function GetRepoEnvironment()
{

   #set an alias for this function

   # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.2
   Clear-Variable -Name repoConfig
   if ($repoConfig -eq $null)
   {
        [string]$repoConfig = [Environment]::GetEnvironmentVariable("REPO_IN_USE", "User")
   }

    foreach ($repoEnv in $reporConfig)
    {
        if ($repoEnv.Count -eq = 0)
        {
        Write-Host: "You need to configure User Environmental Variables for $REPO_IN_USE /n 
                     and add ";" after each entry in your systems environment variables to create an array of variables."
        Write-Host: "For GitHub.com, enter github /n
                     For GitLab.com, enter gitlab /n
                     For BitBucket.org, enter bitbuck /n
                     For Azure, enter azure /n
                     For Aws, enter aws"
        }
        else 
        {
            $allRepoHosts = @() # How do you initiate and build a commonParams dyanamicall, or use @Args and Splat
            $allRepoHosts = $repoEnv
        }    
    
        Write-Host $allRepoHosts.
}

} #make $allRepoHosts a global variable in function.

$allRepoHosts = @('github','gitlab','bitbuck','azure','aws',) # Have this dyanamically populated

#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_switch?view=powershell-7.2

#Switch use regex 
#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions?view=powershell-7.2
function InitRepo()

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

function GetSshPath()
{
    commonParams = @{
    ssh_path = "C:\Users\charl\.ssh\"
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

function Set-Aliases(

    New-Alias -Name repoenv -Vale GetRepoEnvironment
    New-Alias -Name irepo -Vale GetRepoEnvironment
    New-Alias -Name gsshpath -Value GetSshPath

    Export-Alias repoenv,irepo,gsshpath
    Import-Alias repoenv,irepo,gsshpath

)
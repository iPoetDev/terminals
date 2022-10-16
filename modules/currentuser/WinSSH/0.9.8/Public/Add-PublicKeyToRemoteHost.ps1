<#
    .SYNOPSIS
        This function connects to a Remote Host via ssh and adds the specified User/Client SSH Public Key to
        the ~/.ssh/authorized_keys file on that Remote Host. As long as you can connect to the Remote Host via
        ssh, this function will work with both Windows and Linux targets.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER PublicKeyPath
        This parameter is MANDATORY.

        This parameter takes a string that represents the full path to the SSH User/Client Public Key that you
        would like to add to the Remote Host's ~/.ssh/authorized_keys file.

    .PARAMETER RemoteHost
        This parameter is MANDATORY.

        This parameter takes a string that represents an IP Address or DNS-Resolvable name to a remote host
        running an sshd server.

    .PARAMETER RemoteHostUserName
        This parameter is MANDATORY,

        This parameter takes a string that represents the User Name you would like to use to ssh
        into the Remote Host.

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> $SplatParams = @{
            PublicKeyPath       = "$HOME\.ssh\id_rsa.pub"
            RemoteHost          = "Ubuntu18.zero.lab"
            RemoteHostUserName  = "zero\zeroadmin"
        }
        PS C:\Users\zeroadmin> Add-PublicKeyToRemoteHost @SplatParams
#>
function Add-PublicKeyToRemoteHost {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$PublicKeyPath,

        [Parameter(Mandatory=$True)]
        [string]$RemoteHost,

        [Parameter(Mandatory=$True)]
        [string]$RemoteHostUserName
    )

    ##### BEGIN Variable/Parameter Transforms and PreRun Prep #####

    if (!$(Test-Path $PublicKeyPath)) {
        Write-Error "The path $PublicKeyPath was not found! Halting!"
        $global:FunctionResult = "1"
        return
    }

    try {
        $RemoteHostNetworkInfo = ResolveHost -HostNameOrIP $RemoteHost -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to resolve $RemoteHost! Halting!"
        $global:FunctionResult = "1"
        return
    }    
    
    if (![bool]$(Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Error "Unable to find ssh.exe! Halting!"
        $global:FunctionResult = "1"
        return
    }

    $PubKeyContent = Get-Content $PublicKeyPath

    ##### END Variable/Parameter Transforms and PreRun Prep #####


    ##### BEGIN Main Body #####

    if ($RemoteHostNetworkInfo.FQDN) {
        $RemoteHostLocation = $RemoteHostNetworkInfo.FQDN
    }
    elseif ($RemoteHostNetworkInfo.HostName) {
        $RemoteHostLocation = $RemoteHostNetworkInfo.HostName
    }
    elseif ($RemoteHostNetworkInfo.IPAddressList[0]) {
        $RemoteHostLocation = $RemoteHostNetworkInfo.IPAddressList[0]
    }

    #ssh -t $RemoteHostUserName@$RemoteHostLocation "echo '$PubKeyContent' >> ~/.ssh/authorized_keys"
    if ($RemoteHostUserName -match "\\|@") {
        if ($RemoteHostUserName -match "\\") {
            $DomainPrefix = $($RemoteHostUserName -split "\\")[0]
        }
        if ($RemoteHostUserName -match "@") {
            $DomainPrefix = $($RemoteHostUserName -split "\\")[-1]
        }
    }

    if (!$DomainPrefix) {
        #ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes" -t $RemoteHostUserName@$RemoteHostLocation "echo '$PubKeyContent' >> ~/.ssh/authorized_keys"
        ssh -o "StrictHostKeyChecking=no" -t $RemoteHostUserName@$RemoteHostLocation "echo '$PubKeyContent' >> ~/.ssh/authorized_keys"
    }
    else {
        #ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes" -t $RemoteHostUserName@$DomainPrefix@$RemoteHostLocation "echo '$PubKeyContent' >> ~/.ssh/authorized_keys"
        ssh -o "StrictHostKeyChecking=no" -t $RemoteHostUserName@$DomainPrefix@$RemoteHostLocation "echo '$PubKeyContent' >> ~/.ssh/authorized_keys"
    }

    ##### END Main Body #####
}

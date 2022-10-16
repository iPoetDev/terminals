<#
    .SYNOPSIS
        This function gets the SSL Certificate at the specified IP Address / Port
        and returns an System.Security.Cryptography.X509Certificates.X509Certificate2 object.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES

    .PARAMETER IPAddress
        This parameter is MANDATORY.

        This parameter takes a string that represents an IP Address.

    .PARAMETER Port
        This parameter is MANDATORY.

        This parameter takes an integer that represents a Port Number (443, 636, etc).

    .EXAMPLE
        # In the below example, 172.217.15.110 happens to be a google.com IP Address

        PS C:\Users\zeroadmin> Check-Cert -IPAddress 172.217.15.110 -Port 443

        Thumbprint                                Subject
        ----------                                -------
        8FBB134B2216D6C71CF4E4431ABD82182922AC7C  CN=*.google.com, O=Google Inc, L=Mountain View, S=California, C=US
        
#>
function Check-Cert {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$IPAddress,
        
        [Parameter(Mandatory=$True)]
        [int]$Port
    )
    
    try {
        $TcpSocket = New-Object Net.Sockets.TcpClient($IPAddress,$Port)
        $tcpstream = $TcpSocket.GetStream()
        $Callback = {param($sender,$cert,$chain,$errors) return $true}
        $SSLStream = New-Object -TypeName System.Net.Security.SSLStream -ArgumentList @($tcpstream, $True, $Callback)

        try {
            $SSLStream.AuthenticateAsClient($IPAddress)
            $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SSLStream.RemoteCertificate)
        }
        finally {
            $SSLStream.Dispose()
        }
    }
    finally {
        $TCPSocket.Dispose()
    }
    
    $Certificate
}

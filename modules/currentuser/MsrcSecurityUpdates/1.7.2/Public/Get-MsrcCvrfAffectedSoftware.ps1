Function Get-MsrcCvrfAffectedSoftware {
<#
    .SYNOPSIS
        Get details of products affected by a CVRF document

    .DESCRIPTION
       CVRF documents next products into several places, including:
       -Vulnerabilities
       -Threats
       -Remediations
       -Product Tree
       This function gathers the details for each product identified in a CVRF document.

    .PARAMETER Vulnerability

    .PARAMETER ProductTree
    
    .EXAMPLE
        Get-MsrcCvrfDocument -ID 2016-Nov | Get-MsrcCvrfAffectedSoftware
   
        Get product details from a CVRF document using the pipeline.
   
    .EXAMPLE
        $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
        Get-MsrcCvrfAffectedSoftware -Vulnerability $cvrfDocument.Vulnerability -ProductTree $cvrfDocument.ProductTree

        Get product details from a CVRF document using a variable and parameters
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Vulnerability,

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $ProductTree
)
Begin {}
Process {
    $Vulnerability | ForEach-Object {

        $v = $_

        $v.ProductStatuses.ProductID | ForEach-Object {
            $id = $_
            
            [PSCustomObject] @{
                FullProductName = $(
                    $ProductTree.FullProductName  | 
                    Where-Object { $_.ProductID -eq $id} | 
                    Select-Object -ExpandProperty Value
                ) ;
                KBArticle = $v.Remediations | where-Object {$_.ProductID -contains $id} | Where-Object {$_.Type -eq 2} | ForEach-Object {
                                [PSCustomObject]@{
                                    ID = $_.Description.Value;
                                    URL= $_.URL;
                                    SubType = $_.SubType
                                }
                            };
               CVE = $v.CVE
                Severity = $(
                    (
                        $v.Threats | 
                        Where-Object {$_.Type -eq 3 } | 
                        Where-Object { $_.ProductID -contains $id }
                    ).Description.Value
                ) ;
                Impact = $(
                    (
                        $v.Threats | 
                        Where-Object {$_.Type -eq 0 } | 
                        Where-Object { $_.ProductID -contains $id }
                    ).Description.Value
                )
                RestartRequired = $(
                    (
                        $v.Remediations | 
                        Where-Object { $_.ProductID -contains $id }
                    ).RestartRequired.Value | ForEach-Object {
                        "$($_)"
                    }
                ) ;
                Supercedence = $(
                    (
                        $v.Remediations | 
                        Where-Object { $_.ProductID -contains $id }
                    ).Supercedence | ForEach-Object {
                        "$($_)"
                    }
                ) ;
                CvssScoreSet = $( [PSCustomObject] @{ 
                        base=    ($v.CVSSScoreSets | Where-Object { $_.ProductID -contains $id } ).BaseScore;
                        temporal=($v.CVSSScoreSets | Where-Object { $_.ProductID -contains $id } ).TemporalScore;;
                        vector=  ($v.CVSSScoreSets | Where-Object { $_.ProductID -contains $id } ).Vector;
                    }
                ) ;
            }
        }
    }
}
End {}
}
# SIG # Begin signature block
# MIIkYQYJKoZIhvcNAQcCoIIkUjCCJE4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmfmpISKSw5ejv
# QlI8PG3H9LlvF0qMNc0O4Y0/5m+QKqCCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
# pFcaX8o+AAAAAACOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTYxMTE3MjIwOTIxWhcNMTgwMjE3MjIwOTIxWjCBgzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA0IfUQit+ndnGetSiw+MVktJTnZUXyVI2+lS/qxCv
# 6cnnzCZTw8Jzv23WAOUA3OlqZzQw9hYXtAGllXyLuaQs5os7efYjDHmP81LfQAEc
# wsYDnetZz3Pp2HE5m/DOJVkt0slbCu9+1jIOXXQSBOyeBFOmawJn+E1Zi3fgKyHg
# 78CkRRLPA3sDxjnD1CLcVVx3Qv+csuVVZ2i6LXZqf2ZTR9VHCsw43o17lxl9gtAm
# +KWO5aHwXmQQ5PnrJ8by4AjQDfJnwNjyL/uJ2hX5rg8+AJcH0Qs+cNR3q3J4QZgH
# uBfMorFf7L3zUGej15Tw0otVj1OmlZPmsmbPyTdo5GPHzwIDAQABo4IBgDCCAXww
# HwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKvI1u2y
# FdKqjvHM7Ww490VK0Iq7MFIGA1UdEQRLMEmkRzBFMQ0wCwYDVQQLEwRNT1BSMTQw
# MgYDVQQFEysyMzAwMTIrYjA1MGM2ZTctNzY0MS00NDFmLWJjNGEtNDM0ODFlNDE1
# ZDA4MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0Nv
# ZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsG
# AQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01p
# Y0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAgEARIkCrGlT88S2u9SMYFPnymyoSWlmvqWaQZk62J3SVwJR
# avq/m5bbpiZ9CVbo3O0ldXqlR1KoHksWU/PuD5rDBJUpwYKEpFYx/KCKkZW1v1rO
# qQEfZEah5srx13R7v5IIUV58MwJeUTub5dguXwJMCZwaQ9px7eTZ56LadCwXreUM
# tRj1VAnUvhxzzSB7pPrI29jbOq76kMWjvZVlrkYtVylY1pLwbNpj8Y8zon44dl7d
# 8zXtrJo7YoHQThl8SHywC484zC281TllqZXBA+KSybmr0lcKqtxSCy5WJ6PimJdX
# jrypWW4kko6C4glzgtk1g8yff9EEjoi44pqDWLDUmuYx+pRHjn2m4k5589jTajMW
# UHDxQruYCen/zJVVWwi/klKoCMTx6PH/QNf5mjad/bqQhdJVPlCtRh/vJQy4njpI
# BGPveJiiXQMNAtjcIKvmVrXe7xZmw9dVgh5PgnjJnlQaEGC3F6tAE5GusBnBmjOd
# 7jJyzWXMT0aYLQ9RYB58+/7b6Ad5B/ehMzj+CZrbj3u2Or2FhrjMvH0BMLd7Hald
# G73MTRf3bkcz1UDfasouUbi1uc/DBNM75ePpEIzrp7repC4zaikvFErqHsEiODUF
# he/CBAANa8HYlhRIFa9+UrC4YMRStUqCt4UqAEkqJoMnWkHevdVmSbwLnHhwCbww
# ggd6MIIFYqADAgECAgphDpDSAAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5
# MDlaFw0yNjA3MDgyMTA5MDlaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIw
# MTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQ
# TTS68rZYIZ9CGypr6VpQqrgGOBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULT
# iQ15ZId+lGAkbK+eSZzpaF7S35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYS
# L+erCFDPs0S3XdjELgN1q2jzy23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494H
# DdVceaVJKecNvqATd76UPe/74ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZ
# PrGMXeiJT4Qa8qEvWeSQOy2uM1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5
# bmR/U7qcD60ZI4TL9LoDho33X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGS
# rhwjp6lm7GEfauEoSZ1fiOIlXdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADh
# vKwCgl/bwBWzvRvUVUvnOaEP6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON
# 7E1JMKerjt/sW5+v/N2wZuLBl4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xc
# v3coKPHtbcMojyyPQDdPweGFRInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqw
# iBfenk70lrC8RqBsmNLg1oiMCwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFEhuZOVQBdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
# BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGC
# Ny4DMIGDMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2RvY3MvcHJpbWFyeWNwcy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcA
# YQBsAF8AcABvAGwAaQBjAHkAXwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZI
# hvcNAQELBQADggIBAGfyhqWY4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4s
# PvjDctFtg/6+P+gKyju/R6mj82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKL
# UtCw/WvjPgcuKZvmPRul1LUdd5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7
# pKkFDJvtaPpoLpWgKj8qa1hJYx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft
# 0N3zDq+ZKJeYTQ49C/IIidYfwzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4
# MnEnGn+x9Cf43iw6IGmYslmJaG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxv
# FX1Fp3blQCplo8NdUmKGwx1jNpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG
# 0QaxdR8UvmFhtfDcxhsEvt9Bxw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf
# 0AApxbGbpT9Fdx41xtKiop96eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkY
# S//WsyNodeav+vyL6wuA6mk7r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrv
# QQqxP/uozKRdwaGIm1dxVk5IRcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIW
# JDCCFiACAQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAA
# AI6HkaRXGl/KPgAAAAAAjjANBglghkgBZQMEAgEFAKCCAREwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEID77qAcNtZbziNn246zaM8NOvcjK3bPhMOyarw4HnV04MIGk
# BgorBgEEAYI3AgEMMYGVMIGSoEyASgBNAHMAcgBjAFMAZQBjAHUAcgBpAHQAeQBV
# AHAAZABhAHQAZQBzACAAUABvAHcAZQByAFMAaABlAGwAbAAgAE0AbwBkAHUAbABl
# oUKAQGh0dHBzOi8vZ2l0aHViLmNvbS9NaWNyb3NvZnQvTVNSQy1NaWNyb3NvZnQt
# U2VjdXJpdHktVXBkYXRlcy1BUEkwDQYJKoZIhvcNAQEBBQAEggEAsUJXUTMWpt7R
# kfwn6ndNPi19NX24s5yzhOG+M64e4WNFzCjDqm2c8aBGNib8P5rF2w2BGjV5Rd6v
# O1SOMQPm/GieBSFvVFWR8m2/Xgf2TP5vX5UkgPYpcLVs2BYdG2R7K0x+VdiuVSjC
# X1zX+jQ9YyX4FVPIH9vN+wLaXs1oDUnPzLpCY9mHPbdugSv4sloRvmfL/+d1gIuZ
# hsbNHhXwvTIN5bZ6PxCaAM4XFeH+37v8J0kpyB/s+oRGiaUM+OhQyF1GzOiua/BY
# 2ds/pbzT6KydVMv4x+fzqc9vsVx8IDAmT4lhI7zYfsGwv/7hK50qBEkIt5Kjcj31
# 1kGGal36DaGCE0owghNGBgorBgEEAYI3AwMBMYITNjCCEzIGCSqGSIb3DQEHAqCC
# EyMwghMfAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggE9BgsqhkiG9w0BCRABBKCCASwE
# ggEoMIIBJAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCD00LmVD4EG
# NLhBR3sFCh7HYj0OE7ss1CbfUDrArQvR+gIGWSYRqY+ZGBMyMDE3MDYwMjIzMzIy
# NS42NTlaMAcCAQGAAgH0oIG5pIG2MIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMQ0wCwYDVQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERT
# RSBFU046QkJFQy0zMENBLTJEQkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFNlcnZpY2Wggg7NMIIGcTCCBFmgAwIBAgIKYQmBKgAAAAAAAjANBgkqhkiG
# 9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIw
# MTAwHhcNMTAwNzAxMjEzNjU1WhcNMjUwNzAxMjE0NjU1WjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKkdDbx3EYo6IOz8E5f1+n9plGt0VBDVpQoAgoX77XxoSyxfxcPlYcJ2tz5mK1vw
# FVMnBDEfQRsalR3OCROOfGEwWbEwRA/xYIiEVEMM1024OAizQt2TrNZzMFcmgqNF
# DdDq9UeBzb8kYDJYYEbyWEeGMoQedGFnkV+BVLHPk0ySwcSmXdFhE24oxhr5hoC7
# 32H8RsEnHSRnEnIaIYqvS2SJUGKxXf13Hz3wV3WsvYpCTUBR0Q+cBj5nf/VmwAOW
# RH7v0Ev9buWayrGo8noqCjHw2k4GkbaICDXoeByw6ZnNPOcvRLqn9NxkvaQBwSAJ
# k3jN/LzAyURdXhacAQVPIk0CAwEAAaOCAeYwggHiMBAGCSsGAQQBgjcVAQQDAgEA
# MB0GA1UdDgQWBBTVYzpcijGQ80N7fEYbxTNoWoVtVTAZBgkrBgEEAYI3FAIEDB4K
# AFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSME
# GDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRw
# Oi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJB
# dXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5o
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8y
# MDEwLTA2LTIzLmNydDCBoAYDVR0gAQH/BIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEw
# PQYIKwYBBQUHAgEWMWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9QS0kvZG9jcy9D
# UFMvZGVmYXVsdC5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AUABv
# AGwAaQBjAHkAXwBTAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQAD
# ggIBAAfmiFEN4sbgmD+BcQM9naOhIW+z66bM9TG+zwXiqf76V20ZMLPCxWbJat/1
# 5/B4vceoniXj+bzta1RXCCtRgkQS+7lTjMz0YBKKdsxAQEGb3FwX/1z5Xhc1mCRW
# S3TvQhDIr79/xn/yN31aPxzymXlKkVIArzgPF/UveYFl2am1a+THzvbKegBvSzBE
# JCI8z+0DpZaPWSm8tv0E4XCfMkon/VWvL/625Y4zu2JfmttXQOnxzplmkIz/amJ/
# 3cVKC5Em4jnsGUpxY517IW3DnKOiPPp/fZZqkHimbdLhnPkd/DjYlPTGpQqWhqS9
# nhquBEKDuLWAmyI4ILUl5WTs9/S/fmNZJQ96LjlXdqJxqgaKD4kWumGnEcua2A5H
# moDF0M2n0O99g/DhO3EJ3110mCIIYdqwUB5vvfHhAN/nMQekkzr3ZUd46PioSKv3
# 3nJ+YWtvd6mBy6cJrDm77MbL2IK0cs0d9LiFAR6A+xuJKlQ5slvayA1VmXqHczsI
# 5pgt6o3gMy4SKfXAL1QnIffIrE7aKLixqduWsqdCosnPGUFN4Ib5KpqjEWYw07t0
# MkvfY3v1mYovG8chr1m1rtxEPJdQcdeh0sVV42neV8HR3jDA/czmTfsNv11P6Z0e
# GTgvvM9YBS7vDaBQNdrvCScc1bN+NR4Iuto229Nfj950iEkSMIIE2jCCA8KgAwIB
# AgITMwAAAKGl/bnup/yenQAAAAAAoTANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0xNjA5MDcxNzU2NDhaFw0xODA5MDcxNzU2
# NDhaMIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQ0wCwYD
# VQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046QkJFQy0zMENBLTJE
# QkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCb0AF55iKvenwbdR7zt2fWHd6n3gA0
# 2BL5B+oIex9NTcqFlHqrdmsqB0WNUSfTtl1GpSXGYhR5i0/M5iz17J9Neh00IjYq
# uMPi7MVQ7dP9Q8Etv8Xw+s/MhJDroqaybVegj7lhcNRJzogvgy47gUqTtUlKxGXJ
# loXkL/qs4thXHTP2vhDnwlIbE+D5FDaos5v02xXw9NJrfS24Vc4R6Vb/lOkhDruR
# V8ycFXlwzY6s0+OBmZjDDgff23PFzylj9T7sNxh6c/YkdbX8yTeUMFcH1aBAFU0L
# FrDm1TddPNjTq7yHl4d6VXNLYUPB8wmIkr7OuOWESjwWN5xBziCXgcgJAgMBAAGj
# ggEbMIIBFzAdBgNVHQ4EFgQUq1y5gr5xKtWP4OiyKc/6G9O3+kgwHwYDVR0jBBgw
# FoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNUaW1TdGFQQ0FfMjAx
# MC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDAN
# BgkqhkiG9w0BAQsFAAOCAQEAI2BMuAVU6WfJvjk8FTLDE8izAJB/FzOb/XYvXUwS
# s+iwJKL+svQfqLKOLk4QB1zo9zSK7jQd6OFEhvge2949EpSHwZoPQ+Cb+hRhq7bq
# EuOqiGrXZXflB1vQUFPRxVrUKC8qSlF5H3k5KnfHYeUjfyoF2iae1UC24l/cOhN0
# 5Tr9qvs/Avwr+fggUlsoyl2yICjuHR70ioS8F1LqsxJxmiwdG04NeNHbkw0kXheI
# SVQh/NhcJtDpE+Fsyk6/B7g7+eGcL0YMZTqcRbAJp3NMLGu21xZj4PxyOJmmBc0y
# kUGiXvq7160Oe4XL8w93O3gy00+WkRRII8aKl5dYHf2lQaGCA3YwggJeAgEBMIHj
# oYG5pIG2MIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQ0w
# CwYDVQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046QkJFQy0zMENB
# LTJEQkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiJQoB
# ATAJBgUrDgMCGgUAAxUAgq6J9bTmPxZcILwX5MHDQM0562iggcIwgb+kgbwwgbkx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1P
# UFIxJzAlBgNVBAsTHm5DaXBoZXIgTlRTIEVTTjo1N0Y2LUMxRTAtNTU0QzErMCkG
# A1UEAxMiTWljcm9zb2Z0IFRpbWUgU291cmNlIE1hc3RlciBDbG9jazANBgkqhkiG
# 9w0BAQUFAAIFANzcGaQwIhgPMjAxNzA2MDIxNzA2NDRaGA8yMDE3MDYwMzE3MDY0
# NFowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA3NwZpAIBADAHAgEAAgIabzAHAgEA
# AgIYazAKAgUA3N1rJAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMB
# oAowCAIBAAIDFuNgoQowCAIBAAIDB6EgMA0GCSqGSIb3DQEBBQUAA4IBAQBKWg18
# ohUSCCakk9Ld/PQB0RPD/RabIKJ8K6z+Of0y9szbV4VpoOINLRi1VuF7OSrH/B3T
# 25Ef11TE0k0rDkSd30+yZp4kVN24QWorHj6S+qivHYvh5FwVQa1F0yrNKOhx3Yya
# xeatNlb1xnVU0NexEbhJCshk6GLgN0T8p35NFcYZMLpz253mksncOVNuWYVEyFPm
# +rf5aq5//FiFogik/dBnbZS1s7MHzzk6IPdzBf5abgWYhF1dD5sPt8UMMKIJq+jS
# lGG8G5NCUvbPnXWWVLOutjgQzk4eWGyQMEPBjLoE+EpX5je493b48EW4+tvgh8OX
# Yij6fQYBVrgizhhhMYIC9TCCAvECAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAAChpf257qf8np0AAAAAAKEwDQYJYIZIAWUDBAIBBQCgggEy
# MBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgOpba
# LqXaWC+4nUhIBp3W3BwvUpdfjPSAEQQXi8uHqTMwgeIGCyqGSIb3DQEJEAIMMYHS
# MIHPMIHMMIGxBBSCron1tOY/FlwgvBfkwcNAzTnraDCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAAoaX9ue6n/J6dAAAAAAChMBYEFJ+m
# FCvtttwqL4Zaga2iBdfWBZScMA0GCSqGSIb3DQEBCwUABIIBABBbihQ+iCsinhQO
# 1VMCkdLEsqDCXNCxrW/XE4UKtK9+Cxn9ZwZVLWtsJ9JgRXHMmaGMtw5YevTsIYho
# OPRS2Tg2Pn8+nCP7iEpujIQTEaL8N9RNroNRHKK4VSqlYJmTpWibyyyKL3NSYBNY
# Ss0GhLJ5YrT6EI1NH6mUtsklyxbSPIv0o8UhWpu2Nf4XQd4HyyqTl1R5trHd2R8X
# Ws7LYBc53HuQR0P817VfJFfm4LJfUteBlFcQYQGk0k/265amMdYw7gvkPIuHrRZH
# jCxMOqK3ybUcGqdiMt/dW7aHnJ2V+EExETTH6PjhCcTnr/zYkS6E2+V1P77u8+gO
# rqaWKmk=
# SIG # End signature block

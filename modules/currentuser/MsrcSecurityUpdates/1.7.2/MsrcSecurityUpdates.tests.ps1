﻿
# Import module would only work if the module is found in standard locations
# Import-Module -Name MsrcSecurityUpdates -Force
Import-Module .\MsrcSecurityUpdates.psd1 -Verbose -Force

# Set-MSRCApiKey -ApiKey "API KEY PLACEHOLDER" -Verbose

if (-not ($global:MSRCApiKey)) {

   Write-Warning -Message 'You need to use Set-MSRCApiKey first to set your API Key'
   break
}

<#
Get-Help Get-MsrcSecurityUpdate
Get-Help Get-MsrcSecurityUpdate -Examples

Get-Help Get-MsrcCvrfDocument
Get-Help Get-MsrcCvrfDocument -Examples

Get-Help Get-MsrcSecurityBulletinHtml
Get-Help Get-MsrcSecurityBulletinHtml -Examples

Get-Help Get-MsrcCvrfAffectedSoftware
Get-Help Get-MsrcCvrfAffectedSoftware -Examples
#> 

Describe 'Function: Get-MsrcSecurityUpdateMSRC (calls the /Updates API)' {

    It 'Get-MsrcSecurityUpdate - all' {
        Get-MsrcSecurityUpdate | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by year' {
        Get-MsrcSecurityUpdate -Year 2017 | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by vulnerability' {
        Get-MsrcSecurityUpdate -Vulnerability CVE-2017-0003 | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by cvrf' {
        Get-MsrcSecurityUpdate -Cvrf 2017-Jan | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by date - before' {
        Get-MsrcSecurityUpdate -Before 2017-01-01 | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by date - after' {
        Get-MsrcSecurityUpdate -After 2017-01-01 | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcSecurityUpdate - by date - before and after' {
        Get-MsrcSecurityUpdate -Before 2017-01-01 -After 2016-10-01 | 
        Should Not BeNullOrEmpty 
    }
}

Describe 'Function: Get-MsrcCvrfDocument (calls the MSRC /cvrf API)' {

    It 'Get-MsrcCvrfDocument - 2016-Nov' {
        Get-MsrcCvrfDocument -ID 2016-Nov | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcCvrfDocument - 2016-Nov - as XML' {
        Get-MsrcCvrfDocument -ID 2016-Nov -AsXml | 
        Should Not BeNullOrEmpty 
    }

    Get-MsrcSecurityUpdate | 
    Foreach-Object {
        It "Get-MsrcCvrfDocument - none shall throw: $($PSItem.ID)" {
            {
                Get-MsrcCvrfDocument -ID $PSItem.ID | 
                Out-Null
            } |
            Should Not Throw
        }
    }
}

Describe 'Function: Set-MSRCApiKey with proxy' {
    if (-not ($global:msrcProxy)) {

       Write-Warning -Message 'This test requires you to use Set-MSRCApiKey first to set your API Key and proxy details'
       break
    }

    It 'Get-MsrcSecurityUpdate - all' {
        Get-MsrcSecurityUpdate | 
        Should Not BeNullOrEmpty 
    }

    It 'Get-MsrcCvrfDocument - 2016-Nov' {
        Get-MsrcCvrfDocument -ID 2016-Nov | 
        Should Not BeNullOrEmpty 
    }
}

# May still work but not ready yet...
# Describe 'Function: Get-MsrcSecurityBulletinHtml (generates the MSRC Security Bulletin HTML Report)' {
#     It 'Security Bulletin Report' {
#         Get-MsrcCvrfDocument -ID 2016-Nov |
#         Get-MsrcSecurityBulletinHtml |
#         Should Not BeNullOrEmpty
#     }
# }
InModuleScope MsrcSecurityUpdates {
    Describe 'Function: Get-MsrcCvrfAffectedSoftware' {
        It 'Get-MsrcCvrfAffectedSoftware by pipeline' {
            Get-MsrcCvrfDocument -ID 2016-Nov |
            Get-MsrcCvrfAffectedSoftware |
            Should Not BeNullOrEmpty
        }

        It 'Get-MsrcCvrfAffectedSoftware by parameters' {
            $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
            Get-MsrcCvrfAffectedSoftware -Vulnerability $cvrfDocument.Vulnerability -ProductTree $cvrfDocument.ProductTree |
            Should Not BeNullOrEmpty
        }
    }

    Describe 'Function: Get-MsrcCvrfProductVulnerability' {
        It 'Get-MsrcCvrfProductVulnerability by pipeline' {
            Get-MsrcCvrfDocument -ID 2016-Nov |
            Get-MsrcCvrfProductVulnerability |
            Should Not BeNullOrEmpty
        }

        It 'Get-MsrcCvrfProductVulnerability by parameters' {
            $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
            Get-MsrcCvrfProductVulnerability -Vulnerability $cvrfDocument.Vulnerability -ProductTree $cvrfDocument.ProductTree -DocumentTracking $cvrfDocument.DocumentTracking -DocumentTitle $cvrfDocument.DocumentTitle  |
            Should Not BeNullOrEmpty
        }
    }
}

Describe 'Function: Get-MsrcVulnerabilityReportHtml (generates the MSRC Vulnerability Summary HTML Report)' {
    It 'Vulnerability Summary Report - does not throw' {
        {
            Get-MsrcCvrfDocument -ID 2016-Nov |
            Get-MsrcVulnerabilityReportHtml -Verbose | Out-Null
        } |
        Should Not Throw
    }

    Get-MsrcSecurityUpdate | 
    Foreach-Object {
        It "Vulnerability Summary Report - none shall throw: $($PSItem.ID)" {
            {
                Get-MsrcCvrfDocument -ID $PSItem.ID |
                Get-MsrcVulnerabilityReportHtml | 
                Out-Null
            } |
            Should Not Throw
        }
    }
}


Describe 'Function: Get-KBDownloadUrl (generates the html for KBArticle downloads used in the vulnerability report affected software table)' {
    It 'Get-KBDownloadUrl by pipeline' {
        {
            $doc = Get-MsrcCvrfDocument -ID 2017-May
            $af = $doc | Get-MsrcCvrfAffectedSoftware 
            $af.KBArticle | Get-KBDownloadUrl
        } |
        Should Not Throw
    }


    It "Get-KBDownloadUrl by parameters" {
        {
            $doc = Get-MsrcCvrfDocument -ID 2017-May
            $af = $doc | Get-MsrcCvrfAffectedSoftware 
            Get-KBDownloadUrl -KBArticleObject $af.KBArticle
        } |
        Should Not Throw
    }
}
# SIG # Begin signature block
# MIIkYQYJKoZIhvcNAQcCoIIkUjCCJE4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDGOrX/4wTPkYGU
# u2bsG1GOvXbcOLPISJf0nmchHQs/SaCCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
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
# KoZIhvcNAQkEMSIEIHqq/Vx3YPSNiQRUZRc4Psmg3LIJSK275u41a87IHJ1/MIGk
# BgorBgEEAYI3AgEMMYGVMIGSoEyASgBNAHMAcgBjAFMAZQBjAHUAcgBpAHQAeQBV
# AHAAZABhAHQAZQBzACAAUABvAHcAZQByAFMAaABlAGwAbAAgAE0AbwBkAHUAbABl
# oUKAQGh0dHBzOi8vZ2l0aHViLmNvbS9NaWNyb3NvZnQvTVNSQy1NaWNyb3NvZnQt
# U2VjdXJpdHktVXBkYXRlcy1BUEkwDQYJKoZIhvcNAQEBBQAEggEAS0avMwO3P87d
# JHUqxBTDVuJcZeHYWC8zeLPrhznl/5vZrf6YwAa/m3o8LAGINNBZw9bXHz7IEmbR
# w/rduybvRaPSX6fPdbeBbavdUyMjYT0/oa1FY/lg4Dggyv1ouji0h/ogVSZ+keNJ
# zr2TMRBfHcAYRlJ4A7fstxDMVm1i6HcWtNnVS95/xiKj003QMwEyYjnyF02RGHXx
# Nh+c3twkwNh2ekZVnMxQjt53iEskOEGiInRMh8p9RSn3T/2aniMpkJxwz+Y3pbNA
# EZvzbbfwsJmRTB9jBjK94chmdfPjxpO29QxcXL+dmEvy/hL+wfxPJ8wkjPNjE+F2
# rWWCUb7SyKGCE0owghNGBgorBgEEAYI3AwMBMYITNjCCEzIGCSqGSIb3DQEHAqCC
# EyMwghMfAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggE9BgsqhkiG9w0BCRABBKCCASwE
# ggEoMIIBJAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCBx08ciZB+J
# k+uLTMXxEFNCbpjbkg0sOiSzw4z4MW2YcgIGWSdV7NxnGBMyMDE3MDYwMjIzMzIy
# NS44OTVaMAcCAQGAAgH0oIG5pIG2MIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMQ0wCwYDVQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERT
# RSBFU046QjFCNy1GNjdGLUZFQzIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
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
# AgITMwAAALFxE3nfdfY1yAAAAAAAsTANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0xNjA5MDcxNzU2NTdaFw0xODA5MDcxNzU2
# NTdaMIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQ0wCwYD
# VQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046QjFCNy1GNjdGLUZF
# QzIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqpCSUbVjWW7yhvQ/t166a5Gfgm9GL
# YYSuYr3i+BudY+Z3SP/1qsDvnf0cPV2kbW6FhuacDFz6qy68wzR+kS+21MriVlJT
# uyzmsl9aZsWf8nyRIYjwr2IFoHqFCQm4hfiyL2mk2v1Hehkjcdsn/JGQpQ+TiGjO
# ljoKR6FFzT9l+7q1CLKojuYKVdhlNePD6suyHf+B0G9gN3fzMUGWVp/7e6KYpCBR
# NcaNsp+plmTe0RTeJtZU9TECabGUbexZOVeZTfV8LD/pNXMaDbnWWr5Djo6Nt4f2
# 8HZM5yoSyjg1qLcnUJ0wBhR2V6VVW2BB0jH9z7ke+vDRjpbu4YEBadbnAgMBAAGj
# ggEbMIIBFzAdBgNVHQ4EFgQUTlc994suFEtXsvwiXtPPtydEEDswHwYDVR0jBBgw
# FoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNUaW1TdGFQQ0FfMjAx
# MC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDAN
# BgkqhkiG9w0BAQsFAAOCAQEAc+6N+7Rbw8FOmN9ho+sAogEspyWNPj5idZtuAa+Z
# dTw68hQMGSS/yA0YYdE7kNLJJoIBEjOCfbIiF4CqHobAzbIqt9vh5UJg97UJOUKx
# 5LlM6/5Of/3mZeP43FOq+42auGAJWvQJDtvfGgpzANxBuDtOZ6sOBsi/aTtwSpth
# tT8Hcy1JfxmON/RmeB0qhfQliQAQNtlyE6tGJS0Mki16A8pk9/oKN4diOuYrC9M5
# ULO/eVbS7KHXJv84N5Ef5WoQ1IcJugWISKr0qkow6l6TVW9CGYjYptOVG8rzr2CP
# U3C5QcfxzdZe7gDRfX4IGZTy3SC9398WVC/DTi94paH3zqGCA3YwggJeAgEBMIHj
# oYG5pIG2MIGzMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMQ0w
# CwYDVQQLEwRNT1BSMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046QjFCNy1GNjdG
# LUZFQzIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiJQoB
# ATAJBgUrDgMCGgUAAxUAOrrfkyhl5HrT56P24qdEbliqU9KggcIwgb+kgbwwgbkx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1P
# UFIxJzAlBgNVBAsTHm5DaXBoZXIgTlRTIEVTTjo0REU5LTBDNUUtM0UwOTErMCkG
# A1UEAxMiTWljcm9zb2Z0IFRpbWUgU291cmNlIE1hc3RlciBDbG9jazANBgkqhkiG
# 9w0BAQUFAAIFANzcF3MwIhgPMjAxNzA2MDIxNjU3MjNaGA8yMDE3MDYwMzE2NTcy
# M1owdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA3NwXcwIBADAHAgEAAgIjpjAHAgEA
# AgIaejAKAgUA3N1o8wIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMB
# oAowCAIBAAIDFuNgoQowCAIBAAIDB6EgMA0GCSqGSIb3DQEBBQUAA4IBAQAexrj0
# Qv58WfnYDLwOw6kqONzz3leFKCxxNwvGSW/fpihO4U6O3VaNqsLTfpRqJFBo6y0X
# 6y2yvaWoXBzdftd4YVBBehxAFbOVYoSqKiqXuuRB2Qe6R0TW7Fy4XyFdZUBiUa7U
# aQo2kPjUCAlP6t+zgyw/C1VdnUR+jIHW09Jq0ln5Xma+K+T+xS0wyaL9NDI2VHgh
# daGUHceUtcwuDd9Th4TuKqihelFfV/HeiI5lgdHqZ+UBQZVd5j1T4avQ/Dp7Xqhg
# vMzTRH9tzVp1Ode8bAyy7DlDkY2nEtVsJNPn47uX8JQAPmh7b7u75fbmBZLOSa+U
# 2AKFGjJLTY1R2CnUMYIC9TCCAvECAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAACxcRN533X2NcgAAAAAALEwDQYJYIZIAWUDBAIBBQCgggEy
# MBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgnGtM
# Ozegs/BphG622CZYSrgISGlRN/c1LyE/fHqS/I8wgeIGCyqGSIb3DQEJEAIMMYHS
# MIHPMIHMMIGxBBQ6ut+TKGXketPno/bip0RuWKpT0jCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAAsXETed919jXIAAAAAACxMBYEFFKw
# rQJPdob0XI9lcC6TO4L2aoyjMA0GCSqGSIb3DQEBCwUABIIBAGnrvwv6ixljpftw
# pkmuXlqAoHwWhXKxcDMw+KNmpk3YjY1O3Fh/20HfwA9LwYoo6KmLFqmtw3Bff1m1
# EeMexrgbxg+VmbtHdNhndh2fYp+7mOLUo6BeaUios1aeCl8XQSIbMY+2YzNAb6Lk
# L2lk8L0TnraXR1tN3eQVuoyGxBWDGo4bfge1LMIOnL9WrDz3cK9QwAnO6ocPX3Y7
# 387vKgtO4gzrBOv1ytEMaFcLDGK4cT8Y8lU9cQhEx7dpn5FYNc+XR9y2CVz6r5Kz
# zaiFmGS9rrD18jRs0qp0nU92LHfIpGCCURm6H0BIUx0EMxTTlRKf4Rzwk3uaMjjE
# OiWV3JU=
# SIG # End signature block

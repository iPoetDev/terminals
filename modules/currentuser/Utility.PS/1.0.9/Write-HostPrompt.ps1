<#
.SYNOPSIS
    Displays a PowerShell prompt for multiple fields or multiple choices.
.DESCRIPTION
    Displays a PowerShell prompt for multiple fields or multiple choices.
.EXAMPLE
    PS C:\>Write-HostPrompt "Prompt Caption" "Prompt Message" -Fields @(
        New-Object System.Management.Automation.Host.FieldDescription -ArgumentList "Field 1"
        New-Object System.Management.Automation.Host.FieldDescription -ArgumentList "Field 2"
    )
    Display prompt for 2 fields.
.EXAMPLE
    PS C:\>Write-HostPrompt "Prompt Caption" "Prompt Message" -DefaultChoice 0 -Choices @(
        New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "Choice &1 Label","Choice 1 Help Message"
        New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes","Yes Help Message"
        New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "$No","No Help Message"
    )
    Display prompt with 3 choices.
.INPUTS
    System.Management.Automation.Host.FieldDescription
    System.Management.Automation.Host.ChoiceDescription
.OUTPUTS
    System.Collections.Generic.Dictionary[System.String,System.Management.Automation.PSObject]
    System.Int32
#>
function Write-HostPrompt {
    [CmdletBinding()]
    param
    (
        # Caption to preceed or title the prompt.
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Caption,
        # A message that describes the prompt.
        [Parameter(Mandatory = $true, Position = 2)]
        [string] $Message,
        # The fields in the prompt.
        [Parameter(Mandatory = $true, ParameterSetName = 'Fields', Position = 3, ValueFromPipeline = $true)]
        [System.Management.Automation.Host.FieldDescription[]] $Fields,
        # The choices the shown in the prompt.
        [Parameter(Mandatory = $true, ParameterSetName = 'Choices', Position = 3, ValueFromPipeline = $true)]
        [System.Management.Automation.Host.ChoiceDescription[]] $Choices,
        # The index of the label in the choices to make default.
        [Parameter(Mandatory = $false, ParameterSetName = 'Choices', Position = 4)]
        [int] $DefaultChoice = -1
    )

    begin {
        ## Create list to capture multiple fields or multiple choices.
        [System.Collections.Generic.List[System.Management.Automation.Host.FieldDescription]] $listFields = New-Object System.Collections.Generic.List[System.Management.Automation.Host.FieldDescription]
        [System.Collections.Generic.List[System.Management.Automation.Host.ChoiceDescription]] $listChoices = New-Object System.Collections.Generic.List[System.Management.Automation.Host.ChoiceDescription]
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Fields' {
                foreach ($Field in $Fields) { $listFields.Add($Field) }
            }
            'Choices' {
                foreach ($Choice in $Choices) { $listChoices.Add($Choice) }
            }
        }
    }

    end {
        switch ($PSCmdlet.ParameterSetName) {
            'Fields' { return $Host.UI.Prompt($Caption, $Message, $listFields.ToArray()) }
            'Choices' { return $Host.UI.PromptForChoice($Caption, $Message, $listChoices.ToArray(), $DefaultChoice) }
        }
    }
}

# SIG # Begin signature block
# MIIZnAYJKoZIhvcNAQcCoIIZjTCCGYkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD2a0/1r69iYteV
# RSHqXCXbTdO+7+UbBwMaysOrNJzpn6CCFJUwggT+MIID5qADAgECAhANQkrgvjqI
# /2BAIc4UAPDdMA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwHhcN
# MjEwMTAxMDAwMDAwWhcNMzEwMTA2MDAwMDAwWjBIMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFt
# cCAyMDIxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwuZhhGfFivUN
# CKRFymNrUdc6EUK9CnV1TZS0DFC1JhD+HchvkWsMlucaXEjvROW/m2HNFZFiWrj/
# ZwucY/02aoH6KfjdK3CF3gIY83htvH35x20JPb5qdofpir34hF0edsnkxnZ2OlPR
# 0dNaNo/Go+EvGzq3YdZz7E5tM4p8XUUtS7FQ5kE6N1aG3JMjjfdQJehk5t3Tjy9X
# tYcg6w6OLNUj2vRNeEbjA4MxKUpcDDGKSoyIxfcwWvkUrxVfbENJCf0mI1P2jWPo
# GqtbsR0wwptpgrTb/FZUvB+hh6u+elsKIC9LCcmVp42y+tZji06lchzun3oBc/gZ
# 1v4NSYS9AQIDAQABo4IBuDCCAbQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQC
# MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQQYDVR0gBDowODA2BglghkgBhv1s
# BwEwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMB8G
# A1UdIwQYMBaAFPS24SAd/imu0uRhpbKiJbLIFzVuMB0GA1UdDgQWBBQ2RIaOpLqw
# Zr68KC0dRDbd42p6vDBxBgNVHR8EajBoMDKgMKAuhixodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vc2hhMi1hc3N1cmVkLXRzLmNybDAyoDCgLoYsaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC10cy5jcmwwgYUGCCsGAQUFBwEBBHkw
# dzAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME8GCCsGAQUF
# BzAChkNodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNz
# dXJlZElEVGltZXN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQBIHNy1
# 6ZojvOca5yAOjmdG/UJyUXQKI0ejq5LSJcRwWb4UoOUngaVNFBUZB3nw0QTDhtk7
# vf5EAmZN7WmkD/a4cM9i6PVRSnh5Nnont/PnUp+Tp+1DnnvntN1BIon7h6JGA078
# 9P63ZHdjXyNSaYOC+hpT7ZDMjaEXcw3082U5cEvznNZ6e9oMvD0y0BvL9WH8dQgA
# dryBDvjA4VzPxBFy5xtkSdgimnUVQvUtMjiB2vRgorq0Uvtc4GEkJU+y38kpqHND
# Udq9Y9YfW5v3LhtPEx33Sg1xfpe39D+E68Hjo0mh+s6nv1bPull2YYlffqe0jmd4
# +TaY4cso2luHpoovMIIFJjCCBA6gAwIBAgIQCm8Gpkn9Nk686mPMJKDEczANBgkq
# hkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDMzMTAwMDAwMFoX
# DTIzMDQwNTEyMDAwMFowYzELMAkGA1UEBhMCVVMxDTALBgNVBAgTBE9oaW8xEzAR
# BgNVBAcTCkNpbmNpbm5hdGkxFzAVBgNVBAoTDkphc29uIFRob21wc29uMRcwFQYD
# VQQDEw5KYXNvbiBUaG9tcHNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAMVnygZO0wvpQ3NjGpEREqp0r/FN5C0X0Gn6HxrhPXAyGZaBlEjV0eO6bz8N
# BVFwyHsQ0BFxT7CrGvCCwvekm7bqIZaIJe9kFYAvOVBDK+S042dGaT8cUSxU6QIk
# gXL2IZKZu8R8H0+26rehGpadj+onbqzFshaS8C18/1oFv27W/3FeOwAkXbE8Mbpu
# c9ntR/6PUV4biw3AYUITVps0PmfTB1f06DmrbWa3orHVDO1yEL/E1hoe0jpXPAHz
# vtNlLMtZg5LeRrGdkfasq8V94XicNWU8XFy6D5cFlIg0RPcSzMJRJb78nfpQInrp
# DAagviDCUVR5ZwLsvDk096h8kCUCAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+5845JPvDWenjXahLo4XUCcTn
# MjAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGE
# BggrBgEFBQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBOBggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQC
# MAAwDQYJKoZIhvcNAQELBQADggEBAER9rMHu+w+qJrQmh6at6GrAPYuHi2zuU04n
# dRRzTSmHUKvzS1DvEYxLp6cO//3gHEqBV1S0YV58Rn5idMii7fmANSfO1Og4x77/
# CmmnpwB8aoSCpbRxqcIBE+pUm7r7JBT4xNEKT3FkgcpVymE4VuIscBgnekEmmaVf
# Doh1Xm4cQ+hvtyZ8+3+bNQ/Oe008RSk5zmiWiS++eGeB1D5v6yLs2bHAHldKKCp8
# Mg322VqRB2C9bFlQSxS97FB/s4J4jGxjSSl6MmcYLzkw+Copc5/9c1QEzBe+9rZM
# aAPwb6e977tkFtFOCfiekESAjku2NPqjj83EtLOOllrv3r81oWcwggUwMIIEGKAD
# AgECAhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0x
# MzEwMjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0Ew
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZ
# z9D7RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnko
# On7p0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXU
# LaGj6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q
# 8grkV7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5S
# lsHyDxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPR
# AgMBAAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIB
# hjATBgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNy
# dDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBG
# MDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNl
# cnQuY29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt
# 9mV1DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcN
# AQELBQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L
# /e8q3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xG
# Tlz/kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGiv
# m6dcIFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZ
# Hen6dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdi
# bqFT+hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggUxMIIEGaADAgECAhAKoSXW1jIb
# fkHkBdo2l8IVMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xNjAxMDcxMjAwMDBa
# Fw0zMTAxMDcxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQC90DLuS82Pf92puoKZxTlUKFe2I0rEDgdFM1EQ
# fdD5fU1ofue2oPSNs4jkl79jIZCYvxO8V9PD4X4I1moUADj3Lh477sym9jJZ/l9l
# P+Cb6+NGRwYaVX4LJ37AovWg4N4iPw7/fpX786O6Ij4YrBHk8JkDbTuFfAnT7l3I
# mgtU46gJcWvgzyIQD3XPcXJOCq3fQDpct1HhoXkUxk0kIzBdvOw8YGqsLwfM/fDq
# R9mIUF79Zm5WYScpiYRR5oLnRlD9lCosp+R1PrqYD4R/nzEU1q3V8mTLex4F0IQZ
# chfxFwbvPc3WTe8GQv2iUypPhR3EHTyvz9qsEPXdrKzpVv+TAgMBAAGjggHOMIIB
# yjAdBgNVHQ4EFgQU9LbhIB3+Ka7S5GGlsqIlssgXNW4wHwYDVR0jBBgwFoAUReui
# r/SSy4IxLVGLp6chnfNtyA8wEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8E
# BAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgweQYIKwYBBQUHAQEEbTBrMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwUAYDVR0g
# BEkwRzA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IBAQBx
# lRLpUYdWac3v3dp8qmN6s3jPBjdAhO9LhL/KzwMC/cWnww4gQiyvd/MrHwwhWiq3
# BTQdaq6Z+CeiZr8JqmDfdqQ6kw/4stHYfBli6F6CJR7Euhx7LCHi1lssFDVDBGiy
# 23UC4HLHmNY8ZOUfSBAYX4k4YU1iRiSHY4yRUiyvKYnleB/WCxSlgNcSR3CzddWT
# hZN+tpJn+1Nhiaj1a5bA9FhpDXzIAbG5KHW3mWOFIoxhynmUfln8jA/jb7UBJrZs
# pe6HUSHkWGCbugwtK22ixH67xCUrRwIIfEmuE7bhfEJCKMYYVs9BNLZmXbZ0e/VW
# MyIvIjayS6JKldj1po5SMYIEXTCCBFkCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBD
# QQIQCm8Gpkn9Nk686mPMJKDEczANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBZgXPT3E6F
# aT73pkuo3+RT7A39ndjnBtQKMUEpVeW6qTANBgkqhkiG9w0BAQEFAASCAQAx/xng
# t24M/URGNwXaUkQGlIE/pUeeYcO1YB4IafxFPBa7NE/3HGv6Ij6vVHd1oMqJ5M1I
# fsQ2z97/mKuggiTNEsrqj3l2jx0cSvw7hxUCRo05R48gTa9RdpBhKd/GVk/IuV+u
# Pcspko1DVKtHCxMzvaypK1GlLt/6io9uhmbSuwOUANglSB+qUbaZK9s9JZtFouxB
# NuPqYA2BYmHzHk9FP8J/9jteGpI75/L/ONngSX4q2a5eNhR9CD9h0bCZ6CQaG7CT
# JiCcnQgb3KsWIVTkNw9uWqTQE5kY6Xz4MsxNIn48AkxwyduTdtY694EZemHdLoTq
# iSbhSKITzWZ35u/joYICIDCCAhwGCSqGSIb3DQEJBjGCAg0wggIJAgEBMIGGMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBUaW1lc3RhbXBpbmcgQ0ECEA1CSuC+Ooj/YEAhzhQA8N0wCQYFKw4DAhoFAKBd
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIxMDEx
# NDA1MzEwMVowIwYJKoZIhvcNAQkEMRYEFM9eF59S59bFO3m8ixqGhxgFxT8bMA0G
# CSqGSIb3DQEBAQUABIIBAAkgfUegiUHMKm21xbm+RhbPjvCuSjmyhIexM7LuUnuH
# XypVYqitu6MK9jC9ti0UzYhdFT1ZWHNtmV0Ax95rxfYOvodNT57OGz/RtYynuJyZ
# fTraondwwahNwtMcZT0ayY++5wd5HLoZM1wubernso1tvjScTmaVJ6bEyNaH9czc
# DBEt9KAVcRzmRv/r90tr3jGNOlbd/C6qaZJv5CXOrnquFJ839w6AbTjpwOZtybaN
# CIizFABeYhQLjqPUR+fPxgVtqKDVfOgEKP1nz8dlAkee0/Ny4ZCOmrcXDgH56kdI
# FQilGFHaCe8x6j5ZwTnW+FHI/fmnxffjzuvsH2KCXV8=
# SIG # End signature block

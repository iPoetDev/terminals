function New-PGPKey {
    [cmdletBinding(DefaultParameterSetName = 'ClearText')]
    param([parameter(Mandatory, ParameterSetName = 'Strength')]
        [parameter(Mandatory, ParameterSetName = 'StrengthCredential')]
        [parameter(Mandatory, ParameterSetName = 'ClearText')]
        [parameter(Mandatory, ParameterSetName = 'Credential')]
        [string] $FilePathPublic,
        [parameter(Mandatory, ParameterSetName = 'Strength')]
        [parameter(Mandatory, ParameterSetName = 'StrengthCredential')]
        [parameter(Mandatory, ParameterSetName = 'ClearText')]
        [parameter(Mandatory, ParameterSetName = 'Credential')]
        [string] $FilePathPrivate,
        [parameter(ParameterSetName = 'Strength')]
        [parameter(ParameterSetName = 'ClearText')]
        [string] $UserName,
        [parameter(ParameterSetName = 'Strength')]
        [parameter(ParameterSetName = 'ClearText')]
        [string] $Password,
        [parameter(Mandatory, ParameterSetName = 'StrengthCredential')]
        [parameter(Mandatory, ParameterSetName = 'Credential')]
        [pscredential] $Credential,
        [parameter(Mandatory, ParameterSetName = 'Strength')]
        [parameter(Mandatory, ParameterSetName = 'StrengthCredential')]
        [int] $Strength,
        [parameter(Mandatory, ParameterSetName = 'Strength')]
        [parameter(Mandatory, ParameterSetName = 'StrengthCredential')]
        [int] $Certainty,
        [parameter(ParameterSetName = 'Strength')]
        [parameter(ParameterSetName = 'StrengthCredential')]
        [switch] $EmitVersion)
    try { $PGP = [PgpCore.PGP]::new() } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "New-PGPKey - Creating keys genarated erorr: $($_.Exception.Message)"
            return
        }
    }
    if ($Credential) {
        $UserName = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
    }
    try { if ($Strength) { $PGP.GenerateKey($FilePathPublic, $FilePathPrivate, $UserName, $Password, $Strength, $Certainty, $EmitVersion.IsPresent) } else { $PGP.GenerateKey($FilePathPublic, $FilePathPrivate, $UserName, $Password) } } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "New-PGPKey - Creating keys genarated erorr: $($_.Exception.Message)"
            return
        }
    }
}
function Protect-PGP {
    [cmdletBinding(DefaultParameterSetName = 'File')]
    param([Parameter(Mandatory, ParameterSetName = 'Folder')]
        [Parameter(Mandatory, ParameterSetName = 'File')]
        [Parameter(Mandatory, ParameterSetName = 'String')]
        [string[]] $FilePathPublic,
        [Parameter(Mandatory, ParameterSetName = 'Folder')][string] $FolderPath,
        [Parameter(ParameterSetName = 'Folder')][string] $OutputFolderPath,
        [Parameter(Mandatory, ParameterSetName = 'File')][string] $FilePath,
        [Parameter(ParameterSetName = 'File')][string] $OutFilePath,
        [Parameter(Mandatory, ParameterSetName = 'String')][string] $String)
    $PublicKeys = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($FilePathPubc in $FilePathPublic) {
        if (Test-Path -LiteralPath $FilePathPubc) { $PublicKeys.Add([System.IO.FileInfo]::new($FilePathPubc)) } else {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                Write-Warning -Message "Protect-PGP - Public key doesn't exists $($FilePathPubc): $($_.Exception.Message)"
                return
            }
        }
    }
    try {
        $EncryptionKeys = [PgpCore.EncryptionKeys]::new($PublicKeys)
        $PGP = [PgpCore.PGP]::new($EncryptionKeys)
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "Protect-PGP - Can't encrypt files because: $($_.Exception.Message)"
            return
        }
    }
    if ($FolderPath) {
        $ResolvedFolderPath = Resolve-Path -Path $FolderPath
        foreach ($File in Get-ChildItem -LiteralPath $ResolvedFolderPath.Path -Recurse:$Recursive) {
            try {
                if ($OutputFolderPath) {
                    $ResolvedOutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolderPath)
                    $OutputFile = [io.Path]::Combine($ResolvedOutputFolder, "$($File.Name).pgp")
                    $PGP.EncryptFile($File.FullName, $OutputFile)
                } else { $PGP.EncryptFile($File.FullName, "$($File.FullName).pgp") }
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                    Write-Warning -Message "Protect-PGP - Can't encrypt file $($File.FullName): $($_.Exception.Message)"
                    return
                }
            }
        }
    } elseif ($FilePath) {
        try {
            $ResolvedFilePath = Resolve-Path -Path $FilePath
            if ($OutFilePath) {
                $ResolvedOutFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFilePath)
                $PGP.EncryptFile($ResolvedFilePath.Path, "$($ResolvedOutFilePath)")
            } else { $PGP.EncryptFile($ResolvedFilePath.Path, "$($ResolvedFilePath.Path).pgp") }
        } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                Write-Warning -Message "Protect-PGP - Can't encrypt file $($FilePath): $($_.Exception.Message)"
                return
            }
        }
    } elseif ($String) { try { $PGP.EncryptArmoredString($String) } catch { if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else { Write-Warning -Message "Protect-PGP - Can't encrypt string: $($_.Exception.Message)" } } }
}
function Test-PGP {
    [cmdletBinding(DefaultParameterSetName = 'File')]
    param([Parameter(Mandatory, ParameterSetName = 'Folder')]
        [Parameter(Mandatory, ParameterSetName = 'File')]
        [Parameter(Mandatory, ParameterSetName = 'String')]
        [string] $FilePathPublic,
        [Parameter(Mandatory, ParameterSetName = 'Folder')][string] $FolderPath,
        [Parameter(ParameterSetName = 'Folder')][string] $OutputFolderPath,
        [Parameter(Mandatory, ParameterSetName = 'File')][string] $FilePath,
        [Parameter(ParameterSetName = 'File')][string] $OutFilePath,
        [Parameter(Mandatory, ParameterSetName = 'String')][string] $String)
    if (Test-Path -LiteralPath $FilePathPublic) { $PublicKey = [System.IO.FileInfo]::new($FilePathPublic) } else {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "Test-PGP - Public key doesn't exists $($FilePathPublic): $($_.Exception.Message)"
            return
        }
    }
    try {
        $EncryptionKeys = [PgpCore.EncryptionKeys]::new($PublicKey)
        $PGP = [PgpCore.PGP]::new($EncryptionKeys)
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "Test-PGP - Can't test files because: $($_.Exception.Message)"
            return
        }
    }
    if ($FolderPath) {
        $ResolvedFolderPath = Resolve-Path -Path $FolderPath
        foreach ($File in Get-ChildItem -LiteralPath $ResolvedFolderPath.Path -Recurse:$Recursive) {
            try {
                $Output = $PGP.VerifyFile($File.FullName)
                $ErrorMessage = ''
            } catch {
                $Output = $false
                if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                    Write-Warning -Message "Test-PGP - Can't test file $($File.FuleName): $($_.Exception.Message)"
                    $ErrorMessage = $($_.Exception.Message)
                }
            }
            [PSCustomObject] @{FilePath = $File.FullName
                Status                  = $Output
                Error                   = $ErrorMessage
            }
        }
    } elseif ($FilePath) {
        $ResolvedFilePath = Resolve-Path -Path $FilePath
        try { $Output = $PGP.VerifyFile($ResolvedFilePath.Path) } catch {
            $Output = $false
            if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                Write-Warning -Message "Test-PGP - Can't test file $($ResolvedFilePath.Path): $($_.Exception.Message)"
                $ErrorMessage = $($_.Exception.Message)
            }
        }
        [PSCustomObject] @{FilePath = $ResolvedFilePath.Path
            Status                  = $Output
            Error                   = $ErrorMessage
        }
    } elseif ($String) { try { $PGP.VerifyArmoredString($String) } catch { if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else { Write-Warning -Message "Test-PGP - Can't test string: $($_.Exception.Message)" } } }
}
function Unprotect-PGP {
    [cmdletBinding(DefaultParameterSetName = 'FolderClearText')]
    param([Parameter(Mandatory, ParameterSetName = 'FolderCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FolderClearText')]
        [Parameter(Mandatory, ParameterSetName = 'FileCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FileClearText')]
        [Parameter(Mandatory, ParameterSetName = 'StringClearText')]
        [Parameter(Mandatory, ParameterSetName = 'StringCredential')]
        [string] $FilePathPrivate,
        [Parameter(ParameterSetName = 'FolderClearText')]
        [Parameter(ParameterSetName = 'FileClearText')]
        [Parameter(ParameterSetName = 'StringClearText')]
        [string] $Password,
        [Parameter(Mandatory, ParameterSetName = 'FileCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FolderCredential')]
        [Parameter(Mandatory, ParameterSetName = 'StringCredential')]
        [pscredential] $Credential,
        [Parameter(Mandatory, ParameterSetName = 'FolderCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FolderClearText')]
        [string] $FolderPath,
        [Parameter(Mandatory, ParameterSetName = 'FolderCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FolderClearText')]
        [string] $OutputFolderPath,
        [Parameter(Mandatory, ParameterSetName = 'FileCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FileClearText')]
        [string] $FilePath,
        [Parameter(Mandatory, ParameterSetName = 'FileCredential')]
        [Parameter(Mandatory, ParameterSetName = 'FileClearText')]
        [string] $OutFilePath,
        [Parameter(Mandatory, ParameterSetName = 'StringClearText')]
        [Parameter(Mandatory, ParameterSetName = 'StringCredential')]
        [string] $String)
    if ($Credential) { $Password = $Credential.GetNetworkCredential().Password }
    if (-not (Test-Path -LiteralPath $FilePathPrivate)) {
        Write-Warning -Message "Unprotect-PGP - Remove PGP encryption failed because private key file doesn't exists."
        return
    }
    $PrivateKey = Get-Content -LiteralPath $FilePathPrivate -Raw
    try {
        $EncryptionKeys = [PgpCore.EncryptionKeys]::new($PrivateKey, $Password)
        $PGP = [PgpCore.PGP]::new($EncryptionKeys)
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
            Write-Warning -Message "Protect-PGP - Can't encrypt files because: $($_.Exception.Message)"
            return
        }
    }
    if ($FolderPath) {
        $ResolvedFolderPath = Resolve-Path -Path $FolderPath
        foreach ($File in Get-ChildItem -LiteralPath $ResolvedFolderPath.Path -Recurse:$Recursive) {
            try {
                if ($OutputFolderPath) {
                    $ResolvedOutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolderPath)
                    $OutputFile = [io.Path]::Combine($ResolvedOutputFolder, "$($File.Name.Replace('.pgp',''))")
                    $PGP.DecryptFile($File.FullName, $OutputFile)
                } else { $PGP.DecryptFile($File.FullName, "$($File.FullName)") }
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                    Write-Warning -Message "Unprotect-PGP - Remove PGP encryption from $($File.FullName) failed: $($_.Exception.Message)"
                    return
                }
            }
        }
    } elseif ($FilePath) {
        try {
            $ResolvedFilePath = Resolve-Path -Path $FilePath
            if ($OutFilePath) {
                $ResolvedOutFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFilePath)
                $PGP.DecryptFile($ResolvedFilePath.Path, "$($ResolvedOutFilePath)", $FilePathPrivate, $Password)
            } else { $PGP.DecryptFile($ResolvedFilePath.Path, "$($FilePath.Replace('.pgp',''))") }
        } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                Write-Warning -Message "Unprotect-PGP - Remove PGP encryption from $($FilePath) failed: $($_.Exception.Message)"
                return
            }
        }
    } elseif ($String) {
        try { $PGP.DecryptArmoredString($String) } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') { throw } else {
                Write-Warning -Message "Unprotect-PGP - Remove PGP encryption from string failed: $($_.Exception.Message)"
                return
            }
        }
    }
}
Export-ModuleMember -Function @('New-PGPKey', 'Protect-PGP', 'Test-PGP', 'Unprotect-PGP') -Alias @()
# SIG # Begin signature block
# MIIdWQYJKoZIhvcNAQcCoIIdSjCCHUYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoEpztR7qRryCpTaMbBuFQi9x
# A56gghhnMIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3Qg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg
# +XESpa7cJpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lT
# XDGEKvYPmDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5
# a3/UsDg+wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g
# 0I6QNcZ4VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1
# roV9Iq4/AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whf
# GHdPAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3
# cmbYMuRCdWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmr
# EthngYTffwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+
# fT8r87cmNW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5Q
# Z7dsvfPxH2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu
# 838fYxAe+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw
# 8jCCBP4wggPmoAMCAQICEA1CSuC+Ooj/YEAhzhQA8N0wDQYJKoZIhvcNAQELBQAw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIFRpbWVzdGFtcGluZyBDQTAeFw0yMTAxMDEwMDAwMDBaFw0zMTAxMDYwMDAw
# MDBaMEgxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4G
# A1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjEwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDC5mGEZ8WK9Q0IpEXKY2tR1zoRQr0KdXVNlLQMULUmEP4d
# yG+RawyW5xpcSO9E5b+bYc0VkWJauP9nC5xj/TZqgfop+N0rcIXeAhjzeG28ffnH
# bQk9vmp2h+mKvfiEXR52yeTGdnY6U9HR01o2j8aj4S8bOrdh1nPsTm0zinxdRS1L
# sVDmQTo3VobckyON91Al6GTm3dOPL1e1hyDrDo4s1SPa9E14RuMDgzEpSlwMMYpK
# jIjF9zBa+RSvFV9sQ0kJ/SYjU/aNY+gaq1uxHTDCm2mCtNv8VlS8H6GHq756Wwog
# L0sJyZWnjbL61mOLTqVyHO6fegFz+BnW/g1JhL0BAgMBAAGjggG4MIIBtDAOBgNV
# HQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDBBBgNVHSAEOjA4MDYGCWCGSAGG/WwHATApMCcGCCsGAQUFBwIBFhtodHRwOi8v
# d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwHwYDVR0jBBgwFoAU9LbhIB3+Ka7S5GGlsqIl
# ssgXNW4wHQYDVR0OBBYEFDZEho6kurBmvrwoLR1ENt3janq8MHEGA1UdHwRqMGgw
# MqAwoC6GLGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtdHMu
# Y3JsMDKgMKAuhixodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVk
# LXRzLmNybDCBhQYIKwYBBQUHAQEEeTB3MCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wTwYIKwYBBQUHMAKGQ2h0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURUaW1lc3RhbXBpbmdDQS5jcnQw
# DQYJKoZIhvcNAQELBQADggEBAEgc3LXpmiO85xrnIA6OZ0b9QnJRdAojR6OrktIl
# xHBZvhSg5SeBpU0UFRkHefDRBMOG2Tu9/kQCZk3taaQP9rhwz2Lo9VFKeHk2eie3
# 8+dSn5On7UOee+e03UEiifuHokYDTvz0/rdkd2NfI1Jpg4L6GlPtkMyNoRdzDfTz
# ZTlwS/Oc1np72gy8PTLQG8v1Yfx1CAB2vIEO+MDhXM/EEXLnG2RJ2CKadRVC9S0y
# OIHa9GCiurRS+1zgYSQlT7LfySmoc0NR2r1j1h9bm/cuG08THfdKDXF+l7f0P4Tr
# weOjSaH6zqe/Vs+6WXZhiV9+p7SOZ3j5NpjhyyjaW4emii8wggUwMIIEGKADAgEC
# AhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEw
# MjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7
# RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p
# 0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj
# 6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grk
# V7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHy
# DxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMB
# AAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCB
# gQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgG
# CmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1
# DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEL
# BQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q
# 3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/
# kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dc
# IFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6
# dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT
# +hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggUxMIIEGaADAgECAhAKoSXW1jIbfkHk
# Bdo2l8IVMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMT
# G0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xNjAxMDcxMjAwMDBaFw0z
# MTAxMDcxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQC90DLuS82Pf92puoKZxTlUKFe2I0rEDgdFM1EQfdD5
# fU1ofue2oPSNs4jkl79jIZCYvxO8V9PD4X4I1moUADj3Lh477sym9jJZ/l9lP+Cb
# 6+NGRwYaVX4LJ37AovWg4N4iPw7/fpX786O6Ij4YrBHk8JkDbTuFfAnT7l3ImgtU
# 46gJcWvgzyIQD3XPcXJOCq3fQDpct1HhoXkUxk0kIzBdvOw8YGqsLwfM/fDqR9mI
# UF79Zm5WYScpiYRR5oLnRlD9lCosp+R1PrqYD4R/nzEU1q3V8mTLex4F0IQZchfx
# FwbvPc3WTe8GQv2iUypPhR3EHTyvz9qsEPXdrKzpVv+TAgMBAAGjggHOMIIByjAd
# BgNVHQ4EFgQU9LbhIB3+Ka7S5GGlsqIlssgXNW4wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwUAYDVR0gBEkw
# RzA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9DUFMwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IBAQBxlRLp
# UYdWac3v3dp8qmN6s3jPBjdAhO9LhL/KzwMC/cWnww4gQiyvd/MrHwwhWiq3BTQd
# aq6Z+CeiZr8JqmDfdqQ6kw/4stHYfBli6F6CJR7Euhx7LCHi1lssFDVDBGiy23UC
# 4HLHmNY8ZOUfSBAYX4k4YU1iRiSHY4yRUiyvKYnleB/WCxSlgNcSR3CzddWThZN+
# tpJn+1Nhiaj1a5bA9FhpDXzIAbG5KHW3mWOFIoxhynmUfln8jA/jb7UBJrZspe6H
# USHkWGCbugwtK22ixH67xCUrRwIIfEmuE7bhfEJCKMYYVs9BNLZmXbZ0e/VWMyIv
# IjayS6JKldj1po5SMIIFPTCCBCWgAwIBAgIQBNXcH0jqydhSALrNmpsqpzANBgkq
# hkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDYyNjAwMDAwMFoX
# DTIzMDcwNzEyMDAwMFowejELMAkGA1UEBhMCUEwxEjAQBgNVBAgMCcWabMSFc2tp
# ZTERMA8GA1UEBxMIS2F0b3dpY2UxITAfBgNVBAoMGFByemVteXPFgmF3IEvFgnlz
# IEVWT1RFQzEhMB8GA1UEAwwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7KB3iyBrhkLUbbFe9qxhKKPBYqD
# Bqlnr3AtpZplkiVjpi9dMZCchSeT5ODsShPuZCIxJp5I86uf8ibo3vi2S9F9AlfF
# jVye3dTz/9TmCuGH8JQt13ozf9niHecwKrstDVhVprgxi5v0XxY51c7zgMA2g1Ub
# +3tii0vi/OpmKXdL2keNqJ2neQ5cYly/GsI8CREUEq9SZijbdA8VrRF3SoDdsWGf
# 3tZZzO6nWn3TLYKQ5/bw5U445u/V80QSoykszHRivTj+H4s8ABiforhi0i76beA6
# Ea41zcH4zJuAp48B4UhjgRDNuq8IzLWK4dlvqrqCBHKqsnrF6BmBrv+BXQIDAQAB
# o4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0O
# BBYEFBixNSfoHFAgJk4JkDQLFLRNlJRmMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE
# DDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUw
# QzA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNl
# cnQuY29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNp
# Z25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAmr1s
# z4lsLARi4wG1eg0B8fVJFowtect7SnJUrp6XRnUG0/GI1wXiLIeow1UPiI6uDMsR
# XPHUF/+xjJw8SfIbwava2eXu7UoZKNh6dfgshcJmo0QNAJ5PIyy02/3fXjbUREHI
# NrTCvPVbPmV6kx4Kpd7KJrCo7ED18H/XTqWJHXa8va3MYLrbJetXpaEPpb6zk+l8
# Rj9yG4jBVRhenUBUUj3CLaWDSBpOA/+sx8/XB9W9opYfYGb+1TmbCkhUg7TB3gD6
# o6ESJre+fcnZnPVAPESmstwsT17caZ0bn7zETKlNHbc1q+Em9kyBjaQRcEQoQQNp
# ezQug9ufqExx6lHYDjGCBFwwggRYAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EC
# EATV3B9I6snYUgC6zZqbKqcwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFA/2UTDy2sJS9slzdsQO
# YnTQccjdMA0GCSqGSIb3DQEBAQUABIIBAB+AA9qRiFEsgsPHTghvFaX3tJpf/FZk
# PTqcWdBecKhgcse3shWHr7cTd759NN3Y6JF5qPbUhyqolhBWm57lcZuWntFAfO7Y
# q4prWERGBR6V6/cWPsTAlPVELysY8E2q/pTGmGglR4eABm29GuRudCpDaInw4UdM
# 3cJPXyWygc8OdmfhyTfUTsMX216FMC7zJam1fDvuINF/rnVTxFy6Tcxk1eOyF9Mb
# 2JAc8Rf+WOTg5+kkFSLjHWMy+y5KnoL3s+qIWB4uKB7dsxbZSsnpR1+ijfTZJ3q7
# 3/dGXJSGofN5E3lSDINb5J6lCigaeYvapRmWwhniUyZ9qloIi5CD8a+hggIwMIIC
# LAYJKoZIhvcNAQkGMYICHTCCAhkCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQQIQ
# DUJK4L46iP9gQCHOFADw3TANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIyMDMwMTIyMjUzN1owLwYJKoZI
# hvcNAQkEMSIEIL4KwXIzqW/iKbJKum32LANElvJq35ttAqGN1/QlHg45MA0GCSqG
# SIb3DQEBAQUABIIBAIPXVs11AjaPt9n6GZMGzwlgnjkGL2LPbhmOSsX27XzqCBAe
# zlV9Y24pwuIdWA29hMn2aCl3J7FwaQzUhhuoMQ5VJFFGzjyIbXnjLtlSqbHKMsqP
# xsGGBHmpDvkvCMKMJzwBjoDXWiyUvXzC2MrdXU305Ir0wGiMTuHH8SGMc1FgOGXu
# HPZPw+IZe3pJAat3Pld+Zt6WcrEmNvik90clQ+pHKDubRWAcJ5M/lw1Gu9TSu+mk
# VMygWfvYxMm57AusoG5Xh8hQ6MweO/O4sECk1qzorOcRwAZTDL7rgNQBGAVWGfx3
# KOFoYTf/lUR7n6+GsMampLTMfohavlyQulZjMMw=
# SIG # End signature block

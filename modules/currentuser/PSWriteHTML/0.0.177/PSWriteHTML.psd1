@{
    AliasesToExport      = @('EmailHTML', 'Add-JavaScript', 'New-JavaScript', 'Add-JS', 'Add-CSS', 'ConvertTo-CSS', 'CalendarEvent', 'ChartCategory', 'ChartAxisX', 'New-ChartCategory', 'ChartAxisY', 'ChartBar', 'ChartBarOptions', 'New-ChartFill', 'ChartDonut', 'ChartGrid', 'ChartLegend', 'ChartLine', 'ChartPie', 'ChartRadial', 'ChartSpark', 'ChartTheme', 'ChartTimeLine', 'ChartToolbar', 'DiagramEdge', 'DiagramEdges', 'New-DiagramEdge', 'DiagramLink', 'DiagramNode', 'DiagramOptionsInteraction', 'DiagramOptionsLayout', 'DiagramOptionsEdges', 'New-DiagramOptionsEdges', 'DiagramOptionsLinks', 'DiagramOptionsManipulation', 'DiagramOptionsNodes', 'DiagramOptionsPhysics', 'HierarchicalTreeNode', 'Dashboard', 'New-HTMLLink', 'Calendar', 'Chart', 'Container', 'Diagram', 'New-Diagram', 'Footer', 'Header', 'Image', 'EmailImage', 'EmailList', 'Main', 'New-HTMLColumn', 'Panel', 'New-HTMLPanelOption', 'New-PanelOption', 'PanelOption', 'New-PanelStyle', 'PanelStyle', 'New-HTMLContent', 'Section', 'New-HTMLSectionOptions', 'SectionOption', 'New-HTMLSectionOption', 'Tab', 'Table', 'EmailTable', 'New-TableOption', 'TableOption', 'EmailTableOption', 'EmailTableStyle', 'TableStyle', 'New-TableStyle', 'TabOptions', 'New-TabOption', 'New-HTMLTabOptions', 'TabOption', 'New-HTMLTabOption', 'TabStyle', 'HTMLText', 'Text', 'EmailText', 'EmailTextBox', 'New-HTMLNavItem', 'New-HTMLNavLink', 'New-HTMLNavTopMenu', 'TableAlphabetSearch', 'New-HTMLTableAlphabetSearch', 'TableButtonCopy', 'EmailTableButtonCopy', 'New-HTMLTableButtonCopy', 'TableButtonCSV', 'EmailTableButtonCSV', 'New-HTMLTableButtonCSV', 'TableButtonExcel', 'EmailTableButtonExcel', 'New-HTMLTableButtonExcel', 'TableButtonPageLength', 'EmailTableButtonPageLength', 'New-HTMLTableButtonPageLength', 'TableButtonPDF', 'EmailTableButtonPDF', 'New-HTMLTableButtonPDF', 'TableButtonPrint', 'EmailTableButtonPrint', 'New-HTMLTableButtonPrint', 'TableButtonSearchBuilder', 'EmailTableButtonSearchBuilder', 'New-HTMLTableButtonSearchBuilder', 'EmailTableColumnOption', 'TableColumnOption', 'New-HTMLTableColumnOption', 'EmailTableCondition', 'TableConditionalFormatting', 'New-HTMLTableCondition', 'TableCondition', 'EmailTableConditionGroup', 'TableConditionGroup', 'New-HTMLTableConditionGroup', 'TableContent', 'EmailTableContent', 'New-HTMLTableContent', 'TableHeader', 'EmailTableHeader', 'New-HTMLTableHeader', 'TablePercentageBar', 'New-HTMLTablePercentageBar', 'TableReplace', 'EmailTableReplace', 'New-HTMLTableReplace', 'TableRowGrouping', 'EmailTableRowGrouping', 'New-HTMLTableRowGrouping', 'Out-GridHtml', 'ohv')
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2022 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'PSWriteHTML is PowerShell Module to generate beautiful HTML reports, pages, emails without any knowledge of HTML, CSS or JavaScript. To get started basics PowerShell knowledge is required.'
    FunctionsToExport    = @('Add-HTML', 'Add-HTMLScript', 'Add-HTMLStyle', 'ConvertTo-CascadingStyleSheets', 'Email', 'EmailAttachment', 'EmailBCC', 'EmailBody', 'EmailCC', 'EmailFrom', 'EmailHeader', 'EmailLayout', 'EmailLayoutColumn', 'EmailLayoutRow', 'EmailListItem', 'EmailOptions', 'EmailReplyTo', 'EmailServer', 'EmailSubject', 'EmailTo', 'Enable-HTMLFeature', 'New-AccordionItem', 'New-CalendarEvent', 'New-CarouselSlide', 'New-ChartAxisX', 'New-ChartAxisY', 'New-ChartBar', 'New-ChartBarOptions', 'New-ChartDataLabel', 'New-ChartDesign', 'New-ChartDonut', 'New-ChartEvent', 'New-ChartGrid', 'New-ChartLegend', 'New-ChartLine', 'New-ChartMarker', 'New-ChartPie', 'New-ChartRadial', 'New-ChartRadialOptions', 'New-ChartSpark', 'New-ChartTheme', 'New-ChartTimeLine', 'New-ChartToolbar', 'New-ChartToolTip', 'New-DiagramEvent', 'New-DiagramLink', 'New-DiagramNode', 'New-DiagramOptionsInteraction', 'New-DiagramOptionsLayout', 'New-DiagramOptionsLinks', 'New-DiagramOptionsManipulation', 'New-DiagramOptionsNodes', 'New-DiagramOptionsPhysics', 'New-GageSector', 'New-HierarchicalTreeNode', 'New-HTML', 'New-HTMLAccordion', 'New-HTMLAnchor', 'New-HTMLCalendar', 'New-HTMLCarousel', 'New-HTMLCarouselStyle', 'New-HTMLChart', 'New-HTMLCodeBlock', 'New-HTMLContainer', 'New-HTMLDiagram', 'New-HTMLFontIcon', 'New-HTMLFooter', 'New-HTMLFrame', 'New-HTMLGage', 'New-HTMLHeader', 'New-HTMLHeading', 'New-HTMLHierarchicalTree', 'New-HTMLHorizontalLine', 'New-HTMLImage', 'New-HTMLList', 'New-HTMLListItem', 'New-HTMLLogo', 'New-HTMLMain', 'New-HTMLMap', 'New-HTMLNav', 'New-HTMLNavFloat', 'New-HTMLNavTop', 'New-HTMLOrgChart', 'New-HTMLPage', 'New-HTMLPanel', 'New-HTMLPanelStyle', 'New-HTMLQRCode', 'New-HTMLSection', 'New-HTMLSectionScrolling', 'New-HTMLSectionScrollingItem', 'New-HTMLSectionStyle', 'New-HTMLSpanStyle', 'New-HTMLStatus', 'New-HTMLStatusItem', 'New-HTMLSummary', 'New-HTMLSummaryItem', 'New-HTMLSummaryItemData', 'New-HTMLTab', 'New-HTMLTable', 'New-HTMLTableOption', 'New-HTMLTableStyle', 'New-HTMLTabPanel', 'New-HTMLTabStyle', 'New-HTMLTag', 'New-HTMLText', 'New-HTMLTextBox', 'New-HTMLTimeline', 'New-HTMLTimelineItem', 'New-HTMLToast', 'New-HTMLTree', 'New-HTMLWinBox', 'New-HTMLWizard', 'New-HTMLWizardStep', 'New-NavFloatWidget', 'New-NavFloatWidgetItem', 'New-NavItem', 'New-NavLink', 'New-NavTopMenu', 'New-OrgChartNode', 'New-TableAlphabetSearch', 'New-TableButtonCopy', 'New-TableButtonCSV', 'New-TableButtonExcel', 'New-TableButtonPageLength', 'New-TableButtonPDF', 'New-TableButtonPrint', 'New-TableButtonSearchBuilder', 'New-TableColumnOption', 'New-TableCondition', 'New-TableConditionGroup', 'New-TableContent', 'New-TableEvent', 'New-TableHeader', 'New-TableLanguage', 'New-TablePercentageBar', 'New-TableReplace', 'New-TableRowGrouping', 'New-TreeNode', 'Out-HtmlView', 'Save-HTML')
    GUID                 = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
    ModuleVersion        = '0.0.177'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = @('HTML', 'WWW', 'JavaScript', 'CSS', 'Reports', 'Reporting', 'Windows', 'MacOS', 'Linux')
            ProjectUri = 'https://github.com/EvotecIT/PSWriteHTML'
            IconUri    = 'https://evotec.xyz/wp-content/uploads/2018/12/PSWriteHTML.png'
        }
    }
    RootModule           = 'PSWriteHTML.psm1'
    ScriptsToProcess     = @()
}
# SIG # Begin signature block
# MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBbTmUgo40o3eEt
# 23/6Ot2anL//Y7BUs0CkjVZUNanoyaCCIT0wggO3MIICn6ADAgECAhAM5+DlF9hG
# /o/lYPwb8DA5MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBa
# Fw0zMTExMTAwMDAwMDBaMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAK0OFc7kQ4BcsYfzt2D5cRKlrtwmlIiq9M71IDkoWGAM+IDaqRWVMmE8
# tbEohIqK3J8KDIMXeo+QrIrneVNcMYQq9g+YMjZ2zN7dPKii72r7IfJSYd+fINcf
# 4rHZ/hhk0hJbX/lYGDW8R82hNvlrf9SwOD7BG8OMM9nYLxj+KA+zp4PWw25EwGE1
# lhb+WZyLdm3X8aJLDSv/C3LanmDQjpA1xnhVhyChz+VtCshJfDGYM2wi6YfQMlqi
# uhOCEe05F52ZOnKh5vqk2dUXMXWuhX0irj8BRob2KHnIsdrkVxfEfhwOsLSSplaz
# vbKX7aqn8LfFqD+VFtD/oZbrCF8Yd08CAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFEXroq/0ksuCMS1Ri6enIZ3zbcgP
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUA
# A4IBAQCiDrzf4u3w43JzemSUv/dyZtgy5EJ1Yq6H6/LV2d5Ws5/MzhQouQ2XYFwS
# TFjk0z2DSUVYlzVpGqhH6lbGeasS2GeBhN9/CTyU5rgmLCC9PbMoifdf/yLil4Qf
# 6WXvh+DfwWdJs13rsgkq6ybteL59PyvztyY1bV+JAbZJW58BBZurPSXBzLZ/wvFv
# hsb6ZGjrgS2U60K3+owe3WLxvlBnt2y98/Efaww2BxZ/N3ypW2168RJGYIPXJwS+
# S86XvsNnKmgR34DnDDNmvxMNFG7zfx9jEB76jRslbWyPpbdhAbHSoyahEHGdreLD
# +cOZUbcrBwjOLuZQsqf6CkUvovDyMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1
# b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtE
# aWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgx
# MDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLX
# cep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSR
# I5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXi
# TWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5
# Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8
# vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYD
# VR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4
# oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCow
# KAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZI
# AYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaA
# FEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPz
# ItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRu
# pY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKN
# JK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmif
# z0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN
# 3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKy
# ZqHnGKSaZFHvMIIFPTCCBCWgAwIBAgIQBNXcH0jqydhSALrNmpsqpzANBgkqhkiG
# 9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDYyNjAwMDAwMFoXDTIz
# MDcwNzEyMDAwMFowejELMAkGA1UEBhMCUEwxEjAQBgNVBAgMCcWabMSFc2tpZTER
# MA8GA1UEBxMIS2F0b3dpY2UxITAfBgNVBAoMGFByemVteXPFgmF3IEvFgnlzIEVW
# T1RFQzEhMB8GA1UEAwwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7KB3iyBrhkLUbbFe9qxhKKPBYqDBqln
# r3AtpZplkiVjpi9dMZCchSeT5ODsShPuZCIxJp5I86uf8ibo3vi2S9F9AlfFjVye
# 3dTz/9TmCuGH8JQt13ozf9niHecwKrstDVhVprgxi5v0XxY51c7zgMA2g1Ub+3ti
# i0vi/OpmKXdL2keNqJ2neQ5cYly/GsI8CREUEq9SZijbdA8VrRF3SoDdsWGf3tZZ
# zO6nWn3TLYKQ5/bw5U445u/V80QSoykszHRivTj+H4s8ABiforhi0i76beA6Ea41
# zcH4zJuAp48B4UhjgRDNuq8IzLWK4dlvqrqCBHKqsnrF6BmBrv+BXQIDAQABo4IB
# xTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYE
# FBixNSfoHFAgJk4JkDQLFLRNlJRmMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3
# BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25p
# bmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAmr1sz4ls
# LARi4wG1eg0B8fVJFowtect7SnJUrp6XRnUG0/GI1wXiLIeow1UPiI6uDMsRXPHU
# F/+xjJw8SfIbwava2eXu7UoZKNh6dfgshcJmo0QNAJ5PIyy02/3fXjbUREHINrTC
# vPVbPmV6kx4Kpd7KJrCo7ED18H/XTqWJHXa8va3MYLrbJetXpaEPpb6zk+l8Rj9y
# G4jBVRhenUBUUj3CLaWDSBpOA/+sx8/XB9W9opYfYGb+1TmbCkhUg7TB3gD6o6ES
# Jre+fcnZnPVAPESmstwsT17caZ0bn7zETKlNHbc1q+Em9kyBjaQRcEQoQQNpezQu
# g9ufqExx6lHYDjCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZI
# hvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNz
# dXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVow
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjww
# IjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J5
# 8soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMH
# hOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6
# Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQ
# ecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4b
# A3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9
# WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCU
# tNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvo
# ZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/J
# vNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCP
# orF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMB
# Af8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXr
# oq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRt
# MGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEF
# BQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgw
# BgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cH
# vZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8
# UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTn
# f+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxU
# jG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8j
# LfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5lDCCBq4w
# ggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4X
# DTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVk
# IEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5M
# om2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE
# 2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWN
# lCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFo
# bjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhN
# ef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3Vu
# JyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtz
# Q87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4O
# uGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5
# sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm
# 4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIz
# tM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6
# FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qY
# rhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYB
# BQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# QQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZ
# MBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmO
# wJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H
# 6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/
# R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzv
# qLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/ae
# sXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdm
# kfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3
# EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh
# 3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA
# 3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8
# BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsf
# gPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbGMIIErqADAgECAhAKekqI
# nsmZQpAGYzhNhpedMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBH
# NCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIwMzI5MDAwMDAw
# WhcNMzMwMzE0MjM1OTU5WjBMMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNl
# cnQsIEluYy4xJDAiBgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALkqliOmXLxf1knwFYIY9DPu
# zFxs4+AlLtIx5DxArvurxON4XX5cNur1JY1Do4HrOGP5PIhp3jzSMFENMQe6Rm7p
# o0tI6IlBfw2y1vmE8Zg+C78KhBJxbKFiJgHTzsNs/aw7ftwqHKm9MMYW2Nq867Lx
# g9GfzQnFuUFqRUIjQVr4YNNlLD5+Xr2Wp/D8sfT0KM9CeR87x5MHaGjlRDRSXw9Q
# 3tRZLER0wDJHGVvimC6P0Mo//8ZnzzyTlU6E6XYYmJkRFMUrDKAz200kheiClOEv
# A+5/hQLJhuHVGBS3BEXz4Di9or16cZjsFef9LuzSmwCKrB2NO4Bo/tBZmCbO4O2u
# fyguwp7gC0vICNEyu4P6IzzZ/9KMu/dDI9/nw1oFYn5wLOUrsj1j6siugSBrQ4nI
# fl+wGt0ZvZ90QQqvuY4J03ShL7BUdsGQT5TshmH/2xEvkgMwzjC3iw9dRLNDHSNQ
# zZHXL537/M2xwafEDsTvQD4ZOgLUMalpoEn5deGb6GjkagyP6+SxIXuGZ1h+fx/o
# K+QUshbWgaHK2jCQa+5vdcCwNiayCDv/vb5/bBMY38ZtpHlJrYt/YYcFaPfUcONC
# leieu5tLsuK2QT3nr6caKMmtYbCgQRgZTu1Hm2GV7T4LYVrqPnqYklHNP8lE54CL
# KUJy93my3YTqJ+7+fXprAgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgG
# BmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxq
# II+eyG8wHQYDVR0OBBYEFI1kt4kh/lZYRIRhp+pvHDaP3a8NMFoGA1UdHwRTMFEw
# T6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRH
# NFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGD
# MIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYB
# BQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQEL
# BQADggIBAA0tI3Sm0fX46kuZPwHk9gzkrxad2bOMl4IpnENvAS2rOLVwEb+EGYs/
# XeWGT76TOt4qOVo5TtiEWaW8G5iq6Gzv0UhpGThbz4k5HXBw2U7fIyJs1d/2Wcuh
# wupMdsqh3KErlribVakaa33R9QIJT4LWpXOIxJiA3+5JlbezzMWn7g7h7x44ip/v
# EckxSli23zh8y/pc9+RTv24KfH7X3pjVKWWJD6KcwGX0ASJlx+pedKZbNZJQfPQX
# podkTz5GiRZjIGvL8nvQNeNKcEiptucdYL0EIhUlcAZyqUQ7aUcR0+7px6A+TxC5
# MDbk86ppCaiLfmSiZZQR+24y8fW7OK3NwJMR1TJ4Sks3KkzzXNy2hcC7cDBVeNaY
# /lRtf3GpSBp43UZ3Lht6wDOK+EoojBKoc88t+dMj8p4Z4A2UKKDr2xpRoJWCjihr
# pM6ddt6pc6pIallDrl/q+A8GQp3fBmiW/iqgdFtjZt5rLLh4qk1wbfAs8QcVfjW0
# 5rUMopml1xVrNQ6F1uAszOAMJLh8UgsemXzvyMjFjFhpr6s94c/MfRWuFL+Kcd/K
# l7HYR+ocheBFThIcFClYzG/Tf8u+wQ5KbyCcrtlzMlkI5y2SoRoR/jKYpl0rl+CL
# 05zMbbUNrkdjOEcXW28T2moQbh9Jt0RbtAgKh1pZBHYRoad3AhMcMYIFXTCCBVkC
# AQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBB
# c3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQBNXcH0jqydhSALrNmpsqpzANBglg
# hkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCAic4la8rN+LDdU16F7yCGvKi76tVYNa+i+KHsoqeA/
# azANBgkqhkiG9w0BAQEFAASCAQCtUQXWkdig1ZCpbqOJ3OVt3dxaRtTY7DOW75d8
# Q7GW8epCc7xGJUh4NnTCHytkGwSGbr1M8mbNvseLJHUnKUJNScs8E1J0RyBVao78
# fa/lWTacXUJJh4R1lJRSYkSiqnhIrpv+/PaNn9bMpQJFC4gxKpKQr4nRSJs1k1LG
# 5i0s1R2Xi/geqmKxSda4HkRfH/madz3CXfi+aSxKF+ZuTPduagRT3kq5xFewhJn+
# TNPYU+twViIjgqElHCW8RpAOqwXEepeX/ANkZXL/86X51fCA+7W4DBNC43gW120f
# oYNLeWIjPptbgSlIyyCjmivagUFZQjmmZLJXhLDaLzDOfBGnoYIDIDCCAxwGCSqG
# SIb3DQEJBjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRp
# Z2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQw
# OTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQCnpKiJ7JmUKQBmM4TYaXnTANBglg
# hkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcN
# AQkFMQ8XDTIyMDgxODIwMTgwNlowLwYJKoZIhvcNAQkEMSIEIDbDSciP+B0W12QS
# HLGQ+LN3YkuBfdDdeoTFtpV1uD4jMA0GCSqGSIb3DQEBAQUABIICACn0FeXABS6c
# S+L2TqYuwXB67CSUSWr+o/KWlSJnJaE49BVszFcKo03AdayvUjFoEfthSYCIBstp
# NdZqdj9s83NTQnUEson01WAHRhyFZL2Nf21WCcFoTJi61Kv+gvmwpuRiGHRwj2KU
# HM7iFIK64QjxrVRrRtH453whzEghNVofJ/EmioFWQ4AwrD4Su2KAYLAeqpgpe41i
# oY/6OLF2x354lnVKFysyzH0Ec8CC/W4hetJBb3xnLqyhhX5xrHd0YiuajwpuAToy
# w85HhoM29YSs3vbvU5iW42dQj+LhwtMjZ6VqYhG/9dBViIzo6w5rfzfo9hfJIEDi
# kFR0z3uJVOfGSwObItM912yZHaKqeOBZ1O3afevnWCZl2yCe1s5kprcvuUfMthKK
# 2WE94/LGjzS77I0GRr5PRTPN0gzzro8AppchetrltVAcFun1+6AqEATTLtc8Yh1y
# kxGgylBYQf/njTjT4oebkN3sgD3eF1pHSs6JTpjaE00M1eXVqdbDv3Mnpbe0LRah
# xaxqjtc14nVvxzYRgW94xhJXGL+5TZcn8j+0G/EsarQh1Chd+YLd+5w3vurJu9Y2
# Egbvbp6xbbRqOTl3Ks7JYm7IiWRs1zKz1XDgce74kjMSYPPdXZu7VIeIVznvPvJc
# rhSX8C+YTxkS2D0wxT7FpjMZWZPvcSlq
# SIG # End signature block

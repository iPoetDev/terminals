Function Get-MsrcSecurityBulletinHtml {
[CmdletBinding()]
Param(

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Vulnerability,

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $ProductTree,


    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $DocumentTracking,

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $DocumentTitle
)    
Begin {

    $htmlDocumentTemplate = @'
<html>
<head>
    <!-- this is the css from the old bulletin site. Change this to better style your report to your liking -->
    <link rel="stylesheet" href="https://i-technet.sec.s-msft.com/Combined.css?resources=0:ImageSprite,0:TopicResponsive,0:TopicResponsive.MediaQueries,1:CodeSnippet,1:ProgrammingSelector,1:ExpandableCollapsibleArea,0:CommunityContent,1:TopicNotInScope,1:FeedViewerBasic,1:ImageSprite,2:Header.2,2:HeaderFooterSprite,2:Header.MediaQueries,2:Banner.MediaQueries,3:megabladeMenu.1,3:MegabladeMenu.MediaQueries,3:MegabladeMenuSpriteCluster,0:Breadcrumbs,0:Breadcrumbs.MediaQueries,0:ResponsiveToc,0:ResponsiveToc.MediaQueries,1:NavSidebar,0:LibraryMemberFilter,4:StandardRating,2:Footer.2,5:LinkList,2:Footer.MediaQueries,0:BaseResponsive,6:MsdnResponsive,0:Tables.MediaQueries,7:SkinnyRatingResponsive,7:SkinnyRatingV2;/Areas/Library/Content:0,/Areas/Epx/Content/Css:1,/Areas/Epx/Themes/TechNet/Content:2,/Areas/Epx/Themes/Shared/Content:3,/Areas/Global/Content:4,/Areas/Epx/Themes/Base/Content:5,/Areas/Library/Themes/Msdn/Content:6,/Areas/Library/Themes/TechNet/Content:7&amp;v=9192817066EC5D087D15C766A0430C95">
    
    <!-- this style section changes cell widths in the exec header table so that the affected products at the end are wide enough to read -->
    <style>
        #execHeader td:first-child  {{ width: 10% ;}}
        #execHeader td:nth-child(5) {{ width: 37% ;}}
    </style>

    <!-- this section defines explicit width for all cells in the affected software tables. This is so the column width is the same across each product -->
    <style>
        .affected_software td:first-child {{ width: 20% ; }}
        .affected_software td:nth-child(2) {{ width: 20% ; }}
        .affected_software td:nth-child(3) {{ width: 15% ; }}
        .affected_software td:nth-child(4) {{ width: 22.5% ; }}
        .affected_software td:nth-child(5) {{ width: 22.5% ; }}

    </style>

</head>

<body lang=EN-US link=blue>
<div id="documentWrapper" style="width: 90%; margin-left: auto; margin-right: auto;">

<h1>Microsoft Security Bulletin Summary for {0}</h1>

<p>This document is a summary for Microsoft security updates released for {0}.</p>

<p>Microsoft also provides information to help customers prioritize
monthly security updates with any non-security, high-priority updates that are being
released on the same day as the monthly security updates. Please see the section,
<b>Other Information</b>.
</p>

<p>
As a reminder, the <a href="https://portal.msrc.microsoft.com/en-us/security-guidance">Security Updates Guide</a> 
will be replacing security bulletins. Please see our blog post, 
<a href="https://blogs.technet.microsoft.com/msrc/2016/11/08/furthering-our-commitment-to-security-updates/">Furthering our commitment to security updates</a>, for more details.
</p>

<p>To receive automatic notifications whenever Microsoft Security
Updates are issued, subscribe to <a href="http://go.microsoft.com/fwlink/?LinkId=21163">Microsoft Technical Security Notifications</a>.
</p>

<h1>Executive Summaries</h1>

<p>The following table summarizes the security updates for this month in order of severity.
For details on affected software, see the next section, Affected Software.
</p>

<table id="execHeader" border=1 cellpadding=0 width="99%">
 <thead style="background-color: #ededed">
  <tr>
   <td><b>CVE ID</b></td>
   <td><b>Vulnerability Description</b></td>
   <td><b>Maximum Severity Rating</b></td>
   <td><b>Vulnerability Impact</b></td>
   <td><b>Affected Software</b></td>
  </tr>
 </thead>
 {1}
</table>

<h1>Exploitability Index</h1>

<p>The following table provides an exploitability assessment of each of the vulnerabilities addressed this month. The vulnerabilities are listed in order of bulletin ID then CVE ID. Only vulnerabilities that have a severity rating of Critical or Important in the bulletins are included.</p>

<p><b>How do I use this table?</b></p>

<p>Use this table to learn about the likelihood of code execution and denial of service exploits within 30 days of security bulletin release, for each of the security updates that you may need to install. Review each of the assessments below, in accordance with your specific configuration, to prioritize your deployment of this month's updates. For more information about what these ratings mean, and how they are determined, please see <a href="http://technet.microsoft.com/security/cc998259">Microsoft Exploitability Index</a>.
</p>

<p>In the columns below, "Latest Software Release" refers to the subject software, and "Older Software Releases" refers to all older, supported releases of the subject software, as listed in the "Affected Software" and "Non-Affected Software" tables in the bulletin.</p>

<table border=1 cellpadding=0 width="99%">
 <thead style="background-color: #ededed">
  <tr>
   <td><b>CVE ID</b></td>
   <td><b>Vulnerability Title</b></td>
   <td><b>Exploitability Assessment for Latest Software Release</b></td>
   <td><b>Exploitability Assessment for Older Software Release</b></td>
   <td><b>Denial of Service Exploitability Assessment</b></td>   
  </tr>
 </thead>
 {2}
</table>

<h1>Affected Software</h1>

<p>The following tables list the bulletins in order of major software category and severity.</p>
<p>Use these tables to learn about the security updates that you may need to install. You should review each software program or component listed to see whether any security updates pertain to your installation. If a software program or component is listed, then the severity rating of the software update is also listed.</p>
<p><b>Note:</b> You may have to install several security updates for a single vulnerability. Review the whole column for each bulletin identifier that is listed to verify the updates that you have to install, based on the programs or components that you have installed on your system.</p>

<!-- Affected software tables -->
{3}
<!-- End Affected software tables -->

<h1>Detection and Deployment Tools and Guidance</h1>

<p>Several resources are available to help administrators deploy security updates.</p>
<ul>
    <li>
        Microsoft Baseline Security Analyzer (MBSA) lets
        administrators scan local and remote systems for missing security updates and common
        security misconfigurations.
    </li>
    <li>
        Windows Server Update Services (WSUS), Systems Management Server (SMS), 
        and System Center Configuration Manager help administrators distribute security updates.
    </li>
    <li>
        The Update Compatibility Evaluator components included with Application Compatibility 
        Toolkit aid in streamlining the testing and validation of Windows updates against installed applications.
    </li>
</ul>

<p>For information about these and other tools that are available, see 
    <a href="http://technet.microsoft.com/security/cc297183">Security Tools for IT Pros</a>.
</p>

<h1>Other Information</h1>

<h2>Microsoft Windows Malicious Software Removal Tool</h2>

<p>Microsoft will release an updated version of the Microsoft Windows
Malicious Software Removal Tool on Windows Update, Microsoft Update, Windows Server
Update Services, and the Download Center.</p>

<h2>Microsoft Active Protections Program (MAPP)</h2>

<p>To improve security protections for customers, Microsoft provides
vulnerability information to major security software providers in advance of each
monthly security update release. Security software providers can then use this vulnerability
information to provide updated protections to customers via their security software
or devices, such as antivirus, network-based intrusion detection systems, or host-based
intrusion prevention systems. To determine whether active protections are available
from security software providers, please visit the active protections websites provided
by program partners, listed in 
<a href="http://go.microsoft.com/fwlink/?LinkId=215201">Microsoft Active Protections Program (MAPP) Partners</a>.
</p>

<h2>Security Strategies and Community</h2>

<p>Updates for other security issues are available from the following locations:</p>

<ul>
<li>
    Non-Window Security updates are available from <a href="http://go.microsoft.com/fwlink/?LinkId=21129">Microsoft Download Center</a>.
    You can find them most easily by doing a keyword search for &quot;security update&quot;.
</li>
<li>
    All Updates are available from <a href="http://go.microsoft.com/fwlink/?LinkID=40747">Microsoft Update</a>.
</li>
</ul>

<h2>IT Pro Security Community</h2>

<p>Learn to improve security and optimize your IT infrastructure,
and participate with other IT Pros on security topics in 
<a href="http://go.microsoft.com/fwlink/?LinkId=21164">IT Pro Security Community</a>.
</p>

<h2>Support</h2>
<ul>
<li>
    The affected software listed has been tested to determine
    which versions are affected. Other versions are past their support life cycle. To
    determine the support life cycle for your software version, visit 
    <a href="http://go.microsoft.com/fwlink/?LinkId=21742">Microsoft Support Lifecycle</a>.
</li>
<li>
    Help protect your computer that is running Windows
    from viruses and malware: 
    <a href="http://support.microsoft.com/contactus/cu_sc_virsec_master">Virus and Security Solution Center</a>
</li>
</ul>

<h2>Disclaimer</h2>

<p>The information provided in the Microsoft Knowledge Base is
provided &quot;as is&quot; without warranty of any kind. Microsoft disclaims all
warranties, either express or implied, including the warranties of merchantability
and fitness for a particular purpose. In no event shall Microsoft Corporation or
its suppliers be liable for any damages whatsoever including direct, indirect, incidental,
consequential, loss of business profits or special damages, even if Microsoft Corporation
or its suppliers have been advised of the possibility of such damages. Some states
do not allow the exclusion or limitation of liability for consequential or incidental
damages so the foregoing limitation may not apply.</p>

</div>

 </body>
</html>
'@ 

    $cveSummaryRowTemplate = @'
<tr>
     <td>{0}</td>
     <td>{1}</td>
     <td>{2}</td>
     <td>{3}</td>
     <td>{4}</td>
 </tr>
'@
    $cveSummaryTableHtml = ''

    $exploitabilityRowTemplate = @'
<tr>
     <td>{0}</td>
     <td>{1}</td>
     <td>{2}</td>
     <td>{3}</td>
     <td>{4}</td>
 </tr>
'@

    $exploitabilityIndexTableHtml = ''

    $affectedSoftwareNameHeaderTemplate = @'
    <table class="affected_software" border=1 cellpadding=0 width="99%">
        <thead style="background-color: #ededed">
            <tr>
                <td colspan="5"><b>{0}</b></td>
            </tr>
        </thead>
            <tr>
                <td><b>CVE ID</b></td>
                <td><b>KB Article</b></td>
                <td><b>Restart Required</b></td>
                <td><b>Severity</b></td>  
                <td><b>Impact</b></td>  
            </tr>
        {1}
    </table>
'@

    $affectedSoftwareRowTemplate = @'
    <tr>
         <td>{0}</td>
         <td>{1}</td>
         <td>{2}</td>
         <td>{3}</td>
         <td>{4}</td>
    </tr>
'@

    $affectedSoftwareTableHtml = ''
    $affectedSoftwareDocumentHtml = ''
}
Process {

    #region CVE Summary Table
    $HT = @{
        Vulnerability = $PSBoundParameters['Vulnerability']
        ProductTree = $PSBoundParameters['ProductTree']
    }

    Get-MsrcCvrfCVESummary @HT | 
    ForEach-Object {
        $cveSummaryTableHtml += $cveSummaryRowTemplate -f @(
            "$($_.CVE)<br><a href=`"http://www.cve.mitre.org/cgi-bin/cvename.cgi?name=$($_.CVE)`">MITRE</a><br><a href=`"https://web.nvd.nist.gov/view/vuln/detail?vulnId=$($_.CVE)`">NVD</a>"
            $_.Description
            $_.'Maximum Severity Rating'
            $_.'Vulnerability Impact' -join ',<br>'
            $_.'Affected Software' -join ',<br>'
        )
    }
    #endregion

    #region Exploitability Index Table

    Get-MsrcCvrfExploitabilityIndex -Vulnerability $PSBoundParameters['Vulnerability'] | 
    ForEach-Object {
        $exploitabilityIndexTableHtml += $exploitabilityRowTemplate -f @(
            $_.CVE #TODO - make this an href
            $_.Title
            $_.LatestSoftwareRelease
            $_.OlderSoftwareRelease
            'N/A' # was $ExploitStatus.DenialOfService           
        )
    }
    #endregion

    #region Affected Software Table

    $affectedSoftware = Get-MsrcCvrfAffectedSoftware @HT

    $affectedSoftware.FullProductName | 
    Sort-Object -Unique | 
    ForEach-Object {

        $PN = $_
     
        $affectedSoftwareTableHtml = ''
        
        $affectedSoftware | 
        Where-Object { $_.FullProductName -eq $PN } | 
        Sort-Object -Unique -Property CVE |
        ForEach-Object {
            $affectedSoftwareTableHtml += $affectedSoftwareRowTemplate -f @(
                $_.CVE,
                $(
                    if (-not($_.KBArticle)) {
                        'None'
                    } else {
                        ($_.KBArticle | ForEach-Object {
                            '<a href="https://catalog.update.microsoft.com/v7/site/Search.aspx?q={0}">{0}</a><br>' -f  $_
                        }) -join '<br />'
                    }
                ),
                $(
                    if (-not($_.RestartRequired)) {
                        'Unknown'
                    } else{
                        ($_.RestartRequired | ForEach-Object {
                            '{0}<br>' -f $_
                        })  -join '<br />'
                    }
                ),
                $(
                    if (-not($_.Severity)) {
                        'Unknown'
                    } else {
                        ($_.Severity | ForEach-Object {
                            '{0}<br>' -f $_
                        })  -join '<br />'
                    }
                ),
                $(
                    if (-not($_.Impact)) {
                        'Unknown'
                    } else { 
                        ($_.Impact | ForEach-Object {
                            '{0}<br>' -f $_
                        }) -join '<br />'
                    }
                )
            )
        }
        $affectedSoftwareDocumentHtml += $affectedSoftwareNameHeaderTemplate -f @(
            $PN
            $affectedSoftwareTableHtml
        )
    }
    #endregion

    $htmlDocumentTemplate -f @(
        $DocumentTitle.Value           # Title
        $cveSummaryTableHtml           # CVE Summary Rows
        $exploitabilityIndexTableHtml  # Expoitability Rows
        $affectedSoftwareDocumentHtml  # Affected Software Rows
    )

}
End {}
}
# SIG # Begin signature block
# MIIkYAYJKoZIhvcNAQcCoIIkUTCCJE0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcACrDBPxVwV71
# 6wPAWvg3doBkjwNTcK7SzRnliNeKFKCCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
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
# IzCCFh8CAQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAA
# AI6HkaRXGl/KPgAAAAAAjjANBglghkgBZQMEAgEFAKCCAREwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIL3VpJfbrKHkJGlye8SRMSsLqZbaLr/O34Mm/N3+v6ZJMIGk
# BgorBgEEAYI3AgEMMYGVMIGSoEyASgBNAHMAcgBjAFMAZQBjAHUAcgBpAHQAeQBV
# AHAAZABhAHQAZQBzACAAUABvAHcAZQByAFMAaABlAGwAbAAgAE0AbwBkAHUAbABl
# oUKAQGh0dHBzOi8vZ2l0aHViLmNvbS9NaWNyb3NvZnQvTVNSQy1NaWNyb3NvZnQt
# U2VjdXJpdHktVXBkYXRlcy1BUEkwDQYJKoZIhvcNAQEBBQAEggEAhLPvyQI+gvMn
# +skiqWglx+BWv2RXzg12s/cF3QbZNtOJJvmZ/hEN8LvMOuszHV0Gb/muEB88KycI
# vZMNQNHZwjLoSw4SGII6LGY37VKAHRsmNYw8OpWFp4KdKtv3CoGntjTqKvR6y7Oz
# qbzcSPTw9RpWQ3LJ2t6IA//X03kU5ZPQErJeA/DrnMDnXu/oTshbaQW6kRl5KZfH
# IMzJJLHJUvv+8RrthWrJVRiUcs6VPUzqvTZAP7lP/7Vy2mgwOL/HM8lxFW+XwmBQ
# 1OYcN26HVel5IOdxRLQqz/V3Z1y0aHBWvZiErGu4iVeP4MBfzxBe9LBZO9uGYitG
# +tYtK9DuxaGCE0kwghNFBgorBgEEAYI3AwMBMYITNTCCEzEGCSqGSIb3DQEHAqCC
# EyIwghMeAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggE8BgsqhkiG9w0BCRABBKCCASsE
# ggEnMIIBIwIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCB11EYaU9Ns
# UBBZoC1D/zICX6mLuAemp/Or2WF/3UKKAAIGWSXwqkJrGBIyMDE3MDYwMjIzMzIy
# NS41OVowBwIBAYACAfSggbmkgbYwgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNF
# IEVTTjo3MjhELUM0NUYtRjlFQjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaCCDs0wggZxMIIEWaADAgECAgphCYEqAAAAAAACMA0GCSqGSIb3
# DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
# MAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAx
# MDAeFw0xMDA3MDEyMTM2NTVaFw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# qR0NvHcRijog7PwTl/X6f2mUa3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AV
# UycEMR9BGxqVHc4JE458YTBZsTBED/FgiIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN
# 0Or1R4HNvyRgMlhgRvJYR4YyhB50YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvf
# YfxGwScdJGcSchohiq9LZIlQYrFd/XcfPfBXday9ikJNQFHRD5wGPmd/9WbAA5ZE
# fu/QS/1u5ZrKsajyeioKMfDaTgaRtogINeh4HLDpmc085y9Euqf03GS9pAHBIAmT
# eM38vMDJRF1eFpwBBU8iTQIDAQABo4IB5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAw
# HQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvFM2hahW1VMBkGCSsGAQQBgjcUAgQMHgoA
# UwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQY
# MBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6
# Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1
# dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0
# dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3J0MIGgBgNVHSABAf8EgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9
# BggrBgEFBQcCARYxaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQ
# Uy9kZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8A
# bABpAGMAeQBfAFMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOC
# AgEAB+aIUQ3ixuCYP4FxAz2do6Ehb7Prpsz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn
# 8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOMzPRgEop2zEBAQZvcXBf/XPleFzWYJFZL
# dO9CEMivv3/Gf/I3fVo/HPKZeUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6AG9LMEQk
# IjzP7QOllo9ZKby2/QThcJ8ySif9Va8v/rbljjO7Yl+a21dA6fHOmWaQjP9qYn/d
# xUoLkSbiOewZSnFjnXshbcOco6I8+n99lmqQeKZt0uGc+R38ONiU9MalCpaGpL2e
# Gq4EQoO4tYCbIjggtSXlZOz39L9+Y1klD3ouOVd2onGqBooPiRa6YacRy5rYDkea
# gMXQzafQ732D8OE7cQnfXXSYIghh2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fe
# cn5ha293qYHLpwmsObvsxsvYgrRyzR30uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjm
# mC3qjeAzLhIp9cAvVCch98isTtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3Qy
# S99je/WZii8bxyGvWbWu3EQ8l1Bx16HSxVXjad5XwdHeMMD9zOZN+w2/XU/pnR4Z
# OC+8z1gFLu8NoFA12u8JJxzVs341Hgi62jbb01+P3nSISRIwggTaMIIDwqADAgEC
# AhMzAAAAsjUFaDciHA2nAAAAAACyMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQSAyMDEwMB4XDTE2MDkwNzE3NTY1N1oXDTE4MDkwNzE3NTY1
# N1owgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNV
# BAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjo3MjhELUM0NUYtRjlF
# QjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBAJhKAbvRWPV/dJFC6aEuU13yLCBvEi6b
# 09eVldydb4l8DmtwKU2wLg81VvaPAkv4fFVtUM0/x6p48hAHqAdrA7v8K/CqJZ3d
# /PFjcCRlb4T6S0ReznIofcKzH8VvhmqZh666/swFmL5vvhWCR2W3L3XKvNoQeps7
# Mk/aHUiSDiLnsbFCbVnCYp4sKgrwNTcgAgns4RTjtRfjgH5U7l1RDpPZmkozya8m
# Dev2ayOVLz9dEiE3SiTPjr0Pm1M/7unujHB72jv1armZPLfbAXwSyz9VzvSv1ga5
# OjzffCfUcpTNr0oJNsYi7F1zvTrigBod9b13cI1jcHvAwPbunjRph7cCAwEAAaOC
# ARswggEXMB0GA1UdDgQWBBQzZL5naxzc+WNEBkjkxUPJkPaClTAfBgNVHSMEGDAW
# gBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1TdGFQQ0Ff
# MjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBDQV8yMDEw
# LTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0G
# CSqGSIb3DQEBCwUAA4IBAQBB4LKgoMr0KG/Mjd3+270gVYlsICl2dj/UJ8lee4P7
# wcJHNo32eiFMRBs6cWOrIya/RK6iGe8n1liGunpw+i+0S+RxSDpX0rX/oxAbmgnD
# Xx4J6DDNketUXMELWf706lIvqHo1a2C2gzgJppp225az1zWHqGQ6XAbPTBMNxiIY
# twBjjLh1sUXhqUda2//8uxodVDnbFV/mV+Q0nngv/bTcIN/SExCjzj1x2eGwXmVZ
# e45s7pWzmd/wqBxhD0xPV6rWxDH2fA1i62xrAKEKhNJ8cSknIqTYEw/Aesid3To5
# 6t4nBtwEYY48aoSa3062mu2wTOH6UY2AQgWmJvaDbwHmoYIDdjCCAl4CAQEwgeOh
# gbmkgbYwgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTAL
# BgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjo3MjhELUM0NUYt
# RjlFQjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIlCgEB
# MAkGBSsOAwIaBQADFQC9/8WVY5DxE5xg1hnAr+m4nh4gHaCBwjCBv6SBvDCBuTEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEnMCUGA1UECxMebkNpcGhlciBOVFMgRVNOOjRERTktMEM1RS0zRTA5MSswKQYD
# VQQDEyJNaWNyb3NvZnQgVGltZSBTb3VyY2UgTWFzdGVyIENsb2NrMA0GCSqGSIb3
# DQEBBQUAAgUA3NwXYTAiGA8yMDE3MDYwMjE2NTcwNVoYDzIwMTcwNjAzMTY1NzA1
# WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDc3BdhAgEAMAcCAQACAicWMAcCAQAC
# AhjkMAoCBQDc3WjhAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwGg
# CjAIAgEAAgMW42ChCjAIAgEAAgMHoSAwDQYJKoZIhvcNAQEFBQADggEBAD3IpAxq
# KHOZRQEHOioydw9niZFWSByEamcIxAuUfy4xb137UIIrspK0kPgIXIX3UDsCplDl
# Pa8aKmfS7ZLC3F7AN0dFTQTUSoWytnS0tvr+QK0k/tA9YBvYRvOHOAOB//ButwCa
# PA3FD4pfywRXpxCXCsF5kkOuXM3laQBIpblTgo3a64cuPi2SlXIDC35+u1ZR+ICt
# xyficbNgm2+Rg5rtEfoPa7BrjipTA48Q0IySThnihL7xfPvrw53jBsDaOvGwxC5Q
# g1Oa2OyuEwciYOX3dHD9C4gQvnNr7TBK27Cza3XSaaLkGi50C7d/eja4RBngKSWb
# x8RUayFPNvYI9agxggL1MIIC8QIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAALI1BWg3IhwNpwAAAAAAsjANBglghkgBZQMEAgEFAKCCATIw
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAwGBT2
# tpi1SOzc3wAd58YMtwF/wvl3bTumew/Uq/FqzjCB4gYLKoZIhvcNAQkQAgwxgdIw
# gc8wgcwwgbEEFL3/xZVjkPETnGDWGcCv6bieHiAdMIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAACyNQVoNyIcDacAAAAAALIwFgQUwVmz
# /We1La8K9le1fohs0KiivuUwDQYJKoZIhvcNAQELBQAEggEAbPZD2I62rtIh7JDE
# BOA7sPAznWCWDPEeZowYcqBLRL/4u6vk1kZgzPOIf8sGXBV2pXA1e9peR8TtJ423
# PN6GB40tr1DsVYlNaSpXm4GeE3c3sMZjmhIeUUTXXgIVJisNRelmJi5F5DkvaHDz
# IyTv3pt/176+RVI+eidMz9hI7ah+c3sfyT1w7RvXUTaJx3TIs0/tdB2ZjGfoFHrX
# nb588xxsloExLcv7crfjwnUoRAyk+i6be3otgdcKxu6jvW3jBt46CjqNRlTyJp6R
# inON/N10PlLRo8RbPuMIxHpzONZtWkl1HFxXP+PDyv1dl811VxRqpsKb5TiwHmEG
# 78YkPw==
# SIG # End signature block

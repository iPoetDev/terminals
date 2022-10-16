#Requires -Version 3.0
# Also requires .NET Version 4.7.2 or above

$ServiceUnavailableRetryTimeoutInSeconds = 30
$WaitForCompletionRetryTimeoutInSeconds = 5
$DefaultHttpClientTimeoutInSeconds = 100

<#
.SYNOPSIS
  Submits a new signing request or resubmits an existing one via the SignPath REST API.
.DESCRIPTION
  The Submit-SigningRequest cmdlet either submits a new signing request (with the specified InputArtifactPath) or resubmits (-Resubmit switch) an
  existing one (with the specified OriginalSigningRequestId) via the SignPath REST API.
  When passing the -WaitForCompletion switch the command also waits for the signing request to complete, downloads the signed file and stores it in
  the path specified by the OutputArtifactPath argument.  Otherwise the result of the submitted signing request can be downloaded with
  the Get-SignedArtifact command.

  To tweak timing issues use the parameters ServiceUnavailableTimeoutInSeconds, UploadAndDownloadRequestTimeoutInSeconds and WaitForCompletionTimeoutInSeconds.
.EXAMPLE
  Submit-SigningRequest `
    -InputArtifactPath Program.exe `
    -CIUserToken /Joe3s2m7hkhVyoba4H4weqj9UxIk6nKRXGhGbH7nv4= `
    -OrganizationId 1c0ab26c-12f3-4c6e-a043-2568e133d2de `
    -ProjectSlug myProject `
    -SigningPolicySlug testSigning `
    -OutputArtifactPath Program.signed.exe `
    -WaitForCompletion
.EXAMPLE
  Submit-SigningRequest `
    -CIUserToken /Joe3s2m7hkhVyoba4H4weqj9UxIk6nKRXGhGbH7nv4= `
    -OrganizationId 1c0ab26c-12f3-4c6e-a043-2568e133d2de `
    -Resubmit `
    -OriginalSigningRequestId 86e6b7ff-24aa-4404-9905-2b48c0e2b258 `
    -OutputArtifactPath Program.signed.exe `
    -WaitForCompletion
.OUTPUTS
  Returns the SigningRequestId which can be used with Get-SignedArtifact.
.NOTES
  Author: SignPath GmbH
.LINK
  https://about.signpath.io/documentation/powershell/Submit-SigningRequest
#>
function Submit-SigningRequest {
  [CmdletBinding(DefaultParameterSetName = 'Submit')]
  Param(
    # The URL to the API, e.g. 'https://app.signpath.io/api/'.
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $ApiUrl = "https://app.signpath.io/api/",

    # The API token you retrieve when adding a new CI user.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $CIUserToken,

    # The ID of the organization containing the signing policy.
    # Go to "Project > Signing policy" in the web client and copy the first ID from the URL to retrieve this value (e.g. https://app.signpath.io/<OrganizationId>/SigningPolicies/<SigningPolicyId>).
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OrganizationId,

    # If you use IDs to reference the artifact configuration and signing policy: this is the ID of the artifact configuration you want to use for
    # signing. If not given, the default artifact configuration will be used instead.
    # Go to "Project -> Artifact configuration" in the web client and copy the last ID from the URL to retrieve this value (e.g. https://app.signpath.io/<OrganizationId>/ArtifactConfigurations/<ArtifactConfigurationId>).
    [Parameter(ParameterSetName = 'Submit')]
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [string] $ArtifactConfigurationId,

    # If you use IDs to reference the artifact configuration and signing policy: this is the ID of the signing policy you want to use for signing.
    # Go to "Project > Signing policy" in the web client and copy the last ID from the URL to retrieve this value (e.g. https://app.signpath.io/<OrganizationId>/SigningPolicies/<SigningPolicyId>).
    [Parameter()]
    [string] $SigningPolicyId,

    # If you use slugs to reference the artifact configuration and signing policy: this is the project in which the artifact configuration and signing
    # policy reside in.
    [Parameter(ParameterSetName = 'Submit')]
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Alias("ProjectKey")]
    [string] $ProjectSlug,

    # If you use slugs to reference the artifact configuration and signing policy: this is the slug of the artifact configuration you want to use for
    # signing. If not given, the default artifact configuration will be used instead.
    [Parameter(ParameterSetName = 'Submit')]
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Alias("ArtifactConfigurationKey")]
    [string] $ArtifactConfigurationSlug,

    # If you use slugs to reference the artifact configuration and signing policy: this is the slug of the signing policy you want to use for signing.
    [Parameter()]
    [Alias("SigningPolicyKey")]
    [string] $SigningPolicySlug,

    # Specifies the path of the artifact that you want to be signed.
    [Parameter(Mandatory, ParameterSetName = 'Submit')]
    [Parameter(Mandatory, ParameterSetName = 'Submit_WaitForCompletion')]
    [ValidateNotNullOrEmpty()]
    [string] $InputArtifactPath,

    # An optional description of the uploaded artifact that could be helpful to the approver.
    [Parameter()]
    [string] $Description,

    # Information about the origin of the artifact (e.g. source code repository, commit ID, etc). See https://about.signpath.io/documentation/powershell#submit-signingrequest
    [Parameter(ParameterSetName = 'Submit')]
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Hashtable] $Origin,

    # Provide values for parameters defined in the artifact configuration. See https://about.signpath.io/documentation/artifact-configuration#user-defined-parameters
    [Parameter(ParameterSetName = 'Submit')]
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Hashtable] $Parameters,

    # Client certificate that's used for a secure Web API request. Not supported by SignPath.io directly, use for proxies.
    [Parameter()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,

    # The total time in seconds that the cmdlet will wait for a single service call to succeed (across several retries). Defaults to 600 seconds.
    [Parameter()]
    [int] $ServiceUnavailableTimeoutInSeconds = 600,

    # The HTTP timeout used for upload and download HTTP requests. Defaults to 300 seconds.
    [Parameter()]
    [int] $UploadAndDownloadRequestTimeoutInSeconds = 300,

    [Parameter(Mandatory, ParameterSetName = 'Resubmit')]
    [Parameter(Mandatory, ParameterSetName = 'Resubmit_WaitForCompletion')]
    [switch] $Resubmit,

    # The original signing request's ID of that should be resubmitted.
    [Parameter(Mandatory, ParameterSetName = 'Resubmit')]
    [Parameter(Mandatory, ParameterSetName = 'Resubmit_WaitForCompletion')]
    [ValidateNotNullOrEmpty()]
    [string] $OriginalSigningRequestId,

    [Parameter(Mandatory, ParameterSetName = 'Submit_WaitForCompletion')]
    [Parameter(Mandatory, ParameterSetName = 'Resubmit_WaitForCompletion')]
    [switch] $WaitForCompletion,

    # Specifies the path of the downloaded signed artifact (result file). If this is not given, the InputArtifactPath with an added ".signed" extension is used (e.g. "Input.dll" => "Input.signed.dll").
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Parameter(Mandatory, ParameterSetName = 'Resubmit_WaitForCompletion')]
    [ValidateNotNullOrEmpty()]
    [string] $OutputArtifactPath,

    # The maximum time in seconds that the cmdlet will wait for the signing request to complete (upload and download have no specific timeouts). Defaults to 600 seconds.
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Parameter(ParameterSetName = 'Resubmit_WaitForCompletion')]
    [int] $WaitForCompletionTimeoutInSeconds = 600,

    # Allows the cmdlet to overwrite the file at OutputArtifactPath.
    [Parameter(ParameterSetName = 'Submit_WaitForCompletion')]
    [Parameter(ParameterSetName = 'Resubmit_WaitForCompletion')]
    [switch] $Force
  )

  Set-StrictMode -Version 2.0

  $ApiUrl = GetVersionedApiUrl $ApiUrl
  Write-Verbose "Using versioned API URL: $ApiUrl"

  if($Resubmit.IsPresent) {
    $resubmitUrl = [string]::Join("/", @($ApiUrl.Trim("/"), $OrganizationId, "SigningRequests", "Resubmit"))
    $requestFactory = CreateResubmitRequestFactory `
      -url $resubmitUrl `
      -originalSigningRequestId $OriginalSigningRequestId `
      -signingPolicySlug $SigningPolicySlug `
      -description $Description

    return SubmitHelper "Resubmit" "Resubmitted" $requestFactory `
      -ciUserToken $CIUserToken `
      -clientCertificate $ClientCertificate `
      -defaultHttpClientTimeoutInSeconds $DefaultHttpClientTimeoutInSeconds `
      -uploadAndDownloadRequestTimeoutInSeconds $UploadAndDownloadRequestTimeoutInSeconds `
      -waitForCompletionTimeoutInSeconds $WaitForCompletionTimeoutInSeconds `
      -waitForCompletion $WaitForCompletion.IsPresent `
      -outputArtifactPath $OutputArtifactPath `
      -force $Force.IsPresent
  } else {
    $InputArtifactPath = PrepareInputArtifactPath $InputArtifactPath
    Write-Verbose "Using input artifact: $InputArtifactPath"

    $hash = (Get-FileHash -Path $InputArtifactPath -Algorithm "SHA256").Hash
    Write-Host "SHA256 hash: $hash"

    if (-not $OutputArtifactPath) {
      $extension = [System.IO.Path]::GetExtension($InputArtifactPath)
      $OutputArtifactPath = [System.IO.Path]::ChangeExtension($InputArtifactPath, "signed$extension")
    }

    $submitUrl = [string]::Join("/", @($ApiUrl.Trim("/"), $OrganizationId, "SigningRequests"))
    $requestFactory = CreateSubmitRequestFactory `
      -url $submitUrl `
      -artifactConfigurationId $ArtifactConfigurationId `
      -signingPolicyId $SigningPolicyId `
      -projectSlug $ProjectSlug `
      -artifactConfigurationSlug $ArtifactConfigurationSlug `
      -signingPolicySlug $SigningPolicySlug `
      -description $Description `
      -inputArtifactPath $InputArtifactPath `
      -origin $Origin `
      -parameters $Parameters

    return SubmitHelper "Submit" "Submitted" $requestFactory `
      -ciUserToken $CIUserToken `
      -clientCertificate $ClientCertificate `
      -defaultHttpClientTimeoutInSeconds $DefaultHttpClientTimeoutInSeconds `
      -uploadAndDownloadRequestTimeoutInSeconds $UploadAndDownloadRequestTimeoutInSeconds `
      -waitForCompletionTimeoutInSeconds $WaitForCompletionTimeoutInSeconds `
      -waitForCompletion $WaitForCompletion.IsPresent `
      -outputArtifactPath $OutputArtifactPath `
      -force $Force.IsPresent
  }
}

<#
.SYNOPSIS
    Tries to download a signed artifact based on a SigningRequestId.
.DESCRIPTION
    Waits for a given signing request until its processing has finished and downloads the resultiung artifact.
    If the request couldn't be downloaded in time, because the processing took to long or the request is invalid,
    this function throws exceptions.

    To tweak timing issues use the parameters ServiceUnavailableTimeoutInSeconds, UploadAndDownloadRequestTimeoutInSeconds and WaitForCompletionTimeoutInSeconds.
.EXAMPLE
    Get-SignedArtifact `
      -OutputArtifactPath Program.exe `
      -CIUserToken /Joe3s2m7hkhVyoba4H4weqj9UxIk6nKRXGhGbH7nv4= `
      -OrganizationId 1c0ab26c-12f3-4c6e-a043-2568e133d2de `
      -SigningRequestId 711960ed-bdb8-41cd-a6bf-a10d0ae3cfcd
.OUTPUTS
    Returns void but creates a file in the given OutputArtifactPath on success.
.NOTES
  Author: SignPath GmbH
.LINK
  https://about.signpath.io/documentation/powershell/Get-SignedArtifact
#>
function Get-SignedArtifact {
  [CmdletBinding()]
  Param(
    # The URL to the API, e.g. https://app.signpath.io/api/.
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $ApiUrl = "https://app.signpath.io/api/",

    # The API token you retrieve when adding a new CI user.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $CIUserToken,

    # The ID of the organization containing the signing policy.
    # Go to "Project > Signing policy" in the web client and copy the first ID from the URL to retrieve this value (e.g. https://app.signpath.io/<OrganizationId>/SigningPolicies/<SigningPolicyId>).
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OrganizationId,

    # The ID of the SigningRequest that contains the desired artifact
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SigningRequestId,

    # Specifies the path of the downloaded signed artifact (result file).
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputArtifactPath,

    # Client certificate that's used for a secure Web API request. Not supported by SignPath.io directly, use for proxies.
    [Parameter()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,

    # The total time in seconds that the cmdlet will wait for a service call to succeed (across several retries). Defaults to 600 seconds.
    [Parameter()]
    [int] $ServiceUnavailableTimeoutInSeconds = 600,

    # The HTTP timeout used for upload and download HTTP requests. Defaults to 300 seconds.
    [Parameter()]
    [int] $UploadAndDownloadRequestTimeoutInSeconds = 300,

    # The maximum time in seconds that the cmdlet will wait for the signing request to complete. Defaults to 600 seconds.
    [Parameter()]
    [int] $WaitForCompletionTimeoutInSeconds = 600,

    # Allows the cmdlet to overwrite the file at OutputArtifactPath.
    [Parameter()]
    [switch] $Force
  )

  Set-StrictMode -Version 2.0

  $ApiUrl = GetVersionedApiUrl $ApiUrl
  Write-Verbose "Using versioned API URL: $ApiUrl"

  $OutputArtifactPath = PrepareOutputArtifactPath $Force $OutputArtifactPath
  Write-Verbose "Will write signed artifact to: $OutputArtifactPath"

  CreateAndUseAuthorizedHttpClient $CIUserToken -ClientCertificate $ClientCertificate -Timeout $DefaultHttpClientTimeoutInSeconds {
    Param ([System.Net.Http.HttpClient] $defaultHttpClient)

    CreateAndUseAuthorizedHttpClient $CIUserToken -Timeout $UploadAndDownloadRequestTimeoutInSeconds {
      Param ([System.Net.Http.HttpClient] $uploadAndDownloadHttpClient)

      $expectedSigningRequestUrl = [string]::Join("/", @($ApiUrl.Trim("/"), $OrganizationId, "SigningRequests", $SigningRequestId))

      $downloadUrl = WaitForCompletionAndRetrieveSignedArtifactDownloadLink `
        -httpClient $defaultHttpClient `
        -url $expectedSigningRequestUrl `
        -WaitForCompletionTimeoutInSeconds $WaitForCompletionTimeoutInSeconds `
        -WaitForCompletionRetryTimeoutInSeconds $WaitForCompletionRetryTimeoutInSeconds `
        -ServiceUnavailableRetryTimeoutInSeconds $ServiceUnavailableRetryTimeoutInSeconds

      DownloadArtifact `
        -HttpClient $uploadAndDownloadHttpClient `
        -Url $downloadUrl `
        -Path $OutputArtifactPath `
        -ServiceUnavailableRetryTimeoutInSeconds $ServiceUnavailableRetryTimeoutInSeconds
    }
  }
}

function GetVersionedApiUrl ([string] $apiUrl) {
  $supportedApiVersion = "v1"
  return [string]::Join("/", @($apiUrl.Trim("/"), $supportedApiVersion))
}

function SubmitHelper ([string] $verb,
                       [string] $verbPastTense,
                       [ScriptBlock] $requestFactory,
                       [string] $ciUserToken,
                       [System.Security.Cryptography.X509Certificates.X509Certificate2] $clientCertificate,
                       [int] $defaultHttpClientTimeoutInSeconds,
                       [int] $uploadAndDownloadRequestTimeoutInSeconds,
                       [int] $waitForCompletionTimeoutInSeconds,
                       [bool] $waitForCompletion,
                       [string] $outputArtifactPath,
                       [bool] $force) {
  CreateAndUseAuthorizedHttpClient $ciUserToken -ClientCertificate $clientCertificate -Timeout $defaultHttpClientTimeoutInSeconds {
    Param ([System.Net.Http.HttpClient] $defaultHttpClient)

    CreateAndUseAuthorizedHttpClient $ciUserToken -ClientCertificate $clientCertificate -Timeout $uploadAndDownloadRequestTimeoutInSeconds {
      Param ([System.Net.Http.HttpClient] $uploadAndDownloadHttpClient)

      if ($waitForCompletion) {
        $outputArtifactPath = PrepareOutputArtifactPath $force $outputArtifactPath
        Write-Verbose "Will write output artifact to: $outputArtifactPath"
      }

      $response = $null
      try {
        Write-Verbose "$verb signing request..."
        $response = SendWithRetry `
          -HttpClient $HttpClient `
          -RequestFactory $requestFactory `
          -ServiceUnavailableRetryTimeoutInSeconds $ServiceUnavailableRetryTimeoutInSeconds
        CheckResponse $response

        $getUrl = $response.Headers.Location.AbsoluteUri
        Write-Host "$verbPastTense signing request at '$getUrl'"
      } finally {
        if ((Test-Path variable:response) -and $null -ne $response) {
          $response.Dispose()
        }
      }

      if ($waitForCompletion) {
        $downloadUrl = WaitForCompletionAndRetrieveSignedArtifactDownloadLink `
          -HttpClient $defaultHttpClient `
          -Url $getUrl `
          -WaitForCompletionTimeoutInSeconds $waitForCompletionTimeoutInSeconds `
          -WaitForCompletionRetryTimeoutInSeconds $WaitForCompletionRetryTimeoutInSeconds `
          -ServiceUnavailableRetryTimeoutInSeconds $ServiceUnavailableRetryTimeoutInSeconds

        DownloadArtifact `
          -HttpClient $uploadAndDownloadHttpClient `
          -Url $downloadUrl `
          -Path $outputArtifactPath `
          -ServiceUnavailableRetryTimeoutInSeconds $ServiceUnavailableRetryTimeoutInSeconds
      }

      $guidRegex = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
      $pattern = [regex]"SigningRequests/($guidRegex)"
      $getUrl -match $pattern | Out-Null
      $signingRequestId = $matches[1]
      Write-Verbose "Parsed signing request ID: $signingRequestId"
      return $signingRequestId
    }
  }
}

function CreateSubmitRequestFactory (
  [string] $url,
  [string] $artifactConfigurationId,
  [string] $signingPolicyId,
  [string] $projectSlug,
  [string] $artifactConfigurationSlug,
  [string] $signingPolicySlug,
  [string] $description,
  [string] $inputArtifactPath,
  [Hashtable] $origin,
  [Hashtable] $parameters
) {
  $local:IsVerboseEnabled = $null -ne $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -and $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

  return {
    if ($IsVerboseEnabled) {
      $VerbosePreference = "Continue"
    }

    function AddContent ($content, $baseKey, $key, $value) {
      # All parameters ending in "File" are interpreted as streams
      if ( $key.ToLower().EndsWith("file")) {
        if ( $value.StartsWith("@")) {
          $filePath = $value.Substring(1)
          $packageFileStream = New-Object System.IO.FileStream ($filePath, [System.IO.FileMode]::Open)
          $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
          # PLANNED SIGN-988 This shouldn't be needed anymore
          $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "application/octet-stream"
          $fileName = [System.IO.Path]::GetFileName($filePath)
          $content.Add($streamContent, "$baseKey.$key", $fileName)
          Write-Verbose "Adding file content to origin: $baseKey.$key = $fileName"
        } else {
          # IDEA: We will later on support non-file parameter values here too, for now we throw
          throw "*File origin parameters must start with @ to indicate a file path"
        }
      } else {
        $stringContent = New-Object System.Net.Http.StringContent $value
        $content.Add($stringContent, "$baseKey.$key")
        Write-Verbose "Add normal content to origin: $baseKey.$key = $value"
      }
    }

    function AddAllHashTableContent ($content, $hashtable, $baseKey) {
      Write-Verbose "Recursive add origin base key: $baseKey"
      foreach ($kvp in $hashtable.GetEnumerator()) {
        if ($kvp.Value.GetType().Name -eq "Hashtable") {
          Write-Verbose "$($kvp.Key) is a Hashtable, enter next recursion level"
          AddAllHashTableContent $content $kvp.Value "$baseKey.$($kvp.Key)"
        }
        else {
          AddContent $content $baseKey $kvp.Key $kvp.Value
        }
      }
    }

    function AddAllHashTableParameters ($content, $hashtable, $baseKey) {
      foreach ($kvp in $hashtable.GetEnumerator()) {
        $parameterContent = New-Object System.Net.Http.StringContent $kvp.Value
        $content.Add($parameterContent, "$baseKey.$($kvp.Key)")
      }
    }

    $content = New-Object System.Net.Http.MultipartFormDataContent

    try {
      if ($artifactConfigurationId) {
        Write-Verbose "ArtifactConfigurationId: $artifactConfigurationId"
        $artifactConfigurationIdContent = New-Object System.Net.Http.StringContent $artifactConfigurationId
        $content.Add($artifactConfigurationIdContent, "ArtifactConfigurationId")
      }

      if ($signingPolicyId) {
        Write-Verbose "SigningPolicyId: $signingPolicyId"
        $signingPolicyIdContent = New-Object System.Net.Http.StringContent $signingPolicyId
        $content.Add($signingPolicyIdContent, "SigningPolicyId")
      }

      if ($projectSlug) {
        Write-Verbose "ProjectSlug: $projectSlug"
        $projectSlugContent = New-Object System.Net.Http.StringContent $projectSlug
        $content.Add($projectSlugContent, "ProjectSlug")
      }

      if ($artifactConfigurationSlug) {
        Write-Verbose "ArtifactConfigurationSlug: $artifactConfigurationSlug"
        $artifactConfigurationSlugContent = New-Object System.Net.Http.StringContent $artifactConfigurationSlug
        $content.Add($artifactConfigurationSlugContent, "ArtifactConfigurationSlug")
      }

      if ($signingPolicySlug) {
        Write-Verbose "SigningPolicySlug: $signingPolicySlug"
        $signingPolicySlugContent = New-Object System.Net.Http.StringContent $signingPolicySlug
        $content.Add($signingPolicySlugContent, "SigningPolicySlug")
      }

      Write-Verbose "Description: $description"
      $descriptionContent = New-Object System.Net.Http.StringContent $description
      $content.Add($descriptionContent, "Description")

      $packageFileStream = New-Object System.IO.FileStream ($inputArtifactPath, [System.IO.FileMode]::Open)
      $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
      # PLANNED SIGN-988 This shouldn't be needed anymore
      $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "application/octet-stream"
      $fileName = [System.IO.Path]::GetFileName($inputArtifactPath)
      $content.Add($streamContent, "Artifact", $fileName)
      Write-Verbose "Artifact: $fileName"

      if ($origin) {
        Write-Verbose "Adding all origin parameters..."
        AddAllHashTableContent $content $origin "Origin"
      }

      if ($parameters) {
        Write-Verbose "Adding all signing request parameters..."
        AddAllHashTableParameters $content $parameters "Parameters"
      }

      $request = New-Object System.Net.Http.HttpRequestMessage Post, $url
      $request.Content = $content

      Write-Verbose "Request URL: $url"
      return $request
      # Only dispose the content in case of exceptions, otherwise the caller is responsible for disposing the whole request after it has been performed.
    } catch {
      $content.Dispose()
      throw
    }
  }.GetNewClosure()
}

function CreateResubmitRequestFactory (
  [string] $url,
  [string] $originalSigningRequestId,
  [string] $signingPolicySlug,
  [string] $description
) {
  $local:IsVerboseEnabled = $null -ne $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -and $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

  return {
    if ($IsVerboseEnabled) {
      $VerbosePreference = "Continue"
    }

    $content = New-Object System.Net.Http.MultipartFormDataContent

    try {

      Write-Verbose "OriginalSigningRequestId: $originalSigningRequestId"
      $originalSigningRequestIdContent = New-Object System.Net.Http.StringContent $originalSigningRequestId
      $content.Add($originalSigningRequestIdContent, "OriginalSigningRequestId")

      Write-Verbose "SigningPolicySlug: $signingPolicySlug"
      $signingPolicySlugContent = New-Object System.Net.Http.StringContent $signingPolicySlug
      $content.Add($signingPolicySlugContent, "SigningPolicySlug")

      Write-Verbose "Description: $description"
      $descriptionContent = New-Object System.Net.Http.StringContent $description
      $content.Add($descriptionContent, "Description")

      $request = New-Object System.Net.Http.HttpRequestMessage Post, $url
      $request.Content = $content

      Write-Verbose "Request URL: $url"
      return $request
      # Only dispose the content in case of exceptions, otherwise the caller is responsible for disposing the whole request after it has been performed.
    } catch {
      $content.Dispose()
      throw
    }
  }.GetNewClosure()
}

function GetWithRetry ([System.Net.Http.HttpClient] $httpClient, [string] $url, [int] $serviceUnavailableRetryTimeoutInSeconds) {
  $response = SendWithRetry `
    -HttpClient $httpClient `
    -RequestFactory { New-Object System.Net.Http.HttpRequestMessage Get, $url }.GetNewClosure() `
    -ServiceUnavailableRetryTimeoutInSeconds $serviceUnavailableRetryTimeoutInSeconds
  return $response
}

function SendWithRetry (
  [System.Net.Http.HttpClient] $httpClient,
  [ScriptBlock] $requestFactory,
  [int] $serviceUnavailableRetryTimeoutInSeconds) {

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $retry = 0

  while ($true) {
    $retryReason = $null

    if ($retry -gt 0) {
      Write-Host "Retry $retry..."
    }

    $request = $null
    try {
      Write-Verbose "Generating request..."
      $request = & $requestFactory

      Write-Verbose "HttpClient timeout: $($httpClient.Timeout)"
      Write-Verbose "Sending request..."
      $response = $httpClient.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

      Write-Verbose "Response status code: $($response.StatusCode)"
      if (503 -eq $response.StatusCode) {
        $retryReason = "SignPath REST API is temporarily unavailable. Please try again in a few moments."
      } elseif(500 -le $response.StatusCode -and 600 -gt $response.StatusCode) {
        $retryReason = "SignPath REST API returned an unexpected status code ($($response.StatusCode))"
      } else {
        return $response
      }
    } catch [System.Net.Http.HttpRequestException] {
      Write-Verbose "Request failed with HttpRequestException"
      $retryReason = $_
      Write-Host "URL: " $request.RequestUri
      Write-Host "EXCEPTION: " $_.Exception
    } catch [System.Threading.Tasks.TaskCanceledException] {
      Write-Verbose "Request failed with TaskCanceledException"
      $retryReason = "SignPath REST API answer time exceeded the timeout ($($HttpClient.Timeout))"
      Write-Host "URL: " $request.RequestUri
      Write-Host "EXCEPTION: " $_.Exception
    } finally {
      Write-Verbose "Disposing request"
      if ($null -ne $request) {
        $request.Dispose()
      }
    }

    Write-Verbose "Retry reason: $retryReason"

    if (($sw.Elapsed.TotalSeconds + $serviceUnavailableRetryTimeoutInSeconds) -lt $ServiceUnavailableTimeoutInSeconds) {
      Write-Host "SignPath REST API call failed. Retrying in ${serviceUnavailableRetryTimeoutInSeconds}s..."
      Start-Sleep -Seconds $serviceUnavailableRetryTimeoutInSeconds
    } else {
      Write-Host "SignPath REST API could not be called successfully in $($retry + 1) tries. Aborting"
      throw $retryReason
    }

    $retry++
  }
}

function DownloadArtifact (
  [System.Net.Http.HttpClient] $httpClient,
  [string] $url,
  [string] $path,
  [int] $serviceUnavailableRetryTimeoutInSeconds) {

  $downloadResponse = $null
  $streamToWriteTo = $null
  try {
    Write-Host "Downloading signed artifact..."
    $downloadResponse = GetWithRetry `
      -HttpClient $httpClient `
      -Url $url `
      -ServiceUnavailableRetryTimeoutInSeconds $serviceUnavailableRetryTimeoutInSeconds
    CheckResponse $downloadResponse

    $pathWithoutFile = [System.IO.Path]::GetDirectoryName($path)
    [System.IO.Directory]::CreateDirectory($pathWithoutFile) | Out-Null

    $stream = $downloadResponse.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
    $streamToWriteTo = [System.IO.File]::Open($path, 'Create')
    $stream.CopyToAsync($streamToWriteTo).GetAwaiter().GetResult() | Out-Null
    Write-Host "Downloaded signed artifact and saved at '$path'"
  } finally {
    if ((Test-Path variable:downloadResponse) -and $null -ne $downloadResponse) {
      $downloadResponse.Dispose()
    }

    if ((Test-Path variable:stream) -and $null -ne $stream) {
      $stream.Dispose()
    }

    if ((Test-Path variable:streamToWriteTo) -and $null -ne $streamToWriteTo) {
      $streamToWriteTo.Dispose()
    }
  }
}

function WaitForCompletionAndRetrieveSignedArtifactDownloadLink (
  [System.Net.Http.HttpClient] $httpClient,
  [string] $url,
  [int] $waitForCompletionTimeoutInSeconds,
  [int] $waitForCompletionRetryTimeoutInSeconds,
  [int] $serviceUnavailableRetryTimeoutInSeconds) {

  $StatusComplete = "Completed"
  $StatusFailed = "Failed"
  $StatusDenied = "Denied"
  $StatusCanceled = "Canceled"
  $WorkflowStatusArtifactRetrievalFailed = "ArtifactRetrievalFailed"

  $getResponse = $null
  try {
    $resultJson = $null
    $status = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
      Write-Host "Checking status... " -NoNewline

      $getResponse = GetWithRetry -HttpClient $httpClient -Url $url -ServiceUnavailableRetryTimeoutInSeconds $serviceUnavailableRetryTimeoutInSeconds

      CheckResponse $getResponse
      $resultJson = $getResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
      $status = $resultJson.status
      $workflowStatus = $resultJson.workflowStatus
      Write-Host $status

      if ($resultJson.isFinalStatus) {
        break
      }

      Write-Verbose "Waiting for $waitForCompletionRetryTimeoutInSeconds seconds until checking again..."
      Start-Sleep -Seconds $waitForCompletionRetryTimeoutInSeconds
    } while ($sw.Elapsed.TotalSeconds -lt $waitForCompletionTimeoutInSeconds)

    $timeoutExpired = $sw.Elapsed.TotalSeconds -ge $waitForCompletionTimeoutInSeconds
    if ($status -ne $StatusComplete) {
      if ($status -eq $StatusDenied) {
        throw "Terminating because signing request was denied"
      } elseif ($status -eq $StatusCanceled) {
        throw "Terminating because signing request was canceled"
      } elseif ($workflowStatus -eq $WorkflowStatusArtifactRetrievalFailed) {
        throw "Terminating because artifact retrieval failed"
      } elseif ($status -eq $StatusFailed) {
        throw "Terminating because signing request failed"
      } elseif ($timeoutExpired) {
        throw "Timeout expired while waiting for signing request to complete"
      } else {
        throw "Terminating because of unexpected signing request status: $status"
      }
    }

    if($resultJson.PSObject.Properties.Name -contains "signedArtifactLink") {
      return $resultJson.signedArtifactLink
    }

    throw "Downloading the signed artifact is not possible since the signing request's artifacts have been deleted."
  } finally {
    if ((Test-Path variable:getResponse) -and $null -ne $getResponse) {
      $getResponse.Dispose()
    }
  }
}

function CreateAndUseAuthorizedHttpClient ([string] $cIUserToken, [int] $timeout, [ScriptBlock] $scriptBlock, [System.Security.Cryptography.X509Certificates.X509Certificate2] $clientCertificate) {
  Add-Type -AssemblyName System.IO
  Add-Type -AssemblyName System.Net.Http

  $previousSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

  $httpClientHandler = New-Object System.Net.Http.HttpClientHandler
  if ($null -ne $clientCertificate) {
    if (-not $clientCertificate.HasPrivateKey) {
      throw "The given client certificate has not private key and therefore cannot be used as client certificate."
    }

    Write-Verbose "Adding HttpClient client certificate: $clientCertificate"
    $httpClientHandler.ClientCertificates.Add($clientCertificate) | Out-Null
  }

  $httpClient = New-Object System.Net.Http.HttpClient $httpClientHandler
  $httpClient.Timeout = [TimeSpan]::FromSeconds($timeout)
  $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue @("Bearer", $cIUserToken)

  try {
    & $scriptBlock $httpClient
  } finally {
    if ($null -ne $httpClient) {
      $httpClient.Dispose()
    }
    [System.Net.ServicePointManager]::SecurityProtocol = $previousSecurityProtocol
  }
}

function PrepareInputArtifactPath ([string] $inputArtifactPath) {
  $inputArtifactPath = NormalizePath $inputArtifactPath

  if (-not (Test-Path -Path $inputArtifactPath)) {
    throw "The input artifact path '$inputArtifactPath' does not exist"
  }
  return $inputArtifactPath
}

function PrepareOutputArtifactPath ([bool] $force, [string] $outputArtifactPath) {
  $outputArtifactPath = NormalizePath $outputArtifactPath

  if (-not $force -and (Test-Path -Path $outputArtifactPath)) {
    throw "There is already a file at '$outputArtifactPath'. If you want to overwrite it use the -Force switch"
  }
  return $outputArtifactPath
}

function NormalizePath ([string] $path) {
  if (-not [System.IO.Path]::IsPathRooted($path)) {
    return Join-Path $PWD $path
  }
  return $path
}

function CheckResponse ([System.Net.Http.HttpResponseMessage] $response) {
  Write-Verbose "Checking response: $response"
  if (-not $response.IsSuccessStatusCode) {
    Write-Verbose "No success response."
    $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

    $additionalReason = ""
    if (401 -eq $response.StatusCode) {
      $additionalReason = " Did you provide the correct CIUserToken?"
    }
    elseif(403 -eq $response.StatusCode) {
      $additionalReason = " Did you add the CI user to the list of submitters in the specified signing policy? Did you provide the correct OrganizationId? In case you are using a trusted build system, did you link it to the specified project?"
    }

    $serverMessage = ""
    if ($responseBody -ne "") {
      $serverMessage = " (Server reported the following message: '" + $responseBody + "')"
    }

    $errorMessage = "Error {0} {1}.{2}{3}" -f $response.StatusCode.value__, $response.ReasonPhrase, $additionalReason, $serverMessage

    throw [System.Net.Http.HttpRequestException]$errorMessage
  }
}

Export-ModuleMember Submit-SigningRequest
Export-ModuleMember Get-SignedArtifact
# SIG # Begin signature block
# MIIoBAYJKoZIhvcNAQcCoIIn9TCCJ/ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCxIT5pOAAX6S8L
# nO4KSjrcrWJ8ctJ71YF/U83RCB4PBaCCDakwggNfMIICR6ADAgECAgsEAAAAAAEh
# WFMIojANBgkqhkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3Qg
# Q0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2ln
# bjAeFw0wOTAzMTgxMDAwMDBaFw0yOTAzMTgxMDAwMDBaMEwxIDAeBgNVBAsTF0ds
# b2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYD
# VQQDEwpHbG9iYWxTaWduMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# zCV2kHkGeCIW9cCDtoTKKJ79BXYRxa2IcvxGAkPHsoqdBF8kyy5L4WCCRuFSqwyB
# R3Bs3WTR6/Usow+CPQwrrpfXthSGEHm7OxOAd4wI4UnSamIvH176lmjfiSeVOJ8G
# 1z7JyyZZDXPesMjpJg6DFcbvW4vSBGDKSaYo9mk79svIKJHlnYphVzesdBTcdOA6
# 7nIvLpz70Lu/9T0A4QYz6IIrrlOmOhZzjN1BDiA6wLSnoemyT5AuMmDpV8u5BJJo
# aOU4JmB1sp93/5EU764gSfytQBVI0QIxYRleuJfvrXe3ZJp6v1/BE++bYvsNbOBU
# aRapA9pu6YOTcXbGaYWCFwIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
# AQH/BAUwAwEB/zAdBgNVHQ4EFgQUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZI
# hvcNAQELBQADggEBAEtA28BQqv7IDO/3llRFSbuWAAlBrLMThoYoBzPKa+Z0uboA
# La6kCtP18fEPir9zZ0qDx0R7eOCvbmxvAymOMzlFw47kuVdsqvwSluxTxi3kJGy5
# lGP73FNoZ1Y+g7jPNSHDyWj+ztrCU6rMkIrp8F1GjJXdelgoGi8d3s0AN0GP7URt
# 11Mol37zZwQeFdeKlrTT3kwnpEwbc3N29BeZwh96DuMtCK0KHCz/PKtVDg+Rfjbr
# w1dJvuEuLXxgi8NBURMjnc73MmuUAaiZ5ywzHzo7JdKGQM47LIZ4yWEvFLru21Vv
# 34TuBQlNvSjYcs7TYlBlHuuSl4Mx2bO1ykdYP18wggSnMIIDj6ADAgECAg5IG2oH
# qUJMHqr+883xDzANBgkqhkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWdu
# IFJvb3QgQ0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xv
# YmFsU2lnbjAeFw0xNjA2MTUwMDAwMDBaFw0yNDA2MTUwMDAwMDBaMG4xCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMUQwQgYDVQQDEztHbG9i
# YWxTaWduIEV4dGVuZGVkIFZhbGlkYXRpb24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEy
# NTYgLSBHMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANm3uiWtlPNb
# vkEGHFPKDBCMUUFZM3lk9Fed5NUlxOxQhFiYcnlA4i941JLqJg6erpV8+8T9cUTd
# jF+3I4teu/T8S8sjPcN2A/XRjEW8cXUdi9KJib7jUT3GyIqyMTUHbrn1umoN9BCf
# rtViSSh77Fe6qzJ8sX3SolYGNu6w79BqruqrH9YNn3yW+61wmS1dlfCA0HlG7FU6
# zNM4+wQHqAd1goLg0H53uI/r0ij8rm0UaEF/dkPXSLpgROG3cujQ8CADe9ratAZ1
# x7ID3viUxmiPXnuem5024M7Sa8bGa+kUIrVxfraPWh/b5270QhCQaOYrRRBPc7os
# 18UxanLdY3MCAwEAAaOCAWMwggFfMA4GA1UdDwEB/wQEAwIBBjAdBgNVHSUEFjAU
# BggrBgEFBQcDAwYIKwYBBQUHAwkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU3CxYLCpvNS2feZWoSF3EbT5Tv7kwHwYDVR0jBBgwFoAUj/BLf6guRSSuTVD6
# Y5qL3uLdG7wwPgYIKwYBBQUHAQEEMjAwMC4GCCsGAQUFBzABhiJodHRwOi8vb2Nz
# cDIuZ2xvYmFsc2lnbi5jb20vcm9vdHIzMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6
# Ly9jcmwuZ2xvYmFsc2lnbi5jb20vcm9vdC1yMy5jcmwwYgYDVR0gBFswWTALBgkr
# BgEEAaAyAQIwBwYFZ4EMAQMwQQYJKwYBBAGgMgFfMDQwMgYIKwYBBQUHAgEWJmh0
# dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEB
# CwUAA4IBAQB2CcTML9nvHkup+FfzQDkhykw8HZ4pKyDUK0TSiM4aDQXPg4G762m8
# MY0qxMdEzGBglBzPoeECJA6tW74swiceZ7foKB8yUeM585jfuJ8uiyq0ewoDvL02
# BI/J0JxPowInmbDwRek03+Q6o7cGN9hvKnmQ1NROWHHsU6lhmPc5aeASnFdYcoYn
# KaUd5TLzK5mXWr8rsDy0BuoOZOy3zWWAJBfC2Tf1sSYQNUd7mgK6VKJFk/95vxqM
# xZ+1n99452tQ8UeUaUskuNoF6AydTwbsSjEgfk9dhoQvNaPNnMGEVx8frcDipLHv
# KWshl6bU/u0DN7D89Y0qvNyEg+Pew+dfMIIFlzCCBH+gAwIBAgIMLBDbiLZjb4wT
# /e4rMA0GCSqGSIb3DQEBCwUAMG4xCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMUQwQgYDVQQDEztHbG9iYWxTaWduIEV4dGVuZGVkIFZhbGlk
# YXRpb24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBHMzAeFw0yMDEwMDIxMzU3
# MDlaFw0yMzEwMDMxMzU3MDlaMIHrMR0wGwYDVQQPDBRQcml2YXRlIE9yZ2FuaXph
# dGlvbjEQMA4GA1UEBRMHNDc1NTA2ejETMBEGCysGAQQBgjc8AgEDEwJBVDEVMBMG
# CysGAQQBgjc8AgECEwRXaWVuMRUwEwYLKwYBBAGCNzwCAQETBFdpZW4xCzAJBgNV
# BAYTAkFUMQ0wCwYDVQQIEwRXaWVuMQ0wCwYDVQQHEwRXaWVuMRowGAYDVQQJExFX
# ZXJkZXJ0b3JnYXNzZSAxNDEWMBQGA1UEChMNU2lnblBhdGggR21iSDEWMBQGA1UE
# AxMNU2lnblBhdGggR21iSDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AMgMwU0L50Zxij13cvgZHvBrzaN7q9aWjlhUSu/HIxSke8+woajflpPaGr6A8gsA
# DJCmgP2NA0wFelssA7A42WNls5LkLcfPaNxEmxOaqbEozB8R6q6cHVXNecV1ePCL
# dVzDb82Iv7evpSSJ4PpU/tp21VVdTiXTP39uwuHlbUJ0KeRmnCV3rd1pnUZS7AmF
# XhnwYktFjWNPmrQ+XOqEp7n9sOg+PUOl1uQYBJKzKy0EQnz263MtagNO3hFc1xxI
# /4S2fd3Xk85iVyafj3/WgImVflNeaK2ayo4nwhnayE6Vdm1xrQS6TPcjd0CdFa1D
# oD2ma+h9RApByxuY8wAioe0CAwEAAaOCAbUwggGxMA4GA1UdDwEB/wQEAwIHgDCB
# oAYIKwYBBQUHAQEEgZMwgZAwTgYIKwYBBQUHMAKGQmh0dHA6Ly9zZWN1cmUuZ2xv
# YmFsc2lnbi5jb20vY2FjZXJ0L2dzZXh0ZW5kY29kZXNpZ25zaGEyZzNvY3NwLmNy
# dDA+BggrBgEFBQcwAYYyaHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzZXh0
# ZW5kY29kZXNpZ25zaGEyZzMwVQYDVR0gBE4wTDBBBgkrBgEEAaAyAQIwNDAyBggr
# BgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8w
# BwYFZ4EMAQMwCQYDVR0TBAIwADBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzZXh0ZW5kY29kZXNpZ25zaGEyZzMuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB8GA1UdIwQYMBaAFNwsWCwqbzUtn3mVqEhdxG0+U7+5
# MB0GA1UdDgQWBBTWmX8rS+NROkC9GcibVKe3ru+sCDANBgkqhkiG9w0BAQsFAAOC
# AQEADzLf9ib1c44b59PgRdLNkAvgHl2ZbDa3bnz+5jILYePECxq7snIp7rSJwGUC
# 3jB+zGBabHDQyCm5jAt023o50VXyVyzqSv7tfDlUdpjiEZnRlCYibF+p7eHBBxQc
# dOSxyBsKuGX5jK9xHTN3kn/UUwYHpp/q6fQKdSRuJ4UG7Ris7LTs1FBX82Kg5BbP
# BzGdcH0f8b3kiiu7nP7CPZfDNLkrxZbvfEa6n4kfAZbBPbBSvF36z7+KYOMTOd2n
# lPKJM5PoGOTtGOKSwGyxEo3AsJjSGAS8aOYzGW4ROrcUa3F5rJycrTh1/luECPQW
# SDqPQqiVUWLjniq5ijekgwDrWzGCGbEwghmtAgEBMH4wbjELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExRDBCBgNVBAMTO0dsb2JhbFNpZ24g
# RXh0ZW5kZWQgVmFsaWRhdGlvbiBDb2RlU2lnbmluZyBDQSAtIFNIQTI1NiAtIEcz
# AgwsENuItmNvjBP97iswDQYJYIZIAWUDBAIBBQCggZowGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLgYKKwYB
# BAGCNwIBDDEgMB6gHIAaAFMAaQBnAG4AUABhAHQAaAAuAHAAcwBtADEwLwYJKoZI
# hvcNAQkEMSIEIBYilaprNHJFGBrkB9UEwtmXH2Cues9yB+oL1FcAuGDzMA0GCSqG
# SIb3DQEBAQUABIIBAKR4W+5lII0piu4mgurytLLfEwmZ6y2RiDgJWPxLtBSEZxCU
# HfM6NrDjJxtFBuTeEtX2bpgiJcm8JIutAi860mQKWshbBYWoWYnY1X7Jip26XTeG
# 4E9SKgA+SVaAoiSEj3AUH2fgqtwoeJ57o/JOP8Y9apCsxvkKYzuc+mbTqLcrM9c/
# tB7wamo2tkAXkm7eAk4totk/G7ZKx5Pcosjc9Bc0TJCQRj6IO6dwfMOi7HKCnM+J
# sAQzt4/cxCnoa274m9QtWnmp/+8oz+XhqfFkVSocTi+VEc4mN09YG1rmpY9u0Vv+
# zcGPP4CWqiIF5WXyGbjhgWYHcRertkVpM/spnRKhghdnMIIXYwYKKwYBBAGCNwMD
# ATGCF1MwghdPBgkqhkiG9w0BBwKgghdAMIIXPAIBAzEPMA0GCWCGSAFlAwQCAQUA
# MHcGCyqGSIb3DQEJEAEEoGgEZjBkAgEBBglghkgBhv1sBwEwMTANBglghkgBZQME
# AgEFAAQgmeBzwctTCrw9Pgd1C1MGSuh9hMRjgjlKMmTC0pMuG2cCEGnEIXsLK89L
# VH2zhLsGdTIYDzIwMjIwNzE4MTUwMjQwWqCCEzEwggbGMIIErqADAgECAhAKekqI
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
# 05zMbbUNrkdjOEcXW28T2moQbh9Jt0RbtAgKh1pZBHYRoad3AhMcMIIGrjCCBJag
# AwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIw
# MzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCw
# zIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFz
# sbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ
# 7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7
# QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/teP
# c5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCY
# OjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9K
# oRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6
# dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM
# 1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbC
# dLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbEC
# AwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7Zv
# mKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI
# 2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/ty
# dBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVP
# ulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmB
# o1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc
# 6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3c
# HXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0d
# KNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZP
# J/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLe
# Mt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDy
# Divl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBbEwggSZoAMCAQICEAEkCvseOAuK
# FvFLcZ3008AwDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UE
# AxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDYwOTAwMDAwMFoX
# DTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQw
# H/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6
# dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXG
# XuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXn
# Mcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy
# 19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFY
# F/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+Skjqe
# PdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFg
# qrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJR
# R3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7Gr
# hotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCAV4wggFa
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9P
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIB
# hjATBgNVHSUEDDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNy
# dDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsG
# CWCGSAGG/WwHATANBgkqhkiG9w0BAQwFAAOCAQEAmhYCpQHvgfsNtFiyeK2oIxnZ
# czfaYJ5R18v4L0C5ox98QE4zPpA854kBdYXoYnsdVuBxut5exje8eVxiAE34SXpR
# TQYy88XSAConIOqJLhU54Cw++HV8LIJBYTUPI9DtNZXSiJUpQ8vgplgQfFOOn0XJ
# IDcUwO0Zun53OdJUlsemEd80M/Z1UkJLHJ2NltWVbEcSFCRfJkH6Gka93rDlkUcD
# rBgIy8vbZol/K5xlv743Tr4t851Kw8zMR17IlZWt0cu7KgYg+T9y6jbrRXKSeil7
# FAM8+03WSHF6EBGKCHTNbBsEXNKKlQN2UVBT1i73SkbDrhAscUywh7YnN0RgRDGC
# A3YwggNyAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQCnpKiJ7JmUKQBmM4TYaXnTANBglghkgBZQMEAgEF
# AKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8X
# DTIyMDcxODE1MDI0MFowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQUhQjzhlFcs9MH
# fba0t8B/G0peQd4wLwYJKoZIhvcNAQkEMSIEICsbNM2qnAMvpmoTbgSodH5Y+yr4
# Jq8hufCTkatOFJpvMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIJ2mkBXDScbBiXhF
# ujWCrXDIj6QpO9tqvpwr0lOSeeY7MA0GCSqGSIb3DQEBAQUABIICAJMUcIAfv3x0
# zTjZ5HFXhRqe/Z1zRPBP/pLggp7bEhn4bC/bBuxo2xWanDR68ZBCF5zEqi1dZxc/
# FuSivRDbQyrVmn+BCGW+s7IliU5n0j7qJRnqRZyoIbux1hhCpHdes1Q+7EFHHYIL
# XrOFFyAyYEAN1WFXR8b2CsLTD5IqHMms42B9AC0Rl+S4U9E4Pn/rWJGMlW8Hq8gk
# YQ9qUKyZ9nAWzoFgeNJOtGBKVnXZqPNWgmO4fnR/fY58eVW15s2kYz7EldFUcXOr
# a5HEnW53F3hVZw2hoAATDqg/M5EO4+KL/3DC4B6FWN+MC0vywJbkrU2ZmFvfc5jg
# D2dc0u0NNd1Y31NU/6zzsgsLIkVoSmfFiu2fUZjgSALk5P6a1Os8eq2VrnASs+oT
# mKblIwKlDne1/U7em783c6cDu2+1JRpOQTLerdU9FUczpqhb6lHNVDvxu6cg3bog
# k+RzKZYubD2vyoCFYIrhhrTxoD4Yh3ZMC7mxnM01Pwndup+hdZtzNO2NolBNyWb9
# NuIX2NUPG6Moxdnc/JJwGQsbG5bea8gABzYJktqdKDf0+0ZgsmtYdBU+4xFisqIs
# UZDOsd21ch0f8I6C0qN6AQfK+G+o3Q3k71L5IlnQKVG68XwHyxMmWzC8JRPrPjQ+
# HrkvAIJJ0K251rgc7jIvbJoCY5ad5zhF
# SIG # End signature block

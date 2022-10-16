function _generateKey {
    $newChar = @()
    $char = [char[]](48..93)
    $char += [char[]](97..122)
    For($i=0; $i -lt $char.Count; $i++) {
        $newChar += $char[$i]
    }
    [String]$p = Get-Random -InputObject $newChar -Count 32
    return $p.Replace(" ","")
}
function _getBytes([string] $key) {
    return [System.Text.Encoding]::UTF8.GetBytes($key)
}
function _encrypt([string] $plainText, [string] $key) {
    return $plainText | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key (_getBytes $key)
}
function _decrypt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $encryptedText,
        [Parameter(Mandatory)]
        [string] $key
    )
    try {
        $cred = [pscredential]::new("x", ($encryptedText | ConvertTo-SecureString -Key (_getBytes $key) -ErrorAction SilentlyContinue))
        return $cred.GetNetworkCredential().Password
    }
    catch {
        Write-Warning "Cannot get the value as plain text; Use the right key to get the secret value as plain text."
    }
}
function _getOS {
    if ($env:OS -match 'Windows') { return 'Windows' }
    elseif ($IsLinux) { return 'Linux' }
    elseif ($IsMacOs -or $IsOSX) { return 'MacOs' }
}
function _getUser {
    # should work in both Mac and Linux
    return [System.Environment]::UserName
}
function _clearHistory([string] $functionName) {
    $path = (Get-PSReadLineOption).HistorySavePath
    if (!([string]::IsNullOrEmpty($path)) -and (Test-Path -Path $path)) {
        $contents = Get-Content -Path $path
        if ($contents -notmatch $functionName) { $contents -notmatch $functionName | Set-Content -Path $path -Encoding UTF8 }
    }
}
function _createDb {
    $path = Join-Path -Path $Home -ChildPath ".cos_$((_getUser).ToLower())"
    $pathExists = Test-Path $path
    $file = Join-Path -Path $path -ChildPath "_.db"
    $fileExists = Test-Path $file
    # Metadata section is required so that we know what we are storing.
    $query = "CREATE TABLE _ (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL,
        Value TEXT NOT NULL,
        Metadata TEXT NOT NULL,
        AddedOn TEXT,
        UpdatedOn TEXT)"
    # Make ID as primary key and copy all data from old table.
    # This should run if the file exists with older schema
    if ($fileExists) {
        $columns = (Invoke-SqliteQuery -DataSource $file -Query "PRAGMA table_info(_)").name
        if (!$columns.Contains("AddedOn")) {
            $res = Invoke-SqliteQuery -DataSource $file -Query "SELECT * FROM _"
            $null = Remove-Item -Path $file -Force
            $null = New-Item -Path $file -ItemType File
            Invoke-SqliteQuery -DataSource $file -Query $query
            foreach ($i in $res) {
                $dataTable = [PSCustomObject]@{
                    Name = $i.Name
                    Value = $i.Value
                    Metadata = $i.Metadata
                    AddedOn = $null
                    UpdatedOn = $null
                } | Out-DataTable
            }
            Invoke-SQLiteBulkCopy -DataTable $dataTable -DataSource $file -Table _ -ConflictClause Ignore -Force
            _hideFile $file
        }
    } else {
        if (!$pathExists) { $null = New-Item -Path $path -ItemType Directory }
        if (!$fileExists) {
            $null = New-Item -Path $file -ItemType File
            Invoke-SqliteQuery -DataSource $file -Query $query
            _hideFile $file
        }
    }
    return $file
}
function _connectionWarning {
    Write-Warning "You must create a connection to the vault to manage the secrets. Check your connection object and pass the right credential."
}
function _getDbPath {
    return _createDb
}
function _getKeyFile {
    $path = Split-Path -Path (_getDbPath) -Parent
    return (Join-Path -Path $path -ChildPath "private.key")
}
function _getConnectionFile {
    $path = Split-Path -Path (_getKeyFile) -Parent
    return (Join-Path -Path $path -ChildPath "connection.clixml")
}
function _archiveKeyFile {
    $path = Split-Path -Path (_getKeyFile) -Parent
    [string] $keyFile = _getKeyFile
    $file = $keyFile.Replace("private", "private_$(Get-Date -Format ddMMyyyy-HH_mm_ss)")
    $archivePath = Join-Path -Path $path -ChildPath "archive"
    if (!(Test-Path $archivePath)) { $null = New-Item -Path $archivePath -ItemType Directory }
    _unhideFile (_getKeyFile)
    Rename-Item -Path (_getKeyFile) -NewName $file
    Move-Item -Path $file -Destination "$archivePath" -Force
}
function _isKeyFileExists {
    return (Test-Path (_getKeyFile))
}
function _saveKey([string] $key, [switch] $force) {
    $file = _getKeyFile
    $fileExists = _isKeyFileExists
    if ($fileExists -and !$force.IsPresent) { Write-Warning "Key file already exists; Use Force parameter to update the file." }
    if ($fileExists -and $force.IsPresent) {
        _unhideFile $file
        $encryptedKey = [pscredential]::new("key", ($key | ConvertTo-SecureString -AsPlainText -Force))
        $encryptedKey.Password | Export-Clixml -Path $file -Force
        _hideFile $file
    }
    if (!$fileExists) {
        $encryptedKey = [pscredential]::new("key", ($key | ConvertTo-SecureString -AsPlainText -Force))
        $encryptedKey.Password | Export-Clixml -Path $file -Force
        _hideFile $file
    }
}
function _hideFile([string] $filePath) {
    if ((_getOS) -eq "Windows") {
        if ((Get-Item $filePath -Force).Attributes -notmatch 'Hidden') { (Get-Item $filePath).Attributes += 'Hidden' }
    }
}
function _unhideFile([string] $filePath) {
    if ((_getOS) -eq "Windows") {
        if ((Get-Item $filePath -Force).Attributes -match 'Hidden') { (Get-Item $filePath -Force).Attributes -= 'Hidden' }
    }
}
function _isNameExists([string] $name) {
    return [bool] (Get-PSSecret -Name $name -WarningAction 'SilentlyContinue')
}
function _getHackedPasswords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [String[]]$secureStringList
    )
    begin {
        #initialize function variables
        $encoding = [System.Text.Encoding]::UTF8
        $result = @()
        $hackedCount = @()
    }
    process {
        foreach ($string in $secureStringList) {
            $SHA1Hash = New-Object -TypeName "System.Security.Cryptography.SHA1CryptoServiceProvider"
            $Hashcode = ($SHA1Hash.ComputeHash($encoding.GetBytes($string)) | `
                    ForEach-Object { "{0:X2}" -f $_ }) -join ""
            $Start, $Tail = $Hashcode.Substring(0, 5), $Hashcode.Substring(5)
            $Url = "https://api.pwnedpasswords.com/range/" + $Start
            $Request = Invoke-RestMethod -Uri $Url -UseBasicParsing -Method Get
            $hashedArray = $Request.Split()
            foreach ($item in $hashedArray) {
                if (!([string]::IsNullOrEmpty($item))) {
                    $encodedPassword = $item.Split(":")[0]
                    $count = $item.Split(":")[1]
                    $Hash = [PSCustomObject]@{
                        "HackedPassword" = $encodedPassword.Trim()
                        "Count"          = $count.Trim()
                    }
                    $result += $Hash
                }
            }
            foreach ($pass in $result) {
                if($pass.HackedPassword -eq $Tail) {
                    $newHash = [PSCustomObject]@{
                        Name = $string
                        Count = $pass.Count
                    }
                    $hackedCount += $newHash
                }
            }
            if ($string -notin $hackedCount.Name) {
                $finalHash = [PSCustomObject]@{
                    Name = $string
                    Count = 0
                }
                $hackedCount += $finalHash
            }
        }
        return $hackedCount
    }
}
function _isHacked([string] $value) {
    $res = (_getHackedPasswords $value -ErrorAction SilentlyContinue).Count
    if ($res -gt 0) {
        Write-Warning "Secret '$value' was hacked $($res) time(s); Consider changing the secret value."
    }
}
function _clearPersonalVault {
    Remove-Item -Path (Split-Path -Path (_getDbPath) -Parent) -Recurse -Force
}
function _clearConnection {
    Remove-Item -Path (_getConnectionFile) -Force
    [System.Environment]::SetEnvironmentVariable("PERSONALVAULT_U", "", [System.EnvironmentVariableTarget]::Process)
    [System.Environment]::SetEnvironmentVariable("PERSONALVAULT_P", "", [System.EnvironmentVariableTarget]::Process)
}
function _isValidConnection ([PersonalVault] $connection) {
    $verified = $false
    if (($null -ne $connection.UserName) -and ($null -ne $connection.Password)) {
        if (Test-Path -Path (_getConnectionFile)) {
            $properties = Import-Clixml -Path (_getConnectionFile)
            $prop = [pscredential]::new($properties.UserName, $properties.Password)
            $propPassword = $prop.GetNetworkCredential().Password
            $conn = [pscredential]::new($connection.UserName, $connection.Password)
            $connPassword = $conn.GetNetworkCredential().Password
            if (($prop.UserName -eq $conn.UserName) -and ($propPassword -eq $connPassword)) { $verified = $true }
        }
    }
    return $verified
}
function _setEnvironmentVariable ([string] $key, [string] $value) {
    if (!([string]::IsNullOrEmpty($key)) -and !([string]::IsNullOrEmpty($value))) {
        [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
    }
}
function _getEnvironmentVariable([string] $key) {
    if (!([string]::IsNullOrEmpty($key))) {
        return [System.Environment]::GetEnvironmentVariable($key)
    }
}
function _getConnectionObject {
    $connection = [PersonalVault]::new()
    $userName = _getEnvironmentVariable -key "PERSONALVAULT_U"
    $password = (_getEnvironmentVariable -key "PERSONALVAULT_P")
    if (!([string]::IsNullOrEmpty($userName)) -and !([string]::IsNullOrEmpty($password))) {
        $connection.UserName = $userName
        $connection.Password = $password | ConvertTo-SecureString -ErrorAction SilentlyContinue
        return $connection
    }
}
function _isValidRecoveryWord ([securestring] $recoveryWord) {
    $res = Import-Clixml -Path (_getConnectionFile)
    $key = [pscredential]::new("Key", $res.Key)
    $recKey = [pscredential]::new("Key", $recoveryWord)
    return ($recKey.GetNetworkCredential().Password -eq $key.GetNetworkCredential().Password)
}
function _selectValueFromDB([string] $name, [int] $id) {
    if ($name -and $id) {
        return (Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT Value FROM _ WHERE Name = '$name' AND Id = '$id'")
    }
    if (!$name -and $id) {
        return (Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT Value FROM _ WHERE Id = '$id'")
    }
    if ($name -and !$id) {
        return (Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT Value FROM _ WHERE Name = '$name'")
    }
    return (Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT * FROM _")
}
function Add-PSSecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Value,
        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Provide the details of what you are storing",
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Metadata,
        [ValidateNotNullOrEmpty()]
        [string] $Key = (Get-PSKey -WarningAction SilentlyContinue)
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            _isHacked $Value
            $encryptedValue = _encrypt -plainText $Value -key $Key
            # create the database and save the KV pair
            $null = _createDb
            Invoke-SqliteQuery `
                -DataSource (_getDbPath) `
                -Query "INSERT INTO _ (Name, Value, Metadata, AddedOn, UpdatedOn) VALUES (@N, @V, @M, @D, @U)" `
                -SqlParameters @{
                N = $Name
                V = $encryptedValue
                M = $Metadata
                D = Get-Date
                U = $null
            }
            # cleaning up
            _clearHistory $MyInvocation.MyCommand.Name
        } else { _connectionWarning }
    }
}
function Connect-PSPersonalVault {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential] $Credential
    )
    process {
        $personalVault = [PersonalVault]::new()
        $personalVault.UserName = if ([string]::IsNullOrEmpty($Credential.UserName)) { _getUser } else { $Credential.UserName }
        $personalVault.Password = $Credential.Password
        # Return the PersonalVault object so that it can be consumed and verified by other cmdlets
        _setEnvironmentVariable -key "PERSONALVAULT_U" -value $personalVault.UserName
        _setEnvironmentVariable -key "PERSONALVAULT_P" -value ($personalVault.Password | ConvertFrom-SecureString)
        return $personalVault
    }
}
function Get-PSArchivedKey {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [datetime] $DateModified
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            $archivePath = Join-Path -Path (Split-Path -Path (_getKeyFile) -Parent) -ChildPath "archive"
            if (Test-Path $archivePath) {
                $results = @()
                $archivedFiles = Get-ChildItem -Path $archivePath | Select-Object FullName, LastWriteTime
                if ($PSBoundParameters.ContainsKey('DateModified')) {
                    $archivedFiles = $archivedFiles | Where-Object { (Get-Date $_.LastWriteTime -Format ddMMyyyy) -eq (Get-Date $DateModified -Format ddMMyyyy) }
                }
                $archivedFiles | ForEach-Object {
                    $key = Import-Clixml $_.FullName
                    $keyObj = [pscredential]::new("key", $key)
                    $obj = [PSCustomObject]@{
                        DateModified = $_.LastWriteTime
                        Key          = $keyObj.GetNetworkCredential().Password
                    }
                    $results += $obj
                }
                return $results
            }
        } else { _connectionWarning }
    }
}
function Get-PSKey {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [switch] $Force
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            if (_isKeyFileExists) {
                $res = Import-Clixml (_getKeyFile)
                $key = [pscredential]::new("key", $res)
                $key = $key.GetNetworkCredential().Password
            }
            if (!(_isKeyFileExists)) {
                $key = _generateKey
                _saveKey -key $key
            }
            if ($Force.IsPresent) {
                _archiveKeyFile
                $key = _generateKey; _saveKey -key $key -force
            }
            return $key
        } else { _connectionWarning }
    }
}
function Get-PSSecret {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter([NameCompleter])]
        [ValidateNotNullOrEmpty()]
        [string] $Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter([IdCompleter])]
        [ValidateNotNullOrEmpty()]
        [int] $Id,
        [ValidateNotNullOrEmpty()]
        [string] $Key = (Get-PSKey -WarningAction SilentlyContinue),
        [switch] $AsPlainText
    )
    process {
        # check if the credentials are valid.
        if (_isValidConnection (_getConnectionObject)) {
            if ($AsPlainText.IsPresent) {
                if (($PSBoundParameters.ContainsKey('Name')) -and ($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -name $Name -id $Id).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Name '$Name' and Id '$Id'; Pass the correct value and try again."
                    }
                    else { return _decrypt -encryptedText $res -key $Key }
                }
                if (!($PSBoundParameters.ContainsKey('Name')) -and ($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -id $Id).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Id '$Id'; Pass the correct value and try again."
                    }
                    else { return _decrypt -encryptedText $res -key $Key }
                }
                if (($PSBoundParameters.ContainsKey('Name')) -and !($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -name $Name).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Name '$Name'; Pass the correct value and try again."
                    }
                    else {
                        $result = @()
                        $res | ForEach-Object {
                            $result += (_decrypt -encryptedText $_ -key $Key)
                        }
                        return $result
                    }
                }
                $result = @()
                $res = _selectValueFromDB
                $res | ForEach-Object {
                    $r = [PSCustomObject]@{
                        Id = $_.Id
                        Name = $_.Name
                        Value = (_decrypt -encryptedText $_.Value -key $Key)
                        Metadata = $_.Metadata
                        AddedOn = if ($null -ne $_.AddedOn) { Get-Date $_.AddedOn } else { $_.AddedOn }
                        UpdatedOn = if ($null -ne $_.UpdatedOn) { Get-Date $_.UpdatedOn } else { $_.UpdatedOn }
                    }
                    $result += $r
                }
                if ([bool] ($result.Value)) { return $result }
            }
            else {
                if (($PSBoundParameters.ContainsKey('Name')) -and ($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -name $Name -id $Id).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Name '$Name' and Id '$Id'; Pass the correct value and try again."
                    }
                    else { return $res }
                }
                if (!($PSBoundParameters.ContainsKey('Name')) -and ($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -id $Id).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Id '$Id'; Pass the correct value and try again."
                    }
                    else { return $res }
                }
                if (($PSBoundParameters.ContainsKey('Name')) -and !($PSBoundParameters.ContainsKey('Id'))) {
                    $res = (_selectValueFromDB -name $Name).Value
                    if (($null -eq $res) -or ([string]::IsNullOrEmpty($res))) {
                        Write-Warning "Couldn't find the value for given Name '$Name'; Pass the correct value and try again."
                    }
                    else { return $res }
                }
                $result = @()
                $res = _selectValueFromDB
                $res | ForEach-Object {
                    $r = [PSCustomObject]@{
                        Id = $_.Id
                        Name = $_.Name
                        Value = $_.Value
                        Metadata = $_.Metadata
                        AddedOn = if ($null -ne $_.AddedOn) { Get-Date $_.AddedOn } else { $_.AddedOn }
                        UpdatedOn = if ($null -ne $_.UpdatedOn) { Get-Date $_.UpdatedOn } else { $_.UpdatedOn }
                    }
                    $result += $r
                }
                if ([bool] ($result.Value)) { return $result }
            }
        } else { _connectionWarning }
    }
}
function Import-PSPersonalVault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring] $RecoveryWord
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            if (_isValidRecoveryWord $RecoveryWord) {
                $res = Import-Clixml -Path (_getConnectionFile)
                return [PSCustomObject]@{
                    UserName = $res.UserName
                    Password = ([pscredential]::new("P", $res.Password)).GetNetworkCredential().Password
                }
            } else {
                Write-Warning "Recovery word is incorrect. Please pass the valid recovery word and try again."
            }
        } else { _connectionWarning }
    }
}
function Register-PSPersonalVault {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential] $Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring] $RecoveryWord,
        [switch] $Force
    )
    process {
        $personalVault = [PersonalVault]::new()
        $personalVault.UserName = if ([string]::IsNullOrEmpty($Credential.UserName)) { _getUser } else { $Credential.UserName }
        $personalVault.Password = $Credential.Password
        $personalVault.Key = $RecoveryWord
        if (!(Test-Path (_getConnectionFile))) { $personalVault | Export-Clixml -Path (_getConnectionFile) }
        if ($Force.IsPresent) {
            if (_isValidConnection (_getConnectionObject)) {
                $personalVault | Export-Clixml -Path (_getConnectionFile) -Force
            } else { _connectionWarning }
        }
    }
}
function Remove-PSPersonalVault {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [switch] $Force
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("Personal Vault", "Remove-PSPersonalVault")) {
                _clearPersonalVault
            }
        } else { _connectionWarning }
    }
}
function Remove-PSPersonalVaultConnection {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [switch] $Force
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("Connection", "Remove-PSPersonalVaultConnection")) {
                _clearConnection
            }
        } else { _connectionWarning }
    }
}
function Remove-PSSecret {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = "Id")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id")]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Both")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([IdCompleter])]
        [int] $Id,
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Name")]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Both")]
        [ArgumentCompleter([NameCompleter])]
        [ValidateNotNullOrEmpty()]
        [string] $Name,
        [switch] $Force
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            if ($Force -or $PSCmdlet.ShouldProcess($Name, "Remove-Secret")) {
                if ($PSCmdlet.ParameterSetName -eq "Id") {
                    Invoke-SqliteQuery -DataSource (_getDbPath) -Query "DELETE FROM _ WHERE Id = '$Id'"
                }
                if ($PSCmdlet.ParameterSetName -eq "Name") {
                    $res = Get-PSSecret -Name $Name
                    if ($res.Count -eq 1) {
                        Invoke-SqliteQuery -DataSource (_getDbPath) -Query "DELETE FROM _ WHERE Name = '$Name'"
                    } else {
                        Write-Warning "More than (1) values found for given Name '$Name'; Pass Id to remove the respective value from the vault."
                    }
                }
                if ($PSCmdlet.ParameterSetName -eq "Both") {
                    Invoke-SqliteQuery -DataSource (_getDbPath) -Query "DELETE FROM _ WHERE Name = '$Name' AND Id = '$Id'"
                }
            }
        } else { _connectionWarning }
    }
}
function Update-PSSecret {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter([NameCompleter])]
        [ValidateNotNullOrEmpty()]
        [string] $Name,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Value,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([IdCompleter])]
        [int] $Id,
        [ValidateNotNullOrEmpty()]
        [string] $Key = (Get-PSKey -WarningAction SilentlyContinue),
        [switch] $Force
    )
    process {
        if (_isValidConnection (_getConnectionObject)) {
            _isHacked $Value
            if ($Force -or $PSCmdlet.ShouldProcess($Value, "Update-Secret")) {
                $encryptedValue = _encrypt -plainText $Value -key $Key
                Invoke-SqliteQuery `
                    -DataSource (_getDbPath) `
                    -Query "UPDATE _ SET Value = '$encryptedValue', UpdatedOn = (@D) WHERE Name = '$Name' AND Id = '$Id'" `
                    -SqlParameters @{
                        D = Get-Date
                    }
                # cleaning up
                _clearHistory $MyInvocation.MyCommand.Name
            }
        } else { _connectionWarning }
    }
}


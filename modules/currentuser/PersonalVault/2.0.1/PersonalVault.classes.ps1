using namespace System.Collections;
using namespace System.Management.Automation;
using namespace System.Collections.Generic;
 class IdCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [Language.CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $results = [List[CompletionResult]]::new()
        $Ids = Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT * FROM _"
        foreach ($value in $Ids.Id) {
            if ($value -like "*$WordToComplete*") {
                $results.Add($value)
            }
        }
        if (_isValidConnection (_getConnectionObject)) {
            return $results
        }
        return $null
    }
}
class NameCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [Language.CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $results = [List[CompletionResult]]::new()
        $names = Invoke-SqliteQuery -DataSource (_getDbPath) -Query "SELECT * FROM _"
        foreach ($value in $names.Name) {
            if ($value -like "*$WordToComplete*") {
                $results.Add($value)
            }
        }
        if (_isValidConnection (_getConnectionObject)) {
            return $results
        }
        return $null
    }
}
class PersonalVault {
    [string] $UserName
    [securestring] $Password
    [string] $Name = "PersonalVault"
    hidden [securestring] $Key
    [string] $ConnectionFilePath = (_getConnectionFile)
}


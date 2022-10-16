function GetCurrentUser {
    [CmdletBinding()]
    Param ()
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

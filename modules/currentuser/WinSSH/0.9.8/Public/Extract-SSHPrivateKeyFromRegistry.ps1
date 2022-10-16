<#
    .SYNOPSIS
        Microsoft's port of OpenSSH (OpenSSH-Win64) ultimately adds RSA Private Keys to the Registry when they are added to the
        ssh-agent service. This function extracts those RSA Private Keys from the Registry. It can only be used under the same
        User Profile that added the key(s) to the ssh-agent in the first place.

    .DESCRIPTION
        See .SYNOPSIS

    .NOTES
        Python Code from: https://github.com/ropnop/windows_sshagent_extract

    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -

        PS C:\Users\zeroadmin> Extract-SSHPrivateKeyFromRegistry
#>
function Extract-SSHPrivateKeysFromRegistry {
    [CmdletBinding()]
    Param ()

    $OpenSSHRegistryPath = "HKCU:\Software\OpenSSH\Agent\Keys\"

    $RegistryKeys = Get-ChildItem $OpenSSHRegistryPath | Get-ItemProperty

    if ($RegistryKeys.Length -eq 0) {
        Write-Error "No ssh-agent keys in registry"
        $global:FunctionResult = "1"
        return
    }

    $tempDirectory = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName())
    $null = [IO.Directory]::CreateDirectory($tempDirectory)

    Add-Type -AssemblyName System.Security
    [System.Collections.ArrayList]$keys = @()
    $RegistryKeys | foreach {
        $key = @{}
        $comment = [System.Text.Encoding]::ASCII.GetString($_.comment)
        $encdata = $_.'(default)'
        $decdata = [Security.Cryptography.ProtectedData]::Unprotect($encdata, $null, 'CurrentUser')
        $b64key = [System.Convert]::ToBase64String($decdata)
        $key[$comment] = $b64key
        $null = $keys.Add($key)
    }

    ConvertTo-Json -InputObject $keys | Out-File -FilePath "$tempDirectory/extracted_keyblobs.json" -Encoding ascii

    $InstallPython3Result = Install-Program -ProgramName python3 -CommandName python -UseChocolateyCmdLine
    if (!$(Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Error "Unable to find python.exe! Halting!"
        $global:FunctionResult = "1"
        return
    }
    if (!$(Get-Command pip -ErrorAction SilentlyContinue)) {
        Write-Error "Unable to find pip.exe! Halting!"
        $global:FunctionResult = "1"
        return
    }
    pip install pyasn1 pip *> $null
    
    Set-Content -Path "$tempDirectory\extractPrivateKeys.py" -Value @"
#!/usr/bin/env python

# Script to extract OpenSSH private RSA keys from base64 data
# From: https://github.com/ropnop/windows_sshagent_extract

import sys
import base64
import json
try:
    from pyasn1.type import univ
    from pyasn1.codec.der import encoder
except ImportError:
    print("You must install pyasn1")
    sys.exit(0)


def extractRSAKey(data):
    keybytes = base64.b64decode(data)
    offset = keybytes.find(b"ssh-rsa")
    if not offset:
        print("[!] No valid RSA key found")
        return None
    keybytes = keybytes[offset:]

    # This code is re-implemented code originally written by soleblaze in sshkey-grab
    start = 10
    size = getInt(keybytes[start:(start+2)])
    # size = unpack_bigint(keybytes[start:(start+2)])
    start += 2
    n = getInt(keybytes[start:(start+size)])
    start = start + size + 2
    size = getInt(keybytes[start:(start+2)])
    start += 2
    e = getInt(keybytes[start:(start+size)])
    start = start + size + 2
    size = getInt(keybytes[start:(start+2)])
    start += 2
    d = getInt(keybytes[start:(start+size)])
    start = start + size + 2
    size = getInt(keybytes[start:(start+2)])
    start += 2
    c = getInt(keybytes[start:(start+size)])
    start = start + size + 2
    size = getInt(keybytes[start:(start+2)])
    start += 2
    p = getInt(keybytes[start:(start+size)])
    start = start + size + 2
    size = getInt(keybytes[start:(start+2)])
    start += 2
    q = getInt(keybytes[start:(start+size)])

    e1 = d % (p - 1)
    e2 = d % (q - 1)

    keybytes = keybytes[start+size:]

    seq = (
        univ.Integer(0),
        univ.Integer(n),
        univ.Integer(e),
        univ.Integer(d),
        univ.Integer(p),
        univ.Integer(q),
        univ.Integer(e1),
        univ.Integer(e2),
        univ.Integer(c),
    )

    struct = univ.Sequence()

    for i in range(len(seq)):
        struct.setComponentByPosition(i, seq[i])
    
    raw = encoder.encode(struct)
    data = base64.b64encode(raw).decode('utf-8')

    width = 64
    chopped = [data[i:i + width] for i in range(0, len(data), width)]
    top = "-----BEGIN RSA PRIVATE KEY-----\n"
    content = "\n".join(chopped)
    bottom = "\n-----END RSA PRIVATE KEY-----"
    return top+content+bottom

def getInt(buf):
    return int.from_bytes(buf, byteorder='big')


def run(filename):
    with open(filename, 'r') as fp:
        keysdata = json.loads(fp.read())
    
    for jkey in keysdata:
        for keycomment, data in jkey.items():
            privatekey = extractRSAKey(data)
            print("[+] Key Comment: {}".format(keycomment))
            print(privatekey)
            print()
    
    sys.exit(0)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: {} extracted_keyblobs.json".format(sys.argv[0]))
        sys.exit(0)
    filename = sys.argv[1]
    run(filename)
    
"@

    Push-Location $tempDirectory

    $SSHAgentPrivateKeys = python .\extractPrivateKeys.py .\extracted_keyblobs.json

    [System.Collections.ArrayList]$UpdatedSSHAgentPrivKeyInfoArray = @()
    $SSHAgentPrivateKeysArrayList = [System.Collections.ArrayList]$SSHAgentPrivateKeys
    $NumberOfPrivateKeys = $($SSHAgentPrivateKeys | Where-Object {$_ -eq "-----END RSA PRIVATE KEY-----"}).Count
    for ($i=0; $i -lt $NumberOfPrivateKeys; $i++) {
        $SSHAgentPrivateKeysArrayListClone = $($SSHAgentPrivateKeysArrayList.Clone() -join "`n").Trim() -split "`n"
        New-Variable -Name "KeyInfo$i" -Value $(New-Object System.Collections.ArrayList) -Force

        :privkeylines foreach ($Line in $SSHAgentPrivateKeysArrayListClone) {
            if (![System.String]::IsNullOrWhiteSpace($Line)) {
                $null = $(Get-Variable -Name "KeyInfo$i" -ValueOnly).Add($Line)
                $SSHAgentPrivateKeysArrayList.Remove($Line)
            }
            else {
                break privkeylines
            }
        }

        $null = $UpdatedSSHAgentPrivKeyInfoArray.Add($(Get-Variable -Name "KeyInfo$i" -ValueOnly))
    }

    [System.Collections.ArrayList]$FinalSSHPrivKeyObjs = @()
    foreach ($PrivKeyInfoStringArray in $UpdatedSSHAgentPrivKeyInfoArray) {
        $OriginalPrivateKeyFilePath = $PrivKeyInfoStringArray[0] -replace "\[\+\] Key Comment: ",""
        $PrivateKeyContent = $PrivKeyInfoStringArray[1..$($PrivKeyInfoStringArray.Count-1)]
        $PSObj = [pscustomobject]@{
            OriginalPrivateKeyFilePath      = $OriginalPrivateKeyFilePath
            PrivateKeyContent               = $PrivateKeyContent
        }

        $null = $FinalSSHPrivKeyObjs.Add($PSObj)
    }

    Pop-Location

    Remove-Item $tempDirectory -Recurse -Force

    $FinalSSHPrivKeyObjs
}

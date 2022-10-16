---
external help file: pstools.psscriptinfo-help.xml
Module Name: pstools.psscriptinfo
online version:
schema: 2.0.0
---

# Update-PSScriptInfo

## SYNOPSIS

## SYNTAX

```
Update-PSScriptInfo [-FilePath] <FileInfo> [[-Properties] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Replaces PSScriptInfo settings.
Properties defined the properties  parameter that do not exist in the existing PSScriptInfo are added,  already existing settings set to $null are removed and existing  properties with a non-null value are updated.

## EXAMPLES

### EXAMPLE 1
```
Update-PSScriptInfo -Filepath C:\Script\Get-Test.ps1 -Properties @{Version="1.0.0.1";IsPreRelease=$null;IsReleased=$true}
```

Assuming that the specified file contains a PSScriptInfo block with the properties Version:"0.0.1.4" and IsPreRelease="true" this example would  - Update version

- Remove IsPreRelease
- Add IsReleased

\<#PSScriptInfo {     "Version":"1.0.0.1",     "IsReleased":"true" } PSScriptInfo \>

## PARAMETERS

### -FilePath
File path to file to update PSScriptInfo in.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
Hashtable with properties to add,remove and change.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

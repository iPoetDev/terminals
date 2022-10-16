---
external help file: pstools.psscriptinfo-help.xml
Module Name: pstools.psscriptinfo
online version:
schema: 2.0.0
---

# Add-PSScriptInfo

## SYNOPSIS

## SYNTAX

```
Add-PSScriptInfo [-FilePath] <FileInfo> [[-Properties] <Hashtable>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Add new PSScriptInfo to file

## EXAMPLES

### EXAMPLE 1
```
Add-PSScriptInfo -FilePath C:\Scripts\Do-Something.ps1 -Properties @{Version='1.0.0';Author='Jane Doe';DateCreated='2021-01-01'}
Adds a PSScriptInfo block containing the properties version and author. Resulting PSScriptInfo block
that would be added to the beginning of the file would look like:
```

\<#PSScriptInfo
{
    "Version" : "1.0.0",
    "Author" : "Jane Doe",
    "DateCreated" : "2021-01-01"
}
PSScriptInfo
\>

## PARAMETERS

### -FilePath
File to add PSScriptInfo to

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
HashTable (ordered dictionary) containing key value pairs for properties that should be included in PSScriptInfo

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

### -Force
Use force to replace any existing PSScriptInfo block

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

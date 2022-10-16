function Format-PSTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][System.Collections.ICollection] $Object,
        [switch] $SkipTitle,
        [string[]] $Property,
        [string[]] $ExcludeProperty,
        [Object] $OverwriteHeaders,
        [switch] $PreScanHeaders,
        [string] $Splitter = ';')
    if ($Object[0] -is [System.Collections.IDictionary]) {
        $Array = @(if (-not $SkipTitle) { , @('Name', 'Value') }
            foreach ($O in $Object) {
                foreach ($Name in $O.Keys) {
                    $Value = $O[$Name]
                    if ($O[$Name].Count -gt 1) { $Value = $O[$Name] -join $Splitter } else { $Value = $O[$Name] }
                    , @($Name, $Value)
                }
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    } elseif ($Object[0].GetType().Name -match 'bool|byte|char|datetime|decimal|double|ExcelHyperLink|float|int|long|sbyte|short|string|timespan|uint|ulong|URI|ushort') { return $Object } else {
        if ($Property) { $Object = $Object | Select-Object -Property $Property }
        $Array = @(if ($PreScanHeaders) { $Titles = Get-ObjectProperties -Object $Object } elseif ($OverwriteHeaders) { $Titles = $OverwriteHeaders } else { $Titles = $Object[0].PSObject.Properties.Name }
            if (-not $SkipTitle) { , $Titles }
            foreach ($O in $Object) {
                $ArrayValues = foreach ($Name in $Titles) {
                    $Value = $O."$Name"
                    if ($Value.Count -gt 1) { $Value -join $Splitter } elseif ($Value.Count -eq 1) { if ($Value.Value) { $Value.Value } else { $Value } } else { '' }
                }
                , $ArrayValues
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    }
}
function Format-TransposeTable {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][System.Collections.ICollection] $Object,
        [ValidateSet("ASC", "DESC", "NONE")][String] $Sort = 'NONE')
    begin { $i = 0 }
    process {
        foreach ($myObject in $Object) {
            if ($myObject -is [System.Collections.IDictionary]) {
                $output = New-Object -TypeName PsObject
                Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value { Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1] }
                if ($Sort -eq 'ASC') { $myObject.Keys | Sort-Object -Descending:$false | ForEach-Object { $output.AddNote($_, $myObject.$_) } } elseif ($Sort -eq 'DESC') { $myObject.Keys | Sort-Object -Descending:$true | ForEach-Object { $output.AddNote($_, $myObject.$_) } } else { $myObject.Keys | ForEach-Object { $output.AddNote($_, $myObject.$_) } }
                $output
            } else {
                $output = [ordered] @{ }
                $myObject | Get-Member -MemberType *Property | ForEach-Object { $output.($_.name) = $myObject.($_.name) }
                $output
            }
            $i += 1
        }
    }
}
function Get-FileName {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Extension
    Parameter description

    .PARAMETER Temporary
    Parameter description

    .PARAMETER TemporaryFileOnly
    Parameter description

    .EXAMPLE
    Get-FileName -Temporary
    Output: 3ymsxvav.tmp

    .EXAMPLE

    Get-FileName -Temporary
    Output: C:\Users\pklys\AppData\Local\Temp\tmpD74C.tmp

    .EXAMPLE

    Get-FileName -Temporary -Extension 'xlsx'
    Output: C:\Users\pklys\AppData\Local\Temp\tmp45B6.xlsx


    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([string] $Extension = 'tmp',
        [switch] $Temporary,
        [switch] $TemporaryFileOnly)
    if ($Temporary) { return "$($([System.IO.Path]::GetTempFileName()).Replace('.tmp','')).$Extension" }
    if ($TemporaryFileOnly) { return "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).$Extension" }
}
function Get-ObjectCount {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Object]$Object)
    return $($Object | Measure-Object).Count
}
function Get-ObjectProperties {
    [CmdletBinding()]
    param ([System.Collections.ICollection] $Object,
        [string[]] $AddProperties,
        [switch] $Sort,
        [bool] $RequireUnique = $true)
    $Properties = @(foreach ($O in $Object) {
            $ObjectProperties = $O.PSObject.Properties.Name
            $ObjectProperties
        }
        foreach ($Property in $AddProperties) { $Property })
    if ($Sort) { return $Properties | Sort-Object -Unique:$RequireUnique } else { return $Properties | Select-Object -Unique:$RequireUnique }
}
function Get-ColorFromARGB {
    [CmdletBinding()]
    param([int] $A,
        [int] $R,
        [int] $G,
        [int] $B)
    return [system.drawing.color]::FromArgb($A, $R, $G, $B)
}
function Set-WordContinueFormatting {
    param([int] $Count,
        [alias ("C")] [System.Drawing.KnownColor[]]$Color = @(),
        [alias ("S")] [double[]] $FontSize = @(),
        [alias ("FontName")] [string[]] $FontFamily = @(),
        [alias ("B")] [nullable[bool][]] $Bold = @(),
        [alias ("I")] [nullable[bool][]] $Italic = @(),
        [alias ("U")] [Xceed.Document.NET.UnderlineStyle[]] $UnderlineStyle = @(),
        [alias ('UC')] [System.Drawing.KnownColor[]]$UnderlineColor = @(),
        [alias ("SA")] [double[]] $SpacingAfter = @(),
        [alias ("SB")] [double[]] $SpacingBefore = @(),
        [alias ("SP")] [double[]] $Spacing = @(),
        [alias ("H")] [Xceed.Document.NET.Highlight[]] $Highlight = @(),
        [alias ("CA")] [Xceed.Document.NET.CapsStyle[]] $CapsStyle = @(),
        [alias ("ST")] [Xceed.Document.NET.StrikeThrough[]] $StrikeThrough = @(),
        [alias ("HT")] [Xceed.Document.NET.HeadingType[]] $HeadingType = @(),
        [int[]] $PercentageScale = @(),
        [Xceed.Document.NET.Misc[]] $Misc = @(),
        [string[]] $Language = @(),
        [int[]]$Kerning = @(),
        [nullable[bool][]]$Hidden = @(),
        [int[]]$Position = @(),
        [single[]] $IndentationFirstLine = @(),
        [single[]] $IndentationHanging = @(),
        [Xceed.Document.NET.Alignment[]] $Alignment = @(),
        [Xceed.Document.NET.Direction[]] $DirectionFormatting = @(),
        [Xceed.Document.NET.ShadingType[]] $ShadingType = @(),
        [Xceed.Document.NET.Script[]] $Script = @())
    for ($RowNr = 0; $RowNr -le $Count; $RowNr++) {
        Write-Verbose "Set-WordContinueFormatting - RowNr: $RowNr / $Count"
        if ($null -eq $Color[$RowNr] -and $null -ne $Color[$RowNr - 1]) { $Color += $Color[$RowNr - 1] }
        if ($null -eq $FontSize[$RowNr] -and $null -ne $FontSize[$RowNr - 1]) { $FontSize += $FontSize[$RowNr - 1] }
        if ($null -eq $FontFamily[$RowNr] -and $null -ne $FontFamily[$RowNr - 1]) { $FontFamily += $FontFamily[$RowNr - 1] }
        if ($null -eq $Bold[$RowNr] -and $null -ne $Bold[$RowNr - 1]) { $Bold += $Bold[$RowNr - 1] }
        if ($null -eq $Italic[$RowNr] -and $null -ne $Italic[$RowNr - 1]) { $Italic += $Italic[$RowNr - 1] }
        if ($null -eq $SpacingAfter[$RowNr] -and $null -ne $SpacingAfter[$RowNr - 1]) { $SpacingAfter += $SpacingAfter[$RowNr - 1] }
        if ($null -eq $SpacingBefore[$RowNr] -and $null -ne $SpacingBefore[$RowNr - 1]) { $SpacingBefore += $SpacingBefore[$RowNr - 1] }
        if ($null -eq $Spacing[$RowNr] -and $null -ne $Spacing[$RowNr - 1]) { $Spacing += $Spacing[$RowNr - 1] }
        if ($null -eq $Highlight[$RowNr] -and $null -ne $Highlight[$RowNr - 1]) { $Highlight += $Highlight[$RowNr - 1] }
        if ($null -eq $CapsStyle[$RowNr] -and $null -ne $CapsStyle[$RowNr - 1]) { $CapsStyle += $CapsStyle[$RowNr - 1] }
        if ($null -eq $StrikeThrough[$RowNr] -and $null -ne $StrikeThrough[$RowNr - 1]) { $StrikeThrough += $StrikeThrough[$RowNr - 1] }
        if ($null -eq $HeadingType[$RowNr] -and $null -ne $HeadingType[$RowNr - 1]) { $HeadingType += $HeadingType[$RowNr - 1] }
        if ($null -eq $PercentageScale[$RowNr] -and $null -ne $PercentageScale[$RowNr - 1]) { $PercentageScale += $PercentageScale[$RowNr - 1] }
        if ($null -eq $Misc[$RowNr] -and $null -ne $Misc[$RowNr - 1]) { $Misc += $Misc[$RowNr - 1] }
        if ($null -eq $Language[$RowNr] -and $null -ne $Language[$RowNr - 1]) { $Language += $Language[$RowNr - 1] }
        if ($null -eq $Kerning[$RowNr] -and $null -ne $Kerning[$RowNr - 1]) { $Kerning += $Kerning[$RowNr - 1] }
        if ($null -eq $Hidden[$RowNr] -and $null -ne $Hidden[$RowNr - 1]) { $Hidden += $Hidden[$RowNr - 1] }
        if ($null -eq $Position[$RowNr] -and $null -ne $Position[$RowNr - 1]) { $Position += $Position[$RowNr - 1] }
        if ($null -eq $IndentationFirstLine[$RowNr] -and $null -ne $IndentationFirstLine[$RowNr - 1]) { $IndentationFirstLine += $IndentationFirstLine[$RowNr - 1] }
        if ($null -eq $IndentationHanging[$RowNr] -and $null -ne $IndentationHanging[$RowNr - 1]) { $IndentationHanging += $IndentationHanging[$RowNr - 1] }
        if ($null -eq $Alignment[$RowNr] -and $null -ne $Alignment[$RowNr - 1]) { $Alignment += $Alignment[$RowNr - 1] }
        if ($null -eq $DirectionFormatting[$RowNr] -and $null -ne $DirectionFormatting[$RowNr - 1]) { $DirectionFormatting += $DirectionFormatting[$RowNr - 1] }
        if ($null -eq $ShadingType[$RowNr] -and $null -ne $ShadingType[$RowNr - 1]) { $ShadingType += $ShadingType[$RowNr - 1] }
        if ($null -eq $Script[$RowNr] -and $null -ne $Script[$RowNr - 1]) { $Script += $Script[$RowNr - 1] }
    }
    Write-Verbose "Set-WordContinueFormatting - Alignment: $Alignment"
    return @($Color,
        $FontSize,
        $FontFamily,
        $Bold,
        $Italic,
        $UnderlineStyle,
        $UnderlineColor,
        $SpacingAfter,
        $SpacingBefore,
        $Spacing,
        $Highlight,
        $CapsStyle,
        $StrikeThrough,
        $HeadingType,
        $PercentageScale,
        $Misc,
        $Language,
        $Kerning,
        $Hidden,
        $Position,
        $IndentationFirstLine,
        $IndentationHanging,
        $Alignment,
        $DirectionFormatting,
        $ShadingType,
        $Script)
}
function Set-WordTextText {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [alias ("S")][AllowNull()] $Text,
        [switch]$Append,
        [bool] $Supress = $false)
    if ($Paragraph) {
        if ($Text) {
            if ($Text -isnot [String]) { throw 'Invalid argument for parameter -Text.' }
            if ($Append -ne $true) { $Paragraph = Remove-WordText -Paragraph $Paragraph }
            Write-Verbose "Set-WordTextText - Appending Value $Text"
            $Paragraph = $Paragraph.Append($Text)
        }
    }
    if ($Supress) { return } else { return $Paragraph }
}
function New-WordBlock {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $true)][Xceed.Document.NET.Container]$WordDocument,
        [nullable[bool]] $TocGlobalDefinition,
        [string] $TocGlobalTitle,
        [int] $TocGlobalRightTabPos,
        [Xceed.Document.NET.TableOfContentsSwitches[]] $TocGlobalSwitches,
        [nullable[bool]] $TocEnable,
        [string] $TocText,
        [int] $TocListLevel,
        [nullable[Xceed.Document.NET.ListItemType]] $TocListItemType,
        [nullable[Xceed.Document.NET.HeadingType]] $TocHeadingType,
        [int] $EmptyParagraphsBefore,
        [int] $EmptyParagraphsAfter,
        [int] $PageBreaksBefore,
        [int] $PageBreaksAfter,
        [string] $Text,
        [string] $TextNoData,
        [nullable[Xceed.Document.NET.Alignment][]] $TextAlignment = [Xceed.Document.NET.Alignment]::Both,
        [Object] $TableData,
        [nullable[Xceed.Document.NET.TableDesign]] $TableDesign = [Xceed.Document.NET.TableDesign]::None,
        [nullable[int]] $TableMaximumColumns = 5,
        [nullable[bool]] $TableTitleMerge,
        [string] $TableTitleText,
        [nullable[Xceed.Document.NET.Alignment]] $TableTitleAlignment = 'center',
        [nullable[System.Drawing.KnownColor]] $TableTitleColor = 'Black',
        [switch] $TableTranspose,
        [float[]] $TableColumnWidths,
        [Object] $ListData,
        [nullable[Xceed.Document.NET.ListItemType]] $ListType,
        [string] $ListTextEmpty,
        [string[]] $ListBuilderContent,
        [Xceed.Document.NET.ListItemType[]] $ListBuilderType,
        [int[]] $ListBuilderLevel,
        [Object] $TextBasedData,
        [nullable[Xceed.Document.NET.Alignment][]] $TextBasedDataAlignment = [Xceed.Document.NET.Alignment]::Both,
        [nullable[bool]] $ChartEnable,
        [string] $ChartTitle,
        $ChartKeys,
        $ChartValues,
        [Xceed.Document.NET.ChartLegendPosition] $ChartLegendPosition = [Xceed.Document.NET.ChartLegendPosition]::Bottom,
        [bool] $ChartLegendOverlay)
    $WordDocument | New-WordBlockPageBreak -PageBreaks $PageBreaksBefore
    if ($TocGlobalDefinition) { Add-WordToc -WordDocument $WordDocument -Title $TocGlobalTitle -Switches $TocGlobalSwitches -RightTabPos $TocGlobalRightTabPos -Supress $True }
    if ($TocEnable) { $TOC = $WordDocument | Add-WordTocItem -Text $TocText -ListLevel $TocListLevel -ListItemType $TocListItemType -HeadingType $TocHeadingType }
    $WordDocument | New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsBefore
    if ($Text) { if ($TableData -or $ListData -or ($ChartEnable -and ($ChartKeys.Count -gt 0) -or ($ChartValues.Count -gt 0)) -or $ListBuilderContent -or (-not $TextNoData)) { $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $Text -Alignment $TextAlignment } else { if ($TextNoData) { $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $TextNoData -Alignment $TextAlignment } } }
    if ($TableData -and $TableDesign) {
        if ($TableTitleMerge) { $OverwriteTitle = $TableTitleText }
        if ($TableColumnWidths) { Add-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -DataTable $TableData -AutoFit Window -Design $TableDesign -DoNotAddTitle:$TableTitleMerge -MaximumColumns $TableMaximumColumns -Transpose:$TableTranspose -ColumnWidth $TableColumnWidths -OverwriteTitle $OverwriteTitle -Supress $True } else { Add-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -DataTable $TableData -AutoFit Window -Design $TableDesign -DoNotAddTitle:$TableTitleMerge -MaximumColumns $TableMaximumColumns -Transpose:$TableTranspose -OverwriteTitle $OverwriteTitle -Supress $True }
    }
    if ($ListData) {
        if ((Get-ObjectCount $ListData) -gt 0) {
            Write-Verbose 'New-WordBlock - Adding ListData'
            $List = Add-WordList -WordDocument $WordDocument -ListType $ListType -Paragraph $Paragraph -ListData $ListData
        } else {
            Write-Verbose 'New-WordBlock - Adding ListData - Empty List'
            $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $ListTextEmpty
        }
    }
    if ($ListBuilderContent) { $Paragraph = New-WordList -WordDocument $WordDocument -Type $ListBuilderType[0] { for ($a = 0; $a -lt $ListBuilderContent.Count; $a++) { New-WordListItem -ListLevel $ListBuilderLevel[$a] -ListValue $ListBuilderContent[$a] } } -Supress $False }
    if ($TextBasedData) { $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $TextBasedData -Alignment $TextBasedDataAlignment }
    if ($ChartEnable) {
        $WordDocument | New-WordBlockParagraph -EmptyParagraphs 1
        if (($ChartKeys.Count -eq 0) -or ($ChartValues.Count -eq 0)) { } else { Add-WordPieChart -WordDocument $WordDocument -ChartName $ChartTitle -Names $ChartKeys -Values $ChartValues -ChartLegendPosition $ChartLegendPosition -ChartLegendOverlay $ChartLegendOverlay }
    }
    $WordDocument | New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsAfter
    $WordDocument | New-WordBlockPageBreak -PageBreaks $PageBreaksAfter
}
function New-WordBlockList {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $true)][Xceed.Document.NET.Container]$WordDocument,
        [bool] $TocEnable,
        [string] $TocText,
        [int] $TocListLevel,
        [Xceed.Document.NET.ListItemType] $TocListItemType,
        [Xceed.Document.NET.HeadingType] $TocHeadingType,
        [int] $EmptyParagraphsBefore,
        [int] $EmptyParagraphsAfter,
        [string] $Text,
        [string] $TextListEmpty,
        [Object] $ListData,
        [Xceed.Document.NET.ListItemType] $ListType)
    if ($TocEnable) { $TOC = $WordDocument | Add-WordTocItem -Text $TocText -ListLevel $TocListLevel -ListItemType $TocListItemType -HeadingType $TocHeadingType }
    New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsBefore -WordDocument $WordDocument
    $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $Text
    if ((Get-ObjectCount $ListData) -gt 0) { $List = Add-WordList -WordDocument $WordDocument -ListType $ListType -Paragraph $Paragraph -ListData $ListData } else { $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $TextListEmpty }
    New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsAfter -WordDocument $WordDocument
}
function New-WordBlockPageBreak {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $true)][Xceed.Document.NET.Container]$WordDocument,
        [int] $PageBreaks,
        [bool] $Supress)
    $i = 0
    While ($i -lt $PageBreaks) {
        Write-Verbose "New-WordBlockPageBreak - PageBreak $i"
        $WordDocument | Add-WordPageBreak -Supress $True
        $i++
    }
}
function New-WordBlockParagraph {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $true)][Xceed.Document.NET.Container]$WordDocument,
        [int] $EmptyParagraphs)
    $i = 0
    While ($i -lt $EmptyParagraphs) {
        Write-Verbose "New-WordBlockList - EmptyParagraphs $i"
        $Paragraph = Add-WordParagraph -WordDocument $WordDocument
        $i++
    }
}
function New-WordBlockTable {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $true)][Xceed.Document.NET.Container]$WordDocument,
        [bool] $TocEnable,
        [string] $TocText,
        [int] $TocListLevel,
        [Xceed.Document.NET.ListItemType] $TocListItemType,
        [Xceed.Document.NET.HeadingType] $TocHeadingType,
        [int] $EmptyParagraphsBefore,
        [int] $EmptyParagraphsAfter,
        [int] $PageBreaksBefore,
        [int] $PageBreaksAfter,
        [string] $Text,
        [Object] $TableData,
        [nullable[Xceed.Document.NET.TableDesign]] $TableDesign,
        [int] $TableMaximumColumns = 5,
        [nullable[bool]] $TableTitleMerge,
        [string] $TableTitleText,
        [nullable[Xceed.Document.NET.Alignment]] $TableTitleAlignment = 'center',
        [nullable[System.Drawing.KnownColor]] $TableTitleColor = 'Black',
        [switch] $TableTranspose,
        [nullable[bool]] $ChartEnable,
        [string] $ChartTitle,
        $ChartKeys,
        $ChartValues,
        [Xceed.Document.NET.ChartLegendPosition] $ChartLegendPosition = [Xceed.Document.NET.ChartLegendPosition]::Bottom,
        [bool] $ChartLegendOverlay)
    $WordDocument | New-WordBlockPageBreak -PageBreaks $PageBreaksBefore
    if ($TocEnable) { $TOC = $WordDocument | Add-WordTocItem -Text $TocText -ListLevel $TocListLevel -ListItemType $TocListItemType -HeadingType $TocHeadingType }
    $WordDocument | New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsBefore
    $Paragraph = Add-WordText -WordDocument $WordDocument -Paragraph $Paragraph -Text $Text
    if ($TableData) {
        $Table = Add-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -DataTable $TableData -AutoFit Window -Design $TableDesign -DoNotAddTitle:$TableTitleMerge -MaximumColumns $TableMaximumColumns -Transpose:$TableTranspose
        if ($TableTitleMerge) {
            $Table = Set-WordTableRowMergeCells -Table $Table -RowNr 0 -MergeAll
            if ($TableTitleText -ne $null) {
                $TableParagraph = Get-WordTableRow -Table $Table -RowNr 0 -ColumnNr 0
                $TableParagraph = Set-WordText -Paragraph $TableParagraph -Text $TableTitleText -Alignment $TableTitleAlignment -Color $TableTitleColor
            }
        }
    }
    if ($ChartEnable) {
        $WordDocument | New-WordBlockParagraph -EmptyParagraphs 1
        Add-WordPieChart -WordDocument $WordDocument -ChartName $ChartTitle -Names $ChartKeys -Values $ChartValues -ChartLegendPosition $ChartLegendPosition -ChartLegendOverlay $ChartLegendOverlay
    }
    $WordDocument | New-WordBlockParagraph -EmptyParagraphs $EmptyParagraphsAfter
    $WordDocument | New-WordBlockPageBreak -PageBreaks $PageBreaksAfter
}
function Add-WordBarChart {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $ChartName,
        [string[]] $Names,
        [int[]] $Values,
        [Xceed.Document.NET.Series[]] $ChartSeries,
        [Xceed.Document.NET.ChartLegendPosition] $ChartLegendPosition = [Xceed.Document.NET.ChartLegendPosition]::Left,
        [bool] $ChartLegendOverlay = $false,
        [Xceed.Document.NET.BarGrouping] $BarGrouping = [Xceed.Document.NET.BarGrouping]::Standard,
        [Xceed.Document.NET.BarDirection] $BarDirection = [Xceed.Document.NET.BarDirection]::Bar,
        [int] $BarGapWidth = 200,
        [switch] $NoLegend)
    if ($null -eq $ChartSeries) { $ChartSeries = Add-WordChartSeries -ChartName $ChartName -Names $Names -Values $Values }
    [Xceed.Document.NET.BarChart] $chart = [Xceed.Document.NET.BarChart]::new()
    $chart.BarDirection = $BarDirection
    $chart.BarGrouping = $BarGrouping
    $chart.GapWidth = $BarGapWidth
    if (-not $NoLegend) { $chart.AddLegend($ChartLegendPosition, $ChartLegendOverlay) }
    foreach ($series in $ChartSeries) { $chart.AddSeries($Series) }
    if ($Paragraph -eq $null) { $WordDocument.InsertChart($chart) } else { $WordDocument.InsertChartAfterParagraph($chart, $paragraph) }
}
function Add-WordChartSeries {
    [CmdletBinding()]
    param ([string] $ChartName = 'Legend',
        [string[]] $Names,
        [int[]] $Values)
    [Array] $rNames = foreach ($Name in $Names) { $Name }
    [Array] $rValues = foreach ($value in $Values) { $value }
    [Xceed.Document.NET.Series] $series = [Xceed.Document.NET.Series]::new($ChartName)
    $Series.Bind($rNames, $rValues)
    return $Series
}
function Add-WordLineChart {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $ChartName,
        [string[]] $Names,
        [int[]] $Values,
        [Xceed.Document.NET.Series[]] $ChartSeries,
        [Xceed.Document.NET.ChartLegendPosition] $ChartLegendPosition = [Xceed.Document.NET.ChartLegendPosition]::Left,
        [bool] $ChartLegendOverlay = $false,
        [switch] $NoLegend)
    if ($null -eq $ChartSeries) { $ChartSeries = Add-WordChartSeries -ChartName $ChartName -Names $Names -Values $Values }
    [Xceed.Document.NET.LineChart] $chart = [Xceed.Document.NET.LineChart]::new()
    if (-not $NoLegend) { $chart.AddLegend($ChartLegendPosition, $ChartLegendOverlay) }
    foreach ($series in $ChartSeries) { $chart.AddSeries($Series) }
    if ($Paragraph -eq $null) { $WordDocument.InsertChart($chart) } else { $WordDocument.InsertChartAfterParagraph($chart, $paragraph) }
}
function Add-WordPieChart {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $ChartName,
        [string[]] $Names,
        [int[]] $Values,
        [Xceed.Document.NET.ChartLegendPosition] $ChartLegendPosition = [Xceed.Document.NET.ChartLegendPosition]::Left,
        [bool] $ChartLegendOverlay = $false,
        [switch] $NoLegend)
    $Series = Add-WordChartSeries -ChartName $ChartName -Names $Names -Values $Values
    [Xceed.Document.NET.PieChart] $chart = [Xceed.Document.NET.PieChart]::new()
    if (-not $NoLegend) { $chart.AddLegend($ChartLegendPosition, $ChartLegendOverlay) }
    $chart.AddSeries($Series)
    if ($null -eq $Paragraph) { $WordDocument.InsertChart($chart) } else { $WordDocument.InsertChartAfterParagraph($chart, $paragraph) }
}
function Add-WordFooter {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [nullable[bool]] $DifferentFirstPage,
        [nullable[bool]] $DifferentOddAndEvenPages,
        [bool] $Supress = $false)
    $WordDocument.AddFooters()
    if ($DifferentOddAndEvenPages -ne $null) { $WordDocument.DifferentFirstPage = $DifferentFirstPage }
    if ($DifferentOddAndEvenPages -ne $null) { $WordDocument.DifferentOddAndEvenPages = $DifferentOddAndEvenPages }
    if ($Supress) { return } else { return $WordDocument.Footers }
}
function Add-WordHeader {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [nullable[bool]] $DifferentFirstPage,
        [nullable[bool]] $DifferentOddAndEvenPages,
        [bool] $Supress = $false)
    $WordDocument.AddHeaders()
    if ($DifferentOddAndEvenPages -ne $null) { $WordDocument.DifferentFirstPage = $DifferentFirstPage }
    if ($DifferentOddAndEvenPages -ne $null) { $WordDocument.DifferentOddAndEvenPages = $DifferentOddAndEvenPages }
    if ($Supress) { return } else { return $WordDocument.Headers }
}
function Get-WordFooter {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [ValidateSet('All', 'First', 'Even', 'Odd')][string] $Type = 'All',
        [bool] $Supress = $false)
    if ($Type -eq 'All') { $WordDocument.Footers } else { $WordDocument.Footers.$Type }
}
function Get-WordHeader {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [ValidateSet('All', 'First', 'Even', 'Odd')][string] $Type = 'All',
        [bool] $Supress = $false)
    if ($Type -eq 'All') { $WordDocument.Headers } else { $WordDocument.Headers.$Type }
}
function Add-WordHyperLink {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)] [Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)] [Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $UrlText,
        [uri] $UrlLink,
        [alias ("C")] [System.Drawing.KnownColor]$Color,
        [alias ("S")] [double] $FontSize,
        [alias ("FontName")] [string] $FontFamily,
        [alias ("B")] [nullable[bool]] $Bold,
        [alias ("I")] [nullable[bool]] $Italic,
        [alias ("U")] [Xceed.Document.NET.UnderlineStyle] $UnderlineStyle,
        [alias ('UC')] [System.Drawing.KnownColor]$UnderlineColor,
        [alias ("SA")] [double] $SpacingAfter,
        [alias ("SB")] [double] $SpacingBefore,
        [alias ("SP")] [double] $Spacing,
        [alias ("H")] [Xceed.Document.NET.Highlight] $Highlight,
        [alias ("CA")] [Xceed.Document.NET.CapsStyle] $CapsStyle,
        [alias ("ST")] [Xceed.Document.NET.StrikeThrough] $StrikeThrough,
        [alias ("HT")] [Xceed.Document.NET.HeadingType] $HeadingType,
        [int] $PercentageScale,
        [Xceed.Document.NET.Misc] $Misc,
        [string] $Language,
        [int]$Kerning,
        [nullable[bool]]$Hidden,
        [int]$Position,
        [nullable[bool]]$NewLine,
        [single] $IndentationFirstLine,
        [single] $IndentationHanging,
        [Xceed.Document.NET.Alignment] $Alignment,
        [Xceed.Document.NET.Direction] $Direction,
        [Xceed.Document.NET.ShadingType] $ShadingType,
        [System.Drawing.KnownColor]$ShadingColor,
        [Xceed.Document.NET.Script] $Script,
        [bool] $Supress = $false)
    $HyperLink = $WordDocument.AddHyperlink($UrlText, $UrlLink)
    if (-not $Paragraph) { $Paragraph = $WordDocument.InsertParagraph() }
    if ($Paragraph -and $HyperLink) { $Data = $Paragraph.AppendHyperlink($HyperLink) }
    if ($Color) { $Paragraph = $Paragraph | Set-WordTextColor -Color $Color -Supress $false }
    if ($FontSize) { $Paragraph = $Paragraph | Set-WordTextFontSize -FontSize $FontSize -Supress $false }
    if ($FontFamily) { $Paragraph = $Paragraph | Set-WordTextFontFamily -FontFamily $FontFamily -Supress $false }
    if ($Bold) { $Paragraph = $Paragraph | Set-WordTextBold -Bold $Bold -Supress $false }
    if ($Italic) { $Paragraph = $Paragraph | Set-WordTextItalic -Italic $Italic -Supress $false }
    if ($UnderlineColor) { $Paragraph = $Paragraph | Set-WordTextUnderlineColor -UnderlineColor $UnderlineColor -Supress $false }
    if ($UnderlineStyle) { $Paragraph = $Paragraph | Set-WordTextUnderlineStyle -UnderlineStyle $UnderlineStyle -Supress $false }
    if ($SpacingAfter) { $Paragraph = $Paragraph | Set-WordTextSpacingAfter -SpacingAfter $SpacingAfter -Supress $false }
    if ($SpacingBefore) { $Paragraph = $Paragraph | Set-WordTextSpacingBefore -SpacingBefore $SpacingBefore -Supress $false }
    if ($Spacing) { $Paragraph = $Paragraph | Set-WordTextSpacing -Spacing $Spacing -Supress $false }
    if ($Highlight) { $Paragraph = $Paragraph | Set-WordTextHighlight -Highlight $Highlight -Supress $false }
    if ($CapsStyle) { $Paragraph = $Paragraph | Set-WordTextCapsStyle -CapsStyle $CapsStyle -Supress $false }
    if ($StrikeThrough) { $Paragraph = $Paragraph | Set-WordTextStrikeThrough -StrikeThrough $StrikeThrough -Supress $false }
    if ($PercentageScale) { $Paragraph = $Paragraph | Set-WordTextPercentageScale -PercentageScale $PercentageScale -Supress $false }
    if ($Language) { $Paragraph = $Paragraph | Set-WordTextLanguage -Language $Language -Supress $false }
    if ($Kerning) { $Paragraph = $Paragraph | Set-WordTextKerning -Kerning $Kerning -Supress $false }
    if ($Misc) { $Paragraph = $Paragraph | Set-WordTextMisc -Misc $Misc -Supress $false }
    if ($Position) { $Paragraph = $Paragraph | Set-WordTextPosition -Position $Position -Supress $false }
    if ($Hidden) { $Paragraph = $Paragraph | Set-WordTextHidden -Hidden $Hidden -Supress $false }
    if ($ShadingColor) { $Paragraph = $Paragraph | Set-WordTextShadingType -ShadingColor $ShadingColor -ShadingType $ShadingType -Supress $false }
    if ($Script) { $Paragraph = $Paragraph | Set-WordTextScript -Script $Script -Supress $false }
    if ($HeadingType) { $Paragraph = $Paragraph | Set-WordTextHeadingType -HeadingType $HeadingType -Supress $false }
    if ($IndentationFirstLine) { $Paragraph = $Paragraph | Set-WordTextIndentationFirstLine -IndentationFirstLine $IndentationFirstLine -Supress $false }
    if ($IndentationHanging) { $Paragraph = $Paragraph | Set-WordTextIndentationHanging -IndentationHanging $IndentationHanging -Supress $false }
    if ($Alignment) { $Paragraph = $Paragraph | Set-WordTextAlignment -Alignment $Alignment -Supress $false }
    if ($Direction) { $Paragraph = $Paragraph | Set-WordTextDirection -Direction $Direction -Supress $false }
    if ($Supress -eq $false) { return $Data } else { return }
}
function Add-WordList {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [alias('ListType')][Xceed.Document.NET.ListItemType] $Type = [Xceed.Document.NET.ListItemType]::Bulleted,
        [alias('DataTable')][Array] $ListData,
        [int] $BehaviourOption = 0,
        [Array] $ListLevels,
        [bool] $Supress = $false)
    if ($ListData.Count -gt 0) {
        if ($ListData[0].GetType() -match 'bool|byte|char|datetime|decimal|double|float|int|long|sbyte|short|string|timespan|uint|ulong|URI|ushort') {
            $Counter = 0
            $Data = New-WordList -WordDocument $WordDocument -Type $Type { foreach ($Item in $ListData) {
                    if ($ListLevels) { New-WordListItem -Level $ListLevels[$Counter] -Text $Item } else { New-WordListItem -Level 0 -Text $Item }
                    $Counter++
                } } -Supress $Supress
        } elseif ($ListData[0] -is [System.Collections.IDictionary]) {
            $Data = New-WordList -WordDocument $WordDocument -Type $Type { foreach ($Object in $ListData) {
                    foreach ($O in $Object.GetEnumerator()) {
                        $TextMain = $($O.Name)
                        $TextSub = $($O.Value)
                        if ($BehaviourOption -eq 0) {
                            New-WordListItem -ListLevel 0 -ListValue $TextMain
                            foreach ($TextValue in $TextSub) { New-WordListItem -ListLevel 1 -ListValue $TextValue }
                        } elseif ($BehaviourOption -eq 1) {
                            $TextSub = $TextSub -Join ", "
                            $Value = "$TextMain - $TextSub"
                            New-WordListItem -ListLevel 0 -ListValue $Value
                        }
                    }
                } } -Supress $supress
        } else {
            $Data = New-WordList -WordDocument $WordDocument -Type $Type { foreach ($Object in $ListData) {
                    $Titles = $Object.PSObject.Properties.Name
                    foreach ($Text in $Titles) {
                        $TextMain = $Text
                        $TextSub = $($Object.$Text)
                        if ($BehaviourOption -eq 0) {
                            New-WordListItem -ListLevel 0 -ListValue $TextMain
                            foreach ($TextValue in $TextSub) { New-WordListItem -ListLevel 1 -ListValue $TextValue }
                        } elseif ($BehaviourOption -eq 1) {
                            $TextSub = $TextSub -Join ", "
                            $Value = "$TextMain - $TextSub"
                            New-WordListItem -ListLevel 0 -ListValue $Value
                        }
                    }
                } } -Supress $Supress
        }
        if ($supress -eq $false) { return $Data } else { return }
    }
}
function Add-WordListItem {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $List,
        [Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Document.NET.InsertBeforeOrAfter] $InsertWhere = [Xceed.Document.NET.InsertBeforeOrAfter]::AfterSelf,
        [bool] $Supress)
    if ($null -ne $Paragraph) { if ($InsertWhere -eq [Xceed.Document.NET.InsertBeforeOrAfter]::AfterSelf) { $data = $Paragraph.InsertListAfterSelf($List) } elseif ($InsertWhere -eq [Xceed.Document.NET.InsertBeforeOrAfter]::AfterSelf) { $data = $Paragraph.InsertListBeforeSelf($List) } } else { $data = $WordDocument.InsertList($List) }
    if ($Supress) { return } else { $data }
}
function Convert-ListToHeadings {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $List,
        [alias ("HT")] [Xceed.Document.NET.HeadingType] $HeadingType = [Xceed.Document.NET.HeadingType]::Heading1,
        [bool] $Supress)
    Write-Verbose "Convert-ListToHeadings - NumID: $($List.NumID)"
    $Paragraphs = Get-WordParagraphForList -WordDocument $WordDocument -ListID $List.NumID
    Write-Verbose "Convert-ListToHeadings - List Elements Count: $($Paragraphs.Count)"
    $ParagraphsWithHeadings = foreach ($p in $Paragraphs) {
        Write-Verbose "Convert-ListToHeadings - Loop: $HeadingType"
        $p.StyleName = $HeadingType
        $p
    }
    if ($Supress) { return } else { return $ParagraphsWithHeadings }
}
function New-WordList {
    [CmdletBinding()]
    param([ScriptBlock] $ListItems,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [int] $BehaviourOption = 0,
        [alias('ListType')][Xceed.Document.NET.ListItemType] $Type = [Xceed.Document.NET.ListItemType]::Bulleted,
        [bool] $Supress = $true)
    if ($ListItems) {
        $Parameters = Invoke-Command -ScriptBlock $ListItems
        $List = $null
        foreach ($Item in $Parameters) {
            if ($null -eq $List) {
                $List = $WordDocument.AddList($Item.Text, $Item.Level, $Type, $Item.StartNumber, $Item.TrackChanges, $Item.ContinueNumbering)
                $Paragraph = $List.Items[$List.Items.Count - 1]
            } else {
                $List = $WordDocument.AddListItem($List, $Item.Text, $Item.Level, $Type, $Item.StartNumber, $Item.TrackChanges, $Item.ContinueNumbering)
                $Paragraph = $List.Items[$List.Items.Count - 1]
            }
        }
        Add-WordListItem -WordDocument $WordDocument -List $List -Supress $true
        if (-not $Supress) { $List }
    }
}
function New-WordListItem {
    [CmdletBinding()]
    param([alias('ListLevel')][ValidateRange(0, 8)] [int] $Level,
        [alias('Value', 'ListValue')][string] $Text,
        [nullable[int]] $StartNumber,
        [bool]$TrackChanges = $false,
        [bool]$ContinueNumbering = $false,
        [bool]$Supress = $false)
    [PSCustomObject] @{ObjectType = 'ListItem'
        Level                     = $Level
        Text                      = $Text
        StartNumber               = $StartNumber
        TrackChanges              = $TrackChanges
        ContinueNumbering         = $ContinueNumbering
    }
}
function New-WordListItemInternal {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $List,
        [alias('Level')] [ValidateRange(0, 8)] [int] $ListLevel,
        [alias('ListType')][Xceed.Document.NET.ListItemType] $ListItemType = [Xceed.Document.NET.ListItemType]::Bulleted,
        [alias('Value', 'ListValue')]$Text,
        [nullable[int]] $StartNumber,
        [bool]$TrackChanges = $false,
        [bool]$ContinueNumbering = $false,
        [bool]$Supress = $false)
    if ($null -eq $List) { $List = $WordDocument.AddList($Text, $ListLevel, $ListItemType, $StartNumber, $TrackChanges, $ContinueNumbering) } else { $List = $WordDocument.AddListItem($List, $Text, $ListLevel, $ListItemType, $StartNumber, $TrackChanges, $ContinueNumbering) }
    $null = $List.Items[$List.Items.Count - 1]
    Write-Verbose "Add-WordListItem - ListType Value: $Text Name: $($List.GetType().Name) - BaseType: $($List.GetType().BaseType)"
    return $List
}
function Set-WordList {
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $List,
        [int] $ParagraphNumber = 0,
        [alias ("C")] [nullable[System.Drawing.KnownColor]]$Color,
        [alias ("S")] [nullable[double]] $FontSize,
        [alias ("FontName")] [string] $FontFamily,
        [alias ("B")] [nullable[bool]] $Bold,
        [alias ("I")] [nullable[bool]] $Italic,
        [alias ("U")] [nullable[Xceed.Document.NET.UnderlineStyle]] $UnderlineStyle,
        [alias ('UC')] [nullable[System.Drawing.KnownColor]]$UnderlineColor,
        [alias ("SA")] [nullable[double]] $SpacingAfter,
        [alias ("SB")] [nullable[double]] $SpacingBefore,
        [alias ("SP")] [nullable[double]] $Spacing,
        [alias ("H")] [nullable[Xceed.Document.NET.Highlight]] $Highlight,
        [alias ("CA")] [nullable[Xceed.Document.NET.CapsStyle]] $CapsStyle,
        [alias ("ST")] [nullable[Xceed.Document.NET.StrikeThrough]] $StrikeThrough,
        [alias ("HT")] [nullable[Xceed.Document.NET.HeadingType]] $HeadingType,
        [nullable[int]] $PercentageScale ,
        [nullable[Xceed.Document.NET.Misc]] $Misc ,
        [string] $Language ,
        [nullable[int]]$Kerning ,
        [nullable[bool]]$Hidden ,
        [nullable[int]]$Position ,
        [nullable[single]] $IndentationFirstLine ,
        [nullable[single]] $IndentationHanging ,
        [nullable[Xceed.Document.NET.Alignment]] $Alignment ,
        [nullable[Xceed.Document.NET.Direction]] $DirectionFormatting,
        [nullable[Xceed.Document.NET.ShadingType]] $ShadingType,
        [nullable[System.Drawing.KnownColor]]$ShadingColor,
        [nullable[Xceed.Document.NET.Script]] $Script,
        [bool] $Supress = $false)
    foreach ($Data in $List.Items) {
        $Data = $Data | Set-WordTextColor -Color $Color -Supress $false
        $Data = $Data | Set-WordTextFontSize -FontSize $FontSize -Supress $false
        $Data = $Data | Set-WordTextFontFamily -FontFamily $FontFamily -Supress $false
        $Data = $Data | Set-WordTextBold -Bold $Bold -Supress $false
        $Data = $Data | Set-WordTextItalic -Italic $Italic -Supress $false
        $Data = $Data | Set-WordTextUnderlineColor -UnderlineColor $UnderlineColor -Supress $false
        $Data = $Data | Set-WordTextUnderlineStyle -UnderlineStyle $UnderlineStyle -Supress $false
        $Data = $Data | Set-WordTextSpacingAfter -SpacingAfter $SpacingAfter -Supress $false
        $Data = $Data | Set-WordTextSpacingBefore -SpacingBefore $SpacingBefore -Supress $false
        $Data = $Data | Set-WordTextSpacing -Spacing $Spacing -Supress $false
        $Data = $Data | Set-WordTextHighlight -Highlight $Highlight -Supress $false
        $Data = $Data | Set-WordTextCapsStyle -CapsStyle $CapsStyle -Supress $false
        $Data = $Data | Set-WordTextStrikeThrough -StrikeThrough $StrikeThrough -Supress $false
        $Data = $Data | Set-WordTextPercentageScale -PercentageScale $PercentageScale -Supress $false
        $Data = $Data | Set-WordTextSpacing -Spacing $Spacing -Supress $false
        $Data = $Data | Set-WordTextLanguage -Language $Language -Supress $false
        $Data = $Data | Set-WordTextKerning -Kerning $Kerning -Supress $false
        $Data = $Data | Set-WordTextMisc -Misc $Misc -Supress $false
        $Data = $Data | Set-WordTextPosition -Position $Position -Supress $false
        $Data = $Data | Set-WordTextHidden -Hidden $Hidden -Supress $false
        $Data = $Data | Set-WordTextShadingType -ShadingColor $ShadingColor -ShadingType $ShadingType -Supress $false
        $Data = $Data | Set-WordTextScript -Script $Script -Supress $false
        $Data = $Data | Set-WordTextHeadingType -HeadingType $HeadingType -Supress $false
        $Data = $Data | Set-WordTextIndentationFirstLine -IndentationFirstLine $IndentationFirstLine -Supress $false
        $Data = $Data | Set-WordTextIndentationHanging -IndentationHanging $IndentationHanging -Supress $false
        $Data = $Data | Set-WordTextAlignment -Alignment $Alignment -Supress $false
        $Data = $Data | Set-WordTextDirection -Direction $Direction -Supress $false
    }
    if ($Supress) { return } else { return $List }
}
function Get-WordDocument {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath,
        [string] $LicenseKey)
    if ($FilePath -ne '') {
        if (Test-Path -LiteralPath $FilePath) {
            try {
                if ($LicenseKey) { $null = [Licenser]::LicenseKey($LicenseKey) }
                $WordDocument = [Xceed.Words.NET.DocX]::Load($FilePath)
                Add-Member -InputObject $WordDocument -MemberType NoteProperty -Name FilePath -Value $FilePath
            } catch {
                $ErrorMessage = $_.Exception.Message
                if ($ErrorMessage -like '*Xceed.Document.NET.Licenser.LicenseKey property must be set to a valid license key in the code of your application before using this product.*') {
                    Write-Warning "Get-WordDocument - PSWriteWord on .NET CORE works only with pay version. Please provide license key."
                    Exit
                } else {
                    Write-Warning "Get-WordDocument - Document: $FilePath Error: $ErrorMessage"
                    Exit
                }
            }
        } else {
            Write-Warning "Get-WordDocument - Document doesn't exists in path $FilePath. Terminating loading word from file."
            return
        }
    }
    return $WordDocument
}
function Merge-WordDocument {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath1,
        [alias('Append')][string] $FilePath2,
        [string] $FileOutput,
        [switch] $OpenDocument,
        [bool] $Supress = $false)
    if ($FilePath1 -ne '' -and $FilePath2 -ne '' -and (Test-Path -LiteralPath $FilePath1) -and (Test-Path -LiteralPath $FilePath2)) {
        try {
            $WordDocument1 = Get-WordDocument -FilePath $FilePath1
            $WordDocument2 = Get-WordDocument -FilePath $FilePath2
            $WordDocument1.InsertDocument($WordDocument2, $true)
            $FilePathOutput = Save-WordDocument -WordDocument $WordDocument1 -FilePath $FileOutput -OpenDocument:$OpenDocument
        } catch {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage -like '*Xceed.Document.NET.Licenser.LicenseKey property must be set to a valid license key in the code of your application before using this product.*') {
                Write-Warning "Merge-WordDocument - PSWriteWord on .NET CORE works only with pay version. Please provide license key."
                Exit
            } else {
                Write-Warning "Merge-WordDocument - Error: $ErrorMessage"
                Exit
            }
        }
        if (-not $Supress) { return $FilePathOutput }
    } else { Write-Warning "Merge-WordDocument - Either $FilePath1 or $FilePath2 doesn't exists. Terminating." }
}
function New-WordDocument {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath = '',
        [string] $LicenseKey)
    try {
        if ($LicenseKey) { $null = [Licenser]::LicenseKey = $LicenseKey }
        $WordDocument = [Xceed.Words.NET.DocX]::Create($FilePath)
        Add-Member -InputObject $WordDocument -MemberType NoteProperty -Name FilePath -Value $FilePath
    } catch {
        $ErrorMessage = $_.Exception.Message
        if ($ErrorMessage -like '*Xceed.Document.NET.Licenser.LicenseKey property must be set to a valid license key in the code of your application before using this product.*') {
            Write-Warning "New-WordDocument - PSWriteWord on .NET CORE works only with pay version. Please provide license key."
            Exit
        } else {
            Write-Warning "New-WordDocument - Document: $FilePath Error: $ErrorMessage"
            Exit
        }
    }
    return $WordDocument
}
function Save-WordDocument {
    [CmdletBinding()]
    param ([alias('Document')][parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $false)][Xceed.Document.NET.Container]$WordDocument,
        [alias('Path')][string] $FilePath,
        [string] $Language,
        [switch] $KillWord,
        [switch] $OpenDocument,
        [bool] $Supress = $false)
    if ($Language) {
        Write-Verbose -Message "Save-WordDocument - Setting Language to $Language"
        $Paragraphs = Get-WordParagraphs -WordDocument $WordDocument
        foreach ($p in $Paragraphs) { Set-WordParagraph -Paragraph $p -Language $Language -Supress $True }
    }
    if (($KillWord) -and ($FilePath)) {
        $FileName = Split-Path $FilePath -leaf
        Write-Verbose -Message "Save-WordDocument - Killing Microsoft Word with text $FileName"
        $Process = Stop-Process -Name "$FileName*" -Confirm:$false -PassThru
        Write-Verbose -Message "Save-WordDocument - Killed Microsoft Word: $FileName"
    }
    if (-not $FilePath) {
        try {
            $FilePath = $WordDocument.FilePath
            Write-Verbose -Message "Save-WordDocument - Saving document (Save: $FilePath)"
            $Data = $WordDocument.Save()
        } catch {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage -like "*The process cannot access the file*because it is being used by another process.*") {
                $FilePath = Get-FileName -Temporary -Extension 'docx'
                Write-Warning -Message "Couldn't save file as it was in use. Trying different name $FilePath"
                $Data = $WordDocument.SaveAs($FilePath)
            }
        }
    } else {
        try {
            Write-Verbose "Save-WordDocument - Saving document (Save AS: $FilePath)"
            $Data = $WordDocument.SaveAs($FilePath)
        } catch {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage -like "*The process cannot access the file*because it is being used by another process.*") {
                $FilePath = Get-FileName -Temporary -Extension 'docx'
                Write-Warning -Message "Couldn't save file as it was in use. Trying different name $FilePath"
                $Data = $WordDocument.SaveAs($FilePath)
            }
        }
    }
    If ($OpenDocument) { if (($FilePath -ne '') -and (Test-Path -LiteralPath $FilePath)) { Invoke-Item -Path $FilePath } else { Write-Warning -Message "Couldn't open file as it doesn't exists - $FilePath" } }
    if ($Supress) { return } else { return $FilePath }
}
function Add-WordCustomProperty {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [string] $Name,
        [string] $Value,
        [bool] $Supress)
    $CustomProperty = New-Object -TypeName CustomProperty -ArgumentList $Name, $Value
    $Data = $WordDocument.AddCustomProperty($CustomProperty)
    if ($Supress) { return } else { return $Data }
}
function Add-WordEquation {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [string] $Equation,
        [bool] $Supress = $false)
    $Output = $WordDocument.InsertEquation($Equation)
    if ($Supress -eq $false) { return $Output } else { return }
}
function Add-WordLine {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Document.NET.HorizontalBorderPosition] $HorizontalBorderPosition = [Xceed.Document.NET.HorizontalBorderPosition]::Bottom,
        [ValidateSet('single', 'double', 'triple')] $LineType = 'single',
        [nullable[int]] $LineSize = 6,
        [nullable[int]] $LineSpace = 1,
        [string] $LineColor = 'black',
        [bool] $Supress)
    if ($Paragraph -eq $null) { $Paragraph = Add-WordParagraph -WordDocument $WordDocument -Supress $False }
    $Paragraph = $Paragraph.InsertHorizontalLine($HorizontalBorderPosition, $LineType, $LineSize, $LineSpace, $LineColor)
    if ($Supress) { return } else { $Paragraph }
}
function Add-WordPageCount {
    [alias('Add-WordPageNumber')]
    param([Xceed.Document.NET.PageNumberFormat] $PageNumberFormat = [Xceed.Document.NET.PageNumberFormat]::normal,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Footers] $Footer,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Headers] $Header,
        [Xceed.Document.NET.Alignment] $Alignment,
        [ValidateSet('All', 'First', 'Even', 'Odd')][string] $Type = 'All',
        [ValidateSet('Both', 'PageCountOnly', 'PageNumberOnly')][string] $Option = 'Both',
        [string] $TextBefore,
        [string] $TextMiddle,
        [string] $TextAfter,
        [bool] $Supress)
    $Paragraphs = [System.Collections.Generic.List[Object]]::new()
    if ($Footer -or $Header -or $Paragraph) {
        if ($null -eq $Paragraph) {
            if ($Type -eq 'All') {
                $Types = 'First', 'Even', 'Odd'
                foreach ($T in $Types) {
                    if ($Footer) { $Paragraphs.Add($Footer.$T.InsertParagraph()) }
                    if ($Header) { $Paragraphs.Add($Header.$T.InsertParagraph()) }
                }
            } else {
                if ($Footer) { $Paragraphs.Add($Footer.$Type.InsertParagraph()) }
                if ($Header) { $Paragraphs.Add($Header.$Type.InsertParagraph()) }
            }
        } else { $Paragraphs.Add($Paragraph) }
        foreach ($CurrentParagraph in $Paragraphs) {
            $CurrentParagraph = Add-WordText -Paragraph $CurrentParagraph -Text $TextBefore -AppendToExistingParagraph -Alignment $Alignment
            if ($Option -eq 'Both' -or $Option -eq 'PageNumberOnly') { $CurrentParagraph.AppendPageNumber($PageNumberFormat) }
            $CurrentParagraph = Add-WordText -Paragraph $CurrentParagraph -Text $TextMiddle -AppendToExistingParagraph
            if ($Option -eq 'Both' -or $Option -eq 'PageCountOnly') { $CurrentParagraph.AppendPageCount($PageNumberFormat) }
            $CurrentParagraph = Add-WordText -Paragraph $CurrentParagraph -Text $TextAfter -AppendToExistingParagraph
        }
        if ($Supress) { return } else { return $Paragraphs }
    } else { Write-Warning -Message 'Add-WordPageCount - Footer or Header or Paragraph is required.' }
}
function Add-WordProtection {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [Xceed.Document.NET.EditRestrictions] $EditRestrictions,
        [string] $Password)
    if ($Password -eq $null) { $WordDocument.AddProtection($EditRestrictions) } else { $WordDocument.AddPasswordProtection($EditRestrictions, $Password) }
}
function Add-WordSection {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [switch] $PageBreak,
        [bool] $Supress)
    if ($PageBreak) { $Data = $WordDocument.InsertSectionPageBreak() } else { $Data = $WordDocument.InsertSection() }
    if ($Supress -eq $true) { return } else { return $Data }
}
function Add-WordTabStopPosition {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [single] $HorizontalPosition,
        [Xceed.Document.NET.TabStopPositionLeader] $TabStopPositionLeader,
        [Xceed.Document.NET.Alignment] $Alignment,
        [bool] $Supress = $false)
    if ($null -eq $Paragraph) { $Paragraph = Add-WordParagraph -WordDocument $WordDocument -Supress $False }
    $data = $Paragraph.InsertTabStopPosition($Alignment, $HorizontalPosition, $TabStopPositionLeader)
    if ($Supress) { return } else { $data }
}
function Get-WordCustomProperty {
    [CmdletBinding()]
    param ([Xceed.Document.NET.Container]$WordDocument,
        [string] $Name)
    if ($Property -eq $null) { $Data = $WordDocument.CustomProperties.Values } else { $Data = $WordDocument.CustomProperties.$Name.Value }
    return $Data
}
function Get-WordPageSettings {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument)
    $Object = [ordered]@{MarginLeft = $WordDocument.MarginLeft
        MarginRight                 = $WordDocument.MarginRight
        MarginTop                   = $WordDocument.MarginTop
        MarginBottom                = $WordDocument.MarginBottom
        PageWidth                   = $WordDocument.PageWidth
        PageHeight                  = $WordDocument.PageHeight
        Orientation                 = $WordDocument.PageLayout.Orientation
    }
    return $Object
}
function Get-WordSection {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument)
    return $WordDocument.Sections
}
function Set-WordMargins {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [nullable[single]] $MarginLeft,
        [nullable[single]] $MarginRight,
        [nullable[single]] $MarginTop,
        [nullable[single]] $MarginBottom)
    if ($MarginLeft -ne $null) { $WordDocument.MarginLeft = $MarginLeft }
    if ($MarginRight -ne $null) { $WordDocument.MarginRight = $MarginRight }
    if ($MarginTop -ne $null) { $WordDocument.MarginTop = $MarginTop }
    if ($MarginBottom -ne $null) { $WordDocument.MarginBottom = $MarginBottom }
}
function Set-WordOrientation {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [alias ("PageLayout")][nullable[Xceed.Document.NET.Orientation]] $Orientation)
    if ($Orientation -ne $null) { $WordDocument.PageLayout.Orientation = $Orientation }
}
function Set-WordPageSettings {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [nullable[single]] $MarginLeft,
        [nullable[single]] $MarginRight,
        [nullable[single]] $MarginTop,
        [nullable[single]] $MarginBottom,
        [nullable[single]] $PageWidth,
        [nullable[single]] $PageHeight,
        [alias ("PageLayout")][nullable[Xceed.Document.NET.Orientation]] $Orientation)
    Set-WordMargins -WordDocument $WordDocument -MarginLeft $MarginLeft -MarginRight $MarginRight -MarginTop $MarginTop -MarginBottom $Mar
    Set-WordPageSize -WordDocument $WordDocument -PageWidth $PageWidth -PageHeight $PageHeight
    Set-WordOrientation -WordDocument $WordDocument -Orientation $Orientation
}
function Set-WordPageSize {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [nullable[single]] $PageWidth,
        [nullable[single]] $PageHeight)
    if ($PageWidth -ne $null) { $WordDocument.PageWidth = $PageWidth }
    if ($PageHeight -ne $null) { $WordDocument.PageHeight = $PageHeight }
}
function Add-WordPageBreak {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Paragraph', 'Table', 'List')][Xceed.Document.NET.InsertBeforeOrAfter] $WordObject,
        [alias('Insert')][validateset('BeforeSelf', 'AfterSelf')][string] $InsertWhere = 'AfterSelf',
        [bool] $Supress = $false)
    $RemovalRequired = $false
    if ($WordObject -eq $null) {
        Write-Verbose "Add-WordPageBreak - Adding temporary paragraph"
        $RemovalRequired = $True
        $WordObject = $WordDocument.InsertParagraph()
    }
    if ($InsertWhere -eq 'AfterSelf') { $WordObject.InsertPageBreakAfterSelf() } else { $WordObject.InsertPageBreakBeforeSelf() }
    if ($RemovalRequired) {
        Write-Verbose "Add-WordPageBreak - Removing paragraph that was added temporary"
        Remove-WordParagraph -Paragraph $WordObject
    }
    if ($Supress -eq $true) { return } else { return $WordObject }
}
Function Add-WordParagraph {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [alias('Paragraph', 'Table', 'List')][Xceed.Document.NET.InsertBeforeOrAfter] $WordObject,
        [alias('Insert')][validateset('BeforeSelf', 'AfterSelf')][string] $InsertWhere = 'AfterSelf',
        [bool] $Supress = $false)
    $NewParagraph = $WordDocument.InsertParagraph()
    if ($WordObject -ne $null) { if ($InsertWhere -eq 'AfterSelf') { $NewParagraph = $WordObject.InsertParagraphAfterSelf($NewParagraph) } elseif ($InsertWhere -eq 'BeforeSelf') { $NewParagraph = $WordObject.InsertParagraphBeforeSelf($NewParagraph) } }
    if ($Supress -eq $true) { return } else { return $NewParagraph }
}
function Add-WordText {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Footer] $Footer,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Header] $Header,
        [alias ("T")] [String[]]$Text,
        [alias ("C")] [System.Drawing.KnownColor[]]$Color = @(),
        [alias ("S")] [double[]] $FontSize = @(),
        [alias ("FontName")] [string[]] $FontFamily = @(),
        [alias ("B")] [nullable[bool][]] $Bold = @(),
        [alias ("I")] [nullable[bool][]] $Italic = @(),
        [alias ("U")] [Xceed.Document.NET.UnderlineStyle[]] $UnderlineStyle = @(),
        [alias ('UC')] [System.Drawing.KnownColor[]]$UnderlineColor = @(),
        [alias ("SA")] [double[]] $SpacingAfter = @(),
        [alias ("SB")] [double[]] $SpacingBefore = @(),
        [alias ("SP")] [double[]] $Spacing = @(),
        [alias ("H")] [Xceed.Document.NET.Highlight[]] $Highlight = @(),
        [alias ("CA")] [Xceed.Document.NET.CapsStyle[]] $CapsStyle = @(),
        [alias ("ST")] [Xceed.Document.NET.StrikeThrough[]] $StrikeThrough = @(),
        [alias ("HT")] [Xceed.Document.NET.HeadingType[]] $HeadingType = @(),
        [int[]] $PercentageScale = @(),
        [Xceed.Document.NET.Misc[]] $Misc = @(),
        [string[]] $Language = @(),
        [int[]]$Kerning = @(),
        [nullable[bool][]]$Hidden = @(),
        [int[]]$Position = @(),
        [nullable[bool][]]$NewLine = @(),
        [single[]] $IndentationFirstLine = @(),
        [single[]] $IndentationHanging = @(),
        [Xceed.Document.NET.Alignment[]] $Alignment = @(),
        [Xceed.Document.NET.Direction[]] $Direction = @(),
        [Xceed.Document.NET.ShadingType[]] $ShadingType = @(),
        [System.Drawing.KnownColor[]]$ShadingColor = @(),
        [Xceed.Document.NET.Script[]] $Script = @(),
        [Switch] $ContinueFormatting,
        [alias ("Append")][Switch] $AppendToExistingParagraph,
        [bool] $Supress = $false)
    if ($null -eq $Alignment) { $Alignment = @() }
    if ($Text.Count -eq 0) { return }
    if ($Footer -or $Header) {
        if ($null -ne $Paragraph) {
            if (-not $AppendToExistingParagraph) {
                if ($Header) { $NewParagraph = $Header.InsertParagraph() } else { $NewParagraph = $Footer.InsertParagraph() }
                $Paragraph = $Paragraph.InsertParagraphAfterSelf($NewParagraph)
            }
        } else { if ($null -ne $WordDocument) { if ($Header) { $Paragraph = $Header.InsertParagraph() } else { $Paragraph = $Footer.InsertParagraph() } } else { throw 'Both Paragraph and WordDocument are null' } }
    } else {
        if ($null -ne $Paragraph) {
            if (-not $AppendToExistingParagraph) {
                $NewParagraph = $WordDocument.InsertParagraph()
                $Paragraph = $Paragraph.InsertParagraphAfterSelf($NewParagraph)
            }
        } else { if ($null -ne $WordDocument) { $Paragraph = $WordDocument.InsertParagraph() } else { throw 'Both Paragraph and WordDocument are null' } }
    }
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($null -ne $NewLine[$i] -and $NewLine[$i] -eq $true) {
            if ($i -gt 0) { if ($null -ne $Paragraph) { $Paragraph = $Paragraph.InsertParagraphAfterSelf($Paragraph) } else { $Paragraph = $WordDocument.InsertParagraph() } }
            $Paragraph = $Paragraph.Append($Text[$i])
        } else { $Paragraph = $Paragraph.Append($Text[$i]) }
        if ($ContinueFormatting -eq $true) {
            Write-Verbose "Add-WordText - ContinueFormatting: $ContinueFormatting Text Count: $($Text.Count)"
            $Formatting = Set-WordContinueFormatting -Count $Text.Count -Color $Color -FontSize $FontSize -FontFamily $FontFamily -Bold $Bold -Italic $Italic -UnderlineStyle $UnderlineStyle -UnderlineColor $UnderlineColor -SpacingAfter $SpacingAfter -SpacingBefore $SpacingBefore -Spacing $Spacing -Highlight $Highlight -CapsStyle $CapsStyle -StrikeThrough $StrikeThrough -HeadingType $HeadingType -PercentageScale $PercentageScale -Misc $Misc -Language $Language -Kerning $Kerning -Hidden $Hidden -Position $Position -IndentationFirstLine $IndentationFirstLine -IndentationHanging $IndentationHanging -Alignment $Alignment -ShadingType $ShadingType -Script $Script
            $Color = $Formatting[0]
            $FontSize = $Formatting[1]
            $FontFamily = $Formatting[2]
            $Bold = $Formatting[3]
            $Italic = $Formatting[4]
            $UnderlineStyle = $Formatting[5]
            $UnderlineColor = $Formatting[6]
            $SpacingAfter = $Formatting[7]
            $SpacingBefore = $Formatting[8]
            $Spacing = $Formatting[9]
            $Highlight = $Formatting[10]
            $CapsStyle = $Formatting[11]
            $StrikeThrough = $Formatting[12]
            $HeadingType = $Formatting[13]
            $PercentageScale = $Formatting[14]
            $Misc = $Formatting[15]
            $Language = $Formatting[16]
            $Kerning = $Formatting[17]
            $Hidden = $Formatting[18]
            $Position = $Formatting[19]
            $IndentationFirstLine = $Formatting[20]
            $IndentationHanging = $Formatting[21]
            $Alignment = $Formatting[22]
            $ShadingType = $Formatting[24]
            $Script = $Formatting[25]
        }
        $Paragraph = $Paragraph | Set-WordTextColor -Color $Color[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextFontSize -FontSize $FontSize[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextFontFamily -FontFamily $FontFamily[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextBold -Bold $Bold[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextItalic -Italic $Italic[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextUnderlineColor -UnderlineColor $UnderlineColor[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextUnderlineStyle -UnderlineStyle $UnderlineStyle[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextSpacingAfter -SpacingAfter $SpacingAfter[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextSpacingBefore -SpacingBefore $SpacingBefore[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextSpacing -Spacing $Spacing[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextHighlight -Highlight $Highlight[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextCapsStyle -CapsStyle $CapsStyle[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextStrikeThrough -StrikeThrough $StrikeThrough[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextPercentageScale -PercentageScale $PercentageScale[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextLanguage -Language $Language[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextKerning -Kerning $Kerning[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextMisc -Misc $Misc[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextPosition -Position $Position[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextHidden -Hidden $Hidden[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextShadingType -ShadingColor $ShadingColor[$i] -ShadingType $ShadingType[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextScript -Script $Script[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextHeadingType -HeadingType $HeadingType[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextIndentationFirstLine -IndentationFirstLine $IndentationFirstLine[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextIndentationHanging -IndentationHanging $IndentationHanging[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextAlignment -Alignment $Alignment[$i] -Supress $false
        $Paragraph = $Paragraph | Set-WordTextDirection -Direction $Direction[$i] -Supress $false
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Get-WordListItemParagraph {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $List,
        [nullable[int]] $Item,
        [switch] $LastItem)
    if ($List -ne $null) {
        $Count = $List.Items.Count
        Write-Verbose "Get-WordListItemParagraph - List Count $Count"
        if ($LastItem) {
            Write-Verbose "Get-WordListItemParagraph - Last Element $($Count-1)"
            $Paragraph = $List.Items[$Count - 1]
        } else {
            if ($null -ne $Item -and $Item -le $Count) {
                Write-Verbose "Get-WordListItemParagraph - Returning paragraph for Item Nr: $Item"
                $Paragraph = $List.Items[$Item]
            }
        }
    }
    return $Paragraph
}
function Get-WordParagraphs {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument)
    $Paragraphs = @()
    foreach ($p in $WordDocument.Paragraphs) { $Paragraphs += $p }
    return $Paragraphs
}
function Get-WordParagraphForList {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [int] $ListID)
    $IDs = @()
    foreach ($p in $WordDocument.Paragraphs) {
        if ($p.ParagraphNumberProperties -ne $null) {
            $ListNumber = $p.ParagraphNumberProperties.LastNode.LastAttribute.Value
            if ($ListNumber -eq $ListID) { $IDs += $p }
        }
    }
    return $Ids
}
function Remove-WordParagraph {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [bool] $TrackChanges)
    $Paragraph.Remove($TrackChanges)
}
function Remove-WordText {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [int] $Index = 0,
        [int] $Count = $($Paragraph.Text.Length),
        [bool] $TrackChanges,
        [bool] $RemoveEmptyParagraph,
        [bool] $Supress = $false)
    if ($Paragraph -ne $null) {
        Write-Verbose "Remove-WordText - Current text $($Paragraph.Text) "
        Write-Verbose "Remove-WordText - Removing from $Index to $Count - Paragraph Text Count: $($Paragraph.Text.Length)"
        if ($Count -ne 0) { $Paragraph.RemoveText($Index, $Count, $TrackChanges, $RemoveEmptyParagraph) }
    }
    if ($Supress) { return } else { return $Paragraph }
}
Function Set-WordParagraph {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Document.NET.Alignment] $Alignment,
        [Xceed.Document.NET.Direction] $Direction,
        [string] $Language,
        [bool] $Supress = $false)
    if ($Paragraph -ne $null) {
        if ($Alignment -ne $null) {
            Write-Verbose "Set-WordParagraph - Setting Alignment to $Alignment"
            $Paragraph.Alignment = $Alignment
        }
        if ($Direction -ne $null) {
            Write-Verbose "Set-WordParagraph - Setting Direction to $Direction"
            $Paragraph.Direction = $Direction
        }
        if ($Language -ne $null) {
            $Culture = [System.Globalization.CultureInfo]::GetCultureInfo($Language)
            $Paragraph = $Paragraph.Culture($Culture)
        }
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordText {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter[]] $Paragraph,
        [AllowNull()][string[]] $Text = @(),
        [alias ("C")] [System.Drawing.KnownColor[]]$Color = @(),
        [alias ("S")] [double[]] $FontSize = @(),
        [alias ("FontName")] [string[]] $FontFamily = @(),
        [alias ("B")] [nullable[bool][]] $Bold = @(),
        [alias ("I")] [nullable[bool][]] $Italic = @(),
        [alias ("U")] [Xceed.Document.NET.UnderlineStyle[]] $UnderlineStyle = @(),
        [alias ('UC')] [System.Drawing.KnownColor[]]$UnderlineColor = @(),
        [alias ("SA")] [double[]] $SpacingAfter = @(),
        [alias ("SB")] [double[]] $SpacingBefore = @(),
        [alias ("SP")] [double[]] $Spacing = @(),
        [alias ("H")] [Xceed.Document.NET.Highlight[]] $Highlight = @(),
        [alias ("CA")] [Xceed.Document.NET.CapsStyle[]] $CapsStyle = @(),
        [alias ("ST")] [Xceed.Document.NET.StrikeThrough[]] $StrikeThrough = @(),
        [alias ("HT")] [Xceed.Document.NET.HeadingType[]] $HeadingType = @(),
        [int[]] $PercentageScale = @(),
        [Xceed.Document.NET.Misc[]] $Misc = @(),
        [string[]] $Language = @(),
        [int[]]$Kerning = @(),
        [nullable[bool][]] $Hidden = @(),
        [int[]]$Position = @(),
        [nullable[bool][]] $NewLine = @(),
        [switch] $KeepLinesTogether,
        [switch] $KeepWithNextParagraph,
        [single[]] $IndentationFirstLine = @(),
        [single[]] $IndentationHanging = @(),
        [nullable[Xceed.Document.NET.Alignment][]] $Alignment = @(),
        [Xceed.Document.NET.Direction[]] $Direction = @(),
        [Xceed.Document.NET.ShadingType[]] $ShadingType = @(),
        [System.Drawing.KnownColor[]]$ShadingColor = @(),
        [Xceed.Document.NET.Script[]] $Script = @(),
        [alias ("AppendText")][Switch] $Append,
        [bool] $Supress = $false)
    if ($null -eq $Alignment) { $Alignment = @() }
    Write-Verbose "Set-WordText - Paragraph Count: $($Paragraph.Count)"
    for ($i = 0; $i -lt $Paragraph.Count; $i++) {
        Write-Verbose "Set-WordText - Loop: $($i)"
        Write-Verbose "Set-WordText - $($Paragraph[$i])"
        Write-Verbose "Set-WordText - $($Paragraph[$i].Text)"
        if ($null -eq $Paragraph[$i]) { Write-Verbose 'Set-WordText - Paragraph is null' } else { Write-Verbose 'Set-WordText - Paragraph is not null' }
        if ($null -eq $Color[$i]) { Write-Verbose 'Set-WordText - Color is null' } else { Write-Verbose 'Set-WordText - Color is not null' }
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextText -Text $Text[$i] -Append:$Append -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextColor -Color $Color[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextFontSize -FontSize $FontSize[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextFontFamily -FontFamily $FontFamily[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextBold -Bold $Bold[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextItalic -Italic $Italic[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextUnderlineColor -UnderlineColor $UnderlineColor[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextUnderlineStyle -UnderlineStyle $UnderlineStyle[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextSpacingAfter -SpacingAfter $SpacingAfter[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextSpacingBefore -SpacingBefore $SpacingBefore[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextSpacing -Spacing $Spacing[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextHighlight -Highlight $Highlight[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextCapsStyle -CapsStyle $CapsStyle[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextStrikeThrough -StrikeThrough $StrikeThrough[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextPercentageScale -PercentageScale $PercentageScale[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextSpacing -Spacing $Spacing[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextLanguage -Language $Language[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextKerning -Kerning $Kerning[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextMisc -Misc $Misc[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextPosition -Position $Position[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextHidden -Hidden $Hidden[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextShadingType -ShadingColor $ShadingColor[$i] -ShadingType $ShadingType[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextScript -Script $Script[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextHeadingType -HeadingType $HeadingType[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextIndentationFirstLine -IndentationFirstLine $IndentationFirstLine[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextIndentationHanging -IndentationHanging $IndentationHanging[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextAlignment -Alignment $Alignment[$i] -Supress $false
        $Paragraph[$i] = $Paragraph[$i] | Set-WordTextDirection -Direction $Direction[$i] -Supress $false
    }
}
function Set-WordTextAlignment {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.Alignment]] $Alignment,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $Alignment) { $Paragraph.Alignment = $Alignment }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextBold {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[bool]] $Bold,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Bold -ne $null -and $Bold -eq $true) { $Paragraph = $Paragraph.Bold() }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextCapsStyle {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.CapsStyle]] $CapsStyle,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $CapsStyle) { $Paragraph = $Paragraph.CapsStyle($CapsStyle) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextColor {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [alias ("C")] [nullable[System.Drawing.KnownColor]] $Color,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Color -ne $null) {
        $ConvertedColor = [System.Drawing.Color]::FromKnownColor($Color)
        $Paragraph = $Paragraph.Color($ConvertedColor)
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextDirection {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.Direction]] $Direction,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $Direction) { $Paragraph.Direction = $Direction }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextFontFamily {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $FontFamily,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $FontFamily -ne $null -and $FontFamily -ne '') { $Paragraph = $Paragraph.Font($FontFamily) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextFontSize {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [alias ("S")] [nullable[double]] $FontSize,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $FontSize -ne $null) { $Paragraph = $Paragraph.FontSize($FontSize) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextHeadingType {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.HeadingType]] $HeadingType,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $HeadingType) {
        Write-Verbose "Set-WordTextHeadingType - Setting StyleName to $StyleName"
        $Paragraph.StyleName = $HeadingType
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextHidden {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[bool]] $Hidden,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Hidden -ne $null) { $Paragraph = $Paragraph.Hidden($Hidden) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextHighlight {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.Highlight]] $Highlight,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $Highlight) { $Paragraph = $Paragraph.Highlight($Highlight) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextIndentationFirstLine {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[single]] $IndentationFirstLine,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $IndentationFirstLine -ne $null) { $Paragraph.IndentationFirstLine = $IndentationFirstLine }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextIndentationHanging {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[single]] $IndentationHanging,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $IndentationHanging -ne $null) { $Paragraph.IndentationHanging = $IndentationHanging }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextItalic {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[bool]] $Italic,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Italic -ne $null -and $Italic -eq $true) { $Paragraph = $Paragraph.Italic() }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextKerning {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[int]] $Kerning,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Kerning -ne $null) { $Paragraph = $Paragraph.Kerning($Kerning) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextLanguage {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string]$Language,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Language -ne $null -and $Language -ne '') {
        $Culture = [System.Globalization.CultureInfo]::GetCultureInfo($Language)
        $Paragraph = $Paragraph.Culture($Culture)
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextMisc {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.Misc]] $Misc,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $Misc) { $Paragraph = $Paragraph.Misc($Misc) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextPercentageScale {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[int]]$PercentageScale,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $PercentageScale -ne $null) { $Paragraph = $Paragraph.PercentageScale($PercentageScale) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextPosition {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[int]]$Position,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Position -ne $null) { $Paragraph = $Paragraph.Position($Position) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextScript {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.Script]] $Script,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $Script) { $Paragraph = $Paragraph.Script($Script) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextShadingType {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.ShadingType]] $ShadingType,
        [nullable[System.Drawing.KnownColor]] $ShadingColor,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $ShadingType -and $ShadingColor -ne $null) {
        $ConvertedColor = [System.Drawing.Color]::FromKnownColor($ShadingColor)
        $Paragraph = $Paragraph.Shading($ConvertedColor, $ShadingType)
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextSpacing {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[double]] $Spacing,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $Spacing -ne $null) { $Paragraph = $Paragraph.Spacing($Spacing) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextSpacingAfter {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[double]] $SpacingAfter,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $SpacingAfter -ne $null) { $Paragraph = $Paragraph.SpacingAfter($SpacingAfter) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextSpacingBefore {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[double]] $SpacingBefore,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $SpacingBefore -ne $null) { $Paragraph = $Paragraph.SpacingBefore($SpacingBefore) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextStrikeThrough {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.StrikeThrough]] $StrikeThrough,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $StrikeThrough) { $Paragraph = $Paragraph.StrikeThrough($StrikeThrough) }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextUnderlineColor {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[System.Drawing.KnownColor]] $UnderlineColor,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $UnderlineColor -ne $null) {
        $ConvertedColor = [System.Drawing.Color]::FromKnownColor($UnderlineColor)
        $Paragraph = $Paragraph.UnderlineColor($ConvertedColor)
    }
    if ($Supress) { return } else { return $Paragraph }
}
function Set-WordTextUnderlineStyle {
    [CmdletBinding()]
    param([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [nullable[Xceed.Document.NET.UnderlineStyle]] $UnderlineStyle,
        [bool] $Supress = $false)
    if ($null -ne $Paragraph -and $null -ne $UnderlineStyle) { $Paragraph = $Paragraph.UnderlineStyle($UnderlineStyle) }
    if ($Supress) { return } else { return $Paragraph }
}
function Add-WordPicture {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Document.NET.Picture] $Picture,
        [alias('FileImagePath')][string] $ImagePath,
        [Xceed.Document.NET.Alignment] $Alignment,
        [int] $Rotation,
        [switch] $FlipHorizontal,
        [switch] $FlipVertical,
        [int] $ImageWidth,
        [int] $ImageHeight,
        [string] $Description,
        [bool] $Supress = $false)
    if ([string]::IsNullOrEmpty($Paragraph)) { $Paragraph = Add-WordParagraph -WordDocument $WordDocument -Supress $false }
    if ($null -eq $Picture) {
        if ($ImagePath -ne '' -and (Test-Path($ImagePath))) {
            try {
                $Image = $WordDocument.AddImage($ImagePath)
                $Picture = $Image.CreatePicture()
            } catch {
                Write-Warning "Add-WordPicture - Failed adding image. Please check with different file format/type. Aborting."
                return
            }
        } else {
            Write-Warning "Add-WordPicture - Path to ImagePath ($ImagePath) was incorrect. Aborting."
            return
        }
    }
    if ($Rotation -ne 0) { $Picture.Rotation = $Rotation }
    if ($FlipHorizontal -ne $false) { $Picture.FlipHorizontal = $FlipHorizontal }
    if ($FlipVertical -ne $false) { $Picture.FlipVertical = $FlipVertical }
    if (-not [string]::IsNullOrEmpty($Description)) { $Picture.Description = $Description }
    if ($ImageWidth -ne 0) { $Picture.Width = $ImageWidth }
    if ($ImageHeight -ne 0) { $Picture.Height = $ImageHeight }
    $Data = $Paragraph.AppendPicture($Picture)
    if ($Alignment) { $Data = Set-WordTextAlignment -Paragraph $Data -Alignment $Alignment }
    if ($Supress) { return } else { return $Data }
}
function Get-WordPicture {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [switch] $ListParagraphs,
        [switch] $ListPictures,
        [nullable[int]] $PictureID)
    if ($ListParagraphs -eq $true -and $ListPictures -eq $true) { throw 'Only one option is possible at time (-ListParagraphs or -ListPictures)' }
    if ($ListParagraphs) {
        $Paragraphs = $WordDocument.Paragraphs
        $List = foreach ($p in $Paragraphs) { if ($p.Pictures -ne $null) { $p } }
        return $List
    }
    if ($ListPictures) { return $WordDocument.Pictures }
    if ($PictureID -ne $null) { return $WordDocument.Pictures[$PictureID] }
}
function Remove-WordPicture {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [int] $PictureID,
        [bool] $Supress)
    if ($null -ne $Paragraph.Pictures[$PictureID]) { $Paragraph.Pictures[$PictureID].Remove() }
    if ($supress) { return } else { return $Paragraph }
}
function Set-WordPicture {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Document.NET.Picture] $Picture,
        [string] $ImagePath,
        [int] $Rotation,
        [switch] $FlipHorizontal,
        [switch] $FlipVertical,
        [int] $ImageWidth,
        [int] $ImageHeight,
        [string] $Description,
        [int] $PictureID,
        [bool] $Supress = $false)
    $Paragraph = Remove-WordPicture -WordDocument $WordDocument -Paragraph $Paragraph -PictureID $PictureID -Supress $false
    $data = Add-WordPicture -WordDocument $WordDocument -Paragraph $Paragraph -Picture $Picture -ImagePath $ImagePath -ImageWidth $ImageWidth -ImageHeight $ImageHeight -Rotation $Rotation -FlipHorizontal:$FlipHorizontal -FlipVertical:$FlipVertical -Supress $Supress
    if ($Supress) { return } else { return $data }
}
function Add-WordTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Array] $DataTable,
        [Xceed.Document.NET.AutoFit] $AutoFit,
        [Xceed.Document.NET.TableDesign] $Design,
        [Xceed.Document.NET.Direction] $Direction,
        [switch] $BreakPageAfterTable,
        [switch] $BreakPageBeforeTable,
        [nullable[bool]] $BreakAcrossPages,
        [nullable[int]] $MaximumColumns,
        [string] $OverwriteTitle,
        [switch] $DoNotAddTitle,
        [Xceed.Document.NET.Alignment] $TitleAlignment = [Xceed.Document.NET.Alignment]::center,
        [alias ("ColummnWidth")][float[]] $ColumnWidth = @(),
        [nullable[float]] $TableWidth = $null,
        [bool] $Percentage,
        [alias ("C")] [System.Drawing.KnownColor[]]$Color = @(),
        [alias ("S")] [double[]] $FontSize = @(),
        [alias ("FontName")] [string[]] $FontFamily = @(),
        [alias ("B")] [nullable[bool][]] $Bold = @(),
        [alias ("I")] [nullable[bool][]] $Italic = @(),
        [alias ("U")] [Xceed.Document.NET.UnderlineStyle[]] $UnderlineStyle = @(),
        [alias ('UC')] [System.Drawing.KnownColor[]]$UnderlineColor = @(),
        [alias ("SA")] [double[]] $SpacingAfter = @(),
        [alias ("SB")] [double[]] $SpacingBefore = @(),
        [alias ("SP")] [double[]] $Spacing = @(),
        [alias ("H")] [Xceed.Document.NET.Highlight[]] $Highlight = @(),
        [alias ("CA")] [Xceed.Document.NET.CapsStyle[]] $CapsStyle = @(),
        [alias ("ST")] [Xceed.Document.NET.StrikeThrough[]] $StrikeThrough = @(),
        [alias ("HT")] [Xceed.Document.NET.HeadingType[]] $HeadingType = @(),
        [int[]] $PercentageScale = @(),
        [Xceed.Document.NET.Misc[]] $Misc = @(),
        [string[]] $Language = @(),
        [int[]]$Kerning = @(),
        [nullable[bool][]]$Hidden = @(),
        [int[]]$Position = @(),
        [single[]] $IndentationFirstLine = @(),
        [single[]] $IndentationHanging = @(),
        [Xceed.Document.NET.Alignment[]] $Alignment = @(),
        [Xceed.Document.NET.Direction[]] $DirectionFormatting = @(),
        [Xceed.Document.NET.ShadingType[]] $ShadingType = @(),
        [Xceed.Document.NET.Script[]] $Script = @(),
        [nullable[bool][]] $NewLine = @(),
        [switch] $KeepLinesTogether,
        [switch] $KeepWithNextParagraph,
        [switch] $ContinueFormatting,
        [alias('Rotate', 'RotateData', 'TransposeColumnsRows', 'TransposeData')][switch] $Transpose,
        [string[]] $ExcludeProperty,
        [bool] $Supress = $false,
        [string] $Splitter = ';')
    Begin {
        [int] $Run = 0
        [int] $RowNr = 0
        if ($MaximumColumns -eq $null) { $MaximumColumns = 5 }
    }
    Process {
        if ($DataTable.Count -gt 0) {
            if ($Run -eq 0) {
                if ($Transpose) { $DataTable = Format-TransposeTable -Object $DataTable }
                $Data = Format-PSTable -Object $DataTable -ExcludeProperty $ExcludeProperty -SkipTitle:$DoNotAddTitle -Splitter $Splitter
                $WorksheetHeaders = $Data[0]
                $NumberRows = $Data.Count
                $NumberColumns = if ($Data[0].Count -ge $MaximumColumns) { $MaximumColumns } else { $Data[0].Count }
                if ($DoNotAddTitle) { if ($null -eq $Table) { $Table = New-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -NrRows ($NumberRows + 1) -NrColumns $NumberColumns -Supress $false } else { Add-WordTableRow -Table $Table -Count ($NumberRows + 1) -Supress $True } } else { if ($null -eq $Table) { $Table = New-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -NrRows $NumberRows -NrColumns $NumberColumns -Supress $false } else { Add-WordTableRow -Table $Table -Count $NumberRows -Supress $True } }
            } else {
                $Data = Format-PSTable -Object $DataTable -SkipTitle -OverwriteHeaders $WorksheetHeaders -Splitter $Splitter
                $NumberRows = $Data.Count
                $NumberColumns = if ($Data[0].Count -ge $MaximumColumns) { $MaximumColumns } else { $Data[0].Count }
                if ($null -eq $Table) { $Table = New-WordTable -WordDocument $WordDocument -Paragraph $Paragraph -NrRows $NumberRows -NrColumns $NumberColumns -Supress $false } else { Add-WordTableRow -Table $Table -Count $NumberRows -Supress $True }
            }
            if ($ContinueFormatting -eq $true) {
                $Formatting = Set-WordContinueFormatting -Count $NumberRows -Color $Color -FontSize $FontSize -FontFamily $FontFamily -Bold $Bold -Italic $Italic -UnderlineStyle $UnderlineStyle -UnderlineColor $UnderlineColor -SpacingAfter $SpacingAfter -SpacingBefore $SpacingBefore -Spacing $Spacing -Highlight $Highlight -CapsStyle $CapsStyle -StrikeThrough $StrikeThrough -HeadingType $HeadingType -PercentageScale $PercentageScale -Misc $Misc -Language $Language -Kerning $Kerning -Hidden $Hidden -Position $Position -IndentationFirstLine $IndentationFirstLine -IndentationHanging $IndentationHanging -Alignment $Alignment -DirectionFormatting $DirectionFormatting -ShadingType $ShadingType -Script $Script
                $Color = $Formatting[0]
                $FontSize = $Formatting[1]
                $FontFamily = $Formatting[2]
                $Bold = $Formatting[3]
                $Italic = $Formatting[4]
                $UnderlineStyle = $Formatting[5]
                $UnderlineColor = $Formatting[6]
                $SpacingAfter = $Formatting[7]
                $SpacingBefore = $Formatting[8]
                $Spacing = $Formatting[9]
                $Highlight = $Formatting[10]
                $CapsStyle = $Formatting[11]
                $StrikeThrough = $Formatting[12]
                $HeadingType = $Formatting[13]
                $PercentageScale = $Formatting[14]
                $Misc = $Formatting[15]
                $Language = $Formatting[16]
                $Kerning = $Formatting[17]
                $Hidden = $Formatting[18]
                $Position = $Formatting[19]
                $IndentationFirstLine = $Formatting[20]
                $IndentationHanging = $Formatting[21]
                $Alignment = $Formatting[22]
                $DirectionFormatting = $Formatting[23]
                $ShadingType = $Formatting[24]
                $Script = $Formatting[25]
            }
            if ($Run -eq 0 -and $DoNotAddTitle) { $RowNr = 1 }
            foreach ($Row in $Data) {
                $ColumnNr = 0
                foreach ($Column in $Row) {
                    Add-WordTableCellValue -Table $Table -Row $RowNr -Column $ColumnNr -Value $Column -Color $Color[$RowNr] -FontSize $FontSize[$RowNr] -FontFamily $FontFamily[$RowNr] -Bold $Bold[$RowNr] -Italic $Italic[$RowNr] -UnderlineStyle $UnderlineStyle[$RowNr]-UnderlineColor $UnderlineColor[$RowNr]-SpacingAfter $SpacingAfter[$RowNr] -SpacingBefore $SpacingBefore[$RowNr] -Spacing $Spacing[$RowNr] -Highlight $Highlight[$RowNr] -CapsStyle $CapsStyle[$RowNr] -StrikeThrough $StrikeThrough[$RowNr] -HeadingType $HeadingType[$RowNr] -PercentageScale $PercentageScale[$RowNr] -Misc $Misc[$RowNr] -Language $Language[$RowNr]-Kerning $Kerning[$RowNr]-Hidden $Hidden[$RowNr]-Position $Position[$RowNr]-IndentationFirstLine $IndentationFirstLine[$RowNr]-IndentationHanging $IndentationHanging[$RowNr]-Alignment $Alignment[$RowNr]-DirectionFormatting $DirectionFormatting[$RowNr] -ShadingType $ShadingType[$RowNr]-Script $Script[$RowNr] -Supress $True
                    if ($ColumnNr -eq $($MaximumColumns - 1)) { break }
                    $ColumnNr++
                }
                $RowNr++
            }
            $Run++
        }
    }
    End {
        if ($DataTable.Count -gt 0) {
            $Table | Set-WordTableColumnWidth -Width $ColumnWidth -TotalWidth $TableWidth -Percentage $Percentage -Supress $True
            $Table | Set-WordTable -Direction $Direction -AutoFit $AutoFit -Design $Design -BreakPageAfterTable:$BreakPageAfterTable -BreakPageBeforeTable:$BreakPageBeforeTable -BreakAcrossPages $BreakAcrossPages -Supress $True
            if ($OverwriteTitle) {
                $Table = Set-WordTableRowMergeCells -Table $Table -RowNr 0 -MergeAll
                $TableParagraph = Get-WordTableRow -Table $Table -RowNr 0 -ColumnNr 0
                $TableParagraph = Set-WordText -Paragraph $TableParagraph -Text $OverwriteTitle -Alignment $TitleAlignment
            }
            if ($Supress) { return } else { return $Table }
        }
    }
}
function Add-WordTableCellValue {
    [CmdletBinding()]
    param([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $Row,
        [int] $Column,
        [Object] $Value,
        [int] $ParagraphNumber = 0,
        [alias ("C")] [nullable[System.Drawing.KnownColor]]$Color,
        [alias ("S")] [nullable[double]] $FontSize,
        [alias ("FontName")] [string] $FontFamily,
        [alias ("B")] [nullable[bool]] $Bold,
        [alias ("I")] [nullable[bool]] $Italic,
        [alias ("U")] [nullable[Xceed.Document.NET.UnderlineStyle]] $UnderlineStyle,
        [alias ('UC')] [nullable[System.Drawing.KnownColor]]$UnderlineColor,
        [alias ("SA")] [nullable[double]] $SpacingAfter,
        [alias ("SB")] [nullable[double]] $SpacingBefore,
        [alias ("SP")] [nullable[double]] $Spacing,
        [alias ("H")] [nullable[Xceed.Document.NET.Highlight]] $Highlight,
        [alias ("CA")] [nullable[Xceed.Document.NET.CapsStyle]] $CapsStyle,
        [alias ("ST")] [nullable[Xceed.Document.NET.StrikeThrough]] $StrikeThrough,
        [alias ("HT")] [nullable[Xceed.Document.NET.HeadingType]] $HeadingType,
        [nullable[int]] $PercentageScale ,
        [nullable[Xceed.Document.NET.Misc]] $Misc ,
        [string] $Language ,
        [nullable[int]]$Kerning ,
        [nullable[bool]]$Hidden ,
        [nullable[int]]$Position ,
        [nullable[single]] $IndentationFirstLine ,
        [nullable[single]] $IndentationHanging ,
        [nullable[Xceed.Document.NET.Alignment]] $Alignment ,
        [nullable[Xceed.Document.NET.Direction]] $DirectionFormatting,
        [nullable[Xceed.Document.NET.ShadingType]] $ShadingType,
        [nullable[System.Drawing.KnownColor]]$ShadingColor,
        [nullable[Xceed.Document.NET.Script]] $Script,
        [bool] $Supress = $false)
    Write-Verbose "Add-WordTableCellValue - Row: $Row Column $Column Value $Value Supress: $Supress"
    try { $Data = $Table.Rows[$Row].Cells[$Column].Paragraphs[$ParagraphNumber].Append("$Value") } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning "Add-WordTableCellValue - Failed adding value $Value with error: $ErrorMessage"
        return
    }
    $Data = $Data | Set-WordTextColor -Color $Color -Supress $false
    $Data = $Data | Set-WordTextFontSize -FontSize $FontSize -Supress $false
    $Data = $Data | Set-WordTextFontFamily -FontFamily $FontFamily -Supress $false
    $Data = $Data | Set-WordTextBold -Bold $Bold -Supress $false
    $Data = $Data | Set-WordTextItalic -Italic $Italic -Supress $false
    $Data = $Data | Set-WordTextUnderlineColor -UnderlineColor $UnderlineColor -Supress $false
    $Data = $Data | Set-WordTextUnderlineStyle -UnderlineStyle $UnderlineStyle -Supress $false
    $Data = $Data | Set-WordTextSpacingAfter -SpacingAfter $SpacingAfter -Supress $false
    $Data = $Data | Set-WordTextSpacingBefore -SpacingBefore $SpacingBefore -Supress $false
    $Data = $Data | Set-WordTextSpacing -Spacing $Spacing -Supress $false
    $Data = $Data | Set-WordTextHighlight -Highlight $Highlight -Supress $false
    $Data = $Data | Set-WordTextCapsStyle -CapsStyle $CapsStyle -Supress $false
    $Data = $Data | Set-WordTextStrikeThrough -StrikeThrough $StrikeThrough -Supress $false
    $Data = $Data | Set-WordTextPercentageScale -PercentageScale $PercentageScale -Supress $false
    $Data = $Data | Set-WordTextSpacing -Spacing $Spacing -Supress $false
    $Data = $Data | Set-WordTextLanguage -Language $Language -Supress $false
    $Data = $Data | Set-WordTextKerning -Kerning $Kerning -Supress $false
    $Data = $Data | Set-WordTextMisc -Misc $Misc -Supress $false
    $Data = $Data | Set-WordTextPosition -Position $Position -Supress $false
    $Data = $Data | Set-WordTextHidden -Hidden $Hidden -Supress $false
    $Data = $Data | Set-WordTextShadingType -ShadingColor $ShadingColor -ShadingType $ShadingType -Supress $false
    $Data = $Data | Set-WordTextScript -Script $Script -Supress $false
    $Data = $Data | Set-WordTextHeadingType -HeadingType $HeadingType -Supress $false
    $Data = $Data | Set-WordTextIndentationFirstLine -IndentationFirstLine $IndentationFirstLine -Supress $false
    $Data = $Data | Set-WordTextIndentationHanging -IndentationHanging $IndentationHanging -Supress $false
    $Data = $Data | Set-WordTextAlignment -Alignment $Alignment -Supress $false
    $Data = $Data | Set-WordTextDirection -Direction $Direction -Supress $false
    if ($Supress -eq $true) { return } else { return $Data }
}
function Add-WordTableColumn {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $Count = 1,
        [int] $Index,
        [ValidateSet('Left', 'Right')] $Direction = 'Left')
    if ($Direction -eq 'Left') { $ColumnSide = $false } else { $ColumnSide = $true }
    if ($null -ne $Table) { for ($i = 0; $i -lt $Count; $i++) { $Table.InsertColumn($Index + $i, $ColumnSide) } }
}
function Add-WordTableRow {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $Count = 1,
        [nullable[int]] $Index,
        [bool] $Supress = $false)
    if ($null -ne $Table) { $List = @(if ($Index -ne $null) { for ($i = 0; $i -lt $Count; $i++) { $Table.InsertRow($Index + $i) } } else { for ($i = 0; $i -lt $Count; $i++) { $Table.InsertRow() } }) }
    if ($Supress) { return } else { return $List }
}
function Add-WordTableTitle {
    [CmdletBinding()]
    param([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [string[]]$Titles,
        [int] $MaximumColumns,
        [alias ("C")] [nullable[System.Drawing.KnownColor]]$Color,
        [alias ("S")] [nullable[double]] $FontSize,
        [alias ("FontName")] [string] $FontFamily,
        [alias ("B")] [nullable[bool]] $Bold,
        [alias ("I")] [nullable[bool]] $Italic,
        [alias ("U")] [nullable[Xceed.Document.NET.UnderlineStyle]] $UnderlineStyle,
        [alias ('UC')] [nullable[System.Drawing.KnownColor]]$UnderlineColor,
        [alias ("SA")] [nullable[double]] $SpacingAfter,
        [alias ("SB")] [nullable[double]] $SpacingBefore ,
        [alias ("SP")] [nullable[double]] $Spacing ,
        [alias ("H")] [nullable[Xceed.Document.NET.Highlight]] $Highlight ,
        [alias ("CA")] [nullable[Xceed.Document.NET.CapsStyle]] $CapsStyle ,
        [alias ("ST")] [nullable[Xceed.Document.NET.StrikeThrough]] $StrikeThrough ,
        [alias ("HT")] [nullable[Xceed.Document.NET.HeadingType]] $HeadingType ,
        [nullable[int]] $PercentageScale ,
        [nullable[Xceed.Document.NET.Misc]] $Misc ,
        [string] $Language ,
        [nullable[int]]$Kerning ,
        [nullable[bool]]$Hidden ,
        [nullable[int]]$Position ,
        [nullable[single]] $IndentationFirstLine ,
        [nullable[single]] $IndentationHanging ,
        [nullable[Xceed.Document.NET.Alignment]] $Alignment ,
        [nullable[Xceed.Document.NET.Direction]] $DirectionFormatting ,
        [nullable[Xceed.Document.NET.ShadingType]] $ShadingType ,
        [nullable[Xceed.Document.NET.Script]] $Script ,
        [bool] $Supress = $false)
    Write-Verbose "Add-WordTableTitle - Title Count $($Titles.Count) Supress $Supress"
    for ($a = 0; $a -lt $Titles.Count; $a++) {
        if ($Titles[$a] -is [string]) { $ColumnName = $Titles[$a] } else { $ColumnName = $Titles[$a].Name }
        Write-Verbose "Add-WordTableTitle - Column Name: $ColumnName Supress $Supress"
        Write-Verbose "Add-WordTableTitle - Bold $Bold"
        Add-WordTableCellValue -Table $Table -Row 0 -Column $a -Value $ColumnName -Color $Color -FontSize $FontSize -FontFamily $FontFamily -Bold $Bold -Italic $Italic -UnderlineStyle $UnderlineStyle -UnderlineColor $UnderlineColor -SpacingAfter $SpacingAfter -SpacingBefore $SpacingBefore -Spacing $Spacing -Highlight $Highlight -CapsStyle $CapsStyle -StrikeThrough $StrikeThrough -HeadingType $HeadingType -PercentageScale $PercentageScale -Misc $Misc -Language $Language -Kerning $Kerning -Hidden $Hidden -Position $Position -IndentationFirstLine $IndentationFirstLine -IndentationHanging $IndentationHanging -Alignment $Alignment -DirectionFormatting $DirectionFormatting -ShadingType $ShadingType -Script $Script -Supress $Supress
        if ($a -eq $($MaximumColumns - 1)) { break }
    }
    if ($Supress) { return } else { return $Table }
}
function Copy-WordTableRow {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        $Row,
        [nullable[int]] $Index)
    if ($Table -ne $null) { if ($Index -eq $null) { $Table.InsertRow($Row) } else { $Table.InsertRow($Row, $Index) } }
}
function Get-WordTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [switch] $ListTables,
        [switch] $LastTable,
        [nullable[int]] $TableID)
    if ($LastTable) {
        $Tables = $WordDocument.Tables
        $Table = $Tables[$Tables.Count - 1]
        return $Table
    }
    if ($ListTables) { return $WordDocument.Tables }
    if ($TableID -ne $null) { return $WordDocument.Tables[$TableID] }
}
function Get-WordTableRow {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $RowNr,
        [int] $ColumnNr,
        [int] $ParagraphNr,
        [switch] $RowsCount)
    if ($Table -ne $null) {
        if ($RowsCount) { return $Table.Rows.Count }
        return $Table.Rows[$RowNr].Cells[$ColumnNr].Paragraphs[$ParagraphNr]
    }
}
function New-WordTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [int] $NrRows,
        [int] $NrColumns,
        [bool] $Supress = $false)
    Write-Verbose "New-WordTable - NrRows $NrRows NrColumns $NrColumns Supress $supress Paragraph $Paragraph"
    if ($null -eq $Paragraph) { $WordTable = $WordDocument.InsertTable($NrRows, $NrColumns) } else {
        $TableDefinition = $WordDocument.AddTable($NrRows, $NrColumns)
        $WordTable = $Paragraph.InsertTableAfterSelf($TableDefinition)
    }
    if ($Supress) { return } else { return $WordTable }
}
function New-WordTableBorder {
    [CmdletBinding()]
    param ([Xceed.Document.NET.BorderStyle] $BorderStyle,
        [Xceed.Document.NET.BorderSize] $BorderSize,
        [int] $BorderSpace,
        [System.Drawing.KnownColor] $BorderColor)
    $ConvertedColor = [System.Drawing.Color]::FromKnownColor($BorderColor)
    $Border = [Xceed.Document.NET.Border]::new($BorderStyle, $BorderSize, $BorderSpace, $ConvertedColor)
    return $Border
}
function Remove-WordTable {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table)
    if ($Table -ne $null) { $Table.Remove() }
}
function Remove-WordTableColumn {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $Count = 1,
        [nullable[int]] $Index)
    if ($Table) { if ($Index) { for ($i = 0; $i -lt $Count; $i++) { $Table.RemoveColumn($Index + $i) } } else { for ($i = 0; $i -lt $Count; $i++) { $Table.RemoveColumn() } } }
}
function Remove-WordTableRow {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [int] $Count = 1,
        [nullable[int]] $Index,
        [bool] $Supress)
    if ($Table) { if ($Index) { for ($i = 0; $i -lt $Count; $i++) { $Table.RemoveRow($Index + $i) } } else { for ($i = 0; $i -lt $Count; $i++) { $Table.RemoveRow() } } }
    if ($Supress) { return } else { return $Table }
}
function Set-WordTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[Xceed.Document.NET.TableBorderType]] $TableBorderType,
        $Border,
        [nullable[Xceed.Document.NET.AutoFit]] $AutoFit,
        [nullable[Xceed.Document.NET.TableDesign]] $Design,
        [nullable[Xceed.Document.NET.Direction]] $Direction,
        [switch] $BreakPageAfterTable,
        [switch] $BreakPageBeforeTable,
        [nullable[bool]] $BreakAcrossPages,
        [bool] $Supress)
    if ($Table) {
        $Table = $table | Set-WordTableDesign -Design $Design
        $Table = $table | Set-WordTableDirection -Direction $Direction
        $Table = $table | Set-WordTableBorder -TableBorderType $TableBorderType -Border $Border
        $Table = $table | Set-WordTablePageBreak -AfterTable:$BreakPageAfterTable -BeforeTable:$BreakPageBeforeTable -BreakAcrossPages $BreakAcrossPages
        $Table = $table | Set-WordTableAutoFit -AutoFit $AutoFit
    }
    if ($Supress) { return } Else { return $Table }
}
function Set-WordTableAutoFit {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[Xceed.Document.NET.AutoFit]] $AutoFit)
    if (($null -ne $Table) -and ($null -ne $AutoFit)) {
        Write-Verbose "Set-WordTabelAutofit - Setting Table Autofit to: $AutoFit"
        $Table.AutoFit = $AutoFit
    }
    return $Table
}
function Set-WordTableBorder {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[Xceed.Document.NET.TableBorderType]] $TableBorderType,
        $Border,
        [bool] $Supress)
    if ($null -ne $Table -and $null -ne $TableBorderType -and $null -ne $Border) { $Table.SetBorder($TableBorderType, $Border) }
    if ($Supress) { return } else { $Table }
}
function Set-WordTableCell {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[int]] $RowNr,
        [nullable[int]] $ColumnNr,
        [System.Drawing.KnownColor] $FillColor,
        [System.Drawing.KnownColor] $ShadingColor,
        [bool] $Supress = $false)
    $Table = Set-WordTableCellFillColor -Table $Table -RowNr $RowNr -ColumnNr $ColumnNr -FillColor $FillColor -Supress $false
    $Table = Set-WordTableCellShadingColor -Table $Table -RowNr $RowNr -ColumnNr $ColumnNr -ShadingColor $ShadingColor -Supress $false
    if ($Supress) { return } else { return $Table }
}
function Set-WordTableCellFillColor {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[int]] $RowNr,
        [nullable[int]] $ColumnNr,
        [nullable[System.Drawing.KnownColor]] $FillColor,
        [bool] $Supress = $false)
    if ($Table -and $RowNr -and $ColumnNr -and $FillColor) {
        $Cell = $Table.Rows[$RowNr].Cells[$ColumnNr]
        $ConvertedColor = [System.Drawing.Color]::FromKnownColor($FillColor)
        $Cell.FillColor = $ConvertedColor
    }
    if ($Supress) { return } else { return $Table }
}
function Set-WordTableCellShadingColor {
    [CmdletBinding()]
    param ([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[int]] $RowNr,
        [nullable[int]] $ColumnNr,
        [nullable[System.Drawing.KnownColor]] $ShadingColor,
        [bool] $Supress = $false)
    if ($Table -ne $null -and $RowNr -ne $null -and $ColumnNr -ne $null -and $ShadingColor -ne $null) {
        $ConvertedColor = [System.Drawing.Color]::FromKnownColor($ShadingColor)
        $Cell = $Table.Rows[$RowNr].Cells[$ColumnNr]
        $Cell.Shading = $ConvertedColor
    }
    if ($Supress) { return } else { return $Table }
}
function Set-WordTableColumnWidth {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [float[]] $Width = @(),
        [nullable[float]] $TotalWidth = $null,
        [bool] $Percentage,
        [bool] $Supress)
    if ($null -ne $Table -and $null -ne $Width) {
        if ($Percentage) {
            Write-Verbose "Set-WordTableColumnWidth - Option A - Width: $([string] $Width) - Percentage: $Percentage - TotalWidth: $TotalWidth "
            $Table.SetWidthsPercentage($Width, $TotalWidth)
        } else {
            Write-Verbose "Set-WordTableColumnWidth - Option B - Width: $([string] $Width) - Percentage: $Percentage - TotalWidth: $TotalWidth "
            $Table.SetWidths($Width)
        }
    }
    if ($Supress) { return } else { return $Table }
}
function Set-WordTableColumnWidthByIndex {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[int]] $Index,
        [nullable[double]] $Width)
    if ($Table -ne $null -and $Index -ne $null -and $Width -ne $null) { $Table.SetColumnWidth($Index, $Width) }
}
function Set-WordTableDesign {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[Xceed.Document.NET.TableDesign]] $Design)
    if ($Table -ne $null -and $Design -ne $null) { $Table.Design = $Design }
    return $Table
}
function Set-WordTableDirection {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[Xceed.Document.NET.Direction]] $Direction)
    if ($Table -ne $null -and $Direction -ne $null) { $Table.SetDirection($Direction) }
    return $Table
}
function Set-WordTablePageBreak {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [switch] $AfterTable,
        [switch] $BeforeTable,
        [nullable[bool]] $BreakAcrossPages)
    if ($Table) {
        if ($BeforeTable) { $Table.InsertPageBreakBeforeSelf() }
        if ($AfterTable) { $Table.InsertPageBreakAfterSelf() }
        if ($BreakAcrossPages -ne $null) { $Table.BreakAcrossPages = $BreakAcrossPages }
    }
    return $Table
}
function Set-WordTableRowMergeCells {
    [CmdletBinding()]
    param([Xceed.Document.NET.InsertBeforeOrAfter] $Table,
        [nullable[int]] $RowNr,
        [nullable[int]] $ColumnNrStart,
        [nullable[int]] $ColumnNrEnd,
        [switch] $MergeAll,
        [switch] $TrackChanges,
        [switch] $TextMerge,
        [string] $Separator = ' ',
        [bool] $Supress = $false)
    if ($Table) {
        if ($MergeAll -and $null -ne $RowNr) {
            $CellsCount = $Table.Rows[$RowNr].Cells.Count
            $Table.Rows[$RowNr].MergeCells(0, $CellsCount)
            for ($paragraph = 0; $paragraph -lt $Table.Rows[$RowNr].Paragraphs.Count; $paragraph++) { try { $Table.Rows[$RowNr].Paragraphs[$paragraph].Remove($TrackChanges) } catch { Write-Warning -Message "Set-WordTableRowMergeCells - Failed to remove - Paragraph ($paragraph), Row ($RowNr), TrackChanges ($TrackChanges)" } }
        } elseif ($null -ne $RowNr -and $null -ne $ColumnNrStart -and $null -ne $ColumnNrEnd) {
            $CurrentParagraphCount = $Table.Rows[$RowNr].Cells[$ColumnNrStart].Paragraphs.Count
            $Table.Rows[$RowNr].MergeCells($ColumnNrStart, $ColumnNrEnd)
            if ($TextMerge) { [string] $Texts = foreach ($Paragraph in $Table.Rows[$RowNr].Cells[$ColumnNrStart].Paragraphs | Select-Object -Skip ($CurrentParagraphCount - 1)) { $Paragraph.Text } -join $Separator }
            foreach ($Paragraph in $Table.Rows[$RowNr].Cells[$ColumnNrStart].Paragraphs | Select-Object -Skip $CurrentParagraphCount) { $Paragraph.Remove($TrackChanges) }
            if ($TextMerge) { Set-WordTextText -Paragraph $Table.Rows[$RowNr].Cells[$ColumnNrStart].Paragraphs[$CurrentParagraphCount - 1] -Text $Texts -Supress $True }
        }
    }
    if ($Supress) { return } else { return $Table }
}
function Add-WordTOC {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [alias ('BeforeParagraph')][parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.InsertBeforeOrAfter] $Paragraph,
        [string] $Title = 'Table of contents',
        [Xceed.Document.NET.TableOfContentsSwitches[]] $Switches = @(),
        [alias ('Heading', 'HeadingType')][Xceed.Document.NET.HeadingType] $HeaderStyle = [Xceed.Document.NET.HeadingType]::Heading1,
        [int] $MaxIncludeLevel = 3,
        [int] $RightTabPos = $null,
        [bool] $Supress = $false)
    if ($WordDocument -ne $null) {
        $TableOfContentSwitch = 0
        foreach ($S in $switches) { $TableOfContentSwitch += $s -As [Int] }
        if ($Paragraph -eq $null) { $toc = $WordDocument.InsertTableOfContents($Title, $TableOfContentSwitch, $HeaderStyle, $MaxIncludeLevel, $RightTabPos) } else { $toc = $WordDocument.InsertTableOfContents($Paragraph, $Title, $TableOfContentSwitch, $HeaderStyle, $MaxIncludeLevel, $RightTabPos) }
    }
    if ($Supress -eq $false) { return $Toc } else { return }
}
function Add-WordTocItem {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Document.NET.Container] $WordDocument,
        [alias('Level')] [ValidateRange(0, 8)] [int] $ListLevel,
        [alias('ListType')][Xceed.Document.NET.ListItemType] $ListItemType = [Xceed.Document.NET.ListItemType]::Bulleted,
        [alias('Value', 'ListValue')]$Text,
        [alias ("HT")] [Xceed.Document.NET.HeadingType] $HeadingType = [Xceed.Document.NET.HeadingType]::Heading1,
        [nullable[int]] $StartNumber,
        [bool]$TrackChanges = $false,
        [bool]$ContinueNumbering = $true,
        [bool]$Supress = $false)
    $List = New-WordListItemInternal -WordDocument $WordDocument -List $null -Text $Text -ListItemType $ListItemType -ContinueNumbering $ContinueNumbering -ListLevel $ListLevel -StartNumber $StartNumber -TrackChanges $TrackChanges
    $List = Add-WordListItem -WordDocument $WordDocument -List $List
    $Paragraph = Convert-ListToHeadings -WordDocument $WordDocument -List $List -HeadingType $HeadingType
    if ($Supress) { return } else { return $Paragraph }
}
Add-Type -Path $PSScriptRoot\Lib\Default\Xceed.Document.NET.dll
Add-Type -Path $PSScriptRoot\Lib\Default\Xceed.Words.NET.dll
Export-ModuleMember -Function @('Add-WordBarChart', 'Add-WordChartSeries', 'Add-WordCustomProperty', 'Add-WordEquation', 'Add-WordFooter', 'Add-WordHeader', 'Add-WordHyperLink', 'Add-WordLine', 'Add-WordLineChart', 'Add-WordList', 'Add-WordListItem', 'Add-WordPageBreak', 'Add-WordPageCount', 'Add-WordParagraph', 'Add-WordPicture', 'Add-WordPieChart', 'Add-WordProtection', 'Add-WordSection', 'Add-WordTable', 'Add-WordTableCellValue', 'Add-WordTableColumn', 'Add-WordTableRow', 'Add-WordTableTitle', 'Add-WordTabStopPosition', 'Add-WordText', 'Add-WordTOC', 'Add-WordTocItem', 'Convert-ListToHeadings', 'Copy-WordTableRow', 'Get-WordCustomProperty', 'Get-WordDocument', 'Get-WordFooter', 'Get-WordHeader', 'Get-WordListItemParagraph', 'Get-WordPageSettings', 'Get-WordParagraphForList', 'Get-WordParagraphs', 'Get-WordPicture', 'Get-WordSection', 'Get-WordTable', 'Get-WordTableRow', 'Merge-WordDocument', 'New-WordBlock', 'New-WordBlockList', 'New-WordBlockPageBreak', 'New-WordBlockParagraph', 'New-WordBlockTable', 'New-WordDocument', 'New-WordList', 'New-WordListItem', 'New-WordListItemInternal', 'New-WordTable', 'New-WordTableBorder', 'Remove-WordParagraph', 'Remove-WordPicture', 'Remove-WordTable', 'Remove-WordTableColumn', 'Remove-WordTableRow', 'Remove-WordText', 'Save-WordDocument', 'Set-WordList', 'Set-WordMargins', 'Set-WordOrientation', 'Set-WordPageSettings', 'Set-WordPageSize', 'Set-WordParagraph', 'Set-WordPicture', 'Set-WordTable', 'Set-WordTableAutoFit', 'Set-WordTableBorder', 'Set-WordTableCell', 'Set-WordTableCellFillColor', 'Set-WordTableCellShadingColor', 'Set-WordTableColumnWidth', 'Set-WordTableColumnWidthByIndex', 'Set-WordTableDesign', 'Set-WordTableDirection', 'Set-WordTablePageBreak', 'Set-WordTableRowMergeCells', 'Set-WordText', 'Set-WordTextAlignment', 'Set-WordTextBold', 'Set-WordTextCapsStyle', 'Set-WordTextColor', 'Set-WordTextDirection', 'Set-WordTextFontFamily', 'Set-WordTextFontSize', 'Set-WordTextHeadingType', 'Set-WordTextHidden', 'Set-WordTextHighlight', 'Set-WordTextIndentationFirstLine', 'Set-WordTextIndentationHanging', 'Set-WordTextItalic', 'Set-WordTextKerning', 'Set-WordTextLanguage', 'Set-WordTextMisc', 'Set-WordTextPercentageScale', 'Set-WordTextPosition', 'Set-WordTextScript', 'Set-WordTextShadingType', 'Set-WordTextSpacing', 'Set-WordTextSpacingAfter', 'Set-WordTextSpacingBefore', 'Set-WordTextStrikeThrough', 'Set-WordTextUnderlineColor', 'Set-WordTextUnderlineStyle') -Alias @('Add-WordPageNumber')
function New-CommanderToolbarIcon {
    <#
    .SYNOPSIS
    Creates a notification tray toolbar icon.
    
    .DESCRIPTION
    Creates a notification tray toolbar icon.
    
    .PARAMETER Text
    Text to display when the icon is hovered.
    
    .PARAMETER MenuItem
    Menu items to display when the icon is right clicked.
    
    .PARAMETER LoadMenuItems
    A script block to call to dynamically load menu items.
    
    .PARAMETER HideExit
    Hides the exit menu item.
    
    .PARAMETER HideConfig
    Hides the config menu item.

    .PARAMETER Icon
    Path to an icon file to display in the toolbar.
    
    .EXAMPLE
    New-CommanderToolbarIcon -MenuItem @(
        New-CommanderMenuItem -Text 'Notepad' -Action {
            Start-Process notepad
        } -MenuItem @(
            New-CommanderMenuItem -Text 'Subnotepad' -Action {
                Start-Process notepad
            }
        ) -LoadMenuItems {  
            New-CommanderMenuItem -Text 'Dynamic SubNotepad' -Action {
                Start-Process notepad
            }
        }
    ) -LoadMenuItems {
        New-CommanderMenuItem -Text 'Dynamic Notepad' -Action {
            Start-Process notepad
        }
    }

    Creates a tool bar icon with several menu items.


    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Text, 
        [Parameter()]
        [pscommander.MenuItem[]]$MenuItem,
        [Parameter()]
        [ScriptBlock]$LoadMenuItems,
        [Parameter()]
        [Switch]$HideExit,
        [Parameter()]
        [Switch]$HideConfig,
        [Parameter()]
        [string]$Icon
    )

    Process {
        $ToolbarIcon = [pscommander.ToolbarIcon]::new()
        $ToolbarIcon.Text = $Text 
        $ToolbarIcon.MenuItems = $MenuItem
        $ToolbarIcon.LoadItems = $LoadMenuItems
        $ToolbarIcon.HideExit = $HideExit
        $ToolbarIcon.HideConfig = $HideConfig
        $ToolbarIcon.Icon = $Icon
        $ToolbarIcon
    }
}

function New-CommanderMenuItem {
    <#
    .SYNOPSIS
    Creates a new menu item to use within a toolbar notification icon.
    
    .DESCRIPTION
    Creates a new menu item to use within a toolbar notification icon.
    
    .PARAMETER Text
    The text to display for this menu item.
    
    .PARAMETER Action
    A script block to invoke when the menu item is clicked.
    
    .PARAMETER MenuItem
    Child menu items to display.
    
    .PARAMETER LoadMenuItems
    Child menu items to load dynamically.

    .PARAMETER ArgumentList
    Arguments passed to the action.

    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Text,
        [Parameter()]
        [ScriptBlock]$Action, 
        [Parameter()]
        [pscommander.MenuItem[]]$MenuItem,
        [Parameter()]
        [ScriptBlock]$LoadMenuItems,
        [Parameter()]
        [object[]]$ArgumentList = @()
    )

    Process {
        $mi = [pscommander.MenuItem]::new()
        $mi.Text = $Text 
        $mi.Action = $Action
        $mi.Children = $MenuItem
        $mi.LoadChildren = $LoadMenuItems
        $mi.ArgumentList = $ArgumentList
        $mi
    }
}

function New-CommanderHotKey {
    <#
    .SYNOPSIS
    Creates a new global hot key binding.
    
    .DESCRIPTION
    Creates a new global hot key binding.
    
    .PARAMETER ModifierKey
    One or modifier keys to use for this hot key.
    
    .PARAMETER Key
    The main key to use for this hot key.
    
    .PARAMETER Action
    The action to invoke for this hot key.
    
    .EXAMPLE
    New-CommanderHotKey -Key 'T' -ModifierKey 'Ctrl' -Action { 
        Start-Process notepad
    }

    Starts notepad when Ctrl+T is pressed.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [pscommander.ModifierKeys]$ModifierKey,
        [Parameter(Mandatory)]
        [pscommander.Keys]$Key,
        [Parameter(Mandatory)]
        [ScriptBlock]$Action
    )

    $HotKey = [pscommander.HotKey]::new()
    $HotKey.Id = Get-Random
    $HotKey.ModifierKeys = $ModifierKey
    $HotKey.Keys = $Key
    $HotKey.Action = $Action

    $HotKey
}

function New-CommanderSchedule {
    <#
    .SYNOPSIS
    Creates a scheduled action based on a CRON expression.
    
    .DESCRIPTION
    Creates a scheduled action based on a CRON expression.
    
    .PARAMETER Action
    The action to execute on the schedule. 
    
    .PARAMETER CronExpression
    The CRON expression that defines when to run the action.
    
    .EXAMPLE
    New-CommanderSchedule -CronExpression "* * * * *" -Action {
        Start-Process Notepad
    }

    Starts notepad every minute.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ScriptBlock]$Action,
        [Parameter()]
        [string]$CronExpression
    )

    $Schedule = [pscommander.Schedule]::new()
    $Schedule.Action = $Action 
    $Schedule.Cron = $CronExpression
    
    $Schedule
}

function New-CommanderContextMenu {
    <#
    .SYNOPSIS
    Creates a context menu item that executes PowerShell.
    
    .DESCRIPTION
    Creates a context menu item that executes PowerShell.
    
    .PARAMETER Action
    The script block action to execute. $Args[0] will include the path the was right clicked.
    
    .PARAMETER Text
    The text to display.
    
    .PARAMETER Location
    The location to display this context menu item. File will display this action when right clicking on the associated file extension. FolderLeftPane will display when right clicking on a folder in the left pane of the explorer window. FolderRightPane will display when right clicking on the folder in the right pane of the explorer window or the desktop.
    
    .PARAMETER Extension
    The extension to associate this context menu item to. This requires that Location is set to File. 
    
    .PARAMETER DisplayOnShiftClick
    Displays this option only when shift is help down during the right click.
    
    .PARAMETER Position
    The location to position this context menu item. You can select Top, Bottom and None. None is the default. 
    
    .PARAMETER Icon
    An icon to display for this context menu item.
    
    .PARAMETER IconIndex
    The index within the icon file to use. 
    
    .EXAMPLE
    New-CommanderContextMenu -Text 'Click me' -Action {
        Start-Process code -ArgumentList $args[0]
    }

    Starts VS Code and opens the file that was right clicked. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$Action, 
        [Parameter(Mandatory)]
        [string]$Text, 
        [Parameter()]
        [ValidateSet("FolderLeftPanel", "FolderRightPanel", "File")]
        [string]$Location = "File", 
        [Parameter()]
        [string]$Extension = "*",
        [Parameter()]
        [Switch]$DisplayOnShiftClick,
        [Parameter()]
        [ValidateSet("Top", "Bottom", "None")]
        [string]$Position = 'None',
        [Parameter()]
        [string]$Icon,
        [Parameter()]
        [int]$IconIndex
    )

    $ContextMenu = [pscommander.ExplorerContextMenu]::new()
    $ContextMenu.Id = Get-Random
    $ContextMenu.Action = $Action 
    $ContextMenu.Text = $Text 
    $ContextMenu.Location = $Location 
    $ContextMenu.Extension = $Extension 
    $ContextMenu.Extended = $DisplayOnShiftClick
    $ContextMenu.Position = $Position
    $ContextMenu.Icon = $Icon 
    $ContextMenu.IconIndex = $IconIndex
    $ContextMenu 
}

function New-CommanderFileAssociation {
    <#
    .SYNOPSIS
    Creates a file association that will invoke the action when it's opened.
    
    .DESCRIPTION
    Creates a file association that will invoke the action when it's opened.
    
    .PARAMETER Extension
    The extension to associate with the action. 
    
    .PARAMETER Action
    The action to execute when the file type is opened. $Args[0] will be the full file name of the file opened. 
    
    .EXAMPLE
    New-CommanderFileAssociation -Extension ".ps2" -Action {
        Start-Process code -ArgumentList $Args[0]
    }

    Starts VS Code and opens the opened PS2 file. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Extension,
        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    if (-not $Extension.StartsWith('.')) {
        throw "Extension needs to start with '.'"
    }

    $FileAssociation = [pscommander.FileAssociation]::new()
    $FileAssociation.Id = Get-Random
    $FileAssociation.Extension = $Extension
    $FileAssociation.Action = $Action
    $FileAssociation
}

function New-CommanderCustomProtocol {
    <#
    .SYNOPSIS
    Creates a custom protocol handler. 
    
    .DESCRIPTION
    Creates a custom protocol handler. 
    
    .PARAMETER Protocol
    The protcol scheme to use. 
    
    .PARAMETER Action
    The action to execute when the file type is opened. $Args[0] will be the full file name of the file opened. 
    
    .EXAMPLE
    New-CommanderCustomProtocol -Protocol "Commander" -Action {
        Start-Process code -ArgumentList $Args[0]
    }

    Starts code when the Commander protocol is used. Commander://test.txt 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Protocol,
        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    $CustomProtocol = [pscommander.CustomProtocol]::new()
    $CustomProtocol.Protocol = $Protocol
    $CustomProtocol.Action = $Action
    $CustomProtocol
}

function New-CommanderShortcut {
    <#
    .SYNOPSIS
    Creates a new desktop shortcut that will run the action.
    
    .DESCRIPTION
    Creates a new desktop shortcut that will run the action.
    
    .PARAMETER Text
    The text to display on the desktop.
    
    .PARAMETER Description
    The description shown when hovering the shortcut. 
    
    .PARAMETER Icon
    The icon to display.
    
    .PARAMETER Action
    The action to execute when the shortcut is clicked. 
    
    .EXAMPLE
    New-CommanderShortcut -Text 'Click Me' -Description 'Nice' -Action {
        Start-Process notepad
    }

    Creates a shortcut that will start notepad when clicked.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,
        [Parameter()]
        [string]$Description,
        [Parameter()]
        [string]$Icon,
        [Parameter(Mandatory)]
        [ScriptBlock]$Action
    )

    $Shortcut = [pscommander.Shortcut]::new()
    $Shortcut.Id = Get-Random
    $Shortcut.Text = $Text
    $Shortcut.Description = $Description
    $Shortcut.Icon = $Icon
    $Shortcut.Action = $Action
    $Shortcut
}

function Start-Commander {
    <#
    .SYNOPSIS
    Starts PSCommander. 
    
    .DESCRIPTION
    Starts PSCommander
    
    .EXAMPLE
    Start-Commander

    Starts PSCommander
    #>

    param($ConfigPath)

    if (-not $ConfigPath) {
        $Documents = [System.Environment]::GetFolderPath('MyDocuments')
        $ConfigPath = [IO.Path]::Combine($Documents, 'PSCommander', 'config.ps1')
    }

    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Configuration file for PSCommander not found. Creating config file..."
        New-Item -Path (Join-Path $Documents 'PSCommander') -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        "New-CommanderToolbarIcon -MenuItem @( 
    New-CommanderMenuItem -Text 'Documentation' -Action { 
        Start-Process 'https://docs.poshtools.com/powershell-pro-tools-documentation/pscommander' 
    } 
)" | Out-File $ConfigPath 
        Start-Process -FilePath "$PSScriptRoot\psscriptpad.exe" -ArgumentList @("-c `"$ConfigPath`"")
    }

    Start-Process (Join-Path $PSScriptRoot "PSCommander.exe") -ArgumentList "--configFilePath '$ConfigPath'"
}

function Install-Commander {
    <#
    .SYNOPSIS
    Sets commander to run on logon.

    .DESCRIPTION
    Sets commander to run on logon.

    .EXAMPLE
    Install-Commander

    Sets commander to run on logon.
    #>
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'PSCommander' -Value (Join-Path $PSScriptRoot "pscommander.exe") -Force | Out-Null 
}

function Uninstall-Commander {
    <#
    .SYNOPSIS
    Stops commander from running on logon.
    
    .DESCRIPTION
    Stops commander from running on logon.
    
    .EXAMPLE
    Uninstall-Commander

    Stops commander from running on logon.
    #>
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'PSCommander'
}

function Install-CommanderLicense {
    <#
    .SYNOPSIS
    Installs a PowerShell Pro Tools license to use with PSCommander.
    
    .DESCRIPTION
    Installs a PowerShell Pro Tools license to use with PSCommander. You will need to restart PSCommander after installing the license.
    
    .PARAMETER Path
    The path to the PowerShell Pro Tools license. 
    
    .EXAMPLE
    Install-CommanderLicense -Path .\license.txt 
    
    Installs the PSCommander license. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "File not found"
    }

    $Content = Get-Content $Path -Raw
    $Folder = Join-Path $env:appdata "PowerShell Pro Tools"
    if (-not (Test-Path $Folder)) {
        New-Item -Path $Folder -ItemType 'Directory'
    }

    $Content | Out-File (Join-Path $Folder "license.lic")
}

function Register-CommanderEvent {
    <#
    .SYNOPSIS
    Registers a handler to invoke when an event takes place.
    
    .DESCRIPTION
    Registers a handler to invoke when an event takes place.
    
    .PARAMETER OnCommander
    Specifies event handlers for events within commander. 

    .PARAMETER OnWindows
    Specifies event handlers for events within Windows.

    .PARAMETER WmiEventType
    Specifies the WMI event type to query when using -OnWindows WmiEvent

    .PARAMETER WmiEventFilter
    Specifies the WMI event filter to query when using -OnWindows WmiEvent
    
    .PARAMETER Action
    The action to invoke when an event takes place.
    
    .EXAMPLE
    Register-CommanderEvent -OnCommander Start -Action {
        Start-Process notepad
    }

    Starts notepad when commander starts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = "Commander")]
        [ValidateSet('start', 'stop', 'error')]
        [string]$OnCommander,
        [Parameter(Mandatory, ParameterSetName = "Windows")]
        [ValidateSet('ProcessStarted', 'WmiEvent')]
        [string]$OnWindows,
        [Parameter(ParameterSetName = "Windows")]
        [string]$WmiEventType,
        [Parameter(ParameterSetName = "Windows")]
        [string]$WmiEventFilter,
        [Parameter(Mandatory)]
        [ScriptBlock]$Action
    )

    $CommanderEvent = [pscommander.CommanderEvent]::new()
    $CommanderEvent.Id = Get-Random
    $CommanderEvent.Category = $PSCmdlet.ParameterSetName

    if ($OnCommander) {
        $CommanderEvent.Event = $OnCommander
    }
    
    if ($OnWindows) {
        $CommanderEvent.Event = $OnWindows
        if ($OnWindows -eq 'ProcessStarted') {
            $CommanderEvent.Properties['WmiEventType'] = "__InstanceCreationEvent"
            $CommanderEvent.Properties['WmiEventFilter'] = 'TargetInstance isa "Win32_Process"'
        }

        if ($OnWindows -eq 'WmiEvent') {
            $CommanderEvent.Properties['WmiEventType'] = $WmiEventType
            $CommanderEvent.Properties['WmiEventFilter'] = $WmiEventFilter
        }
    }

    $CommanderEvent.Action = $Action
    $CommanderEvent
}

function Stop-Commander {
    <#
    .SYNOPSIS
    Stops commander
    
    .DESCRIPTION
    Stops commander
    
    .EXAMPLE
    Stop-Commander
    #>
    Get-Process PSCommander | Stop-Process
}

function Set-CommanderSetting {
    <#
    .SYNOPSIS
    Set commander settings.
    
    .DESCRIPTION
    Set commander settings.
    
    .PARAMETER DisableUpdateCheck
    Does not check for updates when starting commander. Find-Module is used to check for updates. 
    
    .EXAMPLE
    Set-CommanderSetting -DisableUpdateCheck
    #>
    param(
        [Parameter()]
        [Switch]$DisableUpdateCheck
    )

    $Settings = [pscommander.Settings]::new()
    $Settings.DisableUpdateCheck = $DisableUpdateCheck
    $Settings
}

function New-CommanderDesktop {
    param(
        [Parameter(Mandatory)]
        [pscommander.DesktopWidget[]]$Widget
    )

    $Desktop = [pscommander.Desktop]::new();
    $Desktop.Widgets = $Widget 
    $Desktop
}

function Set-CommanderDesktop {
    <#
    .SYNOPSIS
    Sets the commander desktop widgets.
    
    .DESCRIPTION
    Sets the commander desktop widgets. This cmdlet must be run within PSCommander.
    
    .PARAMETER Widget
    Widgets to display on the desktop.
    #>
    param(
        [Parameter(Mandatory)]
        [pscommander.DesktopWidget[]]$Widget
    )

    if ($DesktopService -eq $null) {
        throw 'This cmdlet only works when running with PSCommander'
    }

    $Desktop = [pscommander.Desktop]::new();
    $Desktop.Widgets = $Widget 
    $Desktop
    
    $DesktopService.SetDesktop($Desktop)
}

function Clear-CommanderDesktop {
    <#
    .SYNOPSIS
    Clears the commander desktop.
    
    .DESCRIPTION
    Clears the commander desktop. This cmdlet must be run within PSCommander.
    
    .EXAMPLE
    Clear-CommanderDesktop
    #>
    if ($DesktopService -eq $null) {
        throw 'This cmdlet only works when running with PSCommander'
    }

    $DesktopService.ClearDesktop()
}

function New-CommanderDesktopWidget {
    <#
    .SYNOPSIS
    Creates a desktop widget.
    
    .DESCRIPTION
    Creates a desktop widget. Desktop widgets display data. They appear on top of the wall paper but under icons. They are not interactive. 
    
    .PARAMETER Top
    The top location of the widget.
    
    .PARAMETER Left
    The left location of the widget.
    
    .PARAMETER Height
    The height of the widget. 
    
    .PARAMETER Width
    The width of the widget. 
    
    .PARAMETER MeasurementHistory
    The number of measurements to keep in the graph.
    
    .PARAMETER MeasurementFrequency
    How frequently to record a new measurements in seconds. 
    
    .PARAMETER LoadMeasurement
    A script block that records a measurement. Expected to return a number.
    
    .PARAMETER MeasurementTitle
    The title of the measurement.
    
    .PARAMETER MeasurementSubtitle
    The subtitle of the measurement. 
    
    .PARAMETER MeasurementDescription
    The description of the measurement. 
    
    .PARAMETER MeasurementUnit
    The unit to display for the measurement. 
    
    .PARAMETER MeasurementTheme
    The theme to use for the measurement. 
    
    .PARAMETER LoadWidget
    Loads a custom WPF widget. You will need to return a Window. The window will not be interactive.
    
    .PARAMETER Url
    Displays the webpage specified by the URL.
    
    .PARAMETER Image
    An image to display. 
    
    .PARAMETER Text
    Text to display.
    
    .PARAMETER Font
    A font to use with the text. 
    
    .PARAMETER BackgroundColor
    A background color for the text. If absent, the wall paper will be used. 
    
    .PARAMETER FontColor
    The font color to use for the text. 
    
    .PARAMETER FontSize
    The font size to use for the text. 

    .PARAMETER DataSource
    The data source to load data from. 
    
    .EXAMPLE
    New-CommanderDesktopWidget -Text 'Hello, world!' -Height 200 -Width 1000 -FontSize 100 -Top 500 -Left 500

    Displays text on the desktop.

    .EXAMPLE
    New-CommanderDesktopWidget -Image 'C:\src\blog\content\images\news.png' -Height 200 -Width 200 -Top 200 

    Displays an image on the desktop. 

    .EXAMPLE
    New-CommanderDesktopWidget -Url 'https://www.google.com' -Height 500 -Width 500 -Top 400

    Displays a webpage on the desktop.

    .EXAMPLE
    New-CommanderDesktopWidget -LoadWidget {
       [xml]$Form = "<Window xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`"><Grid><Label Content=`"Hello, World`" Height=`"30`" Width=`"110`"/></Grid></Window>"
		$XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
		[Windows.Markup.XamlReader]::Load($XMLReader)
   } -Height 200 -Width 200 -Top 200 -Left 200

   Displays a custom WPF window on the desktop.

   .EXAMPLE 
   New-CommanderDesktopWidget -LoadMeasurement {Get-Random} -MeasurementTitle 'Test' -MeasurementSubtitle 'Tester' -MeasurementUnit '%' -Height 300 -Width 500 -Left 600 -Top 200 -MeasurementFrequency 1 -MeasurementDescription "Nice" -MeasurementTheme 'DarkBlue'

   Displays a measurement graph on the desktop.
    
    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = "Custom")]
    param(
        [Parameter()]
        [int]$Top,
        [Parameter()]
        [int]$Left,
        [Parameter()]
        [int]$Height = 12,
        [Parameter()]
        [int]$Width = 100,
        [Parameter()]
        [switch]$DisableTransparency,
        [Parameter(ParameterSetName = "Measurement")]
        [int]$MeasurementHistory = 100,
        [Parameter(ParameterSetName = "Measurement")]
        [int]$MeasurementFrequency = 30,
        [Parameter(Mandatory, ParameterSetName = "Measurement")]
        [ScriptBlock]$LoadMeasurement,
        [Parameter(Mandatory, ParameterSetName = "Measurement")]
        [string]$MeasurementTitle,
        [Parameter(Mandatory, ParameterSetName = "Measurement")]
        [string]$MeasurementSubtitle,
        [Parameter(ParameterSetName = "Measurement")]
        [string]$MeasurementDescription,
        [Parameter(Mandatory, ParameterSetName = "Measurement")]
        [string]$MeasurementUnit,
        [Parameter(ParameterSetName = "Measurement")]
        [ValidateSet("LightRed", 'LightGreen', 'LightBlue', "DarkRed", 'DarkGreen', 'DarkBlue')]
        [string]$MeasurementTheme = "LightRed",
        [Parameter(Mandatory, ParameterSetName = "Custom")]
        [Parameter(Mandatory, ParameterSetName = "DataSource")]
        [ScriptBlock]$LoadWidget,
        [Parameter(Mandatory, ParameterSetName = "Url")]
        [string]$Url,
        [Parameter(Mandatory, ParameterSetName = "Image")]
        [string]$Image,
        [Parameter(Mandatory, ParameterSetName = "Text")]
        [string]$Text,
        [Parameter(ParameterSetName = "Text")]
        [string]$Font,
        [Parameter(ParameterSetName = "Text")]
        [string]$BackgroundColor,
        [Parameter(ParameterSetName = "Text")]
        [string]$FontColor = '#fff',
        [Parameter(ParameterSetName = "Text")]
        [int]$FontSize = 12,
        [Parameter(ParameterSetName = "DataSource")]
        [string]$DataSource
    )

    $Widget = $null 
    if ($PSCmdlet.ParameterSetName -eq 'Text') {
        $Widget = [pscommander.TextDesktopWidget]::new()
        $Widget.Text = $Text
        $Widget.Font = $Font 
        $Widget.BackgroundColor = $BackgroundColor 
        $Widget.FontColor = $FontColor 
        $Widget.FontSize = $FontSize
    }

    if ($PScmdlet.ParameterSetName -eq 'Image') {
        $Widget = [pscommander.ImageDesktopWidget]::new() 
        $Widget.Image = $Image
    }

    if ($PSCmdlet.ParameterSetName -eq 'Url') {
        $Widget = [pscommander.WebpageDesktopWidget]::new()
        $Widget.Url = $Url
    }

    if ($PSCmdlet.ParameterSetName -eq 'Custom') {
        $Widget = [pscommander.CustomDesktopWidget]::new()
        $Widget.LoadWidget = $LoadWidget
    }

    if ($PSCmdlet.ParameterSetName -eq 'DataSource') {
        $Widget = [pscommander.DataDesktopWidget]::new()
        $Widget.LoadWidget = $LoadWidget
        $Widget.DataSource = $DataSource
    }

    if ($PSCmdlet.ParameterSetName -eq 'Measurement') {
        $Widget = [pscommander.MeasurementDesktopWidget]::new()
        $Widget.LoadMeasurement = $LoadMeasurement
        $Widget.Title = $MeasurementTitle
        $Widget.Subtitle = $MeasurementSubtitle
        $Widget.Unit = $MeasurementUnit
        $Widget.Frequency = $MeasurementFrequency
        $Widget.History = $MeasurementHistory
        $Widget.Description = $MeasurementDescription
        $Widget.Theme = $MeasurementTheme
    }

    $Widget.Top = $Top
    $Widget.Left = $Left
    $Widget.Height = $Height
    $Widget.Width = $Width
    $Widget.Transparent = -not $DisableTransparency.IsPresent
    $Widget
}

function Register-CommanderDataSource {
    <#
    .SYNOPSIS
    Registers a custom data source script block to run on an interval.
    
    .DESCRIPTION
    Registers a custom data source script block to run on an interval. Data sources can be used with desktop widgets. 
    
    .PARAMETER Name
    The name of the data source. 
    
    .PARAMETER LoadData
    The data to load. 
    
    .PARAMETER RefreshInterval
    The refresh interval in seconds. 
    
    .PARAMETER HistoryLimit
    The amount of history to retain. 
    
    .EXAMPLE
    Register-CommanderDataSource -Name 'ComputerInfo' -LoadData {
        $Stats = Get-NetAdapterStatistics
        $NetworkDown = 0
        $Stats.ReceivedBytes | Foreach-Object { $NetworkDown += $_ } 
        
        $NetworkUp = 0
        $Stats.SentBytes | Foreach-Object { $NetworkUp += $_ } 
            
        @{
            CPU = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -Expand Average
            Memory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
            NetworkUp = $NetworkUp / 1KB
            NetworkDown = $NetworkDown / 1KB
        }
    } -RefreshInterval 5

    Gathers computer information and stores it as a data source.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name, 
        [Parameter(Mandatory)]
        [ScriptBlock]$LoadData, 
        [Parameter()]
        [int]$RefreshInterval = 60,
        [Parameter()]
        [int]$HistoryLimit = 10 ,
        [Parameter()]
        [object[]]$ArgumentList = @()
    )

    $DataSource = [pscommander.DataSource]::new()
    $DataSource.Name = $Name 
    $DataSource.LoadData = $LoadData 
    $DataSource.RefreshInterval = $RefreshInterval
    $DataSource.HistoryLimit = $HistoryLimit
    $DataSource.ArgumentList = $ArgumentList
    $DataSource
}

function New-CommanderBlink {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Blink = [pscommander.Blink]::new()
    $Blink.Path = $Path
    $Blink
}
# SIG # Begin signature block
# MIIZgQYJKoZIhvcNAQcCoIIZcjCCGW4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU96iLxf1STurVv7JCM11mQc7T
# Vz6gghSPMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBSAwggQI
# oAMCAQICEAt+xO9Gr4vTuh34OEyIkdwwDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMTA0MDUwMDAwMDBaFw0yMjA0MTIyMzU5NTlaMF4xCzAJ
# BgNVBAYTAlVTMQ4wDAYDVQQIEwVJZGFobzEPMA0GA1UEBxMGSGFpbGV5MRYwFAYD
# VQQKEw1BZGFtIERyaXNjb2xsMRYwFAYDVQQDEw1BZGFtIERyaXNjb2xsMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwIuNYs3TqwWb2B366lXeTnod7DUH
# PG8X65leprfUJkvAN82lexIMGxhFm7NW33PL/PQqfaAf7VoTF/b+sNiHUaSxoNkO
# uOaB9kxqz/JELaDbC7aLZ5fMtQ6XYZzF8w3O5ND1EchkXgRYfvArgGQ/FHRsWP38
# yRJUKgkUiamXc3Vndf5fR+0cAv//T2xkT8Qtea6PZVYT/FMvCOCU6JNKvrQizI8X
# of5BfnVjJmsqYyKzJ9H+XskKLUG4Z5R4E/Iyl5tqE71beCymgf2hfbj0jQyoGN98
# UEnHXSLs/s1QgF8xj4EdMWm7LbU7PEbCFST8YBCsEXE2Ws956D3HQ5cRnQIDAQAB
# o4IBxDCCAcAwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0O
# BBYEFFlwWJYbrJY+eGzrteeyGguWHT3aMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE
# DDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwSwYDVR0gBEQw
# QjA2BglghkgBhv1sAwEwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2ln
# bmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQBHZcWj
# Ajcj20p1mdag+bH1DX2Sx/9ctNT3jlTONCEeXNUNy7IR4KC1hcBksJwWphbTEgmv
# XDswoeV+d4W2i1+llV0d6CUL5xmMuv7iW3f5Ia+9Dj9RZFOt00W0v6nigtbS5d85
# k6zZXegWVmlRP5z/gwfLzCLbEo87JpX7LuQP9vWcCjRP2uCp6L7TtP4Ol+u18sti
# tw+PXBazxZXg0I0J8UpBQkjyLofo7be+5fcZnrt8rKcqhCJAGkkgQCfbkfRMWd84
# bH3tsNGTYIR6jzaL830OunyO2+uPRreYR6yHCa4IhrvKfI5xj1sFO077hm/EGsxv
# lgpPiI/H8Otl7KM5MIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkq
# hkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBB
# c3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAw
# WjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3Vy
# ZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6
# kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQj
# ZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5w
# MWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp
# 6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH
# 5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgw
# BgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYI
# KwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
# b20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUH
# AgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYD
# VR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuC
# MS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2
# qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4Q
# pO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEp
# KBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/Dm
# ZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9
# CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHv
# MIIFMTCCBBmgAwIBAgIQCqEl1tYyG35B5AXaNpfCFTANBgkqhkiG9w0BAQsFADBl
# MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
# d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJv
# b3QgQ0EwHhcNMTYwMTA3MTIwMDAwWhcNMzEwMTA3MTIwMDAwWjByMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0
# YW1waW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvdAy7kvN
# j3/dqbqCmcU5VChXtiNKxA4HRTNREH3Q+X1NaH7ntqD0jbOI5Je/YyGQmL8TvFfT
# w+F+CNZqFAA49y4eO+7MpvYyWf5fZT/gm+vjRkcGGlV+Cyd+wKL1oODeIj8O/36V
# +/OjuiI+GKwR5PCZA207hXwJ0+5dyJoLVOOoCXFr4M8iEA91z3FyTgqt30A6XLdR
# 4aF5FMZNJCMwXbzsPGBqrC8HzP3w6kfZiFBe/WZuVmEnKYmEUeaC50ZQ/ZQqLKfk
# dT66mA+Ef58xFNat1fJky3seBdCEGXIX8RcG7z3N1k3vBkL9olMqT4UdxB08r8/a
# rBD13ays6Vb/kwIDAQABo4IBzjCCAcowHQYDVR0OBBYEFPS24SAd/imu0uRhpbKi
# JbLIFzVuMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRo
# dHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMFAGA1UdIARJMEcwOAYKYIZIAYb9bAACBDAqMCgGCCsG
# AQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAsGCWCGSAGG/WwH
# ATANBgkqhkiG9w0BAQsFAAOCAQEAcZUS6VGHVmnN793afKpjerN4zwY3QITvS4S/
# ys8DAv3Fp8MOIEIsr3fzKx8MIVoqtwU0HWqumfgnoma/Capg33akOpMP+LLR2HwZ
# YuhegiUexLoceywh4tZbLBQ1QwRostt1AuByx5jWPGTlH0gQGF+JOGFNYkYkh2OM
# kVIsrymJ5Xgf1gsUpYDXEkdws3XVk4WTfraSZ/tTYYmo9WuWwPRYaQ18yAGxuSh1
# t5ljhSKMYcp5lH5Z/IwP42+1ASa2bKXuh1Eh5Fhgm7oMLSttosR+u8QlK0cCCHxJ
# rhO24XxCQijGGFbPQTS2Zl22dHv1VjMiLyI2skuiSpXY9aaOUjGCBFwwggRYAgEB
# MIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNz
# dXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAt+xO9Gr4vTuh34OEyIkdwwCQYFKw4D
# AhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZI
# hvcNAQkEMRYEFCMLdJbidNoGSfU2AMQ/ORpUP2H2MA0GCSqGSIb3DQEBAQUABIIB
# AEuWd3x/XN5H3RhnMUbWmYsNiyPY31+mvnhTzEisX3yFUOITj/6T6b/A2jahzh4P
# NGWCJcgXkW4ZmgjAUEg+3tK5IAnPhMfcytNJ6yClA9vEwi7HowNPSALt/asqxfkU
# vO49+ciM2woNPlCcyasDt3hERSp1EaZGJ96WQy2VGvsD3U4KRpB2ch+j3thD8cem
# N2p1sMMhpPx/HGDs7BPM7TWdhOavhvfApLGZxQzH5vmZ2Qhk0eqUTVuOmsQjQzn/
# q7BUx2PJDpbHj0WFIvs9WnQKxsemNjnVlYia+2CQ4RLLYk+CUl1NvEwb+JFGlmR3
# TlVITPBEYDAAFNzr+H41pkShggIwMIICLAYJKoZIhvcNAQkGMYICHTCCAhkCAQEw
# gYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1
# cmVkIElEIFRpbWVzdGFtcGluZyBDQQIQDUJK4L46iP9gQCHOFADw3TANBglghkgB
# ZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkF
# MQ8XDTIyMDExMTEzNTgwNFowLwYJKoZIhvcNAQkEMSIEINNDPf2SisQAIBlp1Fw0
# uojQ8Hger8K4aV0wTel1C+D1MA0GCSqGSIb3DQEBAQUABIIBAGtMLKol6aDnXtP/
# /pQfCD9ZmecCtx0/aaEANC0CBWoD7yNjNPEjau1oX4cneixNXuercMuZ8sVZf3af
# P/QtHkrdWEzcgA+H4IDVfSEGzwnJ4l3LbMN9k7rZ4hO2iLK1l1mK6YJ0Cxf7Gcvj
# EDLxTVxdONNEq5YUnQ8Gq6J3Z6Cbik9jzyYWSfxgWbTOjoPwxlyu60mhIyn6JhMj
# TcjzEfwqFb6WXWmhB+VzskHHcbBSukKNL5TSnRg6UzBL/WtqitMpBWcP+DiddiF3
# K1osPGwR9SH4dBqjOUciDyVsdt0UmL2AOeujaHt90gj7NMNsDcholmlVInDAiosm
# JSMFzMY=
# SIG # End signature block

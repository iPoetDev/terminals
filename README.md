# terminals
Developer-Environnment: Terminals, Prompts, Shells, Configurations

## Powershell Profiles

## Tools

1. Terminals

- Windows: Windows Terminal, VSCode Terminal, 
- Linux: Terminator, Guake Terminal, Tilix, Hyper, Tilda, Alacritty, Konsole, GNOME Terminal, Yakuake, Kitty, XTERM
- macOSX: maxOS Terminal, iTerm

2. Package Managers

a. Windows

- Winget
- Scoop
- Choco
- PowerShellGet (PSGallery)

b. Linux

- Default package management per distribution 'Nix OS

c. macOS

- Homebrew

3. Shells

- Powershell - Cross Platform (Win, Linux, macOS)
- Bash (CyGwin, MyGnw, macOS, Linux)
- Fish (macOS, Linux))
- Zsh (macOS, Linux)

4. Installables (Powershell)

- See components below

> Just note: 

## Components

After Oh My Posh is installed, next steps are to configure the terminal and shell to get the prompt to look exactly like you want.

- install a font
- configure your terminal/editor to use the installed font
- configure your shell to use Oh My Posh
- (optional) configure a theme or custom prompt configuration

### Terminal



### Oh-My-Posh

[Website: Oh-My-Posh](https://ohmyposh.dev/) ⚫ [Github: jandedobbeleer](https://github.com/jandedobbeleer/oh-my-posh)

- No longer a Powrrshell Module => Is an portable executable, on $PATH.
- Is invoked as an expression in/from $PROFILE 

scoop
```powershell
  oh-my-posh init pwsh --config "$(scoop prefix oh-my-posh)\themes\jandedobbeleer.omp.json"
```

winget
```powershe
  oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"
```

```powershell
import-module oh-my-posh -scope Global
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"

```

### Nerd Fonts

#### Font Patching

[GitHub: NerdFont](https://github.com/ryanoasis/nerd-fonts/)

>> Use the provided FontForge Python Script to patch your own font or to generate over 1.4 million unique combinations/variations (more details).<br />
>> You can even specify a custom symbol font with the --custom option to include even more glyphs. <figcaption>https://www.nerdfonts.com/</figcaption>

```shell
   fontforge --script ./font-patcher --complete <YOUR FONT FILE>
```

`fontforge --script ./font-patcher --help`

<detail><summary></summary>

```shell
  ./font-patcher
usage: font-patcher [-h] [-v] [-s] [-l] [-q] [-w] [-c] [--careful]
                    [--removeligs] [--postprocess [POSTPROCESS]]
                    [--configfile [CONFIGFILE]] [--custom [CUSTOM]]
                    [-ext [EXTENSION]] [-out [OUTPUTDIR]]
                    [--glyphdir [GLYPHDIR]] [--makegroups]
                    [--variable-width-glyphs]
                    [--progressbars | --no-progressbars] [--also-windows]
                    [--fontawesome] [--fontawesomeextension] [--fontlogos]
                    [--octicons] [--codicons] [--powersymbols] [--pomicons]
                    [--powerline] [--powerlineextra] [--material] [--weather]
                    font

Nerd Fonts Font Patcher: patches a given font with programming and development related glyphs

* Website: https://www.nerdfonts.com
* Version: 2.2.2
* Development Website: https://github.com/ryanoasis/nerd-fonts
* Changelog: https://github.com/ryanoasis/nerd-fonts/blob/master/changelog.md

positional arguments:
  font                  The path to the font to patch (e.g., Inconsolata.otf)

options:
  -h, --help            show this help message and exit
  -v, --version         show program's version number and exit
  -s, --mono, --use-single-width-glyphs
                        Whether to generate the glyphs as single-width not double-width (default is double-width)
  -l, --adjust-line-height
                        Whether to adjust line heights (attempt to center powerline separators more evenly)
  -q, --quiet, --shutup
                        Do not generate verbose output
  -w, --windows         Limit the internal font name to 31 characters (for Windows compatibility)
  -c, --complete        Add all available Glyphs
  --careful             Do not overwrite existing glyphs if detected
  --removeligs, --removeligatures
                        Removes ligatures specificed in JSON configuration file
  --postprocess [POSTPROCESS]
                        Specify a Script for Post Processing
  --configfile [CONFIGFILE]
                        Specify a file path for JSON configuration file (see sample: src/config.sample.json)
  --custom [CUSTOM]     Specify a custom symbol font. All new glyphs will be copied, with no scaling applied.
  -ext [EXTENSION], --extension [EXTENSION]
                        Change font file type to create (e.g., ttf, otf)
  -out [OUTPUTDIR], --outputdir [OUTPUTDIR]
                        The directory to output the patched font file to
  --glyphdir [GLYPHDIR]
                        Path to glyphs to be used for patching
  --makegroups          Use alternative method to name patched fonts (experimental)
  --variable-width-glyphs
                        Do not adjust advance width (no "overhang")
  --progressbars        Show percentage completion progress bars per Glyph Set
  --no-progressbars     Don't show percentage completion progress bars per Glyph Set
  --also-windows        Create two fonts, the normal and the --windows version

Symbol Fonts:
  --fontawesome         Add Font Awesome Glyphs (http://fontawesome.io/)
  --fontawesomeextension
                        Add Font Awesome Extension Glyphs (https://andrelzgava.github.io/font-awesome-extension/)
  --fontlogos, --fontlinux
                        Add Font Logos Glyphs (https://github.com/Lukas-W/font-logos)
  --octicons            Add Octicons Glyphs (https://octicons.github.com)
  --codicons            Add Codicons Glyphs (https://github.com/microsoft/vscode-codicons)
  --powersymbols        Add IEC Power Symbols (https://unicodepowersymbol.com/)
  --pomicons            Add Pomicon Glyphs (https://github.com/gabrielelana/pomicons)
  --powerline           Add Powerline Glyphs
  --powerlineextra      Add Powerline Glyphs (https://github.com/ryanoasis/powerline-extra-symbols)
  --material, --materialdesignicons, --mdi
                        Add Material Design Icons (https://github.com/templarian/MaterialDesign)
  --weather, --weathericons
                        Add Weather Icons (https://github.com/erikflowers/weather-icons)
```

</detail>

### Configure a Theme/Custom Prompt Configuration

- [Schema](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/schema.json)

#### Oh-My-Posh Segments

##### Interesting

- Project
- Command
- Connection
- Git: Status, Stash, Worktree, Upstream, Bare, Branch, Branch Id, Branch Behind, Branch Gone, Commit, Tag, Rebase. Cheery, Recert,, GitLab, Biktbucket,, Gthub, Git,
- OS 
- Path
- SSH
- Shell
- Text
- Time
- Wakatime
- Withings


#### PSReadline

- [Source: Hanselman](https://www.hanselman.com/blog/you-should-be-customizing-your-powershell-prompt-with-psreadline)
- [Sample: Advanced PSReadline](https://raw.githubusercontent.com/PowerShell/PSReadLine/master/PSReadLine/SamplePSReadLineProfile.ps1)

###### [Features](https://github.com/PowerShell/PSReadLine)

This module replaces the command line editing experience of PowerShell for versions 3 and up. It provides:

- Syntax coloring
- Simple syntax error notification
- A good multi-line experience (both editing and history)
- Customizable key bindings
- Cmd and emacs modes (neither are fully implemented yet, but both are usable)
- Many configuration options
- Bash style completion (optional in Cmd mode, default in Emacs mode)
- Bash/zsh style interactive history search (CTRL-R)
- Emacs yank/kill ring
- PowerShell token based "word" movement and kill
- Undo/redo
- Automatic saving of history, including sharing history across live sessions
- "Menu" completion (somewhat like Intellisense, select completion with arrows) via Ctrl+Space

Set to Profile
```powershell
# History
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Get-PSReadLineKeyHandler #See Below
```

Basic editing functions
=======================

| Key              Function           Description                                                                                                     |
| :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| ---              --------           -----------                                                                                                     |
| Shift+Enter      AddLine            Move the cursor to the next line without attempting to execute the input                                        |
| F12,c            AddLine            Move the cursor to the next line without attempting to execute the input                                        |
| Backspace        BackwardDeleteChar Delete the character before the cursor                                                                          |
| Ctrl+h           BackwardDeleteChar Delete the character before the cursor                                                                          |
| Ctrl+Home        BackwardDeleteLine Delete text from the cursor to the start of the line                                                            |
| Ctrl+Backspace   BackwardKillWord   Move the text from the start of the current or previous word to the cursor to the kill ring                     |
| Ctrl+w           BackwardKillWord   Move the text from the start of the current or previous word to the cursor to the kill ring                     |
| Ctrl+C           Copy               Copy selected region to the system clipboard.  If no region is selected, copy the whole line                    |
| Ctrl+c           CopyOrCancelLine   Either copy selected text to the clipboard, or if no text is selected, cancel editing the line with CancelLine. |
| Ctrl+x           Cut                Delete selected region placing deleted text in the system clipboard                                             |
| Delete           DeleteChar         Delete the character under the cursor                                                                           |
| Ctrl+End         ForwardDeleteLine  Delete text from the cursor to the end of the line                                                              |
| Ctrl+Enter       InsertLineAbove    Inserts a new empty line above the current line without attempting to execute the input                         |
| Shift+Ctrl+Enter InsertLineBelow    Inserts a new empty line below the current line without attempting to execute the input                         |
| Alt+d            KillWord           Move the text from the cursor to the end of the current or next word to the kill ring                           |
| Ctrl+Delete      KillWord           Move the text from the cursor to the end of the current or next word to the kill ring                           |
| Ctrl+v           Paste              Paste text from the system clipboard                                                                            |
| Shift+Insert     Paste              Paste text from the system clipboard                                                                            |
| Ctrl+y           Redo               Redo an undo                                                                                                    |
| Escape           RevertLine         Equivalent to undo all edits (clears the line except lines imported from history)                               |
| Ctrl+z           Undo               Undo a previous edit                                                                                            |
| Alt+.            YankLastArg        Copy the text of the last argument to the input                                                                 |

Cursor movement functions
=========================

| Key             Function        Description                                                      |
| :----------------------------------------------------------------------------------------------- |
| ---             --------        -----------                                                      |
| LeftArrow       BackwardChar    Move the cursor back one character                               |
| Ctrl+LeftArrow  BackwardWord    Move the cursor to the beginning of the current or previous word |
| Home            BeginningOfLine Move the cursor to the beginning of the line                     |
| End             EndOfLine       Move the cursor to the end of the line                           |
| RightArrow      ForwardChar     Move the cursor forward one character                            |
| Ctrl+]          GotoBrace       Go to matching brace                                             |
| Ctrl+RightArrow NextWord        Move the cursor forward to the start of the next word            |

History functions
=================

| Key       Function              Description                                                                                                                 |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ---       --------              -----------                                                                                                                 |
| Alt+F7    ClearHistory          Remove all items from the command line history (not PowerShell history)                                                     |
| Ctrl+s    ForwardSearchHistory  Search history forward interactively                                                                                        |
| F8        HistorySearchBackward Search for the previous item in the history that starts with the current input - like PreviousHistory if the input is empty |
| Shift+F8  HistorySearchForward  Search for the next item in the history that starts with the current input - like NextHistory if the input is empty         |
| DownArrow NextHistory           Replace the input with the next item in the history                                                                         |
| UpArrow   PreviousHistory       Replace the input with the previous item in the history                                                                     |
| Ctrl+r    ReverseSearchHistory  Search history backwards interactively                                                                                      |

Completion functions
====================

| Key           Function            Description                                                                                                                        |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ---           --------            -----------                                                                                                                        |
| Ctrl+@        MenuComplete        Complete the input if there is a single completion, otherwise complete the input by selecting from a menu of possible completions. |
| Ctrl+Spacebar MenuComplete        Complete the input if there is a single completion, otherwise complete the input by selecting from a menu of possible completions. |
| F12,a         MenuComplete        Complete the input if there is a single completion, otherwise complete the input by selecting from a menu of possible completions. |
| Tab           TabCompleteNext     Complete the input using the next completion                                                                                       |
| Shift+Tab     TabCompletePrevious Complete the input using the previous completion                                                                                   |

Miscellaneous functions
=======================

| Key           Function              Description                                                           |
| :-------------------------------------------------------------------------------------------------------- |
| ---           --------              -----------                                                           |
| Ctrl+l        ClearScreen           Clear the screen and redraw the current line at the top of the screen |
| Alt+0         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+1         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+2         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+3         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+4         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+5         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+6         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+7         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+8         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+9         DigitArgument         Start or accumulate a numeric argument to other functions             |
| Alt+-         DigitArgument         Start or accumulate a numeric argument to other functions             |
| PageDown      ScrollDisplayDown     Scroll the display down one screen                                    |
| Ctrl+PageDown ScrollDisplayDownLine Scroll the display down one line                                      |
| PageUp        ScrollDisplayUp       Scroll the display up one screen                                      |
| Ctrl+PageUp   ScrollDisplayUpLine   Scroll the display up one line                                        |
| Ctrl+Alt+?    ShowKeyBindings       Show all key bindings                                                 |
| Alt+?         WhatIsKey             Show the key binding for the next chord entered                       |
|                                                                                                           |
Selection functions
===================

| Key                   Function            Description                                                                      |
| :------------------------------------------------------------------------------------------------------------------------- |
| ---                   --------            -----------                                                                      |
| Ctrl+a                SelectAll           Select the entire line. Moves the cursor to the end of the line                  |
| Shift+LeftArrow       SelectBackwardChar  Adjust the current selection to include the previous character                   |
| Shift+Home            SelectBackwardsLine Adjust the current selection to include from the cursor to the end of the line   |
| Shift+Ctrl+LeftArrow  SelectBackwardWord  Adjust the current selection to include the previous word                        |
| Shift+RightArrow      SelectForwardChar   Adjust the current selection to include the next character                       |
| Shift+End             SelectLine          Adjust the current selection to include from the cursor to the start of the line |
| F12,d                 SelectLine          Adjust the current selection to include from the cursor to the start of the line |
| Shift+Ctrl+RightArrow SelectNextWord      Adjust the current selection to include the next word                            |

Search functions
================

| Key      |Function                |Description                                                                      |
| :---------------------------------------------------------------------------------------------------------------- |
| ---      |--------                |-----------                                                                      |
| F3       |CharacterSearch         |Read a character and move the cursor to the next occurence of that character     |
| Shift+F3 |CharacterSearchBackward |Read a character and move the cursor to the previous occurence of that character |

User defined functions
======================

| Key      |Function                |Description         |
| :--------------------------------------------------- |
| ---      |--------                |-----------         |
| Enter    |OhMyPoshEnterKeyHandler |User defined action |
| Spacebar |OhMyPoshSpaceKeyHandler |User defined action |

##### [Sample](https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1?WT.mc_id=-blog-scottha)

```powershell
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
```

```powershell

# Searching for commands with up/down arrow is really handy.  The
# option "moves to end" is useful if you want the cursor at the end
# of the line while cycling through history like it does w/o searching,
# without that option, the cursor will remain at the position it was
# when you used up arrow, which can be useful if you forget the exact
# string you started the search on

# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.

# This is an example of a macro that you might use to execute a command.
# This will add the command to history.

# In Emacs mode - Tab acts like in bash, but the Windows style completion
# is still useful sometimes, so bind some keys so we can do both

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.

# CaptureScreen is good for blog posts or email showing a transaction
# of what you did when asking for help or demonstrating a technique.

# The built-in word movement uses character delimiters, but token based word
# movement is also very useful - these are the bindings you'd use if you
# prefer the token based movements bound to the normal emacs word movement
# key bindings.


#region Smart Insert/Delete

# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.

# This example will replace any aliases on the command line with the resolved commands.

# F1 for help on the command line - naturally

# Ctrl+Shift+j then type a key to mark the current directory.
# Ctrj+j then the same key will change back to that directory without
# needing to type cd and won't change the command line.

# Auto correct 'git cmt' to 'git commit'

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line. 
```

### Setting Aliases

- [References: MS Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-alias?view=powershell-7.2)
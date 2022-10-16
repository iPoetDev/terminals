$Commands = @{
    'PowerSsh' = @('ssh', 'ssh-agent', 'ssh-add', 'scp', 'sftp', 'rsync');
    'Bash' = @('ssh-keygen', 'ssh-copy-id', 'ssh-keyscan');
}

Function Set-ModulePowerSSH {
    ForEach ($Type in $Commands.GetEnumerator()) {
        ForEach ($Command in $Type.Value) {
            Invoke-Expression -Command "Add-$($Type.Key)Command -Command $Command"
        }
    }
    Set-ModuleBash
}

Function Invoke-PowerSshCommand {
    If ([System.Environment]::GetEnvironmentVariable('PowerSshChecked', 'Process')) {
        $AgentPid = [System.Environment]::GetEnvironmentVariable('PowerSshAgentPid', 'User')
        $AgentSocket = [System.Environment]::GetEnvironmentVariable('PowerSshAgentSocket', 'User')
    } Else {
        # Detection of WSL
        Bash -c ':'
        # Bash
        If (`
            (-Not ($ProcessBashId = [System.Environment]::GetEnvironmentVariable('PowerSshId', 'User')))`
            -Or (-Not ($ProcessBash = Get-Process -Name PowerShell | Where-Object -Property Id -Eq $ProcessBashId))`
            -Or ($ProcessBash.StartTime.GetHashCode() -NotLike [System.Environment]::GetEnvironmentVariable('PowerSshHash', 'User'))`
        ) {
            $ProcessBash = Start-Process PowerShell -PassThru -ArgumentList '-WindowStyle Hidden -Command Bash'
            [System.Environment]::SetEnvironmentVariable('PowerSshId', $ProcessBash.Id, 'User')
            [System.Environment]::SetEnvironmentVariable('PowerSshHash', $ProcessBash.StartTime.GetHashCode(), 'User')
        }
        # Agent
        If (`
            (-Not ($AgentPid = [System.Environment]::GetEnvironmentVariable('PowerSshAgentPid', 'User')))`
            -Or (-Not ($AgentSocket = [System.Environment]::GetEnvironmentVariable('PowerSshAgentSocket', 'User')))`
            -Or (-Not (Bash -c "ps $AgentPid | grep ssh-agent"))
        ) {
            If ($MyInvocation.InvocationName -eq 'ssh-agent') {
                $AgentOutput = Bash -c "ssh-agent $Args" | Select-String -Pattern '(SSH_[A-Z_]+)=([^;]*)' -AllMatches
            } Else {
                $AgentOutput = Bash -c 'ssh-agent' | Select-String -Pattern '(SSH_[A-Z_]+)=([^;]*)' -AllMatches
            }
            $AgentPid = $AgentOutput.Matches[1].Groups[2].Value
            $AgentSocket = $AgentOutput.Matches[0].Groups[2].Value
            [System.Environment]::SetEnvironmentVariable('PowerSshAgentPid', $AgentPid, 'User')
            [System.Environment]::SetEnvironmentVariable('PowerSshAgentSocket', $AgentSocket, 'User')
            If (Bash -c "grep ~/.bashrc -e 'export SSH_AGENT_PID'") {
                Bash -c "sed -i 's/export SSH_AGENT_PID=.*/export SSH_AGENT_PID=$AgentPid/g' ~/.bashrc"
                Bash -c "sed -i 's/export SSH_AUTH_SOCK=.*/export SSH_AUTH_SOCK=$($AgentSocket -replace '/', '\/')/g' ~/.bashrc"
            } Else {
                Bash -c "printf 'export SSH_AGENT_PID=$AgentPid\nexport SSH_AUTH_SOCK=$AgentSocket' >> ~/.bashrc"
            }
        }
        # Key
        If ($MyInvocation.InvocationName -eq 'ssh-add') {
            Bash -c "export SSH_AGENT_PID=$AgentPid && export SSH_AUTH_SOCK=$AgentSocket && ssh-add $Args"
        } Else {
            If (-Not (Bash -c "export SSH_AGENT_PID=$AgentPid && export SSH_AUTH_SOCK=$AgentSocket && ssh-add -l 2> /dev/null | grep .ssh")) {
                Bash -c "export SSH_AGENT_PID=$AgentPid && export SSH_AUTH_SOCK=$AgentSocket && ssh-add"
            }
        }
        If (Bash -c "export SSH_AGENT_PID=$AgentPid && export SSH_AUTH_SOCK=$AgentSocket && ssh-add -l 2> /dev/null | grep .ssh") {
            [System.Environment]::SetEnvironmentVariable('PowerSshChecked', $True, 'Process')
        }
    }
    Bash -c "export SSH_AGENT_PID=$AgentPid && export SSH_AUTH_SOCK=$AgentSocket && $($MyInvocation.InvocationName) $Args"
}

Function Add-PowerSshCommand {
    Param(
        [Parameter(
            Mandatory = $True
        )]
        [String] $Command
    )
    Set-Alias -Name $Command -Value Invoke-PowerSshCommand -Scope Global -ErrorAction Stop
    If (-Not (Test-Path -PathType Leaf -Path $Profile)) {
        New-Item -ItemType File -Path $Profile
    }
    $Content = "Set-Alias -Name $Command -Value Invoke-PowerSshCommand"
    If (-Not (Get-Content -Path $Profile | Select-String -SimpleMatch $Content)) {
        Add-Content -Path $Profile -Value $Content
    }
}

Function Remove-PowerSshCommand {
    Param(
        [Parameter(
            Mandatory = $True
        )]
        [String] $Command
    )
    Remove-Item Alias:$Command
    If (Test-Path -PathType Leaf -Path $Profile) {
        $Content = Get-Content -Path $Profile | Select-String -NotMatch -Pattern "Set-Alias -Name $Command -Value Invoke-PowerSshCommand"
        Set-Content -Path $Profile -Value $Content
    }
}

Function Get-PowerSshCommand {
    Param(
        [String] $Command
    )
    If ($Command) {
        If (Get-Content -Path $Profile | Select-String -Pattern "Set-Alias -Name $Command -Value Invoke-PowerSshCommand") {
            Write-Output $Command
        }
    } Else {
        $MatchesCommands = Get-Content -Path $Profile | Select-String -Pattern "Set-Alias -Name (\w+) -Value Invoke-PowerSshCommand"
        ForEach ($Match in $MatchesCommands.Matches) {
            Write-Output $Match.Groups[1].Value
        }
    }
}

Function Set-SshKeys {
    Param(
        [String] $Comment = (Get-Culture).TextInfo.ToTitleCase($env:COMPUTERNAME.ToLower())
    )
    Bash -c "ssh-keygen -t rsa -b 4096 -C '$Comment'"
}

Function Get-SshPublicKey {
    Bash -c "cat ~/.ssh/id_rsa.pub"
}
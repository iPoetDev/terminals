if (Get-Module 'npm-upgrade') {
	return
}

<#
.SYNOPSIS
Upgrade npm.

.DESCRIPTION
Upgrade npm to latest version.

.EXAMPLE
Update-NPM
#>
function Update-NPM {
	# Check npm command
	if (-not ([bool](Get-Command 'npm' -ErrorAction SilentlyContinue))) {
		Write-Error -Message 'npm not found.' -Category ObjectNotFound

		return
	}

	$cwd = Get-Location
	$npmTempPath = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP 'npm-selfupdate'))
	$nodePath = $null

	# Find Node.js path
	if (
		($null -ne $env:ProgramFiles) -and
		(Test-Path (Join-Path $env:ProgramFiles 'nodejs'))
	) {
		$nodePath = Join-Path $env:ProgramFiles 'nodejs'
	} elseif (
		($null -ne ${env:ProgramFiles(x86)}) -and
		(Test-Path (Join-Path ${env:ProgramFiles(x86)} 'nodejs'))
	) {
		$nodePath = Join-Path ${env:ProgramFiles(x86)} 'nodejs'
	}

	# npmrc path
	$npmrcPath = Join-Path $nodePath 'node_modules/npm/npmrc'

	# Create temporary path for storing files from current npm
	if (Test-Path $npmTempPath) {
		Remove-Item -Path $npmTempPath -Recurse -Force
	}
	New-Item -Path $npmTempPath -ItemType Directory | Out-Null

	# Backup npmrc
	$backupNpmrcPath = (Join-Path $npmTempPath 'npmrc')
	if (Test-Path $npmrcPath) {
		Copy-Item -Path $npmrcPath -Destination $backupNpmrcPath -Force
	}

	# Upgrade npm (and corepack if exist)
	$hasCorepack = [bool](Get-Command 'corepack' -ErrorAction SilentlyContinue)
	Set-Location $nodePath
	if ($hasCorepack) {
		Write-Host -Object 'Upgrading npm and corepack...' -ForegroundColor Yellow
		npm install npm@latest corepack@latest --progress --loglevel error
	} else {
		Write-Host -Object 'Upgrading npm...' -ForegroundColor Yellow
		npm install npm@latest --progress --loglevel error
	}

	# Remove generated package-lock.json
	Remove-Item -Path (Join-Path $nodePath 'package-lock.json') -Force -ErrorAction SilentlyContinue

	# Restore npmrc
	Copy-Item -Path $backupNpmrcPath -Destination $npmrcPath -Force

	# Clear temporary files
	Remove-Item -Path $npmTempPath -Recurse -Force -ErrorAction SilentlyContinue

	# Finish
	Set-Location $cwd
	if ($hasCorepack) {
		Write-Host -Object 'npm and corepack upgraded.' -ForegroundColor Green
	} else {
		Write-Host -Object 'npm upgraded.' -ForegroundColor Green
	}
}

New-Alias -Name 'Upgrade-NPM' -Value 'Update-NPM' -Option ReadOnly
New-Alias -Name 'npmu' -Value 'Update-NPM' -Option ReadOnly

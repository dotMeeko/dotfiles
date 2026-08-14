<#
.SYNOPSIS
    Sets up midgard (Windows 11): packages via WinGet, dotfiles via chezmoi.

.DESCRIPTION
    Run once on a new machine, from an elevated PowerShell:

        irm https://raw.githubusercontent.com/<user>/<repo>/main/windows/bootstrap.ps1 | iex

    or, from a clone:

        .\windows\bootstrap.ps1

    Order matters. Developer Mode is enabled by the WinGet configuration before
    chezmoi runs, because chezmoi cannot create symlinks on Windows without it.
    The same configuration renames the machine to midgard, which needs a reboot
    to take effect.

.NOTES
    Requires Windows 11 with App Installer (WinGet) present — it ships with the
    OS. Everything else is installed from here.
#>

[CmdletBinding()]
param(
    # Where the dotfiles live. Override when testing a fork.
    [string]$RepoUrl = "https://github.com/dotMeeko/nixos.git",

    # Skip the package step and only apply dotfiles.
    [switch]$DotfilesOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "warning: $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "error: $Message" -ForegroundColor Red; exit 1 }

# --- Preflight ---------------------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Fail "run this from an elevated PowerShell — enabling Developer Mode needs it"
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail @"
winget not found. It ships with Windows 11 as part of App Installer.
Install it from the Microsoft Store ('App Installer'), then run this again.
"@
}

# The DSC v3 schema used by windows/configuration.winget needs WinGet 1.11+.
$wingetVersion = (winget --version) -replace '^v', ''
Write-Step "winget $wingetVersion"

try {
    $parsed = [version]($wingetVersion -split '-')[0]
    if ($parsed -lt [version]"1.11") {
        Write-Warn "winget $wingetVersion is older than 1.11 — the dscv3 processor may be unavailable"
        Write-Warn "update App Installer from the Microsoft Store if 'winget configure' fails"
    }
} catch {
    Write-Warn "could not parse the winget version; continuing"
}

$configFile = Join-Path $PSScriptRoot "configuration.winget"

# --- Packages ----------------------------------------------------------------

if (-not $DotfilesOnly) {
    if (-not (Test-Path $configFile)) {
        Write-Fail "configuration.winget not found at $configFile"
    }

    Write-Step "Installing packages and enabling Developer Mode"
    Write-Host "  this takes a while — each package is roughly 10-15s" -ForegroundColor DarkGray

    # --disable-interactivity keeps it unattended; without the agreements flag
    # it stops on a prompt.
    winget configure --file $configFile `
        --accept-configuration-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "winget configure failed with exit code $LASTEXITCODE"
    }
}

# --- Dotfiles ----------------------------------------------------------------

# chezmoi was just installed; PATH in this session predates it.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    Write-Fail "chezmoi is still not on PATH — open a new shell and re-run with -DotfilesOnly"
}

Write-Step "Applying dotfiles"

# The repo root holds a .chezmoiroot file containing "chezmoi", so chezmoi
# reads its source state from the chezmoi/ subdirectory. That is what lets the
# NixOS config and the dotfiles live in one repository.
if (Test-Path (Join-Path $env:USERPROFILE ".local\share\chezmoi")) {
    Write-Host "  chezmoi is already initialised — updating" -ForegroundColor DarkGray
    chezmoi update --apply
} else {
    chezmoi init --apply $RepoUrl
}

if ($LASTEXITCODE -ne 0) {
    Write-Fail "chezmoi failed with exit code $LASTEXITCODE"
}

# --- Done --------------------------------------------------------------------

Write-Host ""
Write-Step "Done."
Write-Host @"

Open a new terminal for PATH changes to take effect.

  chezmoi diff      what would change
  chezmoi apply     apply it
  chezmoi edit      edit a dotfile at its source

"@

if ($env:COMPUTERNAME -ne "midgard") {
    Write-Warn "this machine is still named '$env:COMPUTERNAME' — reboot to become 'midgard'"
}

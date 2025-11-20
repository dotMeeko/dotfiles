# Windows dotfiles installer
# This script runs Dotbot to install dotfiles on Windows

param()

$ErrorActionPreference = 'Stop'

$BASEDIR = $PSScriptRoot
$DOTBOT_DIR = Join-Path (Join-Path $BASEDIR "core") "dotbot"
$CONFIG = "install.conf.windows.yaml"

Write-Host "Installing dotfiles for Windows..." -ForegroundColor Cyan
Write-Host ""

# Check if dotbot submodule exists
if (-not (Test-Path (Join-Path $DOTBOT_DIR "bin" "dotbot"))) {
    Write-Host "Initializing Dotbot submodule..." -ForegroundColor Yellow

    try {
        Set-Location $BASEDIR
        & git submodule update --init --recursive "$DOTBOT_DIR"
        Write-Host "[OK] Dotbot submodule initialized" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to initialize Dotbot submodule" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
}

# Check if Python is available
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Python is not available" -ForegroundColor Red
    Write-Host "  Please install Python 3.8+ first" -ForegroundColor Yellow
    Write-Host "  Run: irm https://raw.githubusercontent.com/dotMeeko/dotfiles/main/installer/windows.ps1 | iex" -ForegroundColor Cyan
    exit 1
}

# Check if config file exists
$configPath = Join-Path $BASEDIR $CONFIG
if (-not (Test-Path $configPath)) {
    Write-Host "[ERROR] Configuration file not found: $CONFIG" -ForegroundColor Red
    exit 1
}

Write-Host "Running Dotbot with configuration: $CONFIG" -ForegroundColor Cyan
Write-Host ""

# Run Dotbot
try {
    $dotbotBin = Join-Path $DOTBOT_DIR "bin" "dotbot"

    & python "$dotbotBin" -d "$BASEDIR" -c "$configPath"

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Dotfiles installed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "[ERROR] Dotbot returned exit code: $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Failed to run Dotbot" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

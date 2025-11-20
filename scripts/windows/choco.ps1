<#
.SYNOPSIS
    Install or update applications via Chocolatey
.DESCRIPTION
    Installs packages not available in winget using Chocolatey package manager
.PARAMETER UpdateOnly
    Only update already installed packages, don't install new ones
.EXAMPLE
    .\choco.ps1
    Installs all packages
.EXAMPLE
    .\choco.ps1 -UpdateOnly
    Updates all packages without installing new ones
.NOTES
    Author: Meeko
    Requires: Administrator privileges
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(HelpMessage = "Only update already installed packages")]
    [switch]$UpdateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helper Functions

function Write-Step {
    param([string]$Message)
    Write-Host "==>" -ForegroundColor Cyan -NoNewline
    Write-Host " $Message" -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "V" -ForegroundColor Green -NoNewline
    Write-Host " $Message" -ForegroundColor White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "!" -ForegroundColor Yellow -NoNewline
    Write-Host " $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "X" -ForegroundColor Red -NoNewline
    Write-Host " $Message" -ForegroundColor Red
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Chocolatey {
    Write-Step "Installing Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        refreshenv

        Write-Success "Chocolatey installed successfully"
        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-ErrorMsg "Failed to install Chocolatey: $errorMessage"
        return $false
    }
}

function Install-ChocoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "Chocolatey package ID")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId,

        [Parameter(Mandatory, HelpMessage = "Display name for user feedback")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(HelpMessage = "Update package instead of installing")]
        [switch]$Update
    )

    begin {
        if ($Update) {
            Write-Step "Updating $DisplayName..."
            $command = "upgrade"
        } else {
            Write-Step "Installing $DisplayName..."
            $command = "install"
        }
    }

    process {
        try {
            $result = choco $command $PackageId -y 2>&1
            $resultString = $result -join "`n"

            $isSuccess = $false
            if ($LASTEXITCODE -eq 0) {
                $isSuccess = $true
            }
            if ($resultString -match "installed") {
                $isSuccess = $true
            }
            if ($resultString -match "upgraded") {
                $isSuccess = $true
            }
            if ($resultString -match "already installed") {
                $isSuccess = $true
            }
            if ($resultString -match "is the latest version available") {
                $isSuccess = $true
            }

            if ($isSuccess) {
                $isAlreadyUpToDate = $false
                if ($resultString -match "already installed") {
                    $isAlreadyUpToDate = $true
                }
                if ($resultString -match "is the latest version available") {
                    $isAlreadyUpToDate = $true
                }

                if ($isAlreadyUpToDate) {
                    Write-Success "$DisplayName is already up to date"
                } else {
                    Write-Success "$DisplayName completed successfully"
                }
                return $true
            } else {
                Write-Warning "$DisplayName returned code: $LASTEXITCODE"
                return $false
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-ErrorMsg "Failed: $errorMessage"
            Write-Verbose "Stack trace: $($_.ScriptStackTrace)"
            return $false
        }
    }
}

#endregion

#region Main

try {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  Chocolatey Package Installer         " -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # Check Administrator
    if (-not (Test-Administrator)) {
        Write-ErrorMsg "This script requires Administrator privileges"
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Running as Administrator"
    Write-Host ""

    # Check or Install Chocolatey
    if (-not (Test-CommandExists "choco")) {
        if (-not (Install-Chocolatey)) {
            exit 1
        }
        Write-Host ""
    } else {
        Write-Success "Chocolatey is available"
        Write-Host ""
    }

    # Packages to install
    Write-Host "Chocolatey Packages:" -ForegroundColor Cyan
    Write-Host ""

    $packages = @(
        @{ Id = "nerd-fonts-hack"; Name = "Hack Nerd Font" }
        @{ Id = "nerd-fonts-firacode"; Name = "FiraCode Nerd Font" }
        @{ Id = "nerd-fonts-jetbrainsmono"; Name = "JetBrainsMono Nerd Font" }
        @{ Id = "windhawk"; Name = "Windhawk" }
    )

    $failed = @()
    foreach ($pkg in $packages) {
        $success = Install-ChocoPackage -PackageId $pkg.Id -DisplayName $pkg.Name -Update:$UpdateOnly
        if (-not $success) {
            $failed += $pkg.Name
        }
    }

    Write-Host ""

    # Summary
    Write-Host "========================================" -ForegroundColor Green
    if ($UpdateOnly) {
        Write-Host "  Update completed!                     " -ForegroundColor Green
    } else {
        Write-Host "  Installation completed!               " -ForegroundColor Green
    }
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    if ($failed.Count -gt 0) {
        Write-Warning "Failed packages: $($failed -join ', ')"
        Write-Host ""
    }

    Write-Host "Fonts installed! You may need to restart applications to see new fonts." -ForegroundColor Cyan
    Write-Host ""

}
catch {
    Write-Host ""
    $errorMessage = $_.Exception.Message
    Write-ErrorMsg "Script failed: $errorMessage"
    exit 1
}

#endregion

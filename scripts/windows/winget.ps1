<#
.SYNOPSIS
    Install or update applications via winget
.DESCRIPTION
    Installs development tools and applications using Windows Package Manager (winget)
.PARAMETER UpdateOnly
    Only update already installed packages, don't install new ones
.PARAMETER SkipOptional
    Skip installation of optional development tools
.EXAMPLE
    .\winget.ps1
    Installs all essential and optional tools
.EXAMPLE
    .\winget.ps1 -SkipOptional
    Installs only essential tools
.EXAMPLE
    .\winget.ps1 -UpdateOnly
    Updates all tools without installing new ones
.NOTES
    Author: Meeko
    Requires: winget (Windows Package Manager)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(HelpMessage = "Only update already installed packages")]
    [switch]$UpdateOnly,

    [Parameter(HelpMessage = "Skip installation of optional development tools")]
    [switch]$SkipOptional
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
    Write-Host "✓" -ForegroundColor Green -NoNewline
    Write-Host " $Message" -ForegroundColor White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠" -ForegroundColor Yellow -NoNewline
    Write-Host " $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗" -ForegroundColor Red -NoNewline
    Write-Host " $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "Winget package ID")]
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
            $result = winget $command --id $PackageId --silent --accept-package-agreements --accept-source-agreements 2>&1
            $resultString = $result -join "`n"

            $isSuccess = $false
            if ($LASTEXITCODE -eq 0) {
                $isSuccess = $true
            }
            if ($resultString -match "successfully installed") {
                $isSuccess = $true
            }
            if ($resultString -match "successfully upgraded") {
                $isSuccess = $true
            }
            if ($resultString -match "already installed") {
                $isSuccess = $true
            }
            if ($resultString -match "No available upgrade found") {
                $isSuccess = $true
            }
            if ($resultString -match "Found an existing package already installed") {
                $isSuccess = $true
            }

            if ($isSuccess) {
                $isAlreadyUpToDate = $false
                if ($resultString -match "already installed") {
                    $isAlreadyUpToDate = $true
                }
                if ($resultString -match "No available upgrade") {
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
            Write-ErrorMsg "Failed: $($_.Exception.Message)"
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
    Write-Host "  Windows Application Installer         " -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # Check winget
    if (-not (Test-CommandExists "winget")) {
        Write-ErrorMsg "winget is not available"
        Write-Host "Install from: https://aka.ms/getwinget" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "winget is available"
    Write-Host ""

    # Essential tools
    Write-Host "Essential Development Tools:" -ForegroundColor Cyan
    Write-Host ""

    $essentialTools = @(
        @{ Id = "Git.Git"; Name = "Git" }
    )

    $failedEssential = @()
    foreach ($tool in $essentialTools) {
        $success = Install-WingetPackage -PackageId $tool.Id -DisplayName $tool.Name -Update:$UpdateOnly
        if (-not $success) {
            $failedEssential += $tool.Name
        }
    }

    Write-Host ""

    # Optional tools
    if (-not $SkipOptional) {
        Write-Host "Optional Development Tools:" -ForegroundColor Cyan
        Write-Host ""

        $optionalTools = @(
            @{ Id = "Python.Python.3.13"; Name = "Python 3.13" }
        )

        $failedOptional = @()
        foreach ($tool in $optionalTools) {
            $success = Install-WingetPackage -PackageId $tool.Id -DisplayName $tool.Name -Update:$UpdateOnly
            if (-not $success) {
                $failedOptional += $tool.Name
            }
        }

        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Green
    if ($UpdateOnly) {
        Write-Host "  Update completed!                     " -ForegroundColor Green
    } else {
        Write-Host "  Installation completed!               " -ForegroundColor Green
    }
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    if ($failedEssential.Count -gt 0) {
        Write-Warning "Failed essential tools: $($failedEssential -join ', ')"
        Write-Host ""
    }

    if (-not $SkipOptional) {
        if ($failedOptional.Count -gt 0) {
            Write-Host "Failed optional tools: $($failedOptional -join ', ')" -ForegroundColor Gray
            Write-Host ""
        }
    }

    Write-Host "Restart your terminal to use newly installed tools" -ForegroundColor Cyan
    Write-Host ""

}
catch {
    Write-Host ""
    Write-ErrorMsg "Script failed: $($_.Exception.Message)"
    exit 1
}

#endregion

<#
.SYNOPSIS
    Windows dotfiles installer for @dotMeeko/dotfiles
.DESCRIPTION
    Automatically installs essential dependencies (Python, Git) and enables Developer Mode for symbolic links
    Usage: irm https://raw.githubusercontent.com/dotMeeko/dotfiles/main/installer/windows.ps1 | iex
.NOTES
    Author: Meeko
    Requires: PowerShell 5.1+ and Administrator privileges
#>

[CmdletBinding()]
param()

# Strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Administrator Privileges Required     " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This installer needs Administrator privileges to:" -ForegroundColor White
    Write-Host "  • Install Python and Git via winget" -ForegroundColor Gray
    Write-Host "  • Enable Developer Mode for symbolic links" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please restart PowerShell as Administrator and run:" -ForegroundColor Yellow
    Write-Host "  irm https://raw.githubusercontent.com/dotMeeko/dotfiles/main/installer/windows.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or right-click PowerShell → Run as Administrator" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#region Helper Functions

function Write-Banner {
    Write-Host @'
+-------------------------------------------------------+
| $$\      $$\                     $$\                  |
| $$$\    $$$ |                    $$ |                 |
| $$$$\  $$$$ | $$$$$$\   $$$$$$\  $$ |  $$\  $$$$$$\   |
| $$\$$\$$ $$ |$$  __$$\ $$  __$$\ $$ | $$  |$$  __$$\  |
| $$ \$$$  $$ |$$$$$$$$ |$$$$$$$$ |$$$$$$  / $$ /  $$ | |
| $$ |\$  /$$ |$$   ____|$$   ____|$$  _$$<  $$ |  $$ | |
| $$ | \_/ $$ |\$$$$$$$\ \$$$$$$$\ $$ | \$$\ \$$$$$$  | |
| \__|     \__| \_______| \_______|\__|  \__| \______/  |
|                                                       |
|                  @dotMeeko/dotfiles                   |
+-------------------------------------------------------+
'@ -ForegroundColor Magenta
    Write-Host ""
}

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

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Package {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )

    Write-Step "Installing $DisplayName..."

    try {
        $result = winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements 2>&1
        $resultString = $result -join "`n"

        # Check for success indicators
        if ($LASTEXITCODE -eq 0 -or
            $resultString -match "successfully installed" -or
            $resultString -match "already installed" -or
            $resultString -match "No available upgrade found" -or
            $resultString -match "Found an existing package already installed") {

            if ($resultString -match "already installed" -or $resultString -match "Found an existing package") {
                Write-Success "$DisplayName is already installed"
            } else {
                Write-Success "$DisplayName installed successfully"
            }
            return $true
        } else {
            Write-Warning "$DisplayName installation returned code: $LASTEXITCODE"
            Write-Host "  This may not be an error if the package is already installed" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-ErrorMsg "Failed to install $DisplayName : $_"
        return $false
    }
}

function Update-EnvironmentPath {
    Write-Step "Refreshing environment PATH..."

    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"

    Write-Success "PATH refreshed"
}

function Enable-DeveloperMode {
    Write-Step "Enabling Developer Mode for symbolic link support..."

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"

    try {
        # Create registry key if it doesn't exist
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        # Set Developer Mode
        Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
        Write-Success "Developer Mode enabled"
        Write-Host "  Symbolic links can now be created without Administrator privileges" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-ErrorMsg "Failed to enable Developer Mode"
        Write-Host "  This is CRITICAL - dotbot cannot create symbolic links without it" -ForegroundColor Red
        Write-Host "  Manual steps: Settings → Update & Security → For developers → Developer Mode" -ForegroundColor Yellow
        return $false
    }
}

function Test-CriticalDependencies {
    Write-Step "Verifying critical dependencies..."
    Write-Host ""

    $allGood = $true
    $missingDeps = @()

    # Check Python
    if (Test-CommandExists "python") {
        Write-Success "Python is available"

        # Verify Python version (with retry for freshly installed Python)
        $pythonVersion = $null
        $maxRetries = 3

        for ($i = 0; $i -lt $maxRetries; $i++) {
            try {
                $pythonVersion = python --version 2>&1
                if ($pythonVersion) {
                    break
                }
            }
            catch {
                if ($i -lt $maxRetries - 1) {
                    Start-Sleep -Milliseconds 500
                }
            }
        }

        if ($pythonVersion -and $pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]

            if (($major -eq 3 -and $minor -ge 8) -or ($major -gt 3)) {
                Write-Host "  Version: $pythonVersion" -ForegroundColor Gray
            } else {
                Write-ErrorMsg "Python version is too old: $pythonVersion (need 3.8+)"
                $allGood = $false
                $missingDeps += "Python 3.8+"
            }
        } else {
            Write-Warning "Could not verify Python version (command available but no output)"
            Write-Host "  Python command exists, assuming installation is correct" -ForegroundColor Gray
        }
    } else {
        Write-ErrorMsg "Python is not available"
        $allGood = $false
        $missingDeps += "Python 3.8+"
    }

    # Check Git
    if (Test-CommandExists "git") {
        Write-Success "Git is available"

        try {
            $gitVersion = git --version 2>&1
            Write-Host "  Version: $gitVersion" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Could not verify Git version"
        }
    } else {
        Write-ErrorMsg "Git is not available"
        $allGood = $false
        $missingDeps += "Git"
    }

    # Check Developer Mode
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    try {
        $devMode = Get-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
        if ($devMode.AllowDevelopmentWithoutDevLicense -eq 1) {
            Write-Success "Developer Mode is enabled"
        } else {
            Write-ErrorMsg "Developer Mode is not enabled"
            $allGood = $false
            $missingDeps += "Developer Mode"
        }
    }
    catch {
        Write-ErrorMsg "Developer Mode is not enabled"
        $allGood = $false
        $missingDeps += "Developer Mode"
    }

    Write-Host ""

    if (-not $allGood) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  CRITICAL DEPENDENCIES MISSING!        " -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "The following critical dependencies are missing:" -ForegroundColor Red
        foreach ($dep in $missingDeps) {
            Write-Host "  ✗ $dep" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Dotbot will NOT work without these dependencies!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install missing dependencies manually:" -ForegroundColor Yellow

        if ($missingDeps -contains "Python 3.8+") {
            Write-Host "  - Python: https://www.python.org/downloads/" -ForegroundColor Yellow
            Write-Host "    Or run: winget install Python.Python.3.13" -ForegroundColor Cyan
        }

        if ($missingDeps -contains "Git") {
            Write-Host "  - Git: https://git-scm.com/download/win" -ForegroundColor Yellow
            Write-Host "    Or run: winget install Git.Git" -ForegroundColor Cyan
        }

        if ($missingDeps -contains "Developer Mode") {
            Write-Host "  - Developer Mode: Settings → Update & Security → For developers" -ForegroundColor Yellow
        }

        Write-Host ""
        return $false
    }

    Write-Success "All critical dependencies are available"
    return $true
}

#endregion

#region Main Installation

try {
    Clear-Host
    Write-Banner

    # Check administrator privileges
    Write-Step "Checking administrator privileges..."
    if (-not (Test-Administrator)) {
        Write-ErrorMsg "This script requires Administrator privileges"
        Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Running with Administrator privileges"
    Write-Host ""

    # Check winget availability
    Write-Step "Checking winget availability..."
    if (-not (Test-CommandExists "winget")) {
        Write-ErrorMsg "winget is not available"
        Write-Host "Please install winget from: https://aka.ms/getwinget" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "winget is available"
    Write-Host ""

    # Install essential dependencies
    Write-Step "Installing essential dependencies..."
    Write-Host ""

    $dependencies = @(
        @{ Id = "Git.Git"; Name = "Git" },
        @{ Id = "Python.Python.3.13"; Name = "Python 3.13" }
    )

    $failedPackages = @()
    foreach ($dep in $dependencies) {
        $success = Install-Package -PackageId $dep.Id -DisplayName $dep.Name
        if (-not $success) {
            $failedPackages += $dep.Name
        }
    }

    Write-Host ""

    if ($failedPackages.Count -gt 0) {
        Write-Warning "Some packages failed to install: $($failedPackages -join ', ')"
        Write-Host "You may need to install them manually" -ForegroundColor Yellow
        Write-Host ""
    }

    # Update PATH to include newly installed tools
    Update-EnvironmentPath
    Write-Host ""

    # Enable Developer Mode (CRITICAL - exit if fails)
    $devModeSuccess = Enable-DeveloperMode
    Write-Host ""

    if (-not $devModeSuccess) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  CRITICAL ERROR: Developer Mode       " -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Cannot continue without Developer Mode enabled." -ForegroundColor Red
        Write-Host "Dotbot requires symbolic link permissions to work." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please enable Developer Mode manually and run this script again:" -ForegroundColor Yellow
        Write-Host "  Settings → Update & Security → For developers → Developer Mode" -ForegroundColor Cyan
        Write-Host ""
        exit 1
    }

    # FINAL VERIFICATION - Check all critical dependencies are actually available
    if (-not (Test-CriticalDependencies)) {
        Write-Host ""
        exit 1
    }

    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Installation completed successfully!  " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All dependencies verified and ready:" -ForegroundColor Cyan
    Write-Host "  ✓ Git" -ForegroundColor White
    Write-Host "  ✓ Python 3.8+" -ForegroundColor White
    Write-Host "  ✓ Developer Mode (symbolic links)" -ForegroundColor White
    Write-Host ""
    # Enable script execution for CurrentUser
    Write-Host ""
    Write-Step "Configuring PowerShell execution policy..."

    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
            Write-Success "PowerShell execution policy set to RemoteSigned"
            Write-Host "  Scripts can now run without blocking" -ForegroundColor Gray
        } else {
            Write-Success "PowerShell execution policy already configured ($currentPolicy)"
        }
    }
    catch {
        Write-Warning "Could not set execution policy automatically"
        Write-Host "  You may need to run manually: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart your terminal to load new PATH" -ForegroundColor White
    Write-Host "  2. Clone dotfiles: " -ForegroundColor White -NoNewline
    Write-Host "git clone --recurse-submodules https://github.com/dotMeeko/dotfiles.git" -ForegroundColor Yellow
    Write-Host "  3. Run installer: " -ForegroundColor White -NoNewline
    Write-Host "cd dotfiles && .\install.ps1" -ForegroundColor Yellow
    Write-Host ""

}
catch {
    Write-Host ""
    Write-ErrorMsg "Installation failed with error:"
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion

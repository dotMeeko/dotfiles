# Windows Installation Guide

Complete guide for setting up dotfiles on Windows.

## Prerequisites

- Windows 11
- Administrator privileges

## Installation Steps

### 1. Install Dependencies

Run in PowerShell as Administrator:

```powershell
irm https://raw.githubusercontent.com/dotMeeko/dotfiles/main/installer/windows.ps1 | iex
```

This installs:
- Git
- Python 3.8+
- Developer Mode (for symbolic links)
- PowerShell execution policy configuration

**Note:** Restart your terminal after installation to load new PATH.

### 2. Clone and Install Dotfiles

```powershell
git clone --recurse-submodules https://github.com/dotMeeko/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
.\install.ps1
```

This will:
- Create symbolic links for configuration files
- Configure Git settings (CRLF, editor)
- Set up directory structure

### 3. Install Applications (Optional)

Install development tools via winget:

```powershell
.\scripts\windows\winget.ps1
```

**Usage examples:**

```powershell
# Install only essential tools
.\scripts\windows\winget.ps1 -SkipOptional

# Update already installed packages
.\scripts\windows\winget.ps1 -UpdateOnly

# Get help
Get-Help .\scripts\windows\winget.ps1 -Full
```

## Updating Dotfiles

```powershell
cd ~/.dotfiles
git pull
.\install.ps1
```

## Troubleshooting

| Problem                           | Solution                                                                                                                                                                     |
|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Symbolic Links Not Working**    | Enable Developer Mode:<br>Settings → Update & Security → For developers → Developer Mode                                                                                     |
| **Script Execution Blocked**      | Set execution policy:<br>`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`                                                                                               |
| **Winget Not Available**          | Install "App Installer" from Microsoft Store<br>Or download: https://aka.ms/getwinget                                                                                        |
| **Git Submodule Not Initialized** | `git submodule update --init --recursive`                                                                                                                                    |
| **PATH Not Updated**              | Restart terminal or run:<br>`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")` |

## Manual Installation

If automatic installation fails, install dependencies manually:

1. **Git**: https://git-scm.com/download/win
2. **Python 3.8+**: https://www.python.org/downloads/
3. **Enable Developer Mode**: Settings → Update & Security → For developers

Then proceed with step 2 (Clone and Install Dotfiles).

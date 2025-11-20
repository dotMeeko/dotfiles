# PowerShell Profile Configuration
# Author: Meeko
# Location: $PROFILE

# Clear PowerShell banner
Clear-Host

#region Environment Setup

# Set dotfiles path
$DOTFILES = "$HOME\.dotfiles"

# Starship prompt
$ENV:STARSHIP_CONFIG = "$DOTFILES\config\starship\starship.toml"

#endregion

#region Prompt

# Initialize Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

#endregion

#region Aliases

# Navigation
Set-Alias -Name .. -Value Set-LocationUp
function Set-LocationUp { Set-Location .. }

# Git shortcuts
function gs { git status }
function ga { git add $args }
function gc { git commit -m $args }
function gp { git push }
function gl { git pull }
function gd { git diff }
function gco { git checkout $args }

# Quick dotfiles access
function dotfiles { Set-Location $DOTFILES }

# List files with colors
function ll { Get-ChildItem $args | Format-Table -AutoSize }
function la { Get-ChildItem -Force $args | Format-Table -AutoSize }

#endregion

#region Helper Functions

# Reload profile
function Reload-Profile {
    . $PROFILE
    Write-Host "Profile reloaded!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

# Edit profile
function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $PROFILE
    } else {
        notepad $PROFILE
    }
}
Set-Alias -Name editprofile -Value Edit-Profile

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Display system info on startup
function Show-SystemInfo {
    $isAdmin = Test-Administrator
    $currentUser = [System.Environment]::UserName
    $roleText = if ($isAdmin) { "root" } else { $currentUser }

    Write-Host ""
    Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "Running as: $roleText" -ForegroundColor $(if ($isAdmin) { "Red" } else { "Green" })
    Write-Host "Dotfiles: $DOTFILES" -ForegroundColor Magenta
    Write-Host ""
}

#endregion

#region Startup

# Show system info on shell start
Show-SystemInfo

#endregion

# Microsoft.PowerShell_profile.ps1 — managed by chezmoi (Windows, PowerShell 7).
# Deployed to %USERPROFILE%\Documents\PowerShell\. Portable, no Nix.

# Aliases
Set-Alias ll Get-ChildItem

function gs { git status @args }
function ca { chezmoi apply @args }

# Simple prompt showing the current path
function prompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }

# Better history search if PSReadLine is available
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
}

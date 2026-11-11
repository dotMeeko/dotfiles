# Microsoft.PowerShell_profile.ps1 — managed by dotter (Windows, PowerShell 7).
# Deployed to %USERPROFILE%\Documents\PowerShell\. Portable, no Nix.

# Aliases
Set-Alias ll Get-ChildItem

function gs { git status @args }
# Deploy the dotfiles. dotter reads .dotter/global.toml relative to the current
# directory, so it has to run from the repo root — hence the push/pop.
$DotfilesRepo = Join-Path $HOME "{{dotfiles_repo}}"
function dot {
    Push-Location $DotfilesRepo
    try { dotter @args } finally { Pop-Location }
}

# Simple prompt showing the current path
function prompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }

# Better history search if PSReadLine is available
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
}

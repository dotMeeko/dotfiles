# PowerShell profile — managed by chezmoi, edit the source not this file.
#
# This lives at ~/.config/powershell/profile.ps1 rather than in Documents,
# because Windows redirects Documents into OneDrive on many machines and the
# real $PROFILE path moves with it. run_onchange_windows-link-profile.ps1
# dot-sources this file from whatever $PROFILE actually is.
#
# Mirrors the zsh setup on NixOS and macOS: same prompt, same aliases, so
# muscle memory carries across machines.

# --- Prompt ------------------------------------------------------------------
# starship.toml is shared with every other machine and chezmoi puts it in the
# same place on all platforms, so no STARSHIP_CONFIG override is needed.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# --- Tools -------------------------------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- Aliases -----------------------------------------------------------------
# Same names as the zsh side.

function ll { eza -lah --icons --group-directories-first @args }
function la { eza -a --icons --group-directories-first @args }
function lt { eza --tree --icons @args }

# Git. `gc` and `gp` are deliberately NOT used: they collide with PowerShell's
# built-in Get-Content and Get-ItemProperty aliases, and shadowing those breaks
# other scripts.
function gs { git status --short --branch @args }
function ga { git add @args }
function gcm { git commit -m @args }
function gd { git diff @args }
function gds { git diff --staged @args }
function gl { git log --oneline --graph --decorate -20 @args }
function gco { git checkout @args }
function gpush { git push @args }
function gpull { git pull @args }

# Dotfiles
function dots { chezmoi cd }
function dotsa { chezmoi apply }
function dotsd { chezmoi diff }

# --- Helpers -----------------------------------------------------------------

function Reload-Profile {
    . $PROFILE
    Write-Host "profile reloaded" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

function Edit-Profile {
    # Edits the chezmoi source, not the generated file.
    chezmoi edit ~/.config/powershell/profile.ps1
}
Set-Alias -Name editprofile -Value Edit-Profile

# --- Readline ----------------------------------------------------------------
# Bring PSReadLine closer to the zsh setup: history search on the arrow keys,
# inline suggestions from history.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

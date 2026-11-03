# packages.ps1 — Windows packages, the counterpart of nix/home/packages.nix (NixOS)
# and macos/Brewfile (macOS). chezmoi still owns every config; this file only installs
# software.
#
# Run:  pwsh -File windows\packages.ps1
#       pwsh -File windows\packages.ps1 -WhatIf     # show what would be installed
#
# winget covers everything here; scoop is not needed so far. IDs were checked against
# microsoft/winget-pkgs. `winget install` is idempotent — an already-installed package
# is reported as such and skipped.
[CmdletBinding(SupportsShouldProcess)]
param()

$packages = @(
    # CLI — same set as the other two OSes
    'Git.Git',
    'Neovim.Neovim',
    'twpayne.chezmoi',              # owns the dotfiles themselves
    'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd',
    'junegunn.fzf',
    'jqlang.jq',
    'Python.Python.3.13',
    'Microsoft.PowerShell',         # PowerShell 7; Windows ships 5.1, the profile targets 7

    # GUI
    'Zen-Team.Zen-Browser',         # same browser as on NixOS
    'Anthropic.ClaudeCode'
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from the Microsoft Store first."
}

foreach ($id in $packages) {
    if ($PSCmdlet.ShouldProcess($id, 'winget install')) {
        Write-Host "==> $id" -ForegroundColor Cyan
        # --exact so a prefix never matches a different package; the accept flags keep
        # the run non-interactive.
        winget install --id $id --exact --source winget `
            --accept-package-agreements --accept-source-agreements
    }
}

Write-Host ""
Write-Host "Done. Configs come separately: chezmoi init --apply dotMeeko/dotfiles" -ForegroundColor Green

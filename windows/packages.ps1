# packages.ps1 — Windows packages, the counterpart of nix/home/packages.nix (NixOS)
# and macos/Brewfile (macOS). dotter still owns every config; this file only installs
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
    'SuperCuber.Dotter',            # owns the dotfiles themselves
    'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd',
    'junegunn.fzf',
    'jqlang.jq',
    'Python.Python.3.13',
    'Microsoft.PowerShell',         # PowerShell 7; Windows ships 5.1, the profile targets 7

    # GUI
    'Zen-Team.Zen-Browser',         # same browser as on NixOS
    # GUI editor, same as on the other two OSes. Publisher is ZedIndustries, NOT
    # "Zed" — manifests/z/Zed does not exist in winget-pkgs. winget also carries a
    # "Preview" version under the same id, which is Zed's preview channel; the
    # numbered releases are the stable ones.
    'ZedIndustries.Zed',
    # Docker for development. Needs WSL2 present first — Desktop runs its engine
    # inside it; `wsl --install` if it is not there yet. winget also has
    # Docker.DockerCLI / Docker.DockerCompose as standalone pieces and
    # Docker.DockerDesktopEdge as the preview channel; this is the stable app.
    'Docker.DockerDesktop',
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
Write-Host "Done. Configs come separately: clone the repo, write .dotter\local.toml, run dotter" -ForegroundColor Green

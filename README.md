# Dotfiles

Personal dotfiles repository using [Dotbot](https://github.com/anishathalye/dotbot) for cross-platform configuration management.

## Quick Start

### Windows

**1. Install dependencies** (requires Administrator):

```powershell
irm https://raw.githubusercontent.com/dotMeeko/dotfiles/main/installer/windows.ps1 | iex
```

This installs:
- Python 3.*
- Git
- Developer Mode (for symbolic links)

**2. Clone and install dotfiles:**

```powershell
git clone --recurse-submodules https://github.com/dotMeeko/dotfiles.git
cd dotfiles
.\install.ps1
```
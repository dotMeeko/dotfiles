{ pkgs, ... }:

{
  # The shell, git and CLI tooling for bifrost.
  #
  # valhalla and midgard are not built from Nix, so they get the equivalent
  # from chezmoi: packages via chezmoi/.chezmoidata/packages.yaml, dotfiles via
  # chezmoi/dot_config/. Those lists are kept in sync with this file by hand —
  # the tools should feel the same on every machine.

  programs.home-manager.enable = true;

  # --- Git -------------------------------------------------------------------
  # Note: userName/userEmail/extraConfig were renamed; the current API is
  # programs.git.settings.<git-section>.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Meeko";
        email = "50156678+dotMeeko@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      # Reuse recorded conflict resolutions.
      rerere.enabled = true;
      alias = {
        s = "status --short --branch";
        l = "log --oneline --graph --decorate -20";
        d = "diff";
        ds = "diff --staged";
        la = "log --oneline --graph --all -20";
      };
    };
  };

  # --- Shell -----------------------------------------------------------------
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -lah --icons --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      tree = "eza --tree --icons";
      cat = "bat --paging=never";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Deliberately not configured here: the prompt is defined once in
    # chezmoi/dot_config/starship.toml and shared with Windows, where Nix does
    # not reach. See the note in home/starship.nix.
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # --- Packages --------------------------------------------------------------
  # The CLI set that should feel identical on every machine. Keep this in
  # intent-sync with chezmoi/.chezmoidata/packages.yaml, which covers the
  # machines Nix does not manage.
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    jq
    tree
    lazygit
    neovim
    mise # per-project runtime versions
    chezmoi # only used to push dotfiles to midgard from here
    claude-code # Anthropic CLI. Unfree — allowUnfree is set in configuration.nix
  ];
}

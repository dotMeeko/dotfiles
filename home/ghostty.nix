{ ... }:

{
  # Ghostty on bifrost. valhalla gets the same settings from
  # chezmoi/dot_config/ghostty/config instead — keep the two in sync by hand.
  #
  # Reference: https://ghostty.org/docs/config/reference
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;

      # Themes ship with ghostty (from iTerm2-Color-Schemes). Run
      # `ghostty +list-themes` to see what this build has, then set e.g.
      # theme = "catppuccin-mocha";
      background-opacity = 0.95;

      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = false; # niri draws its own borders

      cursor-style = "bar";
      mouse-hide-while-typing = true;

      # Ghostty confirms before closing a surface with a running process;
      # that prompt is noise on a tiling setup.
      confirm-close-surface = false;
    };
  };
}

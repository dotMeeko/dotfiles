{ config, ... }:

{
  # niri configuration in Nix. programs.niri.settings comes from niri-flake,
  # which is why that input exists — the nixpkgs module has enable/package only.
  #
  # This generates ~/.config/niri/config.kdl. Do not hand-edit that file; it is
  # a symlink into the store and gets overwritten on every rebuild.

  # --- DMS integration -------------------------------------------------------
  # The niri module's config block is gated on programs.dank-material-shell.
  # enable *within home-manager*, so it has to be enabled here too — the NixOS
  # module's enable is a separate option in a separate evaluation.
  programs.dank-material-shell = {
    enable = true;

    # The systemd user service is left to the NixOS module (modules/desktop.nix
    # sets systemd.enable). Both modules define a unit called `dms`, and
    # letting both create it would be a conflict.
    systemd.enable = false;

    niri = {
      # Adds the shell's own keybindings: Mod+Space launcher, Mod+V clipboard,
      # Mod+X power menu, media and brightness keys. enableKeybinds and
      # includes.enable are mutually exclusive by the module's own warning, so
      # includes stays off.
      enableKeybinds = true;

      # NOT enabled: this adds `dms run` to niri's spawn-at-startup, and the
      # systemd user service from modules/desktop.nix already starts it. Both
      # would launch a second copy of the shell. systemd wins here because it
      # restarts DMS if it crashes.
      enableSpawn = false;

      includes.enable = false;
    };
  };

  programs.niri.settings = {
    prefer-no-csd = true;

    input = {
      keyboard.xkb = {
        layout = "us,ru";
        options = "grp:alt_shift_toggle";
      };
      focus-follows-mouse.enable = true;
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    layout = {
      gaps = 8;
      border = {
        enable = true;
        width = 2;
      };
      # Widths cycled through with Mod+R.
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 1.0 / 2.0;
    };

    # Screenshots land here rather than in the home root.
    screenshot-path = "${config.home.homeDirectory}/Pictures/screenshots/%Y-%m-%d-%H%M%S.png";

    # Nothing here duplicates the DMS bindings — these are the compositor's own
    # window management keys.
    #
    # An action is an attrset with one key (its name) whose value is the
    # argument list; a single argument may be passed bare, and an action with
    # no arguments takes an empty list. Writing them as bare names — as if
    # `config.lib.niri.actions` exported every action as a value — fails with
    # "undefined variable", because only some are exposed that way.
    binds = {
      "Mod+T".action.spawn = "ghostty";
      "Mod+Q".action.close-window = [ ];
      "Mod+Shift+E".action.quit.skip-confirmation = true;

      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Down".action.focus-window-down = [ ];

      "Mod+H".action.focus-column-left = [ ];
      "Mod+L".action.focus-column-right = [ ];
      "Mod+K".action.focus-window-up = [ ];
      "Mod+J".action.focus-window-down = [ ];

      "Mod+Shift+H".action.move-column-left = [ ];
      "Mod+Shift+L".action.move-column-right = [ ];
      "Mod+Shift+K".action.move-window-up = [ ];
      "Mod+Shift+J".action.move-window-down = [ ];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;

      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+W".action.toggle-column-tabbed-display = [ ];
      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+Shift+Space".action.toggle-window-floating = [ ];

      "Print".action.screenshot = [ ];
      "Shift+Print".action.screenshot-window = [ ];
    };
  };
}

# home-manager wiring for the primary user (name comes from config.my.username).
# Niri config + DankMaterialShell integration live here (home-manager).
{ config, lib, inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.${config.my.username} = {
    imports = [
      # niri home-manager module is added automatically by niri.nixosModules.niri.
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
      ../home/packages.nix
    ];

    home.username = config.my.username;
    home.homeDirectory = "/home/${config.my.username}";
    home.stateVersion = "26.05";

    # config.kdl is hand-owned (chezmoi deploys it, see home/dot_config/niri/).
    # HM must not link it, or activation dies at checkLinkTargets and the whole
    # HM file layer silently stops applying.
    xdg.configFile."niri-config".enable = lib.mkForce false;

    # DankMaterialShell — preconfigured Quickshell desktop shell over Niri.
    # Wire keybinds + autostart directly (and disable the overlapping `includes`).
    programs.dank-material-shell = {
      enable = true;
      niri = {
        enableKeybinds = true;
        enableSpawn = true;
        includes.enable = false;
      };
    };
  };
}

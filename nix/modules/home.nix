# home-manager wiring for the primary user (name comes from config.my.username).
{ config, lib, inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.${config.my.username} = {
    imports = [
      # niri home-manager module is added automatically by niri.nixosModules.niri.
      ../home/packages.nix
    ];

    home.username = config.my.username;
    home.homeDirectory = "/home/${config.my.username}";
    home.stateVersion = "26.05";

    # config.kdl is hand-owned (dotter symlinks it, see linux/niri/ in the repo).
    # HM must not link it, or activation dies at checkLinkTargets and the whole
    # HM file layer silently stops applying. niri-flake still defines this entry
    # even now that nothing else wants to write the file, so the force stays.
    xdg.configFile."niri-config".enable = lib.mkForce false;
  };
}

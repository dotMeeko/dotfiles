{
  description = "Meeko cross-platform dotfiles — NixOS systems (Nix installs packages; chezmoi owns configs)";

  inputs = {
    # Stable base for the system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Unstable, exposed as pkgs.unstable for packages that must be fresh (e.g. Niri).
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      disko,
      ...
    }:
    let
      system = "x86_64-linux";
      # Expose the unstable package set as pkgs.unstable (hybrid stable + unstable).
      unstableOverlay = _final: _prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # Build a host by ROLE (the flake attribute = the role, NOT the machine name).
      # The machine name (networking.hostName) is a parameter, set at install time
      # into hosts/<role>/machine.nix — renaming a machine never touches this flake.
      mkHost =
        role:
        nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.overlays = [ unstableOverlay ]; }
            disko.nixosModules.disko
            ./hosts/${role}/default.nix
            ./hosts/${role}/disko.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.meeko = import ./home/packages.nix;
            }
          ];
        };
    in
    {
      # One entry per ROLE. Add `server = mkHost "server";` when a server exists.
      nixosConfigurations = {
        desktop = mkHost "desktop";
      };
    };
}

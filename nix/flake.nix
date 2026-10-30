{
  description = "Meeko cross-platform dotfiles — NixOS systems (Nix installs packages; chezmoi owns configs)";

  inputs = {
    # Stable base for the system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Unstable, exposed as pkgs.unstable for packages that must be fresh.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Niri compositor via niri-flake (nixos session + home-manager config/lib).
    niri.url = "github:sodiboo/niri-flake";
    # DankMaterialShell — Quickshell desktop shell over Niri (preconfigured).
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      disko,
      niri,
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
      # Machine name, user name and disk layout are parameters, set at install time
      # into hosts/<role>/{machine,user,disko}.nix — renaming never touches this flake.
      mkHost =
        role:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ unstableOverlay ]; }
            disko.nixosModules.disko
            niri.nixosModules.niri
            home-manager.nixosModules.home-manager
            ./modules/options.nix
            ./modules/home.nix
            ./hosts/${role}/default.nix
            ./hosts/${role}/disko.nix
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

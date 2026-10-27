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
    in
    {
      # Real host: the dual-boot PC (SSD #2 = NixOS).
      # Test it in QEMU with `nixos-rebuild build-vm .#desktop`.
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
          disko.nixosModules.disko
          ./hosts/desktop/default.nix
          ./hosts/desktop/disko.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.meeko = import ./home/packages.nix;
          }
        ];
      };
    };
}

{
  description = "bifrost — NixOS: niri + DankMaterialShell";

  # Only bifrost is built from Nix. valhalla (macOS) and midgard (Windows) are
  # handled by chezmoi + their native package managers — see chezmoi/ and
  # windows/.

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning — see modules/disko.nix.
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri-flake, not the nixpkgs module: it provides programs.niri.settings,
    # which is what lets niri be configured in Nix — and it is also the API the
    # DMS niri module builds its keybindings on. The nixpkgs module only has
    # enable/package. This flake disables the nixpkgs one to avoid a conflict.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The stable branch tracks tagged releases instead of bleeding-edge master.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, disko, niri, dms, ... }@inputs:
    let
      # Not hardcoded: scripts/install.sh writes this from what you type.
      user = import ./user.nix;
    in
    {
      nixosConfigurations.bifrost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          disko.nixosModules.disko
          ./modules/disko.nix
          ./modules/btrfs.nix
          ./modules/desktop.nix
          ./modules/nvidia.nix

          niri.nixosModules.niri
          dms.nixosModules.dank-material-shell

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.${user.username} = import ./home/bifrost.nix;
              # Move pre-existing dotfiles aside instead of failing the build.
              backupFileExtension = "hm-bak";
              # Both DMS home modules are needed:
              #   dank-material-shell — defines programs.dank-material-shell
              #                         itself, including .enable
              #   niri               — adds the .niri.* options used in
              #                         home/niri.nix, and its config block is
              #                         gated on that .enable
              # The nixos module covers the system side only; without these the
              # options in home/niri.nix are undefined.
              # (niri-flake adds its own home module automatically.)
              sharedModules = [
                dms.homeModules.dank-material-shell
                dms.homeModules.niri
              ];
            };
          }
        ];
      };
    };
}

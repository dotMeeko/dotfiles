{
  description = "bifrost — NixOS: niri + DankMaterialShell";

  # Only bifrost is built from Nix. valhalla (macOS) and midgard (Windows) are
  # handled by chezmoi + their native package managers — see chezmoi/ and
  # windows/.

  inputs = {
    # Stable release, not nixos-unstable: package versions are frozen and only
    # security and bug fixes land, so a `nix flake update` cannot pull in a
    # surprise. Bump this to the next release branch deliberately.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Must track the same release as nixpkgs. home-manager's master expects
    # unstable and will reference options a stable nixpkgs does not have.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
    #
    # NOTE: this flake is developed against nixos-unstable, and `follows` points
    # it at our stable nixpkgs instead. That is the usual arrangement, but if a
    # build ever fails on a missing attribute, dropping the follows line lets it
    # use its own unstable nixpkgs — at the cost of a second copy in the store.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The stable branch tracks tagged releases instead of bleeding-edge master.
    # Same caveat as niri above: upstream targets unstable.
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

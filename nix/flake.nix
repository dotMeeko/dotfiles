{
  description = "Meeko cross-platform dotfiles — NixOS systems (Nix installs packages; dotter owns configs)";

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
    # Noctalia Greeter — greetd login screen for the Noctalia shell.
    #
    # From the upstream flake, not nixpkgs: the pinned nixos-26.05 has no
    # noctalia-greeter module at all (checked — display-managers/ there ships
    # dms-greeter, gdm, sddm and friends, but not this one). Their module also
    # already carries the fix for the NixOS session-discovery bug, prefixing the
    # greetd command with XDG_DATA_DIRS, and it disables the nixpkgs copy of
    # itself so the two can never both apply.
    #
    # The shell itself needs no module — it is one binary plus its own TOML, and
    # comes from pkgs.unstable (see home/packages.nix) because nixpkgs-26.05 is
    # four minor versions behind.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Zen browser — not in nixpkgs; community flake. Package only (dotter owns configs).
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
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

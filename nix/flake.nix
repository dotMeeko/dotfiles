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
    # Dux Modular Shell (DMS) — Quickshell desktop shell over Niri.
    #
    # Formerly DankMaterialShell: the project moved to the Dux Labs org with 2.0
    # (2026-10-20) and `github:AvengeMedia/DankMaterialShell` is gone. The NAMES
    # inside did not move with it, and that mismatch is permanent — the flake
    # exposes `homeModules.dank-material-shell` and the options still live under
    # `programs.dank-material-shell`, with `dankMaterialShell` kept as a warning
    # alias. Checked against the stable branch, not assumed.
    #
    # The /stable branch on purpose: it tracks releases (currently 2.1.2,
    # 2026-11-08), while master is explicitly not recommended for daily use.
    #
    # NOT from nixpkgs: stable 26.05 pins `dms-shell` 1.4.6 and its
    # `programs.dms-shell` module is written for that 1.4.x line, while unstable
    # already ships `dux-shell` 2.1.2 — mixing the stable module with the
    # unstable package is version skew waiting to happen. The upstream flake
    # ships module and package as one piece.
    dux-shell = {
      url = "github:duxlabs-dev/dux-shell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Dux Greeter — greetd login screen in the DMS style (Material 3, theme-synced).
    #
    # Its own repo as of 2.x: the shell flake's `nixosModules.greeter` is now an
    # empty stub that only prints "the greeter moved to the dux-greeter repo".
    # The module here still defines `programs.dms-greeter` (NOT
    # services.displayManager.*), and it still reads
    # /etc/greetd/niri_overrides.kdl — both verified in the flake source, since
    # modules/desktop-niri.nix depends on each.
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
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

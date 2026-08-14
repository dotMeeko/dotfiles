{ ... }:

{
  # The prompt is one file shared by every machine, including Windows, where
  # Nix does not exist. Rather than describing it twice — once as Nix options
  # here, once as TOML for chezmoi — the TOML is the single source and
  # home-manager just links it into place.
  #
  # ../chezmoi/dot_config/starship.toml is the exact same file chezmoi deploys
  # on macOS and Windows. Edit it there and every machine picks the change up.
  #
  # No mkForce needed: programs.starship only writes its own config when
  # `settings` or `presets` are set, and common.nix deliberately leaves both
  # empty. The module still exports STARSHIP_CONFIG pointing at this path.
  xdg.configFile."starship.toml".source = ../chezmoi/dot_config/starship.toml;
}

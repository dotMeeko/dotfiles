# NVIDIA GPU (RTX 5080, Blackwell). The monitor is connected to the NVIDIA card,
# so the dGPU drives the display directly (no iGPU offload).
{ config, lib, ... }:
{
  # Allow only specific unfree packages, not everything: the NVIDIA driver and Claude Code.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      "nvidia-persistenced"
      "claude-code"
    ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland (Niri)
    open = true; # REQUIRED for Blackwell / RTX 50xx (proprietary modules don't support it)
    nvidiaSettings = true;
    powerManagement.enable = true;
    # 595.71.05 (stable 26.05) — new enough for RTX 5080; matches the stable kernel ABI.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}

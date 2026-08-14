{ config, ... }:

{
  # RTX 5080 (Blackwell).
  #
  # IMPORTANT: open kernel modules are MANDATORY for the 50xx series — Blackwell
  # will not come up with the proprietary modules, hence open = true. That does
  # not make the driver free (its userspace stays proprietary), so allowUnfree
  # is set in configuration.nix.

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam, Wine
  };

  hardware.nvidia = {
    open = true;

    # Required for Wayland: niri will not start without KMS.
    modesetting.enable = true;

    # Drivers >= 555 support explicit sync, which removes flickering and
    # stutter under Wayland. production is 595.x, so we are well past that.
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # nvidia-settings utility.
    nvidiaSettings = true;

    # On a desktop the suspend/resume hooks tend to hurt more than help.
    # Enable this if the screen stays black after sleep.
    powerManagement.enable = false;
  };

  # The nvidia module only loads these kernel modules when
  # services.xserver.enable is set, and we run pure Wayland without an X
  # server — so list them explicitly.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
    "nvidia_uvm"
  ];

  # Wayland-specific bits for NVIDIA.
  environment.sessionVariables = {
    # Makes Firefox/Chromium and Electron apps run on Wayland.
    NIXOS_OZONE_WL = "1";
    # VA-API through NVIDIA (hardware video decoding).
    LIBVA_DRIVER_NAME = "nvidia";
    # GBM backend for nvidia — required by Wayland compositors.
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}

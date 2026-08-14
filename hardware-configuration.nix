# Hardware specifics that disko does not cover: kernel modules for this
# machine's chipset and storage controller.
#
# Filesystems are NOT here — disko generates them from modules/disko.nix.
# If you regenerate this with nixos-generate-config, use --no-filesystems,
# otherwise it writes a fileSystems block that collides with disko's.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Enough to reach an NVMe or SATA disk in initrd. scripts/install.sh runs
  # nixos-generate-config --no-filesystems and reports if the detected list
  # differs from this one.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # Ryzen 7 7800X3D
  boot.extraModulePackages = [ ];

  # Swap: none. 32 GB of RAM, and zram below covers spikes without writing
  # to the SSD.
  swapDevices = [ ];
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

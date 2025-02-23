{ config, lib, pkgs, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
  };

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2048;  # MB
      cores = 2;
      graphics = true;
      qemu.options = [
        "-net nic,model=virtio,macaddr=52:54:00:12:34:56"
        "-net bridge,br=br0"
      ];
    };
  };

  # Required packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    qemu
    OVMF
  ];
}

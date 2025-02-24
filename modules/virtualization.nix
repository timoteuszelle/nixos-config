{ config, lib, pkgs, ... }:

with lib;

{
  options.myconfig.virtualization = {
    enable = mkEnableOption "Enable safe virtualization configuration";
  };

  config = mkIf config.myconfig.virtualization.enable {
    # Basic virtualization support
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      virt-manager
      qemu
      OVMF
    ];

    # Service configuration with safety timeouts
    systemd.services.libvirtd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      requires = [ "network.target" ];
      serviceConfig = {
        TimeoutStartSec = "30s";
        TimeoutStopSec = "1min";
      };
    };

    # Network timeouts
    networking.timeouts = {
      dhcpcd = 10;
      network-online = 30;
    };

    # User permissions
    users.users.${config.users.users.tim.name}.extraGroups = [ "libvirtd" ];
  };
}

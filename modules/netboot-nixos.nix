{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.netboot-nixos;
  
  # Create a custom NixOS system configuration for netboot
  netbootSystem = (import "${pkgs.path}/nixos" {
    configuration = { modulesPath, ... }: {
      imports = [
        "${modulesPath}/installer/netboot/netboot-minimal.nix"
        /etc/nixos/secrets.nix  # Import secrets
      ];
      
      # Basic system configuration
      boot.supportedFilesystems = [ "btrfs" "ext4" "xfs" ];
      boot.kernelParams = cfg.kernelParams;
      
      # Enable SSH for remote management
      services.openssh.enable = true;
      
      # Tailscale configuration
      services.tailscale = {
        enable = true;
        authKeyFile = "/etc/tailscale/authkey";
      };

      # Set system state version
      system.stateVersion = "24.11";

      # User configuration
      users = {
        mutableUsers = false;
        users.tim = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" ];
          initialPassword = config.secrets.initialPassword;
          openssh.authorizedKeys.keys = with config.secrets.sshKeys.tim; [
            nagoya
            sakai
          ];
        };
      };

      # Enable sudo for wheel group without password
      security.sudo.wheelNeedsPassword = false;


      # Create the authkey file from secrets
      system.activationScripts.tailscaleKey = ''
        mkdir -p /etc/tailscale
        echo ${config.secrets.tailscale.authkey} > /etc/tailscale/authkey
        chmod 600 /etc/tailscale/authkey
      '';
      
      # Add any additional system configuration here
      environment.systemPackages = with pkgs; [
        vim
        git
        htop
        tailscale
      ];
      
      # Define users if needed

      # Enable automatic Tailscale connection
      systemd.services.tailscale-autoconnect = {
        description = "Automatic connection to Tailscale";
        after = [ "network-pre.target" "tailscale.service" ];
        wants = [ "network-pre.target" "tailscale.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for tailscaled to be ready
          sleep 2
          # Attempt to connect to tailscale
          status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
          if [ $status = "Stopped" ]; then
            ${pkgs.tailscale}/bin/tailscale up --authkey file:/etc/tailscale/authkey
          fi
        '';
      };
    };
  }).config.system.build;
  
  # Extract paths for kernel and initrd
  kernel = "${netbootSystem.kernel}/bzImage";
  initrd = "${netbootSystem.netbootRamdisk}/initrd";
  
in {
  options.services.netboot-nixos = {
    enable = mkEnableOption "NixOS netboot configuration";
    
    tftpRoot = mkOption {
      type = types.str;
      default = "/var/lib/tftp";
      description = "Root directory for TFTP files";
    };

    networkAddress = mkOption {
      type = types.str;
      default = "192.168.1.111";
      description = "IP address of the netboot server";
    };

    kernelParams = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional kernel parameters for netbooted systems";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "L+ ${cfg.tftpRoot}/undionly.kpxe - - - - ${pkgs.ipxe}/undionly.kpxe"
      "d ${cfg.tftpRoot}/nixos 0755 root root -"
      "L+ ${cfg.tftpRoot}/nixos/bzImage - - - - ${kernel}"
      "L+ ${cfg.tftpRoot}/nixos/initrd - - - - ${initrd}"
      "L+ ${cfg.tftpRoot}/boot.ipxe - - - - /etc/tftp/boot.ipxe"
    ];

    environment.etc."tftp/boot.ipxe".text = ''
      #!ipxe

      # Set default boot parameters
      kernel ${toString cfg.kernelParams}
      
      # Boot menu
      :start
      menu iPXE boot menu
      item --key n nixos Boot NixOS
      item shell Drop to iPXE shell
      choose --timeout 5000 --default nixos selected || goto shell
      goto ''${selected}

      :nixos
      echo Booting NixOS...
      kernel http://${cfg.networkAddress}/nixos/bzImage init=${netbootSystem.toplevel}/init ${toString cfg.kernelParams}
      initrd http://${cfg.networkAddress}/nixos/initrd
      boot

      :shell
      echo Type 'exit' to return to menu
      shell
      goto start
    '';

    # Required services configuration
    services.nginx.virtualHosts."netboot" = {
      root = cfg.tftpRoot;
      locations."/" = {
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };
}

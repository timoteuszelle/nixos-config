{ config, pkgs, ... }: {
  imports = [ ./modules/netboot-nixos.nix ];
  containers.netboot = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0";
    
    # Configure a static IP for the container
    localAddress = "192.168.1.111/24";
    
    # Basic network configuration
    extraFlags = [ 
      "--network-veth"
    ];
    
    bindMounts = {
      "/var/lib/tftp" = {
        hostPath = "/var/lib/tftp";
        isReadOnly = false;
      };
      "/home/tim/.ssh/authorized_keys" = {
        hostPath = "/home/tim/.ssh/authorized_keys";
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: {
      system.stateVersion = "24.11";

      # Enable OpenSSH
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      # Create tim user (matching your existing setup)
      users.users.tim = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/tim";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = [ "/home/tim/.ssh/authorized_keys" ];
      };

      # Sudo without password (matching your existing setup)
      security.sudo.extraRules = [{
        users = [ "tim" ];
        commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
      }];

      # Required packages
      environment.systemPackages = with pkgs; [
        ipxe
        bash
        coreutils
        openssh
        jq
        sudo
      ];

      # Configure TFTP server for netboot
      services.tftpd = {
        enable = true;
        path = "/var/lib/tftp";
      };

      # Simple HTTP server for serving boot files
      services.nginx = {
        enable = true;
        virtualHosts."netboot" = {
          root = "/var/lib/tftp";
          listen = [{ addr = "192.168.1.111"; port = 80; }];
        };
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 22 80 ];
          allowedUDPPorts = [ 69 ]; # TFTP
        };
        useHostResolvConf = false;
        defaultGateway = "192.168.1.1";
        nameservers = [ "192.168.1.200" ]; # Pi-hole
      };
    };
  };

  # Create required directories on the host
  systemd.tmpfiles.rules = [
    "d /var/lib/tftp 0755 root root -"
  ];
}

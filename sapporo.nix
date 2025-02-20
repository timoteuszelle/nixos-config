{ config, lib, pkgs, ... }: {
  containers.sapporo = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = false;
    
    forwardPorts = [{
      hostPort = 2222;
      containerPort = 22;
      protocol = "tcp";
    }];
    
    extraFlags = [ 
      "--system-call-filter=@network-io"
      "--system-call-filter=@system-service"
      "--capability=CAP_NET_ADMIN"
      "--capability=CAP_NET_RAW"
    ];
    
    bindMounts = {
      "/dev/net/tun" = {
        hostPath = "/dev/net/tun";
        isReadOnly = false;
      };
      "/workspace" = {
        hostPath = "/home/tim/git-workspace";
        isReadOnly = false;
      };
      "/workspace-persist" = {
        hostPath = "/home/tim/git-workspace-persist";
        isReadOnly = false;
      };
      "/root/.gitconfig" = {
        hostPath = "/home/tim/.gitconfig";
        isReadOnly = true;
      };
      "/etc/ssh" = {
        hostPath = "/home/tim/.sapporo/ssh";
        isReadOnly = false;
      };
      "/var/lib/tailscale" = {
        hostPath = "/home/tim/.sapporo/tailscale";
        isReadOnly = false;
      };
    };

    config = { config, pkgs, ... }: {
      system.stateVersion = "24.11";  # Match host version

      # System configuration
      time.timeZone = "Europe/Amsterdam";
      i18n.defaultLocale = "en_US.UTF-8";
      
      # Network configuration
      networking = {
        useHostResolvConf = true;
        firewall = {
          enable = true;
          allowedTCPPorts = [ 2222 ];
          allowedUDPPorts = [ 41641 ];
        };
      };

      # Enable SSH server
      services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PermitRootLogin = "yes";
          PasswordAuthentication = false;
        };
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";  # Enables both client and exit node capabilities
      };

      # Install needed packages
      environment.systemPackages = with pkgs; [
        neovim
        git
        fastfetch
        openssh
        sshs
        bat
        iproute2
        openssl
        toybox
        gh
        jq
        bash
        gnumake
        gcc
        python3
        tailscale
      ];

      # Environment variables
      environment.variables = {
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no";
        NIX_CONFIG = "experimental-features = nix-command flakes";
        HOSTNAME = "sapporo";
      };

      # Match host locale settings
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "nl_NL.UTF-8";
        LC_IDENTIFICATION = "nl_NL.UTF-8";
        LC_MEASUREMENT = "nl_NL.UTF-8";
        LC_MONETARY = "nl_NL.UTF-8";
        LC_NAME = "nl_NL.UTF-8";
        LC_NUMERIC = "nl_NL.UTF-8";
        LC_PAPER = "nl_NL.UTF-8";
        LC_TELEPHONE = "nl_NL.UTF-8";
        LC_TIME = "nl_NL.UTF-8";
      };

      # Configure users
      users.users.tim = {
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [
          "/home/tim/.ssh/id_ed25519.pub"
        ];
      };

      # Enable sudo for wheel group
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # Nix configuration
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      # Enable networking capabilities
      boot.kernel.sysctl."net.ipv4.ip_forward" = true;
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
    };
  };

  # Reset script
  environment.systemPackages = with pkgs; [
    (writeScriptBin "reset-sapporo" ''
      #!${stdenv.shell}
      set -e
      echo "Stopping sapporo container..."
      nixos-container stop sapporo
      echo "Removing sapporo container..."
      nixos-container destroy sapporo
      echo "Cleaning temporary workspace..."
      rm -rf /home/tim/git-workspace/*
      echo "Starting fresh sapporo container..."
      nixos-container start sapporo
      echo "Container reset complete!"
    '')
  ];
}

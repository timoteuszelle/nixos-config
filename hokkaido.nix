{ config, pkgs, ... }: {
  containers.hokkaido = {
    autoStart = true;
    privateNetwork = true; # Use a private network namespace with br0 bridging
    hostBridge = "br0"; # Connect directly to host’s br0
    config = { config, pkgs, ... }: {
      system.stateVersion = "24.11";

      # System packages
      environment.systemPackages = with pkgs; [
        # Core tools
        bash coreutils openssh sudo git vim nano tmux toybox
        # Development tools
        gcc gnumake python3 nodejs neovim
        # Network tools
        curl wget iputils netcat htop
        # Nix tools
        nixfmt-classic statix deadnix nixfmt-rfc-style
      ];

      # Enable SSH
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        # Use port 22 inside the container; external access via 192.168.1.202:22
      };

      # Define tim user
      users.users.tim = {
        isNormalUser = true;
        uid = 1000; # Match host UID for file permissions
        home = "/home/tim";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = [ "/home/tim/.ssh/authorized_keys" ];
      };

      # Sudo without password
      security.sudo.extraRules = [{
        users = [ "tim" ];
        commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
      }];

      # Networking
      networking = {
        useDHCP = false;
        interfaces.eth0 = {
          ipv4.addresses = [{ address = "192.168.1.202"; prefixLength = 24; }];
        };
        defaultGateway = "192.168.1.1";
        nameservers = [ "192.168.1.200" "1.1.1.1" ];
        firewall.enable = false; # Disable container firewall (host handles it)
      };

      # Nix configuration
      nix = {
        package = pkgs.nix;
        settings.experimental-features = [ "nix-command" "flakes" ];
      };

      nixpkgs.config.allowUnfree = true;
    };

    # Bind mounts
    bindMounts = {
      "/home/tim/projects" = {
        hostPath = "/home/tim/projects";
        isReadOnly = false;
      };
      "/home/tim/.ssh/authorized_keys" = {
        hostPath = "/home/tim/.ssh/authorized_keys";
        isReadOnly = true;
      };
    };
  };

  # Host-side firewall rule for container SSH
  networking.firewall.allowedTCPPorts = [ 22 ]; # Allow 192.168.1.202:22
}

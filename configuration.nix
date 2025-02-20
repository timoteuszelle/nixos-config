# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./pihole.nix
    ./hardware-configuration.nix
    ./prometheus.nix
    ./homeassistant.nix
    ./ollama.nix
    ./qbittorrent.nix
    ./plex.nix
    ./secrets.nix
    ./portainer.nix
    #./saporro.nix
    ./hokkaido.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nagoya";
    networkmanager.enable = true;
    nameservers = [ "100.100.100.100" "1.1.1.1" "1.0.0.1" ];
    search = [ "tail850809.ts.net" ];

    # Bridge configuration
    interfaces = {
      enp3s0.useDHCP = false;
      enp4s0.useDHCP = false;
      br0 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.1.200";
          prefixLength = 24;
        }];
      };
    };

    bridges = { br0 = { interfaces = [ "enp3s0" "enp4s0" ]; }; };

    defaultGateway = "192.168.1.1";
    useDHCP = false;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        53
        80
	2323
        4711
        3000
        9090
        9100
        8080
        8123
        3001
        8888
        8999
        6881
        32400
        3005
        8324
        32469
        8000
        9000
        9443
        11434
	2222
	9617
        2323
        7070
        7443
        4000 4001 4002
        5000 5001
      ];
      allowedUDPPorts = [ 53 67 6881 1900 32410 32412 32413 32414 11434 ];
      interfaces.br0 = {
        allowedTCPPorts = [
          22
          53
          80
	  2323
          4711
          3000
          9090
          9100
          8080
          8123
          3001
          8888
          8999
          6881
          32400
          3005
          8324
          32469
          3389
          4713
          4714
          9000
          8000
          9443
	  2222
	  9617
	  2323
	  7070
	  7443
          4000 4001 4002
          5000 5001
        ];
        allowedUDPPorts = [ 53 67 6881 1900 32410 32412 32413 32414 ];
      };
	extraCommands = ''
  	iptables -t nat -A PREROUTING -p tcp -i tailscale0 --dport 2323 -j DNAT --to-destination 192.168.1.202:22
  	iptables -A FORWARD -p tcp -d 192.168.1.202 --dport 22 -j ACCEPT
	'';
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. 
  users.users.tim = {
    isNormalUser = true;
    description = "Tim Oudesluijs-Zelle";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
  };

  # Disable hibernation and suspend
  powerManagement = {
    enable = true;
    powertop.enable = false;
    cpuFreqGovernor = "performance";
  };

  # Explicitly disable hibernation and suspend
  systemd.sleep.extraConfig = ''
    AllowHibernation= no
    AllowSuspend= no
    AllowSuspendThenHibernate= no
    AllowHybridSleep= no
  '';

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    neovim
    git
    fastfetch
    docker
    tailscale-systray
    tailscale
    openssh
    sshs
    bat
    iproute2
    openssl
    toybox
    ollama
    gh
    jq
  ];

  # Enable remote GUI support
  services.gnome.gnome-remote-desktop.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable Nix Containering
  virtualisation.containers.enable = true;

  systemd.tmpfiles.rules = [
    "d /home/tim/prometheus/grafana 0755 472 472 -"
    "d /home/tim/prometheus/prometheus 0755 65534 65534 -"
    "d /home/tim/prometheus/prometheus-data 0755 65534 65534 -"
    "d /home/tim/projects 0755 1000 1000 -"
    "f /home/tim/.ssh/authorized_keys 0600 1000 1000 -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "24.11";
}

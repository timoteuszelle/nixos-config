{ config, pkgs, ... }:{
  imports = [
    ./pihole.nix ./hardware-configuration.nix ./prometheus.nix ./homeassistant.nix ./ollama.nix
    ./qbittorrent.nix ./plex.nix ./secrets.nix ./portainer.nix ./netboot.nix ./hokkaido.nix
    ./nextcloud.nix ./ddns.nix ./ffxi.nix
  ];  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ rocmPackages.clr amdvlk ];
  };  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;  networking = {
    hostName = "nagoya";
    networkmanager.enable = true;
    nameservers = [ "100.100.100.100" "1.1.1.1" "1.0.0.1" ];
    search = [ "tail850809.ts.net" ];
    interfaces = {
      enp3s0.useDHCP = false;
      enp4s0.useDHCP = false;
      br0 = {
        useDHCP = false;
        ipv4.addresses = [{ address = "192.168.1.200"; prefixLength = 24; }];
      };
    };
    bridges = { br0 = { interfaces = [ "enp3s0" "enp4s0" ]; }; };
    defaultGateway = "192.168.1.1";
    useDHCP = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 53 80 443 2323 4711 4011 3000 9090 9100 8080 8082 8181 8123 3001 8081 8888 8999 6881
        32400 3005 8324 32469 8000 9000 9443 11434 2222 9617 2323 7070 7443 4000 4001 4002 5000 5001 54230 54231 54001 54002
      ];
      allowedUDPPorts = [ 53 67 69 6881 1900 32410 32412 32413 32414 11434 54230 54231 ];
      interfaces.br0 = {
        allowedTCPPorts = [
          22 53 80 443 2323 4711 4011 3000 9090 9100 8080 8082 8181 8123 3001 8081 8888 8999 6881
          32400 3005 8324 32469 3389 4713 4714 9000 8000 9443 2222 9617 2323 7070 7443 4000 4001 4002 5000 5001 54230 54231 54001 54002
        ];
        allowedUDPPorts = [ 53 67 69 4011 6881 1900 32410 32412 32413 32414 54230 54231 ];
      };
      extraCommands = ''
        iptables -t nat -A PREROUTING -p tcp -i tailscale0 --dport 2323 -j DNAT --to-destination 192.168.1.202:22
        iptables -A FORWARD -p tcp -d 192.168.1.202 --dport 22 -j ACCEPT
      '';
    };
  };  time.timeZone = "Europe/Amsterdam";  i18n.defaultLocale = "en_US.UTF-8";
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
  };  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };  services.printing.enable = true;  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };  users.users.tim = {
    isNormalUser = true;
    description = "Tim Oudesluijs-Zelle";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "video" "render" "nextcloud" "ffxi" ];
    packages = with pkgs; [ ];
  };  powerManagement = {
    enable = true;
    powertop.enable = false;
    cpuFreqGovernor = "performance";
  };
  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspend=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;  environment.systemPackages = with pkgs; [
    neovim git fastfetch docker tailscale-systray tailscale openssh sshs bat iproute2 openssl toybox ollama gh jq
  ];  services.gnome.gnome-remote-desktop.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.containers.enable = true;  systemd.tmpfiles.rules = [
    "d /home/tim/prometheus/grafana 0755 472 472 -"
    "d /home/tim/prometheus/prometheus 0755 65534 65534 -"
    "d /home/tim/prometheus/prometheus-data 0755 65534 65534 -"
    "d /home/tim/projects 0755 1000 1000 -"
    "f /home/tim/.ssh/authorized_keys 0600 1000 1000 -"
  ];  system.stateVersion = "24.11";
}



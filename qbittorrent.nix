{ config, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        environment = {
          VPN_SERVICE_PROVIDER = "mullvad";
          VPN_TYPE = "openvpn";
          SERVER_COUNTRIES = "Netherlands";
          OPENVPN_USER = config.secrets.qbittorrent.vpnUser;
          OPENVPN_PASSWORD = config.secrets.qbittorrent.vpnPassword;
          SERVER_HOSTNAME = "nl-ams-ovpn-001";
          SERVER_IP = config.secrets.qbittorrent.vpnIP;
          SERVER_PORT = "1197";
          SERVER_PROTOCOL = "udp";
          OPENVPN_PROTOCOL = "udp";
          #VPN_PORT_FORWARDING = "on";
        };
        extraOptions = [
          "--privileged"
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        ports = [
          "8999:8999/tcp"  # gluetun HTTP control server
          "8888:8888/tcp"  # qbittorrent HTTP
          "6881:6881/tcp"
          "6881:6881/udp"
        ];
      };
      
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        dependsOn = [ "gluetun" ];
        environment = {
          TZ = "Europe/Amsterdam";
          PUID = "1000";
          PGID = "1000";
          WEBUI_PORT = "8888";
        };
        volumes = [
          "/home/tim/qbittorrent/config:/config"
          "/home/tim/qbittorrent/downloads:/downloads"
        ];
        extraOptions = [
          "--network=container:gluetun"
        ];
      };
    };
  };

  # Create required directories
  systemd.tmpfiles.rules = [
    "d /home/tim/qbittorrent/config 0755 1000 1000 -"
    "d /home/tim/qbittorrent/downloads 0755 1000 1000 -"
  ];

  # Add firewall rules
  networking.firewall = {
    allowedTCPPorts = [ 8888 8999 ];
    allowedUDPPorts = [ 6881 ];
  };
}

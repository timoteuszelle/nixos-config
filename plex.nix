{config, lib, pkgs, ...}: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      plex = {
        image = "plexinc/pms-docker:latest";
        volumes = [
          "/home/tim/plex/config:/config"
          "/home/tim/plex/transcode:/transcode"
          "/home/tim/media:/data"  # Adjust this path to where your media is stored
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
          PLEX_CLAIM = config.secrets.plex.claim;  # Add your claim token here if needed for first-time setup
          ADVERTISE_IP = "http://192.168.1.200:32400/";
        };
        extraOptions = [
          "--network=host"  # Recommended for Plex to enable proper network discovery
          "--memory=2g"
          "--memory-swap=4g"
          "--cpu-shares=1024"
          "--device=/dev/dri:/dev/dri"  # If you want hardware transcoding (requires compatible GPU)
          "--health-cmd=curl -f http://192.168.1.200:32400/web || exit 1"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=5s"
        ];
        # Ports commented out since using host network mode
        ports = [
          # "32400:32400"  # Primary Plex port
          # "3005:3005"    # Plex Companion
          # "8324:8324"    # Roku via Plex Companion
          # "32469:32469"  # Plex DLNA Server
          # "1900:1900/udp"  # Plex DLNA Server
          # "32410:32410/udp"  # GDM network discovery
          # "32412:32412/udp"  # GDM network discovery
          # "32413:32413/udp"  # GDM network discovery
          # "32414:32414/udp"  # GDM network discovery
        ];
      };
    };
  };
}

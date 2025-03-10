{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      plex = {
        image = "plexinc/pms-docker:latest";
        volumes = [
          "/home/tim/plex/config:/config"
          "/home/tim/plex/transcode:/transcode"
          "/home/tim/media:/data"
          "/etc/localtime:/etc/localtime:ro"
          "/dev/dri:/dev/dri"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
          PLEX_CLAIM = config.secrets.plex.claim;
          ADVERTISE_IP = "http://192.168.1.200:32400/";
          PLEX_MEDIA_SERVER_USE_VAAPI = "1";
        };
        extraOptions = [
          "--network=host"
          "--memory=12g"
          "--memory-swap=24g"
          "--cpu-shares=4096"
          "--device=/dev/dri:/dev/dri"
          "--privileged"
          "--group-add=video"
          "--health-cmd=curl -f http://192.168.1.200:32400/web || exit 1"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=5s"
        ];
        ports = [];
      };
    };
  };
}

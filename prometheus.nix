{ config, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      prometheus = {
        image = "prom/prometheus:latest";
        volumes = [
          "/home/tim/prometheus/prometheus:/etc/prometheus"
          "/home/tim/prometheus/prometheus-data:/prometheus"
        ];
        environment = { TZ = "Europe/Amsterdam"; };
        extraOptions = [
          "--network=host"
          "--memory=1g"
          "--memory-swap=2g"
          "--cpu-shares=512"
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1"
          "--health-interval=30s"
          "--health-timeout=3s"
          "--health-retries=3"
        ];
      };

      grafana = {
        image = "grafana/grafana:latest";
        volumes = [ "/home/tim/prometheus/grafana:/var/lib/grafana" ];
        environment = {
          TZ = "Europe/Amsterdam";
          GF_SECURITY_ADMIN_PASSWORD = config.secrets.prometheus.adminPassword;
          GF_USERS_ALLOW_SIGN_UP = "false";
          GF_SERVER_ROOT_URL = "http://localhost:3000";
        };
        extraOptions = [
          "--network=host"
          "--memory=512m"
          "--memory-swap=1g"
          "--cpu-shares=512"
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"
          "--health-interval=30s"
          "--health-timeout=3s"
          "--health-retries=3"
        ];
      };

      node-exporter = {
        image = "prom/node-exporter:latest";
        volumes = [ "/proc:/host/proc:ro" "/sys:/host/sys:ro" "/:/rootfs:ro" ];
        environment = { TZ = "Europe/Amsterdam"; };
        extraOptions = [
          "--network=host"
          "--pid=host"
          "--memory=256m"
          "--memory-swap=512m"
          "--cpu-shares=256"
        ];
        cmd = [
          "--path.procfs=/host/proc"
          "--path.sysfs=/host/sys"
          "--path.rootfs=/rootfs"
          "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
        ];
      };

      cadvisor = {
        image = "gcr.io/cadvisor/cadvisor:latest";
        volumes = [
          "/:/rootfs:ro"
          "/var/run:/var/run:ro"
          "/sys:/sys:ro"
          "/var/lib/docker/:/var/lib/docker:ro"
          "/dev/disk/:/dev/disk:ro"
        ];
        environment = { TZ = "Europe/Amsterdam"; };
        extraOptions = [
          "--network=host"
          "--memory=256m"
          "--memory-swap=512m"
          "--cpu-shares=256"
        ];
      };

      pihole-exporter = {
        image = "ekofr/pihole-exporter:latest";
        environment = {
          PIHOLE_HOSTNAME = "localhost";
          PIHOLE_PORT = "80";
          PIHOLE_PASSWORD = config.secrets.pihole.webpassword;
          PORT = "9617";
        };
        extraOptions = [
          "--network=host"
          "--memory=128m"
          "--memory-swap=256m"
          "--cpu-shares=128"
        ];
      };
      
      nextcloud-exporter = {
        image = "xperimental/nextcloud-exporter:latest";
        environment = {
          NEXTCLOUD_SERVER = "http://nextcloud:80";
          NEXTCLOUD_USERNAME = "admin";
          NEXTCLOUD_PASSWORD = config.secrets.nextcloud.adminPassword;
          # Optionally set TLS_SKIP_VERIFY=true if using self-signed certs
        };
        extraOptions = [
          "--network=nextcloud_network"
          "--memory=128m"
          "--memory-swap=256m"
          "--cpu-shares=128"
        ];
      };

      plex-exporter = {
  image = "arnarg/plex_exporter:latest";
  environment = {
    PLEX_URL = "http://localhost:32400";
    PLEX_TOKEN = config.secrets.plex.token; # You'll need to create this secret
    LISTEN_ADDR = ":9594";
  };
  extraOptions = [
    "--network=host"
    "--memory=128m"
    "--memory-swap=256m"
    "--cpu-shares=128"
  ];
};

qbittorrent-exporter = {
  image = "esanchezm/prometheus-qbittorrent-exporter:latest";
  environment = {
    QBITTORRENT_HOST = "localhost";
    QBITTORRENT_PORT = "8080"; # Adjust port if needed
    QBITTORRENT_USER = "admin"; # Replace with your username
    QBITTORRENT_PASSWORD = config.secrets.qbittorrent.password; # Create this secret
    PORT = "9567"; # Port for the exporter
  };
  extraOptions = [
    "--network=host"
    "--memory=128m"
    "--memory-swap=256m"
    "--cpu-shares=128"
  ];
};

# that will at least check if the service is up
ollama-prober = {
  image = "prom/blackbox-exporter:latest";
  volumes = [
    "/home/tim/prometheus/blackbox.yml:/config/blackbox.yml"
  ];
  extraOptions = [
    "--network=nextcloud_network"
    "--memory=128m"
    "--memory-swap=256m"
    "--cpu-shares=128"
  ];
  cmd = [
    "--config.file=/config/blackbox.yml"
  ];
};
    };
  };

  # Open required ports in the firewall
  networking.firewall.allowedTCPPorts = [
    3000  # Grafana
    9090  # Prometheus
    9100  # Node-exporter
    8080  # cAdvisor
    9617  # Pi-hole exporter
    9205  # nextcloud exporter
    9594  # Plex exporter 
    9567  # QBittorrent exporter
  ];
}

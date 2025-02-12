{...}: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        volumes = [
          "/home/tim/homeassistant/config:/config"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
        };
        extraOptions = [
          "--network=host"
          "--memory=1g"
          "--memory-swap=2g"
          "--cpu-shares=1024"
          "--device=/dev/ttyUSB0:/dev/ttyUSB0" # If you need USB devices
          "--privileged"  # Required for some integrations
          "--health-cmd=curl -f http://localhost:8123 || exit 1"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=5s"
        ];
        # Ports commented out since using host network mode
        ports = [
          #"8123:8123"  # Web interface
        ];
      };
    };
  };
}

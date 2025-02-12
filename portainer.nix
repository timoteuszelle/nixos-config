{ config, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      portainer = {
        image = "portainer/portainer-ce:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/home/tim/portainer:/data"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
        };
        extraOptions = [
          "--network=host"
          "--memory=512m"
          "--memory-swap=1g"
          "--cpu-shares=512"
        ];
      };
    };
  };

  # Open required ports in the firewall
  networking.firewall.allowedTCPPorts = [ 
    9000  # Portainer HTTP
    9443  # Portainer HTTPS
    8000  # Portainer Edge
  ];
}

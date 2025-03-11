{ config, pkgs, ... }:

{
  # Define Nextcloud user
  users.users.nextcloud = {
    isSystemUser = true;
    uid = 998;
    group = "nextcloud";
    home = "/srv/nextcloud";
    description = "Nextcloud Docker user";
  };
  users.groups.nextcloud = { gid = 998; };

  # Docker-based Nextcloud container
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      nextcloud = {
        image = "nextcloud:29"; # Stable version as of NixOS 24.11
        autoStart = true;
        ports = [ "8081:80" ]; # Host port 8081 -> container port 80
        volumes = [
          "/srv/nextcloud/data:/var/www/html/data" # Persistent data
          "/srv/nextcloud/config:/var/www/html/config" # Persistent config
        ];
        environment = {
          "NEXTCLOUD_ADMIN_USER" = "admin";
          "NEXTCLOUD_ADMIN_PASSWORD" = config.secrets.nextcloud.adminPassword;
          # No NEXTCLOUD_TRUSTED_DOMAINS - managed manually in config.php
        };
        extraOptions = [
          "--network=bridge" # Uses Docker bridge network
          "--user=998:998" # Run as nextcloud user
        ];
      };
    };
  };

  # Nginx for public HTTPS access
  services.nginx = {
    enable = true;
    virtualHosts."${config.secrets.cloudflare.cloudMyDomainName}" = {
      forceSSL = true;
      enableACME = true; # Auto-generates SSL cert via Let’s Encrypt
      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
        proxyWebsockets = true;
      };
    };
  };

  # Open firewall for HTTPS
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

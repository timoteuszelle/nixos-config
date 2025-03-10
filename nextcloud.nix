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
             "NEXTCLOUD_TRUSTED_DOMAINS" = "192.168.1.200 nextcloud.tail850809.ts.net"; # LAN and Tailscale
           };
           extraOptions = [
             "--network=bridge" # Uses Docker bridge network
	     "--user=998:998" # Run as nextcloud user
           ];
         };
       };
     };
   }

{ config, pkgs, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = config.secrets.cloudflare.email;
    certs = {
      "${config.secrets.cloudflare.cloudMyDomainName}" = {
        domain = config.secrets.cloudflare.cloudMyDomainName;
        dnsProvider = "cloudflare";
        credentialsFile = "/var/lib/secrets/cloudflare-api-token";
        group = "nginx-nextcloud";
      };
    };
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/15 * * * * root ${pkgs.docker}/bin/docker exec -u 33 nextcloud php /var/www/html/cron.php"
      "*/5 * * * * root ${pkgs.docker}/bin/docker exec -u 33 nextcloud php occ preview:generate-all"
      "* * * * * root ${pkgs.bash}/bin/bash /srv/nextcloud/scripts/run_ffmpeg_install.sh"
    ];
  };

  systemd.tmpfiles.rules = [
    "f /var/lib/secrets/cloudflare-api-token 0640 root nginx-nextcloud - CLOUDFLARE_DNS_API_TOKEN=${config.secrets.cloudflare.apiToken}"
    "d /srv/nextcloud 0770 33 1002 -"
    "d /srv/nextcloud/config 0770 33 1002 -"
    "d /srv/nextcloud/data 0770 33 1002 -"
    "d /srv/nextcloud/custom_apps 0770 33 1002 -"
    "d /srv/nextcloud/html 0770 33 1002 -"
    "d /srv/nextcloud/fontcache 0770 33 1002 -"
    "d /srv/nextcloud/redis 0770 6379 6379 -"
    "d /srv/nextcloud/mysql 0770 998 999 -"
    "d /srv/nextcloud/scripts 0755 33 33 -"
    "d /srv/nextcloud/logs 0770 33 1002 -"
    "f /srv/nextcloud/logs/nextcloud-ffmpeg-install.log 0644 33 1002 -"
  ];

  system.activationScripts = {
    nextcloudRebuildTime = ''
      ${pkgs.coreutils}/bin/date +%s > /var/run/nextcloud-rebuild-time
    '';
    nextcloudScripts = ''
      ${pkgs.coreutils}/bin/cat > /srv/nextcloud/scripts/install_config_ffmpeg.sh << 'EOF'
#!/bin/sh
apt-get update
apt-get install -y ffmpeg
php occ config:app:set memories ffmpeg_path --value="/usr/bin/ffmpeg" -u 33
php occ config:app:set memories ffprobe_path --value="/usr/bin/ffprobe" -u 33
echo "FFmpeg installed and configured successfully"
EOF
      ${pkgs.coreutils}/bin/chmod 755 /srv/nextcloud/scripts/install_config_ffmpeg.sh
      ${pkgs.coreutils}/bin/chown 33:33 /srv/nextcloud/scripts/install_config_ffmpeg.sh

      ${pkgs.coreutils}/bin/cat > /srv/nextcloud/scripts/run_ffmpeg_install.sh << 'EOF'
#!/bin/sh
set -e
${pkgs.coreutils}/bin/touch /srv/nextcloud/logs/nextcloud-ffmpeg-install.log
for i in 1 2 3 4; do
  echo "Cron check at $(${pkgs.coreutils}/bin/date)" >> /srv/nextcloud/logs/nextcloud-ffmpeg-install.log
  REBUILD_TIME=$(${pkgs.coreutils}/bin/cat /var/run/nextcloud-rebuild-time 2>/dev/null || echo 0)
  NOW=$(${pkgs.coreutils}/bin/date +%s)
  if [ "$REBUILD_TIME" -gt 0 ] && [ $((NOW - REBUILD_TIME)) -le 180 ] && [ $((NOW - REBUILD_TIME)) -ge 30 ] && ${pkgs.systemd}/bin/systemctl is-active --quiet docker-nextcloud.service && ! ${pkgs.docker}/bin/docker exec nextcloud sh -c "[ -x /usr/bin/ffmpeg ]"; then
    ${pkgs.docker}/bin/docker exec -i nextcloud sh /scripts/install_config_ffmpeg.sh >> /srv/nextcloud/logs/nextcloud-ffmpeg-install.log 2>&1
    echo "Script ran at $(${pkgs.coreutils}/bin/date)" >> /srv/nextcloud/logs/nextcloud-ffmpeg-install.log
  fi
  ${pkgs.coreutils}/bin/sleep 15
done
EOF
      ${pkgs.coreutils}/bin/chmod 755 /srv/nextcloud/scripts/run_ffmpeg_install.sh
      ${pkgs.coreutils}/bin/chown root:root /srv/nextcloud/scripts/run_ffmpeg_install.sh
    '';
  };

  users.users.nextcloud = {
    isSystemUser = true;
    uid = 1002;
    group = "nextcloud";
    home = "/srv/nextcloud";
    description = "Nextcloud Docker user";
  };
  users.groups.nextcloud = { gid = 1002; };
  users.users.redis = {
    isSystemUser = true;
    uid = 6379;
    group = "redis";
    home = "/srv/nextcloud/redis";
    description = "Redis Docker user";
  };
  users.groups.redis = { gid = 6379; };
  users.users.mysql = {
    isSystemUser = true;
    uid = 998;
    group = "mysql";
    home = "/srv/nextcloud/mysql";
    description = "MySQL Docker user";
  };
  users.groups.mysql = { gid = 999; };
  users.groups.nginx-nextcloud = {};

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      nextcloud = {
        image = "nextcloud:31";
        autoStart = true;
        ports = [ "8081:80" ];
        volumes = [
          "/srv/nextcloud/html:/var/www/html"
          "/srv/nextcloud/config:/var/www/html/config"
          "/srv/nextcloud/data:/var/www/html/data"
          "/srv/nextcloud/custom_apps:/var/www/html/custom_apps"
          "/srv/nextcloud/fontcache:/var/cache/fontconfig"
          "/srv/nextcloud/scripts:/scripts"
        ];
        environment = {
          "NEXTCLOUD_ADMIN_USER" = "admin";
          "NEXTCLOUD_ADMIN_PASSWORD" = config.secrets.nextcloud.adminPassword;
          "NEXTCLOUD_TRUSTED_DOMAINS" = config.secrets.cloudflare.cloudMyDomainName;
          "REDIS_HOST" = "redis";
          "MYSQL_HOST" = "mysql";
          "MYSQL_DATABASE" = "nextcloud";
          "MYSQL_USER" = "nextcloud";
          "MYSQL_PASSWORD" = config.secrets.nextcloud.mysqlPassword;
        };
        extraOptions = [
          "--memory=8g"
          "--cpus=8"
          "--link=redis:redis"
          "--link=mysql:mysql"
          "--health-cmd=curl -f http://localhost || exit 1"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
          "--add-host=${config.secrets.cloudflare.cloudMyDomainName}:127.17.0.1"
        ];
        dependsOn = [ "redis" "mysql" ];
      };
      redis = {
        image = "redis:latest";
        autoStart = true;
        volumes = [ "/srv/nextcloud/redis:/data" ];
        user = "6379:6379";
      };
      mysql = {
        image = "mysql:8.4";
        autoStart = true;
        volumes = [ 
          "/srv/nextcloud/mysql:/var/lib/mysql"
          "/srv/nextcloud/mysql/custom.cnf:/etc/mysql/conf.d/custom.cnf"
        ];
        user = "998:999";
        environment = {
          "MYSQL_ROOT_PASSWORD" = config.secrets.nextcloud.mysqlRootPassword;
          "MYSQL_DATABASE" = "nextcloud";
          "MYSQL_USER" = "nextcloud";
          "MYSQL_PASSWORD" = config.secrets.nextcloud.mysqlPassword;
        };
      };
    };
  };

  systemd.services.nginx-nextcloud = {
    description = "Nginx for Nextcloud with SSL";
    after = [ "network.target" "acme-${config.secrets.cloudflare.cloudMyDomainName}.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStartPre = "${pkgs.nginx}/bin/nginx -c /etc/nginx-nextcloud.conf -t";
      ExecStart = "${pkgs.nginx}/bin/nginx -c /etc/nginx-nextcloud.conf";
      ExecReload = "${pkgs.nginx}/bin/nginx -s reload";
      ExecStop = "${pkgs.nginx}/bin/nginx -s stop -c /etc/nginx-nextcloud.conf";
      PIDFile = "/run/nginx-nextcloud.pid";
      RuntimeDirectory = "nginx-nextcloud";
      Restart = "always";
    };
  };

  environment.etc."nginx-nextcloud.conf" = {
    text = ''
      pid /run/nginx-nextcloud.pid;
      error_log stderr;
      events {}
      http {
        include ${pkgs.nginx}/conf/mime.types;
        types {
          text/javascript mjs;
        }
        default_type application/octet-stream;
        server_names_hash_bucket_size 64;

        map $http_upgrade $connection_upgrade {
          default upgrade;
          "" close;
        }

        server {
          listen 0.0.0.0:443 ssl;
          server_name ${config.secrets.cloudflare.cloudMyDomainName};

          ssl_certificate /var/lib/acme/${config.secrets.cloudflare.cloudMyDomainName}/fullchain.pem;
          ssl_certificate_key /var/lib/acme/${config.secrets.cloudflare.cloudMyDomainName}/key.pem;

          add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;

          client_max_body_size 1g;

          proxy_connect_timeout 300;
          proxy_send_timeout 300;
          proxy_read_timeout 300;

          add_header X-Content-Type-Options "nosniff" always;
          add_header X-Robots-Tag "noindex,nofollow" always;
          add_header X-Permitted-Cross-Domain-Policies "none" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Referrer-Policy "no-referrer" always;

          location /.well-known/caldav {
            return 301 $scheme://$host/remote.php/dav;
          }
          location /.well-known/carddav {
            return 301 $scheme://$host/remote.php/dav;
          }
          location / {
            proxy_pass http://127.0.0.1:8081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_hide_header X-Content-Type-Options;
            proxy_hide_header X-Robots-Tag;
            proxy_hide_header X-Permitted-Cross-Domain-Policies;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Referrer-Policy;
          }
        }
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
}

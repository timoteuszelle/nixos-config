{ config, pkgs, ... }:

{
  users.users.ffxi = {
    isSystemUser = true;
    uid = 1003;
    group = "ffxi";
    home = "/srv/ffxi";
    description = "FFXI Server user";
  };
  users.groups.ffxi = {
    gid = 1003;
  };

  systemd.tmpfiles.rules = [
    "d /srv/ffxi 0770 ffxi ffxi -"
    "d /srv/ffxi/mysql 0770 ffxi ffxi -"
    "d /srv/ffxi/server/log 0770 ffxi ffxi -"
    "d /srv/ffxi/server/settings 0770 ffxi ffxi -"
    "d /srv/ffxi/server/settings/default 0770 ffxi ffxi -"
    "d /srv/ffxi/sql 0755 ffxi ffxi -"
    "d /srv/ffxi/server/cert 0770 ffxi ffxi -"  # Added for certs
  ];

  virtualisation.docker.enable = true;

  systemd.services.docker-ffxi-network = {
    description = "FFXI Docker Network";
    before = [ "docker-ffxi-mysql.service" "docker-ffxi-server.service" "docker-ffxi-admin.service" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "docker.service" ];
    after = [ "network-online.target" "docker.service" ];
    serviceConfig = {
      ExecStart = "/bin/sh -c '${pkgs.docker}/bin/docker network inspect lsb >/dev/null 2>&1 || ${pkgs.docker}/bin/docker network create --driver bridge lsb'";
      RemainAfterExit = "yes";
      Type = "oneshot";
    };
  };

  systemd.services.docker-ffxi-mysql = {
    description = "FFXI MariaDB Container";
    after = [ "docker.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-mysql || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-mysql --network lsb -v /srv/ffxi/mysql:/var/lib/mysql -v /srv/ffxi/sql:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=${config.secrets.ffxi.mysqlRootPassword} -e MYSQL_USER=xiuser -e MYSQL_PASSWORD=${config.secrets.ffxi.mysqlPassword} -e MYSQL_DATABASE=xidb --user 1003:1003 mariadb:latest";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-mysql";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-ffxi-server = {
    description = "FFXI Game Server Container";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-server || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-server --network lsb -v /srv/ffxi/server/log:/server/log -v /srv/ffxi/server/settings:/app/settings -v /srv/ffxi/server/cert/login.key:/app/login.key -v /srv/ffxi/server/cert/login.cert:/app/login.cert -v /srv/ffxi/server/start.sh:/app/start.sh -p 54230:54230/tcp -p 54230:54230/udp -p 54231:54231/tcp -p 54001:54001/tcp -p 54002:54002/tcp -p 51220:51220/tcp -e DB_HOST=ffxi-mysql -e DB_PORT=3306 -e DB_USER=xiuser -e DB_PASS=${config.secrets.ffxi.mysqlPassword} -e DB_NAME=xidb -e ZONE_IP=192.168.1.200 --user 1003:1003 ffxi-custom:latest /app/start.sh";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-server";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-ffxi-admin = {
    description = "FFXI Admin Portal Container";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-admin || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-admin --network lsb -p 8082:8080 -e ADMINER_DEFAULT_SERVER=ffxi-mysql --user 1003:1003 adminer:latest";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-admin";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 54230 54231 54001 54002 51220 8082 ];
  networking.firewall.allowedUDPPorts = [ 54230 ];
}

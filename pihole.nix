{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      pihole = {
        image = "pihole/pihole:latest";
        volumes = [
          "/home/tim/pihole/etc-pihole:/etc/pihole"
          "/home/tim/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
          WEBPASSWORD = config.secrets.pihole.webpassword;
          DNSMASQ_USER = "root";
          FTLCONF_LOCAL_IPV4 = "192.168.1.200,100.104.74.13";
          PIHOLE_DNS_1 = "1.1.1.1";
          PIHOLE_DNS_2 = "1.0.0.1";
          DNSMASQ_LISTENING = "local";
          DNS_BOGUS_PRIV = "true";
          DNS_FQDN_REQUIRED = "true";
          DNSSEC = "true";
          DNSMASQ_CACHE_SIZE = "10000";
          WEBUIBOXEDLAYOUT = "traditional";
          BLOCKING_ENABLED = "true";
          REV_SERVER = "true";
          REV_SERVER_CIDR = "192.168.1.0/24";
          REV_SERVER_TARGET = "192.168.1.1";
          REV_SERVER_DOMAIN = "local";
          DHCP_ACTIVE = "true";
          PIHOLE_SKIP_DHCP_CONFIG = "true";
          LIGHTTPD_CONF = ''
            server.bind = "0.0.0.0"
          '';
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--dns=127.0.0.1"
          "--dns=1.1.1.1"
          "--network=host"
          "--memory=512m"
          "--memory-swap=1g"
          "--cpu-shares=512"
          "--health-cmd=curl -f http://localhost/admin || exit 1"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=5s"
        ];
        ports = [];
      };
    };
  };

  systemd.services.config = {
    description = "Configure Pi-hole DHCP and netboot settings";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    before = [ "docker-container@pihole.service" ];
    requisite = [ "docker.service" ];
    path = [ pkgs.coreutils ];
    script = ''
      mkdir -p /home/tim/pihole/etc-dnsmasq.d
      cat > /home/tim/pihole/etc-dnsmasq.d/02-pihole-dhcp.conf << EOF
      dhcp-range=192.168.1.100,192.168.1.199,24h
      dhcp-option=3,192.168.1.1
      dhcp-boot=ipxe.efi,netboot,192.168.1.111
      dhcp-option=66,192.168.1.111
      EOF
      
      chown -R 0:0 /home/tim/pihole/etc-dnsmasq.d
      chmod 644 /home/tim/pihole/etc-dnsmasq.d/*.conf
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };
}

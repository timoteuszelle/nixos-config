{config, lib, pkgs, ...}: {
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
          # Performance optimizations
          FTLCONF_LOCAL_IPV4 = "192.168.1.200";
          PIHOLE_DNS_1 = "1.1.1.1";
          PIHOLE_DNS_2 = "1.0.0.1";
          DNSMASQ_LISTENING = "local";
          DNS_BOGUS_PRIV = "true";
          DNS_FQDN_REQUIRED = "true";
          DNSSEC = "true";
          DNSMASQ_CACHE_SIZE = "10000";
          WEBUIBOXEDLAYOUT = "traditional";
          BLOCKING_ENABLED = "true";
          # Reverse DNS configuration
          REV_SERVER = "true";
          REV_SERVER_CIDR = "192.168.1.0/24";
          REV_SERVER_TARGET = "192.168.1.1";  # Your router's IP address
          REV_SERVER_DOMAIN = "local";
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
        # Ports commented out since using host network mode
        ports = [
          #"53:53/tcp"
          #"53:53/udp"
          #"67:67/udp"
          #"80:80/tcp"
          #"4711:4711/tcp"
        ];
      };
    };
  };
}

{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      pihole = {
        image = "pihole/pihole:latest";
        volumes = [
          "/home/tim/pihole/etc-pihole:/etc/pihole"
          "/home/tim/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
          # Use the correct TFTP root directory
          "/var/lib/tftp:/var/lib/tftp:ro"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
          WEBPASSWORD = config.secrets.pihole.webpassword;
          DNSMASQ_USER = "root";
          # Performance optimizations
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
          # Reverse DNS configuration
          REV_SERVER = "true";
          REV_SERVER_CIDR = "192.168.1.0/24";
          REV_SERVER_TARGET = "192.168.1.1";
          REV_SERVER_DOMAIN = "local";
          # Add DHCP and netboot configuration
          DHCP_ACTIVE = "true";
          DHCP_START = "192.168.1.100";
          DHCP_END = "192.168.1.199";
          DHCP_ROUTER = "192.168.1.1";
          DHCP_LEASETIME = "24";
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

  # Create the 05-pihole-custom.conf file with proper priority
  system.activationScripts.piholeDnsmasqConf = {
    text = ''
      mkdir -p /home/tim/pihole/etc-dnsmasq.d
      cat > /home/tim/pihole/etc-dnsmasq.d/05-pihole-custom.conf << 'EOF'
      # Enable TFTP server
      enable-tftp
      tftp-root=/var/lib/tftp

      # Configure PXE boot options
      dhcp-match=set:ipxe,175
      dhcp-match=set:bios,option:client-arch,0
      dhcp-boot=tag:bios,/ipxe.kpxe
      dhcp-boot=tag:ipxe,http://192.168.1.111/boot.ipxe

      # Additional DHCP options for PXE boot
      dhcp-option=66,192.168.1.111
      dhcp-option=67,boot.ipxe

      # Logging configuration
      log-queries
      log-dhcp

      # Custom cache settings
      cache-size=10000

      # Interface specific settings
      interface=eth0
      bind-interfaces
      EOF
    '';
    deps = [];
  };
}

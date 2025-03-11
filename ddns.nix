{ config, pkgs, ... }:

let
  ddclientConf = pkgs.writeText "ddclient.conf" ''
    daemon=300
    syslog=yes
    protocol=cloudflare
    use=web, web=ifconfig.me
    login=${config.secrets.cloudflare.email}
    password=${config.secrets.cloudflare.apiToken}
    zone=${config.secrets.cloudflare.myDomainName}
    ${config.secrets.cloudflare.cloudMyDomainName}
  '';
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      ddns = {
        image = "qmcgaw/ddclient:latest";
        autoStart = true;
        volumes = [
          "${ddclientConf}:/etc/ddclient/ddclient.conf"
        ];
        environment = {
          "TZ" = "Europe/Amsterdam";  
        };
      };
    };
  };
}

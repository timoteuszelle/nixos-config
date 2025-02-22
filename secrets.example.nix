{ config, pkgs, lib, ... }:
with lib; {
  options.secrets = mkOption {
    type = types.attrs;
    default = { };
    description = "Secret configuration values.";
  };

  config.secrets = {
    pihole = { 
      webpassword = "your-pihole-password-here"; 
    };
    plex = { 
      claim = "your-plex-claim-token-here"; 
    };
    prometheus = { 
      adminPassword = "your-prometheus-password-here"; 
    };
    qbittorrent = {
      vpnPassword = "your-vpn-password";
      vpnUser = "your-vpn-username";
      vpnIP = "your-vpn-ip";
    };
    tailscale = {
      authkey = "your-tailscale-authkey";
    };   
  };
}

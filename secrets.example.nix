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
    # Example SSH keys structure
    sshKeys = {
      tim = {
        nagoya = "your-nagoya-public-key-here";
        sakai = "your-sakai-public-key-here";
      };
    };
    # Example initial password for netboot
    initialPassword = "your-initial-password-here";
  };
}

{ config, pkgs, ... }:

{
  # SSH Server Configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Network configuration
  networking = {
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = config._module.args.containerIP or "192.168.1.202";
        prefixLength = 24;
      }];
    };
    defaultGateway = config._module.args.containerGateway or "192.168.1.1";
    nameservers = config._module.args.containerNameservers or [ "1.1.1.1" "8.8.8.8" ];
  };

  # Required packages
  environment.systemPackages = with pkgs; [
    openssh
  ];
}

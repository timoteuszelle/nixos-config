{ config, pkgs, userName ? "tim", userUID ? 1000, ... }: {
  # Define user
  users.users.${userName} = {
    isNormalUser = true;
    uid = userUID;
    home = "/home/${userName}";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ "/home/${userName}/.ssh/authorized_keys" ];
  };

  # Sudo without password configuration
  security.sudo.extraRules = [{
    users = [ userName ];
    commands = [{ 
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Core system packages that should be available to the user
  environment.systemPackages = with pkgs; [
    bash
    coreutils
    openssh
    sudo
  ];
}

{ config, pkgs, ... }: {
  # Basic development tools and Git-related packages
  environment.systemPackages = with pkgs; [
    # Core dev tools
    git
    vim
    nano
    tmux
    neovim
    toybox
    
    # Nix formatting tools
    nixfmt-classic
    statix
    deadnix
    nixfmt-rfc-style

    # Basic networking tools
    curl
    wget
    iputils
    netcat
    htop
  ];

  # Project directory bind mount
  containers.hokkaido.bindMounts = {
    "/home/tim/projects" = {
      hostPath = "/home/tim/projects";
      isReadOnly = false;
    };
  };
}

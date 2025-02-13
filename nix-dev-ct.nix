{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      nix-dev = {
        image = "nixpkgs/nix-flakes:latest";
        volumes = [
          "/home/tim/git-workspace:/workspace"
          "/home/tim/git-workspace-persist:/workspace-persist"
          "/home/tim/.ssh:/root/.ssh:ro"
          "/home/tim/.gitconfig:/root/.gitconfig:ro"
          "/nix/store:/nix/store:ro"
          "/nix/var/nix/db:/nix/var/nix/db:ro"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
          LANG = "en_US.UTF-8";
          GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no";
          NIX_CONFIG = "experimental-features = nix-command flakes";
          HOSTNAME = "sapporo";
        };
        extraOptions = [
          "--hostname=sapporo"
          "--memory=4g"
          "--memory-swap=8g"
          "--cpu-shares=1024"
          "--network=host"
          "--dns=100.100.100.100"
          "--add-host=sapporo:127.0.0.1"
        ];
        cmd = [
          "/bin/sh"
          "-c"
          ''
            nix-env -iA \
              nixpkgs.git \
              nixpkgs.gh \
              nixpkgs.toybox \
              nixpkgs.nixfmt \
              nixpkgs.nixpkgs-fmt \
              nixpkgs.neovim \
              nixpkgs.bat \
              nixpkgs.jq \
              nixpkgs.ripgrep \
              nixpkgs.fd \
              nixpkgs.shellcheck \
              nixpkgs.direnv \
              nixpkgs.tailscale \
              && tailscale up --accept-routes --hostname=sapporo \
              && exec sleep infinity
          ''
        ];
      };
    };
  };

  environment.systemPackages = with pkgs;
    [
      (writeScriptBin "reset-nix-dev" ''
        #!${stdenv.shell}
        set -e
        echo "Stopping nix-dev container..."
        systemctl stop docker-nix-dev
        echo "Removing nix-dev container..."
        docker rm -f nix-dev || true
        echo "Cleaning temporary workspace..."
        rm -rf /home/tim/git-workspace/*
        echo "Starting fresh nix-dev container..."
        systemctl start docker-nix-dev
        echo "Container reset complete!"
      '')
    ];
}

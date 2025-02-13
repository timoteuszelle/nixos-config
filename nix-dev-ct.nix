{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      sapporo = {
        image = "nixos/nix:latest";
        volumes = [
          "/home/tim/git-workspace:/workspace"
          "/home/tim/git-workspace-persist:/workspace-persist"
          "/home/tim/.ssh:/root/.ssh:ro"
          "/home/tim/.gitconfig:/root/.gitconfig:ro"
          "/nix/store:/nix/store"
          "/nix/var/nix/db:/nix/var/nix/db"
          "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket"
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
        cmd = let
          containerPackages = with pkgs; [
            # Basic utilities
            coreutils
            bash
            git
            gh
            toybox
            
            # Development tools
            #nixfmt
	    nixfmt-rfc-style  # if you want to use the new RFC 166-style formatter
            nixpkgs-fmt
            neovim
            
            # Search and file tools
            bat
            jq
            ripgrep
            fd
            
            # Development helpers
            shellcheck
            direnv
          ];
          packagePaths = lib.makeBinPath containerPackages;
        in [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            # Part 1: Initialize environment
            export PATH="${packagePaths}:$PATH"
            mkdir -p /etc/nix
            echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf

            # Wait for nix-daemon to be ready
            timeout=30
            while [ $timeout -gt 0 ]; do
              if nix-env --version >/dev/null 2>&1; then
                break
              fi
              echo "Waiting for nix-daemon to be ready..."
              sleep 1
              timeout=$((timeout - 1))
            done

            if [ $timeout -eq 0 ]; then
              echo "Timeout waiting for nix-daemon"
              exit 1
            fi

            # Keep container running
            echo "Initialization complete, starting sleep loop"
            exec sleep infinity
          ''
        ];
      };
    };
  };

  environment.systemPackages = with pkgs;
    [
      (writeScriptBin "reset-sapporo" ''
        #!${stdenv.shell}
        set -e
        echo "Stopping sapporo container..."
        systemctl stop docker-sapporo
        echo "Removing sapporo container..."
        docker rm -f sapporo || true
        echo "Cleaning temporary workspace..."
        rm -rf /home/tim/git-workspace/*
        echo "Starting fresh sapporo container..."
        systemctl start docker-sapporo
        echo "Container reset complete!"
      '')
    ];
}

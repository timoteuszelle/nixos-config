{ config, lib, pkgs, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      sapporo = {
        image = "nixos/nix:latest";  # Use this as base image
        hostname = "sapporo";
        #cmd = [ "/bin/sh" ];
	cmd = [ "/root/.nix-profile/bin/bash" "-c" "/run/current-system/sw/bin/sshd -D" ];
        ports = [
          "2222:22"
        ];
        volumes = [
          "/home/tim/git-workspace:/workspace"
          "/home/tim/git-workspace-persist:/workspace-persist"
          "/home/tim/.ssh/id_ed25519.pub:/root/.ssh/authorized_keys:ro"
          "/home/tim/.gitconfig:/root/.gitconfig:ro"
          "/home/tim/.sapporo/ssh:/etc/ssh"
          "/nix/store:/nix/store"
          "/nix/var/nix/db:/nix/var/nix/db"
          "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket"
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
          "--memory=4g"
          "--memory-swap=8g"
          "--cpu-shares=1024"
          "--dns=100.100.100.100"
          "--add-host=sapporo:127.0.0.1"
        ];
      };
    };
  };

  # Keep your existing reset script
  environment.systemPackages = with pkgs; [
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

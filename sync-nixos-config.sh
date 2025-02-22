#!/bin/bash
# Sync individual configuration files
cp /etc/nixos/{configuration.nix,hardware-configuration.nix,homeassistant.nix,ollama.nix,pihole.nix,plex.nix,prometheus.nix,qbittorrent.nix,portainer.nix,hokkaido.nix,netboot.nix} ~/nixos-config/

# Sync modules directory
mkdir -p /etc/nixos/modules
cp -r /etc/nixos/modules/* ~/nixos-config/modules/

echo "NixOS configuration files synced successfully!"

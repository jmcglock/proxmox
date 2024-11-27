#!/bin/bash

# Update and Upgrade Your Server
# Script to safely update and upgrade a Proxmox system

# Exit on any error
set -e

echo "Starting system update and upgrade process..."

# Function to handle errors
error_handler() {
  echo "Error occurred in script at line: $1"
  exit 1
}

trap 'error_handler ${LINENO}' ERR

# Update package lists
echo "Updating package lists..."
apt-get update || {
  echo "Failed to update package lists"
  exit 1
}

# Upgrade packages
echo "Upgrading packages..."
apt-get upgrade -y || {
  echo "Failed to upgrade packages"
  exit 1
}

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
  echo "A system reboot is required!"
  read -p "Would you like to reboot now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    shutdown -r now
  fi
else
  echo "No reboot required."
fi

echo "Update and upgrade completed successfully!"
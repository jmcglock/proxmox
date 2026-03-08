#!/bin/bash
set -euo pipefail
# This script will configure the apt sources for debian bullseye in Proxmox (PVE 7.x - legacy/EOL)

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Backup existing sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup-$(date +%Y%m%d-%H%M%S)
echo "Backed up /etc/apt/sources.list"

# Configure apt sources
echo "deb http://ftp.debian.org/debian bullseye main contrib" > /etc/apt/sources.list
echo "deb http://ftp.debian.org/debian bullseye-updates main contrib" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bullseye-security main contrib" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" >> /etc/apt/sources.list

# Comment out PVE enterprise repository
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
    sed -i 's/^deb/# deb/' /etc/apt/sources.list.d/pve-enterprise.list
    echo "Disabled pve-enterprise.list"
fi

# Comment out Ceph enterprise repository (if present)
if [ -f /etc/apt/sources.list.d/ceph.list ]; then
    sed -i 's/^deb/# deb/' /etc/apt/sources.list.d/ceph.list
    echo "Disabled ceph.list"
fi

# Update package lists
apt-get update
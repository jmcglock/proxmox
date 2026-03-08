#!/bin/bash
set -euo pipefail
# This script will configure the apt sources for debian bookworm in Proxmox (PVE 8.x)

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Backup existing sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup-$(date +%Y%m%d-%H%M%S)
echo "Backed up /etc/apt/sources.list"

# Configure apt sources
echo "deb http://ftp.debian.org/debian bookworm main contrib" > /etc/apt/sources.list
echo "deb http://ftp.debian.org/debian bookworm-updates main contrib" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list

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
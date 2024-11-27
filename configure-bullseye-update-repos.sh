#!/bin/bash
# This script will configure the apt sources for debian bullseye in Proxmox

# Configure apt sources
echo "deb http://ftp.debian.org/debian bullseye main contrib" > /etc/apt/sources.list
echo "deb http://ftp.debian.org/debian bullseye-updates main contrib" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bullseye-security main contrib" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" >> /etc/apt/sources.list

# Comment out enterprise repository
sed -i 's/^deb/# deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Update package lists
apt update -y
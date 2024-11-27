#!/bin/bash

# Script to resize Proxmox local storage by removing local-lvm and extending local storage to use the full available space
# IMPORTANT: This script should be run directly on the Proxmox host
# WARNING: This will delete local-lvm storage. Backup any important data first!

# Exit on any error
set -e

# Function to display error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if user is root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_exit "This script must be run as root"
    fi
}

# Function to check if running on Proxmox
check_proxmox() {
    if [ ! -f "/etc/pve/storage.cfg" ]; then
        error_exit "This script must be run on a Proxmox server"
    fi
}

# Function to check if local-lvm exists
check_local_lvm() {
    if ! lvs | grep -q "data"; then
        error_exit "local-lvm (pve/data) not found"
    fi
}

# Function to check if there are running VMs or containers
check_running_instances() {
    local running_vms=$(qm list | grep "running" | wc -l)
    local running_cts=$(pct list | grep "running" | wc -l)
    
    if [ "$running_vms" -gt 0 ] || [ "$running_cts" -gt 0 ]; then
        error_exit "There are running VMs or containers. Please stop all instances before proceeding."
    fi
}

# Function to backup storage configuration
backup_storage_config() {
    cp /etc/pve/storage.cfg /etc/pve/storage.cfg.backup-$(date +%Y%m%d-%H%M%S)
    echo "Storage configuration backed up"
}

# Main execution starts here
echo "Proxmox Local Storage Resize Script"
echo "==================================="
echo "WARNING: This script will:"
echo "1. Delete the local-lvm storage"
echo "2. Resize the root logical volume to use all available space"
echo "3. Expand the filesystem to use the new space"
echo ""
echo "Make sure you have backed up any important data!"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled"
    exit 1
fi

# Run preliminary checks
echo "Running preliminary checks..."
check_root
check_proxmox
check_local_lvm
check_running_instances

# Backup storage configuration
echo "Backing up storage configuration..."
backup_storage_config

# Remove local-lvm from Proxmox configuration
echo "Removing local-lvm from Proxmox configuration..."
pvesm remove local-lvm || error_exit "Failed to remove local-lvm from Proxmox configuration"

# Remove the data logical volume
echo "Removing data logical volume..."
lvremove -f /dev/pve/data || error_exit "Failed to remove data logical volume"

# Extend root logical volume
echo "Extending root logical volume..."
lvresize -l +100%FREE /dev/pve/root || error_exit "Failed to resize root logical volume"

# Resize the filesystem
echo "Resizing the filesystem..."
resize2fs /dev/mapper/pve-root || error_exit "Failed to resize filesystem"

# Verify the new size
echo "Verifying new storage size..."
df -h /dev/mapper/pve-root

echo ""
echo "Storage resize completed successfully!"
echo "New storage size for 'local' is shown above"
echo ""
echo "NOTE: You may need to reload the Proxmox web interface to see the changes"
#!/bin/bash

# Script to enable IOMMU for PCI passthrough in Proxmox
# This script must be run as root

# Exit on any error
set -e

# Function to display error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    error_exit "This script must be run as root"
fi

echo "Enabling IOMMU for PCI passthrough..."

# Backup GRUB configuration
echo "Creating backup of GRUB configuration..."
cp /etc/default/grub /etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)

# Modify GRUB configuration
echo "Modifying GRUB configuration..."
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
    # Replace existing line
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"/' /etc/default/grub
else
    # Add new line if it doesn't exist
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"' >> /etc/default/grub
fi

# Update GRUB
echo "Updating GRUB..."
update-grub || error_exit "Failed to update GRUB"

# Backup modules file
echo "Creating backup of modules configuration..."
cp /etc/modules /etc/modules.backup-$(date +%Y%m%d-%H%M%S)

# Add required modules
echo "Adding VFIO modules..."
modules="vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd"

# Check if modules are already present and add only if missing
for module in $modules; do
    if ! grep -q "^$module$" /etc/modules; then
        echo "$module" >> /etc/modules
    fi
done

# Update initramfs
echo "Updating initramfs..."
update-initramfs -u -k all || error_exit "Failed to update initramfs"

echo "IOMMU configuration completed successfully!"
echo "The system needs to be rebooted for changes to take effect."
echo ""
read -p "Would you like to reboot now? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Rebooting system..."
    reboot
else
    echo "Please remember to reboot your system manually for changes to take effect."
fi
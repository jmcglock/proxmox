#!/bin/bash

# Script to create a VM in Proxmox
# Usage: ./create_vm.sh <VM_ID> <VM_NAME> [OPTIONS]

# Exit on any error
set -e

# Function to display usage
usage() {
    echo "Usage: $0 <VM_ID> <VM_NAME> [OPTIONS]"
    echo "Options:"
    echo "  --memory <MB>     Memory size in MB (default: 8192)"
    echo "  --cores <COUNT>   Number of CPU cores (default: 8)"
    echo "  --storage <NAME>  Storage pool name (required)"
    echo "  --template <ID>   Template ID to clone from (required)"
    echo "  --bridge <NAME>   Network bridge (default: vmbr0)"
    echo "Example:"
    echo "  $0 100 my-vm --storage local-lvm --template 9000"
    exit 1
}

# Check for minimum required arguments
if [ $# -lt 2 ]; then
    echo "Error: VM ID and NAME are required"
    usage
fi

# Assign required parameters
VM_ID="$1"
VM_NAME="$2"
shift 2

# Default values
VM_MEMORY="8192"
VM_CPU_CORES="8"
VM_BRIDGE="vmbr0"
VM_STORAGE=""
VM_TEMPLATE=""

# Parse optional parameters
while [ $# -gt 0 ]; do
    case "$1" in
        --memory)
            VM_MEMORY="$2"
            shift 2
            ;;
        --cores)
            VM_CPU_CORES="$2"
            shift 2
            ;;
        --storage)
            VM_STORAGE="$2"
            shift 2
            ;;
        --template)
            VM_TEMPLATE="$2"
            shift 2
            ;;
        --bridge)
            VM_BRIDGE="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown parameter '$1'"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$VM_STORAGE" ]; then
    echo "Error: Storage pool name is required (--storage)"
    usage
fi

if [ -z "$VM_TEMPLATE" ]; then
    echo "Error: Template ID is required (--template)"
    usage
fi

# Validate VM_ID is a number
if ! [[ "$VM_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: VM ID must be a number"
    exit 1
fi

# Function to check if VM ID already exists
check_vm_exists() {
    if qm status "$VM_ID" >/dev/null 2>&1; then
        echo "Error: VM ID $VM_ID already exists"
        exit 1
    fi
}

# Main execution
echo "Creating VM with the following configuration:"
echo "VM ID: $VM_ID"
echo "VM Name: $VM_NAME"
echo "Memory: $VM_MEMORY MB"
echo "CPU Cores: $VM_CPU_CORES"
echo "Storage: $VM_STORAGE"
echo "Template: $VM_TEMPLATE"
echo "Network Bridge: $VM_BRIDGE"

# Check if VM already exists
check_vm_exists

# Create the VM
echo "Creating VM..."
qm create "$VM_ID" \
    --name "$VM_NAME" \
    --memory "$VM_MEMORY" \
    --cores "$VM_CPU_CORES" \
    --net0 "virtio,bridge=$VM_BRIDGE" \
    --serial0 socket \
    --vga serial0 \
    --parallel0 none \
    --storage "$VM_STORAGE" \
    --template "$VM_TEMPLATE"

# Set the boot order
echo "Setting boot order..."
qm set "$VM_ID" --boot c --bootdisk scsi0

echo "VM creation completed successfully!"
echo "You can start the VM with: qm start $VM_ID"
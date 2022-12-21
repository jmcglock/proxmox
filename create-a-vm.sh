#!/bin/bash

# Set variables for the new VM
vm_name="<NAME>"
vm_template="local:vztmpl/ubuntu-22.04-standard_20.04-1_amd64.tar.gz"
vm_memory="8192"
vm_cpu_cores="8"
vm_storage="<STORAGE>"

# Create the VM
qm create $vm_name --memory $vm_memory --cores $vm_cpu_cores --net0 virtio,bridge=vmbr0 --serial0 socket --vga serial0 --parallel0 none --hostpci0 00:01.0 --storage $vm_storage --template $vm_template

# Set the boot order to boot from the hard drive first
qm set $vm_name --boot c --bootdisk scsi0

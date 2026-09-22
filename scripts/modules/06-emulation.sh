#!/bin/bash

# Start and enable the libvirt daemon
sudo systemctl enable --now libvirtd

# Add the current user to the libvirt group
sudo usermod -aG libvirt "$USER"

# Use 'sg' to run the virsh commands under the newly added 'libvirt' group
sg libvirt -c "virsh net-autostart default"
sg libvirt -c "virsh net-start default"

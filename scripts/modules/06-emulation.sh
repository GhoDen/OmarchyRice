#!/bin/bash

# Start and enable the libvirt daemon

sudo systemctl enable --now libvirtd

# Add the current user to the libvirt group

sudo usermod -aG libvirt "$USER"

# Refresh the current user's group memberships for these commands using sudo -g

if ! sudo -g libvirt virsh net-info default >/dev/null 2>&1; then
  sudo -g libvirt virsh net-define /dev/stdin <<'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
fi

sudo -g libvirt virsh net-start default || true
sudo -g libvirt virsh net-autostart default

#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# KVM Installation
install() {
    echo "Installing KVM"
    sudo yum install qemu-kvm qemu-img virt-manager libvirt-client libvirt libvirt-python python-virtinst virt-install virt-viewer bridge-utils vim -y
    echo "Starting Service"
    sudo systemctl start libvirtd && sudo systemctl enable libvirtd
}
# Network Bridge
bridge() {
    echo "Configuring Interfaces"
    sudo rm /etc/sysconfig/network-scripts/ifcfg-eth0
    sudo cat << STOP > /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
DEVICE=eth0
ONBOOT=yes
BRIDGE=br0
STOP
    sudo cat << STOP > /etc/sysconfig/network-scripts/ifcfg-br0
TYPE=Bridge
DEVICE=br0
BOOTPROTO=dhcp
ONBOOT=yes
STOP
}
restart() {
    echo "Restarting Network"
    sudo systemctl restart network && ifdown eth0; ifup eth0
}
# Image Retrieval
centos() {
    echo "Downloading Image"
    cd /var/lib/libvirt/boot/
    sudo wget --progress=bar:force https://buildlogs.centos.org/centos/7/isos/x86_64/CentOS-7.0-1406-x86_64-Minimal.iso
}
# Configuring VM
virtual() {
    echo "Creating VM"
    sudo virt-install \
    --virt-type kvm \
    --name centos7 \
    --ram 2048 \
    --vcpus 2 \
    --os-type linux \
    --os-variant centos7 \
    --cdrom /var/lib/libvirt/boot/CentOS-7.0-1406-x86_64-Minimal.iso \
    --network bridge=virbr0 \
    --graphics vnc,port=5999 \
    --console pty,target_type=serial \
    --disk /var/lib/libvirt/images/centos7.qcow2,size=5,format=qcow2
    exit
}
# Executing Functions
install
bridge
restart
centos
virtual

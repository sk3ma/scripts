#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo -e "You must be root to run this script."
  exit
fi
# KVM Installation
install() {
    echo "Installing KVM"
    sudo yum install qemu-kvm qemu-img virt-manager libvirt-client libvirt libvirt-python python-virtinst virt-install virt-viewer bridge-utils -y
    echo "Starting Service"
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
}
# Network Bridge
bridge() {
    echo "Configuring Interfaces"
    sudo rm /etc/sysconfig/network-scripts/ifcfg-eth0
    sudo cat << STOP > /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
BRIDGE=br0
STOP
    sudo cat << STOP > /etc/sysconfig/network-scripts/ifcfg-br0
TYPE=Bridge
DEVICE=br0
BOOTPROTO=static
IPADDR=192.168.33.30
NETMASK=255.255.255.0
GATEWAY=192.168.33.1
ONBOOT=yes
STOP
}
restart() {
    echo "Restarting Network"
    sudo systemctl restart network
    brctl show
}
# ISO Retrieval
centos() {
    echo "Downloading ISO"
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
    --vcpus 1 \
    --os-type linux \
    --os-variant centos7 \
    --cdrom /var/lib/libvirt/boot/CentOS-7.0-1406-x86_64-Minimal.iso \
    --network bridge=virbr0 \
    --graphics vnc \
    --disk /var/lib/libvirt/images/centos7.qcow2,size=5,format=qcow2
    exit
}
# Executing Functions
install
bridge
restart
centos
virtual

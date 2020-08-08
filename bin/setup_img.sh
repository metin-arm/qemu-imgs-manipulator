#!/bin/bash
set -eu

ARCH=$1
IMG=$2
MNT=$3

if [[ "$ARCH" == "x86_64" || "$ARCH" == "i386" ]]; then
	EXTEND_REPO_CMD="echo \"deb http://archive.ubuntu.com/ubuntu bionic universe\" >> /etc/apt/sources.list"
	ARCH_PACKAGES="likwid"
	ARCH_ROOT_HDA="/dev/sda"
else
	EXTEND_REPO_CMD="echo \"deb http://deb.debian.org/debian stable universe\" >> /etc/apt/sources.list"
	ARCH_PACKAGES=""
	ARCH_ROOT_HDA="/dev/vda"
fi

# chroot into the image
cat << EOF | $(dirname $0)/chroot_enter.sh $IMG $MNT bash

set -eux

# First make sure root has no password
passwd -d root

# Now add a user that matches the current user ID
adduser --disabled-password --gecos "" $(whoami)
# No password login
passwd -d $(whoami)
# Make admin and sudoer
usermod -G sudo,adm $(whoami)

# Add more ubuntu repo to allow more software to be installed
$EXTEND_REPO_CMD

# Make sure apt is up-to-date after adding the repo
apt update

# Make sure our rootfs is mounted correctly, or it'd be readonly
echo "$ARCH_ROOT_HDA	/	auto	defaults	0	1" > /etc/fstab

# Install some software we usually need
apt install -y vim trace-cmd hwloc sudo $ARCH_PACKAGES

# Install network and sshd packagers
apt install -y net-tools ifupdown network-manager openssh-server

sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/UsePAM.*/UsePAM no/' /etc/ssh/sshd_config

echo "auto enp0s3" >> /etc/network/interfaces
echo "iface enp0s3 inet dhcp" >> /etc/network/interfaces

# exit chroot
exit

EOF

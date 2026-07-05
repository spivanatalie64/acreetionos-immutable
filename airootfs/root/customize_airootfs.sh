#!/usr/bin/env bash
# customize_airootfs.sh — runs inside the build chroot before squashing
# Use this to set up the live environment for your edition.

set -e

# Set up locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Enable services
systemctl enable NetworkManager.service
systemctl enable sshd.service
systemctl enable choose-mirror.service
systemctl enable pacman-init.service
systemctl enable reflector.service
systemctl enable chronyd.service

# Set root password (empty by default — change for production)
passwd -d root

# Create /etc/hosts
cat > /etc/hosts <<- EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   acreetionos-live.localdomain acreetionos-live
EOF

echo "customize_airootfs.sh: done"

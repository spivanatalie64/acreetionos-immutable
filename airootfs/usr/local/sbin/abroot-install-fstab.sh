#!/bin/bash
# Calamares shellprocess (chroot): write the canonical immutable /etc/fstab
# and the installed-system mkinitcpio.conf (with the abroot hook).
set -euo pipefail

C_G="\033[1;32m"; C_R="\033[1;31m"; C_0="\033[0m"
msg() { printf "${C_G}==>${C_0} %s\n" "$*"; }
die() { printf "${C_R}==> ERROR:${C_0} %s\n" "$*" >&2; exit 1; }

get() { sed -n "s/^$1=//p" /etc/abroot.conf | head -n1; }
[[ -r /etc/abroot.conf ]] || die "/etc/abroot.conf missing - abroot-install-setup must run first"
A_PUID=$(get SLOTA_PARTUUID)
D_PUID=$(get DATA_PARTUUID)
E_PUID=$(get ESP_PARTUUID)
[[ -n ${A_PUID} && -n ${D_PUID} && -n ${E_PUID} ]] || die "incomplete abroot.conf"

msg "Writing /etc/fstab..."
cat >/etc/fstab <<EOF
# /etc/fstab: static file system information - AcreetionOS Immutable.
#
# <device>            <mountpoint>  <fs>    <options>                            <dump> <pass>
PARTUUID=${A_PUID}    /             ext4    ro,noatime                           0      1
PARTUUID=${D_PUID}    /mnt/.data    ext4    rw,noatime                           0      2
/mnt/.data/home       /home         none    bind                                 0      0
/mnt/.data/var        /var          none    bind                                 0      0
PARTUUID=${E_PUID}    /efi          vfat    rw,noatime,fmask=0077,dmask=0077     0      2
EOF

msg "Writing /etc/mkinitcpio.conf..."
cat >/etc/mkinitcpio.conf <<'EOF'
# mkinitcpio configuration - AcreetionOS Immutable.
# The 'abroot' hook mounts the shared data partition and overlays a persistent
# per-slot writable /etc onto the read-only root. It must stay after 'filesystems'.

MODULES=(overlay nvme nvme_core vmd ahci libahci dm_mod loop)
BINARIES=()
FILES=()

HOOKS=(base udev autodetect modconf kms keyboard keymap block filesystems abroot)

#COMPRESSION="zstd"
#COMPRESSION_OPTIONS=()
EOF
rm -f /etc/mkinitcpio.conf.d/archiso.conf

msg "Regenerating initramfs with abroot hook..."
mkinitcpio -P || die "mkinitcpio -P failed - installed system would not boot"

mkdir -p /etc/pacman.d/hooks
cat >/etc/pacman.d/hooks/abroot-pacnew-notice.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /usr/bin/sh -c 'find /etc -name "*.pacnew" 2>/dev/null | head -5 > /var/lib/abroot/pacnew-list || true'
EOF
mkdir -p /var/lib/abroot

msg "fstab + initramfs config written."

#!/bin/bash
# Calamares shellprocess (chroot): discover A/B slots, write /etc/abroot.conf,
# prepare the shared data partition.
#
# At this point Calamares has already:
#   * partitioned the disk (ESP, two equal ext4 slots, data partition)
#   * mounted / (slot A, rw), /efi and /mnt/.data
#
# Slot identification heuristic (independent of partition numbering):
#   * ESP   = whatever is mounted at /efi
#   * data  = whatever is mounted at /mnt/.data
#   * A     = whatever is mounted at /
#   * B     = ext4 on the SAME disk as A, unmounted, same size as A
set -euo pipefail

C_G="\033[1;32m"; C_R="\033[1;31m"; C_0="\033[0m"
msg() { printf "${C_G}==>${C_0} %s\n" "$*"; }
die() { printf "${C_R}==> ERROR:${C_0} %s\n" "$*" >&2; exit 1; }

part_info() {
	# part_info <mount-or-device> -> "<partuuid> <size-bytes>"
	local dev="$1"
	mountpoint -q "$dev" && dev=$(findmnt -nro SOURCE "$dev")
	[[ -b ${dev} ]] || die "not a block device: $1"
	lsblk -rno PARTUUID,SIZE "${dev}" | head -n1
}

msg "Identifying A/B layout..."

read -r A_PUID A_SIZE <<<"$(part_info /)"
read -r D_PUID _ <<<"$(part_info /mnt/.data)"
read -r E_PUID _ <<<"$(part_info /efi)"

[[ -n ${A_PUID} && ${A_PUID} != "null" ]] || die "could not resolve PARTUUID of slot A"
[[ -n ${D_PUID} && ${D_PUID} != "null" ]] || die "could not resolve PARTUUID of data partition"
[[ -n ${E_PUID} && ${E_PUID} != "null" ]] || die "could not resolve PARTUUID of the ESP"

# Find slot B: ext4, unmounted, same disk as A, prefer identical size to A.
A_DEV=$(findmnt -nro SOURCE /)
A_DISK=$(lsblk -rno PKNAME "$(lsblk -rno PATH | grep -Fx "${A_DEV}" | head -n1)" 2>/dev/null || true)
[[ -n ${A_DISK} ]] || die "could not determine parent disk of slot A"

B_PUID=""
while read -r puid pname fstype size pkname mnt; do
	[[ ${fstype} == ext4 ]] || continue
	[[ ${pkname} == "${A_DISK}" ]] || continue
	[[ -z ${mnt} || ${mnt} == "" ]] || continue
	[[ ${pname} == "${A_DEV}" ]] && continue
	if [[ ${size} == "${A_SIZE}" ]]; then B_PUID=${puid}; break; fi
	B_PUID=${B_PUID:-${puid}}
done < <(lsblk -rno PARTUUID,PATH,FSTYPE,SIZE,PKNAME,MOUNTPOINT)

[[ -n ${B_PUID} && ${B_PUID} != "null" ]] || die "could not identify standby slot B"

msg "Layout resolved:"
echo "  slot A : ${A_PUID}"
echo "  slot B : ${B_PUID}"
echo "  data   : ${D_PUID}"
echo "  ESP    : ${E_PUID}"

cat >/etc/abroot.conf <<EOF
# Written by abroot-install-setup during installation.
# AcreetionOS Immutable partition map (see abroot(8)).
SLOTA_PARTUUID=${A_PUID}
SLOTB_PARTUUID=${B_PUID}
DATA_PARTUUID=${D_PUID}
ESP_PARTUUID=${E_PUID}
EOF
chmod 644 /etc/abroot.conf

msg "Preparing shared data store..."
mkdir -p /mnt/.data/abroot/state
mkdir -p /mnt/.data/abroot/etc-A/upper /mnt/.data/abroot/etc-A/work
mkdir -p /mnt/.data/abroot/etc-B/upper /mnt/.data/abroot/etc-B/work
mkdir -p /mnt/.data/home
mkdir -p /mnt/.data/var

# Move the freshly-unpacked /var into the shared store so the system boots
# complete (dbus, journal, pacman db cache, ...). Same for /home. Bind them
# back immediately so every later install step sees the final layout.
cp -a /var/. /mnt/.data/var/
rm -rf /var/* && mkdir -p /var
mount --bind /mnt/.data/var /var
mkdir -p /home /mnt/.data/home
chmod 1777 /mnt/.data/home 2>/dev/null || chmod 755 /mnt/.data/home
mount --bind /mnt/.data/home /home

# Slot A was successfully written - mark ready so it can serve as a rollback target.
date -Is >/mnt/.data/abroot/state/A.ok

msg "abroot.conf and data store ready."

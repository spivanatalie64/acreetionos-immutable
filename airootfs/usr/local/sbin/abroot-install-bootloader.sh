#!/bin/bash
# Calamares shellprocess (chroot): install GRUB to the ESP and write the
# self-contained A/B boot configuration.
#
# Boot flow (ESP grub.cfg):
#   * loads /efi/acr/env  (active_slot, pending_slot, tries_left)
#   * default entry = committed active slot
#   * a pending slot boots with a decreasing tries counter; when the counter
#     hits zero without abroot-commit.service promoting it, GRUB falls back
#     to the active slot automatically
#   * abroot rollback simply flips active_slot in the env file
set -euo pipefail

C_G="\033[1;32m"; C_R="\033[1;31m"; C_0="\033[0m"
msg() { printf "${C_G}==>${C_0} %s\n" "$*"; }
die() { printf "${C_R}==> ERROR:${C_0} %s\n" "$*" >&2; exit 1; }

get() { sed -n "s/^$1=//p" /etc/abroot.conf | head -n1; }
[[ -r /etc/abroot.conf ]] || die "/etc/abroot.conf missing - run abroot-install-setup first"

A_PUID=$(get SLOTA_PARTUUID)
B_PUID=$(get SLOTB_PARTUUID)

# Resolve filesystem UUIDs of both slots for GRUB's search command.
uuid_for_partuuid() {
	local dev
	dev=$(findfs "PARTUUID=$1") || die "partition $1 not found"
	blkid -s UUID -o value "${dev}" || die "no filesystem UUID on ${dev}"
}
A_FUUID=$(uuid_for_partuuid "${A_PUID}")
B_FUUID=$(uuid_for_partuuid "${B_PUID}")

msg "Installing GRUB (removable/fallback path, no NVRAM dependency)..."
mkdir -p /efi
mountpoint -q /efi || mount "PARTUUID=$(get ESP_PARTUUID)" /efi

grub-install --target=x86_64-efi \
	--efi-directory=/efi \
	--bootloader-id=ACREETIONOS-IMMUTABLE \
	--boot-directory=/boot \
	--removable \
	--no-nvram || die "grub-install failed"

msg "Writing A/B boot logic to ESP..."
mkdir -p /efi/acr
: >/efi/acr/env
grub-editenv /efi/acr/env create
grub-editenv /efi/acr/env set active_slot=A
# Also keep a copy of the partition map next to the env file for rescue tools.
cp /etc/abroot.conf /efi/acr/partitions.conf

GRUB_AB_CFG=$(cat <<EOF
# AcreetionOS Immutable A/B boot configuration.
# This file replaces grub-install's generated stub. It is self-contained:
# kernels are loaded directly from whichever slot is selected.

insmod part_gpt
insmod fat
insmod ext2
insmod search_fs_uuid
insmod search_fs_file
insmod loadenv
insmod test
insmod echo
insmod sleep

set timeout=5

# Locate the ESP by the presence of the environment file.
search --no-floppy --file --set=esp /acr/env
load_env -f (\${esp})/acr/env

if [ "\${active_slot}" != "B" ]; then
    set active=A
else
    set active=B
fi

set def="slot_\${active}"

if [ "\${pending_slot}" = "A" -o "\${pending_slot}" = "B" ]; then
    if [ -z "\${tries_left}" ]; then
        set tries_left=3
        save_env tries_left
    fi
    if [ "\${tries_left}" = "0" ]; then
        echo "Pending slot \${pending_slot} failed to boot \${tries_left} times left - falling back to slot \${active}."
        sleep 4
        unset pending_slot
        unset tries_left
        save_env pending_slot
        save_env tries_left
    else
        set tries_left=\$((tries_left-1))
        save_env tries_left
        echo "Booting PENDING update in slot \${pending_slot} ..."
        sleep 2
        set def="slot_\${pending_slot}"
    fi
fi

set default="\${def}"
export default

menuentry 'AcreetionOS Immutable (Slot A)' --id=slot_A {
    search --no-floppy --fs-uuid --set=root ${A_FUUID}
    linux /boot/vmlinuz-linux root=PARTUUID=${A_PUID} ro abroot.slot=A quiet splash loglevel=3 vt.global_cursor_default=0 nvme_core.default_ps_max_latency_us=0 i915.force_probe=* i915.enable_guc=3 i915.enable_fbc=1
    initrd /boot/initramfs-linux.img
}

menuentry 'AcreetionOS Immutable (Slot B)' --id=slot_B {
    search --no-floppy --fs-uuid --set=root ${B_FUUID}
    linux /boot/vmlinuz-linux root=PARTUUID=${B_PUID} ro abroot.slot=B quiet splash loglevel=3 vt.global_cursor_default=0 nvme_core.default_ps_max_latency_us=0 i915.force_probe=* i915.enable_guc=3 i915.enable_fbc=1
    initrd /boot/initramfs-linux.img
}

menuentry 'AcreetionOS Immutable (Slot A - verbose)' --id=slot_A_verbose {
    search --no-floppy --fs-uuid --set=root ${A_FUUID}
    linux /boot/vmlinuz-linux root=PARTUUID=${A_PUID} ro abroot.slot=A
    initrd /boot/initramfs-linux.img
}

menuentry 'AcreetionOS Immutable (Slot B - verbose)' --id=slot_B_verbose {
    search --no-floppy --fs-uuid --set=root ${B_FUUID}
    linux /boot/vmlinuz-linux root=PARTUUID=${B_PUID} ro abroot.slot=B
    initrd /boot/initramfs-linux.img
}

menuentry 'System restart' --id=restart {
    reboot
}

menuentry 'Firmware setup' --id=fwsetup {
    fwsetup
}
EOF
)

# Replace the stub grub.cfg that grub-install generated (fallback + named path).
for cfg in /efi/EFI/BOOT/grub.cfg /efi/EFI/ACREETIONOS-IMMUTABLE/grub.cfg; do
	[[ -d $(dirname "${cfg}") ]] || continue
	printf '%s\n' "${GRUB_AB_CFG}" >"${cfg}"
done

msg "GRUB installed. Slot A is the committed default."

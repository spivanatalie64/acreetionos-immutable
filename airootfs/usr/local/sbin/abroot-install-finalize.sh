#!/bin/bash
# Calamares shellprocess (chroot): final system polish for AcreetionOS Immutable.
# Replaces the mutable edition's postinstall.sh pipeline.
set -euo pipefail

C_G="\033[1;32m"; C_Y="\033[1;33m"; C_0="\033[0m"
msg() { printf "${C_G}==>${C_0} %s\n" "$*"; }
warn() { printf "${C_Y}==> WARNING:${C_0} %s\n" "$*"; }

msg "Applying desktop configuration..."

# Wallpapers into place
mkdir -p /usr/share/backgrounds
if [[ -d /backgrounds ]]; then
	cp -a /backgrounds/. /usr/share/backgrounds/
fi

# Per-user Cinnamon configuration: apply to /etc/skel AND to any user Calamares
# already created (the users module runs before this job).
apply_to_home() {
	local home="$1"
	[[ -d ${home} ]] || return 0
	mkdir -p "${home}/.config"
	if [[ -d /cinnamon-configs/cinnamon-stuff/.config ]]; then
		cp -a /cinnamon-configs/cinnamon-stuff/.config/. "${home}/.config/"
	fi
	mkdir -p "${home}/.config/autostart"
	if [[ -f /cinnamon-configs/dd.desktop ]]; then
		sed 's|Exec=/usr/bin/dd.sh|Exec=/usr/local/bin/immutable-user-setup.sh|' \
			/cinnamon-configs/dd.desktop >"${home}/.config/autostart/dd-immutable.desktop"
	fi
	for f in .bashrc .nanorc AcreetionOS.txt; do
		[[ -f "/cinnamon-configs/${f}" ]] && cp "/cinnamon-configs/${f}" "${home}/"
	done
}

apply_to_home /etc/skel
while IFS=: read -r _ _ uid _ _ home _; do
	[[ ${uid} -ge 1000 && ${home} == /home/* ]] || continue
	apply_to_home "${home}"
	owner=$(basename "${home}")
	chown -R "${owner}:${owner}" "${home}" 2>/dev/null ||
		warn "could not chown ${home} (user ${owner})"
done </etc/passwd

# Root keeps the welcome note
[[ -f /cinnamon-configs/AcreetionOS.txt ]] && cp /cinnamon-configs/AcreetionOS.txt /root/

# Keep dconf seeds for the first-login script under /etc
mkdir -p /etc/acreetionos
for f in cinnamon.dconf terminal-settings; do
	[[ -f "/${f}" ]] && mv "/${f}" "/etc/acreetionos/${f}"
done

# sudo nicety kept from the mutable edition
echo "Defaults pwfeedback" >/etc/sudoers.d/90-pwfeedback
chmod 440 /etc/sudoers.d/90-pwfeedback

msg "Enabling system services..."
rm -f /etc/systemd/system/display-manager.service
systemctl enable lightdm.service 2>/dev/null || warn "could not enable lightdm"
systemctl enable NetworkManager.service 2>/dev/null || true
systemctl enable abroot-commit.service 2>/dev/null || warn "could not enable abroot-commit"

msg "Setting hostname..."
echo "acreetionos-immutable" >/etc/hostname

msg "Cleaning installer staging files..."
# Give the installed system a working resolver config for first boot
# (NetworkManager takes over afterwards).
if [[ -f /resolv.conf ]]; then
	cp /resolv.conf /etc/resolv.conf
fi
rm -rf /mkinitcpio /cinnamon-configs /backgrounds
rm -f /archiso.conf /resolve.conf /resolv.conf /middle.png \
	/usr/share/applications/calamares.desktop 2>/dev/null || true

msg "Marking slot A as committed default..."
date -Is >/var/lib/abroot/install-stamp 2>/dev/null || {
	mkdir -p /var/lib/abroot
	date -Is >/var/lib/abroot/install-stamp
}

msg "AcreetionOS Immutable installation finalized."

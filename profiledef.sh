#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="AcreetionOS-Immutable"
iso_label="acreetionOS_Immutable_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Acreetion OS"
iso_application="Acreetion OS Immutable Install Media"
# ISO version is derived from the most recent git tag ("v1.2" -> "1.2"),
# falling back to the commit short hash, then to "0.0" outside a git tree.
_profile_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
iso_version="$(
    cd "${_profile_dir}" 2>/dev/null || exit
    _tag="$(git describe --tags --abbrev=0 2>/dev/null)" \
        && printf '%s' "${_tag#v}" \
        || git rev-parse --short HEAD 2>/dev/null \
        || printf '0.0'
)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
declare -A file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/bin/calamares"]="0:0:755"
  ["/usr/bin/fixkeys.sh"]="0:0:755"
  ["/usr/bin/dd.sh"]="0:0:755"
  ["/usr/bin/calamares.sh"]="0:0:755"
  ["/usr/bin/wifi-connection"]="0:0:755"
  ["/usr/bin/abroot"]="0:0:755"
  ["/usr/bin/acreetion-recovery"]="0:0:755"
  ["/usr/local/bin/setup-displays.sh"]="0:0:755"
  ["/usr/local/bin/immutable-user-setup.sh"]="0:0:755"
  ["/usr/local/sbin/abroot-install-setup.sh"]="0:0:755"
  ["/usr/local/sbin/abroot-install-fstab.sh"]="0:0:755"
  ["/usr/local/sbin/abroot-install-bootloader.sh"]="0:0:755"
  ["/usr/local/sbin/abroot-install-finalize.sh"]="0:0:755"
  ["/etc/NetworkManager/dispatcher.d/10-fix-static-method"]="0:0:755"
)

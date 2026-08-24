# AcreetionOS Immutable - Calamares launcher.
# Installer configuration is vendored in /etc/calamares (immutable A/B layout),
# so unlike the mutable edition there is no calamares-config package to pull.
# /etc/mkinitcpio.conf for the installed system is written by
# abroot-install-fstab.sh (includes the abroot hook).

sudo pacman-key --init
sudo pacman -Syy

calamares -d 8 > /root/calamares.log

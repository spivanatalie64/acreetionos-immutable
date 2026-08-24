#!/bin/bash
# First-login setup for user accounts on AcreetionOS Immutable.
# Autostarted once via ~/.config/autostart/dd-immutable.desktop and removes
# itself after running. Immutable-safe: no writes to the read-only root.
set -e

SEED_DIR=/etc/acreetionos

if [[ -r "${SEED_DIR}/cinnamon.dconf" ]]; then
	dconf load /org/cinnamon/ <"${SEED_DIR}/cinnamon.dconf" || true
fi
if [[ -r "${SEED_DIR}/terminal-settings" ]]; then
	dconf load /org/gnome/terminal/ <"${SEED_DIR}/terminal-settings" || true
fi

rm -f "${HOME}/.config/autostart/dd-immutable.desktop"

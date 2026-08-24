#!/bin/bash
# Build the AcreetionOS Immutable ISO.
# Requires archiso; runs mkarchiso as root (pacstrap/mount privileges).
set -euo pipefail
cd "$(dirname "$0")"

./refresh.sh

# Stamp commit/date/user info into airootfs/etc/acreetion-build (lands in the ISO)
./generate-build-info.sh

sudo mkarchiso -L AcreetionOS_Immutable_XL \
	-v \
	-w "${PWD}/work" \
	-o "${PWD}/../ISO-immutable" \
	-C "${PWD}/pacman.conf" \
	"${PWD}"

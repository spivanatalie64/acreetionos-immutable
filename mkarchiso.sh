#!/usr/bin/env bash
set -euo pipefail
mkdir -p ./ISO
exec mkarchiso -L "acreetionOS_immutable_202608" -v -o ./ISO . -C ./pacman.conf

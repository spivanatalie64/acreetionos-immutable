#!/bin/bash
# AcreetionOS Immutable - full build
./refresh.sh -j && ./mkarchiso.sh
# sudo rm /var/cache/pacman/pkg/*
sudo rm -rf ./work

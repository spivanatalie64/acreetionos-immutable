mkarchiso -L "AcreetionOS_IMMUTABLE" -v -o ../ISO . -C ./pacman.conf export PACMAN_OPTS="--overwrite '*'" --j$(nproc)

# AcreetionOS Immutable

Atomic, dual-root (A/B) variant of [AcreetionOS](https://acreetionos.org).
The installed system runs from a **read-only root**; updates are staged into a
standby slot and activated atomically on reboot, with automatic fallback if an
update fails to boot.

## Partition layout

Created automatically by the Calamares "erase disk" flow (manual partitioning
is disabled — it cannot guarantee a valid A/B layout):

| # | Label        | FS   | Size     | Mount       | Purpose                                  |
|---|--------------|------|----------|-------------|------------------------------------------|
| 1 | ACR-EFI      | FAT32| 1024 MiB | `/efi`      | GRUB + `acr/env` boot-state file         |
| 2 | ACR-SLOT-A   | ext4 | ~40 %    | `/`         | Root slot A (**read-only** at runtime)   |
| 3 | ACR-SLOT-B   | ext4 | ~40 %    | —           | Standby root slot B                      |
| 4 | acreetion-data | ext4 | ~15 %  | `/mnt/.data`| Shared: `/home`, `/var`, per-slot `/etc` |

- `/` is mounted read-only (`ro` in fstab).
- `/home` and `/var` are bind mounts from the data partition.
- `/etc` is an overlayfs mounted by the custom `abroot` mkinitcpio hook:
  lower = the slot's read-only `/etc`, upper = persistent per-slot directory on
  the data partition. Factory-reset of system config = delete that slot's upper.
- Slot B starts empty; the first `abroot update` clones slot A into it.

## Boot flow

1. GRUB (installed with `--removable`, no NVRAM dependency) reads
   `/efi/acr/env`: `active_slot`, `pending_slot`, `tries_left`.
2. Default entry = committed active slot. If a pending slot is armed, it boots
   instead and GRUB decrements `tries_left` (default 3) and saves it back.
3. Early in userspace, `abroot-commit.service` verifies basic health and
   promotes the pending slot to `active_slot` (commit).
4. If a broken update fails before the commit service runs, the try counter
   reaches zero and GRUB falls back to the previously committed slot.

## Updating / rolling back

```bash
sudo abroot status      # slots, pending state, last update
sudo abroot update      # clone -> upgrade standby slot -> arm it, then reboot
sudo abroot rollback    # flip default back to the other slot
sudo abroot unlock      # temporary read-write root until next reboot
```

`abroot update` clones the running system into the standby slot (if empty),
runs `pacman -Syu` + `mkinitcpio -P` inside it via `arch-chroot`, marks it
ready and arms the boot switch. The running system keeps working untouched
until you reboot.

## Recovery environment

The Recovery Environment boot entry ships with A/B awareness: it can show slot
status and switch the default slot, and its bootloader repair re-runs the
immutable GRUB setup instead of a stock `grub-mkconfig`.

## Building the ISO

```bash
./build.sh          # cleans work/, builds ISO into ../ISO-immutable/
```

Requires Arch Linux with `archiso`, run as root. The live media itself boots
like the mutable edition (syslinux/BIOS + grub/UEFI); immutability applies to
the installed system.

## Repository notes

### Versioning & releases

- The ISO version is derived from git: the newest `vX.Y[.Z]` tag becomes the
  ISO version (`profiledef.sh`), so `git tag v1.1` is all it takes to cut
  `AcreetionOS-Immutable-1.1` builds. Untagged checkouts fall back to the
  commit short hash.
- Branches:
  - `master` — development; every push builds a dated ISO and repoints the
    `AcreetionOS-Immutable-latest.iso` symlink.
  - `X.Y` (e.g. `1.0`) — per-version maintenance branches, created from the
    matching tag; pushes build dated ISOs from that series.
  - `vX.Y[.Z]` tags — release cuts; CI publishes
    `AcreetionOS-Immutable-<tag>.iso` permanently and creates a GitLab
    **Release** with download/checksum asset links.
- Release flow:
  ```bash
  git checkout -b 1.0 master      # optional maintenance branch
  git tag -a v1.0 -m "AcreetionOS Immutable 1.0"
  git push origin master --tags   # (+ push the branch if created)
  ```
- GitHub: a `v*.*` tag push also creates a GitHub Release (`.github/workflows/
  release.yml`) linking to the same artifacts on iso.acreetionos.org; the
  Mirror workflow forwards branches/tags to GitLab.

### CI

- `.gitlab-ci.yml` builds on `master`, per-version branches (`X.Y`) and
  `v*` tags, then publishes to the nginx-served directory and keeps the 3 most
  recent development builds (tagged releases are never pruned).

## Known limitations / roadmap

- LUKS encryption is not wired into the immutable layout yet.
- No swap partition; add a swapfile on `/var` manually if needed.
- `.pacnew` handling in `/etc` is manual (see warnings in `abroot status`).
- BIOS boot for the *installed* system is UEFI-only (live media still boots on
  legacy BIOS).

## License

GPL-3.0 — same as upstream AcreetionOS.

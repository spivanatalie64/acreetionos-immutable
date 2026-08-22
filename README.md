# AcreetionOS Immutable Edition

Immutable Filesystem Community Edition — a Cinnamon desktop on Arch with a
**read-only OS root**, snapshot-based updates, and OSTree-backed `/usr`
history.

> Self-contained archiso profile. Builds standalone from standard Arch mirrors.

## The immutability model

The live ISO is immutable by construction (squashfs). An installed system
uses btrfs subvolumes:

| Subvolume    | Mountpoint    | Access | Purpose                                  |
|--------------|---------------|--------|------------------------------------------|
| `@`          | `/`           | **ro** | The immutable OS base                    |
| `@home`      | `/home`       | rw     | User data                                |
| `@var`       | `/var`        | rw     | Logs, caches, spool                      |
| `@snapshots` | `/.snapshots` | rw     | Read-only snapshots of `@`, OSTree repo  |

- **Updates are snapshotted transactions**: `acro update` takes a pre-update
  snapshot, unlocks root, runs `pacman -Syu`, re-locks, and can record the
  exact `/usr` state into a local OSTree repository.
- **Rollback**: every update leaves a restore point behind.
  `acro rollback <name>` promotes a snapshot back to be the new root.
- **Apps stay out of the base**: Flatpak/Flathub is wired in via `acro apps`.
- **OSTree history**: `acro ostree-commit` / `acro ostree-diff` record and
  diff `/usr` states between updates. (Full boot-level OSTree deployments
  with A/B switching are roadmap, see below.)

## Install

Boot the ISO and run:

```bash
acreetionos-install            # or: acreetionos-install /dev/sdX
```

It partitions the target disk (512 MiB ESP + btrfs root), installs the full
Cinnamon package set, writes a read-only-root fstab, sets up GRUB, creates
your user, and drops in the `acro` manager.

## Managing an installed system (`acro`)

```
acro status                  state, snapshots, usr history
acro unlock | lock           temporarily remount / writable / read-only
acro update [--yes]          snapshot -> pacman -Syu -> re-lock
acro snapshot create|list|delete|prune
acro rollback <name>         promote a snapshot to be the new root
acro ostree-commit|ostree-diff   record/diff /usr states
acro apps                    Flatpak setup + app updates
```

## Build

```bash
git clone https://github.com/spivanatalie64/acreetionos-immutable.git
cd acreetionos-immutable
./build.sh
```

ISO lands in `./ISO/`. CI builds weekly and on push, then publishes a GitHub
release with the ISO asset.

## Layout

| Path | Purpose |
|------|---------|
| `profiledef.sh` | Edition metadata |
| `packages.x86_64` | Static package list |
| `pacman.conf` | Standard Arch mirrors |
| `airootfs/usr/local/bin/acro` | Immutability manager |
| `airootfs/usr/local/bin/acreetionos-install` | Guided disk installer |
| `airootfs/usr/share/acreetionos/packages.x86_64` | Package list copy read by the installer |
| `airootfs/` | Live-environment overlay (DM, configs) |
| `.github/workflows/` | CI: ISO build + lint + release |

## Roadmap

- Boot-level OSTree deployments (true A/B roots with atomic switch-back)
- Branded GRUB theme assets (background + font)
- Graphical installer front-end

## Community

- **Discord:** AcreetionOS Community Server
- **Issues:** https://github.com/spivanatalie64/acreetionos-immutable/issues
- **Website:** https://acreetionos.org

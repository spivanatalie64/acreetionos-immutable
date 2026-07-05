# AcreetionOS Edition Template

**Base template for creating AcreetionOS community editions.**

This repo provides the minimal archiso profile infrastructure — bootloaders,
live environment configs, build scripts — without any desktop environment
or display server. Use it as a starting point for new editions.

## Usage

1. **Fork or copy** this repo
2. **Replace placeholders** in these files:
   - `profiledef.sh` — edition name, label, description, version
   - `packages.x86_64` — add your edition-specific packages
   - `airootfs/etc/os-release` — update edition info
   - `build.sh` — edition name in echo messages
   - `mkarchiso.sh` — edition label
3. **Customize** `airootfs/` with your edition's configs and scripts
4. **Build** with `./build.sh`

## Placeholder Reference

| Placeholder | Description |
|-------------|-------------|
| `Immutable` | Human-readable edition name (e.g., "XFCE") |
| `IMMUTABLE` | Short label for ISO volume (e.g., "XFCE") |
| `Immutable Filesystem Community Edition` | Short description |
| `immutable` | GitHub repo name suffix |

## Directory Structure

```
├── profiledef.sh          # ISO metadata & file permissions
├── packages.x86_64        # Package list (base + edition)
├── pacman.conf            # Repository configuration
├── bootstrap_packages.x86_64
├── build.sh               # Build entry point
├── mkarchiso.sh           # mkarchiso wrapper
├── refresh.sh             # Cleanup script
├── generate-build-info.sh # Build metadata
├── grub/                  # GRUB bootloader configs
├── syslinux/              # SYSLINUX bootloader configs
├── efiboot/               # EFI boot files
├── airootfs/              # Live root filesystem overlay
│   ├── etc/               # System configs
│   ├── root/              # Root user files
│   └── usr/               # User binaries & scripts
└── .github/workflows/     # GitHub Actions CI
```

## Build Requirements

- `archiso` package
- `sudo` access
- ~10GB free disk space for the build

## CI/CD

This template includes a reusable GitHub Actions workflow in
`.github/workflows/build.yml`. Set the following secrets for upload targets:

| Secret | Purpose |
|--------|---------|
| `CLOUDFLARE_ACCOUNT_ID` | R2 upload |
| `CLOUDFLARE_API_TOKEN` | R2 upload |
| `CLOUDFLARE_EMAIL` | R2 upload |
| `IA_ACCESS_KEY` | Internet Archive upload |
| `IA_SECRET_KEY` | Internet Archive upload |
| `SF_USERNAME` | SourceForge upload |
| `SF_PASSWORD` | SourceForge upload |

## License

GPL-3.0 — see [LICENSE](LICENSE).

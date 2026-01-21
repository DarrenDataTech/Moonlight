# Moonlight
Moonlight installation and scripts

## Raspberry Pi Installation Script

This repository contains an automated installation script for Moonlight Qt on Raspberry Pi.

### Quick Start

Download and run the installation script:

```bash
curl -O https://raw.githubusercontent.com/DarrenDataTech/Moonlight/main/install-moonlight-rpi.sh
chmod +x install-moonlight-rpi.sh
./install-moonlight-rpi.sh
```

Or if you've cloned the repository:

```bash
./install-moonlight-rpi.sh
```

### Features

The script provides an interactive menu with the following options:

1. **Install/Update Moonlight Qt** - Installs or updates Moonlight Qt from the official repository
2. **Configure Audio (Raspberry Pi OS Lite)** - Installs and configures PulseAudio for audio support
3. **Fix Input Permissions (OSMC)** - Fixes controller input permissions for OSMC users
4. **Fix 4K Monitor Support** - Increases GPU memory allocation for 4K 60Hz displays
5. **Show Usage Instructions** - Displays information on how to use Moonlight

### Requirements

- Raspberry Pi 4 or later (earlier models may not perform well)
- Raspberry Pi OS 12 (Bookworm) or later
- Internet connection for downloading packages

### Best Practices

- For best performance, run Moonlight from a console/TTY (Ctrl+Alt+F2)
- Keep display resolution at 1080p or below when running from desktop environment
- For HDR support, run from console and use Full KMS driver (vc4-kms-v3d)

### Updating Moonlight

After installation, you can update Moonlight Qt using:

```bash
sudo apt update
sudo apt upgrade
```

Or use the script's option 1 to update.

### Based On

This script is based on the official installation guide:
https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4


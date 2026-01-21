# Moonlight
Moonlight installation and scripts for Raspberry Pi

## Moonlight Qt Installation Script

This repository contains an automated installation script for Moonlight Qt on Raspberry Pi 4 and later.

### Quick Install

To install Moonlight Qt on your Raspberry Pi, run:

```bash
curl -fsSL https://raw.githubusercontent.com/DarrenDataTech/Moonlight/main/install-moonlight-rpi.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/DarrenDataTech/Moonlight/main/install-moonlight-rpi.sh
chmod +x install-moonlight-rpi.sh
./install-moonlight-rpi.sh
```

### What the Script Does

The installation script automates the following steps from the [official Moonlight documentation](https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4):

1. **Verifies Requirements**
   - Checks if running on a Raspberry Pi
   - Verifies OS version (Raspberry Pi OS 12 Bookworm or later recommended)

2. **Installs Moonlight Qt**
   - Adds the official Moonlight Qt repository
   - Installs the moonlight-qt package

3. **Optional Audio Configuration** (for Raspberry Pi OS Lite)
   - Prompts to install PulseAudio for audio over HDMI
   - Provides instructions for audio configuration via raspi-config

4. **Optional Controller Support**
   - Adds user to input group for DS4/DS5 controller features
   - Particularly important for OSMC users

5. **Optional 4K Display Support**
   - Configures GPU memory (128MB) for 4K 60 Hz displays
   - Prevents decoder errors on high-resolution monitors

### Requirements

- Raspberry Pi 4 or later
- Raspberry Pi OS 12 (Bookworm) or later
- Internet connection

### Usage Tips

- **Best Performance**: Run Moonlight from console/TTY (Ctrl+Alt+F2-F6) rather than desktop environment
- **Desktop Usage**: Keep display resolution at 1080p or below when running from desktop on Pi 4
- **HDR Support**: Requires running from console and using vc4-kms-v3d driver

### Updates

To update Moonlight Qt after installation:

```bash
sudo apt update
sudo apt upgrade
```

### Troubleshooting

For common issues and solutions, refer to the [official documentation](https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4).

#!/bin/bash

# Moonlight Qt Installation Script for Raspberry Pi
# Based on: https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4
#
# Requirements:
# - Raspberry Pi 4 or later
# - Raspberry Pi OS 12 (Bookworm) or later

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if [ ! -f /proc/device-tree/model ]; then
        print_warning "Cannot determine if this is a Raspberry Pi"
        read -r -p "Continue anyway? (y/n): " continue_install
        if [ "$continue_install" != "y" ]; then
            exit 0
        fi
    else
        model=$(cat /proc/device-tree/model)
        print_info "Detected: $model"
    fi
}

# Function to check OS version
check_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "OS: $NAME $VERSION"
        
        # Check for Raspberry Pi OS 12 (Bookworm) or later
        if [ "$ID" = "raspbian" ] || [ "$ID" = "debian" ]; then
            version_id=$(echo "$VERSION_ID" | cut -d. -f1)
            if [ "$version_id" -lt 12 ]; then
                print_warning "Raspberry Pi OS 12 (Bookworm) or later is recommended"
                read -r -p "Continue anyway? (y/n): " continue_install
                if [ "$continue_install" != "y" ]; then
                    exit 0
                fi
            fi
        fi
    fi
}

# Function to install Moonlight Qt
install_moonlight() {
    print_info "Installing Moonlight Qt..."
    
    # Check if lsb_release is available
    if ! command -v lsb_release &> /dev/null; then
        print_info "Installing lsb-release package..."
        sudo apt update
        sudo apt install -y lsb-release
    fi
    
    # Add Moonlight repository
    print_info "Adding Moonlight repository..."
    print_warning "This will download and execute a setup script from Cloudsmith"
    print_warning "Please review the script at: https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-qt/setup.deb.sh"
    read -r -p "Continue with repository setup? (y/n): " continue_repo
    if [ "$continue_repo" != "y" ]; then
        print_info "Repository setup cancelled"
        return 1
    fi
    
    curl -1sLf 'https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-qt/setup.deb.sh' | distro=raspbian codename=$(lsb_release -cs) sudo -E bash
    
    # Install Moonlight Qt
    print_info "Installing moonlight-qt package..."
    sudo apt install -y moonlight-qt
    
    print_success "Moonlight Qt installed successfully!"
}

# Function to configure audio for Raspberry Pi OS Lite
configure_audio_lite() {
    print_info "Configuring audio for Raspberry Pi OS Lite..."
    
    # Check if PulseAudio is already installed
    if dpkg -l pulseaudio 2>/dev/null | grep -q '^ii'; then
        print_info "PulseAudio is already installed"
    else
        print_info "Installing PulseAudio..."
        sudo apt install -y pulseaudio
    fi
    
    print_warning "Please follow these manual steps to complete audio configuration:"
    echo "1. Run: sudo raspi-config"
    echo "2. Navigate to: Advanced Settings -> Audio Config"
    echo "3. Select: PulseAudio"
    echo "4. Reboot your Pi"
    echo "5. Run: sudo raspi-config again"
    echo "6. Navigate to: System Settings -> Audio"
    echo "7. Select: your desired audio output"
}

# Function to fix OSMC input permissions
fix_osmc_permissions() {
    print_info "Fixing OSMC input device permissions..."
    sudo usermod -a -G input "$USER"
    print_success "User added to input group. Please reboot for changes to take effect."
}

# Function to fix 4K monitor GPU memory
fix_4k_gpu_memory() {
    print_info "Increasing GPU memory for 4K 60 Hz support..."
    
    # Detect config file location (older vs newer Raspberry Pi OS)
    config_file=""
    if [ -f /boot/firmware/config.txt ]; then
        config_file="/boot/firmware/config.txt"
    elif [ -f /boot/config.txt ]; then
        config_file="/boot/config.txt"
    else
        print_error "Cannot find config.txt in /boot or /boot/firmware"
        return 1
    fi
    
    print_info "Using config file: $config_file"
    
    # Check if gpu_mem is already set
    if grep -q "^gpu_mem=" "$config_file"; then
        print_warning "gpu_mem is already configured in $config_file"
        print_info "Current setting:"
        grep "^gpu_mem=" "$config_file"
        read -r -p "Do you want to update it to 128? (y/n): " update_gpu
        if [ "$update_gpu" = "y" ]; then
            sudo sed -i 's/^gpu_mem=.*/gpu_mem=128/' "$config_file"
            print_success "GPU memory updated to 128MB"
        fi
    else
        echo "gpu_mem=128" | sudo tee -a "$config_file"
        print_success "GPU memory set to 128MB"
    fi
    
    print_warning "Please reboot for changes to take effect."
}

# Function to show usage instructions
show_usage() {
    echo ""
    print_info "Usage Instructions:"
    echo ""
    echo "  Launch Moonlight:"
    echo "    - From desktop: Find Moonlight Qt in your applications menu"
    echo "    - From terminal: moonlight-qt"
    echo ""
    echo "  For best performance:"
    echo "    - Run Moonlight directly from a console/TTY"
    echo "    - Switch to TTY using Ctrl+Alt+F2 (or F3, F4, etc.)"
    echo "    - Return to desktop using Ctrl+Alt+F1 or Ctrl+Alt+F7"
    echo ""
    echo "  Update Moonlight:"
    echo "    sudo apt update"
    echo "    sudo apt upgrade"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo "========================================"
    echo "  Moonlight Qt Installation Script"
    echo "  for Raspberry Pi"
    echo "========================================"
    echo ""
    echo "1) Install/Update Moonlight Qt"
    echo "2) Configure Audio (Raspberry Pi OS Lite)"
    echo "3) Fix Input Permissions (OSMC)"
    echo "4) Fix 4K Monitor Support (increase GPU memory)"
    echo "5) Show Usage Instructions"
    echo "6) Exit"
    echo ""
    read -r -p "Select an option (1-6): " choice
    
    case $choice in
        1)
            check_raspberry_pi
            check_os_version
            install_moonlight
            show_usage
            ;;
        2)
            configure_audio_lite
            ;;
        3)
            fix_osmc_permissions
            ;;
        4)
            fix_4k_gpu_memory
            ;;
        5)
            show_usage
            ;;
        6)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
    
    # Ask if user wants to do something else
    echo ""
    read -r -p "Do you want to perform another action? (y/n): " another
    if [ "$another" = "y" ]; then
        show_menu
    fi
}

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    print_info "The script will use sudo when needed"
    exit 1
fi

# Start the script
clear
show_menu

print_success "Script completed!"
echo ""
print_info "Notes:"
echo "  - For best performance, run Moonlight from a console/TTY"
echo "  - Keep display resolution at 1080p or below when running from desktop"
echo "  - To enable HDR, run Moonlight from console and use Full KMS driver (vc4-kms-v3d)"
echo ""

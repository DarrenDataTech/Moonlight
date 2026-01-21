#!/bin/bash

#######################################
# Moonlight Qt Installation Script for Raspberry Pi 4
# Based on: https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4
#
# Requirements:
# - Raspberry Pi 4 or later
# - Raspberry Pi OS 12 (Bookworm) or later
#######################################

set -e  # Exit on error

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
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_error "This script is designed for Raspberry Pi devices only."
        exit 1
    fi
    print_success "Raspberry Pi detected"
}

# Function to check OS version
check_os_version() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        print_info "Detected OS: $PRETTY_NAME"
        
        # Check for Raspberry Pi OS 12 (Bookworm) or later
        if [ "$ID" = "raspbian" ] || [ "$ID" = "debian" ]; then
            VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
            if [ "$VERSION_MAJOR" -lt 12 ]; then
                print_warning "Raspberry Pi OS 12 (Bookworm) or later is recommended."
                print_warning "You are running version $VERSION_ID. Installation may not work properly."
                read -p "Do you want to continue anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
        fi
    fi
}

# Function to install Moonlight Qt
install_moonlight() {
    print_info "Installing Moonlight Qt..."
    
    # Add Moonlight repository
    print_info "Adding Moonlight Qt repository..."
    print_warning "Downloading and executing repository setup script from Cloudsmith..."
    
    # Download the script first
    local TEMP_SCRIPT
    TEMP_SCRIPT=$(mktemp)
    if ! curl -1sLf 'https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-qt/setup.deb.sh' -o "$TEMP_SCRIPT"; then
        print_error "Failed to download repository setup script"
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi
    
    # Execute the script
    distro=raspbian codename=$(lsb_release -cs) sudo -E bash "$TEMP_SCRIPT"
    rm -f "$TEMP_SCRIPT"
    
    # Update package list
    print_info "Updating package list..."
    sudo apt update
    
    # Install Moonlight Qt
    print_info "Installing moonlight-qt package..."
    sudo apt install -y moonlight-qt
    
    print_success "Moonlight Qt installed successfully!"
}

# Function to configure PulseAudio for Raspberry Pi OS Lite
configure_pulseaudio() {
    print_info "Checking audio configuration..."
    
    # Check if PulseAudio is installed
    if ! command -v pulseaudio &> /dev/null; then
        print_warning "PulseAudio is not installed."
        print_info "This is required for Raspberry Pi OS Lite for audio over HDMI."
        read -p "Do you want to install and configure PulseAudio? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Installing PulseAudio..."
            sudo apt install -y pulseaudio
            
            print_warning "Audio configuration steps:"
            print_info "1. Run: sudo raspi-config"
            print_info "2. Navigate to Advanced Settings -> Audio Config and select 'PulseAudio'"
            print_info "3. Reboot your Pi (sudo reboot)"
            print_info "4. Run: sudo raspi-config"
            print_info "5. Navigate to System Settings -> Audio and select your audio output"
            print_warning "Please complete these steps manually after installation."
        fi
    else
        print_success "PulseAudio is already installed"
    fi
}

# Function to fix OSMC input device permissions
fix_input_permissions() {
    print_info "Checking input device permissions..."
    
    # Check if user is in input group
    if ! groups "$USER" | grep -q '\binput\b'; then
        print_warning "User is not in the 'input' group."
        print_info "This is required for extended DS4/DS5 controller features."
        read -p "Do you want to add your user to the input group? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Adding user to input group..."
            sudo usermod -a -G input "$USER"
            print_success "User added to input group"
            print_warning "You need to reboot for this change to take effect"
        fi
    else
        print_success "User is already in the input group"
    fi
}

# Function to configure GPU memory for 4K displays
configure_gpu_memory() {
    print_info "Checking GPU memory configuration..."
    
    read -p "Do you have a 4K 60 Hz monitor? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check which config file exists
        local CONFIG_FILE=""
        if [ -f /boot/firmware/config.txt ]; then
            CONFIG_FILE="/boot/firmware/config.txt"
        elif [ -f /boot/config.txt ]; then
            CONFIG_FILE="/boot/config.txt"
        else
            print_error "Could not find config.txt file"
            return
        fi
        
        # Check if gpu_mem is already set to 128 or higher
        local CURRENT_GPU_MEM
        CURRENT_GPU_MEM=$(grep "^gpu_mem=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
        if [ -n "$CURRENT_GPU_MEM" ] && [ "$CURRENT_GPU_MEM" -ge 128 ] 2>/dev/null; then
            print_info "GPU memory is already configured to ${CURRENT_GPU_MEM}MB"
        else
            print_info "For 4K 60 Hz displays, GPU memory needs to be increased to 128MB"
            
            # Check if there's an existing gpu_mem setting that needs updating
            if [ -n "$CURRENT_GPU_MEM" ]; then
                print_warning "Current gpu_mem is set to ${CURRENT_GPU_MEM}MB (less than 128MB)"
                read -p "Do you want to update it to 128MB? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    print_info "Updating gpu_mem to 128 in $CONFIG_FILE..."
                    sudo sed -i "s/^gpu_mem=.*/gpu_mem=128/" "$CONFIG_FILE"
                    print_success "GPU memory updated to 128MB"
                    print_warning "You need to reboot for this change to take effect"
                fi
            else
                read -p "Do you want to configure GPU memory now? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    print_info "Adding gpu_mem=128 to $CONFIG_FILE..."
                    echo "gpu_mem=128" | sudo tee -a "$CONFIG_FILE"
                    print_success "GPU memory configured to 128MB"
                    print_warning "You need to reboot for this change to take effect"
                fi
            fi
        fi
    fi
}

# Function to display usage tips
display_tips() {
    echo
    print_success "Installation complete!"
    echo
    print_info "=== Usage Tips ==="
    print_info "• Launch Moonlight from desktop or run 'moonlight-qt' in terminal"
    print_info "• For best performance, run from console/TTY (Ctrl+Alt+F2-F6)"
    print_info "• Keep display resolution at 1080p or below when running from desktop"
    print_info "• Your desktop is typically at Ctrl+Alt+F1 or Ctrl+Alt+F7"
    echo
    print_info "=== Updates ==="
    print_info "To update Moonlight Qt in the future, run:"
    print_info "  sudo apt update && sudo apt upgrade"
    echo
    print_info "=== HDR Support ==="
    print_info "• HDR requires running from console/TTY (not desktop)"
    print_info "• Ensure /boot/config.txt uses 'vc4-kms-v3d' (not 'vc4-fkms-v3d')"
    echo
    print_info "For troubleshooting, visit:"
    print_info "https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4"
    echo
}

# Main installation flow
main() {
    echo "================================================"
    echo "  Moonlight Qt Installation for Raspberry Pi"
    echo "================================================"
    echo
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root (without sudo)"
        print_info "The script will prompt for sudo when needed"
        exit 1
    fi
    
    # Perform checks
    check_raspberry_pi
    check_os_version
    
    echo
    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Install Moonlight Qt
    install_moonlight
    
    echo
    # Optional configurations
    configure_pulseaudio
    echo
    fix_input_permissions
    echo
    configure_gpu_memory
    
    # Display tips
    display_tips
    
    # Check if reboot is needed (based on input group or gpu_mem changes)
    print_warning "A reboot is recommended if you made configuration changes"
    read -p "Do you want to reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Rebooting..."
        sudo reboot
    fi
}

# Run main function
main

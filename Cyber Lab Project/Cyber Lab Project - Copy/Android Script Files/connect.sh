#!/bin/bash
# connect.sh - Main wireless connection script with Android 11+ support

# Configuration - These will be updated by config.sh
KALI_IP="192.168.1.11"
PHONE_IP="192.168.1.9"
DEFAULT_PORT="5555"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="wireless_adb.conf"

# Function to get connection details from config
get_connection_details() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source the config file
        source "$CONFIG_FILE" 2>/dev/null
        
        if [ -n "$CONNECTED_PORT" ]; then
            PHONE="${PHONE_IP}:${CONNECTED_PORT}"
            ADB_CMD="adb -s $PHONE"
            return 0
        fi
    fi
    
    # Try to detect connection
    CONNECTED_DEVICE=$(adb devices | grep "$PHONE_IP" | grep -o "$PHONE_IP:[0-9]*" | head -1)
    
    if [ -n "$CONNECTED_DEVICE" ]; then
        PHONE="$CONNECTED_DEVICE"
        ADB_CMD="adb -s $PHONE"
        
        # Save to config
        echo "PHONE_IP=$PHONE_IP" > "$CONFIG_FILE"
        echo "KALI_IP=$KALI_IP" >> "$CONFIG_FILE"
        echo "CONNECTED_PORT=$(echo $PHONE | cut -d: -f2)" >> "$CONFIG_FILE"
        echo "CONNECTION_METHOD=auto_detected" >> "$CONFIG_FILE"
        
        return 0
    fi
    
    return 1
}

# Function to check if devices are on same network
check_network() {
    echo -e "${CYAN}[1/4] Checking network configuration...${NC}"
    
    # Get Kali's network
    KALI_NET=$(echo $KALI_IP | cut -d. -f1-3)
    PHONE_NET=$(echo $PHONE_IP | cut -d. -f1-3)
    
    if [ "$KALI_NET" != "$PHONE_NET" ]; then
        echo -e "${RED}⚠️  WARNING: Devices appear to be on different networks${NC}"
        echo "  Kali:   $KALI_NET.x"
        echo "  Phone:  $PHONE_NET.x"
        echo ""
        echo "They must be on the same WiFi network for wireless ADB."
        return 1
    fi
    
    echo -e "${GREEN}✓ Both devices on same network ($KALI_NET.x)${NC}"
    return 0
}

# Function to ping phone
ping_phone() {
    echo -e "${CYAN}[2/4] Checking phone connectivity...${NC}"
    echo -n "Pinging $PHONE_IP... "
    
    if ping -c 2 -W 1 $PHONE_IP > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Phone is reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ Phone not reachable${NC}"
        echo ""
        echo "Possible issues:"
        echo "1. Phone WiFi is off"
        echo "2. Different WiFi network"
        echo "3. Phone IP changed"
        echo ""
        echo "To find phone IP:"
        echo "  Settings → Wi-Fi → Tap connected network"
        return 1
    fi
}

# Function to check USB connection first (required for Android 11+ wireless debugging)
check_usb_connection() {
    echo -e "${CYAN}[*] Checking USB connection...${NC}"
    
    # Restart ADB
    adb kill-server 2>/dev/null
    sleep 1
    adb start-server
    sleep 2
    
    # Check for USB devices
    if adb devices | grep -q ".*device$"; then
        echo -e "${GREEN}✓ USB device detected${NC}"
        
        # Set TCP mode on port 5555
        echo "Setting TCP mode on port $DEFAULT_PORT..."
        adb tcpip $DEFAULT_PORT
        sleep 3
        
        # Get device IP from USB (optional)
        echo "Getting device info..."
        adb shell ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1
        
        return 0
    else
        echo -e "${YELLOW}⚠️  No USB device detected${NC}"
        echo "For Android 11+, you need to:"
        echo "1. Connect phone via USB"
        echo "2. Enable USB debugging"
        echo "3. Run this script again"
        return 1
    fi
}

# Function to establish wireless connection
connect_wireless() {
    echo -e "${CYAN}[3/4] Establishing wireless connection...${NC}"
    
    # Try default port 5555 first
    echo "Trying port $DEFAULT_PORT..."
    CONNECT_OUTPUT=$(adb connect $PHONE_IP:$DEFAULT_PORT 2>&1)
    echo "Result: $CONNECT_OUTPUT"
    
    sleep 2
    
    # Check if connected
    if adb devices | grep -q "$PHONE_IP:$DEFAULT_PORT.*device"; then
        echo -e "${GREEN}✓ Successfully connected on port $DEFAULT_PORT!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Port $DEFAULT_PORT connection failed${NC}"
        return 1
    fi
}

# Function for Android 11+ wireless debugging
try_wireless_debugging() {
    echo -e "${CYAN}[4/4] Android 11+ Wireless Debugging Method${NC}"
    
    echo -e "${PURPLE}📱 On Your Phone:${NC}"
    echo "1. Go to Settings → Developer Options"
    echo "2. Turn ON 'Wireless Debugging'"
    echo "3. Tap 'Wireless Debugging'"
    echo "4. Look for 'Pair device with pairing code'"
    echo ""
    
    read -p "Do you want to use Wireless Debugging pairing? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    
    # Check if adb pairing is available (version 31+ required)
    ADB_VERSION=$(adb version | head -1 | grep -o "[0-9]*" | head -1)
    if [ "$ADB_VERSION" -lt 31 ]; then
        echo -e "${RED}⚠️  Your ADB version is too old (needs 31+ for Android 11 wireless pairing)${NC}"
        echo "Update ADB from: https://developer.android.com/studio/releases/platform-tools"
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Two Options:${NC}"
    echo "1. Using pairing code"
    echo "2. Using port number from Wireless Debugging screen"
    echo ""
    
    read -p "Choose option (1 or 2): " option
    
    case $option in
        1)
            # Pairing code method
            echo ""
            echo "On your phone:"
            echo "1. Tap 'Pair device with pairing code'"
            echo "2. Note the 6-digit pairing code and port number"
            echo ""
            
            read -p "Enter pairing port (4 digits): " pair_port
            if [ -z "$pair_port" ]; then
                echo "No port entered, skipping..."
                return 1
            fi
            
            read -p "Enter 6-digit pairing code: " pair_code
            if [ -z "$pair_code" ]; then
                echo "No code entered, skipping..."
                return 1
            fi
            
            echo "Pairing with $PHONE_IP:$pair_port..."
            adb pair $PHONE_IP:$pair_port $pair_code
            
            # After pairing, connect with wireless debugging port
            echo ""
            echo "Now look for the 'IP address & port' on Wireless Debugging screen"
            read -p "Enter wireless debugging port (4 digits): " wd_port
            
            if [ -n "$wd_port" ]; then
                echo "Connecting to $PHONE_IP:$wd_port..."
                adb connect $PHONE_IP:$wd_port 2>&1
                sleep 2
                
                if adb devices | grep -q "$PHONE_IP:$wd_port.*device"; then
                    echo -e "${GREEN}✓ Connected via Wireless Debugging!${NC}"
                    return 0
                fi
            fi
            ;;
            
        2)
            # Direct wireless debugging port method
            echo ""
            echo "On your phone, look for:"
            echo "'IP address & port' under Wireless Debugging"
            echo "Example: 192.168.1.9:45139"
            echo ""
            
            read -p "Enter the full IP:PORT from phone (e.g., 192.168.1.9:45139): " wd_address
            
            if [ -z "$wd_address" ]; then
                echo "No address entered, skipping..."
                return 1
            fi
            
            echo "Connecting to $wd_address..."
            adb connect $wd_address 2>&1
            sleep 2
            
            if adb devices | grep -q "$wd_address.*device"; then
                echo -e "${GREEN}✓ Connected via Wireless Debugging!${NC}"
                return 0
            else
                echo -e "${RED}✗ Connection failed${NC}"
                echo "Make sure Wireless Debugging is ON and phone screen is unlocked"
                return 1
            fi
            ;;
            
        *)
            echo "Invalid option"
            return 1
            ;;
    esac
    
    return 1
}

# Function to display connection status
show_status() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               WIRELESS ADB CONNECTION                 ║${NC}"
    echo -e "${BLUE}║           Kali: $KALI_IP                              ║${NC}"
    echo -e "${BLUE}║           Phone: $PHONE_IP                            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check current connection
    CONNECTED_DEVICES=$(adb devices | grep "$PHONE_IP")
    
    if [ -n "$CONNECTED_DEVICES" ]; then
        echo -e "${GREEN}✅ WIRELESS CONNECTION ACTIVE${NC}"
        echo "$CONNECTED_DEVICES"
        echo ""
        
        # Get the connected address
        CONNECTED_ADDR=$(echo "$CONNECTED_DEVICES" | grep -o "$PHONE_IP:[0-9]*")
        
        # Get device info
        MODEL=$(adb -s $CONNECTED_ADDR shell getprop ro.product.model 2>/dev/null || echo "Unknown")
        ANDROID=$(adb -s $CONNECTED_ADDR shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        BATTERY=$(adb -s $CONNECTED_ADDR shell dumpsys battery 2>/dev/null | grep level | awk '{print $2}' || echo "Unknown")
        
        echo -e "${CYAN}Device Information:${NC}"
        echo "  📱 Model:    $MODEL"
        echo "  🤖 Android:  $ANDROID"
        echo "  🔋 Battery:  $BATTERY%"
        echo "  🔌 Port:     $(echo $CONNECTED_ADDR | cut -d: -f2)"
        echo ""
        
        return 0
    else
        echo -e "${RED}❌ NOT CONNECTED${NC}"
        echo ""
        return 1
    fi
}

# Function to test basic commands
test_connection() {
    CONNECTED_ADDR=$(adb devices | grep "$PHONE_IP" | grep -o "$PHONE_IP:[0-9]*" | head -1)
    
    if [ -z "$CONNECTED_ADDR" ]; then
        echo -e "${RED}No connected device found${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Testing wireless commands...${NC}"
    echo ""
    
    echo -e "${YELLOW}1. Battery status:${NC}"
    adb -s $CONNECTED_ADDR shell dumpsys battery | grep -E "level|status" | head -2
    
    echo ""
    echo -e "${YELLOW}2. Storage info:${NC}"
    adb -s $CONNECTED_ADDR shell df /storage/emulated/0 2>/dev/null | tail -1
    
    echo ""
    echo -e "${YELLOW}3. Screen info:${NC}"
    adb -s $CONNECTED_ADDR shell wm size 2>/dev/null
    adb -s $CONNECTED_ADDR shell wm density 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✅ Wireless control verified!${NC}"
}

# Function to show quick commands
show_quick_commands() {
    CONNECTED_ADDR=$(adb devices | grep "$PHONE_IP" | grep -o "$PHONE_IP:[0-9]*" | head -1)
    
    if [ -z "$CONNECTED_ADDR" ]; then
        echo "No active connection"
        return
    fi
    
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━ QUICK WIRELESS COMMANDS ━━━━━━━━━━━━${NC}"
    echo ""
    echo "Basic commands:"
    echo "  adb -s $CONNECTED_ADDR shell             # Open phone terminal"
    echo "  adb -s $CONNECTED_ADDR logcat            # View phone logs"
    echo "  adb devices                              # Check connection"
    echo ""
    echo "File operations:"
    echo "  adb -s $CONNECTED_ADDR pull /sdcard/file.txt ."
    echo "  adb -s $CONNECTED_ADDR push file.txt /sdcard/"
    echo ""
    echo "Screenshots:"
    echo "  adb -s $CONNECTED_ADDR shell screencap -p /sdcard/screen.png"
    echo "  adb -s $CONNECTED_ADDR pull /sdcard/screen.png"
    echo "  adb -s $CONNECTED_ADDR shell rm /sdcard/screen.png"
    echo ""
    echo "Disconnect:"
    echo "  adb disconnect $CONNECTED_ADDR"
    echo ""
}

# Main function
main() {
    clear
    echo -e "${BLUE}Starting wireless connection to phone...${NC}"
    echo -e "${BLUE}Kali IP: $KALI_IP${NC}"
    echo -e "${BLUE}Phone IP: $PHONE_IP${NC}"
    echo ""
    
    # Step 1: Check network
    if ! check_network; then
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Step 2: Ping phone
    if ! ping_phone; then
        echo ""
        read -p "Phone not reachable. Try to continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # For Android 11+, check USB connection first
    echo ""
    echo -e "${YELLOW}For Android 11+ Wireless Debugging, you may need USB first.${NC}"
    read -p "Check USB connection? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_usb_connection
    fi
    
    # Step 3: Try wireless connection
    echo ""
    if ! connect_wireless; then
        echo -e "${YELLOW}Direct port 5555 connection failed.${NC}"
        echo ""
        
        # Try Android 11+ wireless debugging
        try_wireless_debugging
    fi
    
    # Show final status
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if show_status; then
        # Test the connection
        test_connection
        
        # Show quick commands
        show_quick_commands
        
        # Offer to start control center
        echo ""
        read -p "Launch Control Center? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] && [ -f "./control.sh" ]; then
            ./control.sh
        elif [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}control.sh not found in current directory${NC}"
        fi
    else
        echo -e "${RED}Could not establish wireless connection${NC}"
        echo ""
        echo "Next steps for Android 11+:"
        echo "1. Connect phone via USB first"
        echo "2. Enable USB debugging AND Wireless Debugging"
        echo "3. Run 'adb pair' with pairing code OR"
        echo "4. Use Wireless Debugging port directly"
        echo ""
        echo "For older Android:"
        echo "1. Connect via USB"
        echo "2. Run: adb tcpip 5555"
        echo "3. Disconnect USB"
        echo "4. Run: adb connect $PHONE_IP:5555"
    fi
}

# Run main function
main

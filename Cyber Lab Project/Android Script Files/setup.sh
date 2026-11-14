#!/bin/bash
# setup.sh - Initial wireless ADB setup with Android 11+ support

# Configuration - These will be updated by config.sh
KALI_IP="192.168.1.11"
PHONE_IP="192.168.1.9"
DEFAULT_PORT="5555"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         WIRELESS ADB SETUP - ANDROID 11+ FOCUS        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Network Configuration:${NC}"
echo -e "${YELLOW}📱 Phone IP:${NC} $PHONE_IP"
echo -e "${YELLOW}💻 Kali IP:${NC}  $KALI_IP"
echo -e "${YELLOW}🔌 Default Port:${NC} $DEFAULT_PORT"
echo -e "${YELLOW}📶 Wireless Debug Port:${NC} Variable (4-5 digits)"
echo ""

echo -e "${GREEN}=== STEP 1: Prepare Your Phone ===${NC}"
echo ""
echo -e "${PURPLE}For ALL Android versions:${NC}"
echo "1. Go to Settings → About Phone"
echo "2. Tap 'Build Number' 7 times to enable Developer Options"
echo "3. Go back to Settings → Developer Options"
echo ""
echo -e "${CYAN}For Android 11 and ABOVE (RECOMMENDED):${NC}"
echo "4. Enable 'USB debugging'"
echo "5. Enable 'Wireless debugging'"
echo "6. Tap 'Wireless debugging' to see pairing options"
echo ""
echo -e "${CYAN}For Android 10 and below:${NC}"
echo "4. Enable 'USB debugging'"
echo "5. Look for 'ADB over network' or similar option"
echo "6. OR Install 'WiFi ADB' app from Play Store"
echo ""
read -p "Press Enter when Developer Options are enabled..."

echo ""
echo -e "${GREEN}=== STEP 2: USB Connection (Required for initial setup) ===${NC}"
echo ""
echo -e "${YELLOW}⚠️ IMPORTANT for Android 11+:${NC}"
echo "You MUST connect via USB first to authorize and enable wireless debugging."
echo ""
read -p "Connect your phone via USB now, then press Enter..."

# Check USB connection
echo ""
echo -e "${CYAN}Checking USB connection...${NC}"
adb kill-server 2>/dev/null
sleep 1
adb start-server
sleep 2

if adb devices | grep -q ".*device$"; then
    echo -e "${GREEN}✓ USB device detected${NC}"
    
    # Authorize dialog should appear on phone
    echo ""
    echo -e "${YELLOW}📱 On your phone:${NC}"
    echo "Look for 'Allow USB debugging?' dialog"
    echo "Check 'Always allow from this computer'"
    echo "Tap 'Allow'"
    echo ""
    read -p "Press Enter after authorizing USB debugging..."
    
    # For Android 11+, enable wireless debugging via ADB
    echo -e "${CYAN}Enabling wireless debugging via ADB...${NC}"
    adb shell settings put global adb_wifi_enabled 1
    echo "Wireless debugging enabled in settings"
    
    # Set TCP mode for older Android compatibility
    echo -e "${CYAN}Setting up TCP/IP mode...${NC}"
    adb tcpip $DEFAULT_PORT
    sleep 3
    echo -e "${GREEN}✓ TCP/IP mode enabled on port $DEFAULT_PORT${NC}"
    
else
    echo -e "${RED}✗ No USB device detected${NC}"
    echo ""
    echo "Please ensure:"
    echo "1. USB cable is properly connected"
    echo "2. USB debugging is ENABLED in Developer Options"
    echo "3. On your phone: Check for 'USB debugging connected' notification"
    echo "4. Try different USB cable or port"
    echo ""
    echo -e "${YELLOW}Without USB connection, Android 11+ wireless setup may fail.${NC}"
    echo ""
    read -p "Try USB connection again? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        adb devices
        echo ""
        read -p "Press Enter if device is now detected..."
    fi
fi

echo ""
echo -e "${GREEN}=== STEP 3: Network Verification ===${NC}"
echo ""

# Check if phone is reachable via WiFi
echo -n "Pinging phone ($PHONE_IP)... "
if ping -c 2 -W 1 $PHONE_IP > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Reachable${NC}"
    SAME_NETWORK=true
else
    echo -e "${RED}✗ Not reachable${NC}"
    SAME_NETWORK=false
    
    echo ""
    echo -e "${YELLOW}Network troubleshooting:${NC}"
    echo "1. Ensure both devices are on SAME WiFi network"
    echo "2. Check phone WiFi IP: Settings → Wi-Fi → Tap connected network"
    echo "3. Check Kali network: ip addr show"
    echo "4. Try turning phone WiFi off/on"
    echo "5. Common network patterns:"
    echo "   - Home: 192.168.1.x, 192.168.0.x"
    echo "   - Hotspot: 192.168.43.x, 192.168.137.x"
    echo ""
    
    # Ask for correct phone IP
    read -p "Enter your phone's WiFi IP (or press Enter to use $PHONE_IP): " user_ip
    if [ -n "$user_ip" ]; then
        PHONE_IP=$user_ip
        echo "Using phone IP: $PHONE_IP"
    fi
    
    echo -n "Testing ping to $PHONE_IP... "
    if ping -c 2 -W 1 $PHONE_IP > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Reachable${NC}"
        SAME_NETWORK=true
    else
        echo -e "${RED}✗ Still not reachable${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== STEP 4: Android 11+ Wireless Debugging Setup ===${NC}"
echo ""
echo -e "${CYAN}Choose your connection method:${NC}"
echo ""
echo "1. ${GREEN}Wireless Debugging (Android 11+ Recommended)${NC}"
echo "   - Uses secure pairing"
echo "   - Works with screen locked"
echo "   - More reliable"
echo ""
echo "2. ${YELLOW}Legacy ADB over WiFi (Android 10 and below)${NC}"
echo "   - Uses port $DEFAULT_PORT"
echo "   - Requires ADB over network enabled"
echo ""
read -p "Select method (1 or 2): " method_choice
echo ""

case $method_choice in
    1)
        # Android 11+ Wireless Debugging
        echo -e "${PURPLE}📱 On Your Phone:${NC}"
        echo "1. Go to Settings → Developer Options"
        echo "2. Ensure 'Wireless Debugging' is ON"
        echo "3. Tap 'Wireless Debugging'"
        echo "4. You'll see two options:"
        echo "   a) 'Pair device with pairing code'"
        echo "   b) 'IP address & port' (for connecting after pairing)"
        echo ""
        
        echo -e "${CYAN}Pairing Process:${NC}"
        echo "1. Tap 'Pair device with pairing code'"
        echo "2. Note the 6-digit pairing code"
        echo "3. Note the pairing port (4 digits)"
        echo ""
        
        read -p "Enter pairing port (4 digits): " pair_port
        read -p "Enter 6-digit pairing code: " pair_code
        
        if [ -n "$pair_port" ] && [ -n "$pair_code" ]; then
            echo "Pairing device at $PHONE_IP:$pair_port..."
            adb pair $PHONE_IP:$pair_port $pair_code
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Pairing successful!${NC}"
                
                # Now connect using wireless debugging port
                echo ""
                echo -e "${PURPLE}📱 On Your Phone:${NC}"
                echo "Go back to 'Wireless Debugging' screen"
                echo "Note the 'IP address & port' (different from pairing port)"
                echo ""
                
                read -p "Enter wireless debugging port (4-5 digits): " wd_port
                
                if [ -n "$wd_port" ]; then
                    echo "Connecting to $PHONE_IP:$wd_port..."
                    adb connect $PHONE_IP:$wd_port
                    
                    if adb devices | grep -q "$PHONE_IP:$wd_port.*device"; then
                        echo -e "${GREEN}✓ Wireless Debugging connection established!${NC}"
                        CONNECTED_PORT=$wd_port
                        METHOD="wireless_debugging"
                    fi
                fi
            else
                echo -e "${RED}✗ Pairing failed${NC}"
                echo "Make sure Wireless Debugging is ON and phone is unlocked"
            fi
        else
            echo "Invalid input, skipping pairing..."
        fi
        ;;
        
    2)
        # Legacy ADB over WiFi
        echo -e "${CYAN}Legacy ADB over WiFi setup:${NC}"
        echo ""
        
        if [ "$SAME_NETWORK" = false ]; then
            echo -e "${RED}Phone not reachable via ping. Connection may fail.${NC}"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        
        echo "Attempting connection to $PHONE_IP:$DEFAULT_PORT..."
        adb connect $PHONE_IP:$DEFAULT_PORT
        
        sleep 2
        
        if adb devices | grep -q "$PHONE_IP:$DEFAULT_PORT.*device"; then
            echo -e "${GREEN}✓ Legacy wireless connection established!${NC}"
            CONNECTED_PORT=$DEFAULT_PORT
            METHOD="legacy_adb"
        else
            echo -e "${RED}✗ Legacy connection failed${NC}"
            echo "For Android 10 and below:"
            echo "1. Install 'WiFi ADB' app from Play Store"
            echo "2. Launch it and enable ADB over WiFi"
            echo "3. Try connecting again"
        fi
        ;;
        
    *)
        echo "Invalid choice, using Wireless Debugging method..."
        ;;
esac

echo ""
echo -e "${GREEN}=== STEP 5: Connection Verification ===${NC}"
echo ""

# Check if connected
CONNECTED_DEVICE=$(adb devices | grep "$PHONE_IP")
if [ -n "$CONNECTED_DEVICE" ]; then
    echo -e "${GREEN}✅ CONNECTION SUCCESSFUL!${NC}"
    echo "Connected device: $CONNECTED_DEVICE"
    echo ""
    
    # Get device info
    CONNECTED_ADDR=$(echo "$CONNECTED_DEVICE" | grep -o "$PHONE_IP:[0-9]*")
    MODEL=$(adb -s $CONNECTED_ADDR shell getprop ro.product.model 2>/dev/null || echo "Unknown")
    ANDROID=$(adb -s $CONNECTED_ADDR shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    SERIAL=$(adb -s $CONNECTED_ADDR shell getprop ro.serialno 2>/dev/null | head -c 12 || echo "Unknown")
    
    echo -e "${CYAN}Device Information:${NC}"
    echo "  📱 Model:      $MODEL"
    echo "  🤖 Android:    $ANDROID"
    echo "  🔢 Serial:     $SERIAL"
    echo "  🌐 Connection: $METHOD"
    echo "  🔌 Port:       $CONNECTED_PORT"
    echo ""
    
    # Test basic commands
    echo -e "${CYAN}Testing basic ADB commands:${NC}"
    echo -n "  Shell access: "
    if adb -s $CONNECTED_ADDR shell echo "test" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Working${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    
    echo -n "  File system: "
    if adb -s $CONNECTED_ADDR shell ls /sdcard > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Accessible${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    
    # Save configuration
    echo ""
    echo -e "${CYAN}Saving configuration...${NC}"
    echo "KALI_IP=$KALI_IP" > wireless_adb.conf
    echo "PHONE_IP=$PHONE_IP" >> wireless_adb.conf
    echo "CONNECTED_PORT=$CONNECTED_PORT" >> wireless_adb.conf
    echo "CONNECTION_METHOD=$METHOD" >> wireless_adb.conf
    echo "LAST_CONNECTED=$(date +"%Y-%m-%d %H:%M:%S")" >> wireless_adb.conf
    echo "DEVICE_MODEL=$MODEL" >> wireless_adb.conf
    echo "ANDROID_VERSION=$ANDROID" >> wireless_adb.conf
    
    echo -e "${GREEN}✓ Configuration saved to wireless_adb.conf${NC}"
    echo ""
    echo -e "${BLUE}Setup complete! You can now use wireless ADB.${NC}"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo "1. You can disconnect USB cable now"
    echo "2. Run: ./connect.sh (for reconnection)"
    echo "3. Run: ./control.sh (for full control panel)"
    echo ""
    echo -e "${YELLOW}Note:${NC} For Android 11+, wireless connection may persist"
    echo "even after reboot until you toggle Wireless Debugging off."
    
else
    echo -e "${RED}❌ CONNECTION FAILED${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting steps:${NC}"
    echo ""
    echo "1. ${CYAN}For Android 11+:${NC}"
    echo "   - Ensure 'Wireless Debugging' is still ON"
    echo "   - Phone screen must be unlocked for initial connection"
    echo "   - Try re-pairing with a new code"
    echo ""
    echo "2. ${CYAN}Check network:${NC}"
    echo "   - Run: ping $PHONE_IP"
    echo "   - Ensure same WiFi network"
    echo "   - Disable VPN on either device"
    echo ""
    echo "3. ${CYAN}ADB issues:${NC}"
    echo "   - Run: adb kill-server && adb start-server"
    echo "   - Run: adb devices"
    echo "   - Check if phone appears in list"
    echo ""
    echo "4. ${CYAN}Alternative approach:${NC}"
    echo "   - Use USB connection first"
    echo "   - Run: adb tcpip 5555"
    echo "   - Disconnect USB"
    echo "   - Run: adb connect $PHONE_IP:5555"
    echo ""
fi

echo ""
echo -e "${GREEN}Setup script completed.${NC}"
echo "Phone IP: $PHONE_IP"
echo "Kali IP:  $KALI_IP"

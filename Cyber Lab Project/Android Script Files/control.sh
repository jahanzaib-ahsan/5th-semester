#!/bin/bash
# control.sh - Modern Wireless ADB Control Center
# Android 11+ Compatible with Modern UI

# Configuration - These will be updated by config.sh
KALI_IP="192.168.1.11"
PHONE_IP="192.168.1.9"

# Modern Colors
RED='\033[1;38;5;196m'
GREEN='\033[1;38;5;46m'
YELLOW='\033[1;38;5;226m'
BLUE='\033[1;38;5;39m'
PURPLE='\033[1;38;5;129m'
CYAN='\033[1;38;5;51m'
ORANGE='\033[1;38;5;208m'
PINK='\033[1;38;5;205m'
LIME='\033[1;38;5;118m'
NC='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
ARROW="➜"
PHONE="📱"
COMPUTER="💻"
BATTERY="🔋"
NETWORK="📡"
FOLDER="📁"
CAMERA="📸"
VIDEO="🎥"
APPS="📦"
SETTINGS="⚙️"
POWER="🔌"
REBOOT="🔄"
TERMINAL="💻"
INFO="ℹ️"
BACKUP="💾"
CONTROL="🎮"
SYNC="🔄"
EXIT="🚪"

# Configuration file
CONFIG_FILE="wireless_adb.conf"

# Function to get connection details from config
get_connection_details() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null
        if [ -n "$CONNECTED_PORT" ]; then
            PHONE="${PHONE_IP}:${CONNECTED_PORT}"
            ADB_CMD="adb -s $PHONE"
            return 0
        fi
    fi
    
    CONNECTED_DEVICE=$(adb devices | grep "$PHONE_IP" | grep -o "$PHONE_IP:[0-9]*" | head -1)
    if [ -n "$CONNECTED_DEVICE" ]; then
        PHONE="$CONNECTED_DEVICE"
        ADB_CMD="adb -s $PHONE"
        return 0
    fi
    
    return 1
}

# Modern Header
show_header() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${PURPLE}                    WIRELESS CONTROL CENTER                    ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}${CYAN}              Android 11+ Ready • Modern Interface              ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    if ! get_connection_details; then
        echo -e "${RED}${CROSS} No wireless connection detected!${NC}"
        echo -e "${YELLOW}Run ./connect.sh first to establish connection${NC}"
        echo ""
        exit 1
    fi
    
    # Test connection
    if ! timeout 2 $ADB_CMD shell getprop ro.product.model > /dev/null 2>&1; then
        echo -e "${YELLOW}${ARROW} Reconnecting...${NC}"
        adb connect $PHONE
        sleep 2
    fi
    
    # Get device info
    MODEL=$($ADB_CMD shell getprop ro.product.model 2>/dev/null || echo "Unknown")
    ANDROID=$($ADB_CMD shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    BATTERY_LEVEL=$($ADB_CMD shell dumpsys battery 2>/dev/null | grep level | awk '{print $2}' || echo "N/A")
    API_LEVEL=$($ADB_CMD shell getprop ro.build.version.sdk 2>/dev/null || echo "Unknown")
    DEVICE_NAME=$($ADB_CMD shell getprop ro.product.device 2>/dev/null || echo "Unknown")
    
    # Status bar
    echo -e "${GREEN}${CHECK} CONNECTED ${NC}${BLUE}│${NC} ${PHONE} ${MODEL} ${BLUE}│${NC} ${BATTERY} ${BATTERY_LEVEL}% ${BLUE}│${NC} 🤖 Android ${ANDROID}"
    echo -e "${BLUE}────────────┼──────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}Device:${NC} ${DEVICE_NAME} ${BLUE}│${NC} ${CYAN}API:${NC} ${API_LEVEL} ${BLUE}│${NC} ${CYAN}Connection:${NC} ${PHONE}"
    echo -e "${BLUE}────────────┴──────────────────────────────────────────────────${NC}"
    echo ""
}

# Modern Menu
show_menu() {
    while true; do
        show_header
        
        # Menu Grid Layout
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                     CONTROL PANEL                       ║${NC}"
        echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
        
        # Row 1
        echo -e "${PURPLE}║${NC}  ${GREEN}1.${NC} ${INFO} System Info      ${BLUE}│${NC} ${GREEN}2.${NC} ${CAMERA} Screenshot     ${BLUE}│${NC} ${GREEN}3.${NC} ${VIDEO} Screen Record   ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}Quick device overview${NC}             ${BLUE}│${NC} ${CYAN}Capture screen${NC}              ${BLUE}│${NC} ${CYAN}Record video${NC}             ${PURPLE}║${NC}"
        
        # Row 2
        echo -e "${PURPLE}║${NC}  ${GREEN}4.${NC} ${FOLDER} File Explorer   ${BLUE}│${NC} ${GREEN}5.${NC} ${TERMINAL} ADB Shell     ${BLUE}│${NC} ${GREEN}6.${NC} ${APPS} App Manager     ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}Browse device files${NC}              ${BLUE}│${NC} ${CYAN}Command terminal${NC}            ${BLUE}│${NC} ${CYAN}Manage applications${NC}       ${PURPLE}║${NC}"
        
        # Row 3
        echo -e "${PURPLE}║${NC}  ${GREEN}7.${NC} ${NETWORK} Network Info   ${BLUE}│${NC} ${GREEN}8.${NC} ${BACKUP} Backup Data    ${BLUE}│${NC} ${GREEN}9.${NC} ${CONTROL} Input Controls ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}Network status${NC}                  ${BLUE}│${NC} ${CYAN}Backup files${NC}                 ${BLUE}│${NC} ${CYAN}Remote control${NC}            ${PURPLE}║${NC}"
        
        # Row 4
        echo -e "${PURPLE}║${NC}  ${GREEN}10.${NC} ${SETTINGS} Device Settings ${BLUE}│${NC} ${GREEN}11.${NC} ${SYNC} Quick Actions   ${BLUE}│${NC} ${GREEN}12.${NC} ${REBOOT} Reboot Phone  ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  ${CYAN}Open settings${NC}                   ${BLUE}│${NC} ${CYAN}Toggle features${NC}              ${BLUE}│${NC} ${CYAN}Restart device${NC}            ${PURPLE}║${NC}"
        
        echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
        
        # Bottom options
        echo -e "${PURPLE}║${NC}  ${RED}13.${NC} ${POWER} Disconnect       ${BLUE}│${NC} ${ORANGE}14.${NC} 🔄 Refresh Connection ${BLUE}│${NC} ${LIME}0.${NC} ${EXIT} Exit            ${PURPLE}║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC} ${YELLOW}Select option [0-14]:${NC} \c"
        read -n 2 -r choice
        echo -e "${BLUE}│${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        case $choice in
            1) system_info ;;
            2) take_screenshot ;;
            3) screen_record ;;
            4) file_explorer ;;
            5) adb_shell ;;
            6) app_manager ;;
            7) network_info ;;
            8) backup_data ;;
            9) input_controls ;;
            10) device_settings ;;
            11) quick_actions ;;
            12) reboot_options ;;
            13) disconnect_device ;;
            14) refresh_connection ;;
            0) exit_control ;;
            *) 
                echo -e "${RED}Invalid option! Press Enter...${NC}"
                read -n 1
                ;;
        esac
    done
}

# Modern System Info
system_info() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                     SYSTEM INFORMATION                    ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    $ADB_CMD shell "
        echo '${GREEN}=== DEVICE INFORMATION ===${NC}'
        echo 'Model:    \$(getprop ro.product.model)'
        echo 'Brand:    \$(getprop ro.product.brand)'
        echo 'Device:   \$(getprop ro.product.device)'
        echo 'Android:  \$(getprop ro.build.version.release)'
        echo 'API:      \$(getprop ro.build.version.sdk)'
        echo 'Build:    \$(getprop ro.build.id)'
        echo ''
        echo '${GREEN}=== STORAGE ===${NC}'
        df -h 2>/dev/null | head -5 || echo 'Storage info unavailable'
        echo ''
        echo '${GREEN}=== MEMORY ===${NC}'
        free -m 2>/dev/null || echo 'Memory info unavailable'
        echo ''
        echo '${GREEN}=== BATTERY ===${NC}'
        dumpsys battery 2>/dev/null | grep -E 'level|status|health|temperature|voltage' || echo 'Battery info unavailable'
        echo ''
        echo '${GREEN}=== CPU ===${NC}'
        cat /proc/cpuinfo | grep 'processor\|model name' | head -4 || echo 'CPU info unavailable'
    "
    
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -n 1
}

# Modern Screenshot
take_screenshot() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                      SCREENSHOT                         ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
    
    echo -e "${YELLOW}${ARROW} Capturing screenshot...${NC}"
    
    # Different methods for different Android versions
    if [ "$API_LEVEL" -ge 30 ]; then
        echo -e "${CYAN}Using Android 11+ method...${NC}"
        $ADB_CMD exec-out screencap -p > "$FILENAME" 2>/dev/null
    else
        $ADB_CMD shell screencap -p /sdcard/screen.png
        $ADB_CMD pull /sdcard/screen.png "$FILENAME"
        $ADB_CMD shell rm -f /sdcard/screen.png 2>/dev/null
    fi
    
    if [ -s "$FILENAME" ]; then
        echo -e "${GREEN}${CHECK} Screenshot saved: ${NC}${FILENAME}"
        echo ""
        
        # Display image info
        if command -v file &> /dev/null; then
            IMG_INFO=$(file "$FILENAME")
            IMG_SIZE=$(du -h "$FILENAME" | cut -f1)
            echo -e "${CYAN}Image Info:${NC}"
            echo -e "  Size: $IMG_SIZE"
            echo -e "  Type: $(echo $IMG_INFO | cut -d: -f2-)"
        fi
        
        # Ask to open
        echo ""
        read -p "Open screenshot? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v display &> /dev/null; then
                display "$FILENAME" &
            elif command -v eog &> /dev/null; then
                eog "$FILENAME" &
            else
                echo -e "${YELLOW}No image viewer found${NC}"
            fi
        fi
    else
        echo -e "${RED}${CROSS} Failed to capture screenshot${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -n 1
}

# Modern Screen Record
screen_record() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                    SCREEN RECORDING                    ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    if [ "$API_LEVEL" -ge 30 ]; then
        echo -e "${YELLOW}⚠️  Note: Android 11+ may require screen recording permission${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}Recording Options:${NC}"
    echo "1. Quick record (10 seconds)"
    echo "2. Custom duration"
    echo "3. Record with audio"
    echo "4. Cancel"
    echo ""
    
    read -p "Select option [1-4]: " record_choice
    
    case $record_choice in
        1) duration=10 ;;
        2)
            read -p "Duration (seconds, max 180): " duration
            if ! [[ "$duration" =~ ^[0-9]+$ ]] || [ "$duration" -gt 180 ]; then
                duration=180
                echo -e "${YELLOW}Capped at 180 seconds${NC}"
            fi
            ;;
        3)
            duration=10
            echo -e "${YELLOW}Audio recording may not work on all devices${NC}"
            ;;
        4) return ;;
        *) return ;;
    esac
    
    VIDFILE="recording_$(date +%Y%m%d_%H%M%S).mp4"
    
    echo ""
    echo -e "${YELLOW}${ARROW} Recording for ${duration} seconds...${NC}"
    echo -e "${CYAN}[${BLUE}#${CYAN}]${NC} \c"
    
    $ADB_CMD shell screenrecord --bit-rate 4M --time-limit $duration /sdcard/recording.mp4 2>/dev/null &
    RECORD_PID=$!
    
    # Progress bar
    for i in $(seq 1 $duration); do
        sleep 1
        echo -n "█"
    done
    echo ""
    
    wait $RECORD_PID 2>/dev/null
    sleep 2
    
    echo -e "${YELLOW}${ARROW} Downloading recording...${NC}"
    $ADB_CMD pull /sdcard/recording.mp4 "$VIDFILE" 2>/dev/null
    $ADB_CMD shell rm -f /sdcard/recording.mp4 2>/dev/null
    
    if [ -f "$VIDFILE" ] && [ -s "$VIDFILE" ]; then
        echo -e "${GREEN}${CHECK} Recording saved: ${NC}${VIDFILE}"
        VIDEO_SIZE=$(du -h "$VIDFILE" | cut -f1)
        echo -e "${CYAN}File Size:${NC} $VIDEO_SIZE"
        
        # Ask to play
        echo ""
        read -p "Play recording? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v mpv &> /dev/null; then
                mpv --no-terminal "$VIDFILE" &
            elif command -v vlc &> /dev/null; then
                vlc "$VIDFILE" &
            else
                echo -e "${YELLOW}No video player found${NC}"
            fi
        fi
    else
        echo -e "${RED}${CROSS} Recording failed${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -n 1
}

# Modern File Explorer
file_explorer() {
    current_path="/sdcard"
    
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}${CYAN}                    FILE EXPLORER                      ${NC}${BLUE}│${NC}"
        echo -e "${BLUE}│${NC}${YELLOW}                    $current_path                       ${NC}${BLUE}│${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        # Get directory listing
        echo -e "${GREEN}Directories:${NC}"
        echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
        DIRS=$($ADB_CMD shell "cd \"$current_path\" && ls -la 2>/dev/null | grep '^d' | head -15")
        if [ -n "$DIRS" ]; then
            echo "$DIRS" | awk '{print "📁 " $9}'
        else
            echo "No directories"
        fi
        
        echo ""
        echo -e "${GREEN}Files:${NC}"
        echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
        FILES=$($ADB_CMD shell "cd \"$current_path\" && ls -la 2>/dev/null | grep -v '^d' | head -15")
        if [ -n "$FILES" ]; then
            echo "$FILES" | awk '{if ($9 != "") print "📄 " $9 " (" $5 " bytes)"}'
        else
            echo "No files"
        fi
        
        echo ""
        echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}Commands:${NC}"
        echo "  cd <name>    - Change directory"
        echo "  get <file>   - Download file"
        echo "  put <file>   - Upload file"
        echo "  ..           - Go up"
        echo "  ls           - Refresh"
        echo "  exit         - Back to menu"
        echo ""
        
        read -p "${ARROW} " cmd
        
        case $cmd in
            cd\ *)
                dir=$(echo $cmd | cut -d' ' -f2)
                if [ "$dir" = ".." ]; then
                    current_path=$(dirname "$current_path")
                else
                    new_path="$current_path/$dir"
                    if $ADB_CMD shell "cd \"$new_path\" 2>/dev/null"; then
                        current_path="$new_path"
                    else
                        echo -e "${RED}Directory not found${NC}"
                        sleep 1
                    fi
                fi
                ;;
            get\ *)
                file=$(echo $cmd | cut -d' ' -f2-)
                echo -e "${YELLOW}Downloading $file...${NC}"
                $ADB_CMD pull "$current_path/$file" .
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}${CHECK} Downloaded${NC}"
                else
                    echo -e "${RED}${CROSS} Failed${NC}"
                fi
                sleep 1
                ;;
            put\ *)
                file=$(echo $cmd | cut -d' ' -f2-)
                if [ -f "$file" ]; then
                    echo -e "${YELLOW}Uploading $file...${NC}"
                    $ADB_CMD push "$file" "$current_path/"
                    echo -e "${GREEN}${CHECK} Uploaded${NC}"
                else
                    echo -e "${RED}${CROSS} File not found${NC}"
                fi
                sleep 1
                ;;
            ..) current_path=$(dirname "$current_path") ;;
            ls) continue ;;
            exit) return ;;
            *) echo -e "${RED}Unknown command${NC}"; sleep 1 ;;
        esac
    done
}

# Modern ADB Shell
adb_shell() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                    ADB SHELL                          ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}${YELLOW}          Type 'exit' to return to menu                ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}Quick commands:${NC}"
    echo "  pwd                    - Current directory"
    echo "  ls -la                 - List files"
    echo "  df -h                  - Disk usage"
    echo "  free -m                - Memory usage"
    echo "  getprop                - Device properties"
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
    
    $ADB_CMD shell
}

# Modern App Manager
app_manager() {
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}${CYAN}                    APP MANAGER                       ${NC}${BLUE}│${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        echo -e "${GREEN}1.${NC} ${CYAN}List User Apps${NC}"
        echo -e "${GREEN}2.${NC} ${CYAN}List System Apps${NC}"
        echo -e "${GREEN}3.${NC} ${CYAN}Install APK${NC}"
        echo -e "${GREEN}4.${NC} ${CYAN}Uninstall App${NC}"
        echo -e "${GREEN}5.${NC} ${CYAN}Clear App Data${NC}"
        echo -e "${GREEN}6.${NC} ${CYAN}Launch App${NC}"
        echo -e "${GREEN}7.${NC} ${CYAN}Force Stop App${NC}"
        echo -e "${GREEN}8.${NC} ${CYAN}Back to Menu${NC}"
        echo ""
        
        read -p "${ARROW} Select option [1-8]: " app_choice
        
        case $app_choice in
            1)
                echo ""
                echo -e "${YELLOW}User Applications:${NC}"
                echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
                $ADB_CMD shell pm list packages -3 | sort | head -20 | sed 's/package://g' | awk '{print "📱 " $1}'
                ;;
            2)
                echo ""
                echo -e "${YELLOW}System Applications:${NC}"
                echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
                $ADB_CMD shell pm list packages -s | sort | head -20 | sed 's/package://g' | awk '{print "⚙️  " $1}'
                ;;
            3)
                echo ""
                echo -e "${YELLOW}Available APK files:${NC}"
                find . -maxdepth 1 -name "*.apk" -type f | head -5 | awk '{print "📦 " $1}'
                echo ""
                read -p "APK filename: " apk_file
                if [ -f "$apk_file" ]; then
                    echo -e "${YELLOW}Installing...${NC}"
                    $ADB_CMD install "$apk_file"
                else
                    echo -e "${RED}File not found${NC}"
                fi
                ;;
            4)
                read -p "Package name: " package
                if [ -n "$package" ]; then
                    echo -e "${YELLOW}Uninstalling...${NC}"
                    $ADB_CMD uninstall "$package"
                fi
                ;;
            5)
                read -p "Package name: " package
                if [ -n "$package" ]; then
                    echo -e "${YELLOW}Clearing data...${NC}"
                    $ADB_CMD shell pm clear "$package"
                fi
                ;;
            6)
                read -p "Package name: " package
                if [ -n "$package" ]; then
                    echo -e "${YELLOW}Launching...${NC}"
                    $ADB_CMD shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
                fi
                ;;
            7)
                read -p "Package name: " package
                if [ -n "$package" ]; then
                    echo -e "${YELLOW}Force stopping...${NC}"
                    $ADB_CMD shell am force-stop "$package"
                fi
                ;;
            8) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read -n 1
    done
}

# Modern Network Info
network_info() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                    NETWORK INFORMATION                  ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    $ADB_CMD shell "
        echo '${GREEN}=== WIFI CONNECTION ===${NC}'
        echo 'IP Address:'
        ip -4 addr show wlan0 2>/dev/null | grep inet | awk '{print \"  \" \$2}' || echo '  Not connected'
        echo ''
        echo '${GREEN}=== CONNECTION DETAILS ===${NC}'
        dumpsys wifi | grep -E 'SSID|BSSID|RSSI|frequency' | head -8 | sed 's/^/  /'
        echo ''
        echo '${GREEN}=== NETWORK STATS ===${NC}'
        cat /proc/net/dev 2>/dev/null | grep wlan0 | awk '{print \"  RX: \" \$2 \" bytes\\n  TX: \" \$10 \" bytes\"}' || echo '  No stats available'
        echo ''
        echo '${GREEN}=== DNS SERVERS ===${NC}'
        getprop | grep net.dns | head -4 | sed 's/^/  /' || echo '  Not available'
    "
    
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -n 1
}

# Modern Backup Data
backup_data() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                      BACKUP DATA                       ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${CYAN}Backup Options:${NC}"
    echo "1. 📸 Photos (DCIM)"
    echo "2. 📥 Downloads"
    echo "3. 🎥 Camera Photos"
    echo "4. 📁 Documents"
    echo "5. 🎵 Music"
    echo "6. 📄 Custom Folder"
    echo "7. Cancel"
    echo ""
    
    read -p "${ARROW} Select option [1-7]: " backup_choice
    
    case $backup_choice in
        1)
            echo -e "${YELLOW}Backing up Photos...${NC}"
            $ADB_CMD pull /sdcard/DCIM "$BACKUP_DIR/DCIM" 2>/dev/null
            ;;
        2)
            echo -e "${YELLOW}Backing up Downloads...${NC}"
            $ADB_CMD pull /sdcard/Download "$BACKUP_DIR/Download" 2>/dev/null
            ;;
        3)
            echo -e "${YELLOW}Backing up Camera...${NC}"
            $ADB_CMD pull /sdcard/DCIM/Camera "$BACKUP_DIR/Camera" 2>/dev/null
            ;;
        4)
            echo -e "${YELLOW}Backing up Documents...${NC}"
            $ADB_CMD pull /sdcard/Documents "$BACKUP_DIR/Documents" 2>/dev/null
            ;;
        5)
            echo -e "${YELLOW}Backing up Music...${NC}"
            $ADB_CMD pull /sdcard/Music "$BACKUP_DIR/Music" 2>/dev/null
            ;;
        6)
            read -p "Folder path: " folder
            if [ -n "$folder" ]; then
                folder_name=$(basename "$folder")
                echo -e "${YELLOW}Backing up $folder_name...${NC}"
                $ADB_CMD pull "$folder" "$BACKUP_DIR/$folder_name" 2>/dev/null
            fi
            ;;
        7) return ;;
        *) return ;;
    esac
    
    if [ $? -eq 0 ] && [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo -e "${GREEN}${CHECK} Backup completed!${NC}"
        echo -e "${CYAN}Location:${NC} $BACKUP_DIR"
        echo -e "${CYAN}Size:${NC} $BACKUP_SIZE"
    else
        echo -e "${RED}${CROSS} Backup failed${NC}"
        rm -rf "$BACKUP_DIR" 2>/dev/null
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -n 1
}

# Modern Input Controls
input_controls() {
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}${CYAN}                    INPUT CONTROLS                    ${NC}${BLUE}│${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        echo -e "${GREEN}1.${NC} ${CYAN}Send Text${NC}"
        echo -e "${GREEN}2.${NC} ${CYAN}Tap Screen${NC}"
        echo -e "${GREEN}3.${NC} ${CYAN}Swipe${NC}"
        echo -e "${GREEN}4.${NC} ${CYAN}Key Events${NC}"
        echo -e "${GREEN}5.${NC} ${CYAN}Back to Menu${NC}"
        echo ""
        
        read -p "${ARROW} Select option [1-5]: " input_choice
        
        case $input_choice in
            1)
                read -p "Text to send: " text
                if [ -n "$text" ]; then
                    $ADB_CMD shell input text "\"$text\""
                    echo -e "${GREEN}${CHECK} Text sent${NC}"
                fi
                ;;
            2)
                echo -e "${YELLOW}Enter coordinates (e.g., 500 500):${NC}"
                read -p "X Y: " x y
                if [[ "$x" =~ ^[0-9]+$ ]] && [[ "$y" =~ ^[0-9]+$ ]]; then
                    $ADB_CMD shell input tap $x $y
                    echo -e "${GREEN}${CHECK} Tap executed${NC}"
                else
                    echo -e "${RED}Invalid coordinates${NC}"
                fi
                ;;
            3)
                echo -e "${YELLOW}Enter swipe coordinates (e.g., 500 500 600 600):${NC}"
                read -p "X1 Y1 X2 Y2: " x1 y1 x2 y2
                if [[ "$x1" =~ ^[0-9]+$ ]] && [[ "$y1" =~ ^[0-9]+$ ]] && \
                   [[ "$x2" =~ ^[0-9]+$ ]] && [[ "$y2" =~ ^[0-9]+$ ]]; then
                    $ADB_CMD shell input swipe $x1 $y1 $x2 $y2 500
                    echo -e "${GREEN}${CHECK} Swipe executed${NC}"
                else
                    echo -e "${RED}Invalid coordinates${NC}"
                fi
                ;;
            4)
                echo -e "${YELLOW}Key Codes:${NC}"
                echo "  3: Home       24: Volume Up"
                echo "  4: Back       25: Volume Down"
                echo "  5: Call       26: Power"
                echo "  6: End Call   27: Camera"
                echo "  82: Menu      164: Volume Mute"
                echo ""
                read -p "Key code: " keycode
                if [[ "$keycode" =~ ^[0-9]+$ ]]; then
                    $ADB_CMD shell input keyevent $keycode
                    echo -e "${GREEN}${CHECK} Key event sent${NC}"
                else
                    echo -e "${RED}Invalid key code${NC}"
                fi
                ;;
            5) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
        
        sleep 1
    done
}

# Modern Device Settings
device_settings() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                    DEVICE SETTINGS                     ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}Quick Settings:${NC}"
    echo "1. ⚙️  Main Settings"
    echo "2. 📶 WiFi Settings"
    echo "3. 📱 Developer Options"
    echo "4. 🔊 Sound Settings"
    echo "5. 📳 Display Settings"
    echo "6. 🔋 Battery Settings"
    echo "7. 📞 Back to Menu"
    echo ""
    
    read -p "${ARROW} Select option [1-7]: " settings_choice
    
    case $settings_choice in
        1) $ADB_CMD shell am start -a android.settings.SETTINGS ;;
        2) $ADB_CMD shell am start -a android.settings.WIFI_SETTINGS ;;
        3) $ADB_CMD shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS ;;
        4) $ADB_CMD shell am start -a android.settings.SOUND_SETTINGS ;;
        5) $ADB_CMD shell am start -a android.settings.DISPLAY_SETTINGS ;;
        6) $ADB_CMD shell am start -a android.settings.BATTERY_SAVER_SETTINGS ;;
        7) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
    
    echo -e "${GREEN}${CHECK} Settings opened${NC}"
    sleep 1
}

# Modern Quick Actions
quick_actions() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                     QUICK ACTIONS                      ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}Toggles:${NC}"
    echo "1. 📶 Toggle WiFi"
    echo "2. 📳 Toggle Bluetooth"
    echo "3. 🔆 Toggle Flashlight"
    echo "4. 📸 Quick Screenshot"
    echo "5. 🌐 Open Browser"
    echo "6. 🎵 Play/Pause Media"
    echo "7. 📞 Back to Menu"
    echo ""
    
    read -p "${ARROW} Select option [1-7]: " quick_choice
    
    case $quick_choice in
        1)
            wifi_state=$($ADB_CMD shell settings get global wifi_on 2>/dev/null)
            if [ "$wifi_state" = "1" ]; then
                $ADB_CMD shell svc wifi disable
                echo -e "${RED}WiFi: OFF${NC}"
            else
                $ADB_CMD shell svc wifi enable
                echo -e "${GREEN}WiFi: ON${NC}"
            fi
            ;;
        2)
            bt_state=$($ADB_CMD shell settings get global bluetooth_on 2>/dev/null)
            if [ "$bt_state" = "1" ]; then
                $ADB_CMD shell service call bluetooth_manager 8 > /dev/null
                echo -e "${RED}Bluetooth: OFF${NC}"
            else
                $ADB_CMD shell service call bluetooth_manager 6 > /dev/null
                echo -e "${GREEN}Bluetooth: ON${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Toggling flashlight...${NC}"
            $ADB_CMD shell "input keyevent 26 && sleep 0.5 && input keyevent 26"
            ;;
        4)
            echo -e "${YELLOW}Taking quick screenshot...${NC}"
            $ADB_CMD shell input keyevent 120
            ;;
        5)
            echo -e "${YELLOW}Opening browser...${NC}"
            $ADB_CMD shell am start -a android.intent.action.VIEW -d http://google.com
            ;;
        6)
            echo -e "${YELLOW}Toggling media play/pause...${NC}"
            $ADB_CMD shell input keyevent 85
            ;;
        7) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
    
    sleep 1
}

# Modern Reboot Options
reboot_options() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                     REBOOT OPTIONS                     ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️  Warning: This will restart your phone${NC}"
    echo ""
    echo -e "${CYAN}Reboot Methods:${NC}"
    echo "1. 🔄 Normal Reboot"
    echo "2. ⚡ Fast Reboot"
    echo "3. 🔧 Recovery Mode"
    echo "4. 🔩 Bootloader"
    echo "5. 📞 Cancel"
    echo ""
    
    read -p "${ARROW} Select option [1-5]: " reboot_choice
    
    case $reboot_choice in
        1)
            echo -e "${YELLOW}Rebooting normally...${NC}"
            $ADB_CMD reboot
            echo -e "${GREEN}${CHECK} Reboot command sent${NC}"
            ;;
        2)
            echo -e "${YELLOW}Fast rebooting...${NC}"
            $ADB_CMD shell setprop ctl.restart zygote
            echo -e "${GREEN}${CHECK} Fast reboot initiated${NC}"
            ;;
        3)
            echo -e "${YELLOW}Rebooting to recovery...${NC}"
            $ADB_CMD reboot recovery
            echo -e "${GREEN}${CHECK} Recovery reboot command sent${NC}"
            ;;
        4)
            echo -e "${YELLOW}Rebooting to bootloader...${NC}"
            $ADB_CMD reboot bootloader
            echo -e "${GREEN}${CHECK} Bootloader reboot command sent${NC}"
            ;;
        5) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
    
    echo -e "${YELLOW}Phone will restart. Reconnect with ./connect.sh${NC}"
    sleep 3
}

# Modern Disconnect
disconnect_device() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                     DISCONNECT                         ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}Are you sure you want to disconnect?${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} ${CYAN}Disconnect only${NC}"
    echo -e "${GREEN}2.${NC} ${CYAN}Disconnect and clear config${NC}"
    echo -e "${GREEN}3.${NC} ${CYAN}Cancel${NC}"
    echo ""
    
    read -p "${ARROW} Select option [1-3]: " disconnect_choice
    
    case $disconnect_choice in
        1)
            adb disconnect $PHONE
            echo -e "${GREEN}${CHECK} Disconnected${NC}"
            ;;
        2)
            adb disconnect $PHONE
            rm -f "$CONFIG_FILE" 2>/dev/null
            echo -e "${GREEN}${CHECK} Disconnected and config cleared${NC}"
            ;;
        3) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
    
    sleep 2
    exit 0
}

# Refresh Connection
refresh_connection() {
    echo -e "${YELLOW}Refreshing connection...${NC}"
    adb disconnect $PHONE 2>/dev/null
    adb connect $PHONE
    sleep 2
    echo -e "${GREEN}${CHECK} Connection refreshed${NC}"
    sleep 1
}

# Exit Control Center
exit_control() {
    clear
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}${CYAN}                      GOODBYE!                          ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}${GREEN}          Wireless connection remains active            ${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${YELLOW}Thank you for using Wireless Control Center!${NC}"
    echo ""
    echo -e "${CYAN}To reconnect later:${NC} ./connect.sh"
    echo -e "${CYAN}To disconnect:${NC}     adb disconnect $PHONE"
    echo ""
    exit 0
}

# Start
get_connection_details
show_menu

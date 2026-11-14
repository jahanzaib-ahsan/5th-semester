#!/bin/bash
# config.sh - Configuration manager for Wireless ADB Toolkit
# Manages IP addresses and updates all related scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script files
SETUP_SCRIPT="setup.sh"
CONNECT_SCRIPT="connect.sh"
CONTROL_SCRIPT="control.sh"
CONFIG_FILE="wireless_adb.conf"
BACKUP_DIR="config_backups"

# Default values
DEFAULT_KALI_IP="192.168.137.197"
DEFAULT_PHONE_IP="192.168.137.189"
DEFAULT_PORT="5555"

# Function to load existing config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}Loaded existing configuration${NC}"
        return 0
    else
        # Set defaults
        KALI_IP="$DEFAULT_KALI_IP"
        PHONE_IP="$DEFAULT_PHONE_IP"
        PORT="$DEFAULT_PORT"
        return 1
    fi
}

# Function to save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Wireless ADB Configuration
# Generated on $(date)

KALI_IP="$KALI_IP"
PHONE_IP="$PHONE_IP"
PORT="$PORT"
LAST_UPDATED="$(date +"%Y-%m-%d %H:%M:%S")"

# Script files
SETUP_SCRIPT="$SETUP_SCRIPT"
CONNECT_SCRIPT="$CONNECT_SCRIPT"
CONTROL_SCRIPT="$CONTROL_SCRIPT"

# Network information
NETWORK_INFO="Same network: $(echo $KALI_IP | cut -d. -f1-3).x"
EOF
    
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

# Function to backup existing scripts
backup_scripts() {
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    echo -e "${CYAN}Creating backups...${NC}"
    
    for script in "$SETUP_SCRIPT" "$CONNECT_SCRIPT" "$CONTROL_SCRIPT"; do
        if [ -f "$script" ]; then
            cp "$script" "$BACKUP_DIR/${script}_backup_$timestamp"
            echo -e "  ${GREEN}✓${NC} $script"
        else
            echo -e "  ${YELLOW}⚠${NC} $script (not found)"
        fi
    done
    
    echo -e "${GREEN}Backups created in $BACKUP_DIR/${NC}"
}

# Function to update IP in a script
update_script_ip() {
    local script="$1"
    local old_kali_ip="$2"
    local new_kali_ip="$3"
    local old_phone_ip="$4"
    local new_phone_ip="$5"
    local port="$6"
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}  ✗ $script not found${NC}"
        return 1
    fi
    
    # Create temporary file
    local temp_file="${script}.tmp"
    
    # Process the file - replace all IP occurrences
    sed -e "s/$old_kali_ip/$new_kali_ip/g" \
        -e "s/$old_phone_ip/$new_phone_ip/g" \
        "$script" > "$temp_file"
    
    # Update specific variable assignments for each script
    case "$script" in
        "$CONNECT_SCRIPT")
            sed -i "s/KALI_IP=\"$old_kali_ip\"/KALI_IP=\"$new_kali_ip\"/g" "$temp_file"
            sed -i "s/PHONE_IP=\"$old_phone_ip\"/PHONE_IP=\"$new_phone_ip\"/g" "$temp_file"
            sed -i "s/DEFAULT_PORT=\"[0-9]*\"/DEFAULT_PORT=\"$port\"/g" "$temp_file"
            ;;
        "$SETUP_SCRIPT")
            sed -i "s/KALI_IP=\"$old_kali_ip\"/KALI_IP=\"$new_kali_ip\"/g" "$temp_file"
            sed -i "s/PHONE_IP=\"$old_phone_ip\"/PHONE_IP=\"$new_phone_ip\"/g" "$temp_file"
            sed -i "s/DEFAULT_PORT=\"[0-9]*\"/DEFAULT_PORT=\"$port\"/g" "$temp_file"
            ;;
        "$CONTROL_SCRIPT")
            sed -i "s/KALI_IP=\"$old_kali_ip\"/KALI_IP=\"$new_kali_ip\"/g" "$temp_file"
            sed -i "s/PHONE_IP=\"$old_phone_ip\"/PHONE_IP=\"$new_phone_ip\"/g" "$temp_file"
            # Update CONFIG_FILE reference if needed
            sed -i "s/CONFIG_FILE=.*/CONFIG_FILE=\"$CONFIG_FILE\"/g" "$temp_file"
            ;;
    esac
    
    # Replace original file
    mv "$temp_file" "$script"
    chmod +x "$script"
    
    echo -e "${GREEN}  ✓ $script updated${NC}"
    return 0
}

# Function to display current network info
show_network_info() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━ Network Information ━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Current Configuration:${NC}"
    echo -e "  💻 Kali IP:    ${GREEN}$KALI_IP${NC}"
    echo -e "  📱 Phone IP:   ${GREEN}$PHONE_IP${NC}"
    echo -e "  🔌 Port:       ${GREEN}$PORT${NC}"
    
    # Check if on same network
    KALI_NET=$(echo $KALI_IP | cut -d. -f1-3)
    PHONE_NET=$(echo $PHONE_IP | cut -d. -f1-3)
    
    if [ "$KALI_NET" = "$PHONE_NET" ]; then
        echo -e "  📶 Network:    ${GREEN}Same network ($KALI_NET.x)${NC}"
    else
        echo -e "  📶 Network:    ${RED}Different networks${NC}"
        echo -e "                  Kali: $KALI_NET.x"
        echo -e "                  Phone: $PHONE_NET.x"
    fi
    
    echo ""
    echo -e "${CYAN}Script Files:${NC}"
    for script in "$SETUP_SCRIPT" "$CONNECT_SCRIPT" "$CONTROL_SCRIPT"; do
        if [ -f "$script" ]; then
            echo -e "  ${GREEN}✓${NC} $script"
        else
            echo -e "  ${RED}✗${NC} $script (missing)"
        fi
    done
    echo ""
}

# Function to auto-detect Kali IP
detect_kali_ip() {
    echo -e "${CYAN}Detecting Kali IP addresses...${NC}"
    echo ""
    
    # Try different methods to get IP
    IPS=()
    
    # Method 1: ip addr show
    echo -e "Method 1: Network interfaces"
    ip -4 addr show | grep inet | awk '{print $2}' | cut -d/ -f1 | while read ip; do
        if [[ $ip != 127.* ]] && [[ $ip != 172.17.* ]] && [[ $ip != 172.18.* ]]; then
            echo -e "  ${GREEN}✓${NC} $ip"
            IPS+=("$ip")
        fi
    done
    
    # Method 2: hostname -I
    echo -e "\nMethod 2: All IPs"
    hostname -I | tr ' ' '\n' | while read ip; do
        if [ -n "$ip" ] && [[ $ip != 127.* ]] && [[ $ip != 172.17.* ]]; then
            echo -e "  ${GREEN}✓${NC} $ip"
            if [[ ! " ${IPS[@]} " =~ " ${ip} " ]]; then
                IPS+=("$ip")
            fi
        fi
    done
    
    echo ""
    
    if [ ${#IPS[@]} -eq 0 ]; then
        echo -e "${RED}No IP addresses detected${NC}"
        return 1
    fi
    
    # Let user choose
    echo -e "${CYAN}Select Kali IP address:${NC}"
    for i in "${!IPS[@]}"; do
        echo "  $((i+1)). ${IPS[$i]}"
    done
    echo "  0. Enter manually"
    
    read -p "Select [0-${#IPS[@]}]: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#IPS[@]} ]; then
        KALI_IP="${IPS[$((choice-1))]}"
        echo -e "${GREEN}Selected: $KALI_IP${NC}"
        return 0
    elif [ "$choice" = "0" ]; then
        return 1
    else
        echo -e "${RED}Invalid selection${NC}"
        return 1
    fi
}

# Function to get phone IP from user
get_phone_ip() {
    echo ""
    echo -e "${CYAN}Enter Phone IP Address${NC}"
    echo ""
    echo -e "${YELLOW}How to find phone IP:${NC}"
    echo "1. On phone: Settings → Wi-Fi"
    echo "2. Tap connected network"
    echo "3. Look for 'IP Address'"
    echo ""
    echo -e "${YELLOW}Common patterns:${NC}"
    echo "  Home WiFi:    192.168.1.x, 192.168.0.x"
    echo "  Hotspot:      192.168.43.x, 192.168.137.x"
    echo "  Office:       10.x.x.x, 172.16.x.x - 172.31.x.x"
    echo ""
    
    while true; do
        read -p "Phone IP address [$PHONE_IP]: " input_ip
        
        if [ -z "$input_ip" ]; then
            echo -e "${YELLOW}Using default: $PHONE_IP${NC}"
            break
        elif [[ $input_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            PHONE_IP="$input_ip"
            break
        else
            echo -e "${RED}Invalid IP format. Please use format: 192.168.1.100${NC}"
        fi
    done
}

# Function to get port from user
get_port() {
    echo ""
    echo -e "${CYAN}Enter ADB Port${NC}"
    echo ""
    echo -e "${YELLOW}Default port is 5555${NC}"
    echo "For Android 11+ Wireless Debugging, use the port shown on phone"
    echo ""
    
    read -p "ADB port [$PORT]: " input_port
    
    if [ -n "$input_port" ]; then
        if [[ $input_port =~ ^[0-9]+$ ]] && [ "$input_port" -ge 1024 ] && [ "$input_port" -le 65535 ]; then
            PORT="$input_port"
        else
            echo -e "${RED}Invalid port. Must be between 1024-65535${NC}"
            echo -e "${YELLOW}Using default: $PORT${NC}"
        fi
    fi
}

# Function to update all scripts
update_all_scripts() {
    local old_kali_ip="$1"
    local old_phone_ip="$2"
    
    echo ""
    echo -e "${CYAN}Updating script files...${NC}"
    echo ""
    
    # Update each script
    update_script_ip "$SETUP_SCRIPT" "$old_kali_ip" "$KALI_IP" "$old_phone_ip" "$PHONE_IP" "$PORT"
    update_script_ip "$CONNECT_SCRIPT" "$old_kali_ip" "$KALI_IP" "$old_phone_ip" "$PHONE_IP" "$PORT"
    update_script_ip "$CONTROL_SCRIPT" "$old_kali_ip" "$KALI_IP" "$old_phone_ip" "$PHONE_IP" "$PORT"
    
    echo ""
    echo -e "${GREEN}All scripts updated successfully!${NC}"
}

# Function to show main menu
show_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║         WIRELESS ADB CONFIGURATION MANAGER           ║${NC}"
        echo -e "${BLUE}║         Scripts: setup.sh, connect.sh, control.sh    ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        show_network_info
        
        echo -e "${PURPLE}━━━━━━━━━━━━━━━ Configuration Menu ━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "1. Auto-detect Kali IP"
        echo "2. Set Kali IP manually"
        echo "3. Set Phone IP"
        echo "4. Set ADB Port"
        echo "5. Update all scripts with current config"
        echo "6. Test network connectivity"
        echo "7. View current configuration"
        echo "8. Backup scripts before update"
        echo "9. Restore from backup"
        echo "0. Exit"
        echo ""
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        read -p "Select option [0-9]: " choice
        
        case $choice in
            1)
                detect_kali_ip
                if [ $? -eq 0 ]; then
                    save_config
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Enter Kali IP address [$KALI_IP]: " input_ip
                if [ -n "$input_ip" ]; then
                    if [[ $input_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                        KALI_IP="$input_ip"
                        save_config
                        echo -e "${GREEN}Kali IP updated${NC}"
                    else
                        echo -e "${RED}Invalid IP format${NC}"
                    fi
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                get_phone_ip
                save_config
                read -p "Press Enter to continue..."
                ;;
            4)
                get_port
                save_config
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                backup_scripts
                update_all_scripts "$DEFAULT_KALI_IP" "$DEFAULT_PHONE_IP"
                echo ""
                echo -e "${GREEN}✅ Configuration complete!${NC}"
                echo ""
                echo "You can now run:"
                echo "  ./setup.sh    - Initial setup"
                echo "  ./connect.sh  - Connect to phone"
                echo "  ./control.sh  - Control center"
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                echo -e "${CYAN}Testing network connectivity...${NC}"
                echo ""
                
                # Test Kali IP
                echo -n "Kali IP ($KALI_IP): "
                if ip addr show | grep -q "$KALI_IP"; then
                    echo -e "${GREEN}✓ Valid${NC}"
                else
                    echo -e "${YELLOW}⚠ Not assigned to any interface${NC}"
                fi
                
                # Test ping to phone
                echo -n "Pinging phone ($PHONE_IP): "
                if ping -c 2 -W 1 "$PHONE_IP" > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Reachable${NC}"
                else
                    echo -e "${RED}✗ Not reachable${NC}"
                    echo "  Make sure phone is on same network"
                fi
                
                read -p "Press Enter to continue..."
                ;;
            7)
                echo ""
                echo -e "${CYAN}Current Configuration:${NC}"
                echo ""
                echo "Kali IP:    $KALI_IP"
                echo "Phone IP:   $PHONE_IP"
                echo "Port:       $PORT"
                echo ""
                echo "Config file: $CONFIG_FILE"
                if [ -f "$CONFIG_FILE" ]; then
                    echo "Last updated: $(grep LAST_UPDATED "$CONFIG_FILE" | cut -d= -f2 | tr -d '"')"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            8)
                backup_scripts
                read -p "Press Enter to continue..."
                ;;
            9)
                echo ""
                echo -e "${CYAN}Restore from backup${NC}"
                echo ""
                
                if [ ! -d "$BACKUP_DIR" ]; then
                    echo -e "${RED}No backups found${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                # List backups
                backups=($(ls -1t "$BACKUP_DIR"/*.sh 2>/dev/null | head -10))
                
                if [ ${#backups[@]} -eq 0 ]; then
                    echo -e "${RED}No backup files found${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                echo "Recent backups:"
                for i in "${!backups[@]}"; do
                    filename=$(basename "${backups[$i]}")
                    echo "  $((i+1)). $filename"
                done
                echo "  0. Cancel"
                
                read -p "Select backup to restore [0-${#backups[@]}]: " backup_choice
                
                if [[ "$backup_choice" =~ ^[0-9]+$ ]] && [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le ${#backups[@]} ]; then
                    backup_file="${backups[$((backup_choice-1))]}"
                    echo "Restoring from $backup_file..."
                    
                    # Extract script name and restore
                    for script in "$SETUP_SCRIPT" "$CONNECT_SCRIPT" "$CONTROL_SCRIPT"; do
                        if [[ "$backup_file" == *"$script"* ]]; then
                            cp "$backup_file" "$script"
                            chmod +x "$script"
                            echo -e "${GREEN}✓ Restored $script${NC}"
                        fi
                    done
                fi
                
                read -p "Press Enter to continue..."
                ;;
            0)
                echo ""
                echo -e "${GREEN}Goodbye!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to check if required scripts exist
check_scripts() {
    echo -e "${CYAN}Checking required scripts...${NC}"
    echo ""
    
    missing=0
    for script in "$SETUP_SCRIPT" "$CONNECT_SCRIPT" "$CONTROL_SCRIPT"; do
        if [ -f "$script" ]; then
            echo -e "  ${GREEN}✓${NC} $script"
        else
            echo -e "  ${RED}✗${NC} $script (missing)"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -eq 3 ]; then
        echo ""
        echo -e "${RED}ERROR: All script files are missing!${NC}"
        echo "Please make sure setup.sh, connect.sh, and control.sh are in the same directory."
        exit 1
    elif [ $missing -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Warning: Some script files are missing${NC}"
        echo "You can still configure the existing scripts."
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo ""
}

# Function to quick configure
quick_configure() {
    echo ""
    echo -e "${CYAN}Quick Configuration${NC}"
    echo ""
    
    # Detect Kali IP
    if ! detect_kali_ip; then
        read -p "Enter Kali IP address: " kali_input
        if [[ $kali_input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            KALI_IP="$kali_input"
        fi
    fi
    
    # Get Phone IP
    get_phone_ip
    
    # Get Port
    get_port
    
    # Save config
    save_config
    
    # Update scripts
    echo ""
    read -p "Update all scripts now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_scripts
        update_all_scripts "$DEFAULT_KALI_IP" "$DEFAULT_PHONE_IP"
        echo ""
        echo -e "${GREEN}✅ Quick configuration complete!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Configuration saved but scripts not updated${NC}"
        echo "Run option 5 from main menu to update scripts."
    fi
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         WIRELESS ADB CONFIGURATION MANAGER           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check for required scripts
    check_scripts
    
    # Load existing config or use defaults
    if ! load_config; then
        echo -e "${YELLOW}No existing configuration found. Using defaults.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Available options:${NC}"
    echo "1. Quick configure (recommended for first time)"
    echo "2. Manual configuration menu"
    echo "3. Exit"
    echo ""
    
    read -p "Select option [1-3]: " main_choice
    
    case $main_choice in
        1)
            quick_configure
            show_menu
            ;;
        2)
            show_menu
            ;;
        3)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            main
            ;;
    esac
}

# Start main function
main

#!/bin/bash

# ============================================================
#  ████████╗ ██████╗ ██████╗     ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
#  ╚══██╔══╝██╔═══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗██║  ██║╚██╗ ██╔╝
#     ██║   ██║   ██║██████╔╝    ██████╔╝██████╔╝██║   ██║███████║ ╚████╔╝ 
#     ██║   ██║   ██║██╔══██╗    ██╔═══╝ ██╔══██╗██║   ██║██╔══██║  ╚██╔╝  
#     ██║   ╚██████╔╝██║  ██║    ██║     ██║  ██║╚██████╔╝██║  ██║   ██║   
#     ╚═╝    ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
# ============================================================
#  Professional Tor SOCKS5 Proxy Manager
#  Version: 4.1 | Debug & Fix Edition
#  Owner: AilyDev
# ============================================================

# ------------------- Color Definitions -------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ------------------- Configuration -------------------
TOR_SOCKS_PORT="9050"
TOR_CONTROL_PORT="9051"
TOR_PASSWORD="SecureTorPass2024#"
CONFIG_DIR="$HOME/.tor_pro_manager"
LOG_FILE="$CONFIG_DIR/tor_manager.log"
COUNTRY_FILE="$CONFIG_DIR/countries.conf"
SESSION_ID=$(date +%s | sha256sum | base64 | head -c 8)

# ------------------- Global Variables -------------------
declare -a COUNTRIES_LIST=()
ROTATE_PID=""

# ------------------- Initialization -------------------
init_directories() {
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
}

load_countries() {
    if [[ -f "$COUNTRY_FILE" ]] && [[ -s "$COUNTRY_FILE" ]]; then
        mapfile -t COUNTRIES_LIST < "$COUNTRY_FILE"
    else
        COUNTRIES_LIST=("US" "DE" "FR" "NL" "CA")
        printf "%s\n" "${COUNTRIES_LIST[@]}" > "$COUNTRY_FILE"
    fi
}

save_countries() {
    printf "%s\n" "${COUNTRIES_LIST[@]}" > "$COUNTRY_FILE"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ------------------- FIX: Complete Tor Reset -------------------
complete_tor_reset() {
    echo -e "\n${BLUE}▸ Performing complete Tor reset...${NC}"
    
    # Stop Tor completely
    sudo systemctl stop tor
    sudo killall -9 tor 2>/dev/null
    
    # Remove broken files
    sudo rm -rf /var/lib/tor/* 2>/dev/null
    sudo rm -rf /var/log/tor/* 2>/dev/null
    sudo rm -f /etc/tor/torrc 2>/dev/null
    
    # Recreate directories with correct permissions
    sudo mkdir -p /var/lib/tor
    sudo mkdir -p /var/log/tor
    sudo chown -R debian-tor:debian-tor /var/lib/tor
    sudo chown -R debian-tor:debian-tor /var/log/tor
    sudo chmod 700 /var/lib/tor
    sudo chmod 755 /var/log/tor
    
    echo -e "${GREEN}✓ Tor cleaned up${NC}"
}

# ------------------- FIX: Create Working Config -------------------
create_working_config() {
    echo -e "\n${BLUE}▸ Creating working Tor configuration...${NC}"
    
    # Generate hashed password
    local hashed_pass=$(tor --hash-password "$TOR_PASSWORD" 2>/dev/null | grep -v "Tor" | head -n1)
    if [[ -z "$hashed_pass" ]]; then
        echo -e "${RED}✗ Failed to generate password hash${NC}"
        return 1
    fi
    
    # Build countries string
    local countries_str=""
    for country in "${COUNTRIES_LIST[@]}"; do
        countries_str+="$country,"
    done
    countries_str=${countries_str%,}
    
    # Create fresh torrc
    sudo bash -c "cat > /etc/tor/torrc" <<EOL
## ============================================
## TOR SOCKS5 PROXY CONFIGURATION
## ============================================

## Network
SOCKSPort 127.0.0.1:$TOR_SOCKS_PORT
ControlPort 127.0.0.1:$TOR_CONTROL_PORT
HashedControlPassword $hashed_pass
CookieAuthentication 0

## Exit Policy
ExitPolicy accept *:*
ExitPolicy reject *:*

## Exit Nodes
ExitNodes {$countries_str}
StrictNodes 1

## Performance
NumEntryGuards 4
CircuitBuildTimeout 60
KeepalivePeriod 60
NewCircuitPeriod 60
MaxCircuitDirtiness 60

## Data Directory
DataDirectory /var/lib/tor

## Logging
Log notice file /var/log/tor/notices.log
Log warn file /var/log/tor/warnings.log

## Avoid using bridges
UseBridges 0

## Allow SOCKS5 authentication
Socks5Proxy 0
EOL

    # Set proper permissions
    sudo chown debian-tor:debian-tor /etc/tor/torrc
    sudo chmod 644 /etc/tor/torrc
    
    echo -e "${GREEN}✓ Configuration created${NC}"
    return 0
}

# ------------------- FIX: Start Tor Properly -------------------
start_tor_properly() {
    echo -e "\n${BLUE}▸ Starting Tor properly...${NC}"
    
    # Start Tor
    sudo systemctl start tor
    
    # Wait for initialization
    echo -e "${YELLOW}Waiting for Tor to initialize (15 seconds)...${NC}"
    sleep 15
    
    # Check if Tor is running
    if ! systemctl is-active --quiet tor; then
        echo -e "${RED}✗ Tor failed to start${NC}"
        echo -e "${YELLOW}Checking logs...${NC}"
        sudo journalctl -u tor -n 20 --no-pager
        return 1
    fi
    
    echo -e "${GREEN}✓ Tor service is running${NC}"
    return 0
}

# ------------------- Check Tor Ports -------------------
check_tor_ports() {
    echo -e "\n${BLUE}▸ Checking Tor ports...${NC}"
    
    # Check with netstat
    if sudo netstat -tlnp | grep -q ":$TOR_SOCKS_PORT"; then
        echo -e "${GREEN}✓ Port $TOR_SOCKS_PORT is listening${NC}"
        return 0
    else
        echo -e "${RED}✗ Port $TOR_SOCKS_PORT is NOT listening${NC}"
        return 1
    fi
}

test_proxy() {
    echo -e "\n${BLUE}▸ Testing SOCKS5 Proxy...${NC}"
    
    local test_ip=$(curl --socks5 127.0.0.1:$TOR_SOCKS_PORT -s --max-time 15 https://api.ipify.org 2>/dev/null)
    
    if [[ ! -z "$test_ip" ]]; then
        echo -e "${GREEN}✓ Proxy is working!${NC}"
        echo -e "  Your IP: ${WHITE}$test_ip${NC}"
        return 0
    else
        echo -e "${RED}✗ Proxy test failed${NC}"
        return 1
    fi
}

# ------------------- FIX: Install & Fix Tor -------------------
install_tor() {
    echo -e "\n${BLUE}▸ Installing Tor and dependencies...${NC}"
    log_message "INFO" "Starting Tor installation"
    
    # Install packages
    sudo apt update -y 2>&1 | tee -a "$LOG_FILE"
    sudo apt install -y tor tor-geoipdb curl netcat-openbsd net-tools 2>&1 | tee -a "$LOG_FILE"
    
    # Complete reset
    complete_tor_reset
    
    # Create config
    if ! create_working_config; then
        echo -e "${RED}✗ Config creation failed${NC}"
        read -p "Press Enter..."
        return
    fi
    
    # Start Tor
    if ! start_tor_properly; then
        echo -e "${RED}✗ Tor start failed${NC}"
        read -p "Press Enter..."
        return
    fi
    
    # Check ports
    if check_tor_ports; then
        echo -e "${GREEN}✓ Ports are listening${NC}"
    else
        echo -e "${YELLOW}⚠ Ports not listening. Trying alternative config...${NC}"
        fix_tor_alternative
    fi
    
    # Test proxy
    if test_proxy; then
        echo -e "${GREEN}✓ Tor installed and working perfectly!${NC}"
        log_message "SUCCESS" "Tor installed and working"
    else
        echo -e "${RED}✗ Still having issues. Please check:${NC}"
        echo -e "  ${YELLOW}1. Check firewall: sudo ufw allow $TOR_SOCKS_PORT${NC}"
        echo -e "  ${YELLOW}2. Check Tor logs: sudo journalctl -u tor -n 50${NC}"
        echo -e "  ${YELLOW}3. Try Option 9 to restart with fixes${NC}"
    fi
    
    echo -e "\n${GREEN}✓ Proxy: socks5://127.0.0.1:${TOR_SOCKS_PORT}${NC}"
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# ------------------- FIX: Alternative Tor Config -------------------
fix_tor_alternative() {
    echo -e "\n${YELLOW}▸ Trying alternative configuration...${NC}"
    
    sudo systemctl stop tor
    
    # Simple minimal config
    sudo bash -c "cat > /etc/tor/torrc" <<EOL
SOCKSPort 0.0.0.0:$TOR_SOCKS_PORT
ControlPort 0.0.0.0:$TOR_CONTROL_PORT
CookieAuthentication 0
DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
EOL

    sudo systemctl start tor
    sleep 10
    
    if check_tor_ports; then
        echo -e "${GREEN}✓ Alternative config working!${NC}"
    else
        echo -e "${RED}✗ Alternative config failed${NC}"
    fi
}

# ------------------- View Status with Debug -------------------
view_status() {
    echo -e "\n${BLUE}▸ Tor Service Status${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if systemctl is-active --quiet tor; then
        echo -e "${GREEN}● Service: RUNNING${NC}"
        echo -e "  PID: $(systemctl show -p MainPID tor | cut -d= -f2)"
    else
        echo -e "${RED}● Service: STOPPED${NC}"
    fi
    
    echo ""
    check_tor_ports
    
    echo ""
    test_proxy
    
    echo -e "\n${BLUE}▸ Debug Information${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show listening ports
    echo -e "${YELLOW}Listening ports:${NC}"
    sudo netstat -tlnp | grep -E ":(9050|9051)" || echo "  No Tor ports listening"
    
    # Show Tor process
    echo -e "\n${YELLOW}Tor processes:${NC}"
    ps aux | grep tor | grep -v grep || echo "  No Tor processes"
    
    # Show last 5 log lines
    echo -e "\n${YELLOW}Last 5 Tor log lines:${NC}"
    sudo journalctl -u tor -n 5 --no-pager 2>/dev/null || echo "  No logs available"
    
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# ------------------- Manual Rotation (Fixed) -------------------
manual_rotate() {
    if [[ ${#COUNTRIES_LIST[@]} -eq 0 ]]; then
        echo -e "\n${RED}✗ No countries configured. Set them first (Option 3).${NC}"
        read -p "Press Enter..."
        return
    fi
    
    echo -e "\n${BLUE}▸ Manual Location Change${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Select country to switch to:${NC}\n"
    
    local counter=1
    for country in "${COUNTRIES_LIST[@]}"; do
        echo -e "  ${GREEN}[${counter}]${NC} ${WHITE}${country}${NC}"
        ((counter++))
    done
    echo -e "  ${GREEN}[${counter}]${NC} ${YELLOW}Random${NC}"
    echo ""
    echo -ne "${BOLD}${YELLOW}Choose option [1-${counter}]: ${NC}"
    read selection
    
    local selected_country=""
    
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#COUNTRIES_LIST[@]} ]]; then
            selected_country="${COUNTRIES_LIST[$((selection-1))]}"
        elif [[ "$selection" -eq ${#COUNTRIES_LIST[@]}+1 ]]; then
            local random_index=$((RANDOM % ${#COUNTRIES_LIST[@]}))
            selected_country="${COUNTRIES_LIST[$random_index]}"
            echo -e "\n${BLUE}Randomly selected: ${GREEN}${selected_country}${NC}"
        else
            echo -e "\n${RED}✗ Invalid selection!${NC}"
            read -p "Press Enter..."
            return
        fi
    else
        selected_country=$(echo "$selection" | xargs | tr '[:lower:]' '[:upper:]')
        if [[ ! " ${COUNTRIES_LIST[@]} " =~ " ${selected_country} " ]]; then
            echo -e "\n${RED}✗ Country '${selected_country}' not in your list!${NC}"
            read -p "Press Enter..."
            return
        fi
    fi
    
    echo -e "\n${BLUE}▸ Changing location to: ${GREEN}${selected_country}${NC}"
    
    # Try to change circuit
    {
        echo "AUTHENTICATE \"$TOR_PASSWORD\""
        echo "SIGNAL NEWNYM"
        echo "QUIT"
    } | nc 127.0.0.1 "$TOR_CONTROL_PORT" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Location change command sent!${NC}"
        log_message "INFO" "Manual rotate to $selected_country"
        
        sleep 5
        echo -e "\n${BLUE}▸ New IP:${NC}"
        local new_ip=$(curl --socks5 127.0.0.1:$TOR_SOCKS_PORT -s --max-time 10 https://api.ipify.org 2>/dev/null)
        if [[ ! -z "$new_ip" ]]; then
            echo -e "${GREEN}✓ $new_ip${NC}"
        else
            echo -e "${YELLOW}⚠ Could not get new IP. Check proxy status.${NC}"
        fi
    else
        echo -e "${RED}✗ Rotation failed!${NC}"
        echo -e "${YELLOW}Make sure Tor is running (Option 2 to check)${NC}"
        log_message "ERROR" "Manual rotation failed"
    fi
    
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# ------------------- Start Auto Rotation -------------------
start_auto_rotate() {
    if [[ ${#COUNTRIES_LIST[@]} -eq 0 ]]; then
        echo -e "${RED}✗ No countries configured. Set them first (Option 3).${NC}"
        read -p "Press Enter..."
        return
    fi
    
    if [[ ! -z "$ROTATE_PID" ]] && kill -0 "$ROTATE_PID" 2>/dev/null; then
        echo -e "${YELLOW}⚠ Auto-rotation already running (PID: $ROTATE_PID)${NC}"
        read -p "Press Enter..."
        return
    fi
    
    echo -e "\n${YELLOW}Set rotation interval in seconds (minimum 10):${NC}"
    read -p "→ " ROTATE_INTERVAL
    
    if ! [[ "$ROTATE_INTERVAL" =~ ^[0-9]+$ ]] || [[ "$ROTATE_INTERVAL" -lt 10 ]]; then
        echo -e "${RED}✗ Invalid. Minimum is 10 seconds.${NC}"
        read -p "Press Enter..."
        return
    fi
    
    echo -e "${GREEN}✓ Starting auto-rotation every ${ROTATE_INTERVAL}s...${NC}"
    log_message "INFO" "Auto-rotation started"
    
    (
        while true; do
            sleep "$ROTATE_INTERVAL"
            local random_index=$((RANDOM % ${#COUNTRIES_LIST[@]}))
            local selected="${COUNTRIES_LIST[$random_index]}"
            
            echo -e "\n${BLUE}⟳ Rotating to: ${GREEN}${selected}${NC}"
            
            {
                echo "AUTHENTICATE \"$TOR_PASSWORD\""
                echo "SIGNAL NEWNYM"
                echo "QUIT"
            } | nc 127.0.0.1 "$TOR_CONTROL_PORT" 2>/dev/null
            
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✓ Rotation successful → ${selected}${NC}"
                log_message "INFO" "Auto-rotated to $selected"
            else
                echo -e "${RED}✗ Rotation failed${NC}"
                log_message "ERROR" "Auto-rotation failed"
            fi
        done
    ) &
    
    ROTATE_PID=$!
    echo -e "${GREEN}✓ Started with PID: $ROTATE_PID${NC}"
    read -p "Press Enter..."
}

# ------------------- Stop Auto Rotation -------------------
stop_auto_rotate() {
    if [[ -z "$ROTATE_PID" ]] || ! kill -0 "$ROTATE_PID" 2>/dev/null; then
        echo -e "${RED}✗ No rotation process found.${NC}"
        ROTATE_PID=""
        read -p "Press Enter..."
        return
    fi
    
    kill "$ROTATE_PID" 2>/dev/null
    sleep 1
    kill -9 "$ROTATE_PID" 2>/dev/null
    
    echo -e "${GREEN}✓ Auto-rotation stopped${NC}"
    log_message "INFO" "Auto-rotation stopped"
    ROTATE_PID=""
    read -p "Press Enter..."
}

# ------------------- Show Proxy Details -------------------
show_proxy_details() {
    echo -e "\n${BLUE}▸ Proxy Connection Details${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}Type:${NC} SOCKS5"
    echo -e "  ${GREEN}Host:${NC} 127.0.0.1"
    echo -e "  ${GREEN}Port:${NC} $TOR_SOCKS_PORT"
    echo -e "  ${GREEN}Authentication:${NC} None"
    echo ""
    echo -e "${YELLOW}Test commands:${NC}"
    echo -e "  ${WHITE}curl --socks5 127.0.0.1:$TOR_SOCKS_PORT https://api.ipify.org${NC}"
    echo ""
    echo -e "${YELLOW}For Firefox:${NC}"
    echo -e "  ${WHITE}Settings → Network Settings → Manual Proxy${NC}"
    echo -e "  ${WHITE}SOCKS Host: 127.0.0.1  Port: $TOR_SOCKS_PORT${NC}"
    echo -e "  ${WHITE}✓ SOCKS v5  ✓ Proxy DNS${NC}"
    
    read -p "$(echo -e ${YELLOW}Press Enter to continue...${NC})"
}

# ------------------- Restart Tor (Fixed) -------------------
restart_tor() {
    echo -e "\n${BLUE}▸ Restarting Tor Service...${NC}"
    
    complete_tor_reset
    
    if create_working_config; then
        if start_tor_properly; then
            echo -e "${GREEN}✓ Tor restarted successfully${NC}"
            log_message "INFO" "Tor restarted"
            check_tor_ports
            test_proxy
        else
            echo -e "${RED}✗ Failed to start Tor${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to create config${NC}"
    fi
    
    read -p "Press Enter..."
}

# ------------------- Manage Countries -------------------
manage_countries() {
    echo -e "\n${BLUE}▸ Manage Exit Countries${NC}"
    echo -e "${WHITE}Current: ${GREEN}${COUNTRIES_LIST[*]}${NC}"
    echo ""
    echo -e "  ${YELLOW}[1]${NC} Set new countries (comma separated)"
    echo -e "  ${YELLOW}[2]${NC} Add country"
    echo -e "  ${YELLOW}[3]${NC} Remove country"
    echo -e "  ${YELLOW}[4]${NC} Clear all"
    echo ""
    read -p "Select: " sub_choice
    
    case $sub_choice in
        1)
            echo -e "\n${YELLOW}Enter countries (e.g., DE,FR,US):${NC}"
            read -p "→ " input
            IFS=',' read -r -a COUNTRIES_LIST <<< "$input"
            for i in "${!COUNTRIES_LIST[@]}"; do
                COUNTRIES_LIST[i]=$(echo "${COUNTRIES_LIST[i]}" | xargs | tr '[:lower:]' '[:upper:]')
            done
            save_countries
            echo -e "${GREEN}✓ Updated: ${COUNTRIES_LIST[*]}${NC}"
            echo -e "${YELLOW}⚠ Restart Tor (Option 9) to apply${NC}"
            ;;
        2)
            read -p "Enter country to add: " new
            new=$(echo "$new" | xargs | tr '[:lower:]' '[:upper:]')
            COUNTRIES_LIST+=("$new")
            save_countries
            echo -e "${GREEN}✓ Added: $new${NC}"
            ;;
        3)
            read -p "Enter country to remove: " rm
            rm=$(echo "$rm" | xargs | tr '[:lower:]' '[:upper:]')
            COUNTRIES_LIST=("${COUNTRIES_LIST[@]/$rm}")
            save_countries
            echo -e "${GREEN}✓ Removed: $rm${NC}"
            ;;
        4)
            COUNTRIES_LIST=()
            save_countries
            echo -e "${GREEN}✓ Cleared${NC}"
            ;;
        *)
            echo -e "${RED}Invalid${NC}"
            ;;
    esac
    read -p "Press Enter..."
}

# ------------------- View Logs -------------------
view_logs() {
    echo -e "\n${BLUE}▸ Recent Logs${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found${NC}"
    fi
    read -p "Press Enter..."
}

# ------------------- UI -------------------
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}████████╗ ██████╗ ██████╗     ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}╚══██╔══╝██╔═══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗██║  ██║╚██╗ ██╔╝${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}   ██║   ██║   ██║██████╔╝    ██████╔╝██████╔╝██║   ██║███████║ ╚████╔╝ ${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}   ██║   ██║   ██║██╔══██╗    ██╔═══╝ ██╔══██╗██║   ██║██╔══██║  ╚██╔╝  ${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}   ██║   ╚██████╔╝██║  ██║    ██║     ██║  ██║╚██████╔╝██║  ██║   ██║   ${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}   ╚═╝    ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${GREEN}Tor Proxy Manager v4.1 - Debug Edition${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}Session: ${YELLOW}$SESSION_ID${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}Owner:  ${PURPLE}AilyDev${NC}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    print_banner
    
    local tor_status
    if systemctl is-active --quiet tor 2>/dev/null; then
        tor_status="${GREEN}● RUNNING${NC}"
    else
        tor_status="${RED}● STOPPED${NC}"
    fi
    
    local proxy_status
    if test_proxy > /dev/null 2>&1; then
        proxy_status="${GREEN}WORKING${NC}"
    else
        proxy_status="${RED}NOT WORKING${NC}"
    fi
    
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│  ${BOLD}SYSTEM STATUS${NC}                                    │${NC}"
    echo -e "${WHITE}│  Tor Service: ${tor_status}                               │${NC}"
    echo -e "${WHITE}│  Proxy Status: ${proxy_status}                         │${NC}"
    echo -e "${WHITE}│  SOCKS5 Proxy: ${CYAN}socks5://127.0.0.1:${TOR_SOCKS_PORT}${NC}${WHITE}        │${NC}"
    echo -e "${WHITE}│  Countries: ${GREEN}${COUNTRIES_LIST[*]}${NC}${WHITE}                  │${NC}"
    echo -e "${WHITE}│  Owner: ${PURPLE}AilyDev${NC}${WHITE}                                       │${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  MAIN MENU${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC}  Install & Fix Tor              ${BLUE}[ Clean Install ]${NC}"
    echo -e "  ${GREEN}2)${NC}  View Status & Debug           ${BLUE}[ Check Issues ]${NC}"
    echo -e "  ${GREEN}3)${NC}  Manage Exit Countries         ${BLUE}[ Set Locations ]${NC}"
    echo -e "  ${GREEN}4)${NC}  Start Auto-Rotation           ${BLUE}[ Every X Sec ]${NC}"
    echo -e "  ${GREEN}5)${NC}  Manual Location Change        ${BLUE}[ Choose Country ]${NC}"
    echo -e "  ${GREEN}6)${NC}  Show Proxy Details            ${BLUE}[ Connection Info ]${NC}"
    echo -e "  ${GREEN}7)${NC}  Stop Auto-Rotation            ${BLUE}[ Kill Process ]${NC}"
    echo -e "  ${GREEN}8)${NC}  View Logs                     ${BLUE}[ Last 20 Lines ]${NC}"
    echo -e "  ${GREEN}9)${NC}  Restart Tor (With Fix)        ${BLUE}[ Re-apply Config ]${NC}"
    echo -e "  ${GREEN}0)${NC}  Exit                          ${BLUE}[ Goodbye ]${NC}"
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne "${BOLD}${YELLOW}└─► Select option: ${NC}"
}

# ------------------- Main -------------------
main() {
    init_directories
    load_countries
    
    trap 'echo -e "\n${RED}Exiting...${NC}"; stop_auto_rotate; exit 0' INT TERM
    
    while true; do
        print_menu
        read choice
        
        case $choice in
            1) install_tor ;;
            2) view_status ;;
            3) manage_countries ;;
            4) start_auto_rotate ;;
            5) manual_rotate ;;
            6) show_proxy_details ;;
            7) stop_auto_rotate ;;
            8) view_logs ;;
            9) restart_tor ;;
            0) 
                stop_auto_rotate
                echo -e "\n${GREEN}Thank you for using Tor Proxy Manager!${NC}"
                echo -e "${CYAN}Stay anonymous! 🛡️${NC}"
                echo -e "${PURPLE}Owner: AilyDev${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}✗ Invalid: $choice${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"

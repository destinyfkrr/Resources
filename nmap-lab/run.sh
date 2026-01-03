#!/bin/bash
# destinyoo.com Nmap Lab Management Tool

TARGET_SUBNET="172.20.100.0/24"
COMPOSE_CMD=""

# --- Helper Functions ---

get_compose_cmd() {
    if [ -n "$COMPOSE_CMD" ]; then return; fi

    # Check for Docker Compose (prioritize docker-compose v1/standalone as requested)
    if command -v docker-compose &> /dev/null && docker-compose version &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        echo "Error: docker-compose is not installed or detected."
        return 1
    fi
}

check_prereqs() {
    echo ""
    echo "--- Checking Prerequisites ---"
    
    # 1. Check Docker
    if command -v docker &> /dev/null; then
        echo "[OK] Docker is installed."
    else
        echo "[FAIL] Docker is NOT installed."
    fi

    # 2. Check Compose
    if get_compose_cmd; then
        echo "[OK] Docker Compose found: $COMPOSE_CMD"
    else
        echo "[FAIL] Docker Compose NOT found."
    fi

    # 3. Check Nmap
    if command -v nmap &> /dev/null; then
        echo "[OK] Nmap is installed."
    else
        echo "[FAIL] Nmap is NOT installed."
    fi
    echo "------------------------------"
    read -p "Press Enter to continue..."
}

start_lab() {
    echo ""
    echo "--- Starting Nmap Lab ---"
    get_compose_cmd
    
    CMD="$COMPOSE_CMD up -d --build"

    # Check permissions
    if ! docker info &> /dev/null; then
        echo "User does not have Docker permissions. Using sudo..."
        CMD="sudo $CMD"
    fi

    echo "Running: $CMD"
    eval $CMD

    if [ $? -eq 0 ]; then
        echo ""
        echo "Lab is UP! Subnet: $TARGET_SUBNET"
    else
        echo ""
        echo "Error: Failed to start lab."
    fi
    read -p "Press Enter to continue..."
}

stop_lab() {
    echo ""
    echo "--- Stopping Nmap Lab ---"
    get_compose_cmd
    
    CMD="$COMPOSE_CMD down"

    # Check permissions
    if ! docker info &> /dev/null; then
        CMD="sudo $CMD"
    fi

    echo "Running: $CMD"
    eval $CMD
    echo "Lab Stopped."
    read -p "Press Enter to continue..."
}

verify_lab() {
    echo ""
    echo "--- Verifying Nmap Lab ---"
    
    if ! command -v nmap &> /dev/null; then
        echo "Error: nmap not found. Please install nmap."
        return
    fi
    
    echo "Note: Using sudo for Nmap scans..."

    # Discovery
    echo "1. Scanning for hosts..."
    hosts_up=$(sudo nmap -sn $TARGET_SUBNET | grep "Host is up" | wc -l)
    echo "   Hosts found: $hosts_up (Expected ~7)"

    # Service Check Function
    check_port() {
        host=$1; port=$2; proto=$3; name=$4
        echo -n "   Checking $name ($host:$port/$proto)... "
        if [ "$proto" == "udp" ]; then
            out=$(sudo nmap -sU -p $port $host -oG - 2>/dev/null | grep "${port}/open")
        else
            out=$(sudo nmap -p $port $host -oG - 2>/dev/null | grep "${port}/open")
        fi
        
        if [ -n "$out" ]; then echo "OK"; else echo "FAILED"; fi
    }

    echo "2. Checking Services..."
    check_port 172.20.100.10 80 tcp "Ubuntu HTTP"
    check_port 172.20.100.10 22 tcp "Ubuntu SSH"
    check_port 172.20.100.25 21 tcp "Alpine FTP"
    check_port 172.20.100.25 22 tcp "Alpine SSH"
    check_port 172.20.100.33 22 tcp "Rocky SSH"
    check_port 172.20.100.42 80 tcp "Debian HTTP"
    check_port 172.20.100.42 23 tcp "Debian Telnet"
    check_port 172.20.100.68 80 tcp "Misc HTTP"
    check_port 172.20.100.55 53 tcp "UDP Host DNS"
    check_port 172.20.100.55 8080 udp "UDP Host 8080"
    
    echo "--------------------------"
    read -p "Press Enter to continue..."
}

# --- Main Menu ---

while true; do
    clear
    echo "========================================="
    echo " destinyoo.com Nmap Lab Manager"
    echo "========================================="
    echo "1. Check Prerequisites"
    echo "2. Start/Install Lab"
    echo "3. Verify Lab (Run Checks)"
    echo "4. Stop/Remove Lab"
    echo "5. Exit"
    echo "========================================="
    read -p "Select an option [1-5]: " choice

    case $choice in
        1) check_prereqs ;;
        2) start_lab ;;
        3) verify_lab ;;
        4) stop_lab ;;
        5) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option."; read -p "Press Enter..." ;;
    esac
done

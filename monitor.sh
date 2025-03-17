#!/bin/bash

VERBOSE=false
if [[ "$@" =~ "-v" ]]; then
  VERBOSE=true
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

### Check active connections ###
list_active_connections() {
  echo -e "${YELLOW}\n===== Active Connections =====${NC}"
  netstat -tupan | grep ESTABLISHED | awk '{print $5, $6, $7}' | column -t
}

### Check active network services ###
list_active_services() {
  echo -e "${CYAN}\n===== Active Network Services =====${NC}"
  systemctl list-units --type=service --state=running | grep -E 'ssh|xrdp|nginx|ftp|rdp|mysql|postgresql|apache|vsftpd'
}

### Check open ports and associated services ###
list_open_ports() {
  echo -e "${CYAN}\n===== Open Ports and Associated Services =====${NC}"
  ss -tulpen | grep 'LISTEN' | awk '{print $1, $5, $7}' | column -t
}

### Check firewall rules ###
list_firewall_rules() {
  echo -e "${RED}\n===== Firewall Rules =====${NC}"
  if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    sudo ufw status verbose
  else
    sudo iptables -L -v -n
  fi
}

### Last 15 external connections ###
list_last_connections() {
  echo -e "${YELLOW}\n===== Last 15 External Connections =====${NC}"
  last -i | head -n 15
}

### Identify Potentially Vulnerable Entry Points ###
identify_vulnerabilities() {
  echo -e "${RED}\n===== Potentially Vulnerable Entry Points =====${NC}"
  ss -tulpen | grep 'LISTEN' | awk '{print $5, $7}' | while read -r line; do
    ADDRESS=$(echo $line | awk '{print $1}')
    SERVICE=$(echo $line | awk '{print $2}')
    PORT=$(echo $ADDRESS | awk -F: '{print $NF}')
    
    if systemctl is-active --quiet "$SERVICE" && [[ ! -z "$PORT" ]]; then
      echo -e "${RED}WARNING: ${NC}Service ${SERVICE:-Unknown} is active and listening on port $PORT, which may be exposed."
    fi
  done
}

### Display help menu ###
show_help() {
  echo -e "${CYAN}\n===== Monitor Help =====${NC}"
  echo "Usage: monitor [command]"
  echo "Available commands:"
  echo "  now       - Show current active connections"
  echo "  services  - Show active network services"
  echo "  ports     - Show open ports and associated services"
  echo "  firewall  - Show firewall rules"
  echo "  last      - Show last 15 external connections"
  echo "  vuln      - Identify potentially vulnerable entry points"
  echo "  all       - Show everything"
  echo "  help      - Display this help menu"
}

### Command execution based on input ###
if [[ "$1" == "now" ]]; then
  list_active_connections
elif [[ "$1" == "services" ]]; then
  list_active_services
elif [[ "$1" == "ports" ]]; then
  list_open_ports
elif [[ "$1" == "firewall" ]]; then
  list_firewall_rules
elif [[ "$1" == "last" ]]; then
  list_last_connections
elif [[ "$1" == "vuln" ]]; then
  identify_vulnerabilities
elif [[ "$1" == "all" ]]; then
  list_active_connections
  list_active_services
  list_open_ports
  list_firewall_rules
  list_last_connections
  identify_vulnerabilities
else
  show_help
fi

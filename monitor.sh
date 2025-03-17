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

### Execute functions ###
echo -e "${GREEN}\n===== System Analysis in Progress... =====${NC}"
list_active_connections
list_active_services
list_open_ports
list_firewall_rules
list_last_connections

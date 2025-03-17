#!/bin/bash

VERBOSE=false
if [[ "$@" =~ "-v" ]]; then
  VERBOSE=true
fi

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

### Vérification des connexions actives ###
list_active_connections() {
  echo -e "${YELLOW}\n===== Connexions en cours =====${NC}"
  netstat -tupan | grep ESTABLISHED | awk '{print $5, $6, $7}' | column -t
}

### Vérification des services actifs ###
list_active_services() {
  echo -e "${CYAN}\n===== Services réseau actifs =====${NC}"
  systemctl list-units --type=service --state=running | grep -E 'ssh|xrdp|nginx|ftp|rdp|mysql|postgresql|apache|vsftpd'
}

### Vérification des ports ouverts ###
list_open_ports() {
  echo -e "${CYAN}\n===== Ports en écoute et services associés =====${NC}"
  ss -tulpen | grep 'LISTEN' | awk '{print $1, $5, $7}' | column -t
}

### Vérification des règles de pare-feu ###
list_firewall_rules() {
  echo -e "${RED}\n===== Règles du pare-feu =====${NC}"
  if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    sudo ufw status verbose
  else
    sudo iptables -L -v -n
  fi
}

### Dernières connexions extérieures ###
list_last_connections() {
  echo -e "${YELLOW}\n===== 15 dernières connexions externes =====${NC}"
  last -i | head -n 15
}

### Exécution des fonctions ###
echo -e "${GREEN}\n===== Analyse du système en cours... =====${NC}"
list_active_connections
list_active_services
list_open_ports
list_firewall_rules
list_last_connections

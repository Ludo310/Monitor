#!/bin/bash

VERBOSE=false

if [[ "$@" =~ "-v" ]]; then
  VERBOSE=true
fi

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICE_OUTPUT=""
SECURE_OUTPUT=""

check_service() {
  SERVICE=$1
  DEFAULT_PORT=$2

  [ "$VERBOSE" = true ] && echo -e "Vérification du service : $SERVICE..."

  if systemctl list-unit-files | grep -q "^$SERVICE.service"; then
    [ "$VERBOSE" = true ] && echo -e "$SERVICE installé, vérification de l'état."

    if systemctl is-active --quiet "$SERVICE"; then
      STATUS="${GREEN}ON${CYAN}"
    else
      STATUS="${RED}OFF${CYAN}"
    fi

    [ "$VERBOSE" = true ] && echo -e "Détection du port pour $SERVICE."
    PORT=$(ss -tulpn | grep "$SERVICE" | awk '{print $5}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -u | head -n 1)
    if [ -z "$PORT" ]; then
      PORT="$DEFAULT_PORT"
      [ "$VERBOSE" = true ] && echo -e "Aucun port détecté, utilisation du port par défaut : $DEFAULT_PORT"
    fi

    SERVICE_OUTPUT+="$(printf "${CYAN}| %-10s | Port : %-5s | Statut : %-3b |\n" "${SERVICE^^}" "$PORT" "$STATUS")\n"
  else
    [ "$VERBOSE" = true ] && echo -e "$SERVICE non installé, ignoré."
  fi
}

check_secure_service() {
  SERVICE=$1

  [ "$VERBOSE" = true ] && echo -e "Vérification du service de sécurité : $SERVICE..."

  if systemctl list-unit-files | grep -q "^$SERVICE.service"; then
    [ "$VERBOSE" = true ] && echo -e "$SERVICE installé, vérification de l'état."

    if systemctl is-active --quiet "$SERVICE"; then
      STATUS="${GREEN}ON${CYAN}"
    else
      STATUS="${RED}OFF${CYAN}"
    fi

    SECURE_OUTPUT+="$(printf "${CYAN}| %-10s | Statut : %-3b |\n" "${SERVICE^^}" "$STATUS")\n"
  else
    [ "$VERBOSE" = true ] && echo -e "$SERVICE non installé, ignoré."
  fi
}

services_status() {
  SERVICE_OUTPUT=""
  echo -e "${CYAN}Check services ... Wait${NC}"
  check_service ssh 22
  check_service xrdp 3389
  check_service nginx 80
  check_service mysql 3306
  check_service postgresql 5432
  check_service docker 2375
  check_service ftp 21
  check_service vsftpd 21

  echo -e "${CYAN}+-----------+---------------+---------------+"
  echo -e "${CYAN}|  SERVICE  |     PORT      |    STATUT     |"
  echo -e "${CYAN}+-----------+---------------+---------------+"
  echo -e "$SERVICE_OUTPUT"
  echo -e "${CYAN}+-----------+---------------+---------------+${NC}"
}

secure_status() {
  SECURE_OUTPUT=""
  echo -e "${CYAN}Check secure services ... Wait${NC}"
  check_secure_service fail2ban
  check_secure_service ufw

  echo -e "${CYAN}+-----------+---------------+"
  echo -e "${CYAN}|  SERVICE  |    STATUT     |"
  echo -e "${CYAN}+-----------+---------------+"
  echo -e "$SECURE_OUTPUT"
  echo -e "${CYAN}+-----------+---------------+${NC}"
}

port_status() {
  echo -e "${CYAN}Check open ports ... Wait${NC}"

  if systemctl is-active --quiet ufw; then
    echo -e "${CYAN}UFW actif, utilisation des règles firewall${NC}"
    echo -e "${CYAN}+---------------------+"
    echo -e "${CYAN}| PORTS OUVERTS (UFW) |"
    echo -e "${CYAN}+---------------------+"
    sudo ufw status | grep 'ALLOW' | awk '{print $1}' | grep -oP '^\d+' | sort -nu | while read PORT; do
      echo -e "${CYAN}| Port : $PORT"
    done
  else
    echo -e "${CYAN}UFW inactif, utilisation de ss -tulpn${NC}"
    echo -e "${CYAN}+-------------------+"
    echo -e "${CYAN}|   PORTS OUVERTS   |"
    echo -e "${CYAN}+-------------------+"
    ss -tulpn | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -nu | while read PORT; do
      echo -e "${CYAN}| Port : $PORT"
    done
  fi
  echo -e "${CYAN}+-------------------+${NC}"
}

show_help() {
  echo -e "${CYAN}Usage: monitor status [services|secure|port] [-v]\n"
  echo "Options disponibles :"
  echo "  status services : affiche l'état et les ports des services courants."
  echo "  status secure   : affiche l'état des services de sécurité (fail2ban, ufw)."
  echo "  status port     : affiche tous les ports ouverts."
  echo "  status          : affiche services, sécurité et ports ouverts."
  echo "  -v              : active le mode verbose pour afficher les détails."
  echo -e "  -h              : affiche cette aide.${NC}"
}

if [[ "$@" =~ "-h" ]]; then
  show_help
elif [[ "$@" =~ "status services" ]]; then
  services_status
elif [[ "$@" =~ "status secure" ]]; then
  secure_status
elif [[ "$@" =~ "status port" ]]; then
  port_status
elif [[ "$@" =~ "status" ]]; then
  services_status
  secure_status
  port_status
else
  show_help
fi

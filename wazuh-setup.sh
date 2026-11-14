#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please execute with root (sudo bash $0)."
  exit 1
fi

WAZUH_VERSION="4.8"
AGENT_PKG="wazuh-agent_4.8.2-1_amd64.deb"

if [ "$1" = "server" ]; then
  echo "[+] Installing Wazuh Server $WAZUH_VERSION (All-In-One)..."
  apt update && apt upgrade -y
  apt install -y curl wget
  
  wget -O /tmp/wazuh-install.sh "https://packages.wazuh.com/${WAZUH_VERSION}/wazuh-install.sh"
  bash /tmp/wazuh-install.sh -a -i
  
  echo -e "\n[+] Installation Complete!"

elif [ "$1" = "client" ]; then
  IP_WAZUH="$2"
  NOME_AGENTE="$3"

  if [ -z "$IP_WAZUH" ] || [ -z "$NOME_AGENTE" ]; then
    echo "[-] Error: Missing Parameters."
    echo "    Correct Use: sudo bash $0 client <IP_WAZUH> <NAME_AGENT>"
    echo "    Example:     sudo bash $0 client 10.10.30.1 PC01"
    exit 1
  fi

  echo "[+] Configuring Wazuh Agent '$NOME_AGENTE' (v4.8.2) pointing to $IP_WAZUH..."
  apt-get update
  apt-get install -y wget

  wget -O "/tmp/${AGENT_PKG}" "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${AGENT_PKG}"
  WAZUH_MANAGER="$IP_WAZUH" WAZUH_AGENT_NAME="$NOME_AGENTE" dpkg -i "/tmp/${AGENT_PKG}"
  rm -f "/tmp/${AGENT_PKG}"

  systemctl daemon-reload
  systemctl enable --now wazuh-agent

  echo "wazuh-agent hold" | dpkg --set-selections

  echo "[+] Agent '$NOME_AGENTE' installed and running!"
  systemctl status wazuh-agent --no-pager

else
  echo "Incorrect Use."
  echo "  Server: sudo bash $0 server"
  echo "  Client:  sudo bash $0 client <IP_WAZUH> <NAME_AGENT>"
  exit 1
fi
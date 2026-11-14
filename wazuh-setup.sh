#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[-] Execute como root (sudo bash $0)."
  exit 1
fi

if [ "$1" = "servidor" ]; then
  echo "[+] A instalar o Servidor Wazuh (All-In-One)..."
  apt update && apt upgrade -y
  apt install -y curl wget
  
  wget -O /tmp/wazuh-install.sh https://packages.wazuh.com/4.8/wazuh-install.sh
  bash /tmp/wazuh-install.sh -a -i
  
  echo -e "\n[+] Instalação concluída! Credenciais de acesso:"
  if [ -f "wazuh-install-files.tar" ]; then
    tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
  else
    echo "[-] Ficheiro wazuh-install-files.tar não encontrado no diretório atual."
  fi

elif [ "$1" = "cliente" ]; then
  IP_WAZUH="$2"
  NOME_AGENTE="$3"

  if [ -z "$IP_WAZUH" ] || [ -z "$NOME_AGENTE" ]; then
    echo "[-] Erro: Faltam parâmetros."
    echo "    Uso correto: sudo bash $0 cliente <IP_DO_WAZUH> <NOME_DO_AGENTE>"
    echo "    Exemplo:     sudo bash $0 cliente 10.10.50.30 srv-alvo"
    exit 1
  fi

  echo "[+] A configurar o Agente Wazuh '$NOME_AGENTE' associado a $IP_WAZUH..."
  curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

  echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list

  apt-get update
  WAZUH_MANAGER="$IP_WAZUH" WAZUH_AGENT_NAME="$NOME_AGENTE" apt-get install -y wazuh-agent

  systemctl daemon-reload
  systemctl enable --now wazuh-agent

  sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
  apt-get update
  echo "wazuh-agent hold" | dpkg --set-selections

  echo "[+] Agente '$NOME_AGENTE' instalado e a funcionar!"
  systemctl status wazuh-agent --no-pager

else
  echo "Uso incorreto."
  echo "  Servidor: sudo bash $0 servidor"
  echo "  Cliente:  sudo bash $0 cliente <IP_DO_WAZUH> <NOME_DO_AGENTE>"
  exit 1
fi

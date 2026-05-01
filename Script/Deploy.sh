#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}--- Démarrage de l'installation de la Gateway VPN ---${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être lancé en tant que root (ou via sudo).${NC}"
   exit 1
fi

# Update
echo -e "${GREEN}[1/6] Mise à jour de Debian...${NC}"
apt update -y && apt full-upgrade -y -qq

# IP Forwarding
echo -e "${GREEN}[2/6] Activation du routage IP...${NC}"
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
fi

# Installation de Pi-VPN (l'installeur est interactif)
echo -e "${YELLOW}[3/6] Lancement de l'installeur Pi-VPN...${NC}"
echo -e "${YELLOW}Note : Suivez les instructions à l'écran (Choisissez WireGuard).${NC}"
curl -L https://install.pivpn.io | bash

# Firewall (UFW)
echo -e "${GREEN}[4/6] Configuration du Pare-feu (UFW)...${NC}"
# Assurez-vous que votre port SSH est bien 45222 dans /etc/ssh/sshd_config avant de valider !
ufw default deny incoming
ufw default allow outgoing
ufw allow 51820/udp   # Port VPN
ufw allow 45222/tcp   # Port SSH (Modifiez si besoin)
echo "y" | ufw enable

# 6 Fail2Ban
echo -e "${GREEN}[5/6] Installation et configuration de Fail2Ban...${NC}"
apt install fail2ban -y
systemctl enable --now fail2ban

# 7. Création du premier client
echo -e "${YELLOW}[6/6] Création de votre premier profil VPN...${NC}"
pivpn add
pivpn -qr

echo -e "${GREEN}--- Installation terminée avec succès ! ---${NC}"
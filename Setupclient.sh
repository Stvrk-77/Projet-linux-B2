#!/bin/bash
# Script de provisionnement : Client (192.168.56.96)

# 1. Configuration de l'IP Statique et du DNS
echo "Configuration de l'interface LAN (enp0s3) en statique..."
sudo tee /etc/network/interfaces.d/51-lan.cfg > /dev/null <<EOF
auto enp0s3
iface enp0s3 inet static
    address 192.168.56.96
    netmask 255.255.255.0
    gateway 192.168.56.3
    dns-nameservers 192.168.56.3 8.8.8.8
EOF
sudo systemctl restart networking

# Correction /etc/resolv.conf
echo -e "nameserver 192.168.56.3\nsearch entreprise.local" | sudo tee /etc/resolv.conf > /dev/null

echo "Configuration du Client terminée. Vous pouvez tester le service web."
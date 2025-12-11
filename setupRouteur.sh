#!/bin/bash
# Script de provisionnement : Routeur (192.168.56.3 / NAT)

# 1. Configuration de l'IP Statique (Adaptez l'interface si besoin, ex: enp0s8)
# ATTENTION : NE PAS EXECUTER CECI SI VOUS UTILISEZ NETPLAN OU NETWORKMANAGER
echo "Configuration de l'interface LAN (enp0s8) en statique..."
sudo tee /etc/network/interfaces.d/51-lan.cfg > /dev/null <<EOF
auto enp0s8
iface enp0s8 inet static
    address 192.168.56.3
    netmask 255.255.255.0
    # DNS pour résolution externe
    dns-nameservers 8.8.8.8 8.8.4.4
EOF
sudo systemctl restart networking

# 2. Activation du Routage IP
echo 1 | sudo tee /proc/sys/net/ipv4.ip_forward > /dev/null
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
echo "Routage IP activé."

# 3. Installation et configuration du DNS (BIND9)
echo "Installation de BIND9..."
sudo apt update && sudo apt install -y bind9 dnsutils

# NOTE: La configuration des zones BIND9 (named.conf.local, db.entreprise.local, etc.)
# NE PEUT PAS être scriptée facilement. CELA DOIT ÊTRE FAIT MANUELLEMENT.
# 

# 4. Configuration du Pare-feu (NAT et FORWARD)
echo "Configuration du Pare-feu Iptables..."
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo netfilter-persistent save

echo "Configuration du Routeur terminée. Vérifiez la configuration BIND9 manuellement."
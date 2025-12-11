#!/bin/bash
# Script de provisionnement : Serveur Web (192.168.56.10)

# 1. Configuration de l'IP Statique et du DNS
echo "Configuration de l'interface LAN (enp0s3) en statique..."
# L'interface enp0s3 est utilisée pour le LAN dans ce cas (selon votre configuration)
sudo tee /etc/network/interfaces.d/51-lan.cfg > /dev/null <<EOF
auto enp0s3
iface enp0s3 inet static
    address 192.168.56.10
    netmask 255.255.255.0
    gateway 192.168.56.3
    dns-nameservers 192.168.56.3 8.8.8.8
EOF
sudo systemctl restart networking

# Correction /etc/resolv.conf (Problème de l'écraseur)
echo -e "nameserver 192.168.56.3\nsearch entreprise.local" | sudo tee /etc/resolv.conf > /dev/null

# 2. Installation de Nginx et création du Vhost
echo "Installation de Nginx et création du contenu..."
sudo apt update && sudo apt install -y nginx
sudo mkdir -p /var/www/entreprise.local/html

# Création d'un index.html simple
sudo tee /var/www/entreprise.local/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html><head><title>Bienvenue chez ENTREPRISE.LOCAL</title></head>
<body><h1>Bienvenue sur le site de l'Entreprise !</h1></body></html>
EOF

# Création du Vhost
sudo tee /etc/nginx/sites-available/entreprise.local.conf > /dev/null <<EOF
server {
    listen 80;
    server_name web.entreprise.local;
    root /var/www/entreprise.local/html;
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
    server_tokens off;
}
EOF

# Activation du Vhost et suppression du défaut
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/entreprise.local.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# 3. Configuration du Pare-feu Local
echo "Configuration du Pare-feu Iptables local..."
sudo iptables -P INPUT DROP
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo netfilter-persistent save

echo "Configuration du Serveur Web terminée. Prêt pour la sauvegarde."
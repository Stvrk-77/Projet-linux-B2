
# 📜 Journal des Commandes du Projet d'Infrastructure
# Toutes les commandes utilisées pour le déploiement complet du projet.



# I. Phase d'Initialisation et Réseau


# 1. Configuration IP statique du Serveur Web (192.168.56.10)
sudo nano /etc/network/interfaces
# Relecture de la configuration
sudo systemctl restart networking

# 2. Configuration du Routeur (Routage + NAT)
sudo nano /etc/sysctl.conf   # Ajouter : net.ipv4.ip_forward=1
sudo sysctl -p

sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo netfilter-persistent save


# II. Sécurité des Hôtes (Iptables)


sudo iptables -P INPUT DROP
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

sudo netfilter-persistent save
sudo iptables -L INPUT -n


# III. Déploiement des Services


# DNS – Installation (Routeur)
sudo apt update
sudo apt install bind9
sudo systemctl restart bind9

# Nginx – Installation et configuration
sudo apt install nginx
sudo mkdir -p /var/www/entreprise.local/html
sudo nano /var/www/entreprise.local/html/index.html

sudo nano /etc/nginx/sites-available/entreprise.local.conf
sudo ln -s /etc/nginx/sites-available/entreprise.local.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx



# IV. Stratégie de Résilience (Backup/Restore)

# 1. Mise en place de la sauvegarde
ssh-keygen -t rsa -b 4096
ssh-copy-id stark@192.168.56.3

sudo nano /usr/local/bin/backup_web.sh
sudo chmod +x /usr/local/bin/backup_web.sh

# 2. Cron
sudo crontab -e
# Ajouter :
# 0 2 * * * /usr/local/bin/backup_web.sh >> /var/log/backup_web.log 2>&1

sudo crontab -l

# 3. Script de restauration
sudo nano /usr/local/bin/restore_web.sh
sudo chmod +x /usr/local/bin/restore_web.sh



# V. Tests de Validation


# Client – Test DNS + Service Web
curl http://web.entreprise.local
dig web.entreprise.local

# Serveur Web – Test de restauration
sudo rm /etc/nginx/sites-enabled/*
sudo /usr/local/bin/restore_web.sh



# VI. Administration des Services


# Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo systemctl status nginx

# DNS
sudo systemctl restart bind9

# Réseau
sudo systemctl restart networking



# VII. Sauvegarde & Restauration (DRP)


# Sauvegarde forcée
sudo /usr/local/bin/backup_web.sh

# Restauration complète
sudo /usr/local/bin/restore_web.sh

# Restauration granulaire
sudo rsync -avz -e "ssh -i /home/stark/.ssh/id_rsa" stark@192.168.56.3:/chemin/du/fichier /destination/

# Vérification cron
sudo crontab -l

# Vérification sauvegardes sur le Routeur
ls -l /mnt/backups/webserver/



# VIII. Commandes de Test Rapide


# 1. Client : DNS
dig web.entreprise.local

# 2. Client : NAT
curl google.com

# 3. Client : Service Web
curl http://web.entreprise.local

# 4. Serveur Web : écoute Nginx
sudo ss -tuln | grep 80

# 5. Serveur Web : pare-feu
sudo iptables -L INPUT -n

# 6. Serveur Web : SSH
ssh stark@192.168.56.3 exit


# IX. Restauration Manuelle (Exemple : dossier Nginx)


sudo rsync -avz -e "ssh -i /home/stark/.ssh/id_rsa" \
stark@192.168.56.3:/mnt/backups/webserver/etc/nginx/ /etc/nginx/

sudo systemctl reload nginx



# X. Preuves DRP (Présentation)

# 1. Automatisation cron
sudo crontab -l

# 2. SSH sans mot de passe
ssh stark@192.168.56.3 exit

# 3. Sauvegarde manuelle
sudo /usr/local/bin/backup_web.sh

# 4. Vérification des sauvegardes
ls -l /mnt/backups/webserver/

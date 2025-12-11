# Groupe de projet : 
- Rodney NGUEMA
- Mathéo MAUSSANT

# 📄 Rapport Final de Projet d'Infrastructure Réseau et Services

Ce document présente la configuration, le déploiement et la validation de l'infrastructure réseau et des services de l'entreprise, y compris la stratégie de résilience (Sauvegarde/Restauration).

## I. Architecture et Adressage Réseau

L'infrastructure utilise un réseau isolé pour le LAN (`192.168.56.0/24`), avec le Routeur comme passerelle. 

### 1. Plan d'Adressage

| Rôle de la Machine | Adresse IP LAN | Interface LAN | Rôle WAN |
| :--- | :--- | :--- | :--- |
| **Routeur / DNS** | `192.168.56.3` | `enp0s8` | Passerelle NAT (`enp0s3`) |
| **Serveur Web** | `192.168.56.10` | `enp0s3` | Non |
| **Client de Test** | `192.168.56.96` | `enp0s3` | Non |

### 2. Configuration du Routeur (NAT et Routage)

* **Routage IP :** Activation permanente via `net.ipv4.ip_forward=1`.
* **Règle NAT (Masquerading) :**
    ```bash
    sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
    ```

## II. Sécurité Réseau (Firewall Iptables)

Les politiques par défaut sont `DROP` pour minimiser la surface d'attaque.

### 1. Règles du Serveur Web (`192.168.56.10`)

Le serveur Web applique une politique `INPUT DROP`.

* **Règles clés :**
    ```bash
    sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    sudo iptables -P INPUT DROP
    sudo netfilter-persistent save
    ```

## III. Déploiement des Services DNS et Web

### 1. Service DNS (BIND9 sur le Routeur)

BIND9 gère la zone `entreprise.local`.

* **Enregistrement clé :** `web.entreprise.local` $\rightarrow$ `192.168.56.10`.
* **Validation :** Le Client résout correctement le nom, confirmant la bonne configuration de `dns-nameservers` sur toutes les machines du LAN.

### 2. Serveur Web (Nginx Virtual Host)

Le service Nginx délivre la page personnalisée de l'entreprise.

* **Vhost (extrait) :**
    ```nginx
    server {
        listen 80;
        server_name web.entreprise.local;
        root /var/www/entreprise.local/html;
        index index.html;
        # ...
    }
    ```
* **Validation finale :** Le test `curl http://web.entreprise.local` affiche le contenu HTML personnalisé, confirmant le bon fonctionnement de l'ensemble de la chaîne.

## IV. Stratégie de Résilience (Sauvegarde et Restauration)

### 1. Stratégie de Sauvegarde Automatisée

* **Méthode :** `rsync` incrémentielle via SSH (Authentification par clé SSH sans *passphrase*). 
* **Automatisation :** Tâche `cron` quotidienne pour `root` (`0 2 * * *`).

#### Script de Sauvegarde (`/usr/local/bin/backup_web.sh`)

```bash
#!/bin/bash
USER="stark"; HOST="192.168.56.3"; DESTINATION="/mnt/backups/webserver"
IDENTITY_FILE="/home/stark/.ssh/id_rsa" 

CRITICAL_FILES=(
    "/var/www/entreprise.local"   # Contenu Web Personnalisé (le plus important)
    "/etc/nginx"                  # Configuration Nginx
    "/etc/iptables"               # Règles de Pare-feu
    # ... autres fichiers critiques
)

for FILE in "${CRITICAL_FILES[@]}"; do
    sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$FILE" "$USER"@"$HOST":"$DESTINATION"
done
```
### 2. Procédure de Restauration (Reprise après Sinistre)
La stratégie couvre la restauration complète après sinistre total (méthode privilégiée pour la démonstration) et la récupération granulaire (erreur humaine).

### A. Restauration Complète (Sinistre Total)
Procédure : Déploiement d'une VM de remplacement (clonée), rétablissement de la clé SSH, et exécution du script de restauration.
Script de Restauration (sudo /usr/local/bin/restore_web.sh)

```bash
#!/bin/bash
# Le serveur doit avoir l'IP 192.168.56.10 et une clé SSH valide.
USER="stark"; HOST="192.168.56.3"; SOURCE="/mnt/backups/webserver"
IDENTITY_FILE="/home/stark/.ssh/id_rsa"; WEB_CONTENT="/var/www/entreprise.local"

# 1. Restauration des fichiers (avec suppression des fichiers non sauvegardés)
sudo rsync -avzu --delete -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/entreprise.local/ "$WEB_CONTENT"/

# 2. Restauration des configurations
sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/etc/nginx/ /etc/nginx/
sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/etc/iptables/ /etc/iptables/

# 3. Application des nouvelles configurations
sudo netfilter-persistent reload 
sudo systemctl restart nginx

```
### B. Récupération Granulaire (Erreur Humaine sur Serveur de Production)
Pour restaurer un seul dossier (ex: /etc/nginx/) sans arrêter le service ni utiliser le script complet.

Commande (Exemple de récupération ciblée) :
```bash
sudo rsync -avz -e "ssh -i /home/stark/.ssh/id_rsa" \
stark@192.168.56.3:/mnt/backups/webserver/etc/nginx/ \
/etc/nginx/
# Suivi de : sudo systemctl reload nginx
``` 
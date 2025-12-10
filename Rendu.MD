# 📄 Rapport de Projet d'Infrastructure Réseau et Services

Ce document présente la configuration, le déploiement et la validation de l'infrastructure réseau de l'entreprise, y compris la mise en place des services DNS, Web, et la stratégie de résilience (Sauvegarde/Restauration).

## I. Architecture et Adressage Réseau

L'infrastructure est basée sur un réseau privé isolé (`Host-Only Network`) et utilise la machine **Routeur** comme passerelle (NAT) vers Internet.

### 1. Plan d'Adressage

| Rôle de la Machine | Adresse IP LAN | Interface LAN |
| :--- | :--- | :--- |
| **Routeur / DNS** | `192.168.56.3` | `enp0s8` |
| **Serveur Web** | `192.168.56.10` | `enp0s8` |
| **Client de Test** | `192.168.56.96` | `enp0s8` |

## II. Sécurité Réseau (Firewall Iptables)

Les politiques par défaut sont `DROP` et seules les communications essentielles sont autorisées.

### 1. Règles du Routeur (`192.168.56.3`)

* Politiques : `INPUT DROP`, `FORWARD DROP`, `OUTPUT ACCEPT`.
* Configuration : Règles NAT et `FORWARD` pour autoriser le trafic LAN vers WAN.

### 2. Règles du Serveur Web (`192.168.56.10`)

* Politique : `INPUT DROP`.
* Configuration : Ouverture des ports `22` (SSH) et `80` (HTTP).

## III. Déploiement des Services DNS et Web

### 1. Service DNS (BIND9 sur le Routeur)

BIND9 gère la zone `entreprise.local`. L'enregistrement clé est :
* `web.entreprise.local` $\rightarrow$ `192.168.56.10`

### 2. Serveur Web (Nginx Virtual Host)

Le serveur Web utilise Nginx avec un Virtual Host pointant vers `/var/www/entreprise.local/html` pour le domaine `web.entreprise.local`.

* **Validation finale :** `curl http://web.entreprise.local` retourne le contenu personnalisé.

## IV. Stratégie de Résilience (Sauvegarde et Restauration)

### 1. Stratégie de Sauvegarde Automatisée

* **Méthode :** `rsync` via SSH (Clé SSH sans *passphrase*).
* **Destination :** Le **Routeur** (`192.168.56.3`) dans `/mnt/backups/webserver`.
* **Automatisation :** Tâche `cron` quotidienne pour `root` (`0 2 * * *`).

#### Script de Sauvegarde (`/usr/local/bin/backup_web.sh`)

```bash
#!/bin/bash
USER="stark"; HOST="192.168.56.3"; DESTINATION="/mnt/backups/webserver"
IDENTITY_FILE="/home/stark/.ssh/id_rsa" 

CRITICAL_FILES=(
    "/var/www/entreprise.local"   # Contenu Web Personnalisé
    "/etc/nginx"                  # Configuration Nginx
    # ... autres fichiers critiques
)

for FILE in "${CRITICAL_FILES[@]}"; do
    sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$FILE" "$USER"@"$HOST":"$DESTINATION"
done 
```

# 2. Procédure de Restauration (Reprise après Sinistre)
La procédure de restauration est déclenchée suite à une panne du Serveur Web et vise à restaurer le service avec un minimum d'interruption en maintenant l'adresse IP (192.168.56.10).

## Étapes de la Restauration

1. Déploiement du Remplacement : Éteindre la VM Serveur Web défaillante. Déployer une nouvelle VM (via clonage de l'ancienne) en conservant l'IP 192.168.56.10.

2. Rétablissement de la Confiance SSH : Sur la nouvelle VM, générer une nouvelle paire de clés SSH (ssh-keygen) pour l'utilisateur stark et copier la clé publique sur le Routeur (ssh-copy-id).

3. Préparation du Script : S'assurer que le script /usr/local/bin/restore_web.sh est présent et exécutable sur la nouvelle VM.

4. Exécution de la Restauration : Lancer le script pour rapatrier les données et recharger les services.

5. Validation : Vérifier l'accès au site Web (curl http://web.entreprise.local).
Script de Restauration (/usr/local/bin/restore_web.sh)



### Le serveur doit avoir la même IP (192.168.56.10) et une clé SSH valide.
USER="stark"; HOST="192.168.56.3"; SOURCE="/mnt/backups/webserver"
IDENTITY_FILE="/home/stark/.ssh/id_rsa"; WEB_CONTENT="/var/www/entreprise.local"

### 1. Restauration des fichiers du site (avec suppression des fichiers non sauvegardés)
echo "1/3. Restauration du contenu web et des Vhosts Nginx..."
sudo rsync -avzu --delete -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/entreprise.local/ "$WEB_CONTENT"/

### 2. Restauration des configurations (écrasement des fichiers locaux)
echo "2/3. Restauration des fichiers de configuration..."
sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/etc/nginx/ /etc/nginx/
sudo rsync -avzu -e "ssh -i $IDENTITY_FILE" "$USER"@"$HOST":"$SOURCE"/etc/iptables/ /etc/iptables/

### 3. Application des nouvelles configurations
echo "3/3. Application des nouvelles configurations..."
sudo netfilter-persistent reload 
sudo systemctl restart nginx     

echo "--- Restauration terminée ---"
#!/bin/bash
# Ce script doit être créé après la clé SSH pour l'utilisateur 'stark'.
#(Chemin : /usr/local/bin/backup_web.sh)
USER="stark"; HOST="192.168.56.3"; DESTINATION="/mnt/backups/webserver"
IDENTITY_FILE="/home/stark/.ssh/id_rsa" 
# ... (Contenu du script rsync)
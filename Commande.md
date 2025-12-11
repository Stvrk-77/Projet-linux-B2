## I. Réseau et Diagnostic de Base

| Catégorie                 | Commande                       | Rôle                                                             |
|---------------------------|--------------------------------|------------------------------------------------------------------|
| Vérification IP           | `ip a` ou `ip addr show`       | Affiche les adresses IP et les interfaces du système.            |
| Test de Connectivité      | `ping 192.168.56.3`            | Vérifie la connexion au Routeur.                                 |
| Test NAT/Internet         | `curl google.com`              | Vérifie que la NAT et le routage fonctionnent.                   |
| Diagnostic DNS            | `dig web.entreprise.local`     | Teste la résolution du nom via le serveur DNS configuré.         |
| Pare-feu (Affichage)      | `sudo iptables -L INPUT -n`    | Affiche les règles actives de la chaîne INPUT (Sécurité).        |
| Pare-feu (Sauvegarde)     | `sudo netfilter-persistent save` | Rend les règles iptables persistantes au redémarrage.          |
| Ports Ouverts             | `sudo ss -tuln`                | Liste les ports TCP/UDP ouverts et les applications associées.   |

## II. Administration des Services

| Service                 | Commande                          | Rôle                                                                                 |
|-------------------------|-----------------------------------|--------------------------------------------------------------------------------------|
| Nginx (Test de Conf)    | `sudo nginx -t`                   | Vérifie la syntaxe des fichiers de configuration Nginx avant le rechargement.        |
| Nginx (Redémarrer)      | `sudo systemctl restart nginx`    | Redémarre le service (nécessaire après modification de ports ou d'interfaces).       |
| Nginx (Recharger)       | `sudo systemctl reload nginx`     | Applique les modifications des Vhosts **sans couper les connexions existantes**.     |
| Nginx (État)            | `sudo systemctl status nginx`     | Vérifie si Nginx est actif (`active (running)`).                                     |
| DNS (Redémarrer)        | `sudo systemctl restart bind9`    | Redémarre le service BIND9 (sur le Routeur, après modification de zones).            |
| Réseau (Redémarrer)     | `sudo systemctl restart networking` | Force la relecture de `/etc/network/interfaces`.                                    |


## III. Sauvegarde et Restauration (DRP)

| Opération                | Contexte                                      | Commande                                                                                          |
|--------------------------|-----------------------------------------------|----------------------------------------------------------------------------------------------------|
| Sauvegarde Forcée        | Serveur Web (Test ou Urgent)                  | `sudo /usr/local/bin/backup_web.sh`                                                               |
| Restauration Complète    | Serveur Web de Remplacement (Sinistre)        | `sudo /usr/local/bin/restore_web.sh`                                                              |
| Restauration Granulaire  | Serveur Web (Erreur de Fichier)               | `sudo rsync -avz -e "ssh -i /home/stark/.ssh/id_rsa" stark@192.168.56.3:/chemin/du/fichier /destination/` |
| Vérification cron        | Serveur Web (Administration)                  | `sudo crontab -l`                                                                                 |
| Vérification Sauvegarde  | Routeur (Routeur)                             | `ls -l /mnt/backups/webserver/`                                                                   |

## 📝 Commandes de Test Rapide (Validation de Fonctionnement)

| N° | Où Exécuter   | Objectif Démontré                        | Commande à Taper                                   |
|----|----------------|-------------------------------------------|-----------------------------------------------------|
| 1  | Client         | Résolution DNS (Service BIND9)            | `dig web.entreprise.local`                          |
| 2  | Client         | Test NAT / Routage                        | `curl google.com`                                   |
| 3  | Client         | Service Web Final (Nginx, Vhost, Iptables) | `curl http://web.entreprise.local`                 |
| 4  | Serveur Web    | Preuve de l'Écoute Nginx                  | `sudo ss -tuln | grep 80`                           |
| 5  | Serveur Web    | Preuve du Pare-feu (Sécurité)             | `sudo iptables -L INPUT -n`                         |
| 6  | Serveur Web    | Preuve Sauvegarde (SSH)                   | `ssh stark@192.168.56.3 exit`                       |


## Preuves de Fonctionnement – Validation DRP

| N° | Où Exécuter  | Objectif Démontré                      | Commande à Taper                           | Preuve de Réussite |
|----|--------------|------------------------------------------|---------------------------------------------|---------------------|
| 1  | Serveur Web  | Preuve de l'automatisation cron          | `sudo crontab -l`                           | La ligne `0 2 * * * /usr/local/bin/backup_web.sh` est visible (planification quotidienne). |
| 2  | Serveur Web  | Preuve de l'authentification SSH         | `ssh stark@192.168.56.3 exit`               | La connexion réussit et se ferme sans demander de mot de passe. |
| 3  | Serveur Web  | Exécution manuelle de la sauvegarde      | `sudo /usr/local/bin/backup_web.sh`         | Le script s'exécute sans erreur et lance le transfert de fichiers. |
| 4  | Routeur      | Vérification des fichiers sauvegardés    | `ls -l /mnt/backups/webserver/`             | Les dossiers de sauvegarde sont présents et les dates correspondent à l’exécution. |

## Contexte
Nous allons prendre l'exemple de la restauration du dossier complet de configuration **Nginx** (`/etc/nginx/`).

## Restauration Manuelle (Nginx)

| Opération              | Contexte                                   | Commande |
|------------------------|---------------------------------------------|----------|
| Restauration Manuelle  | Serveur Web (Réparation d’un dossier spécifique) | `sudo rsync -avz -e "ssh -i /home/stark/.ssh/id_rsa" stark@192.168.56.3:/mnt/backups/webserver/etc/nginx/ /etc/nginx/` |
| Action Complémentaire  | Après la restauration Nginx                 | `sudo systemctl reload nginx` |

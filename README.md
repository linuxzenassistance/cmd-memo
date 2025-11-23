<h1 align="center">cmdmemo</h1> <p align="center"><strong>Gestionnaire de mémos de commandes Linux</strong><br> Un outil Bash simple, propre et efficace pour organiser vos commandes Linux en catégories.</p> <p align="center"> <img src="https://img.shields.io/badge/shell-bash-green" /> <img src="https://img.shields.io/badge/status-stable-brightgreen" /> <img src="https://img.shields.io/badge/license-MIT-blue" /> </p>
📌 Présentation

cmdmemo est un gestionnaire de mémos technique pour GNU/Linux, basé sur un fichier TSV minimaliste et lisible.
Il permet de stocker, rechercher et classer vos commandes préférées, par catégorie, niveau (root/user), commande et description.

Entièrement écrit en Bash, il est :

✔️ simple

✔️ portable

✔️ rapide

✔️ modifiable

✔️ sans dépendances

✔️ adapté aux débutants comme aux utilisateurs avancés

C’est un outil pensé pour les administrateurs systèmes, formateurs, techniciens, ou toute personne qui veut garder une mémoire technique propre et consultable instantanément.

🗂️ Fonctionnalités principales

Ajouter une nouvelle commande (add)

Modifier une commande existante (edit)

Supprimer une commande (delete)

Rechercher dans toutes les commandes (search)

Lister les commandes d'une catégorie (list)

Gestion dynamique des catégories :

Ajouter une catégorie (addcateg)

Renommer une catégorie (renamecateg)

Supprimer une catégorie avec réaffectation (deletecateg)

Fichier TSV lisible indépendamment

Fichier de catégories externe (cmdmemo.categ)

Zéro dépendance, aucun bashisme exotique

📦 Installation
🔧 Méthode manuelle (simple)
git clone https://github.com/linux-zen-assistance/cmdmemo.git
cd cmdmemo
chmod +x cmdmemo.sh


Ajoutez ensuite à votre ~/.bashrc :

alias cm="$HOME/Dev/GitHub/linux-zen-assistance/cmdmemo/cmdmemo.sh"


Rechargez :

source ~/.bashrc


Vous pouvez maintenant utiliser :

cm -c
cm -s ssh
cm -a

🚀 Utilisation rapide
Lister les catégories
cm -c

Lister les commandes d’une catégorie
cm -l system

Ajouter une commande
cm -a

Rechercher
cm -s apache

Ajouter une catégorie
cm -A

Renommer une catégorie
cm -R oldname newname

Supprimer une catégorie
cm -D files

🧱 Structure des fichiers
cmdmemo/
 ├─ cmdmemo.sh          → Script principal
 ├─ cmdmemo.tsv         → Base de données TSV
 ├─ cmdmemo.categ       → Liste dynamique des catégories
 └─ README.md           → Documentation


Le format du TSV :

categorie<TAB>level<TAB>commande<TAB>description


Exemple :

system	user	ls	Afficher le contenu d'un répertoire
network	root	ip a	Afficher la configuration réseau

🛠️ Contribuer

Les contributions sont les bienvenues :

ajout de fonctionnalités

amélioration du code

suggestions

corrections

documentation

Forkez le dépôt et ouvrez une pull request depuis votre compte GitHub.

🔒 Licence

Ce projet est distribué sous licence MIT.
Vous êtes libre de l’utiliser, le modifier et le redistribuer.

👤 Auteur

Projet développé et maintenu par Linux Zen Assistance
https://linuxzenassistance.com

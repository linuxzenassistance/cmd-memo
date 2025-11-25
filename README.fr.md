<p align="right">🇬🇧 <a href="README.md">English version</a></p>

<h1 align="center">cmd-memo</h1>
<p align="center">
  <strong>Gestionnaire de mémos de commandes Linux</strong><br>
  Un outil Bash simple, propre et efficace pour organiser vos commandes Linux par catégories.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-green" />
  <img src="https://img.shields.io/badge/statut-stable-brightgreen" />
  <img src="https://img.shields.io/badge/licence-MIT-blue" />
</p>

---

## 📌 Présentation

**cmd-memo** est un gestionnaire de mémos techniques pour GNU/Linux, basé sur un fichier TSV minimaliste et lisible.

Il permet de stocker, rechercher et organiser vos commandes favorites selon :

- la catégorie  
- le niveau (root/user)  
- la commande  
- la description  

Écrit entièrement en Bash, il est :

- ✔️ simple  
- ✔️ portable  
- ✔️ rapide  
- ✔️ facile à modifier  
- ✔️ sans dépendances externes  
- ✔️ adapté aux débutants comme aux utilisateurs avancés  

Idéal pour administrateurs systèmes, formateurs, techniciens, ou toute personne souhaitant garder une mémoire technique propre et facilement consultable.

---

## 🗂️ Fonctionnalités principales

- Ajouter une commande (`add`)
- Modifier une commande (`edit`)
- Supprimer une commande (`delete`)
- Rechercher dans toutes les commandes (`search`)
- Lister les commandes d’une catégorie (`list`)

**Gestion dynamique des catégories :**

- Ajouter une catégorie (`addcateg`)
- Renommer une catégorie (`renamecateg`)
- Supprimer une catégorie avec réaffectation (`deletecateg`)

**Fichiers utilisés :**

- Fichier TSV lisible  
- Fichier de catégories externe (`cmd-memo.categ`)  
- Aucune dépendance, pas de bibliothèques exotiques

---

## 📦 Installation

### 🔧 Méthode manuelle (simple)

```bash
git clone https://github.com/linuxzenassistance/cmd-memo.git
cd cmd-memo
chmod +x cmd-memo.sh

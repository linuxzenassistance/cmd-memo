<p align="right">🇫🇷 <a href="README.fr.md">Version française</a></p>

<h1 align="center">cmd-memo</h1>
<p align="center">
  <strong>Linux command memo manager</strong><br>
  A simple, clean and efficient Bash tool to organize your Linux commands by categories.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-green" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
</p>

---

## 📌 Overview

**cmd-memo** is a technical memo manager for GNU/Linux, based on a minimalist and human-readable TSV file.

It lets you store, search and organize your favorite commands by:

- category  
- level (root/user)  
- command  
- description  

Written entirely in Bash, it is:

- ✔️ simple  
- ✔️ portable  
- ✔️ fast  
- ✔️ easy to modify  
- ✔️ dependency-free  
- ✔️ suitable for both beginners and advanced users  

It is designed for system administrators, trainers, technicians, and anyone who wants to keep a clean, instantly searchable technical memory.

---

## 🗂️ Main features

- Add a new command (`add`)
- Edit an existing command (`edit`)
- Delete a command (`delete`)
- Search across all commands (`search`)
- List all commands in a category (`list`)

**Dynamic category management:**

- Add a category (`addcateg`)
- Rename a category (`renamecateg`)
- Delete a category with reassignment (`deletecateg`)

**Data files:**

- Human-readable TSV file  
- External category file (`cmd-memo.categ`)  
- Zero external dependencies, no exotic Bash features

---

## 📦 Installation

### 🔧 Manual (simple) method

```bash
git clone https://github.com/linuxzenassistance/cmd-memo.git
cd cmd-memo
chmod +x cmd-memo.sh

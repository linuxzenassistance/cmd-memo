#!/usr/bin/env bash
#
# cmdmemo.sh – gestionnaire de mémos de commandes
# Format TSV (tabulations réelles) :
#   category<TAB>root|user<TAB>command<TAB>detail
#

set -euo pipefail

# Répertoire du script et fichier TSV associé
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD_FILE="${SCRIPT_DIR}/cmdmemo.tsv"

# Fichier des catégories
CAT_FILE="${SCRIPT_DIR}/cmdmemo.categ"

# Catégories par défaut (utilisées pour initialiser le fichier si absent)
DEFAULT_CATEGORIES=(
  system
  packages
  services
  files
  network
  firewall
  backup
  audio
  video
  image
)

# Tableau en mémoire rempli à partir du fichier de catégories
VALID_CATEGORIES=()

ensure_cat_file_exists() {
  if [[ ! -f "$CAT_FILE" ]]; then
    printf '# Liste des catégories pour cmdmemo\n' >"$CAT_FILE"
    local c
    for c in "${DEFAULT_CATEGORIES[@]}"; do
      printf '%s\n' "$c" >>"$CAT_FILE"
    done
  fi
}

load_categories() {
  ensure_cat_file_exists
  # Charge les catégories non vides, non commentées, triées
  mapfile -t VALID_CATEGORIES < <(
    grep -v '^[[:space:]]*#' "$CAT_FILE" | sed '/^[[:space:]]*$/d' | sort -u
  )
}

# --------------------------------------------------------------------
# Utilitaires
# --------------------------------------------------------------------

usage() {
  cat <<EOF
***************************************************************
Bienvenue dans cmdmemo
Gestionnaire de memos de commandes
Création  LINUX ZEN ASSISTANCE - https://linuxzenassistance.fr
***************************************************************

Usage : $(basename "$0") <commande> [arguments]

Commandes :
 categ (-c)           Lister les catégories présentes dans le fichier
  list  (-l) <categ>   Lister les commandes d'une catégorie
  search(-s) <texte>   Rechercher dans catégorie / niveau / commande / détail
  add   (-a)           Ajouter une nouvelle entrée
  edit  (-e) <cmd>     Modifier une entrée par commande exacte
  delete(-d) <cmd>     Supprimer une entrée par commande exacte
  addcateg   (-A)      Ajouter une catégorie
  renamecateg(-R)      Renommer une catégorie
  deletecateg(-D)      Supprimer une catégorie (avec réaffectation)
  help                 Afficher cette aide

Le fichier de données est : ${CMD_FILE}
Format TSV : category<TAB>root|user<TAB>command<TAB>detail
EOF
}

ensure_file_exists() {
  if [[ ! -f "$CMD_FILE" ]]; then
    printf '# vim: set noexpandtab ts=4 :\n' >"$CMD_FILE"
  fi
}

# Vérifie si une valeur est dans le tableau VALID_CATEGORIES
is_valid_category() {
  local cat="$1"
  load_categories
  for c in "${VALID_CATEGORIES[@]}"; do
    if [[ "$c" == "$cat" ]]; then
      return 0
    fi
  done
  return 1
}

# Parcourt toutes les entrées (ignore les lignes de commentaire)
# et appelle une fonction callback avec :
#   callback "category" "level" "command" "detail"
for_each_entry() {
  local callback="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$line"
    [[ -z "${category:-}" || -z "${level:-}" || -z "${command:-}" ]] && continue
    "$callback" "$category" "$level" "$command" "$detail"
  done <"$CMD_FILE"
}

# Cherche une entrée par "command" exacte.
# Affiche la ligne complète si trouvée, sinon rien.
find_line_by_command() {
  local needle="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$line"
    [[ -z "${command:-}" ]] && continue
    if [[ "$command" == "$needle" ]]; then
      printf '%s\n' "$line"
      return 0
    fi
  done <"$CMD_FILE"
  return 1
}

# Teste l'existence d'une commande (clé unique)
command_exists() {
  local needle="$1"
  if find_line_by_command "$needle" >/dev/null; then
    return 0
  else
    return 1
  fi
}

# Affiche une entrée (category/level/command + détail multi-ligne aligné)
print_entry_block() {
  local category="$1"
  local level="$2"
  local command="$3"
  local detail="$4"

  # Sélection couleur root/user
  local lvl_color="$C_USER"
  if [[ "$level" == "root" ]]; then
    lvl_color="$C_ROOT"
  fi

  # Ligne principale : category (jaune), level (cyan/rouge), command (gras)
  printf '%b%-9s%b %b%-6s%b %b%s%b\n' \
    "$C_CAT" "$category" "$C_RESET" \
    "$lvl_color" "$level" "$C_RESET" \
    "$C_BOLD" "$command" "$C_RESET"

  # Détail multi-lignes (pas d’italique)
  local detail_decoded="${detail//\\n/$'\n'}"

  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    printf '%-9s %-6s   %s\n' "" "" "$line"
  done <<< "$detail_decoded"
}

# --------------------------------------------------------------------
# Commandes
# --------------------------------------------------------------------

# 1) Liste des catégories présentes dans le fichier
cmd_list() {
  ensure_file_exists
  local cat="${1:-}"

  if [[ -z "$cat" ]]; then
    echo "Erreur : il faut préciser une catégorie." >&2
    echo "Utilisation : $(basename "$0") list <categ>" >&2
    exit 1
  fi

  local found=0

  list_callback() {
    local category="$1"
    local level="$2"
    local command="$3"
    local detail="$4"

    if [[ "$category" == "$cat" ]]; then
      found=1
      print_entry_block "$category" "$level" "$command" "$detail"
    fi
  }

  for_each_entry list_callback

  if (( ! found )); then
    # Ici on distingue : catégorie vide vs catégorie inconnue
    load_categories
    local exists=0
    local c
    for c in "${VALID_CATEGORIES[@]}"; do
      if [[ "$c" == "$cat" ]]; then
        exists=1
        break
      fi
    done

    if (( exists )); then
      echo "Aucune commande dans la catégorie \"$cat\""
    else
      echo "La catégorie \"$cat\" n'existe pas"
    fi
  fi
}

# 3) search <texte> : recherche globale
cmd_search() {
  ensure_file_exists
  local query="${1:-}"
  if [[ -z "$query" ]]; then
    echo "Erreur : il faut préciser un texte de recherche." >&2
    echo "Utilisation : $(basename "$0") search <texte>" >&2
    exit 1
  fi

  local q_lc="${query,,}"
  local found=0

  search_callback() {
    local category="$1"
    local level="$2"
    local command="$3"
    local detail="$4"

    local c_lc="${category,,}"
    local l_lc="${level,,}"
    local cmd_lc="${command,,}"
    local d_lc="${detail,,}"

    if [[ "$c_lc" == *"$q_lc"* || \
          "$l_lc" == *"$q_lc"* || \
          "$cmd_lc" == *"$q_lc"* || \
          "$d_lc" == *"$q_lc"* ]]; then
      found=1
      print_entry_block "$category" "$level" "$command" "$detail"
    fi
  }

  for_each_entry search_callback

  if (( ! found )); then
    echo "Aucun résultat pour : $query"
  fi
}

# 4) add : ajout d'une entrée
cmd_add() {
  ensure_file_exists

  echo "=== Ajout d'une nouvelle commande ==="

  ##
  ## Sélection de la catégorie via un petit menu
  ##
  load_categories
  echo "Choisissez une catégorie :"
  local i=1
  local cat
  for cat in "${VALID_CATEGORIES[@]}"; do
    printf "%2d) %s\n" "$i" "$cat"
    ((i++))
  done

  local choice
  read -rp "Numéro (1-${#VALID_CATEGORIES[@]}) [1] : " choice
  choice="${choice:-1}"

  # Sécurité : vérifier numéro valide
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#VALID_CATEGORIES[@]} )); then
    echo "Numéro invalide."
    exit 1
  fi

  local index=$((choice-1))
  local category="${VALID_CATEGORIES[$index]}"

  if ! is_valid_category "$category"; then
    echo "Catégorie inconnue : $category" >&2
    echo "Catégories valides : ${VALID_CATEGORIES[*]}" >&2
    exit 1
  fi

  # Niveau root/user
  local level
  read -rp "Niveau (root/user) [user] : " level
  level="${level:-user}"
  if [[ "$level" != "root" && "$level" != "user" ]]; then
    echo "Niveau invalide : $level (attendu : root ou user)" >&2
    exit 1
  fi

  # Commande (clé)
  local command
  read -rp "Commande (sans sudo) : " command
  if [[ -z "$command" ]]; then
    echo "Erreur : la commande ne peut pas être vide." >&2
    exit 1
  fi

  if command_exists "$command"; then
    echo "Erreur : une entrée existe déjà pour cette commande, ajout refusé." >&2
    exit 1
  fi

  # Détail (une ligne pour l'instant ; on pourra gérer du multi-ligne plus tard)
  local detail
  read -rp "Détail (commentaire court) : " detail

  # On évite les tabulations dans le détail
  detail="${detail//	/    }"

  # Ajout à la fin du fichier
  printf '%s\t%s\t%s\t%s\n' "$category" "$level" "$command" "$detail" >>"$CMD_FILE"

  echo "Entrée ajoutée."
}

# 5) delete <commande> : suppression par nom de commande exact
cmd_delete() {
  ensure_file_exists
  local needle="${1:-}"

  if [[ -z "$needle" ]]; then
    echo "Erreur : il faut préciser la commande exacte à supprimer." >&2
    echo "Utilisation : $(basename "$0") delete <commande>" >&2
    exit 1
  fi

  local tmp
  tmp="$(mktemp)"
  local deleted=0
  local line

  while IFS= read -r line; do
    # Conserver les lignes vides
    if [[ -z "$line" ]]; then
      printf '\n' >>"$tmp"
      continue
    fi

    # Conserver les commentaires (dont la modeline)
    if [[ "${line:0:1}" == "#" ]]; then
      printf '%s\n' "$line" >>"$tmp"
      continue
    fi

    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$line"

    # Si la commande correspond, on ne recopie pas (on supprime)
    if [[ "$command" == "$needle" ]]; then
      deleted=1
      continue
    fi

    # Sinon, on recopie la ligne telle quelle
    printf '%s\n' "$line" >>"$tmp"

  done <"$CMD_FILE"

  mv "$tmp" "$CMD_FILE"

  if (( deleted )); then
    echo "supprimé"
  else
    echo "non trouvé"
  fi
}

# 6) edit <commande> : modifier une entrée existante
cmd_edit() {
  ensure_file_exists
  local needle="${1:-}"

  if [[ -z "$needle" ]]; then
    echo "Erreur : il faut préciser la commande exacte à modifier." >&2
    echo "Utilisation : $(basename "$0") edit <commande>" >&2
    exit 1
  fi

  local line
  if ! line="$(find_line_by_command "$needle")"; then
    echo "Commande \"$needle\" introuvable." >&2
    exit 1
  fi

  local old_category old_level old_command old_detail
  IFS=$'\t' read -r old_category old_level old_command old_detail <<<"$line"

  echo "=== Modification d'une commande ==="
  echo "Commande actuelle : $old_command"

  # --- Catégorie ---
  echo "Catégorie actuelle : $old_category"
  load_categories
  echo "Choisissez une catégorie :"
  local i=1
  local cat
  for cat in "${VALID_CATEGORIES[@]}"; do
    printf "%2d) %s\n" "$i" "$cat"
    ((i++))
  done

  local choice
  read -rp "Numéro (1-${#VALID_CATEGORIES[@]}) [garder ${old_category}] : " choice

  local new_category="$old_category"
  if [[ -n "$choice" ]]; then
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#VALID_CATEGORIES[@]} )); then
      echo "Numéro invalide."
      exit 1
    fi
    local index=$((choice-1))
    new_category="${VALID_CATEGORIES[$index]}"
  fi

  if ! is_valid_category "$new_category"; then
    echo "Catégorie inconnue : $new_category" >&2
    echo "Catégories valides : ${VALID_CATEGORIES[*]}" >&2
    exit 1
  fi

  # --- Niveau root/user ---
  local new_level
  read -rp "Niveau (root/user) [${old_level}] : " new_level
  new_level="${new_level:-$old_level}"
  if [[ "$new_level" != "root" && "$new_level" != "user" ]]; then
    echo "Niveau invalide : $new_level (attendu : root ou user)" >&2
    exit 1
  fi

  # --- Commande ---
  local new_command
  read -rp "Commande (sans sudo) [${old_command}] : " new_command
  new_command="${new_command:-$old_command}"
  if [[ -z "$new_command" ]]; then
    echo "Erreur : la commande ne peut pas être vide." >&2
    exit 1
  fi

  if [[ "$new_command" != "$old_command" ]] && command_exists "$new_command"; then
    echo "Erreur : une entrée existe déjà pour cette commande, modification refusée." >&2
    exit 1
  fi

  # --- Détail ---
  local prompt_detail="Détail (commentaire court)"
  if [[ -n "$old_detail" ]]; then
    prompt_detail+=" [${old_detail}]"
  fi
  prompt_detail+=" : "
  local new_detail
  read -rp "$prompt_detail" new_detail
  new_detail="${new_detail:-$old_detail}"

  # On évite les tabulations dans le détail
  new_detail="${new_detail//	/    }"

  # --- Réécriture du fichier avec la ligne modifiée ---
  local tmp
  tmp="$(mktemp)"
  local edited=0
  local cur_line

  while IFS= read -r cur_line; do
    # Conserver les lignes vides
    if [[ -z "$cur_line" ]]; then
      printf '\n' >>"$tmp"
      continue
    fi

    # Conserver les commentaires (dont la modeline)
    if [[ "${cur_line:0:1}" == "#" ]]; then
      printf '%s\n' "$cur_line" >>"$tmp"
      continue
    fi

    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$cur_line"

    if [[ "$command" == "$old_command" ]]; then
      printf '%s\t%s\t%s\t%s\n' "$new_category" "$new_level" "$new_command" "$new_detail" >>"$tmp"
      edited=1
    else
      printf '%s\n' "$cur_line" >>"$tmp"
    fi
  done <"$CMD_FILE"

  mv "$tmp" "$CMD_FILE"

  if (( edited )); then
    echo "modifié"
  else
    echo "Aucune modification effectuée." >&2
  fi
}

# 7) addcateg : ajouter une catégorie
cmd_addcateg() {
  ensure_cat_file_exists
  load_categories

  local new_cat
  read -rp "Nom de la nouvelle catégorie : " new_cat

  if [[ -z "$new_cat" ]]; then
    echo "Erreur : la catégorie ne peut pas être vide." >&2
    exit 1
  fi

  # On interdit juste la tabulation dans le nom
  if [[ "$new_cat" == *$'\t'* ]]; then
    echo "Erreur : la catégorie ne doit pas contenir de tabulation." >&2
    exit 1
  fi

  # Vérifier que la catégorie n'existe pas déjà
  local c
  for c in "${VALID_CATEGORIES[@]}"; do
    if [[ "$c" == "$new_cat" ]]; then
      echo "Erreur : cette catégorie existe déjà." >&2
      exit 1
    fi
  done

  # Ajouter et réécrire le fichier de catégories trié
  VALID_CATEGORIES+=("$new_cat")

  local tmp
  tmp="$(mktemp)"
  printf '# Liste des catégories pour cmdmemo\n' >"$tmp"
  printf '%s\n' "${VALID_CATEGORIES[@]}" | sort -u >>"$tmp"
  mv "$tmp" "$CAT_FILE"

  echo "Catégorie \"$new_cat\" ajoutée."
}

# 8) renamecateg : renommer une catégorie (dans TSV + fichier de catégories)
cmd_renamecateg() {
  ensure_cat_file_exists
  ensure_file_exists

  local old="${1:-}"
  local new="${2:-}"

  if [[ -z "$old" || -z "$new" ]]; then
    echo "Erreur : il faut préciser l'ancienne et la nouvelle catégorie." >&2
    echo "Utilisation : $(basename "$0") renamecateg <ancienne> <nouvelle>" >&2
    exit 1
  fi

  load_categories

  local found_old=0
  local c
  for c in "${VALID_CATEGORIES[@]}"; do
    if [[ "$c" == "$old" ]]; then
      found_old=1
    fi
    if [[ "$c" == "$new" ]]; then
      echo "Erreur : la catégorie \"$new\" existe déjà." >&2
      exit 1
    fi
  done

  if (( ! found_old )); then
    echo "Cette catégorie n'existe pas : $old" >&2
    exit 1
  fi

  # Réécrire le TSV avec old -> new dans la première colonne
  local tmp
  tmp="$(mktemp)"
  local line

  while IFS= read -r line; do
    # lignes vides
    if [[ -z "$line" ]]; then
      printf '\n' >>"$tmp"
      continue
    fi

    # commentaires (modeline incluse)
    if [[ "${line:0:1}" == "#" ]]; then
      printf '%s\n' "$line" >>"$tmp"
      continue
    fi

    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$line"

    if [[ "$category" == "$old" ]]; then
      category="$new"
    fi

    printf '%s\t%s\t%s\t%s\n' "$category" "$level" "$command" "$detail" >>"$tmp"
  done <"$CMD_FILE"

  mv "$tmp" "$CMD_FILE"

  # Mettre à jour le fichier des catégories
  local tmp2
  tmp2="$(mktemp)"
  printf '# Liste des catégories pour cmdmemo\n' >"$tmp2"
  for c in "${VALID_CATEGORIES[@]}"; do
    if [[ "$c" == "$old" ]]; then
      printf '%s\n' "$new"
    else
      printf '%s\n' "$c"
    fi
  done | sort -u >>"$tmp2"
  mv "$tmp2" "$CAT_FILE"

  echo "Catégorie \"$old\" renommée en \"$new\"."
}

# 9) deletecateg : supprimer une catégorie (avec réaffectation)
cmd_deletecateg() {
  ensure_cat_file_exists
  ensure_file_exists

  local to_delete="${1:-}"
  if [[ -z "$to_delete" ]]; then
    echo "Erreur : il faut préciser la catégorie à supprimer." >&2
    echo "Utilisation : $(basename "$0") deletecateg <categorie>" >&2
    exit 1
  fi

  load_categories

  local found=0
  local c
  for c in "${VALID_CATEGORIES[@]}"; do
    if [[ "$c" == "$to_delete" ]]; then
      found=1
      break
    fi
  done

  if (( ! found )); then
    echo "Cette catégorie n'existe pas : $to_delete" >&2
    exit 1
  fi

  # Construire la liste des autres catégories
  local OTHER_CATEGORIES=()
  for c in "${VALID_CATEGORIES[@]}"; do
    [[ "$c" == "$to_delete" ]] && continue
    OTHER_CATEGORIES+=("$c")
  done

  # Vérifier si cette catégorie est utilisée dans le TSV
  local used=0
  while IFS=$'\t' read -r category level command detail; do
    [[ -z "$category" || "${category:0:1}" == "#" ]] && continue
    if [[ "$category" == "$to_delete" ]]; then
      used=1
      break
    fi
  done <"$CMD_FILE"

  # Si aucune entrée n'utilise cette catégorie → suppression directe
  if (( used == 0 )); then
    local tmp3
    tmp3="$(mktemp)"
    printf '# Liste des catégories pour cmdmemo\n' >"$tmp3"
    for c in "${OTHER_CATEGORIES[@]}"; do
      printf '%s\n' "$c"
    done | sort -u >>"$tmp3"
    mv "$tmp3" "$CAT_FILE"

    echo "Catégorie \"$to_delete\" supprimée (aucune commande ne l'utilisait)."
    return 0
  fi

  if (( ${#OTHER_CATEGORIES[@]} == 0 )); then
    echo "Impossible de supprimer la dernière catégorie." >&2
    exit 1
  fi

  echo "Vous allez supprimer la catégorie \"$to_delete\"."
  echo "Les commandes de cette catégorie doivent être réaffectées."
  echo "Choisissez la catégorie de remplacement :"

  local i=1
  for c in "${OTHER_CATEGORIES[@]}"; do
    printf "%2d) %s\n" "$i" "$c"
    ((i++))
  done

  local choice
  read -rp "Numéro (1-${#OTHER_CATEGORIES[@]}) : " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#OTHER_CATEGORIES[@]} )); then
    echo "Numéro invalide."
    exit 1
  fi

  local target="${OTHER_CATEGORIES[choice-1]}"

  # Réécrire le TSV : to_delete -> target
  local tmp
  tmp="$(mktemp)"
  local line

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      printf '\n' >>"$tmp"
      continue
    fi

    if [[ "${line:0:1}" == "#" ]]; then
      printf '%s\n' "$line" >>"$tmp"
      continue
    fi

    local category level command detail
    IFS=$'\t' read -r category level command detail <<<"$line"

    if [[ "$category" == "$to_delete" ]]; then
      category="$target"
    fi

    printf '%s\t%s\t%s\t%s\n' "$category" "$level" "$command" "$detail" >>"$tmp"
  done <"$CMD_FILE"

  mv "$tmp" "$CMD_FILE"

  # Mettre à jour le fichier des catégories (supprimer to_delete)
  local tmp2
  tmp2="$(mktemp)"
  printf '# Liste des catégories pour cmdmemo\n' >"$tmp2"
  for c in "${OTHER_CATEGORIES[@]}"; do
    printf '%s\n' "$c"
  done | sort -u >>"$tmp2"
  mv "$tmp2" "$CAT_FILE"

  echo "Catégorie \"$to_delete\" supprimée. Commandes réaffectées à \"$target\"."
}

# --------------------------------------------------------------------
# Point d'entrée
# --------------------------------------------------------------------

main() {

  # --- Gestion du mode --no-color ---
  NO_COLOR=0
  if [[ "${1:-}" == "--no-color" ]]; then
    NO_COLOR=1
    shift
  fi

  # Couleurs ANSI (désactivées en mode --no-color)
  if (( NO_COLOR )); then
    C_RESET=""
    C_BOLD=""
    C_CAT=""
    C_USER=""
    C_ROOT=""
  else
    C_RESET="\e[0m"
    C_BOLD="\e[1m"
    C_CAT="\e[33m"
    C_USER="\e[36m"
    C_ROOT="\e[91m"
  fi

  # --- Lecture de la commande principale ---
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    categ|-c)    cmd_categ "$@";;
    list|-l)     cmd_list "$@";;
    search|-s)   cmd_search "$@";;
    add|-a)      cmd_add "$@";;
    delete|-d)   cmd_delete "$@";;
    edit|-e)     cmd_edit "$@";;
    addcateg|-A)       cmd_addcateg "$@";;
    renamecateg|-R)    cmd_renamecateg "$@";;
    deletecateg|-D)    cmd_deletecateg "$@";;
    help|-h|--help) usage;;
    *)
      echo "Commande inconnue : $cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"


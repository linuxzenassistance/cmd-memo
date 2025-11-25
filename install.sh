#!/usr/bin/env bash
#
# Installer for cmd-memo
# - Installs the script and data files into ~/.local/bin
# - Adds a convenient "cm" alias to ~/.bashrc (if not already present)
#

set -euo pipefail

APP_NAME="cmd-memo"
INSTALL_DIR="$HOME/.local/bin"

echo "=== Installing ${APP_NAME} ==="

# Determine source directory (where this install.sh lives)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Source directory : $SOURCE_DIR"
echo "Install directory: $INSTALL_DIR"
echo

echo "Creating install directory if needed..."
mkdir -p "$INSTALL_DIR"

echo "Installing main script..."
cp "$SOURCE_DIR/${APP_NAME}.sh" "$INSTALL_DIR/$APP_NAME"
chmod +x "$INSTALL_DIR/$APP_NAME"

# Install data files (but do not overwrite existing ones)
DATA_TSV="${INSTALL_DIR}/${APP_NAME}.tsv"
DATA_CATEG="${INSTALL_DIR}/${APP_NAME}.categ"

echo
echo "Installing data files..."

if [[ -f "$DATA_TSV" ]]; then
  echo " - Keeping existing ${APP_NAME}.tsv"
else
  echo " - Installing default ${APP_NAME}.tsv"
  cp "$SOURCE_DIR/${APP_NAME}.tsv" "$DATA_TSV"
fi

if [[ -f "$DATA_CATEG" ]]; then
  echo " - Keeping existing ${APP_NAME}.categ"
else
  echo " - Installing default ${APP_NAME}.categ"
  cp "$SOURCE_DIR/${APP_NAME}.categ" "$DATA_CATEG"
fi

echo

# Add alias to ~/.bashrc if not already present
BASHRC="$HOME/.bashrc"
ALIAS_LINE='alias cm="$HOME/.local/bin/cmd-memo"'

if [[ -f "$BASHRC" ]] && grep -q 'alias cm=' "$BASHRC"; then
  echo "Alias 'cm' already defined in ~/.bashrc (not modified)."
else
  echo "Adding 'cm' alias to ~/.bashrc..."
  {
    echo
    echo "# cmd-memo command memo manager"
    echo "$ALIAS_LINE"
  } >> "$BASHRC"
  echo "Alias added to ~/.bashrc"
fi

echo

# Check if INSTALL_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo "⚠️  Warning: $INSTALL_DIR is not in your PATH."
  echo "    You may want to add this line to your shell configuration:"
  echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo
fi

echo "Installation completed."
echo
echo "Next steps:"
echo "  1) Reload your shell configuration:"
echo "       source ~/.bashrc"
echo "  2) Use cmd-memo with:"
echo "       cm -c"
echo "       cm -s ssh"
echo "       cm -a"

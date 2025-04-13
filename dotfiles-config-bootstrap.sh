#!/bin/bash

# ====== Configuration ======
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$HOME/dotfiles_backup/$TIMESTAMP"
DOTFILES_DIR="$HOME/dotfiles"
STOWLIST="$DOTFILES_DIR/stowlist.txt"

# Config folders under ~/.config/ to manage
CONFIG_FOLDERS=(
  "alacritty"
  "feh"
  "fish"
  "FreeTube"
  "gtk-2.0"
  "gtk-3.0"
  "gtk-4.0"
  "kdeconnect"
  "kitty"
  "mpv"
  "nano"
  "neofetch"
  "nnn"
  "paru"
  "picom"
  "pipewire"
  "protonmail"
  "QCAD"
  "ranger"
  "smplayer"
  "sublime-text"
  "Thunar"
  "wikiman"
  "xfce4"
  "xfce4-dict"
)

# ====== Setup ======
mkdir -p "$BACKUP_DIR"
mkdir -p "$DOTFILES_DIR"
> "$STOWLIST"

echo "🔧 Starting dotfile migration for ~/.config folders..."

# ====== Process Each Folder ======
for folder in "${CONFIG_FOLDERS[@]}"; do
  SRC="$HOME/.config/$folder"
  DEST="$DOTFILES_DIR/$folder/.config/$folder"

  if [ -d "$SRC" ]; then
    echo "📦 Backing up $SRC to $BACKUP_DIR/.config/$folder"
    mkdir -p "$BACKUP_DIR/.config"
    mv "$SRC" "$BACKUP_DIR/.config/"

    echo "🛠️  Moving to $DEST"
    mkdir -p "$(dirname "$DEST")"
    mv "$BACKUP_DIR/.config/$folder" "$DEST"

    echo "✅ Adding $folder to stowlist"
    echo "$folder" >> "$STOWLIST"
  else
    echo "⚠️  Skipping $folder — not found"
  fi
done

# ====== Apply Stow Based on stowlist.txt ======
cd "$DOTFILES_DIR" || exit 1
echo "🔗 Stowing configs..."
while read -r module; do
  [ -z "$module" ] && continue
  echo "👉 stow $module"
  stow "$module"
done < "$STOWLIST"

echo "✅ All configs processed and stowed!"
echo "🗃️  Backup directory: $BACKUP_DIR"

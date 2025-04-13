#!/bin/bash

# === CONFIG ===
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_ROOT="$HOME/dotfiles_backup"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
LOGFILE="$DOTFILES_DIR/stow_targets.txt"
ZENITY=$(command -v zenity)
NOTIFY=$(command -v notify-send)

mkdir -p "$DOTFILES_DIR"
mkdir -p "$BACKUP_DIR"
touch "$LOGFILE"

# === FUNCTIONS ===
function info() {
  echo "$1"
  [[ $NOTIFY ]] && notify-send "Stowify" "$1"
}

function error() {
  echo "❌ $1"
  [[ $ZENITY ]] && $ZENITY --error --title="Stowify Error" --text="$1"
}

function confirm() {
  if [[ $ZENITY ]]; then
    $ZENITY --question --title="Stowify Undo" --text="$1"
    return $?
  else
    read -rp "$1 [y/N]: " confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]]
  fi
}

function restore() {
  LAST_BACKUP=$(ls -dt "$BACKUP_ROOT"/* 2>/dev/null | head -n 1)
  [[ -z "$LAST_BACKUP" ]] && error "No backups found!" && exit 1

  confirm "Restore from last backup: $LAST_BACKUP?" || exit 0
  echo "🗃️ Restoring from $LAST_BACKUP..."

  while IFS= read -r line; do
    MOD=$(echo "$line" | cut -d ' ' -f1)
    DEST=$(echo "$line" | cut -d '>' -f2 | sed 's/^[^ ]* -> //')
    [[ -d "$DEST/$MOD" ]] && {
      echo "🧹 Unstowing $MOD from $DEST"
      [[ "$DEST" == "$HOME" ]] && (cd "$DOTFILES_DIR" && stow -D "$MOD")
      [[ "$DEST" != "$HOME" ]] && (cd "$DOTFILES_DIR" && sudo stow -D -t "$DEST" "$MOD")
    }

    SRC="$LAST_BACKUP/$DEST/$MOD"
    [[ -e "$SRC" ]] && {
      echo "♻️ Restoring $SRC to $DEST"
      mkdir -p "$DEST"
      cp -a "$SRC" "$DEST"
    }
  done < "$LOGFILE"

  info "Restore complete!"
  exit 0
}

# === UNDO MODE ===
[[ "$1" == "--undo" ]] && restore

# === MAIN PROCESSING LOOP ===
[[ $# -lt 1 ]] && error "No files provided. Drag from Thunar or run via CLI." && exit 1

for SOURCE in "$@"; do
  [[ ! -e "$SOURCE" ]] && error "$SOURCE not found" && continue

  BASENAME=$(basename "$SOURCE")
  PARENTDIR=$(dirname "$SOURCE")
  MODULE_NAME="$BASENAME"
  MODULE_PATH="$DOTFILES_DIR/$MODULE_NAME"

  # Skip if already logged
  grep -q "^$MODULE_NAME -> $PARENTDIR" "$LOGFILE" && {
    echo "⏩ Skipping $MODULE_NAME (already stowed)"
    continue
  }

  # Path to backup and move
  BACKUP_PATH="$BACKUP_DIR/$PARENTDIR"
  TARGET_PATH="$MODULE_PATH/$PARENTDIR/$BASENAME"
  mkdir -p "$BACKUP_PATH" "$(dirname "$TARGET_PATH")"

  echo "📦 Backing up $SOURCE to $BACKUP_PATH/"
  cp -a "$SOURCE" "$BACKUP_PATH/"

  echo "🚚 Moving $SOURCE to $TARGET_PATH"
  mv "$SOURCE" "$TARGET_PATH"

  echo "🔗 Stowing $MODULE_NAME"
  if [[ "$PARENTDIR" == "$HOME"* ]]; then
    cd "$DOTFILES_DIR" && stow "$MODULE_NAME"
  else
    cd "$DOTFILES_DIR" && sudo stow -t "$PARENTDIR" "$MODULE_NAME"
  fi

  echo "$MODULE_NAME -> $PARENTDIR" >> "$LOGFILE"
  echo "✅ Stowed $MODULE_NAME to $PARENTDIR"
done

[[ $ZENITY ]] && $ZENITY --info --title="Stowify Done" --text="All selected items were stowified."
[[ $NOTIFY ]] && notify-send "Stowify" "All items processed."

exit 0

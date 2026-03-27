#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

confirm_overwrite() {
  local file=$1
  if [[ -f "$file" ]]; then
    read -p "  $file already exists. Overwrite? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
  fi
}

safe_copy() {
  local src=$1
  local dest=$2
  local label=$3
  if [[ -f "$dest" ]]; then
    if confirm_overwrite "$dest"; then
      cp "$src" "$dest"
      echo "  Overwrote $label"
    else
      echo "  Skipped $label"
      return
    fi
  else
    cp "$src" "$dest"
    echo "  Installed $label"
  fi
}

echo "==> Client account dotfiles installer"
echo ""

# Prompt for git identity
read -p "Git user name: " git_name
read -p "Git email: " git_email

echo ""
echo "==> Installing dotfiles for $(whoami)..."

# .zshrc
safe_copy "$DOTFILES_DIR/zshrc" ~/.zshrc ".zshrc"

# Ghostty
mkdir -p ~/.config/ghostty
safe_copy "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config "ghostty config"

# Starship
safe_copy "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml "starship.toml"

# SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh
safe_copy "$DOTFILES_DIR/ssh/config" ~/.ssh/config "ssh config"

# Generate SSH key if not present
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
  echo "  Generated SSH key"
else
  echo "  SSH key already exists, skipping"
fi

# Git config
if [[ -f ~/.gitconfig ]]; then
  if confirm_overwrite ~/.gitconfig; then
    sed -e "s/__NAME__/$git_name/" -e "s/__EMAIL__/$git_email/" \
      "$DOTFILES_DIR/gitconfig.template" > ~/.gitconfig
    echo "  Overwrote .gitconfig"
  else
    echo "  Skipped .gitconfig"
  fi
else
  sed -e "s/__NAME__/$git_name/" -e "s/__EMAIL__/$git_email/" \
    "$DOTFILES_DIR/gitconfig.template" > ~/.gitconfig
  echo "  Installed .gitconfig"
fi

# Lock down permissions
chmod 700 ~/.ssh
[[ -f ~/.ssh/id_ed25519 ]] && chmod 600 ~/.ssh/id_ed25519
[[ -f ~/.ssh/config ]] && chmod 600 ~/.ssh/config
chmod go-rwx ~/.config ~/.gitconfig

echo ""
echo "==> Done! Next steps:"
echo "  1. Restart Ghostty"
echo "  2. Run: gh auth login"
echo "  3. Run: gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\""
echo "  4. Run: aws configure    (if needed)"
echo "  5. Run: gcloud init      (if needed)"
echo "  6. Run: jira init        (if needed)"

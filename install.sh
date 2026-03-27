#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Client account dotfiles installer"
echo ""

# Prompt for git identity
read -p "Git user name: " git_name
read -p "Git email: " git_email

echo ""
echo "==> Installing dotfiles for $(whoami)..."

# .zshrc
cp "$DOTFILES_DIR/zshrc" ~/.zshrc
echo "  Installed .zshrc"

# Ghostty
mkdir -p ~/.config/ghostty
cp "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
echo "  Installed ghostty config"

# Starship
cp "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml
echo "  Installed starship.toml"

# SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp "$DOTFILES_DIR/ssh/config" ~/.ssh/config
chmod 600 ~/.ssh/config
echo "  Installed ssh config"

# Generate SSH key if not present
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
  echo "  Generated SSH key"
else
  echo "  SSH key already exists, skipping"
fi

# Git config
sed -e "s/__NAME__/$git_name/" -e "s/__EMAIL__/$git_email/" \
  "$DOTFILES_DIR/gitconfig.template" > ~/.gitconfig
echo "  Installed .gitconfig"

# Lock down permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config
chmod go-rwx ~/.config ~/.gitconfig

echo ""
echo "==> Done! Next steps:"
echo "  1. Restart Ghostty"
echo "  2. Run: gh auth login"
echo "  3. Run: gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\""
echo "  4. Run: aws configure    (if needed)"
echo "  5. Run: gcloud init      (if needed)"
echo "  6. Run: jira init        (if needed)"

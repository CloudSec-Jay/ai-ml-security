#!/usr/bin/env bash
# Lock sensitive dotfiles with chattr +i
# Run after editing — prevents any process from writing without explicit unlock

TARGETS=(
  "$HOME/.bashrc"
  "$HOME/.zshrc"
  "$HOME/.profile"
  "$HOME/.bash_profile"
  "$HOME/.bash_login"
  "$HOME/.ssh/authorized_keys"
  "$HOME/.aws/credentials"
  "$HOME/.aws/config"
)

for f in "${TARGETS[@]}"; do
  [ -f "$f" ] && sudo chattr +i "$f" && echo "locked: $f"
done

echo "done — run dotfile-unlock.sh to edit"

#!/usr/bin/env bash
# Unlock sensitive dotfiles — run before intentional edits, re-lock after

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
  [ -f "$f" ] && sudo chattr -i "$f" && echo "unlocked: $f"
done

echo "done — remember to run dotfile-lock.sh when finished"

#!/usr/bin/env bash
# PreToolUse hook — Read tool
# Blocks reads of sensitive files
# Exit 2 = block, exit 0 = allow
# OWASP LLM06, MITRE AML.T0057

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.path // ""')
RESOLVED=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

BLOCKED_PATHS=(
  "$HOME/.aws/credentials"
  "$HOME/.ssh/id_rsa"
  "$HOME/.ssh/id_ed25519"
  "$HOME/.ssh/id_ecdsa"
  "$HOME/.ssh/authorized_keys"
  "$HOME/.gnupg"
  "/etc/shadow"
  "/etc/sudoers"
)

for blocked in "${BLOCKED_PATHS[@]}"; do
  EXPANDED=$(eval echo "$blocked")
  if [[ "$RESOLVED" == "$EXPANDED"* ]]; then
    echo "BLOCKED: read of sensitive path: $RESOLVED" >&2
    exit 2
  fi
done

exit 0

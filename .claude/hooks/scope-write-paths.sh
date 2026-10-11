#!/usr/bin/env bash
# PreToolUse hook — Write tool
# Blocks writes outside project root and to sensitive paths
# Exit 2 = block, exit 0 = allow
# OWASP LLM08, MITRE AML.T0049

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // .path // ""')
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# If path couldn't be parsed (e.g. stdin empty in some contexts), allow
[[ -z "$FILE_PATH" ]] && exit 0

RESOLVED=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

if [[ "$RESOLVED" != "$PROJECT_ROOT"* ]]; then
  echo "BLOCKED: write path outside project root: $RESOLVED" >&2
  exit 2
fi

BLOCKED_PATHS=(
  "$HOME/.aws/credentials"
  "$HOME/.ssh"
  "/etc/"
  "$HOME/.bashrc"
  "$HOME/.zshrc"
  "$HOME/.profile"
)

for blocked in "${BLOCKED_PATHS[@]}"; do
  if [[ "$RESOLVED" == "$blocked"* ]]; then
    echo "BLOCKED: write to sensitive path: $RESOLVED" >&2
    exit 2
  fi
done

exit 0

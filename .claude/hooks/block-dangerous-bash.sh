#!/usr/bin/env bash
# PreToolUse hook — Bash tool
# Blocks high-risk shell patterns and redirects to sensitive paths
# Exit 2 = block, exit 0 = allow
# OWASP LLM08, MITRE AML.T0049

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // ""')

# High-risk command patterns
BLOCKED_PATTERNS=(
  "rm -rf"
  "chmod \+s"
  "sudo su"
  "curl.*\|.*bash"
  "wget.*\|.*bash"
  "/etc/passwd"
  "/etc/shadow"
  "base64.*curl"
  "nc -e"
  "mkfifo"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: command matches high-risk pattern: $pattern" >&2
    exit 2
  fi
done

# Sensitive paths — block any redirect (>, >>, tee) targeting these
SENSITIVE_PATHS=(
  ".bashrc"
  ".zshrc"
  ".profile"
  ".bash_profile"
  ".bash_login"
  ".ssh"
  ".aws/credentials"
  ".aws/config"
  "/etc/"
  "/usr/"
  "/bin/"
  "/sbin/"
)

for path in "${SENSITIVE_PATHS[@]}"; do
  if echo "$COMMAND" | grep -qF "$path"; then
    # Only block if a redirect or tee is also present
    if echo "$COMMAND" | grep -qE "(>>|[^>]>|\btee\b)"; then
      echo "BLOCKED: redirect to sensitive path: $path" >&2
      exit 2
    fi
  fi
done

exit 0

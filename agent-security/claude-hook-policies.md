# Claude Code — Hook Policies
# Intercepts high-risk tool calls before execution
# Place in .claude/settings.json under "hooks"
#
# OWASP LLM08 (Excessive Agency) | LLM01 (Prompt Injection)
# MITRE AML.T0049, AML.T0051
# STRIDE: Elevation of Privilege, Tampering

---

## What Hooks Do

Claude Code hooks fire on `PreToolUse` — before a tool executes. A hook can:
- **Block** the call (exit code 2 + message)
- **Warn** and continue (exit code 0 + stderr)
- **Log** silently (exit code 0, no output)

This is the primary control for LLM08 — the agent cannot exceed its scope if the hook blocks the call before it lands.

---

## Hook Configuration

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-bash.sh"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/scope-write-paths.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Hook: block-dangerous-bash.sh

Blocks shell patterns that have no legitimate use in a coding assistant context.

```bash
#!/usr/bin/env bash
# PreToolUse hook — Bash tool
# Reads tool input from stdin as JSON
# Exit 2 = block, exit 0 = allow

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // ""')

# Patterns that are never appropriate
BLOCKED_PATTERNS=(
  "rm -rf"
  "chmod \+s"        # setuid bit — privilege escalation
  "sudo su"
  "curl.*\|.*bash"   # curl pipe to shell — supply chain risk
  "wget.*\|.*bash"
  "/etc/passwd"
  "/etc/shadow"
  "base64.*curl"     # data exfil pattern
  "nc -e"            # reverse shell
  "mkfifo"           # named pipe — C2 pattern
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: command matches high-risk pattern: $pattern" >&2
    exit 2
  fi
done

exit 0
```

---

## Hook: scope-write-paths.sh

Blocks file writes outside the current project directory.

```bash
#!/usr/bin/env bash
# PreToolUse hook — Write tool
# Blocks writes outside project root

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.path // ""')
PROJECT_ROOT=$(pwd)

# Resolve absolute path
RESOLVED=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# Block writes outside project root
if [[ "$RESOLVED" != "$PROJECT_ROOT"* ]]; then
  echo "BLOCKED: write path outside project root: $RESOLVED" >&2
  exit 2
fi

# Block writes to sensitive files
BLOCKED_FILES=(
  "~/.aws/credentials"
  "~/.ssh"
  "/etc/"
  "~/.bashrc"
  "~/.zshrc"
)

for blocked in "${BLOCKED_FILES[@]}"; do
  EXPANDED=$(eval echo "$blocked")
  if [[ "$RESOLVED" == "$EXPANDED"* ]]; then
    echo "BLOCKED: write to sensitive path: $RESOLVED" >&2
    exit 2
  fi
done

exit 0
```

---

## Deployment

```bash
mkdir -p ~/.claude/hooks
cp block-dangerous-bash.sh ~/.claude/hooks/
cp scope-write-paths.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

---

## What This Does NOT Cover

- MCP server tool calls — scoped separately in `mcp-security/`
- Amazon Q — uses IAM controls, not hooks (see [`identity/ml-iam/amazon-q-iam.md`](../identity/ml-iam/amazon-q-iam.md))
- Model-level prompt injection — hooks fire on tool calls, not on model output

## Framework Mapping

| Control | OWASP LLM | MITRE ATLAS | STRIDE |
|---|---|---|---|
| Bash pattern blocking | LLM08 | AML.T0049 | Elevation of Privilege |
| Write path scoping | LLM08 | AML.T0049 | Tampering |
| Hook as approval gate | LLM01 | AML.T0051 | Tampering |

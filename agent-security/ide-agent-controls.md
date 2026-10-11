# IDE Agent Controls

Controls scoping what Claude Code and Amazon Q can do inside this repo. Three layers — hook-based, filesystem-based, and IAM-based.

**OWASP LLM08 (Excessive Agency) | LLM01 (Prompt Injection) | LLM06 (Sensitive Information Disclosure)**
**MITRE AML.T0049, AML.T0051, AML.T0057**

---

## Threat Model

An AI coding agent running in the IDE has access to:
- The filesystem (read, write, execute)
- Shell (arbitrary command execution)
- AWS credentials (via ambient IAM identity)
- MCP servers (tool calls with real side effects)

Without controls, a prompt injection, malicious repo file, or misbehaving suggestion can exfiltrate credentials, modify shell configs, or escalate privileges — all within the agent's normal execution context.

---

## Layer 1 — Claude Code Hooks (PreToolUse)

Hooks fire before a tool executes. Exit 2 blocks the call. A portable example is provided in `.claude/settings.example.json`.

### block-dangerous-bash.sh
**Tool:** `Bash` | **Blocks:** dangerous command patterns + redirects to sensitive paths

| Pattern | Threat | MITRE |
|---|---|---|
| `rm -rf` | Destructive deletion | AML.T0049 |
| `chmod +s` | Setuid privilege escalation | T1548 |
| `curl\|bash`, `wget\|bash` | Supply chain — remote code execution | T1195.002 |
| `/etc/shadow`, `/etc/passwd` | Credential access | T1003 |
| `base64.*curl` | Data exfiltration | AML.T0057 |
| `nc -e`, `mkfifo` | Reverse shell / C2 | T1059 |
| `>> .bashrc`, `>> .zshrc` | Shell config tampering | T1546.004 |
| `>> .aws/credentials` | Credential tampering | T1552 |
| `tee .ssh/authorized_keys` | Persistence via SSH | T1098.004 |

### block-sensitive-reads.sh
**Tool:** `Read` | **Blocks:** reads of credential and key files

| Path | Threat | MITRE |
|---|---|---|
| `~/.aws/credentials` | AWS credential theft | T1552.001 |
| `~/.ssh/id_*` | SSH private key theft | T1552.004 |
| `~/.ssh/authorized_keys` | Persistence enumeration | T1098.004 |
| `~/.gnupg` | GPG key theft | T1552 |
| `/etc/shadow` | Password hash theft | T1003.008 |
| `/etc/sudoers` | Privilege escalation recon | T1548.003 |

### scope-write-paths.sh
**Tool:** `Write` | **Blocks:** file writes outside project root and to sensitive paths

Prevents the Write tool from creating or modifying files outside `$PROJECT_ROOT`. Secondary block on `~/.aws`, `~/.ssh`, `/etc/`.

---

## Layer 2 — Filesystem Immutability (chattr)

Hooks can be bypassed via:
- `!` shell passthrough in Claude Code (direct, no hook system)
- User approval of a blocked command in the permission popup
- Any process outside Claude Code entirely

`chattr +i` enforces at the kernel level — no process, user, or agent can write to an immutable file without explicitly removing the attribute first (`sudo chattr -i`).

### dotfile-lock.sh / dotfile-unlock.sh

```bash
# Lock after editing dotfiles
./tools/dotfile-lock.sh

# Unlock before intentional edits
./tools/dotfile-unlock.sh
```

**Files protected:**

| File | Threat if modified |
|---|---|
| `~/.bashrc`, `~/.zshrc`, `~/.profile` | Persistence — code runs on every shell start |
| `~/.bash_profile`, `~/.bash_login` | Persistence — login shell execution |
| `~/.ssh/authorized_keys` | Backdoor SSH access |
| `~/.aws/credentials` | AWS credential replacement |
| `~/.aws/config` | AWS profile hijacking |

---

## Layer 3 — IAM Scoping (Amazon Q)

Amazon Q runs under your ambient IAM identity. Scoped via a read-only IAM role and permission boundary documented in [`identity/ml-iam/amazon-q-iam.md`](../identity/ml-iam/amazon-q-iam.md).

Key controls:
- Read-only role for IDE use — no write, no IAM mutation, no CloudTrail disable
- Permission boundary caps effective permissions even if role is broader
- Dedicated AWS profile `amazon-q-readonly` — do not use `AdministratorAccess` for Q sessions

---

## Known Limitations

| Gap | Why | Mitigation |
|---|---|---|
| `!` shell passthrough | Claude Code design — bypasses hook system entirely | `chattr +i` on sensitive files |
| User-approved commands | Explicit approval overrides hook block | Conscious decision required |
| Bash subshells | Complex nested commands may evade pattern matching | Defense in depth — chattr covers the rest |
| Amazon Q `!` equivalent | Q has no hook system at all | IAM scoping + chattr |

---

## Related

- [`.claude/settings.example.json`](../.claude/settings.example.json) — portable hook configuration example
- [`.claude/hooks/`](../.claude/hooks/) — hook scripts
- [`tools/dotfile-lock.sh`](../tools/dotfile-lock.sh) — filesystem immutability
- [`identity/ml-iam/amazon-q-iam.md`](../identity/ml-iam/amazon-q-iam.md) — Q IAM controls
- [`claude-hook-policies.md`](claude-hook-policies.md) — hook design rationale

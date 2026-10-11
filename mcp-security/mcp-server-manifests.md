# MCP Server Permission Manifests
#
# OWASP LLM07 (Insecure Plugin Design), LLM05 (Supply Chain)
# MITRE AML.T0054 (LLM Plugin Compromise), T1195.002
# STRIDE: Tampering, Elevation of Privilege

---

## Design Principle

One MCP server per context. Never combine filesystem ops and AWS ops in the same server — a compromised tool in one context cannot pivot to the other.

Every server manifest defines:
- Exact tools allowed (no wildcards)
- Path scope (read vs write, specific directories)
- Network access (allowlisted domains or none)
- Log requirement (every call logged)

---

## Server: filesystem-readonly

For agents that need to read project files only. No write, no shell, no network.

```json
{
  "mcpServers": {
    "filesystem-readonly": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/project"],
      "env": {},
      "scope": {
        "tools": ["read_file", "list_directory", "search_files"],
        "paths": {
          "read": ["/project/"],
          "write": []
        },
        "network": false
      },
      "audit": {
        "log_all_calls": true,
        "log_path": "~/.claude/logs/mcp-filesystem.log"
      }
    }
  }
}
```

**Use case:** Code review, documentation generation, read-only analysis.

---

## Server: filesystem-workspace

For agents that need to write within a scoped workspace. Write restricted to output directory only.

```json
{
  "mcpServers": {
    "filesystem-workspace": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/project/workspace"],
      "env": {},
      "scope": {
        "tools": ["read_file", "write_file", "list_directory"],
        "paths": {
          "read": ["/project/"],
          "write": ["/project/workspace/output/"]
        },
        "network": false
      },
      "audit": {
        "log_all_calls": true,
        "log_path": "~/.claude/logs/mcp-workspace.log"
      }
    }
  }
}
```

**Use case:** Code generation, file editing within project scope.

---

## Server: aws-readonly

For agents that need to query AWS resources. Read-only, specific services only.

```json
{
  "mcpServers": {
    "aws-readonly": {
      "command": "uvx",
      "args": ["awslabs.aws-mcp-servers"],
      "env": {
        "AWS_PROFILE": "cloudsec-readonly",
        "AWS_REGION": "us-east-1"
      },
      "scope": {
        "tools": [
          "ec2_describe_instances",
          "s3_list_buckets",
          "iam_list_roles",
          "cloudtrail_lookup_events"
        ],
        "network": {
          "allowed_domains": ["*.amazonaws.com"]
        }
      },
      "audit": {
        "log_all_calls": true,
        "log_path": "~/.claude/logs/mcp-aws.log"
      }
    }
  }
}
```

**Use case:** Infrastructure review, security analysis, read-only AWS queries.
**IAM:** Uses `cloudsec-readonly` profile — see [`identity/ml-iam/amazon-q-iam.md`](../identity/ml-iam/amazon-q-iam.md).

---

## Vetting Checklist (before adding any MCP server)

Run through this before adding any server to `.claude/settings.json`:

- [ ] Source code reviewed — no obfuscated logic, no unexpected outbound calls
- [ ] Maintainer verified — known org or individual with public identity
- [ ] Tools declared match tools needed — no extra tools accepted
- [ ] Version pinned — never `latest`, pin to specific version + SHA256
- [ ] Network access justified — if it needs network, which domains and why
- [ ] Separate from other servers — does not share context with higher-privilege servers

```bash
# Pin an npm MCP package to a specific version + verify integrity
npm pack @modelcontextprotocol/server-filesystem@0.6.2
sha256sum modelcontextprotocol-server-filesystem-0.6.2.tgz
# Compare against published hash on npmjs.com
```

---

## What NOT to Do

```json
// WRONG — wildcard path, combined contexts, no audit
{
  "mcpServers": {
    "everything": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-everything"]
    }
  }
}
```

- `server-everything` grants filesystem + network + shell in one server
- No path scoping — agent can read/write anywhere
- No audit logging — no trail of what was called

---

## Framework Mapping

| Control | OWASP LLM | MITRE | STRIDE |
|---|---|---|---|
| Tool allowlist per server | LLM07 | AML.T0054 | Elevation of Privilege |
| Path scoping | LLM08 | AML.T0049 | Tampering |
| One server per context | LLM07 | AML.T0054 | Tampering |
| Version pinning | LLM05 | T1195.002 | Tampering |
| Audit logging | LLM08 | AML.T0049 | Repudiation |

---

## Related

- [`agent-security/claude-hook-policies.md`](../agent-security/claude-hook-policies.md) — PreToolUse hooks that enforce these policies at runtime
- [`supply-chain/ai-supply-chain/mcp-package-vetting.md`](../supply-chain/ai-supply-chain/mcp-package-vetting.md) — supply chain vetting
- [`identity/ml-iam/amazon-q-iam.md`](../identity/ml-iam/amazon-q-iam.md) — IAM for Amazon Q

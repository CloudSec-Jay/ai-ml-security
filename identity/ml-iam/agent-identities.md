# IAM for AI Agents

**Framework:** LLM08 (Excessive Agency) / AML.T0049

## The Problem

An AI agent is a principal — it calls APIs, reads files, executes tools. Without scoped identity, it inherits ambient permissions from whatever environment it runs in. That means a compromised or misbehaving agent can do everything the host can do.

The fix is the same as for human IAM: zero trust, scoped to role, no standing access.

---

## Design Principles

1. **One identity per agent role** — inference agent, training agent, and data-access agent are separate identities
2. **Scope to task** — an inference agent gets `read` on model weights, nothing else
3. **No standing write access** — agents that need to write request elevated access via approval gate
4. **Every tool call logged** — agent identity + tool name + input + output

---

## AWS: Agent IAM Role Pattern

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::ml-models-bucket/inference/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

**What this does:** Inference agent can only `GetObject` from the `/inference/` prefix. Cannot list, write, delete. Cannot access any other bucket.

---

## LLM API Key Rotation

LLM API keys (OpenAI, Anthropic, etc.) are secrets, not IAM roles. Treat them the same way:

- Store in AWS Secrets Manager, not environment variables
- Rotate on a schedule (90 days max)
- One key per agent role — not a shared org key
- Log every API call that uses the key

```bash
# Retrieve at runtime, not at build time
aws secretsmanager get-secret-value \
  --secret-id ml-agent/anthropic-api-key \
  --query SecretString --output text
```

---

## Agent Roles Defined Here

| Agent Role | AWS Role ARN | Tools Allowed | Data Access |
|---|---|---|---|
| inference-agent | | s3:GetObject on models/ | model weights (read) |
| training-agent | | s3:GetObject + PutObject on training/ | training data |
| eval-agent | | s3:GetObject on eval-datasets/ | eval datasets (read) |

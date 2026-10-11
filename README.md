<div align="center">

# AI/ML Security Engineering

![OWASP LLM](https://img.shields.io/badge/OWASP-LLM_Top_10-000000?style=flat-square&logo=owasp&logoColor=white)
![MITRE ATLAS](https://img.shields.io/badge/MITRE-ATLAS-E4002B?style=flat-square)
![Zero Trust](https://img.shields.io/badge/Zero_Trust-Agent_Scoping-0078D4?style=flat-square)

Security engineering for AI agents, LLM applications, MCP integrations, model artifacts, and MLOps pipelines.

</div>

---

AI systems run on cloud infrastructure — you can't secure the application layer without understanding what's underneath. This section covers the attack surface that IAM, network controls, and detection rules don't reach: prompt injection, tool poisoning, model supply chain tampering, and agent over-privilege.

**Design principle:** Zero Trust through scoping, not denial. One service identity per agent. MCP tool permissions bound to path, action, and context. Every tool call logged with agent identity, input, and output.

---

## Structure

```
ai-ml-security/
├── agent-security/     MCP attack surface, tool poisoning, prompt injection, over-privilege
├── llm-attacks/        LLM Top 10 missions — prompt injection, insecure output, data exfil, DoS
├── mcp-security/       MCP server vetting, scoped tool permissions, supply chain for MCP packages
├── mlops-security/     ML pipeline integrity, training data poisoning, model serving security
├── identity/           Agent identities, Amazon Q IAM, and Kubernetes service accounts
├── supply-chain/       MCP package vetting and model-weight integrity
└── ai-red-team/        AI-specific offensive testing — model attacks, agent exploitation
```

---

## `agent-security/`

The agent is the trust boundary. Every artifact starts with: what does this agent do, what tools does it call, what can go wrong.

| Artifact | What It Covers |
|---|---|
| `threat-model.md` | STRIDE threat model across agent, tools, and trust boundaries |
| `ide-agent-controls.md` | Control boundaries for coding and IDE agents |
| `claude-hook-policies.md` | Hook-based enforcement patterns and limitations |

Framework mapping: OWASP LLM01 (Prompt Injection), LLM06 (Excessive Agency), MITRE ATLAS AML.T0051

---

## `llm-attacks/`

Every mission follows the format: attack input → model output → detection signal → defensive control. No theoretical attacks without a reproduction path.

| Mission | OWASP LLM | MITRE ATLAS |
|---|---|---|
| `prompt-injection-lab.md` | LLM01 | AML.T0051 |
| `indirect-injection/` | LLM01 | AML.T0051 |

---

## `mcp-security/`

MCP server = untrusted third-party code by default until vetted. Tool descriptions are the attack surface — read them like untrusted input.

| Artifact | What It Covers |
|---|---|
| `mcp-attack-surface.md` | Tool poisoning vectors, permission scope analysis, supply chain risk |

Framework mapping: OWASP LLM05 (Insecure Plugin Design), MITRE T1195.002

---

## `mlops-security/`

Every stage of the ML pipeline is a trust boundary. Data ingestion → training → evaluation → serving: each has its own attack surface.

| Artifact | What It Covers |
|---|---|
| `k8s/mlops-k8s-security.md` | Kubernetes workload isolation for ML pipelines, RBAC, network policy |

Framework mapping: OWASP LLM03 (Training Data Poisoning), MITRE ATLAS AML.T0010

---

## `ai-red-team/`

AI-specific offensive testing — model extraction, jailbreaks, agent exploitation. Every attack maps to OWASP LLM Top 10 + MITRE ATLAS with a reproduction path.

---

## Framework Coverage

| Control | OWASP LLM | MITRE ATLAS | STRIDE |
|---|---|---|---|
| Prompt injection defense | LLM01 | AML.T0051 | Tampering |
| Agent over-privilege | LLM06 | AML.T0054 | Elevation of Privilege |
| Tool poisoning | LLM05 | AML.T0051 | Tampering |
| Training data poisoning | LLM03 | AML.T0010 | Tampering |
| Model supply chain | LLM05 | AML.T0010 | Tampering |

---

## Related controls

- [`identity/ml-iam/`](identity/ml-iam/) — Service identities and scoped permissions for AI agents
- [`supply-chain/models/`](supply-chain/models/) — Model weight integrity and provenance
- [`supply-chain/ai-supply-chain/`](supply-chain/ai-supply-chain/) — MCP package vetting
- [Cloud Security Engineering detection library](https://github.com/CloudSec-Jay/cloud-security-engineer/tree/main/detection) — Wazuh rules and incident-response material

## Portfolio

This project is part of the [Cloud Operations Engineering portfolio](https://cloudsec-jay.github.io/cloud-ops-engineering/).

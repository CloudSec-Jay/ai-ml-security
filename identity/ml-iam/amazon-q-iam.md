# Amazon Q Developer — IAM Scoping
#
# OWASP LLM08 (Excessive Agency)
# MITRE AML.T0049, T1078.004
# STRIDE: Elevation of Privilege, Information Disclosure

---

## The Problem

Amazon Q Developer runs under your IAM identity. In the IDE, it inherits whatever credentials are active in your shell — if that's `AdministratorAccess`, Q can read, write, and delete anything in your account. A prompt injection or misbehaving suggestion that triggers an action does so with your full permissions.

Zero Trust mandate: scope Q's identity to exactly what its task requires.

---

## IAM Role: amazon-q-readonly

For IDE use — code review, security analysis, read-only AWS queries.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyServices",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:GetObject",
        "s3:ListBucket",
        "iam:Get*",
        "iam:List*",
        "cloudtrail:LookupEvents",
        "cloudtrail:GetTrailStatus",
        "guardduty:Get*",
        "guardduty:List*",
        "logs:DescribeLogGroups",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-east-2"]
        }
      }
    },
    {
      "Sid": "DenyAllWrite",
      "Effect": "Deny",
      "Action": [
        "iam:Create*",
        "iam:Delete*",
        "iam:Put*",
        "iam:Attach*",
        "iam:Detach*",
        "s3:DeleteObject",
        "s3:PutObject",
        "ec2:*",
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Permission Boundary: amazon-q-boundary

Attach as a permission boundary to any role Q assumes. Even if the role has broader permissions, the boundary caps what Q can actually do.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:Get*",
        "s3:List*",
        "iam:Get*",
        "iam:List*",
        "cloudtrail:LookupEvents",
        "guardduty:Get*",
        "guardduty:List*",
        "logs:Describe*",
        "logs:Get*",
        "logs:Filter*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyPrivilegeEscalation",
      "Effect": "Deny",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## AWS Profile Setup

Create a dedicated profile for Q in `~/.aws/config`:

```ini
[profile amazon-q-readonly]
sso_session = cloudsec
sso_account_id = <account-id>
sso_role_name = AmazonQReadOnly
region = us-east-1
```

Set it as the active profile when using Q in the IDE — do not use `AdministratorAccess` for day-to-day Q interactions.

---

## Amazon Q Business — Data Source Scoping

Q Business indexes data sources (S3, Confluence, SharePoint) and can surface content in responses. Every indexed source is a potential leak path.

**Before connecting a data source:**
- [ ] Does Q need access to this data to do its job?
- [ ] Does the data contain secrets, PII, or internal-only content?
- [ ] Is the IAM role for the connector scoped to read-only on that source only?
- [ ] Are there documents in this source that should never appear in Q responses?

**Connector IAM — minimum scope:**
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:ListBucket"],
  "Resource": [
    "arn:aws:s3:::approved-knowledge-base",
    "arn:aws:s3:::approved-knowledge-base/*"
  ]
}
```

Never connect: credential stores, secrets buckets, HR data, customer PII.

---

## Audit Trail

Every Q API call appears in CloudTrail under `qbusiness.amazonaws.com`. Key events to monitor:

| Event | What It Means | Detection |
|---|---|---|
| `qbusiness:ChatSync` | Q responded to a query | Log volume anomaly |
| `qbusiness:UpdateDataSource` | Data source config changed | Alert on any change |
| `qbusiness:CreatePlugin` | New plugin added | Alert — review before allowing |
| `sts:AssumeRole` by Q role | Q assumed a role | Alert if role is outside expected set |

Wazuh rule for Q API anomalies → [Cloud Security Engineering detection library](https://github.com/CloudSec-Jay/cloud-security-engineer/tree/main/detection/wazuh/rules) (building).

---

## Framework Mapping

| Control | OWASP LLM | MITRE | STRIDE |
|---|---|---|---|
| Read-only IAM role | LLM08 | AML.T0049, T1078.004 | Elevation of Privilege |
| Permission boundary | LLM08 | T1548.005 | Elevation of Privilege |
| Data source scoping | LLM06 | AML.T0057 | Information Disclosure |
| CloudTrail audit | LLM08 | T1078.004 | Repudiation |

---

## Related

- [`agent-identities.md`](agent-identities.md) — general agent IAM patterns
- [Cloud IAM permission boundaries](https://github.com/CloudSec-Jay/cloud-security-engineer/tree/main/identity/aws-iam/permission-boundaries) — developer boundary pattern
- [`agent-security/claude-hook-policies.md`](../../agent-security/claude-hook-policies.md) — Claude Code controls

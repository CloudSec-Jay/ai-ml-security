# Kubernetes Service Accounts for ML Workloads

Same least-privilege principle as AWS IAM — applied to K8s RBAC and workload identity.

---

## K8s Service Account Pattern

Each ML workload gets its own ServiceAccount. No workload uses the `default` service account.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: inference-agent
  namespace: ml-workloads
  annotations:
    # IRSA — bind to AWS IAM role for cross-cloud access
    eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/inference-agent-role
automountServiceAccountToken: false  # opt-in only
```

---

## RBAC — Scope to Namespace

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inference-agent-role
  namespace: ml-workloads
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]
    resourceNames: ["model-config"]  # specific resource, not wildcard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: inference-agent-binding
  namespace: ml-workloads
subjects:
  - kind: ServiceAccount
    name: inference-agent
    namespace: ml-workloads
roleRef:
  kind: Role
  name: inference-agent-role
  apiGroup: rbac.authorization.k8s.io
```

**Never use ClusterRole for ML workloads** — namespace scope only.

---

## SPIFFE Workload Identity (Cilium)

Cilium assigns a SPIFFE identity to each workload based on its ServiceAccount. This identity is used for mTLS between pods — no hardcoded certs.

```
spiffe://cluster.local/ns/ml-workloads/sa/inference-agent
```

Network policy can then be written against this identity rather than an IP address.

---

## Checklist

- [ ] Every ML pod has a dedicated ServiceAccount
- [ ] `automountServiceAccountToken: false` unless explicitly needed
- [ ] RBAC scoped to namespace, not cluster
- [ ] No wildcard verbs (`*`) or resources (`*`)
- [ ] IRSA annotation set if pod needs AWS access

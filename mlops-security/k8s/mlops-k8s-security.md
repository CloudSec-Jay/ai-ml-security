# MLOps Security on Kubernetes

Security controls specific to ML workloads running on K8s. General K8s security is in `infrastructure/container-security/kubernetes/`. This covers what's unique to ML pipelines.

---

## ML Workload Isolation

ML workloads need stronger isolation than typical web services because:
- Training jobs access sensitive training data
- Inference endpoints are externally exposed
- Model weights are valuable artifacts worth stealing

```yaml
# Dedicated namespace per workload type
namespaces:
  - ml-training      # training jobs — high data access, no egress to internet
  - ml-inference     # serving — limited ingress, no access to training data
  - ml-monitoring    # drift detection, metrics
```

Cilium network policy: training namespace cannot communicate with inference namespace. Both isolated from control plane.

---

## Pod Security (training jobs)

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop: ["ALL"]
```

Training jobs don't need root, write access to `/`, or any Linux capabilities.

---

## Secrets Management

Never mount LLM API keys or model registry credentials as environment variables.

```yaml
# Use external-secrets or AWS Secrets Manager CSI driver
volumes:
  - name: api-key
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: ml-agent-secrets
```

---

## Model Weight Storage

Model weights should not be baked into container images. Mount from object storage at runtime with integrity check before load.

```yaml
initContainers:
  - name: verify-model
    image: ghcr.io/cloudsec-jay/toolbox:latest
    command: ["sh", "-c", "sha256sum -c /config/model.sha256"]
    volumeMounts:
      - name: model-weights
        mountPath: /models
```

---

## What Goes Here

- Cilium network policies scoped to ML namespaces
- Pod security manifests for training/inference/monitoring workloads
- Model weight integrity init containers
- RBAC manifests (see also [`identity/ml-iam/k8s/`](../../identity/ml-iam/k8s/))

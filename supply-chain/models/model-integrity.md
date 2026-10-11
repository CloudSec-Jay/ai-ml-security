# Model Supply Chain Integrity

**Framework:** LLM05 (Supply Chain) / AML.T0010 / OWASP A08

## The Problem

A model weight file is a binary artifact. It can be swapped in transit, backdoored at source, or silently replaced in your artifact store. None of this shows up in application logs — the model still loads and runs inference.

---

## Controls

### 1. SHA256 Checksum Verification

Pin the expected hash at download time. Verify before loading. Fail loud if mismatch.

```python
import hashlib

def verify_model(path: str, expected_sha256: str) -> None:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    actual = h.hexdigest()
    if actual != expected_sha256:
        raise ValueError(f"Model integrity check FAILED\nExpected: {expected_sha256}\nActual:   {actual}")
    print(f"Model integrity verified: {path}")
```

### 2. Digest Pinning

Never pull a model by tag or name alone. Pin to a digest.

```python
# Bad
model = load_model("bert-base-uncased")

# Good
model = load_model("bert-base-uncased@sha256:abc123...")
```

### 3. Cosign Signing

Sign model artifacts the same way you sign container images.

```bash
# Sign
cosign sign --yes ghcr.io/org/model-artifact@sha256:<digest>

# Verify before load
cosign verify ghcr.io/org/model-artifact@sha256:<digest> \
  --certificate-identity <workflow-url> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

### 4. SBOM / ML-BOM

Generate a bill of materials for every model artifact — what it is, where it came from, when it was pulled, what version.

---

## What These Controls Don't Cover

- **Training data poisoning** — checksum validates the artifact, not the training pipeline that produced it
- **Backdoored model with valid signature** — a compromised signer or compromised training run still produces a valid signature

Next layer: training data provenance tracking (`mlops-security/`).

---

## Models Tracked Here

| Model | Source | SHA256 | Signed | Last Verified |
|---|---|---|---|---|
| | | | | |

# Demo: Supply-chain controls in pipeline and cluster

This repo uses separate controls for each use case:
- **Pipeline controls** (GitHub Actions) to generate and verify attestations.
- **Cluster controls** (Kyverno) to enforce attestation presence at admission time.

No image signing keys are managed directly in this repo. Validation is done with GitHub/Sigstore attestation flow as in the [GitHub doc](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-build-provenance-for-container-images).

## Pipeline workflows

The implementation is intentionally split into multiple workflows:

- `build-and-attest.yml`
  - builds + pushes image,
  - generates SLSA provenance attestation,
  - generates SPDX SBOM + SBOM attestation.
- `trivy-scan-attest.yml`
  - performs Trivy scan,
  - creates vulnerability predicate,
  - generates vulnerability attestation (`https://in-toto.io/attestation/vulns/v0.1`).
- `verify-attestations.yml`
  - pipeline policy gate that verifies all three predicate types with `gh attestation verify`.
- `cosign-attest-for-kyverno.yml`
  - generates Kyverno/Cosign-compatible OCI attestations (SLSA, SPDX SBOM, vulnerability report).

Trigger model:
1. Tag push (`v*`) triggers `build-and-attest.yml` and `trivy-scan-attest.yml` independently.
2. `verify-attestations.yml` runs after `trivy-scan-attest.yml` (`workflow_run`) and retries verification until all attestations are visible.

Each workflow can also be run manually from Actions with inputs.

## How to run

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or: **Actions** → “Build, push, and attest” (`build-and-attest.yml`) → **Run workflow**.

## Verify attestations

- **In GitHub:** Actions → select the run → **Attestations**.
- **With GitHub CLI:**

  ```bash
  docker login ghcr.io
  gh attestation verify oci://ghcr.io/YOUR_ORG/demo-supply-chain:v1.0.0 -R YOUR_ORG/demo-supply-chain
  ```

Replace `YOUR_ORG` and `demo-supply-chain` with your GitHub org/user and repo name.

To inspect the attestation (e.g. provenance predicate):

```bash
gh attestation verify oci://ghcr.io/YOUR_ORG/demo-supply-chain:v1.0.0 \
  -R YOUR_ORG/demo-supply-chain \
  --format json \
  --jq '.[].verificationResult.statement.predicate'
```

For SBOM (SPDX) attestation:

```bash
gh attestation verify oci://ghcr.io/YOUR_ORG/demo-supply-chain:v1.0.0 \
  -R YOUR_ORG/demo-supply-chain \
  --predicate-type https://spdx.dev/Document/v2.3 \
  --format json
```

For vulnerability scan attestation:

```bash
gh attestation verify oci://ghcr.io/YOUR_ORG/demo-supply-chain:v1.0.0 \
  -R YOUR_ORG/demo-supply-chain \
  --predicate-type https://in-toto.io/attestation/vulns/v0.1 \
  --format json
```

## Cluster enforcement with Kyverno

Policies are split by use case:

- `kyverno/verify-provenance-attestation.yaml`
- `kyverno/verify-sbom-attestation.yaml`
- `kyverno/verify-vuln-scan-attestation.yaml`

Each policy enforces one attestation type for `ghcr.io/YOUR_ORG/*` images:
- SLSA provenance (`https://slsa.dev/provenance/v1`)
- SPDX SBOM (`https://spdx.dev/Document/v2.3`)
- Vulnerability scan report (`https://in-toto.io/attestation/vulns/v0.1`)

For cluster admission, run `cosign-attest-for-kyverno.yml` for the target image digest so attestations are available in the OCI registry for Kyverno verification.

Apply them individually:

```bash
kubectl apply -f kyverno/verify-provenance-attestation.yaml
kubectl apply -f kyverno/verify-sbom-attestation.yaml
kubectl apply -f kyverno/verify-vuln-scan-attestation.yaml
```

Before applying in a different repo/org, replace `nirmata` in each policy with your GitHub org/user.

## Reference

- [Use artifact attestations (GitHub Docs)](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-build-provenance-for-container-images)

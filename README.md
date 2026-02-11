# Demo: GitHub Artifact Attestations (provenance + SBOM)

This repo builds a container image and adds **GitHub artifact attestations** only: build provenance and SBOM. No image signing (no Cosign). Validation is done with GitHub’s attestation flow as in the [GitHub doc](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-build-provenance-for-container-images).

## What this workflow does

1. Build and push the image to GHCR.
2. **Build provenance attestation** – where and how the image was built.
3. **SBOM** (Syft) + **SBOM attestation** – signed SBOM in GitHub’s system.

Attestations appear in the Actions run and can be verified with `gh attestation verify`.

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

## Reference

- [Use artifact attestations (GitHub Docs)](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-build-provenance-for-container-images)

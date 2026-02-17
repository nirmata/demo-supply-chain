#!/usr/bin/env bash
# Deploy only provenance + SBOM ImageValidatingPolicies (no vuln, no ClusterPolicy).
# Run from repo root after cluster is connected.
set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Deploying GitHub attestation policies (provenance + SBOM only)..."

# Remove ClusterPolicies so only ImageValidatingPolicies apply
kubectl delete clusterpolicy verify-provenance-attestation verify-sbom-attestation verify-vuln-scan-attestation 2>/dev/null || true

# Remove vuln ImageValidatingPolicy (we skip vulnerability scan)
kubectl delete imagevalidatingpolicy verify-github-vuln-scan 2>/dev/null || true

# Apply the two Luc-style ImageValidatingPolicies
kubectl apply -f "$REPO_ROOT/kyverno/imagepolicy-github-provenance.yaml"
kubectl apply -f "$REPO_ROOT/kyverno/imagepolicy-github-sbom.yaml"

echo "Done. Test with: kubectl run test-gh --image=ghcr.io/nirmata/demo-supply-chain:github-attestation --restart=Never -- /bin/sh -c 'sleep 30'"

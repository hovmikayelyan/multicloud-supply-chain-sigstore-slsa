#!/usr/bin/env bash
# Usage: scripts/verify.sh <image@sha256:digest> <owner/repo>
set -euo pipefail
img=$1; repo=$2
id="https://github.com/${repo}/.github/workflows/supply-chain.yml@refs/heads/main"
iss=https://token.actions.githubusercontent.com
cosign verify --certificate-identity "$id" --certificate-oidc-issuer "$iss" "$img"
cosign verify-attestation --type cyclonedx --certificate-identity "$id" --certificate-oidc-issuer "$iss" "$img" >/dev/null
cosign verify-attestation --type slsaprovenance1 --certificate-identity "$id" --certificate-oidc-issuer "$iss" "$img" >/dev/null
echo "OK: signature, SBOM and provenance verified for $img"

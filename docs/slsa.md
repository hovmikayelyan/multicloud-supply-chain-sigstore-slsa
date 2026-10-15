# How this meets SLSA Build Level 2 (and the path to Level 3)

| Requirement | How it is met |
|---|---|
| **Scripted build** | The whole build is `.github/workflows/supply-chain.yml`; no manual steps. |
| **Hosted build platform** | GitHub-hosted runners (ephemeral VMs), not a developer laptop. |
| **Provenance exists** | A SLSA v1 provenance predicate (repo, commit, ref, workflow path, run URL, builder id) is attested to the image digest with `cosign attest --type slsaprovenance1`. |
| **Authentic provenance** | The attestation is signed with a short-lived **Fulcio** certificate bound to the GitHub OIDC identity of the workflow (`…/supply-chain.yml@refs/heads/main`). Consumers verify identity + issuer, not a shared key. |
| **Non-repudiable / transparent** | Every signature and attestation is recorded in the **Rekor** transparency log (UUID in `evidence/rekor.txt`). |
| **Subject = digest** | Signing/attesting is done on `image@sha256:…`, never on a mutable tag. |
| **Verified at deploy** | Kyverno (EKS/GKE) and Binary Authorization (GKE) reject anything not signed by that identity. |

This is **Build L2**: the provenance is generated *inside* the build job, so a compromised build step could in
principle forge it.

## Getting to Level 3
1. Generate and sign provenance in an **isolated** reusable workflow (`slsa-framework/slsa-github-generator`
   `generator_container_slsa3.yml`) so user-defined build steps cannot reach the signing material.
2. Consumers verify with `slsa-verifier verify-image` (pins builder identity + source repo + tag/branch).
3. Pin all actions by commit SHA; protect `main` (required reviews, no force push) so the source is trustworthy.
4. Use hermetic/pinned base images (digest) and lock files for reproducibility of inputs.

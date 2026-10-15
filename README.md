# Multi-cloud verifiable supply chain

GitHub Actions builds one image, produces a CycloneDX SBOM, signs keyless with Cosign (GitHub OIDC -> Fulcio -> Rekor),
attests SBOM + SLSA provenance, pushes the **same digest** to Google Artifact Registry and AWS ECR, then verifies
signatures in both. Kubernetes admission policy rejects anything unsigned.

```
app/                                 sample app + Dockerfile
.github/workflows/supply-chain.yml   CI pipeline (build, SBOM, sign, attest, verify, evidence)
policy/                              Kyverno (GKE, EKS), Binary Authorization, demo pods
scripts/verify.sh                    consumer-side verification
docs/setup.md                        one-time OIDC/WIF + registry + cluster setup
docs/slsa.md                         how this meets SLSA L2 / path to L3
docs/qa.md                           supply-chain security Q&A
evidence/                            filled by CI artifact `evidence` (verify output, Rekor UUIDs)
```

## Usage
Prerequisites: a GCP project, an AWS account and a GitHub repo. To produce the evidence set:
1. Follow `docs/setup.md`, set the repo variables, push to `main`.
2. Download artifacts: `sbom` (SBOM file) and `evidence` (cosign verify outputs, `rekor.txt` with log index + search link;
   the Rekor UUID is in there).
3. Apply the Kyverno policy on a GKE and an EKS cluster, `kubectl apply -f policy/test-pods.yaml`, screenshot the
   denied unsigned pod and admitted signed pod.
4. Collect the workflow YAML, SBOM, cosign outputs, Rekor entry, policy screenshots and `docs/slsa.md` as the evidence set.

Placeholders to replace: `OWNER/REPO`, `MY_PROJECT`, `MY_REPO`, AWS account id. Pin actions to commit SHAs before production use.

## Credentials and secrets
No credentials are stored in this repo. GitHub authenticates to GCP (Workload Identity Federation) and AWS (IAM role) via OIDC,
and images are signed keylessly with Cosign, so there are no cloud keys or signing keys. The repository **variables** you set
(`GCP_WIF_PROVIDER`, `GCP_PUSH_SA`, `AWS_PUSH_ROLE_ARN`, registry/project names) are identifiers, not secrets.

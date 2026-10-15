# One-time cloud setup (OIDC trust, no static keys)

Replace `OWNER/REPO` with your GitHub repo.

## GCP – Workload Identity Federation + Artifact Registry
```bash
gcloud iam workload-identity-pools create github --location=global
gcloud iam workload-identity-pools providers create-oidc github-oidc --location=global \
  --workload-identity-pool=github --issuer-uri=https://token.actions.githubusercontent.com \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='OWNER/REPO'"
gcloud artifacts repositories create MY_REPO --repository-format=docker --location=europe-west1
gcloud iam service-accounts create gh-push
gcloud artifacts repositories add-iam-policy-binding MY_REPO --location=europe-west1 \
  --member=serviceAccount:gh-push@MY_PROJECT.iam.gserviceaccount.com --role=roles/artifactregistry.writer
gcloud iam service-accounts add-iam-policy-binding gh-push@MY_PROJECT.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/OWNER/REPO"
```
Repo variables: `GCP_WIF_PROVIDER` (`projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github-oidc`), `GCP_PUSH_SA`, `GCP_PROJECT`, `GAR_LOCATION`, `GAR_REPO`.

## AWS – OIDC role + ECR
```bash
aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
aws ecr create-repository --repository-name sample-app
```
Role trust policy (condition pins repo + branch):
```json
{"Effect":"Allow","Principal":{"Federated":"arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"},
 "Action":"sts:AssumeRoleWithWebIdentity",
 "Condition":{"StringEquals":{"token.actions.githubusercontent.com:aud":"sts.amazonaws.com"},
              "StringLike":{"token.actions.githubusercontent.com:sub":"repo:OWNER/REPO:ref:refs/heads/main"}}}
```
Attach `AmazonEC2ContainerRegistryPowerUser` scoped to the repo. Repo variables: `AWS_PUSH_ROLE_ARN`, `AWS_REGION`, `ECR_REPO`.

## Cluster enforcement
```bash
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f policy/kyverno-verify-images-gke.yaml   # on GKE (edit OWNER/REPO, registry path)
kubectl apply -f policy/kyverno-verify-images-eks.yaml   # on EKS
kubectl apply -f policy/test-pods.yaml                   # unsigned pod => admission denied
```
Optional GCP managed layer: `policy/gcp-binary-authorization.yaml`.
Note: Kyverno needs pull access to the registry (GKE: node SA with `artifactregistry.reader`; EKS: IRSA role with ECR read) to resolve digests and fetch signatures.

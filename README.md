# infra-registry-creds
Registry Credentials: Automatic Renewal of ImagePullSecrets in Kubernetes Namespaces.
Supports two registry providers. Enable either or both — a provider is active
only when all of its env vars are set.

# Requirements:
Service account - [template](k8s/service-account.yaml)

## AWS ECR
Environment variables:
 - REGION
 - ASSUME (optional — role ARN to assume)
 - IMAGE_PULL_SECRET_NAME
 - AWS_ACCESS_KEY
 - AWS_ACCESS_SECRET

## DHI (Docker Hardened Images / Docker Hub)
Environment variables:
 - DHI_USERNAME (Docker Hub username)
 - DHI_TOKEN (Docker Hub PAT / access token)
 - DHI_IMAGE_PULL_SECRET_NAME
 - DHI_REGISTRY (optional — defaults to https://dhi.io; must match the registry host of the images being pulled, e.g. dhi.io)

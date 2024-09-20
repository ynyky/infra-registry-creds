# infra-registry-creds
Registry Credentials: Automatic Renewal of ImagePullSecrets in Kubernetes Namespaces.
# Requirements:
Environment variables:
 - REGION
 - ASSUME
 - IMAGE_PULL_SECRET_NAME
 - AWS_ACCESS_KEY
 - AWS_ACCESS_SECRET

Service account - [template](k8s/service-account.yaml)

#!/bin/bash

# --- Configuration ---
# Set the default environment if none is provided
ENVIRONMENT=${1:-"kind"} # Default to 'kind' if no argument is given
ARGOCD_CHART_REPO="https://argoproj.github.io/argo-helm"
ARGOCD_CHART_NAME="argo-cd"
NAMESPACE="argocd"

# 1. Determine the Values File based on the Environment
case "$ENVIRONMENT" in
    "kind")
        VALUES_FILE="./infra/live/local/values-kind.yaml"
        # Kind cluster access typically requires a specific kubeconfig path/context
        KUBECONFIG_CONTEXT="kind-local-dev" 
        ;;
    "eks"|"dev"|"prod")
        # Assuming all EKS environments use the same base file for manual bootstrap
        VALUES_FILE="./infra/live/dev/values-dev.yaml" # Or dynamically check $2
        KUBECONFIG_CONTEXT="" # Use default context, or pass a specific one
        ;;
    *)
        echo "Error: Invalid environment specified: $ENVIRONMENT. Must be 'kind', 'eks', 'dev', or 'prod'."
        exit 1
        ;;
esac

# Check if the required values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file not found at $VALUES_FILE"
    exit 1
fi

echo "--- Bootstrapping ArgoCD for $ENVIRONMENT environment using $VALUES_FILE ---"

# 2. Check and Add Helm Repository (Idempotent)
helm repo add argo $ARGOCD_CHART_REPO --force-update

# 3. Create the Namespace if it doesn't exist
kubectl create namespace $NAMESPACE --context $KUBECONFIG_CONTEXT --dry-run=client -o yaml | kubectl apply -f -

# 4. Deploy ArgoCD using Helm and the environment-specific values file
helm upgrade --install $NAMESPACE $ARGOCD_CHART_NAME \
    --repo $ARGOCD_CHART_REPO \
    --namespace $NAMESPACE \
    -f $VALUES_FILE \
    --context $KUBECONFIG_CONTEXT \
    --wait 

# 5. Output Access Instructions
if [ "$ENVIRONMENT" == "kind" ]; then
    echo " "
    echo "--- ArgoCD Deployment Complete ---"
    echo "The ArgoCD server is running on a NodePort (usually 30080) on the Kind node."
    echo "Use 'kubectl get svc -n argocd' to find the exact port."
    echo "Access via: http://localhost:<NodePort>"
    echo "Initial password is the name of the 'argocd-server' pod."
fi
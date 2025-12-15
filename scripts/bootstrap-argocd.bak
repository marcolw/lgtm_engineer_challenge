#!/bin/bash
# Description: Installs ArgoCD via Helm and retrieves the initial login details.

# --- Configuration ---
ARGOCD_NAMESPACE="argocd"
ARGOCD_REPO="https://argoproj.github.io/argo-helm"
ARGOCD_CHART="argo-cd"
ARGOCD_VERSION="5.51.0" # Latest stable as of Dec 2025

echo "--- 🚀 Starting ArgoCD Bootstrap ---"

# 1. Add Helm Repository (Idempotent)
helm repo add argo $ARGOCD_REPO --force-update

# 2. Install/Upgrade ArgoCD
echo "Installing ArgoCD in namespace: $ARGOCD_NAMESPACE"
helm upgrade --install argocd $ARGOCD_CHART \
    --repo $ARGOCD_REPO \
    --namespace $ARGOCD_NAMESPACE \
    --version $ARGOCD_VERSION \
    --create-namespace \
    --set server.service.type=LoadBalancer \
    --wait

# 3. Get Initial Password
echo ""
echo "--- 🔑 ArgoCD Credentials ---"
# The secret usually takes a moment to be available
sleep 10
ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Initial Username: admin"
echo "Initial Password: $ARGOCD_PASSWORD"

# 4. Get LoadBalancer IP
echo ""
echo "--- 🔗 ArgoCD Access URL ---"
echo "Waiting for LoadBalancer to provision (can take 1-3 minutes)..."
ARGOCD_SERVER_ADDRESS=""
while [ -z $ARGOCD_SERVER_ADDRESS ]; do
    sleep 5
    # Check for both hostname (AWS) and IP (other clouds/minikube)
    ADDRESS=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$ADDRESS" ]; then
        ADDRESS=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    ARGOCD_SERVER_ADDRESS=$ADDRESS
done

echo "✅ ArgoCD is running."
echo "URL: https://$ARGOCD_SERVER_ADDRESS"
echo "--------------------------------------------------------"
#!/bin/bash

set -e

echo "=== Galaxy ArgoCD Dev Environment Setup ==="

# Wait for k3s to be ready
echo "Waiting for k3s to start..."
max_attempts=30
attempt=0
while ! command -v k3s &> /dev/null && [ $attempt -lt $max_attempts ]; do
  echo "Waiting for k3s... ($((attempt+1))/$max_attempts)"
  sleep 2
  attempt=$((attempt + 1))
done

# Start k3s if not already running
if ! systemctl is-active --quiet k3s; then
  echo "Starting k3s..."
  systemctl start k3s || service k3s start || /usr/local/bin/k3s server &
fi

# Wait for kubernetes to be ready
echo "Waiting for Kubernetes cluster to be ready..."
max_attempts=60
attempt=0
while ! kubectl cluster-info &> /dev/null && [ $attempt -lt $max_attempts ]; do
  echo "Waiting for cluster... ($((attempt+1))/$max_attempts)"
  sleep 2
  attempt=$((attempt + 1))
done

# Check if cluster is ready
kubectl wait --for=condition=ready node --all --timeout=300s || true

echo "Kubernetes cluster is ready!"

# Add ArgoCD Helm repository
echo "Adding ArgoCD Helm repository..."
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update

# Create argocd namespace
echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD..."
helm install argocd argocd/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer \
  --set server.insecure=true \
  --set server.service.servicePortHttps=443 \
  --wait \
  --timeout 10m

# Get ArgoCD password
echo "Waiting for ArgoCD deployment..."
sleep 10
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "=== ArgoCD Installation Complete ==="
echo "ArgoCD is available at: http://localhost:8080"
echo "Default admin username: admin"
echo "Default admin password: $ARGOCD_PASS"
echo ""

# Port forward ArgoCD to localhost:8080 in background
echo "Setting up port forwarding for ArgoCD..."
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# Display cluster info
echo "=== Kubernetes Cluster Info ==="
kubectl cluster-info
echo ""
kubectl get nodes

# Create argocd-apps namespace
echo ""
echo "Creating argocd-apps namespace..."
kubectl create namespace argocd-apps --dry-run=client -o yaml | kubectl apply -f -

# Wait for ArgoCD CRDs to be available
echo ""
echo "Waiting for ArgoCD CRDs to be fully initialized..."
max_attempts=60
attempt=0
while ! kubectl get crd applications.argoproj.io &> /dev/null && [ $attempt -lt $max_attempts ]; do
  echo "Waiting for Application CRD... ($((attempt+1))/$max_attempts)"
  sleep 2
  attempt=$((attempt + 1))
done

if kubectl get crd applications.argoproj.io &> /dev/null; then
  echo "ArgoCD CRDs are ready!"
else
  echo "Warning: ArgoCD CRDs not fully ready, proceeding anyway..."
fi

# Deploy clusterdos via ArgoCD
echo ""
echo "Deploying clusterdos via ArgoCD..."
sleep 5  # Give a bit more time for CRDs to settle
kubectl apply -f /workspace/clusterdos.yaml

# Deploy Galaxy as a separate ArgoCD Application
echo ""
echo "Deploying Galaxy via ArgoCD..."
sleep 5
kubectl apply -f /workspace/galaxy-app.yaml

echo ""
echo "=== Setup Complete ==="
echo "You can now manage applications using ArgoCD."
echo ""
echo "Deployed Applications:"
kubectl get applications -n argocd
echo ""
echo "To monitor deployments:"
echo "  kubectl get applications -n argocd -w"
echo "  argocd app get clusterdos"
echo "  argocd app get galaxy"
echo ""
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""

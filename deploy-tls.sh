#!/bin/bash
# Script to deploy TLS configuration
# Run this on a machine with kubectl configured and access to your Kubernetes cluster

set -e

echo "Deploying TLS configuration..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please configure kubeconfig."
    exit 1
fi

echo "✓ kubectl is configured"

# Apply ClusterIssuer (needs cluster admin permissions)
echo "Applying ClusterIssuer..."
kubectl apply -f cert-manager/cluster-issuer.yaml

# Apply Certificate
echo "Applying Certificate..."
kubectl apply -f cert-manager/frontend-certificate.yaml

# Update Ingress with TLS
echo "Updating Ingress with TLS configuration..."
kubectl apply -f ingress/frontend-ingress.yaml

echo ""
echo "✓ TLS configuration deployed!"
echo ""
echo "Waiting for certificate to be issued (this may take 1-2 minutes)..."
echo "You can check status with:"
echo "  kubectl get certificate -n taprav-fri"
echo "  kubectl describe certificate frontend-tls-cert -n taprav-fri"
echo ""
echo "Once ready, your site will be available at: https://devops-sk-07.lrk.si"

#!/bin/bash
# Install cert-manager in the Kubernetes cluster

set -e

echo "Checking if cert-manager is installed..."
echo ""

# Check if cert-manager namespace exists
if kubectl get namespace cert-manager &>/dev/null; then
    echo "✓ cert-manager namespace exists"
    kubectl get pods -n cert-manager
else
    echo "✗ cert-manager namespace not found"
    echo "Installing cert-manager..."
    echo ""
    
    # Install cert-manager using official method
    echo "Step 1: Installing cert-manager CRDs..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    
    echo ""
    echo "Step 2: Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s || true
    
    echo ""
    echo "✓ cert-manager installed!"
fi

echo ""
echo "Checking cert-manager pods:"
kubectl get pods -n cert-manager

echo ""
echo "Now you can deploy TLS resources:"
echo "  kubectl apply -f cert-manager/cluster-issuer.yaml"
echo "  kubectl apply -f cert-manager/frontend-certificate.yaml"

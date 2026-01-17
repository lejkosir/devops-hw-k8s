#!/bin/bash
# Deploy TLS using minikube's kubectl wrapper

set -e

echo "Deploying TLS configuration using minikube..."

# Check if minikube is available
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube is not installed"
    exit 1
fi

# Use minikube's kubectl wrapper (works even if minikube status fails)
KUBECTL="minikube kubectl --"

# Test connection
echo "Testing connection..."
if ! $KUBECTL get nodes &>/dev/null; then
    echo "Error: Cannot connect to minikube cluster"
    echo "Note: minikube kubectl -- should work even if 'minikube status' fails"
    exit 1
fi

echo "✓ Connected to minikube cluster"
echo ""

# Apply ClusterIssuer (needs cluster admin permissions)
echo "Applying ClusterIssuer..."
$KUBECTL apply -f cert-manager/cluster-issuer.yaml

# Apply Certificate
echo "Applying Certificate..."
$KUBECTL apply -f cert-manager/frontend-certificate.yaml

# Update Ingress with TLS
echo "Updating Ingress with TLS configuration..."
$KUBECTL apply -f ingress/frontend-ingress.yaml

echo ""
echo "✓ TLS configuration deployed!"
echo ""
echo "Waiting for certificate to be issued (this may take 1-2 minutes)..."
echo "You can check status with:"
echo "  minikube kubectl -- get certificate -n taprav-fri"
echo "  minikube kubectl -- describe certificate frontend-tls-cert -n taprav-fri"
echo ""
echo "Once ready, your site will be available at: https://devops-sk-07.lrk.si"

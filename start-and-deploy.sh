#!/bin/bash
# Start minikube and deploy TLS

set -e

echo "Starting minikube cluster..."

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube is not installed"
    exit 1
fi

# Check if minikube is already running
if minikube status &>/dev/null; then
    echo "✓ minikube is already running"
else
    echo "Starting minikube (this may take a few minutes)..."
    minikube start
    echo "✓ minikube started"
fi

# Wait a moment for cluster to be ready
echo "Waiting for cluster to be ready..."
sleep 5

# Test connection
echo "Testing connection..."
if ! minikube kubectl -- get nodes &>/dev/null; then
    echo "Error: Cannot connect to minikube cluster"
    exit 1
fi

echo "✓ Connected to minikube cluster"
echo ""

# Now deploy TLS
echo "Deploying TLS configuration..."
KUBECTL="minikube kubectl --"

# Apply ClusterIssuer
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
echo "Note: For minikube, you may need to enable the ingress addon:"
echo "  minikube addons enable ingress"
echo ""
echo "Once ready, your site will be available at: https://devops-sk-07.lrk.si"

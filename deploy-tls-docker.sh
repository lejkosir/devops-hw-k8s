#!/bin/bash
# Deploy TLS using kubectl through minikube Docker container

set -e

echo "Deploying TLS configuration via minikube container..."
echo ""

# Test connection first
echo "Testing connection..."
if ! sudo docker exec minikube kubectl get nodes &>/dev/null; then
    echo "Error: Cannot connect to cluster through minikube container"
    exit 1
fi

echo "✓ Connected to cluster"
echo ""

# Use kubectl through docker exec with stdin
KUBECTL="sudo docker exec -i minikube kubectl"

# Apply ClusterIssuer
echo "Applying ClusterIssuer..."
cat cert-manager/cluster-issuer.yaml | $KUBECTL apply -f -

# Apply Certificate
echo "Applying Certificate..."
cat cert-manager/frontend-certificate.yaml | $KUBECTL apply -f -

# Update Ingress with TLS
echo "Updating Ingress with TLS configuration..."
cat ingress/frontend-ingress.yaml | $KUBECTL apply -f -

echo ""
echo "✓ TLS configuration deployed!"
echo ""
echo "Waiting for certificate to be issued (this may take 1-2 minutes)..."
echo "You can check status with:"
echo "  sudo docker exec minikube kubectl get certificate -n taprav-fri"
echo "  sudo docker exec minikube kubectl describe certificate frontend-tls-cert -n taprav-fri"
echo ""
echo "Once ready, your site will be available at: https://devops-sk-07.lrk.si"

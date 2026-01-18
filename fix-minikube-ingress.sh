#!/bin/bash
# Fix minikube ingress to expose HTTPS

echo "Checking minikube ingress setup..."
echo ""

# Check if ingress addon is enabled
echo "=== Checking ingress addon ==="
if minikube addons list | grep -q "ingress.*enabled"; then
    echo "✓ Ingress addon is enabled"
else
    echo "✗ Ingress addon is not enabled"
    echo "Enabling ingress addon..."
    minikube addons enable ingress
    echo "✓ Ingress addon enabled"
fi

# Check ingress controller
echo ""
echo "=== Checking ingress controller pods ==="
kubectl get pods -n ingress-nginx

# Check ingress service
echo ""
echo "=== Checking ingress service ==="
kubectl get svc -n ingress-nginx

echo ""
echo "=== Important: Minikube Ingress Setup ==="
echo ""
echo "For minikube, you need to expose the ingress. Options:"
echo ""
echo "Option 1: Use minikube tunnel (recommended for HTTPS)"
echo "  # Run this in a separate terminal (keeps running):"
echo "  sudo minikube tunnel"
echo "  # This will expose ports 80 and 443"
echo ""
echo "Option 2: Use port forwarding (temporary)"
echo "  kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 443:443"
echo ""
echo "Option 3: Check if ingress is already exposed via LoadBalancer"
echo "  kubectl get svc -n ingress-nginx"
echo "  # If EXTERNAL-IP shows an IP (not <pending>), it's already exposed"
echo ""
echo "After setting up tunnel/port-forward, test:"
echo "  curl -I https://devops-sk-07.lrk.si"

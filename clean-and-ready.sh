#!/bin/bash
# Clean up auto-created certificate and apply fixed ingress

set -e

echo "Cleaning up auto-created certificate..."
echo ""

# Delete the auto-created certificate
kubectl delete certificate frontend-tls-secret -n taprav-fri 2>/dev/null || echo "No certificate to delete"

# Wait a moment
sleep 2

# Apply the fixed ingress (without cert-manager auto-annotation)
echo "Applying fixed ingress configuration..."
kubectl apply -f ingress/frontend-ingress.yaml

# Wait a moment for any auto-creation to happen
sleep 3

echo ""
echo "Checking status..."
kubectl get certificate -n taprav-fri
kubectl get secret -n taprav-fri | grep frontend || echo "No frontend-tls secrets found"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "The ingress no longer auto-creates certificates."
echo "You will control certificate creation explicitly via:"
echo "  kubectl apply -f cert-manager/frontend-certificate.yaml"

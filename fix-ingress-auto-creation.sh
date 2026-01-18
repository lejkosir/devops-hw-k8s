#!/bin/bash
# Fix ingress to prevent auto-certificate creation

set -e

echo "Preventing auto-certificate creation..."
echo ""

# Delete any auto-created certificate
echo "1. Deleting auto-created certificate..."
kubectl delete certificate frontend-tls-secret -n taprav-fri 2>/dev/null || echo "No certificate to delete"

sleep 2

# Apply ingress WITHOUT TLS section (prevents auto-creation)
echo "2. Applying ingress without TLS section..."
kubectl apply -f ingress/frontend-ingress-no-tls.yaml

sleep 2

# Verify no certificate is auto-created
echo ""
echo "3. Checking for auto-created certificates..."
CERT_COUNT=$(kubectl get certificate -n taprav-fri 2>/dev/null | grep -c "frontend-tls" || echo "0")
if [ "$CERT_COUNT" -eq 0 ]; then
    echo "   ✅ No auto-created certificates found"
else
    echo "   ⚠️  Certificate still exists:"
    kubectl get certificate -n taprav-fri
    echo "   Deleting again..."
    kubectl delete certificate -n taprav-fri --all
fi

echo ""
echo "✅ Fixed!"
echo ""
echo "Current state:"
echo "- Ingress is active (HTTP only)"
echo "- TLS section removed to prevent auto-certificate creation"
echo "- No certificates will be auto-created"
echo ""
echo "When ready to create certificate (after rate limit reset):"
echo "  1. kubectl apply -f cert-manager/frontend-certificate.yaml"
echo "  2. Once certificate is Ready, re-enable TLS in ingress:"
echo "     kubectl apply -f ingress/frontend-ingress.yaml"

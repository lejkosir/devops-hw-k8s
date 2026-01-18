#!/bin/bash
# Check what certificates and secrets actually exist

echo "=== Certificates in namespace ==="
kubectl get certificate -n taprav-fri

echo ""
echo "=== Secrets in namespace (filtered) ==="
kubectl get secret -n taprav-fri | grep -E "NAME|frontend-tls"

echo ""
echo "=== Detailed certificate check ==="
kubectl get certificate -n taprav-fri -o name 2>/dev/null | while read cert; do
    echo "Found: $cert"
done

echo ""
echo "=== Clean status ==="
CERT_COUNT=$(kubectl get certificate -n taprav-fri 2>/dev/null | grep -c "frontend-tls-cert" || echo "0")
SECRET_COUNT=$(kubectl get secret -n taprav-fri 2>/dev/null | grep -c "frontend-tls-secret" || echo "0")

echo "Certificates named 'frontend-tls-cert': $CERT_COUNT"
echo "Secrets named 'frontend-tls-secret': $SECRET_COUNT"

if [ "$CERT_COUNT" -eq 0 ] && [ "$SECRET_COUNT" -eq 0 ]; then
    echo ""
    echo "✅ No conflicting certificates or secrets - safe to proceed!"
else
    echo ""
    echo "⚠️  Still have resources to clean up"
fi

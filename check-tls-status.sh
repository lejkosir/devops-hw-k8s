#!/bin/bash
# Check TLS certificate status

echo "Checking TLS certificate status..."
echo ""

# Check certificate status
echo "=== Certificate Status ==="
kubectl get certificate -n taprav-fri

echo ""
echo "=== Certificate Details ==="
kubectl describe certificate frontend-tls-cert -n taprav-fri | grep -A 20 "Status:"

echo ""
echo "=== Certificate Request (if exists) ==="
kubectl get certificaterequest -n taprav-fri 2>/dev/null || echo "No certificate request yet"

echo ""
echo "=== Order Status (ACME) ==="
kubectl get order -n taprav-fri 2>/dev/null || echo "No order yet (may take a moment to create)"

echo ""
echo "=== Challenge Status (ACME) ==="
kubectl get challenge -n taprav-fri 2>/dev/null || echo "No challenge yet"

echo ""
echo "=== Ingress TLS Status ==="
kubectl get ingress frontend-ingress -n taprav-fri -o yaml | grep -A 5 "tls:"

echo ""
echo "=== Secret (where certificate is stored) ==="
kubectl get secret frontend-tls-secret -n taprav-fri 2>/dev/null && echo "✓ Secret exists!" || echo "⚠ Secret not created yet (certificate still being issued)"

echo ""
echo "=== Cert-manager Pods ==="
kubectl get pods -n cert-manager

echo ""
echo "Note: Certificate issuance may take 1-2 minutes. Check again with:"
echo "  kubectl describe certificate frontend-tls-cert -n taprav-fri"

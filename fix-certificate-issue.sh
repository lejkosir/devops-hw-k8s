#!/bin/bash
# Fix certificate issue - delete and recreate if needed

echo "Checking certificate issue..."
echo ""

# Check what's in the secret
echo "=== Secret Contents ==="
kubectl get secret frontend-tls-secret -n taprav-fri -o yaml | grep -E "tls.crt|tls.key" | head -2

# Check for other certificates using the same secret
echo ""
echo "=== Other Certificates ==="
kubectl get certificate -n taprav-fri -o wide

# Check certificate requests
echo ""
echo "=== Certificate Requests ==="
kubectl get certificaterequest -n taprav-fri

echo ""
echo "=== Solution Options ==="
echo ""
echo "Option 1: Delete and recreate the certificate (recommended)"
echo "  kubectl delete certificate frontend-tls-cert -n taprav-fri"
echo "  kubectl delete secret frontend-tls-secret -n taprav-fri"
echo "  kubectl apply -f cert-manager/frontend-certificate.yaml"
echo ""
echo "Option 2: Just delete the secret and let cert-manager recreate it"
echo "  kubectl delete secret frontend-tls-secret -n taprav-fri"
echo "  # cert-manager will automatically recreate it"
echo ""
echo "Option 3: Check if HTTPS actually works despite the status"
echo "  curl -I https://devops-sk-07.lrk.si"
echo "  # If it works, the status might just be a display issue"

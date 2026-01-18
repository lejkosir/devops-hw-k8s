#!/bin/bash
# Complete TLS deployment script

set -e

echo "=== Step 1: Ensuring ingress addon is enabled ==="
minikube addons enable ingress 2>/dev/null || echo "Ingress addon already enabled"
echo ""

echo "=== Step 2: Checking ingress controller ==="
kubectl get pods -n ingress-nginx | grep -q Running && echo "✓ Ingress controller is running" || echo "⚠ Ingress controller not ready"
echo ""

echo "=== Step 3: Cleaning up old certificate (if exists) ==="
kubectl delete certificate frontend-tls-cert -n taprav-fri 2>/dev/null || echo "No old certificate to delete"
kubectl delete secret frontend-tls-secret -n taprav-fri 2>/dev/null || echo "No old secret to delete"
sleep 2
echo ""

echo "=== Step 4: Applying production ClusterIssuer ==="
kubectl apply -f cert-manager/cluster-issuer.yaml
echo ""

echo "=== Step 5: Applying Certificate ==="
kubectl apply -f cert-manager/frontend-certificate.yaml
echo ""

echo "=== Step 6: Updating Ingress ==="
kubectl apply -f ingress/frontend-ingress.yaml
echo ""

echo "=== Step 7: Checking certificate status ==="
echo "Waiting 10 seconds for cert-manager to process..."
sleep 10
kubectl get certificate -n taprav-fri
echo ""

echo "=== IMPORTANT: Next Steps ==="
echo ""
echo "1. Check if minikube tunnel is running (for port 443 access):"
echo "   ps aux | grep 'minikube tunnel'"
echo ""
echo "2. If not running, start it in a SEPARATE terminal:"
echo "   sudo minikube tunnel"
echo "   (This must keep running for HTTPS to work)"
echo ""
echo "3. Check certificate status:"
echo "   kubectl get certificate -n taprav-fri"
echo "   kubectl describe certificate frontend-tls-cert -n taprav-fri"
echo ""
echo "4. Once certificate shows Ready: True, test HTTPS:"
echo "   curl -I https://devops-sk-07.lrk.si"
echo ""

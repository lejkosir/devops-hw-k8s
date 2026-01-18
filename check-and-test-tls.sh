#!/bin/bash
# Check ingress and TLS status

echo "=== Checking Ingress Controller ==="
kubectl get pods -n ingress-nginx
echo ""

echo "=== Checking Ingress Service ==="
kubectl get svc -n ingress-nginx
echo ""

echo "=== Certificate Status ==="
kubectl get certificate -n taprav-fri
echo ""

echo "=== Certificate Details ==="
kubectl describe certificate frontend-tls-cert -n taprav-fri | tail -20
echo ""

echo "=== Ingress Status ==="
kubectl get ingress frontend-ingress -n taprav-fri
echo ""

echo "=== Testing HTTP (should redirect to HTTPS) ==="
curl -I http://devops-sk-07.lrk.si 2>&1 | head -5
echo ""

echo "=== Testing HTTPS ==="
curl -I https://devops-sk-07.lrk.si 2>&1 | head -5
echo ""

echo "=== Important Notes ==="
echo ""
echo "1. If HTTPS connection fails, you need to run: sudo minikube tunnel"
echo "   (This must be running in a separate terminal)"
echo ""
echo "2. Check if tunnel is running:"
echo "   ps aux | grep 'minikube tunnel'"
echo ""
echo "3. If certificate shows 'Ready: False', check the reason:"
echo "   kubectl describe certificate frontend-tls-cert -n taprav-fri"

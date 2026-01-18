#!/bin/bash
# Alternative ways to expose HTTPS when minikube tunnel doesn't work

echo "Checking alternatives to expose HTTPS..."
echo ""

# Option 1: Check if ingress service already has external IP/ports
echo "=== Option 1: Check Ingress Service ==="
kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o wide
echo ""

# Option 2: Check NodePort mapping
echo "=== Option 2: Check NodePort ports ==="
NODEPORT_HTTPS=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].spec.ports[?(@.port==443)].nodePort}' 2>/dev/null || echo "")
if [ -n "$NODEPORT_HTTPS" ]; then
    echo "HTTPS NodePort: $NODEPORT_HTTPS"
    echo "You might be able to access via: https://devops-sk-07.lrk.si:$NODEPORT_HTTPS"
else
    echo "No HTTPS NodePort found"
fi
echo ""

# Option 3: Port forwarding (temporary)
echo "=== Option 3: Port Forwarding (temporary solution) ==="
echo "You can use port forwarding:"
echo "  kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 443:443"
echo "  (This runs in foreground - use separate terminal)"
echo ""

# Option 4: Check if service can be changed to LoadBalancer
echo "=== Option 4: Check service type ==="
SVC_TYPE=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].spec.type}' 2>/dev/null || echo "")
echo "Current service type: $SVC_TYPE"

if [ "$SVC_TYPE" = "NodePort" ]; then
    echo ""
    echo "Service is NodePort. For HTTPS to work:"
    echo "1. Check if port 443 is mapped to a NodePort"
    echo "2. Or try accessing via the NodePort number"
    echo "3. Or configure the service to use LoadBalancer (requires minikube tunnel or cloud LB)"
fi
echo ""

# Option 5: Check minikube profiles
echo "=== Option 5: Check minikube profiles ==="
if command -v minikube &>/dev/null; then
    minikube profile list 2>&1 | head -10
else
    echo "minikube command not available"
fi
echo ""

echo "=== Recommendation ==="
echo "Since minikube tunnel doesn't work, you have options:"
echo ""
echo "1. Port forwarding (for testing):"
echo "   kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 443:443"
echo ""
echo "2. Use NodePort if available (check port number above)"
echo ""
echo "3. Ask your partner how they're accessing the cluster"
echo "   (They might have a different way to expose ports)"

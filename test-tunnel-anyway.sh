#!/bin/bash
# Test if minikube tunnel works despite profile error

echo "=========================================="
echo "Testing Minikube Tunnel (Despite Errors)"
echo "=========================================="
echo ""

# Check current LoadBalancer status
echo "1. Current LoadBalancer status:"
echo "--------------------------------------------"
kubectl get svc -n ingress-nginx ingress-nginx-controller
echo ""

CURRENT_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "Current EXTERNAL-IP: $CURRENT_IP"
echo ""

# Start tunnel in background
echo "2. Starting minikube tunnel in background:"
echo "--------------------------------------------"
echo "Starting tunnel (will show error but might still work)..."
sudo nohup minikube tunnel > /tmp/minikube-tunnel-test.log 2>&1 &
TUNNEL_PID=$!

echo "Tunnel process started (PID: $TUNNEL_PID)"
echo ""

# Wait a bit
echo "3. Waiting 15 seconds for tunnel to establish..."
sleep 15

# Check if tunnel process is still running
if ps -p $TUNNEL_PID > /dev/null; then
    echo "✓ Tunnel process is still running"
else
    echo "✗ Tunnel process died (check logs)"
    echo "Last 20 lines of log:"
    tail -20 /tmp/minikube-tunnel-test.log
    echo ""
    exit 1
fi
echo ""

# Check LoadBalancer again
echo "4. Checking LoadBalancer status again:"
echo "--------------------------------------------"
kubectl get svc -n ingress-nginx ingress-nginx-controller
echo ""

NEW_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "New EXTERNAL-IP: $NEW_IP"
echo ""

# Compare
if [ "$CURRENT_IP" = "<pending>" ] && [ "$NEW_IP" != "<pending>" ] && [ -n "$NEW_IP" ]; then
    echo "=========================================="
    echo "✅ SUCCESS! Tunnel is working!"
    echo "=========================================="
    echo ""
    echo "The LoadBalancer got an external IP: $NEW_IP"
    echo "The profile error was cosmetic - tunnel works anyway!"
    echo ""
    echo "Keep the tunnel running:"
    echo "  ps aux | grep 'minikube tunnel'"
    echo ""
    echo "To stop it later:"
    echo "  sudo pkill -f 'minikube tunnel'"
    echo ""
elif [ "$NEW_IP" = "<pending>" ]; then
    echo "=========================================="
    echo "⚠ Tunnel didn't assign IP"
    echo "=========================================="
    echo ""
    echo "The tunnel process is running but LoadBalancer still pending."
    echo ""
    echo "Check tunnel logs:"
    echo "  tail -f /tmp/minikube-tunnel-test.log"
    echo ""
    echo "Options:"
    echo "1. Have your partner run minikube tunnel (they have the profile)"
    echo "2. Wait longer (sometimes takes 30-60 seconds)"
    echo "3. Use MetalLB instead"
    echo ""
    
    # Show tunnel logs
    echo "Tunnel log (last 20 lines):"
    tail -20 /tmp/minikube-tunnel-test.log
    echo ""
else
    echo "=========================================="
    echo "Status: IP unchanged"
    echo "=========================================="
    echo "Current IP: $CURRENT_IP"
    echo "New IP: $NEW_IP"
    echo ""
fi

echo ""

#!/bin/bash
# Script to try to make minikube tunnel work with existing cluster

echo "=========================================="
echo "Attempting to Use Minikube Tunnel"
echo "=========================================="
echo ""

# 1. Check if cluster is actually minikube
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ "$NODE_NAME" != "minikube" ]; then
    echo "⚠ Node name is '$NODE_NAME', not 'minikube'"
    echo "This might not be a minikube cluster"
else
    echo "✓ Node is named 'minikube' - this is a minikube cluster"
fi
echo ""

# 2. Check minikube config locations
echo "2. Checking minikube configuration..."
echo "--------------------------------------------"

# Check common minikube config locations
MINIKUBE_HOME="${MINIKUBE_HOME:-$HOME/.minikube}"
if [ -d "$MINIKUBE_HOME" ]; then
    echo "✓ Found minikube config in: $MINIKUBE_HOME"
    ls -la "$MINIKUBE_HOME" 2>/dev/null | head -10
else
    echo "✗ No minikube config in: $MINIKUBE_HOME"
fi

# Check root's minikube config
if [ -d "/root/.minikube" ]; then
    echo "✓ Found minikube config in: /root/.minikube"
    echo "  (This suggests cluster was started by root)"
fi
echo ""

# 3. Try to get cluster info from minikube
echo "3. Attempting to connect to existing cluster..."
echo "--------------------------------------------"

# Try minikube status with different approaches
if sudo minikube status &>/dev/null; then
    echo "✓ sudo minikube status works"
    sudo minikube status
elif minikube status &>/dev/null; then
    echo "✓ minikube status works (without sudo)"
    minikube status
else
    echo "⚠ minikube status doesn't work"
    echo "Trying to use existing kubeconfig..."
fi
echo ""

# 4. Check kubeconfig
echo "4. Checking kubeconfig..."
echo "--------------------------------------------"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
if [ -f "$KUBECONFIG_PATH" ]; then
    echo "✓ Kubeconfig found: $KUBECONFIG_PATH"
    # Check if it points to minikube
    if grep -q "minikube" "$KUBECONFIG_PATH" 2>/dev/null; then
        echo "✓ Kubeconfig references minikube"
    fi
else
    echo "⚠ Kubeconfig not found in expected location"
fi
echo ""

# 5. Try to use minikube with existing cluster
echo "5. Attempting to use minikube tunnel..."
echo "--------------------------------------------"

# Check if we can get cluster info
CLUSTER_IP=$(kubectl cluster-info 2>/dev/null | grep "control plane" | grep -oP 'https://\K[0-9.]+' || echo "")

if [ -n "$CLUSTER_IP" ]; then
    echo "✓ Cluster control plane IP: $CLUSTER_IP"
    echo ""
    echo "Since the cluster is running, try these approaches:"
    echo ""
    echo "Option 1: Try minikube tunnel without profile (might work):"
    echo "  sudo minikube tunnel"
    echo ""
    echo "Option 2: Try with explicit cluster connection:"
    echo "  sudo MINIKUBE_HOME=/root/.minikube minikube tunnel"
    echo ""
    echo "Option 3: If cluster was started by another user, try:"
    echo "  sudo -E minikube tunnel"
    echo ""
    echo "Option 4: Check if tunnel works even without profile:"
    echo "  sudo minikube tunnel --alsologtostderr"
    echo ""
else
    echo "⚠ Could not determine cluster IP"
fi

echo ""
echo "=========================================="
echo "Recommended Approach"
echo "=========================================="
echo ""
echo "Since your cluster IS running minikube, try this:"
echo ""
echo "1. Try minikube tunnel directly (it might work despite the error):"
echo "   sudo minikube tunnel"
echo ""
echo "2. Check if it actually assigns the IP (ignore the profile error):"
echo "   # In one terminal: sudo minikube tunnel"
echo "   # In another: watch kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
echo "3. If that doesn't work, the cluster might have been started by root:"
echo "   sudo MINIKUBE_HOME=/root/.minikube minikube tunnel"
echo ""
echo "4. If still not working, check tunnel logs:"
echo "   sudo minikube tunnel --alsologtostderr 2>&1 | tee /tmp/tunnel.log"
echo ""
echo "The tunnel might work even if it complains about the profile!"
echo ""

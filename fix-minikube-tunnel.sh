#!/bin/bash
# Script to diagnose and fix minikube tunnel issues

echo "=========================================="
echo "Minikube Tunnel Diagnostics"
echo "=========================================="
echo ""

# 1. Check if minikube is installed
echo "1. Checking minikube installation..."
if command -v minikube &> /dev/null; then
    echo "✓ minikube is installed"
    minikube version
else
    echo "✗ minikube is not installed"
    echo "This might not be a minikube cluster after all."
    exit 1
fi
echo ""

# 2. Check minikube profiles
echo "2. Checking minikube profiles..."
minikube profile list
echo ""

# 3. Check if any profile is running
echo "3. Checking if minikube is running..."
if minikube status &>/dev/null; then
    echo "✓ minikube is running"
    minikube status
else
    echo "⚠ minikube status check failed"
    echo "The cluster might be running but minikube command can't detect it"
fi
echo ""

# 4. Check cluster info
echo "4. Cluster information..."
kubectl cluster-info | head -3
echo ""

# 5. Check nodes
echo "5. Node information..."
kubectl get nodes -o wide
echo ""

# 6. Check if tunnel process is already running
echo "6. Checking for existing tunnel processes..."
if pgrep -f "minikube tunnel" > /dev/null; then
    echo "⚠ minikube tunnel is already running:"
    ps aux | grep "minikube tunnel" | grep -v grep
    echo ""
    echo "You might need to stop it first:"
    echo "  sudo pkill -f 'minikube tunnel'"
else
    echo "✓ No tunnel process found"
fi
echo ""

# 7. Recommendations
echo "=========================================="
echo "Recommendations"
echo "=========================================="
echo ""

# Check if it's actually minikube
NODE_PROVIDER=$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.minikube\.k8s\.io/name}' 2>/dev/null || echo "")

if [ -n "$NODE_PROVIDER" ]; then
    echo "This appears to be a minikube cluster (profile: $NODE_PROVIDER)"
    echo ""
    echo "Try starting tunnel with the profile:"
    echo "  sudo minikube tunnel -p $NODE_PROVIDER"
    echo ""
    echo "Or if no profile is needed:"
    echo "  sudo minikube tunnel"
else
    echo "⚠ This might not be a minikube cluster"
    echo ""
    echo "The cluster is running, but minikube commands don't work."
    echo "This could mean:"
    echo "1. It's a different Kubernetes setup (k3s, kubeadm, etc.)"
    echo "2. Minikube was used to create it but is no longer available"
    echo "3. The cluster is managed differently"
    echo ""
    echo "For LoadBalancer on non-minikube clusters:"
    echo "- Install MetalLB: https://metallb.universe.tf/installation/"
    echo "- Or use NodePort with external routing"
    echo "- Or contact your instructor about LoadBalancer support"
fi

echo ""

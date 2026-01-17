#!/bin/bash
# Script to try to set up kubectl access without partner's help

set -e

echo "Attempting to set up kubectl access..."
echo ""

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Try 1: Check for k3s (most common on university VMs)
echo "=== Trying k3s configuration ==="
if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
    echo "✓ Found k3s config!"
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    chmod 600 ~/.kube/config
    
    # Get server IP (might need to replace localhost)
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "Attempting to replace localhost with server IP: $SERVER_IP"
    sed -i "s/127.0.0.1/$SERVER_IP/g" ~/.kube/config 2>/dev/null || true
    sed -i "s/localhost/$SERVER_IP/g" ~/.kube/config 2>/dev/null || true
    
    echo "✓ k3s config copied! Testing..."
    if kubectl get nodes &>/dev/null; then
        echo "✓ SUCCESS! kubectl is working!"
        exit 0
    else
        echo "⚠ Config copied but connection failed. May need manual IP adjustment."
    fi
fi

# Try 2: Check for kubeadm
echo ""
echo "=== Trying kubeadm configuration ==="
if [ -f "/etc/kubernetes/admin.conf" ]; then
    echo "✓ Found kubeadm config!"
    sudo cp /etc/kubernetes/admin.conf ~/.kube/config
    chmod 600 ~/.kube/config
    
    echo "✓ kubeadm config copied! Testing..."
    if kubectl get nodes &>/dev/null; then
        echo "✓ SUCCESS! kubectl is working!"
        exit 0
    fi
fi

# Try 3: Check if kubectl can auto-discover (minikube, kind, etc.)
echo ""
echo "=== Trying auto-discovery ==="
if command -v minikube &>/dev/null; then
    echo "Found minikube, trying to use it..."
    minikube status &>/dev/null && minikube kubectl -- get nodes &>/dev/null && echo "✓ Minikube works!" && exit 0
fi

# Try 4: Check if there's a shared kubeconfig
echo ""
echo "=== Checking for shared kubeconfig ==="
SHARED_LOCATIONS=(
    "/shared/.kube/config"
    "/opt/kubeconfig"
    "/usr/local/share/kubeconfig"
)

for loc in "${SHARED_LOCATIONS[@]}"; do
    if [ -f "$loc" ]; then
        echo "✓ Found shared config at $loc"
        cp "$loc" ~/.kube/config
        chmod 600 ~/.kube/config
        if kubectl get nodes &>/dev/null; then
            echo "✓ SUCCESS! kubectl is working!"
            exit 0
        fi
    fi
done

# Try 5: Use sudo to read partner's config (if permissions allow)
echo ""
echo "=== Trying to access partner's config with sudo ==="
if sudo test -f /home/lkosir/.kube/config; then
    echo "✓ Can access partner's config with sudo!"
    sudo cp /home/lkosir/.kube/config ~/.kube/config
    # Try to set permissions, but continue even if it fails
    chmod 600 ~/.kube/config 2>/dev/null || sudo chmod 600 ~/.kube/config 2>/dev/null || echo "⚠ Could not change permissions, but continuing..."
    
    echo "Testing kubectl..."
    if kubectl get nodes &>/dev/null; then
        echo "✓ SUCCESS! kubectl is working!"
        exit 0
    else
        echo "⚠ Config copied but connection test failed. Trying with sudo kubectl..."
        if sudo kubectl get nodes &>/dev/null; then
            echo "✓ SUCCESS! Use 'sudo kubectl' for commands!"
            echo "You can create an alias: alias kubectl='sudo kubectl'"
            exit 0
        fi
    fi
fi

echo ""
echo "✗ Could not automatically set up kubectl."
echo ""
echo "Next steps:"
echo "1. Check if you have sudo access: sudo kubectl get nodes"
echo "2. Ask your partner to share kubeconfig"
echo "3. Check with your instructor for cluster access details"

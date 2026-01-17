#!/bin/bash
# Script to find kubeconfig files on the system

echo "Searching for kubeconfig files..."
echo ""

# Check partner's kubeconfig
echo "=== Checking partner's (lkosir) kubeconfig ==="
if [ -f "/home/lkosir/.kube/config" ]; then
    echo "✓ Found: /home/lkosir/.kube/config"
    ls -lh /home/lkosir/.kube/config
else
    echo "✗ Not found: /home/lkosir/.kube/config"
fi

# Check current user's kubeconfig
echo ""
echo "=== Checking your kubeconfig ==="
if [ -f "$HOME/.kube/config" ]; then
    echo "✓ Found: $HOME/.kube/config"
    ls -lh $HOME/.kube/config
else
    echo "✗ Not found: $HOME/.kube/config"
    echo "  Creating directory..."
    mkdir -p $HOME/.kube
fi

# Check root's kubeconfig
echo ""
echo "=== Checking root's kubeconfig ==="
if [ -f "/root/.kube/config" ]; then
    echo "✓ Found: /root/.kube/config"
    ls -lh /root/.kube/config
else
    echo "✗ Not found: /root/.kube/config"
fi

# Check common k3s location
echo ""
echo "=== Checking k3s kubeconfig ==="
if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
    echo "✓ Found: /etc/rancher/k3s/k3s.yaml (k3s cluster)"
    ls -lh /etc/rancher/k3s/k3s.yaml
else
    echo "✗ Not found: /etc/rancher/k3s/k3s.yaml"
fi

# Check kubeadm admin config
echo ""
echo "=== Checking kubeadm admin config ==="
if [ -f "/etc/kubernetes/admin.conf" ]; then
    echo "✓ Found: /etc/kubernetes/admin.conf (kubeadm cluster)"
    ls -lh /etc/kubernetes/admin.conf
else
    echo "✗ Not found: /etc/kubernetes/admin.conf"
fi

# Check environment variable
echo ""
echo "=== Checking KUBECONFIG environment variable ==="
if [ -n "$KUBECONFIG" ]; then
    echo "✓ KUBECONFIG is set to: $KUBECONFIG"
    if [ -f "$KUBECONFIG" ]; then
        ls -lh "$KUBECONFIG"
    else
        echo "  ⚠ Warning: File doesn't exist!"
    fi
else
    echo "✗ KUBECONFIG environment variable is not set"
fi

echo ""
echo "=== Summary ==="
echo "If kubeconfig was found, you can:"
echo "  1. Copy partner's config: cp /home/lkosir/.kube/config ~/.kube/config"
echo "  2. Or set KUBECONFIG: export KUBECONFIG=/home/lkosir/.kube/config"
echo "  3. For k3s: sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sed -i 's/127.0.0.1/your-server-ip/g' ~/.kube/config"

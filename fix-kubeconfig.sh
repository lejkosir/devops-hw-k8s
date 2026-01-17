#!/bin/bash
# Fix kubeconfig to work properly

echo "Fixing kubeconfig..."

# Check if config exists
if [ ! -f ~/.kube/config ]; then
    echo "✗ No kubeconfig found. Copying from partner..."
    sudo cp /home/lkosir/.kube/config ~/.kube/config
fi

# Check what server is configured
echo ""
echo "Current server in kubeconfig:"
grep -A 2 "server:" ~/.kube/config | head -3

# Get the actual server IP/hostname
echo ""
echo "Detecting server address..."
SERVER_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname -f)

echo "Server IP: $SERVER_IP"
echo "Hostname: $HOSTNAME"

# Check if config has localhost/127.0.0.1
if grep -q "127.0.0.1\|localhost" ~/.kube/config; then
    echo ""
    echo "⚠ Config has localhost. Attempting to fix..."
    
    # Try to replace with server IP
    cp ~/.kube/config ~/.kube/config.backup
    sed -i "s|https://127.0.0.1|https://$SERVER_IP|g" ~/.kube/config
    sed -i "s|https://localhost|https://$SERVER_IP|g" ~/.kube/config
    sed -i "s|http://127.0.0.1|https://$SERVER_IP|g" ~/.kube/config
    sed -i "s|http://localhost|https://$SERVER_IP|g" ~/.kube/config
    
    echo "✓ Updated config. Testing..."
else
    echo "✓ Config doesn't use localhost"
fi

# Set KUBECONFIG explicitly
export KUBECONFIG=~/.kube/config

# Test connection
echo ""
echo "Testing kubectl connection..."
if kubectl cluster-info &>/dev/null; then
    echo "✓ SUCCESS! kubectl is working!"
    kubectl get nodes
    exit 0
elif sudo kubectl cluster-info &>/dev/null; then
    echo "✓ SUCCESS with sudo! Use 'sudo kubectl' for commands"
    sudo kubectl get nodes
    exit 0
else
    echo "✗ Still not working. Let's check the config file..."
    echo ""
    echo "First few lines of kubeconfig:"
    head -20 ~/.kube/config
    echo ""
    echo "Try manually setting KUBECONFIG:"
    echo "  export KUBECONFIG=~/.kube/config"
    echo "  kubectl get nodes"
fi

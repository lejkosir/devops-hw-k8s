#!/bin/bash
# Check if kubectl is installed and where

echo "Checking for kubectl..."
echo ""

# Check in PATH
if command -v kubectl &>/dev/null; then
    echo "✓ kubectl found in PATH: $(which kubectl)"
    kubectl version --client 2>/dev/null || echo "  (version check failed)"
else
    echo "✗ kubectl not found in PATH"
fi

# Check common locations
echo ""
echo "Checking common locations:"
for loc in /usr/local/bin/kubectl /usr/bin/kubectl /opt/bin/kubectl ~/bin/kubectl; do
    if [ -f "$loc" ]; then
        echo "✓ Found: $loc"
    fi
done

# Check if minikube has kubectl
echo ""
echo "Checking minikube kubectl:"
if command -v minikube &>/dev/null; then
    MINIKUBE_PATH=$(which minikube)
    echo "minikube found at: $MINIKUBE_PATH"
    # Try to see if minikube kubectl works
    if minikube kubectl -- version --client &>/dev/null 2>&1; then
        echo "✓ minikube kubectl -- works!"
    else
        echo "✗ minikube kubectl -- doesn't work"
    fi
fi

# Check if we can download kubectl
echo ""
echo "If kubectl is not installed, you can install it:"
echo "  curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"
echo "  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"

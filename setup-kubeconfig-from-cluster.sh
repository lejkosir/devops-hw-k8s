#!/bin/bash
# Create kubeconfig using certificates from the running minikube cluster

set -e

echo "Setting up kubeconfig from running minikube cluster..."
echo ""

# API server address (from check-cluster.sh)
API_SERVER="https://192.168.49.2:8443"

# Create .kube directory
mkdir -p ~/.kube

# Get certificates from /var/lib/minikube/certs (accessible with sudo)
echo "Extracting certificates..."

# CA certificate
if [ -f "/var/lib/minikube/certs/ca.crt" ]; then
    sudo cp /var/lib/minikube/certs/ca.crt /tmp/ca.crt
    echo "✓ Got CA certificate"
else
    echo "✗ Cannot find CA certificate"
    exit 1
fi

# Client certificates (for admin user)
if [ -f "/var/lib/minikube/certs/client.crt" ] && [ -f "/var/lib/minikube/certs/client.key" ]; then
    sudo cp /var/lib/minikube/certs/client.crt /tmp/client.crt
    sudo cp /var/lib/minikube/certs/client.key /tmp/client.key
    sudo chmod 644 /tmp/client.crt
    sudo chmod 644 /tmp/client.key
    echo "✓ Got client certificates"
    USE_CLIENT_CERTS=true
else
    echo "⚠ Client certificates not found, will try without them"
    USE_CLIENT_CERTS=false
fi

# Create kubeconfig
echo "Creating kubeconfig..."

if [ "$USE_CLIENT_CERTS" = true ]; then
    # With client certificates
    cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(cat /tmp/ca.crt | base64 -w 0)
    server: $API_SERVER
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate-data: $(cat /tmp/client.crt | base64 -w 0)
    client-key-data: $(cat /tmp/client.key | base64 -w 0)
EOF
else
    # Without client certs - will need to use service account or token
    cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(cat /tmp/ca.crt | base64 -w 0)
    server: $API_SERVER
    insecure-skip-tls-verify: true
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    token: ""
EOF
fi

chmod 600 ~/.kube/config

echo "✓ kubeconfig created"
echo "Testing connection..."

# Try with regular kubectl
if kubectl get nodes &>/dev/null 2>&1; then
    echo "✓ SUCCESS! kubectl is working!"
    kubectl get nodes
    exit 0
fi

# Try with sudo kubectl
if sudo kubectl get nodes &>/dev/null 2>&1; then
    echo "✓ SUCCESS with sudo! Use 'sudo kubectl' for commands"
    sudo kubectl get nodes
    exit 0
fi

# If that doesn't work, try to find where kubectl is
echo "⚠ Direct connection didn't work. Checking for kubectl installation..."
if command -v kubectl &>/dev/null; then
    echo "kubectl found at: $(which kubectl)"
    kubectl version --client
else
    echo "kubectl not found in PATH"
    echo "Try: sudo apt-get install kubectl"
fi

echo ""
echo "If kubectl is installed, try:"
echo "  export KUBECONFIG=~/.kube/config"
echo "  kubectl get nodes"

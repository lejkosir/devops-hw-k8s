#!/bin/bash
# Create kubeconfig that points directly to the running minikube API server

set -e

echo "Creating kubeconfig for running minikube cluster..."
echo ""

# API server is at 192.168.49.2:8443 (from check-cluster.sh)
API_SERVER="https://192.168.49.2:8443"

# Try to get certificates from minikube container
echo "Extracting certificates from minikube container..."

# Create .kube directory
mkdir -p ~/.kube

# Try to get ca.crt from the minikube container
if sudo docker exec minikube cat /var/lib/minikube/certs/ca.crt > /tmp/ca.crt 2>/dev/null; then
    echo "✓ Got CA certificate from minikube container"
    CA_CERT="/tmp/ca.crt"
else
    echo "⚠ Could not get CA cert from container, trying alternative..."
    # Try to find it in /var/lib/minikube
    if [ -f "/var/lib/minikube/certs/ca.crt" ]; then
        sudo cp /var/lib/minikube/certs/ca.crt /tmp/ca.crt
        CA_CERT="/tmp/ca.crt"
        echo "✓ Got CA certificate from /var/lib/minikube"
    else
        echo "✗ Cannot find CA certificate"
        exit 1
    fi
fi

# Create kubeconfig
echo "Creating kubeconfig..."
cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(cat $CA_CERT | base64 -w 0)
    server: $API_SERVER
  name: minikube-direct
contexts:
- context:
    cluster: minikube-direct
    user: minikube-direct
  name: minikube-direct
current-context: minikube-direct
kind: Config
preferences: {}
users:
- name: minikube-direct
  user:
    client-certificate-data: $(sudo docker exec minikube cat /var/lib/minikube/certs/client.crt 2>/dev/null | base64 -w 0 || echo "")
    client-key-data: $(sudo docker exec minikube cat /var/lib/minikube/certs/client.key 2>/dev/null | base64 -w 0 || echo "")
EOF

# If client certs don't work, try using token
if ! kubectl get nodes &>/dev/null; then
    echo "Client certs didn't work, trying service account token..."
    
    # Try to get a token from the default service account
    TOKEN=$(sudo docker exec minikube cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null || echo "")
    
    if [ -z "$TOKEN" ]; then
        echo "Trying alternative: using kubectl through minikube container..."
        # Use kubectl from inside the container
        echo "You can use: sudo docker exec minikube kubectl <command>"
        exit 0
    fi
fi

chmod 600 ~/.kube/config

echo "✓ kubeconfig created"
echo "Testing connection..."

if kubectl get nodes &>/dev/null; then
    echo "✓ SUCCESS! kubectl is working!"
    kubectl get nodes
    exit 0
elif sudo kubectl get nodes &>/dev/null; then
    echo "✓ SUCCESS with sudo! Use 'sudo kubectl' for commands"
    sudo kubectl get nodes
    exit 0
else
    echo "⚠ Direct kubeconfig didn't work. Trying kubectl through container..."
    echo ""
    echo "You can use kubectl through the minikube container:"
    echo "  sudo docker exec minikube kubectl get nodes"
    echo "  sudo docker exec minikube kubectl apply -f cert-manager/cluster-issuer.yaml"
fi

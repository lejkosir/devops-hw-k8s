#!/bin/bash
# Fix minikube access by copying certificates or using sudo

set -e

echo "Fixing minikube kubectl access..."
echo ""

# Option 1: Try using sudo with minikube kubectl
echo "=== Trying sudo minikube kubectl ==="
if sudo minikube kubectl -- get nodes &>/dev/null; then
    echo "✓ SUCCESS! Use 'sudo minikube kubectl --' for commands"
    sudo minikube kubectl -- get nodes
    echo ""
    echo "You can now deploy TLS with:"
    echo "  sudo minikube kubectl -- apply -f cert-manager/cluster-issuer.yaml"
    echo "  sudo minikube kubectl -- apply -f cert-manager/frontend-certificate.yaml"
    echo "  sudo minikube kubectl -- apply -f ingress/frontend-ingress.yaml"
    exit 0
fi

# Option 2: Copy certificates to user's directory
echo "=== Copying minikube certificates ==="
if sudo test -d /home/lkosir/.minikube; then
    echo "Found partner's minikube directory, copying certificates..."
    
    # Create user's minikube directory
    mkdir -p ~/.minikube/profiles/minikube
    
    # Copy certificates with sudo
    sudo cp /home/lkosir/.minikube/ca.crt ~/.minikube/ca.crt
    sudo cp /home/lkosir/.minikube/profiles/minikube/client.crt ~/.minikube/profiles/minikube/client.crt
    sudo cp /home/lkosir/.minikube/profiles/minikube/client.key ~/.minikube/profiles/minikube/client.key
    
    # Fix permissions
    sudo chown -R $USER:$USER ~/.minikube
    chmod 600 ~/.minikube/ca.crt
    chmod 600 ~/.minikube/profiles/minikube/client.crt
    chmod 600 ~/.minikube/profiles/minikube/client.key
    
    echo "✓ Certificates copied"
    
    # Test
    if minikube kubectl -- get nodes &>/dev/null; then
        echo "✓ SUCCESS! minikube kubectl -- now works!"
        minikube kubectl -- get nodes
        exit 0
    else
        echo "⚠ Certificates copied but still not working"
    fi
fi

# Option 3: Create kubeconfig manually
echo ""
echo "=== Creating kubeconfig manually ==="
mkdir -p ~/.kube

# Try to get certificates from partner's directory with sudo
if sudo test -f /home/lkosir/.minikube/ca.crt; then
    sudo cp /home/lkosir/.minikube/ca.crt /tmp/ca.crt
    sudo cp /home/lkosir/.minikube/profiles/minikube/client.crt /tmp/client.crt
    sudo cp /home/lkosir/.minikube/profiles/minikube/client.key /tmp/client.key
    sudo chmod 644 /tmp/ca.crt /tmp/client.crt /tmp/client.key
    
    # Create kubeconfig
    cat > ~/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(cat /tmp/ca.crt | base64 -w 0)
    server: https://192.168.49.2:8443
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
    
    chmod 600 ~/.kube/config
    
    echo "✓ kubeconfig created"
    
    # Test
    if kubectl get nodes &>/dev/null; then
        echo "✓ SUCCESS! kubectl is working!"
        kubectl get nodes
        exit 0
    fi
fi

echo ""
echo "✗ Could not automatically fix access"
echo "Try manually:"
echo "  1. sudo minikube kubectl -- get nodes"
echo "  2. Or ask your partner to run the TLS deployment"

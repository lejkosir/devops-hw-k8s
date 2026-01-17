#!/bin/bash
# Check if cluster is already running and how to access it

echo "Checking cluster status..."
echo ""

# Check if minikube is running (even if we can't start it)
echo "=== Checking for running minikube ==="
if pgrep -f minikube > /dev/null; then
    echo "✓ Minikube process is running"
    ps aux | grep minikube | grep -v grep
else
    echo "✗ No minikube process found"
fi

# Check Docker containers (might show k8s components)
echo ""
echo "=== Checking Docker containers ==="
if sudo docker ps &>/dev/null; then
    echo "✓ Can access Docker with sudo"
    sudo docker ps | head -10
elif docker ps &>/dev/null; then
    echo "✓ Can access Docker"
    docker ps | head -10
else
    echo "✗ Cannot access Docker"
fi

# Check for k8s API server
echo ""
echo "=== Checking for Kubernetes API server ==="
if curl -k https://192.168.49.2:8443 &>/dev/null; then
    echo "✓ API server responding at 192.168.49.2:8443"
elif curl -k https://127.0.0.1:8443 &>/dev/null; then
    echo "✓ API server responding at 127.0.0.1:8443"
else
    echo "✗ Cannot reach API server"
fi

# Check if we can use partner's minikube
echo ""
echo "=== Checking partner's minikube setup ==="
if [ -d "/home/lkosir/.minikube" ]; then
    echo "✓ Partner has minikube directory"
    ls -la /home/lkosir/.minikube/ 2>/dev/null | head -5
fi

# Try to use partner's minikube context directly
echo ""
echo "=== Trying to use partner's minikube ==="
if [ -f "/home/lkosir/.minikube/profiles/minikube/config.json" ]; then
    echo "✓ Found partner's minikube config"
    echo "You might be able to use:"
    echo "  sudo minikube --profile=/home/lkosir/.minikube kubectl -- get nodes"
fi

echo ""
echo "=== Summary ==="
echo "If the cluster is running but you can't access it:"
echo "1. Ask your partner to run the TLS deployment commands"
echo "2. Or ask them to add you to the docker group: sudo usermod -aG docker $USER"
echo "3. Or ask them to share minikube access"

#!/bin/bash
# Script to install MetalLB LoadBalancer for Kubernetes
# Use this when minikube tunnel doesn't work

set -e

echo "=========================================="
echo "Installing MetalLB LoadBalancer"
echo "=========================================="
echo ""

# 1. Check if MetalLB is already installed
if kubectl get namespace metallb-system &>/dev/null; then
    echo "⚠ MetalLB namespace already exists"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping installation."
        exit 0
    fi
    echo "Removing existing MetalLB..."
    kubectl delete namespace metallb-system --ignore-not-found=true
    sleep 5
fi

# 2. Install MetalLB
echo "Installing MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

# 3. Wait for MetalLB to be ready
echo ""
echo "Waiting for MetalLB to be ready (this may take 1-2 minutes)..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=120s

if [ $? -eq 0 ]; then
    echo "✓ MetalLB is ready"
else
    echo "⚠ MetalLB installation may still be in progress"
    echo "Check status: kubectl get pods -n metallb-system"
fi

# 4. Get network information
echo ""
echo "=========================================="
echo "Network Configuration"
echo "=========================================="
echo ""

# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node Internal IP: $NODE_IP"

# Get cluster CIDR (if available)
CLUSTER_CIDR=$(kubectl cluster-info dump | grep -m 1 service-cluster-ip-range | cut -d'=' -f2 | cut -d'"' -f2 || echo "")
if [ -n "$CLUSTER_CIDR" ]; then
    echo "Cluster CIDR: $CLUSTER_CIDR"
fi

# 5. Configure IP pool
echo ""
echo "=========================================="
echo "IP Address Pool Configuration"
echo "=========================================="
echo ""
echo "MetalLB needs an IP address pool to assign to LoadBalancer services."
echo ""
echo "For the school VM, you typically need:"
echo "1. A range of IPs in your network (e.g., 192.168.49.100-192.168.49.200)"
echo "2. Or use the node's IP range"
echo ""
echo "Current node IP: $NODE_IP"
echo ""

# Try to auto-detect IP range
if [[ $NODE_IP =~ ^192\.168\. ]]; then
    BASE_IP=$(echo $NODE_IP | cut -d'.' -f1-3)
    SUGGESTED_START="${BASE_IP}.100"
    SUGGESTED_END="${BASE_IP}.200"
    echo "Suggested IP range: $SUGGESTED_START-$SUGGESTED_END"
    echo ""
    read -p "Use suggested range? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        IP_START=$SUGGESTED_START
        IP_END=$SUGGESTED_END
    else
        read -p "Enter start IP (e.g., 192.168.49.100): " IP_START
        read -p "Enter end IP (e.g., 192.168.49.200): " IP_END
    fi
else
    echo "Could not auto-detect IP range. Please enter manually:"
    read -p "Enter start IP (e.g., 192.168.49.100): " IP_START
    read -p "Enter end IP (e.g., 192.168.49.200): " IP_END
fi

# 6. Create IP pool configuration
echo ""
echo "Creating IP address pool: $IP_START-$IP_END"
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP_START-$IP_END
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF

if [ $? -eq 0 ]; then
    echo "✓ IP address pool configured"
else
    echo "❌ Failed to configure IP address pool"
    exit 1
fi

# 7. Verify MetalLB is working
echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="
echo ""

echo "MetalLB pods:"
kubectl get pods -n metallb-system

echo ""
echo "IP address pool:"
kubectl get ipaddresspool -n metallb-system

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Check if your LoadBalancer service gets an external IP:"
echo "   kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
echo "2. If external IP is still pending, wait 30 seconds and check again"
echo ""
echo "3. Once external IP is assigned, verify it's accessible:"
echo "   EXTERNAL_IP=\$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "   curl -I http://\$EXTERNAL_IP"
echo ""
echo "4. Continue with TLS certificate deployment:"
echo "   kubectl apply -f cert-manager/cluster-issuer.yaml"
echo "   kubectl apply -f cert-manager/frontend-certificate.yaml"
echo ""
echo "⚠ Note: Ensure your domain DNS points to the VM's public IP, not the MetalLB IP"
echo ""

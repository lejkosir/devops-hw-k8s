# TLS Setup on Minikube

**Your diagnostic shows you're running minikube.** On minikube, LoadBalancer services require `minikube tunnel` to work.

## Quick Setup

### Step 1: Start Minikube Tunnel

**This is REQUIRED for LoadBalancer to work on minikube!**

**First, check if minikube is actually running:**
```bash
# Run diagnostics
bash fix-minikube-tunnel.sh
```

**If minikube profile is not found, try:**
```bash
# Check what profiles exist
minikube profile list

# Check if minikube is running
minikube status

# Try starting minikube if it's not running
minikube start
```

**Then start tunnel:**
```bash
# Run this in a separate terminal (keep it running)
sudo minikube tunnel

# Or with a specific profile (if needed)
sudo minikube tunnel -p <profile-name>
```

**Or run in background:**
```bash
# Start tunnel in background
sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &

# Check if it's running
ps aux | grep "minikube tunnel"

# View logs if needed
tail -f /tmp/minikube-tunnel.log
```

**⚠ Keep this running!** If you stop `minikube tunnel`, the LoadBalancer external IP will go back to `<pending>`.

**If minikube tunnel doesn't work**, see "Alternative: MetalLB" section below.

### Step 2: Configure Service as LoadBalancer

```bash
# Change service type to LoadBalancer
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'
```

### Step 3: Wait for External IP

After starting `minikube tunnel`, wait 10-30 seconds, then check:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

You should see the `EXTERNAL-IP` change from `<pending>` to an IP address (usually `127.0.0.1` or a local IP like `10.96.x.x`).

**Example:**
```
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.97.157.106   127.0.0.1     80:31058/TCP,443:30339/TCP   4d1h
```

### Step 4: Get the External IP

```bash
# Get the external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Note:** On minikube, the external IP is usually `127.0.0.1` (localhost). This means:
- The service is accessible from the minikube VM itself
- For external access, you need to use the VM's public IP or configure port forwarding
- DNS should point to the VM's public IP, not the LoadBalancer IP

### Step 5: Verify Port 80 is Accessible

```bash
# Test from the VM
curl -I http://devops-sk-07.lrk.si

# Or test using the LoadBalancer IP directly
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -I http://$EXTERNAL_IP
```

### Step 6: Deploy TLS Certificate

```bash
# Apply ClusterIssuer
kubectl apply -f cert-manager/cluster-issuer.yaml

# Deploy certificate
kubectl apply -f cert-manager/frontend-certificate.yaml

# Monitor certificate
kubectl get certificate -n taprav-fri -w
```

## Important Notes for Minikube

1. **`minikube tunnel` must stay running** - If you stop it, the LoadBalancer IP will go back to `<pending>`

2. **External IP is usually localhost** - The LoadBalancer IP on minikube is typically `127.0.0.1`, which means:
   - It's accessible from the minikube VM itself
   - For external access, DNS should point to the **VM's public IP**, not the LoadBalancer IP
   - The ingress controller will still handle traffic correctly

3. **Port forwarding** - If you need to access from outside the VM, you might need to configure port forwarding or use the VM's public IP

4. **DNS configuration** - Ensure `devops-sk-07.lrk.si` points to the **VM's public IP**, not the LoadBalancer IP

## Alternative: MetalLB (if minikube tunnel doesn't work)

If `minikube tunnel` doesn't work (profile not found, etc.), you can use MetalLB instead:

### Install MetalLB

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### Configure MetalLB IP Pool

You need to configure an IP address pool. For the school VM, you'll need to know the IP range:

```bash
# Create IP pool (replace with your VM's IP range)
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.49.100-192.168.49.200  # Adjust to your network range
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
```

**Note:** Contact your instructor for the correct IP range to use.

After MetalLB is configured, the LoadBalancer should get an external IP automatically.

## Troubleshooting

### Minikube profile not found

```bash
# Run diagnostics
bash fix-minikube-tunnel.sh

# Check if minikube is actually running the cluster
minikube status

# If not, start minikube
minikube start
```

### LoadBalancer still pending after starting tunnel

```bash
# Check if tunnel is running
ps aux | grep "minikube tunnel"

# Check tunnel logs
tail -f /tmp/minikube-tunnel.log

# Restart tunnel
sudo pkill -f "minikube tunnel"
sudo minikube tunnel
```

### Certificate HTTP-01 challenge fails

**Check if port 80 is accessible:**
```bash
# From the VM
curl -I http://devops-sk-07.lrk.si

# Check if DNS resolves correctly
nslookup devops-sk-07.lrk.si

# Verify DNS points to VM's public IP (not LoadBalancer IP)
```

**Common issues:**
- DNS points to wrong IP (should be VM's public IP, not LoadBalancer IP)
- Port 80 is blocked by firewall
- `minikube tunnel` is not running

### Service works but certificate doesn't issue

```bash
# Check certificate status
kubectl describe certificate frontend-tls-cert -n taprav-fri

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

## Complete Minikube TLS Setup Script

```bash
#!/bin/bash
# Complete TLS setup for minikube

set -e

echo "=========================================="
echo "Minikube TLS Setup"
echo "=========================================="
echo ""

# 1. Check if minikube tunnel is running
if ! pgrep -f "minikube tunnel" > /dev/null; then
    echo "⚠ minikube tunnel is not running"
    echo "Starting minikube tunnel in background..."
    sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
    sleep 5
    echo "✓ minikube tunnel started"
else
    echo "✓ minikube tunnel is already running"
fi

# 2. Configure LoadBalancer
echo ""
echo "Configuring LoadBalancer..."
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# 3. Wait for external IP
echo ""
echo "Waiting for external IP..."
sleep 10

EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "<pending>" ]; then
    echo "⚠ External IP still pending. Check minikube tunnel:"
    echo "  ps aux | grep 'minikube tunnel'"
    echo "  tail -f /tmp/minikube-tunnel.log"
    exit 1
else
    echo "✓ External IP assigned: $EXTERNAL_IP"
fi

# 4. Deploy TLS
echo ""
echo "Deploying TLS certificate..."
kubectl apply -f cert-manager/cluster-issuer.yaml
kubectl apply -f cert-manager/frontend-certificate.yaml

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Monitor certificate:"
echo "  kubectl get certificate -n taprav-fri -w"
echo ""
echo "⚠ Keep minikube tunnel running!"
echo "  Check: ps aux | grep 'minikube tunnel'"
echo ""
```

Save as `setup-minikube-tls.sh` and run:
```bash
chmod +x setup-minikube-tls.sh
./setup-minikube-tls.sh
```

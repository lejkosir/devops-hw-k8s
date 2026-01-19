# School VM Deployment Guide

This guide provides step-by-step instructions for deploying the Kubernetes application stack on the school VM.

## Prerequisites Check

Before starting, verify you have access to the school VM and Kubernetes cluster:

```bash
# Check kubectl access
kubectl get nodes

# Check if ingress-nginx is installed
kubectl get namespace ingress-nginx

# Check if cert-manager is installed
kubectl get namespace cert-manager
```

If ingress-nginx or cert-manager are not installed, contact your instructor or system administrator.

---

## Quick Deployment Steps

### 1. Clone Repository (if not already done)

```bash
cd ~
git clone <your-repo-url>
cd DN03-kubernetes
```

### 2. Create Namespace

```bash
kubectl apply -f namespace/namespace.yaml
```

### 3. Create MySQL Secret

```bash
bash secrets/create-secret.sh
```

Or manually:
```bash
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='skrito123' \
  --from-literal=mysql-user='user' \
  --from-literal=mysql-password='skrito123' \
  --from-literal=mysql-database='taprav-fri'
```

### 4. Deploy Infrastructure Components

```bash
# ConfigMaps
kubectl apply -f configmaps/mysql-initdb.yaml

# PersistentVolumes
kubectl apply -f volumes/mysql-pvc.yaml

# Services
kubectl apply -f services/mysql-service.yaml
kubectl apply -f services/redis-service.yaml
kubectl apply -f services/backend-service.yaml
kubectl apply -f services/frontend-service.yaml
```

### 5. Deploy Applications

```bash
# Deploy infrastructure services first
kubectl apply -f deployments/redis-deployment.yaml
kubectl apply -f deployments/mysql-deployment.yaml

# Wait for MySQL to be ready (important!)
kubectl wait --for=condition=ready pod -l app=mysql -n taprav-fri --timeout=300s

# Deploy application services
kubectl apply -f deployments/backend-deployment.yaml
kubectl apply -f deployments/frontend-deployment.yaml  # Blue deployment
kubectl apply -f deployments/frontend-green-deployment.yaml  # Green deployment
```

### 6. Configure Ingress Controller as LoadBalancer

**On the school VM, the LoadBalancer should provision automatically:**

```bash
# Use the helper script
bash setup-loadbalancer.sh

# Or manually:
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# Wait for external IP (watch the service)
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

**Note:** On the school VM, the LoadBalancer should automatically get an external IP. If it shows `<pending>`, wait 1-5 minutes for provisioning.

### 7. Verify LoadBalancer External IP

```bash
# Get the external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# The EXTERNAL-IP column should show an IP address (not <pending>)
# Example output:
# NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
# ingress-nginx-controller   LoadBalancer   10.96.xxx.xxx   192.168.xxx.xxx   80:xxxxx/TCP,443:xxxxx/TCP   5m
```

**Important:** Ensure your domain `devops-sk-07.lrk.si` DNS points to this external IP. If DNS is not configured, contact your instructor.

### 8. Deploy Ingress Resource

```bash
kubectl apply -f ingress/frontend-ingress.yaml
```

### 9. Configure TLS (cert-manager)

```bash
# Apply ClusterIssuer (if not already applied cluster-wide)
kubectl apply -f cert-manager/cluster-issuer.yaml

# Run pre-deployment checks
bash pre-certificate-checklist.sh

# If all checks pass, deploy certificate
kubectl apply -f cert-manager/frontend-certificate.yaml
```

### 10. Verify Certificate Status

```bash
# Check certificate status
kubectl get certificate -n taprav-fri

# Watch certificate being issued (may take 1-5 minutes)
kubectl describe certificate frontend-tls-cert -n taprav-fri

# Check certificate is ready
kubectl get certificate frontend-tls-cert -n taprav-fri
# Should show: READY = True
```

### 11. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n taprav-fri

# Check services
kubectl get svc -n taprav-fri

# Check ingress
kubectl get ingress -n taprav-fri

# Test HTTP access
curl -I http://devops-sk-07.lrk.si

# Test HTTPS access (after certificate is issued)
curl -I https://devops-sk-07.lrk.si
```

---

## Complete Deployment Script

For convenience, here's a complete deployment script you can run:

```bash
#!/bin/bash
# Complete deployment script for school VM

set -e

echo "=========================================="
echo "Deploying Application Stack"
echo "=========================================="

# 1. Namespace
echo "Creating namespace..."
kubectl apply -f namespace/namespace.yaml

# 2. Secret (update with your values)
echo "Creating MySQL secret..."
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='skrito123' \
  --from-literal=mysql-user='user' \
  --from-literal=mysql-password='skrito123' \
  --from-literal=mysql-database='taprav-fri' \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Infrastructure
echo "Deploying infrastructure..."
kubectl apply -f configmaps/mysql-initdb.yaml
kubectl apply -f volumes/mysql-pvc.yaml
kubectl apply -f services/mysql-service.yaml
kubectl apply -f services/redis-service.yaml
kubectl apply -f services/backend-service.yaml
kubectl apply -f services/frontend-service.yaml

# 4. Applications
echo "Deploying applications..."
kubectl apply -f deployments/redis-deployment.yaml
kubectl apply -f deployments/mysql-deployment.yaml

echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n taprav-fri --timeout=300s

kubectl apply -f deployments/backend-deployment.yaml
kubectl apply -f deployments/frontend-deployment.yaml
kubectl apply -f deployments/frontend-green-deployment.yaml

# 5. LoadBalancer
echo "Configuring LoadBalancer..."
bash setup-loadbalancer.sh

# 6. Ingress
echo "Deploying ingress..."
kubectl apply -f ingress/frontend-ingress.yaml

# 7. TLS
echo "Deploying TLS certificate..."
kubectl apply -f cert-manager/cluster-issuer.yaml
kubectl apply -f cert-manager/frontend-certificate.yaml

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Check status:"
echo "  kubectl get pods -n taprav-fri"
echo "  kubectl get certificate -n taprav-fri"
echo ""
echo "Access application:"
echo "  http://devops-sk-07.lrk.si"
echo "  https://devops-sk-07.lrk.si (after certificate is issued)"
echo ""
```

Save this as `deploy-all.sh` and run:
```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

---

## Troubleshooting on School VM

### LoadBalancer External IP is Pending

**Wait:** On the school VM, LoadBalancer provisioning can take 1-5 minutes. Be patient.

**Check:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
kubectl describe svc -n ingress-nginx ingress-nginx-controller
```

**If still pending after 10 minutes:**
- Contact your instructor - the LoadBalancer service may need manual configuration
- Check if the cluster supports LoadBalancer type services

### Certificate Not Issuing

**Check certificate status:**
```bash
kubectl describe certificate frontend-tls-cert -n taprav-fri
kubectl logs -n cert-manager -l app=cert-manager
```

**Common issues:**
- **HTTP-01 challenge fails**: Ensure port 80 is accessible and DNS points to LoadBalancer IP
- **Rate limiting**: Let's Encrypt has rate limits. Use staging issuer for testing:
  ```bash
  kubectl apply -f cert-manager/cluster-issuer-staging.yaml
  # Update certificate to use staging issuer
  ```
- **DNS not configured**: Ensure `devops-sk-07.lrk.si` points to LoadBalancer external IP

### Pods Not Starting

**Check pod status:**
```bash
kubectl get pods -n taprav-fri
kubectl describe pod <pod-name> -n taprav-fri
kubectl logs <pod-name> -n taprav-fri
```

**Common issues:**
- **Image pull errors**: Verify image tags exist in GHCR
- **PVC not bound**: Check storage class and PVC status:
  ```bash
  kubectl get pvc -n taprav-fri
  kubectl get storageclass
  ```

### Service Not Accessible

**Check ingress:**
```bash
kubectl get ingress -n taprav-fri
kubectl describe ingress frontend-ingress -n taprav-fri
```

**Verify LoadBalancer:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

**Test connectivity:**
```bash
# From VM
curl -I http://devops-sk-07.lrk.si

# Check if DNS resolves correctly
nslookup devops-sk-07.lrk.si
```

---

## Verification Checklist

After deployment, verify:

- [ ] All pods are running: `kubectl get pods -n taprav-fri`
- [ ] LoadBalancer has external IP: `kubectl get svc -n ingress-nginx ingress-nginx-controller`
- [ ] DNS points to LoadBalancer IP: `nslookup devops-sk-07.lrk.si`
- [ ] HTTP is accessible: `curl -I http://devops-sk-07.lrk.si`
- [ ] Certificate is issued: `kubectl get certificate -n taprav-fri`
- [ ] HTTPS is accessible: `curl -I https://devops-sk-07.lrk.si`
- [ ] Application loads in browser: `http://devops-sk-07.lrk.si`

---

## Quick Commands Reference

```bash
# Check everything
kubectl get all -n taprav-fri

# Watch pods
kubectl get pods -n taprav-fri -w

# Check LoadBalancer
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check certificate
kubectl get certificate -n taprav-fri
kubectl describe certificate frontend-tls-cert -n taprav-fri

# Check ingress
kubectl get ingress -n taprav-fri
kubectl describe ingress frontend-ingress -n taprav-fri

# View logs
kubectl logs -n taprav-fri -l app=frontend --tail=50
kubectl logs -n taprav-fri -l app=backend --tail=50

# Delete everything (if needed)
kubectl delete namespace taprav-fri
```

---

## Next Steps

After successful deployment:

1. **Test the application**: Visit `http://devops-sk-07.lrk.si` in your browser
2. **Wait for HTTPS**: Certificate issuance can take 1-5 minutes
3. **Test Blue/Green deployment**: See `blue-green/` directory for scripts
4. **Test Rolling Update**: See README.md for rolling update demo

For more details, see the main [README.md](README.md).

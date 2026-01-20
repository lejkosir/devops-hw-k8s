# Kubernetes Deployment - DevOps HW

Production Kubernetes deployment of a multi-service web application (Frontend, Backend, MySQL, Redis) with automatic TLS/HTTPS, high availability, and zero-downtime deployments.

## Quick Start

```bash
bash deploy.sh
```

That's it. One command deploys everything. The script will:
1. Create namespace and secrets
2. Deploy ConfigMaps, PersistentVolumes, Services
3. Deploy infrastructure (Redis, MySQL)
4. Wait for MySQL to be ready
5. Deploy applications (Backend, Frontend)
6. Configure Ingress as LoadBalancer
7. Deploy TLS certificates (Let's Encrypt)
8. Deploy Ingress with HTTPS

**Access:** https://devops-sk-07.lrk.si (after ~2-3 minutes for certificate issuance)

---

## Prerequisites

Your Kubernetes cluster **must have**:
- `kubectl` configured and working
- Ingress-nginx controller installed
- cert-manager installed
- Domain `devops-sk-07.lrk.si` pointing to your cluster's public IP

If any are missing:

```bash
# Install ingress-nginx (if not present)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager (if not present)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

---

## What's Deployed

### Services
| Service | Replicas | Purpose |
|---------|----------|---------|
| **Frontend** | 3 (HA) | Next.js web application |
| **Backend** | 1 | PHP API server |
| **MySQL** | 1 | Database with persistent storage |
| **Redis** | 1 | Caching layer |

### Key Features

**High Availability** - Frontend has 3 replicas for load distribution
**Persistent Storage** - MySQL data survives Pod restarts
**Health Monitoring** - Readiness and liveness probes on all containers
**Automatic TLS** - Let's Encrypt certificates, auto-renewed
**Zero-Downtime Updates** - Rolling update strategy (maxSurge: 1, maxUnavailable: 0)
**Blue/Green Deployment** - frontend-blue and frontend-green for version switching

---

## Manual Deployment Steps (if you can't use deploy.sh)

```bash
# 1. Create namespace
kubectl apply -f namespace/

# 2. Create MySQL secret
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='skrito123' \
  --from-literal=mysql-user='user' \
  --from-literal=mysql-password='skrito123' \
  --from-literal=mysql-database='taprav-fri'

# 3. Deploy infrastructure
kubectl apply -f configmaps/
kubectl apply -f volumes/
kubectl apply -f services/
kubectl apply -f deployments/redis-deployment.yaml
kubectl apply -f deployments/mysql-deployment.yaml

# 4. Wait for MySQL
kubectl wait --for=condition=ready pod -l app=mysql -n taprav-fri --timeout=300s

# 5. Deploy applications
kubectl apply -f deployments/backend-deployment.yaml
kubectl apply -f deployments/frontend-deployment.yaml
kubectl apply -f deployments/frontend-green-deployment.yaml

# 6. Configure Ingress
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# 7. Deploy TLS
kubectl apply -f cert-manager/
kubectl apply -f ingress/
```

---

## Health Probes Configuration

All containers have readiness and liveness probes tuned for production:

### Frontend & Backend (HTTP)
- **Readiness**: Checks `/` every 10s, starts after 10s delay
- **Liveness**: Checks `/` every 30s, starts after 30s delay
- Prevents routing to unhealthy pods before startup completes

### MySQL (Command)
- **Readiness**: `mysqladmin ping` every 10s, starts after 10s delay
- **Liveness**: `mysqladmin ping` every 30s, starts after 30s delay
- Ensures database is accessible before applications connect

### Redis (Command)
- **Readiness**: `redis-cli ping` every 10s, starts after 5s delay
- **Liveness**: `redis-cli ping` every 30s, starts after 15s delay
- Detects cache failures early

---

## Rolling Update Strategy

Frontend has zero-downtime rolling updates configured:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Can add 1 extra Pod
    maxUnavailable: 0    # Never remove active Pods
```

This means:
- At all times, minimum 3 Pods are serving traffic
- New version Pod starts, passes readiness check, then old Pod terminates
- Takes ~30 seconds per Pod (3 Pods × 10s per update)

To perform a rolling update:

```bash
# Update the image
kubectl set image deployment/frontend-blue frontend=new-image:tag -n taprav-fri

# Watch the rollout
kubectl rollout status deployment/frontend-blue -n taprav-fri
```

---

## Blue/Green Deployment

Two separate deployments allow instant version switching:

### Current Setup
- **frontend-blue**: Active, serving traffic (3 replicas)
- **frontend-green**: Standby, ready to switch to

### To Switch to Green

```bash
# 1. Update the Ingress service selector to point to green
kubectl patch ingress frontend-ingress -n taprav-fri -p \
  '{"spec":{"rules":[{"host":"devops-sk-07.lrk.si","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"frontend-green"}}}]}}]}}'

# 2. Or manually edit and apply:
# - Edit ingress/frontend-ingress.yaml, change service name to "frontend-green"
kubectl apply -f ingress/frontend-ingress.yaml
```

---

## Troubleshooting

### Check all pods are running
```bash
kubectl get pods -n taprav-fri
```

### View pod logs
```bash
# Frontend logs
kubectl logs -n taprav-fri -l app=frontend --tail=100

# Backend logs
kubectl logs -n taprav-fri -l app=backend --tail=100

# MySQL logs
kubectl logs -n taprav-fri -l app=mysql --tail=50
```

### Check certificate status
```bash
# See certificate state
kubectl get certificate -n taprav-fri

# Detailed info
kubectl describe certificate frontend-tls-cert -n taprav-fri

# cert-manager logs if certificate fails
kubectl logs -n cert-manager -l app=cert-manager
```

### Verify Ingress
```bash
kubectl describe ingress frontend-ingress -n taprav-fri
kubectl get ingress -n taprav-fri
```

### Check services can communicate
```bash
# Exec into frontend pod
kubectl exec -it deployment/frontend-blue -n taprav-fri -- /bin/bash

# Test backend connectivity
curl http://backend/taprav-fri/api

# Test MySQL connectivity
mysql -h mysql -u user -p
```

---

## Directory Structure

```
kubernetes/
├── deploy.sh                          # ← RUN THIS ONE COMMAND
├── README.md                          # ← You are here
├── namespace/
│   └── namespace.yaml
├── secrets/
│   └── create-secret.sh               # Manual secret creation (not needed with deploy.sh)
├── configmaps/
│   └── mysql-initdb.yaml
├── volumes/
│   └── mysql-pvc.yaml
├── services/
│   ├── mysql-service.yaml
│   ├── redis-service.yaml
│   ├── backend-service.yaml
│   └── frontend-service.yaml
├── deployments/
│   ├── mysql-deployment.yaml
│   ├── redis-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml       (Blue - active)
│   └── frontend-green-deployment.yaml (Green - standby)
├── ingress/
│   └── frontend-ingress.yaml
└── cert-manager/
    ├── cluster-issuer.yaml
    └── frontend-certificate.yaml
```

---

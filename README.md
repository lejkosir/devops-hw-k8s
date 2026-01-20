# Kubernetes Deployment - DevOps HW

Production Kubernetes deployment of a multi-service web application (Frontend, Backend, MySQL, Redis) with automatic TLS/HTTPS, high availability, and zero-downtime deployments.

**Live Deployment:** https://devops-sk-07.lrk.si

---

## Quick Start

```bash
bash deploy.sh
```

One command deploys everything. The script creates namespace, secrets, ConfigMaps, PersistentVolumes, Services, Deployments, configures Ingress as LoadBalancer, and deploys TLS certificates.

**Access:** https://devops-sk-07.lrk.si (after ~2-3 minutes for certificate issuance)

---

## Prerequisites

- Kubernetes cluster with `kubectl` configured
- Ingress-nginx controller installed
- cert-manager installed
- Domain `devops-sk-07.lrk.si` pointing to cluster's public IP

If missing:

```bash
# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

---

## Architecture

### Services

| Service | Replicas | Image | Purpose |
|---------|----------|-------|---------|
| **Frontend** | 3 (HA) | `ghcr.io/lejkosir/devops-hw-docker-frontend:sha-8c13a21` | Next.js web application |
| **Backend** | 1 | `ghcr.io/lejkosir/devops-hw-docker-backend:sha-8c13a21` | PHP API server |
| **MySQL** | 1 | `mysql:8.0` | Database with persistent storage |
| **Redis** | 1 | `redis:7` | Caching layer |

### Key Features

- **High Availability**: Frontend has 3 replicas for load distribution
- **Persistent Storage**: MySQL data persists via PersistentVolumeClaim (1Gi)
- **Automatic TLS**: Let's Encrypt certificates via cert-manager, auto-renewed
- **Health Monitoring**: Readiness and liveness probes on all containers
- **Zero-Downtime Updates**: Rolling update strategy (maxSurge: 1, maxUnavailable: 0)
- **Blue/Green Deployment**: frontend-blue and frontend-green with instant switching

### CI/CD and Multi-Stage Builds

- **CI/CD Pipeline**: GitHub Actions automatically builds, tags (SHA-based), and publishes images to GHCR on every push
- **Multi-Stage Builds**: Frontend and Backend images use multi-stage Docker builds (configured in separate Docker project repository)
- **Image Tags**: SHA-based tags ensure reproducible deployments (e.g., `sha-8c13a21`)

---

## Deployment Instructions

### Automated Deployment

```bash
bash deploy.sh
```

### Manual Deployment

```bash
# 1. Create namespace
kubectl apply -f namespace/namespace.yaml

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

# 6. Configure Ingress LoadBalancer
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# 7. Deploy TLS
kubectl apply -f cert-manager/cluster-issuer.yaml
kubectl apply -f cert-manager/frontend-certificate.yaml
kubectl apply -f ingress/frontend-ingress.yaml
```

---

## Health Probes Configuration

All containers have readiness and liveness probes with tuned parameters:

### Frontend & Backend (HTTP Probes)
- **Readiness**: HTTP GET `/` every 10s, starts after 10s delay
- **Liveness**: HTTP GET `/` every 20s, starts after 15s delay
- **Rationale**: HTTP probes verify the application actually responds (not just port open). 10s initial delay allows app startup, 20s period balances responsiveness vs. load.

### MySQL (Exec Probe)
- **Readiness**: `mysqladmin ping` every 10s, starts after 10s delay
- **Liveness**: `mysqladmin ping` every 30s, starts after 30s delay
- **Rationale**: Exec probe verifies MySQL can process queries (not just accept connections). 10s delay accounts for MySQL initialization time.

### Redis (Exec Probe)
- **Readiness**: `redis-cli ping` every 10s, starts after 5s delay
- **Liveness**: `redis-cli ping` every 30s, starts after 15s delay
- **Rationale**: Exec probe verifies Redis responds to commands. 5s delay is sufficient as Redis starts quickly.

**Common Parameters**: `successThreshold: 1`, `failureThreshold: 3` - Single success marks ready, 3 consecutive failures trigger action.

---

## Rolling Update Strategy

Frontend deployment uses zero-downtime rolling updates:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Can add 1 extra Pod
    maxUnavailable: 0    # Never remove active Pods
```

**Behavior**: At all times, minimum 3 Pods serve traffic. New Pod starts, passes readiness check, then old Pod terminates. Updates one Pod at a time.

**To perform rolling update:**
```bash
kubectl set image deployment/frontend-blue frontend=new-image:tag -n taprav-fri
kubectl rollout status deployment/frontend-blue -n taprav-fri
```

---

## Blue/Green Deployment

Two separate deployments (`frontend-blue` and `frontend-green`) allow instant version switching via service selector.

**Current Setup:**
- `frontend-blue`: Active, serving traffic (3 replicas)
- `frontend-green`: Standby, ready to switch to (3 replicas)
- `frontend` service: Routes traffic via `version` selector

**To switch to green:**
```bash
bash blue-green/switch-blue-green.sh green
# Or toggle: bash blue-green/switch-blue-green.sh
```

**To check current version:**
```bash
bash blue-green/check-version.sh
```

**To deploy new image to green:**
```bash
bash blue-green/deploy-green.sh sha-<commit-sha>
```

**How it works**: The `frontend` service uses a `version` selector (`blue` or `green`). Switching updates the selector, instantly routing traffic to the other deployment with zero downtime.

---

## Zero-Downtime Deployment Demonstrations

### Rolling Update Demo

**Setup**: Frontend has 3 replicas, `maxSurge: 1`, `maxUnavailable: 0`

1. Start monitoring: `watch kubectl get pods -n taprav-fri -l app=frontend`
2. Update image: `kubectl set image deployment/frontend-blue frontend=ghcr.io/lejkosir/devops-hw-docker-frontend:sha-<new-sha> -n taprav-fri`
3. Observe: New Pod starts → passes readiness → old Pod terminates → repeat for each Pod
4. Verify: `kubectl rollout status deployment/frontend-blue -n taprav-fri`

**Result**: All 3 Pods updated with zero downtime. At least 3 Pods serve traffic at all times.

### Blue/Green Deployment Demo

1. Check current version: `bash blue-green/check-version.sh`
2. Deploy new image to green: `bash blue-green/deploy-green.sh sha-<new-sha>`
3. Monitor green pods: `kubectl get pods -n taprav-fri -l app=frontend,version=green -w`
4. Switch traffic: `bash blue-green/switch-blue-green.sh green`
5. Verify: Traffic instantly routes to green deployment

**Result**: Instant switch with zero downtime. Blue remains running for quick rollback.

**Screenshots/Recordings**: 

[![asciicast](https://asciinema.org/a/BZY75hkqNkk0WXi9.svg)](https://asciinema.org/a/BZY75hkqNkk0WXi9)

---

## TLS / HTTPS Configuration

TLS is configured using **cert-manager** with **Let's Encrypt**:

- **ClusterIssuer**: Let's Encrypt production issuer (HTTP-01 challenge)
- **Certificate**: Automatically issued and renewed for `devops-sk-07.lrk.si`
- **Ingress**: Configured with TLS termination and HTTPS redirect

**Certificate Status:**
```bash
kubectl get certificate -n taprav-fri
kubectl describe certificate frontend-tls-cert -n taprav-fri
```

---

## Troubleshooting

**Check pod status:**
```bash
kubectl get pods -n taprav-fri
kubectl describe pod <pod-name> -n taprav-fri
```

**View logs:**
```bash
kubectl logs -n taprav-fri -l app=frontend --tail=100
kubectl logs -n taprav-fri -l app=backend --tail=100
```

**Check certificate:**
```bash
kubectl get certificate -n taprav-fri
kubectl describe certificate frontend-tls-cert -n taprav-fri
kubectl logs -n cert-manager -l app=cert-manager
```

**Verify ingress:**
```bash
kubectl get ingress -n taprav-fri
kubectl describe ingress frontend-ingress -n taprav-fri
```

---

## Directory Structure

```
.
├── deploy.sh                          # One-command deployment
├── blue-green/                        # Blue/Green deployment helpers
│   ├── switch-blue-green.sh
│   ├── check-version.sh
│   └── deploy-green.sh
├── namespace/
│   └── namespace.yaml
├── secrets/
│   └── mysql-secret.yaml
├── configmaps/
│   └── mysql-initdb.yaml
├── volumes/
│   └── mysql-pvc.yaml
├── services/
│   ├── frontend-service.yaml
│   ├── backend-service.yaml
│   ├── mysql-service.yaml
│   └── redis-service.yaml
├── deployments/
│   ├── frontend-deployment.yaml      # Blue (active)
│   ├── frontend-green-deployment.yaml # Green (standby)
│   ├── backend-deployment.yaml
│   ├── mysql-deployment.yaml
│   └── redis-deployment.yaml
├── ingress/
│   └── frontend-ingress.yaml
└── cert-manager/
    ├── cluster-issuer.yaml
    └── frontend-certificate.yaml
```

---

## Extra Features

- **Blue/Green Deployment Scripts**: Automated scripts for version switching and deployment
- **Comprehensive Health Probes**: Tuned probes for all services (HTTP for web, exec for databases)
- **Single-Command Deployment**: `deploy.sh` automates entire deployment process
- **SHA-Based Image Tags**: Ensures reproducible deployments
- **Fixed CI/CD from last time**: No double npm build in CI/CD and docker file
---

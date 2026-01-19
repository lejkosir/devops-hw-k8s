# devops-hw-k8s
Web stack deployment using Kubernetes

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Complete Deployment Instructions](#complete-deployment-instructions)
- [School VM Deployment](#school-vm-deployment) ⭐
- [Secret Management](#secret-management)
- [TLS / HTTPS Configuration](#tls--https-configuration)
- [Health Probes Configuration](#health-probes-configuration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Rolling Update Strategy](#rolling-update-strategy)
- [Blue/Green Deployment](#bluegreen-deployment)
- [Deployment Demonstrations](#deployment-demonstrations)
- [Extra Features](#extra-features)

---

## Overview

This project migrates a Docker Compose application stack to Kubernetes, providing high availability, zero-downtime deployments, and automatic certificate management. The stack consists of a Next.js frontend, PHP backend API, MySQL database, and Redis cache, all orchestrated using Kubernetes with Nginx Ingress and cert-manager for TLS.

**Live Deployment:** [http://devops-sk-07.lrk.si](http://devops-sk-07.lrk.si)

---

## Architecture

The application consists of **four main services**:

| Service | Description | Replicas | Image |
|---------|-------------|----------|-------|
| **Frontend** | Next.js web application | 3 (HA) | `ghcr.io/lejkosir/devops-hw-docker-frontend` |
| **Backend** | PHP API server | 1 | `ghcr.io/lejkosir/devops-hw-docker-backend` |
| **MySQL** | Database with persistent storage | 1 | `mysql:8.0` |
| **Redis** | Cache service | 1 | `redis:7` |

### Key Components

- **Ingress**: Nginx Ingress Controller for external access
- **TLS**: cert-manager with Let's Encrypt for automatic HTTPS certificates
- **Storage**: PersistentVolumeClaim for MySQL data persistence
- **Networking**: Services provide internal DNS-based service discovery
- **Health Monitoring**: Readiness and liveness probes on all containers
- **Deployment Strategies**: Rolling update and Blue/Green deployment support

---

## Prerequisites

- Kubernetes cluster (tested on minikube and standard K8s clusters)
- Nginx Ingress Controller installed
- **Ingress controller service configured as LoadBalancer** (required for TLS/HTTPS)
  - On minikube: Run `sudo minikube tunnel` after configuring LoadBalancer
  - On cloud providers: LoadBalancer will automatically provision
- cert-manager installed (for TLS)
- Domain name pointing to ingress controller's public IP (`devops-sk-07.lrk.si`)
- Ports 80 and 443 accessible (for HTTP-01 challenge)
- `kubectl` installed and configured

---

## School VM Deployment

**For deploying on the school VM, see the dedicated guide:**

👉 **[SCHOOL-VM-DEPLOYMENT.md](SCHOOL-VM-DEPLOYMENT.md)** - Step-by-step instructions optimized for the school VM environment.

The guide includes:
- Quick deployment steps
- Complete deployment script
- School VM-specific troubleshooting
- Verification checklist

---

## Complete Deployment Instructions

Follow these steps to deploy the entire application stack from scratch.

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd DN03-kubernetes
```

### Step 2: Create Namespace

```bash
kubectl apply -f namespace/namespace.yaml
```

### Step 3: Create MySQL Secret

**Linux/Mac:**
```bash
bash secrets/create-secret.sh
```

**Windows PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File secrets/create-secret.ps1
```

**Manual:**
```bash
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='your-root-password' \
  --from-literal=mysql-user='your-user' \
  --from-literal=mysql-password='your-password' \
  --from-literal=mysql-database='your-database'
```

See `secrets/mysql-secret.yaml.template` for reference.

### Step 4: Deploy ConfigMaps

```bash
kubectl apply -f configmaps/mysql-initdb.yaml
```

### Step 5: Deploy PersistentVolumes

```bash
kubectl apply -f volumes/mysql-pvc.yaml
```

### Step 6: Deploy Services

```bash
kubectl apply -f services/mysql-service.yaml
kubectl apply -f services/redis-service.yaml
kubectl apply -f services/backend-service.yaml
kubectl apply -f services/frontend-service.yaml
```

### Step 7: Deploy Applications

```bash
# Deploy infrastructure services first
kubectl apply -f deployments/redis-deployment.yaml
kubectl apply -f deployments/mysql-deployment.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n taprav-fri --timeout=300s

# Deploy application services
kubectl apply -f deployments/backend-deployment.yaml
kubectl apply -f deployments/frontend-deployment.yaml  # Blue deployment
kubectl apply -f deployments/frontend-green-deployment.yaml  # Green deployment (optional for blue/green)
```

### Step 8: Configure Ingress Controller Service (LoadBalancer)

**Important:** The ingress controller service must be configured as `LoadBalancer` type to expose ports 80 and 443 externally for TLS certificate provisioning.

```bash
# Change ingress controller service to LoadBalancer type
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# On minikube, run tunnel to get external IP (run in separate terminal)
sudo minikube tunnel

# On cloud providers (AWS, GCP, Azure), the LoadBalancer will automatically provision
# Wait for external IP to be assigned:
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

**Note:** 
- On **minikube**: You need to run `sudo minikube tunnel` in a separate terminal to assign an external IP to the LoadBalancer service.
- On **cloud providers**: The LoadBalancer will automatically provision and assign an external IP.
- Ensure your domain (`devops-sk-07.lrk.si`) DNS points to the external IP of the LoadBalancer.

### Step 9: Configure TLS (cert-manager)

```bash
# Apply ClusterIssuer (requires cluster admin)
kubectl apply -f cert-manager/cluster-issuer.yaml

# Apply Certificate resource
kubectl apply -f cert-manager/frontend-certificate.yaml
```

### Step 10: Deploy Ingress

```bash
kubectl apply -f ingress/frontend-ingress.yaml
```

### Step 11: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n taprav-fri

# Check services
kubectl get svc -n taprav-fri

# Check ingress
kubectl get ingress -n taprav-fri

# Check certificate status
kubectl get certificate -n taprav-fri
```

**Note:** Certificate provisioning may take 1-2 minutes. Check cert-manager logs if issues occur:
```bash
kubectl logs -n cert-manager -l app=cert-manager
```

### Quick Deploy Script

For TLS configuration only:
```bash
bash deploy-tls.sh
```

---

## Secret Management

For security best practices, secrets are **NOT** committed to git. They are created using kubectl scripts or manually.

The MySQL secret contains:
- `mysql-root-password`: Root user password
- `mysql-user`: Application database user
- `mysql-password`: Application database user password
- `mysql-database`: Database name

See `secrets/` directory for creation scripts.

---

## TLS / HTTPS Configuration

TLS is configured using **cert-manager** with **Let's Encrypt**:

- Automatic HTTPS certificate provisioning
- Let's Encrypt production certificates
- Automatic certificate renewal (90-day lifecycle)
- HTTP-01 challenge (requires port 80 to be accessible)

### LoadBalancer Requirement

**Important:** The ingress controller service must be configured as `LoadBalancer` type to expose ports 80 and 443 externally. This is required for:
- Let's Encrypt HTTP-01 challenge (port 80)
- HTTPS access (port 443)

To configure the ingress controller as LoadBalancer:
```bash
# Use the helper script
./setup-loadbalancer.sh

# Or manually:
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'

# On minikube, run tunnel in separate terminal:
sudo minikube tunnel
```

### Components

1. **ClusterIssuer** (`cert-manager/cluster-issuer.yaml`): Cluster-wide Let's Encrypt configuration
2. **Certificate** (`cert-manager/frontend-certificate.yaml`): Domain-specific certificate request
3. **Ingress** (`ingress/frontend-ingress.yaml`): TLS termination and HTTPS redirect

The ingress is configured to:
- Automatically obtain Let's Encrypt certificate via cert-manager
- Redirect HTTP → HTTPS
- Use the certificate for TLS termination

**Certificate Status:**
```bash
kubectl get certificate -n taprav-fri
kubectl describe certificate frontend-tls-cert -n taprav-fri
```

---

## Health Probes Configuration

All deployments include **readiness** and **liveness** probes to ensure service reliability and zero-downtime deployments.

### Probe Parameters Rationale

#### Frontend (HTTP Probes)

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 10    # Allow Next.js to start
  periodSeconds: 10          # Check every 10s (frequent for quick detection)
  timeoutSeconds: 3          # 3s timeout per check
  successThreshold: 1        # One success marks ready
  failureThreshold: 3        # 3 failures = 30s before marking unhealthy

livenessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 15    # Longer delay to avoid false positives during startup
  periodSeconds: 20          # Less frequent than readiness (reduces overhead)
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 3        # 3 failures = 60s before restart
```

**Rationale:**
- `initialDelaySeconds: 10` - Next.js needs ~5-10s to start. This prevents premature readiness checks.
- `periodSeconds: 10` - Frequent checks ensure quick detection of failures, important for HA.
- `timeoutSeconds: 3` - Reasonable timeout for HTTP requests, prevents hanging checks.
- `failureThreshold: 3` - Allows transient network issues without false restarts.
- Liveness period longer (20s) than readiness (10s) - Reduces overhead while still catching deadlocks.

#### Backend (HTTP Probes)

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10    # PHP + Apache startup time
  periodSeconds: 10
  timeoutSeconds: 3
  # Same rationale as frontend
```

**Rationale:** Similar to frontend, but PHP/Apache typically starts faster. 10s initial delay provides safety margin.

#### MySQL (TCP Probes)

```yaml
readinessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 30    # MySQL initialization takes time (especially first run)
  periodSeconds: 10
  timeoutSeconds: 3

livenessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 60    # Much longer - database restarts are expensive
  periodSeconds: 30          # Less frequent - TCP checks are lighter
  timeoutSeconds: 5
```

**Rationale:**
- `initialDelaySeconds: 30/60` - MySQL requires time for database initialization, especially on first startup with init scripts.
- `periodSeconds: 30` (liveness) - Less frequent than HTTP services because:
  - TCP checks are lighter, but database operations shouldn't be interrupted frequently
  - Database restarts are expensive, we want to be more conservative
- `timeoutSeconds: 5` - Slightly longer for database connections.

#### Redis (TCP Probes)

```yaml
readinessProbe:
  tcpSocket:
    port: 6379
  initialDelaySeconds: 10    # Redis starts quickly
  periodSeconds: 10
  timeoutSeconds: 3
```

**Rationale:** Redis starts very quickly (< 1s), so 10s initial delay is more than sufficient. TCP checks are used because Redis doesn't expose HTTP endpoints.

### Why These Probes Matter

1. **Readiness Probe**: Ensures traffic only goes to pods that are ready. Critical for zero-downtime deployments.
2. **Liveness Probe**: Automatically restarts crashed/hanging containers. Improves reliability.
3. **Proper Tuning**: Prevents false positives while ensuring quick failure detection.

---

## CI/CD Pipeline

The CI/CD pipeline automatically builds, tags, and publishes Docker images from the source code repository.

### Setup

**Location:** CI/CD is configured in the [Docker project repository](https://github.com/lejkosir/devops-hw-docker) (separate from this K8s repo).

**Workflow File:** `.github/workflows/publish.yaml`

### How It Works

1. **Trigger**: Push to any branch, tags (`v*.*.*`), pull requests, or manual trigger
2. **Source Code**: Clones the application source code repository (`devops-spletna`)
3. **Build Process**:
   - Builds Next.js frontend application (optimized - build happens once in CI/CD, not in Dockerfile)
   - Builds Docker images for frontend and backend
   - Uses multi-stage builds for minimal final images
4. **Tagging**: Images are tagged with:
   - SHA-based tags (`sha-<commit-sha>`) - **Used in Kubernetes deployments**
   - Branch names
   - Semantic versioning (if tags pushed)
   - `latest` (for convenience, but not used in production)
5. **Publish**: Images pushed to GitHub Container Registry (GHCR)

### Image Location

Images are published to:
- **Frontend**: `ghcr.io/lejkosir/devops-hw-docker-frontend:sha-<commit-sha>`
- **Backend**: `ghcr.io/lejkosir/devops-hw-docker-backend:sha-<commit-sha>`

### Using New Images in Kubernetes

After CI/CD completes:

1. Get the new SHA tag from GitHub Actions or GHCR packages page
2. Update deployment:
   ```bash
   # For rolling update (frontend-blue)
   kubectl set image deployment/frontend-blue \
     frontend=ghcr.io/lejkosir/devops-hw-docker-frontend:sha-<new-sha> \
     -n taprav-fri
   
   # For blue/green (green deployment)
   ./blue-green/deploy-green.sh sha-<new-sha>
   ```

### CI/CD Benefits

- **Automatic builds** on every code change
- **Immutable tags** (SHA-based) prevent "latest" tag issues
- **Optimized builds** (frontend built once in CI/CD, not in Dockerfile)
- **Multi-stage builds** for minimal production images

---

## Rolling Update Strategy

The frontend deployment uses a **RollingUpdate** strategy configured to ensure zero-downtime updates while maintaining service availability.

### Configuration

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Allow 1 extra pod during update (total: 4 pods)
    maxUnavailable: 0    # Never go below 3 available pods
```

### How It Works

With `replicas: 3`, `maxSurge: 1`, `maxUnavailable: 0`:

1. **Initial state**: 3 pods running (version 1)
2. **Update triggered**: New pod (version 2) created → 4 pods total (3 v1, 1 v2)
3. **New pod becomes ready**: Traffic shifts to v2 pod
4. **Old pod terminated**: Back to 3 pods (2 v1, 1 v2)
5. **Process repeats**: Until all 3 pods are v2
6. **Always maintains**: Minimum 3 available pods (zero-downtime)

### Demo Instructions

**Prerequisites:**
- Two different image versions (make a visual change, build via CI/CD)
- Frontend deployment with 3 replicas

**Steps:**

1. **Check current state:**
   ```bash
   kubectl get pods -n taprav-fri -l app=frontend,version=blue
   ```

2. **Deploy new version:**
   ```bash
   kubectl set image deployment/frontend-blue \
     frontend=ghcr.io/lejkosir/devops-hw-docker-frontend:sha-<new-commit-sha> \
     -n taprav-fri
   ```

3. **Watch the rolling update:**
   ```bash
   kubectl rollout status deployment/frontend-blue -n taprav-fri
   kubectl get pods -n taprav-fri -l app=frontend,version=blue -w
   ```

4. **Verify zero-downtime:**
   ```bash
   # Continuous requests should always return 200
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://devops-sk-07.lrk.si; sleep 0.5; done
   ```

**Expected Result:**
- Service remains available throughout (HTTP 200)
- Pods updated one at a time
- Always 3+ pods available
- No traffic disruption

---

## Blue/Green Deployment

Blue/Green deployment provides instant traffic switching between two identical environments, enabling zero-downtime deployments and easy rollback.

### Architecture

- **Blue Deployment**: `frontend-blue` (3 replicas) - Current production
- **Green Deployment**: `frontend-green` (3 replicas) - New version
- **Service**: Routes traffic to active version via label selector

### Configuration

The service selector determines which version receives traffic:

```yaml
selector:
  app: frontend
  version: blue   # or "green"
```

### Usage

#### 1. Check Current Active Version

```bash
./blue-green/check-version.sh
```

#### 2. Deploy New Version to Green

```bash
./blue-green/deploy-green.sh sha-<new-commit-sha>
```

This:
- Updates the green deployment with the new image
- Waits for all green pods to be ready
- Green is now ready but not receiving traffic yet

#### 3. Verify Green Deployment

```bash
kubectl get pods -n taprav-fri -l app=frontend,version=green
```

#### 4. Switch Traffic to Green

```bash
./blue-green/switch-blue-green.sh green
```

This instantly switches traffic from blue to green.

#### 5. Rollback (if needed)

```bash
./blue-green/switch-blue-green.sh blue
```

### Demo Instructions

**Prerequisites:**
- Blue and green deployments both created
- Two different image versions ready

**Steps:**

1. **Set up monitoring** (tmux session recommended):
   ```bash
   bash blue-green/tmux-demo-setup.sh
   ```
   This creates 3 panes:
   - Top: Watch pods
   - Bottom-left: Monitor HTTP responses
   - Bottom-right: Run commands

2. **Check initial state:**
   ```bash
   ./blue-green/check-version.sh
   # Should show: Active version: blue
   ```

3. **Deploy new version to green:**
   ```bash
   ./blue-green/deploy-green.sh sha-<new-commit-sha>
   ```

4. **Verify green pods are ready:**
   ```bash
   kubectl get pods -n taprav-fri -l app=frontend,version=green
   ```

5. **Switch traffic:**
   ```bash
   ./blue-green/switch-blue-green.sh green
   ```

6. **Verify switch:**
   ```bash
   ./blue-green/check-version.sh
   # Should show: Active version: green
   ```

7. **Test application:**
   - Visit http://devops-sk-07.lrk.si
   - Should see new version (visual change)

**Expected Result:**
- Both blue and green pods running simultaneously
- Instant traffic switch (no downtime)
- Easy rollback capability
- HTTP monitoring shows continuous 200 responses

### Scripts

All blue/green scripts are in `blue-green/` directory:
- `check-version.sh` - Shows which version is active
- `deploy-green.sh` - Deploys new image to green
- `switch-blue-green.sh` - Switches traffic between versions

---

## Deployment Demonstrations

### Blue/Green Deployment Demo

**Demonstration of zero-downtime deployment using Blue/Green strategy.**

#### Setup

The demo uses a tmux session with three panes to show:
1. **Pod Status**: Real-time view of blue and green pods
2. **HTTP Monitoring**: Continuous requests showing service availability
3. **Commands**: Deployment and traffic switching commands

#### Demo Process

1. **Initial State**: Blue deployment serving traffic (3 pods)
2. **Deploy to Green**: New version deployed to green (3 pods) - not receiving traffic
3. **Switch Traffic**: Instant switch from blue → green
4. **Result**: New version live with zero downtime

#### Screenshots / Recording

*[Screenshots or asciinema link will be added here]*

**Key Moments Captured:**
- Both blue and green pods running simultaneously
- Deploying new version to green
- Traffic switching from blue to green
- HTTP responses showing 200 throughout (zero-downtime proof)
- Instant rollback capability

#### Recording

*[Asciinema recording or video link will be added here]*

---

## Extra Features

### Multi-Stage Docker Builds

The frontend application uses **multi-stage builds** for minimal production images:
- **Build stage**: Full Node.js environment for building the Next.js app
- **Runtime stage**: Distroless Node.js image (minimal, no shell, no package manager)
- **Result**: Significantly smaller and more secure production images

### CI/CD Build Optimization

The CI/CD pipeline optimizes the build process:
- **Frontend**: Built once in CI/CD (not in Dockerfile) - eliminates double build
- **Docker image**: Only packages pre-built artifacts
- **Benefits**: Faster builds, better caching, clearer separation of concerns

### Persistent Volume Configuration

MySQL uses a PersistentVolumeClaim for data persistence:
- **Storage class**: Uses cluster default
- **Access mode**: ReadWriteOnce
- **Size**: 1Gi (configurable)
- **Mount point**: `/var/lib/mysql`

This ensures database data survives pod restarts and redeployments.

### Health Probe Tuning

All services have carefully tuned health probes:
- **Readiness probes**: Ensure only healthy pods receive traffic
- **Liveness probes**: Automatically restart unhealthy containers
- **Parameters**: Optimized per service type (HTTP vs TCP, startup time, etc.)

See [Health Probes Configuration](#health-probes-configuration) for detailed rationale.

### Blue/Green Deployment Scripts

Helper scripts for easy blue/green deployments:
- Automated version checking
- Image deployment with rollout verification
- Instant traffic switching
- See `blue-green/` directory

### Namespace Isolation

All resources deployed in dedicated namespace (`taprav-fri`) for:
- Resource isolation
- Clean organization
- Easy cleanup (delete namespace removes all resources)

---

## Troubleshooting

### LoadBalancer Issues

**External IP is pending:**
- On **minikube**: Run `sudo minikube tunnel` in a separate terminal
- On **cloud providers**: Wait for LoadBalancer provisioning (can take 1-5 minutes)
- Check service status: `kubectl get svc -n ingress-nginx ingress-nginx-controller`

**Ports 80/443 not accessible:**
- Verify LoadBalancer has external IP: `kubectl get svc -n ingress-nginx ingress-nginx-controller`
- Ensure DNS points to the external IP: `nslookup devops-sk-07.lrk.si`
- Check firewall rules allow ports 80 and 443
- On minikube, ensure `minikube tunnel` is running

### Certificate Issues

If certificate is not issued:
```bash
kubectl describe certificate frontend-tls-cert -n taprav-fri
kubectl logs -n cert-manager -l app=cert-manager
```

**Common certificate errors:**
- **HTTP-01 challenge fails**: Ensure port 80 is accessible and DNS points to LoadBalancer IP
- **Rate limiting**: Let's Encrypt has rate limits (5 certs per domain per week). Use staging issuer for testing
- **DNS not propagated**: Wait for DNS changes to propagate (can take up to 48 hours)

### Pod Not Starting

Check pod status:
```bash
kubectl describe pod <pod-name> -n taprav-fri
kubectl logs <pod-name> -n taprav-fri
```

### Image Pull Errors

Verify image exists in GHCR:
- Check GitHub Actions workflow completed
- Verify image tag in GHCR packages page
- Ensure image tag matches exactly (SHA-based tags)

### Service Not Accessible

Check ingress:
```bash
kubectl get ingress -n taprav-fri
kubectl describe ingress frontend-ingress -n taprav-fri
```

---

## Repository Structure

```
.
├── blue-green/              # Blue/green deployment scripts
│   ├── check-version.sh
│   ├── deploy-green.sh
│   ├── switch-blue-green.sh
│   └── tmux-demo-setup.sh
├── cert-manager/            # TLS certificate configuration
│   ├── cluster-issuer.yaml
│   ├── cluster-issuer-staging.yaml
│   └── frontend-certificate.yaml
├── configmaps/              # Configuration files
│   └── mysql-initdb.yaml
├── deployments/             # Application deployments
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml      # Blue deployment
│   ├── frontend-green-deployment.yaml # Green deployment
│   ├── mysql-deployment.yaml
│   └── redis-deployment.yaml
├── ingress/                 # Ingress configuration
│   └── frontend-ingress.yaml
├── namespace/               # Namespace definition
│   └── namespace.yaml
├── secrets/                 # Secret creation scripts
│   ├── create-secret.sh
│   ├── create-secret.ps1
│   └── mysql-secret.yaml.template
├── services/                # Service definitions
│   ├── backend-service.yaml
│   ├── frontend-service.yaml
│   ├── mysql-service.yaml
│   └── redis-service.yaml
├── volumes/                 # Persistent volume claims
│   └── mysql-pvc.yaml
├── deploy-tls.sh            # TLS deployment script
├── setup-loadbalancer.sh    # Configure ingress controller as LoadBalancer
├── pre-certificate-checklist.sh  # Pre-deployment checks for TLS
└── README.md                # This file
```

---

## License

[Your license if applicable]

---

**Last Updated:** January 2026

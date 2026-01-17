# devops-hw-k8s
Web stack deployment using kubernetes

## Prerequisites

- Kubernetes cluster with cert-manager installed
- Nginx Ingress Controller installed
- Domain `devops-sk-07.lrk.si` pointing to the ingress controller's public IP
- Ports 80 and 443 accessible

## TLS / HTTPS Configuration

TLS is configured using **cert-manager** with **Let's Encrypt**:

- Automatic HTTPS certificate provisioning
- Let's Encrypt certificates (production)
- Automatic certificate renewal
- HTTP-01 challenge (requires port 80 to be accessible)

### Setup TLS

**Where to run these commands:**

You need to run these commands on a machine that has:
- `kubectl` installed
- Access to your Kubernetes cluster (kubeconfig configured)
- Appropriate permissions (ClusterIssuer needs cluster admin)

**Options:**
1. **SSH into the cluster node/control plane** (if you have SSH access)
2. **Your local machine** (if you have kubeconfig configured)
3. **Bastion/jump host** (if provided by your university)

**Quick deployment (using scripts):**

**Linux/Mac:**
```bash
bash deploy-tls.sh
```

**Windows PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File deploy-tls.ps1
```

**Manual deployment:**

1. **Apply cert-manager resources:**
   ```bash
   # Apply ClusterIssuer (cluster-wide, needs cluster admin)
   kubectl apply -f cert-manager/cluster-issuer.yaml
   
   # Optional: Apply staging issuer for testing
   kubectl apply -f cert-manager/cluster-issuer-staging.yaml
   ```

2. **Apply Certificate resource:**
   ```bash
   kubectl apply -f cert-manager/frontend-certificate.yaml
   ```

3. **Apply/Update Ingress (includes TLS configuration):**
   ```bash
   kubectl apply -f ingress/frontend-ingress.yaml
   ```

4. **Verify certificate:**
   ```bash
   # Check certificate status
   kubectl get certificate -n taprav-fri
   
   # Check certificate details
   kubectl describe certificate frontend-tls-cert -n taprav-fri
   ```

The ingress is configured to:
- Automatically obtain Let's Encrypt certificate via cert-manager
- Redirect HTTP → HTTPS
- Use the certificate for TLS termination

**Note:** Certificate provisioning may take 1-2 minutes. Check cert-manager logs if issues occur:
```bash
kubectl logs -n cert-manager -l app=cert-manager
```

## Secret Management

For security best practices, secrets are NOT committed to git. Instead, create them using kubectl:

### Linux/Mac:
```bash
bash secrets/create-secret.sh
```

### Windows PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File secrets/create-secret.ps1
```

### Manual creation:
```bash
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='your-root-password' \
  --from-literal=mysql-user='your-user' \
  --from-literal=mysql-password='your-password' \
  --from-literal=mysql-database='your-database'
```

See `secrets/mysql-secret.yaml.template` for reference structure.
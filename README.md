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

**Deployment via SSH (recommended if you have SSH access):**

1. **SSH into the VM:**
   ```bash
   ssh your-username@devops-sk-07.lrk.si
   # or whatever your SSH connection command is
   ```

2. **Clone your repository (if using git):**
   ```bash
   git clone <your-repo-url>
   cd DN03-kubernetes
   ```
   
   **OR transfer files via SCP from your local machine:**
   ```bash
   # From your local Windows machine (PowerShell)
   scp -r . your-username@devops-sk-07.lrk.si:~/DN03-kubernetes/
   ```

3. **Run the deployment script:**
   ```bash
   bash deploy-tls.sh
   ```

**Alternative: Manual deployment on VM:**

If you prefer to run commands manually after SSH:

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
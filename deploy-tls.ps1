# PowerShell script to deploy TLS configuration
# Run this on a machine with kubectl configured and access to your Kubernetes cluster

Write-Host "Deploying TLS configuration..." -ForegroundColor Cyan

# Check if kubectl is available
try {
    $null = Get-Command kubectl -ErrorAction Stop
    Write-Host "✓ kubectl is available" -ForegroundColor Green
} catch {
    Write-Host "Error: kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if we can connect to cluster
try {
    $null = kubectl cluster-info 2>&1
    Write-Host "✓ kubectl is configured" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot connect to Kubernetes cluster. Please configure kubeconfig." -ForegroundColor Red
    exit 1
}

# Apply ClusterIssuer (needs cluster admin permissions)
Write-Host "Applying ClusterIssuer..." -ForegroundColor Yellow
kubectl apply -f cert-manager/cluster-issuer.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: ClusterIssuer may require cluster admin permissions" -ForegroundColor Yellow
}

# Apply Certificate
Write-Host "Applying Certificate..." -ForegroundColor Yellow
kubectl apply -f cert-manager/frontend-certificate.yaml

# Update Ingress with TLS
Write-Host "Updating Ingress with TLS configuration..." -ForegroundColor Yellow
kubectl apply -f ingress/frontend-ingress.yaml

Write-Host ""
Write-Host "✓ TLS configuration deployed!" -ForegroundColor Green
Write-Host ""
Write-Host "Waiting for certificate to be issued (this may take 1-2 minutes)..." -ForegroundColor Cyan
Write-Host "You can check status with:"
Write-Host "  kubectl get certificate -n taprav-fri"
Write-Host "  kubectl describe certificate frontend-tls-cert -n taprav-fri"
Write-Host ""
Write-Host "Once ready, your site will be available at: https://devops-sk-07.lrk.si" -ForegroundColor Green

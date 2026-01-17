# devops-hw-k8s
Web stack deployment using kubernetes

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
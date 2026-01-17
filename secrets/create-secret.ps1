# PowerShell script to create MySQL secret using kubectl (best practice)
# This avoids committing secrets to git

kubectl create secret generic mysql-secret `
  --namespace=taprav-fri `
  --from-literal=mysql-root-password='skrito123' `
  --from-literal=mysql-user='user' `
  --from-literal=mysql-password='skrito123' `
  --from-literal=mysql-database='taprav-fri' `
  --dry-run=client -o yaml | kubectl apply -f -

Write-Host "MySQL secret created successfully in namespace taprav-fri"

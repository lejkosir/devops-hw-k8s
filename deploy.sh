#!/bin/bash
# Complete Kubernetes deployment script for devops-hw-k8s
# Deploy entire application stack with one command
# Usage: bash deploy.sh

set -e

echo "=========================================="
echo "Kubernetes Application Stack Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is configured${NC}"
echo ""

# Step 1: Namespace
echo -e "${YELLOW}1. Creating namespace...${NC}"
kubectl apply -f namespace/namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

# Step 2: MySQL Secret
echo -e "${YELLOW}2. Creating MySQL secret...${NC}"
kubectl create secret generic mysql-secret \
  --namespace=taprav-fri \
  --from-literal=mysql-root-password='skrito123' \
  --from-literal=mysql-user='user' \
  --from-literal=mysql-password='skrito123' \
  --from-literal=mysql-database='taprav-fri' \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ MySQL secret created${NC}"
echo ""

# Step 3: ConfigMaps
echo -e "${YELLOW}3. Creating ConfigMaps...${NC}"
kubectl apply -f configmaps/mysql-initdb.yaml
echo -e "${GREEN}✓ ConfigMaps created${NC}"
echo ""

# Step 4: PersistentVolumes
echo -e "${YELLOW}4. Creating PersistentVolumeClaims...${NC}"
kubectl apply -f volumes/mysql-pvc.yaml
echo -e "${GREEN}✓ PersistentVolumeClaims created${NC}"
echo ""

# Step 5: Services
echo -e "${YELLOW}5. Creating Services...${NC}"
kubectl apply -f services/
echo -e "${GREEN}✓ Services created${NC}"
echo ""

# Step 6: Deploy Redis and MySQL first
echo -e "${YELLOW}6. Deploying infrastructure services (Redis, MySQL)...${NC}"
kubectl apply -f deployments/redis-deployment.yaml
kubectl apply -f deployments/mysql-deployment.yaml
echo -e "${GREEN}✓ Infrastructure services deployed${NC}"
echo ""

# Step 7: Wait for MySQL to be ready
echo -e "${YELLOW}7. Waiting for MySQL to be ready (this may take 1-2 minutes)...${NC}"
if kubectl wait --for=condition=ready pod -l app=mysql -n taprav-fri --timeout=300s 2>/dev/null; then
    echo -e "${GREEN}✓ MySQL is ready${NC}"
else
    echo -e "${RED}Warning: MySQL readiness check timed out, continuing anyway...${NC}"
fi
echo ""

# Step 8: Deploy Backend and Frontend
echo -e "${YELLOW}8. Deploying application services (Backend, Frontend)...${NC}"
kubectl apply -f deployments/backend-deployment.yaml
kubectl apply -f deployments/frontend-deployment.yaml
kubectl apply -f deployments/frontend-green-deployment.yaml
echo -e "${GREEN}✓ Application services deployed${NC}"
echo ""

# Step 9: Configure Ingress LoadBalancer
echo -e "${YELLOW}9. Configuring Ingress Controller as LoadBalancer...${NC}"
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}' 2>/dev/null || echo "Ingress controller already configured"
echo -e "${GREEN}✓ Ingress controller configured${NC}"
echo ""

# Step 10: Get LoadBalancer IP
echo -e "${YELLOW}10. Waiting for LoadBalancer external IP (this may take a few moments)...${NC}"
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✓ LoadBalancer IP: $EXTERNAL_IP${NC}"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 2
done
echo ""

# Step 11: Deploy cert-manager resources
echo -e "${YELLOW}11. Deploying TLS/cert-manager resources...${NC}"
kubectl apply -f cert-manager/cluster-issuer.yaml
kubectl apply -f cert-manager/frontend-certificate.yaml
echo -e "${GREEN}✓ cert-manager resources deployed${NC}"
echo ""

# Step 12: Deploy Ingress
echo -e "${YELLOW}12. Deploying Ingress with TLS...${NC}"
kubectl apply -f ingress/frontend-ingress.yaml
echo -e "${GREEN}✓ Ingress deployed${NC}"
echo ""

# Step 13: Wait for certificate
echo -e "${YELLOW}13. Waiting for TLS certificate to be issued (this may take 1-2 minutes)...${NC}"
for i in {1..60}; do
    CERT_READY=$(kubectl get certificate frontend-tls-cert -n taprav-fri -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    if [ "$CERT_READY" = "True" ]; then
        echo -e "${GREEN}✓ TLS certificate is ready${NC}"
        break
    fi
    echo "  Waiting for certificate... ($i/60)"
    sleep 1
done
echo ""

# Step 14: Verify deployment
echo -e "${YELLOW}14. Verifying deployment...${NC}"
echo ""
echo "Pods in namespace 'taprav-fri':"
kubectl get pods -n taprav-fri
echo ""
echo "Services:"
kubectl get svc -n taprav-fri
echo ""
echo "Ingress:"
kubectl get ingress -n taprav-fri
echo ""
echo "Certificate:"
kubectl get certificate -n taprav-fri
echo ""

echo -e "${GREEN}=========================================="
echo "✓ Deployment complete!"
echo "=========================================="
echo ""
echo "Your application is now available at:"
echo "  HTTP:  http://devops-sk-07.lrk.si"
echo "  HTTPS: https://devops-sk-07.lrk.si"
echo ""
echo "To check certificate status:"
echo "  kubectl describe certificate frontend-tls-cert -n taprav-fri"
echo ""
echo "To monitor pods:"
echo "  kubectl get pods -n taprav-fri -w"
echo ""
echo "To view logs:"
echo "  kubectl logs -n taprav-fri -l app=frontend"
echo "  kubectl logs -n taprav-fri -l app=backend"
echo "  kubectl logs -n taprav-fri -l app=mysql"
echo ""
echo "Blue/Green deployment helpers:"
echo "  bash blue-green/switch-blue-green.sh [blue|green]"
echo "  bash blue-green/check-version.sh"
echo "  bash blue-green/deploy-green.sh <image-tag>"
echo ""

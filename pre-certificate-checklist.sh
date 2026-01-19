#!/bin/bash
# Pre-Certificate Deployment Checklist
# Run this BEFORE attempting to create certificates

echo "=========================================="
echo "PRE-CERTIFICATE DEPLOYMENT CHECKLIST"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# 1. Check kubectl access
echo "✓ 1. Checking kubectl access..."
if kubectl get nodes &>/dev/null; then
    echo "   ✓ kubectl is working"
    kubectl get nodes
    ((PASSED++))
else
    echo "   ✗ kubectl is NOT working"
    ((FAILED++))
fi
echo ""

# 2. Check namespace exists
echo "✓ 2. Checking namespace..."
if kubectl get namespace taprav-fri &>/dev/null; then
    echo "   ✓ Namespace 'taprav-fri' exists"
    ((PASSED++))
else
    echo "   ✗ Namespace 'taprav-fri' does NOT exist"
    echo "   Fix: kubectl apply -f namespace/namespace.yaml"
    ((FAILED++))
fi
echo ""

# 3. Check cert-manager is installed
echo "✓ 3. Checking cert-manager installation..."
if kubectl get namespace cert-manager &>/dev/null; then
    echo "   ✓ cert-manager namespace exists"
    CERT_MANAGER_PODS=$(kubectl get pods -n cert-manager -l app.kubernetes.io/instance=cert-manager --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$CERT_MANAGER_PODS" -gt 0 ]; then
        echo "   ✓ cert-manager pods are running ($CERT_MANAGER_PODS pod(s))"
        kubectl get pods -n cert-manager -l app.kubernetes.io/instance=cert-manager
        ((PASSED++))
    else
        echo "   ✗ cert-manager pods are NOT running"
        echo "   Fix: Install cert-manager first"
        ((FAILED++))
    fi
else
    echo "   ✗ cert-manager namespace does NOT exist"
    echo "   Fix: Install cert-manager: kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml"
    ((FAILED++))
fi
echo ""

# 4. Check ClusterIssuer is ready
echo "✓ 4. Checking ClusterIssuer..."
if kubectl get clusterissuer letsencrypt-prod &>/dev/null; then
    echo "   ✓ ClusterIssuer 'letsencrypt-prod' exists"
    STATUS=$(kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$STATUS" = "True" ]; then
        echo "   ✓ ClusterIssuer is Ready"
        ((PASSED++))
    else
        echo "   ⚠ ClusterIssuer exists but status is: $STATUS"
        kubectl describe clusterissuer letsencrypt-prod | grep -A 5 "Status:"
        ((FAILED++))
    fi
else
    echo "   ✗ ClusterIssuer 'letsencrypt-prod' does NOT exist"
    echo "   Fix: kubectl apply -f cert-manager/cluster-issuer.yaml"
    ((FAILED++))
fi
echo ""

# 5. Check Ingress Controller is running
echo "✓ 5. Checking Ingress Controller..."
INGRESS_PODS=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -c Running || echo "0")
if [ "$INGRESS_PODS" -gt 0 ]; then
    echo "   ✓ Ingress controller is running ($INGRESS_PODS pod(s))"
    kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller
    ((PASSED++))
else
    echo "   ✗ Ingress controller is NOT running"
    echo "   Fix: minikube addons enable ingress"
    ((FAILED++))
fi
echo ""

# 6. Check HTTP is working (port 80)
echo "✓ 6. Checking HTTP access (port 80)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://devops-sk-07.lrk.si 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "308" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "   ✓ HTTP (port 80) is accessible (status: $HTTP_STATUS)"
    ((PASSED++))
else
    echo "   ✗ HTTP (port 80) is NOT accessible (status: $HTTP_STATUS)"
    echo "   Fix: Ensure ingress is working and service is accessible"
    ((FAILED++))
fi
echo ""

# 7. Check LoadBalancer for HTTPS
echo "✓ 7. Checking HTTPS exposure..."
INGRESS_SVC_TYPE=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].spec.type}' 2>/dev/null || echo "None")
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ "$INGRESS_SVC_TYPE" = "LoadBalancer" ]; then
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "<pending>" ]; then
        echo "   ✓ Ingress service is LoadBalancer with IP: $EXTERNAL_IP"
        echo "   ✓ HTTPS should be accessible via: https://devops-sk-07.lrk.si"
        ((PASSED++))
    else
        echo "   ⚠ Ingress service is LoadBalancer but IP is pending"
        echo "   Note: On minikube, run 'sudo minikube tunnel' to get external IP"
        echo "   Note: On cloud providers, wait for LoadBalancer to provision"
        ((FAILED++))
    fi
else
    echo "   ✗ Ingress service type is: $INGRESS_SVC_TYPE (should be LoadBalancer)"
    echo "   Fix: Change ingress controller service to LoadBalancer type"
    echo "   Run: kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
    ((FAILED++))
fi
echo ""

# 8. Check ports 80 and 443 are accessible
echo "✓ 8. Checking port accessibility..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://devops-sk-07.lrk.si 2>/dev/null || echo "000")
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k https://devops-sk-07.lrk.si 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "308" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "   ✓ Port 80 (HTTP) is accessible (status: $HTTP_STATUS)"
    ((PASSED++))
else
    echo "   ✗ Port 80 (HTTP) is NOT accessible (status: $HTTP_STATUS)"
    echo "   Fix: Ensure LoadBalancer has external IP and port 80 is routed"
    ((FAILED++))
fi

if [ "$HTTPS_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "308" ] || [ "$HTTPS_STATUS" = "301" ] || [ "$HTTPS_STATUS" = "302" ]; then
    echo "   ✓ Port 443 (HTTPS) is accessible (status: $HTTPS_STATUS)"
    ((PASSED++))
else
    echo "   ⚠ Port 443 (HTTPS) is NOT accessible (status: $HTTPS_STATUS)"
    echo "   Note: This is expected before certificate is issued"
    ((PASSED++))
fi
echo ""

# 9. Check Ingress resource is configured
echo "✓ 9. Checking Ingress resource..."
if kubectl get ingress frontend-ingress -n taprav-fri &>/dev/null; then
    echo "   ✓ Ingress 'frontend-ingress' exists"
    TLS_CONFIGURED=$(kubectl get ingress frontend-ingress -n taprav-fri -o yaml | grep -c "tls:" || echo "0")
    if [ "$TLS_CONFIGURED" -gt 0 ]; then
        echo "   ✓ Ingress has TLS section configured"
        ((PASSED++))
    else
        echo "   ⚠ Ingress exists but TLS section missing (will be added by certificate)"
        ((PASSED++))
    fi
else
    echo "   ✗ Ingress 'frontend-ingress' does NOT exist"
    echo "   Fix: kubectl apply -f ingress/frontend-ingress.yaml"
    ((FAILED++))
fi
echo ""

# 10. Check no existing certificate conflicts
echo "✓ 10. Checking for existing certificates..."
EXISTING_CERT=$(kubectl get certificate -n taprav-fri 2>/dev/null | grep -c "frontend-tls-cert" || echo "0")
if [ "$EXISTING_CERT" -eq 0 ]; then
    echo "   ✓ No existing certificate (safe to create new one)"
    ((PASSED++))
else
    echo "   ⚠ Existing certificate found - will need to delete first"
    kubectl get certificate -n taprav-fri
    ((FAILED++))
fi
echo ""

# 11. Check domain DNS (if possible)
echo "✓ 11. Checking domain resolution..."
if host devops-sk-07.lrk.si &>/dev/null; then
    DOMAIN_IP=$(host devops-sk-07.lrk.si | grep -oP 'has address \K[0-9.]+' | head -1)
    echo "   ✓ Domain resolves to: $DOMAIN_IP"
    ((PASSED++))
else
    echo "   ⚠ Cannot verify DNS resolution (may still work)"
    ((PASSED++))
fi
echo ""

# Summary
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed/Warnings: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED!"
    echo ""
    echo "You are ready to create the certificate:"
    echo "  kubectl apply -f cert-manager/frontend-certificate.yaml"
else
    echo "❌ SOME CHECKS FAILED"
    echo ""
    echo "Fix the issues above before creating certificates."
    echo "DO NOT create certificates until all checks pass!"
fi
echo ""

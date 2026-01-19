#!/bin/bash
# Script to configure Nginx Ingress Controller service as LoadBalancer
# This is required for TLS/HTTPS to work properly

set -e

echo "=========================================="
echo "Configuring Ingress Controller as LoadBalancer"
echo "=========================================="
echo ""

# Check if ingress-nginx namespace exists
if ! kubectl get namespace ingress-nginx &>/dev/null; then
    echo "❌ Error: ingress-nginx namespace not found"
    echo "Please install Nginx Ingress Controller first:"
    echo "  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml"
    exit 1
fi

# Get current service type
CURRENT_TYPE=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.type}' 2>/dev/null || echo "None")

if [ "$CURRENT_TYPE" = "LoadBalancer" ]; then
    echo "✓ Ingress controller service is already configured as LoadBalancer"
    
    # Check if external IP is assigned
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "<pending>" ]; then
        echo "✓ External IP assigned: $EXTERNAL_IP"
        echo ""
        echo "Service details:"
        kubectl get svc -n ingress-nginx ingress-nginx-controller
    else
        echo "⚠ External IP is pending..."
        echo ""
        echo "On minikube, run this in a separate terminal:"
        echo "  sudo minikube tunnel"
        echo ""
        echo "On cloud providers, wait for the LoadBalancer to provision."
        echo ""
        echo "Current service status:"
        kubectl get svc -n ingress-nginx ingress-nginx-controller
    fi
else
    echo "Current service type: $CURRENT_TYPE"
    echo "Changing to LoadBalancer..."
    
    # Patch the service
    kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully changed service type to LoadBalancer"
        echo ""
        echo "Service details:"
        kubectl get svc -n ingress-nginx ingress-nginx-controller
        echo ""
        
        # Check for external IP
        EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "<pending>" ]; then
            echo ""
            echo "⚠ External IP is pending..."
            echo ""
            echo "On minikube, run this in a separate terminal:"
            echo "  sudo minikube tunnel"
            echo ""
            echo "On cloud providers, wait for the LoadBalancer to provision."
            echo "You can watch the service status with:"
            echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller -w"
        else
            echo "✓ External IP assigned: $EXTERNAL_IP"
            echo ""
            echo "⚠ IMPORTANT: Ensure your domain DNS points to this IP:"
            echo "  devops-sk-07.lrk.si -> $EXTERNAL_IP"
        fi
    else
        echo "❌ Failed to change service type"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Ensure domain DNS points to the external IP"
echo "2. Verify ports 80 and 443 are accessible"
echo "3. Run pre-certificate-checklist.sh to verify setup"
echo "4. Deploy TLS certificate: kubectl apply -f cert-manager/frontend-certificate.yaml"
echo ""

#!/bin/bash
# Diagnostic script to check LoadBalancer support and diagnose issues

echo "=========================================="
echo "LoadBalancer Support Diagnostics"
echo "=========================================="
echo ""

# 1. Check current service status
echo "1. Current Ingress Controller Service Status:"
echo "--------------------------------------------"
kubectl get svc -n ingress-nginx ingress-nginx-controller 2>/dev/null || echo "❌ Service not found"
echo ""

# 2. Check service events (this shows why it's pending)
echo "2. Service Events (why it's pending):"
echo "--------------------------------------------"
kubectl describe svc -n ingress-nginx ingress-nginx-controller 2>/dev/null | grep -A 20 "Events:" || echo "No events found"
echo ""

# 3. Check if LoadBalancer controller exists
echo "3. Checking for LoadBalancer Controllers:"
echo "--------------------------------------------"

# Check for MetalLB
if kubectl get namespace metallb-system &>/dev/null 2>&1; then
    echo "✓ MetalLB namespace exists"
    METALLB_PODS=$(kubectl get pods -n metallb-system --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$METALLB_PODS" -gt 0 ]; then
        echo "✓ MetalLB pods are running ($METALLB_PODS pod(s))"
        kubectl get pods -n metallb-system
    else
        echo "⚠ MetalLB namespace exists but no running pods"
    fi
else
    echo "✗ MetalLB not found"
fi
echo ""

# Check for cloud provider LoadBalancer controller
echo "Checking for cloud provider LoadBalancer controllers..."
CLOUD_CONTROLLERS=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -iE "(cloud|loadbalancer|lb)" || echo "")
if [ -n "$CLOUD_CONTROLLERS" ]; then
    echo "Found potential LoadBalancer controllers:"
    echo "$CLOUD_CONTROLLERS"
else
    echo "No obvious cloud LoadBalancer controllers found"
fi
echo ""

# 4. Check cluster info for cloud provider hints
echo "4. Cluster Information:"
echo "--------------------------------------------"
kubectl cluster-info 2>/dev/null | head -5
echo ""

# Check node labels for cloud provider
echo "Node provider information:"
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.cloud\.google\.com/gke-instance-group}{"\t"}{.metadata.labels.kubernetes\.io/instance-type}{"\t"}{.metadata.labels.eks\.amazonaws\.com/nodegroup}{"\n"}{end}' 2>/dev/null | head -5
echo ""

# 5. Check service spec and status
echo "5. Detailed Service Information:"
echo "--------------------------------------------"
kubectl get svc -n ingress-nginx ingress-nginx-controller -o yaml 2>/dev/null | grep -A 10 "spec:" | head -15
echo ""
kubectl get svc -n ingress-nginx ingress-nginx-controller -o yaml 2>/dev/null | grep -A 10 "status:" | head -15
echo ""

# 6. Check for service annotations that might help
echo "6. Service Annotations:"
echo "--------------------------------------------"
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.metadata.annotations}' 2>/dev/null | jq '.' 2>/dev/null || kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.metadata.annotations}' 2>/dev/null
echo ""
echo ""

# 7. Check if there are other LoadBalancer services working
echo "7. Other LoadBalancer Services in Cluster:"
echo "--------------------------------------------"
OTHER_LB=$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}' 2>/dev/null)
if [ -n "$OTHER_LB" ]; then
    echo "Found other LoadBalancer services:"
    echo "NAMESPACE    NAME    EXTERNAL-IP"
    echo "$OTHER_LB"
    echo ""
    echo "✓ LoadBalancer type IS supported (other services have external IPs)"
else
    echo "No other LoadBalancer services found"
    echo "⚠ This might indicate LoadBalancer is not supported, OR no other services use it"
fi
echo ""

# 8. Check ingress controller installation method
echo "8. Ingress Controller Installation:"
echo "--------------------------------------------"
INGRESS_DEPLOYMENT=$(kubectl get deployment -n ingress-nginx ingress-nginx-controller -o yaml 2>/dev/null | grep -i "image:" | head -1)
if [ -n "$INGRESS_DEPLOYMENT" ]; then
    echo "Ingress controller image:"
    echo "$INGRESS_DEPLOYMENT"
    echo ""
    echo "Ingress controller pods:"
    kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller
else
    echo "Could not find ingress controller deployment"
fi
echo ""

# 9. Check for service load balancer class
echo "9. Service LoadBalancer Class:"
echo "--------------------------------------------"
LB_CLASS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.loadBalancerClass}' 2>/dev/null)
if [ -n "$LB_CLASS" ]; then
    echo "LoadBalancerClass: $LB_CLASS"
else
    echo "No LoadBalancerClass specified (using default)"
fi
echo ""

# 10. Summary and recommendations
echo "=========================================="
echo "Summary and Recommendations"
echo "=========================================="
echo ""

SVC_TYPE=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.type}' 2>/dev/null || echo "None")
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ "$SVC_TYPE" = "LoadBalancer" ]; then
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "<pending>" ]; then
        echo "⚠ Status: Service is LoadBalancer type but external IP is pending"
        echo ""
        echo "Possible causes:"
        echo "1. No LoadBalancer controller installed (MetalLB, cloud provider, etc.)"
        echo "2. LoadBalancer controller is not working properly"
        echo "3. Network/firewall issues preventing IP assignment"
        echo "4. Cluster doesn't support LoadBalancer type"
        echo ""
        echo "Recommendations:"
        echo "- Check service events above for specific error messages"
        echo "- Contact your instructor/system admin about LoadBalancer support"
        echo "- If on bare-metal, MetalLB might need to be installed"
        echo "- Check if other LoadBalancer services work (see section 7 above)"
    else
        echo "✓ LoadBalancer is working! External IP: $EXTERNAL_IP"
    fi
else
    echo "⚠ Service type is: $SVC_TYPE (should be LoadBalancer)"
    echo "Run: kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
fi

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Review the events above to see why LoadBalancer is pending"
echo "2. Check if MetalLB or cloud LoadBalancer controller needs to be installed"
echo "3. Contact your instructor if LoadBalancer support is expected but not working"
echo "4. If LoadBalancer is not supported, you may need to use NodePort with external routing"
echo ""

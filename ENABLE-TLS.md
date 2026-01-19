# Enable TLS/HTTPS on School VM

This guide helps you enable TLS/HTTPS for an **already deployed** application on the school VM.

## Quick Steps

### 1. Configure Ingress Controller as LoadBalancer

```bash
# Check current service type
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Change to LoadBalancer (if not already)
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'
```

**⚠ IMPORTANT: If you're on minikube (which the diagnostic shows), you MUST run `minikube tunnel`:**

```bash
# Run this in a SEPARATE terminal (keep it running)
sudo minikube tunnel
```

**Why?** On minikube, LoadBalancer services don't automatically get external IPs. The `minikube tunnel` command creates a network route that assigns external IPs to LoadBalancer services.

**After running `minikube tunnel`, check the service:**
```bash
# In another terminal, watch the service
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

You should see the EXTERNAL-IP change from `<pending>` to an IP address (usually `127.0.0.1` or a local IP).

**Or use the helper script:**
```bash
bash setup-loadbalancer.sh
```

**Note:** The script will tell you to run `minikube tunnel` if it detects minikube.

### 2. Get the External IP

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Look for the `EXTERNAL-IP` column. It should show an IP address (not `<pending>`).

**Example output:**
```
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.96.xxx.xxx   192.168.xxx.xxx   80:xxxxx/TCP,443:xxxxx/TCP   5m
```

### 3. Verify DNS Points to External IP

```bash
# Check what IP your domain resolves to
nslookup devops-sk-07.lrk.si

# The IP should match the EXTERNAL-IP from step 2
```

**If DNS doesn't match:**
- Contact your instructor to update DNS records
- DNS should point `devops-sk-07.lrk.si` → LoadBalancer external IP

### 4. Verify Port 80 is Accessible

```bash
# Test HTTP access (should work)
curl -I http://devops-sk-07.lrk.si

# Should return HTTP 200, 301, 302, or 308
```

If this fails, the LoadBalancer or DNS might not be configured correctly.

### 5. Run Pre-Certificate Checklist

```bash
bash pre-certificate-checklist.sh
```

This will verify:
- ✅ LoadBalancer is configured
- ✅ External IP is assigned
- ✅ Port 80 is accessible
- ✅ cert-manager is ready
- ✅ ClusterIssuer is configured

**Fix any issues** before proceeding to the next step.

### 6. Deploy TLS Certificate

```bash
# Apply ClusterIssuer (if not already applied)
kubectl apply -f cert-manager/cluster-issuer.yaml

# Deploy the certificate
kubectl apply -f cert-manager/frontend-certificate.yaml
```

### 7. Monitor Certificate Issuance

```bash
# Watch certificate status
kubectl get certificate -n taprav-fri -w

# Or check details
kubectl describe certificate frontend-tls-cert -n taprav-fri
```

**Certificate issuance takes 1-5 minutes.** Look for:
- `READY = True` in `kubectl get certificate`
- `Status: Ready` in the describe output

### 8. Verify HTTPS Works

```bash
# Test HTTPS
curl -I https://devops-sk-07.lrk.si

# Should return HTTP 200 (not certificate errors)
```

### 9. Verify Ingress is Configured

```bash
# Check ingress has TLS configured
kubectl get ingress -n taprav-fri

# Check details
kubectl describe ingress frontend-ingress -n taprav-fri
```

The ingress should show:
- TLS section with `devops-sk-07.lrk.si`
- Secret `frontend-tls-secret` is bound

---

## Troubleshooting

### LoadBalancer External IP is Pending

**First, run diagnostics:**
```bash
bash check-loadbalancer-support.sh
```

**If the diagnostic shows "minikube":**

**You MUST run `minikube tunnel` for LoadBalancer to work on minikube!**

```bash
# Run this in a SEPARATE terminal (keep it running in background)
sudo minikube tunnel

# Or run it in background:
sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
```

**After starting `minikube tunnel`, check the service:**
```bash
# Wait a few seconds, then check
kubectl get svc -n ingress-nginx ingress-nginx-controller

# You should see EXTERNAL-IP change from <pending> to an IP (usually 127.0.0.1 or local IP)
```

**Why?** Minikube doesn't have a built-in LoadBalancer controller. The `minikube tunnel` command creates a network route that assigns external IPs to LoadBalancer services.

**If NOT on minikube:**
- Wait 1-5 minutes for cloud LoadBalancer provisioning
- Check service events: `kubectl describe svc -n ingress-nginx ingress-nginx-controller | grep -A 20 "Events:"`
- Check if MetalLB is installed: `kubectl get namespace metallb-system`
- Contact your instructor if still pending after 10 minutes

### Certificate Not Issuing

**Check certificate status:**
```bash
kubectl describe certificate frontend-tls-cert -n taprav-fri
```

**Check cert-manager logs:**
```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

**Common issues:**

1. **HTTP-01 challenge fails:**
   - Ensure port 80 is accessible: `curl -I http://devops-sk-07.lrk.si`
   - Verify DNS points to LoadBalancer IP: `nslookup devops-sk-07.lrk.si`
   - Check firewall allows port 80

2. **Rate limiting:**
   - Let's Encrypt has rate limits (5 certs per domain per week)
   - Use staging issuer for testing:
     ```bash
     kubectl apply -f cert-manager/cluster-issuer-staging.yaml
     # Update certificate.yaml to use staging issuer
     ```

3. **DNS not propagated:**
   - Wait up to 48 hours for DNS changes
   - Verify DNS: `nslookup devops-sk-07.lrk.si`

### HTTPS Returns Certificate Error

**Check certificate is ready:**
```bash
kubectl get certificate -n taprav-fri
# Should show READY = True
```

**Check secret exists:**
```bash
kubectl get secret frontend-tls-secret -n taprav-fri
```

**If certificate is not ready, wait and check:**
```bash
kubectl describe certificate frontend-tls-cert -n taprav-fri
```

### Port 80 Not Accessible

**Verify LoadBalancer:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

**Test from VM:**
```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test directly
curl -I http://$EXTERNAL_IP
```

**If this works but domain doesn't:**
- DNS issue - verify DNS points to external IP
- Firewall issue - port 80 might be blocked

---

## Quick Verification Commands

```bash
# Check LoadBalancer
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check certificate
kubectl get certificate -n taprav-fri
kubectl describe certificate frontend-tls-cert -n taprav-fri

# Check ingress
kubectl get ingress -n taprav-fri
kubectl describe ingress frontend-ingress -n taprav-fri

# Test HTTP
curl -I http://devops-sk-07.lrk.si

# Test HTTPS
curl -I https://devops-sk-07.lrk.si

# Check DNS
nslookup devops-sk-07.lrk.si
```

---

## Expected Timeline

1. **LoadBalancer provisioning:** 1-5 minutes
2. **Certificate issuance:** 1-5 minutes (after LoadBalancer is ready)
3. **Total time:** 2-10 minutes

---

## Success Indicators

✅ LoadBalancer has external IP (not `<pending>`)  
✅ DNS points to LoadBalancer IP  
✅ HTTP is accessible: `curl -I http://devops-sk-07.lrk.si` returns 200/301/302  
✅ Certificate shows `READY = True`  
✅ HTTPS is accessible: `curl -I https://devops-sk-07.lrk.si` returns 200  
✅ Browser shows valid certificate (green lock icon)

---

## One-Liner Commands

**Complete TLS setup (if everything is ready):**
```bash
kubectl patch svc -n ingress-nginx ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}' && \
sleep 30 && \
kubectl apply -f cert-manager/cluster-issuer.yaml && \
kubectl apply -f cert-manager/frontend-certificate.yaml && \
echo "Certificate deployment initiated. Monitor with: kubectl get certificate -n taprav-fri -w"
```

**Check everything:**
```bash
echo "=== LoadBalancer ===" && \
kubectl get svc -n ingress-nginx ingress-nginx-controller && \
echo -e "\n=== Certificate ===" && \
kubectl get certificate -n taprav-fri && \
echo -e "\n=== Ingress ===" && \
kubectl get ingress -n taprav-fri && \
echo -e "\n=== HTTP Test ===" && \
curl -I http://devops-sk-07.lrk.si 2>&1 | head -1 && \
echo -e "\n=== HTTPS Test ===" && \
curl -I https://devops-sk-07.lrk.si 2>&1 | head -1
```

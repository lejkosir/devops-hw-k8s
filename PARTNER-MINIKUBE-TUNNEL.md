# Partner: Test Minikube Tunnel

## Quick Test

If you started the minikube cluster, you should have the minikube profile. Test if `minikube tunnel` works:

### Step 1: Check if you have the profile

```bash
minikube profile list
```

If you see a profile (usually "minikube"), continue. If not, let your partner know.

### Step 2: Start minikube tunnel

**Option A: Run in background (recommended)**
```bash
sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
```

**Option B: Run in foreground (keep terminal open)**
```bash
sudo minikube tunnel
```

### Step 3: Verify it works

**In another terminal, check if LoadBalancer got an IP:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

**Expected result:**
- `EXTERNAL-IP` should change from `<pending>` to an IP address (usually `127.0.0.1` or similar)
- This should happen within 10-30 seconds

### Step 4: Check if tunnel is running

```bash
# Check if tunnel process is running
ps aux | grep "minikube tunnel"

# Check tunnel logs (if ran in background)
tail -f /tmp/minikube-tunnel.log
```

## Success Indicators

✅ `minikube profile list` shows a profile  
✅ Tunnel starts without errors  
✅ LoadBalancer `EXTERNAL-IP` is not `<pending>`  
✅ Tunnel process stays running

## If It Works

**Keep the tunnel running!** The LoadBalancer needs it to stay active.

**To keep it running in background:**
```bash
# Already done if you used Option A above
# Check it's still running:
ps aux | grep "minikube tunnel"
```

**To stop it later:**
```bash
sudo pkill -f "minikube tunnel"
```

## If It Doesn't Work

If you get errors or the LoadBalancer stays `<pending>`, let your partner know and we'll use MetalLB instead.

## Troubleshooting

**Tunnel dies immediately:**
- Check logs: `tail -20 /tmp/minikube-tunnel.log`
- Verify profile exists: `minikube profile list`
- Try: `sudo minikube tunnel --alsologtostderr` for more details

**LoadBalancer still pending after 30 seconds:**
- Check tunnel is running: `ps aux | grep "minikube tunnel"`
- Check tunnel logs for errors
- Verify service type: `kubectl get svc -n ingress-nginx ingress-nginx-controller`

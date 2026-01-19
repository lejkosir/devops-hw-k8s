# Using Partner's Minikube Profile

## Yes, If Your Partner Started the Cluster

If your partner started the minikube cluster, they have the minikube profile/config. Here are your options:

## Option 1: Partner Runs `minikube tunnel` (Temporary Solution)

**Your partner can run:**
```bash
sudo minikube tunnel
```

**Important considerations:**
- ✅ Will work immediately (they have the profile)
- ⚠️ Must stay running continuously
- ⚠️ If they disconnect/close terminal, tunnel stops
- ⚠️ LoadBalancer IP goes back to `<pending>` when tunnel stops
- ⚠️ Not ideal for long-term use

**Better approach:** Run it in background so it persists:
```bash
# Partner runs this:
sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &

# Check if it's running:
ps aux | grep "minikube tunnel"

# Check logs:
tail -f /tmp/minikube-tunnel.log
```

## Option 2: Share Minikube Config (Better Solution)

**Your partner can share their minikube profile with you:**

### Step 1: Partner Copies Their Minikube Config

```bash
# Partner runs this to create a tarball of their minikube config
cd ~
tar -czf minikube-config.tar.gz .minikube/

# Or if started by root:
sudo tar -czf /tmp/minikube-config.tar.gz /root/.minikube/
```

### Step 2: Transfer to Your Account

```bash
# Partner copies it to a shared location or transfers it
# For example, if you share the same VM:
sudo cp /root/.minikube /home/mbokal/.minikube -r
# Or
sudo chown -R mbokal:mbokal /home/mbokal/.minikube
```

### Step 3: You Use the Config

```bash
# Set MINIKUBE_HOME to point to the config
export MINIKUBE_HOME=~/.minikube

# Or use it directly
sudo MINIKUBE_HOME=~/.minikube minikube tunnel
```

## Option 3: Use Root's Minikube Config (If Started by Root)

**If the cluster was started by root (sudo), you can use root's config directly:**

```bash
# Use root's minikube config directly (DON'T copy it)
sudo MINIKUBE_HOME=/root/.minikube minikube tunnel
```

**If that doesn't work, check what profile name exists:**
```bash
# Check what profiles exist
bash check-minikube-profile.sh

# Or manually:
sudo ls -la /root/.minikube/profiles/

# Then use the actual profile name:
sudo MINIKUBE_HOME=/root/.minikube minikube tunnel -p <actual-profile-name>
```

**Note:** Copying the config sometimes doesn't work due to minikube version differences or internal references. Using `MINIKUBE_HOME` directly is more reliable.

## Option 4: Check Who Actually Started It

**First, figure out who started the cluster:**

```bash
# Check if root has minikube config
sudo ls -la /root/.minikube/

# Check your partner's user (replace 'partner-username' with actual username)
ls -la /home/partner-username/.minikube/

# Check your user
ls -la ~/.minikube/
```

**Whoever has the `.minikube` directory is the one who started it.**

## Recommended Approach

### For Immediate Testing:
1. **Partner runs `minikube tunnel`** (or you use root's config)
2. Verify LoadBalancer gets IP
3. Deploy TLS certificate
4. Test HTTPS

### For Long-term Solution:
1. **Copy minikube config to your account** (Option 2 or 3)
2. Or **install MetalLB** (works for everyone, no tunnel needed)
3. Or **set up a systemd service** to keep tunnel running

## Quick Test: Use Root's Config

**Try this first (easiest):**
```bash
# Check if root has the config
sudo ls -la /root/.minikube/

# If yes, use it:
sudo MINIKUBE_HOME=/root/.minikube minikube tunnel
```

**In another terminal, check if it works:**
```bash
watch kubectl get svc -n ingress-nginx ingress-nginx-controller
```

If the EXTERNAL-IP changes from `<pending>` to an IP, it's working!

## Alternative: MetalLB (Works for Everyone)

**If sharing config is complicated, use MetalLB instead:**
- ✅ Works for all users
- ✅ No need for tunnel
- ✅ Persistent (doesn't need to stay running)
- ✅ More production-like

```bash
bash install-metallb.sh
```

## Summary

**Yes, if your partner started it:**
- They can run `minikube tunnel` and it will work
- But it needs to stay running
- Better: share the config so you can use it too
- Or: use MetalLB (works for everyone)

**Quick test:** Try `sudo MINIKUBE_HOME=/root/.minikube minikube tunnel` first - this often works if the cluster was started with sudo.

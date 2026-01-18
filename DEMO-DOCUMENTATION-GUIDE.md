# Demo Documentation Guide - Rolling Update & Blue/Green Deployment

This guide explains how to document your rolling update and blue/green deployment demonstrations for the assignment.

## Requirements from Assignment

- Screenshots (or link to video/recorded terminal session like asciinema)
- Demonstrate 0-downtime upgrade
- Rolling update and/or blue/green deployment
- Service must have multiple active replicas (frontend has 3)

---

## Demo 1: Rolling Update

### What to Demonstrate

Show that during a rolling update:
- Service remains available (0-downtime)
- Pods are updated one at a time
- Always maintains minimum replicas (3 pods available)

### Step-by-Step Demo Process

#### 1. Prepare Two Different Versions

**Make a visual change in source code:**
```bash
# In devops-spletna repo
cd code/taprav-fri/frontend
# Change a color (e.g., header background color)
# Commit and push
git add .
git commit -m "Change color for rolling update demo"
git push origin relative
```

**Trigger Docker build:**
```bash
# In DN02-docker repo
git commit --allow-empty -m "Trigger build for rolling update demo"
git push
```

**Wait for CI/CD to finish, get new SHA tag** (e.g., `sha-abc123`)

#### 2. Start Recording/Screenshots

**Option A: Record terminal session (asciinema)**
```bash
# Install asciinema if needed
# On VM:
asciinema rec rolling-update-demo.cast
```

**Option B: Take screenshots at key moments**

#### 3. Perform Rolling Update

**Open multiple terminal windows/tabs:**

**Terminal 1: Watch pods during update**
```bash
watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend,version=blue -o wide'
```

**Terminal 2: Continuous requests to verify 0-downtime**
```bash
# Keep making requests to see service stays up
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" https://devops-sk-07.lrk.si
  sleep 0.5
done
```

**Terminal 3: Perform the update**
```bash
# Update the image
kubectl set image deployment/frontend-blue \
  frontend=ghcr.io/lejkosir/devops-hw-docker-frontend:sha-abc123 \
  -n taprav-fri

# Watch rollout status
kubectl rollout status deployment/frontend-blue -n taprav-fri
```

#### 4. What to Capture

**Screenshots/Recordings should show:**

1. **Before update:**
   - All 3 pods running old version
   - Service responding (200 OK)

2. **During update:**
   - 4 pods total (3 old + 1 new) - shows maxSurge: 1
   - Service still responding (200 OK) - shows 0-downtime
   - Pods being replaced one by one

3. **After update:**
   - All 3 pods running new version
   - Service still responding (200 OK)

**Key commands to show:**
```bash
# Show current pods
kubectl get pods -n taprav-fri -l app=frontend,version=blue

# Show rollout history
kubectl rollout history deployment/frontend-blue -n taprav-fri

# Show service is still responding
curl -I https://devops-sk-07.lrk.si
```

---

## Demo 2: Blue/Green Deployment

### What to Demonstrate

Show that during blue/green:
- Two complete environments run simultaneously
- Traffic switches instantly from blue to green
- Zero downtime during switch
- Easy rollback capability

### Step-by-Step Demo Process

#### 1. Prepare Two Different Versions

**Make a visual change (different from rolling update):**
```bash
# In devops-spletna repo
cd code/taprav-fri/frontend
# Change a different color or add version indicator
# Commit and push
git add .
git commit -m "Change color for blue/green demo"
git push origin relative
```

**Trigger Docker build and get new SHA tag** (e.g., `sha-xyz789`)

#### 2. Start Recording/Screenshots

```bash
asciinema rec blue-green-demo.cast
# OR take screenshots
```

#### 3. Perform Blue/Green Deployment

**Terminal 1: Watch all frontend pods**
```bash
watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend'
```

**Terminal 2: Monitor service responses**
```bash
# Keep checking which version is serving
while true; do
  curl -s https://devops-sk-07.lrk.si | grep -o "v[0-9]\.[0-9]" || echo "checking..."
  sleep 1
done
```

**Terminal 3: Perform blue/green deployment**
```bash
# 1. Check current version
./blue-green/check-version.sh
# Should show: Active version: blue

# 2. Deploy new version to green
./blue-green/deploy-green.sh sha-xyz789

# 3. Verify green pods are ready
kubectl get pods -n taprav-fri -l app=frontend,version=green

# 4. (Optional) Test green directly before switching
kubectl port-forward -n taprav-fri deployment/frontend-green 3001:3000
# Test in browser, then Ctrl+C

# 5. Switch traffic to green
./blue-green/switch-blue-green.sh green

# 6. Verify switch
./blue-green/check-version.sh
# Should show: Active version: green

# 7. (Optional) Rollback to blue
./blue-green/switch-blue-green.sh blue
```

#### 4. What to Capture

**Screenshots/Recordings should show:**

1. **Initial state:**
   - Blue pods running (3 pods)
   - Green pods running (3 pods) - but not receiving traffic
   - Service pointing to blue

2. **After deploying to green:**
   - Green pods updated with new image
   - Blue still serving traffic

3. **During switch:**
   - Command: `./blue-green/switch-blue-green.sh green`
   - Service selector changes instantly
   - Traffic switches to green

4. **After switch:**
   - Green pods receiving traffic
   - Blue pods still running (for rollback)
   - Service responding with new version

5. **Rollback (optional):**
   - Switch back to blue
   - Traffic returns to blue instantly

**Key commands to show:**
```bash
# Show both blue and green pods
kubectl get pods -n taprav-fri -l app=frontend

# Show service selector
kubectl get service frontend -n taprav-fri -o yaml | grep -A 2 selector

# Check which version is active
./blue-green/check-version.sh
```

---

## Documentation Format for README

Add a section to your README like this:

```markdown
## Deployment Demonstrations

### Rolling Update

[Description of what rolling update is and why you chose these parameters]

**Configuration:**
- Service: Frontend (3 replicas)
- Strategy: RollingUpdate
- maxSurge: 1 (allows 1 extra pod during update)
- maxUnavailable: 0 (always maintains 3 available pods)

**Demo Steps:**
1. [Brief description]
2. [Brief description]
3. [Brief description]

**Screenshots/Recording:**
- [Link to asciinema recording OR screenshots]
- Screenshot 1: Before update (3 pods running)
- Screenshot 2: During update (4 pods, one being replaced)
- Screenshot 3: After update (3 pods with new version)
- Screenshot 4: Service responding throughout (0-downtime proof)

### Blue/Green Deployment

[Description of blue/green deployment and why it's useful]

**Configuration:**
- Blue deployment: frontend-blue (3 replicas)
- Green deployment: frontend-green (3 replicas)
- Service selector switches between versions

**Demo Steps:**
1. [Brief description]
2. [Brief description]
3. [Brief description]

**Screenshots/Recording:**
- [Link to asciinema recording OR screenshots]
- Screenshot 1: Both blue and green running
- Screenshot 2: Deploying new version to green
- Screenshot 3: Switching traffic to green
- Screenshot 4: Green serving traffic, blue still available
- Screenshot 5: Rollback to blue (optional)
```

---

## Tools for Recording

### Option 1: Asciinema (Recommended)
```bash
# Install
sudo apt install asciinema  # or download from asciinema.org

# Record
asciinema rec demo.cast

# Upload and get link
asciinema upload demo.cast
# Copy the URL and add to README
```

### Option 2: Screen Recording
- Use OBS Studio, SimpleScreenRecorder, or built-in screen recorder
- Record terminal windows showing the commands
- Upload to YouTube or similar, link in README

### Option 3: Screenshots
- Take screenshots at key moments
- Use a tool like `scrot` or built-in screenshot
- Organize in a folder and reference in README

---

## Quick Reference: Commands for Demo

### Rolling Update
```bash
# Watch pods
watch -n 1 'kubectl get pods -n taprav-fri -l app=frontend,version=blue'

# Update image
kubectl set image deployment/frontend-blue \
  frontend=ghcr.io/lejkosir/devops-hw-docker-frontend:sha-NEWTAG \
  -n taprav-fri

# Watch rollout
kubectl rollout status deployment/frontend-blue -n taprav-fri

# Test service
curl -I https://devops-sk-07.lrk.si
```

### Blue/Green
```bash
# Check version
./blue-green/check-version.sh

# Deploy to green
./blue-green/deploy-green.sh sha-NEWTAG

# Switch to green
./blue-green/switch-blue-green.sh green

# Rollback to blue
./blue-green/switch-blue-green.sh blue
```

---

## Tips for Good Documentation

1. **Show the process clearly**: Each screenshot should show a clear step
2. **Prove 0-downtime**: Include evidence that service stayed up (curl responses, timestamps)
3. **Show pod transitions**: Capture the moment pods are being replaced
4. **Include timestamps**: Helps show the process is fast
5. **Explain what's happening**: Add brief captions to screenshots

---

## Example Screenshot Checklist

### Rolling Update:
- [ ] Before: `kubectl get pods` showing 3 blue pods
- [ ] During: `kubectl get pods` showing 4 pods (3 old + 1 new)
- [ ] During: `kubectl rollout status` showing progress
- [ ] After: `kubectl get pods` showing 3 new pods
- [ ] Proof: `curl` responses showing service stayed up throughout

### Blue/Green:
- [ ] Initial: `kubectl get pods` showing both blue and green
- [ ] Deploy: `./blue-green/deploy-green.sh` output
- [ ] Before switch: `./blue-green/check-version.sh` showing blue
- [ ] Switch: `./blue-green/switch-blue-green.sh green` output
- [ ] After switch: `./blue-green/check-version.sh` showing green
- [ ] Proof: Service responding with new version

---

Good luck with your demos! 🚀

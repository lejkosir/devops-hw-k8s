#!/bin/bash
# Fix incomplete minikube profile by getting complete structure from root

set -e

echo "=========================================="
echo "Fixing Incomplete Minikube Profile"
echo "=========================================="
echo ""

# 1. Check what root has
echo "1. Checking root's complete structure:"
echo "--------------------------------------------"

if [ ! -d "/root/.minikube" ]; then
    echo "❌ Root has no .minikube directory"
    exit 1
fi

echo "✓ Root has .minikube directory"
echo ""

# 2. Check root's profile
if [ -d "/root/.minikube/profiles/minikube" ]; then
    echo "Root's profile contents:"
    sudo ls -la /root/.minikube/profiles/minikube/
    echo ""
    
    # Check for config.json
    if [ -f "/root/.minikube/profiles/minikube/config.json" ]; then
        echo "✓ Root has config.json in profile"
    else
        echo "⚠ Root's profile also missing config.json"
    fi
else
    echo "⚠ Root has no profiles/minikube directory"
fi
echo ""

# 3. Check root's main config
if [ -f "/root/.minikube/config/config.json" ]; then
    echo "✓ Root has main config.json"
    echo "Contents:"
    sudo cat /root/.minikube/config/config.json | head -30
    echo ""
else
    echo "⚠ Root has no main config.json"
fi
echo ""

# 4. Remove incomplete copy and get fresh complete copy
echo "2. Getting complete structure from root:"
echo "--------------------------------------------"

# Backup current (if exists)
if [ -d "$HOME/.minikube" ]; then
    echo "Backing up current .minikube..."
    mv ~/.minikube ~/.minikube.backup.$(date +%s)
fi

# Get complete structure from root
echo "Copying complete structure from root..."
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.minikube

echo "✓ Copied complete structure"
echo ""

# 5. Verify what we got
echo "3. Verifying copied structure:"
echo "--------------------------------------------"
if [ -d "$HOME/.minikube/profiles/minikube" ]; then
    echo "Profile contents:"
    ls -la "$HOME/.minikube/profiles/minikube/"
    echo ""
    
    # Check for key files
    echo "Required files:"
    [ -f "$HOME/.minikube/profiles/minikube/config.json" ] && echo "✓ config.json" || echo "✗ config.json MISSING"
    [ -f "$HOME/.minikube/profiles/minikube/client.crt" ] && echo "✓ client.crt" || echo "✗ client.crt MISSING"
    [ -f "$HOME/.minikube/profiles/minikube/client.key" ] && echo "✓ client.key" || echo "✗ client.key MISSING"
    [ -f "$HOME/.minikube/config/config.json" ] && echo "✓ main config.json" || echo "✗ main config.json MISSING"
else
    echo "⚠ No profile directory found after copy"
fi
echo ""

# 6. Try minikube commands
echo "4. Testing minikube:"
echo "--------------------------------------------"
echo "Testing profile list:"
minikube profile list 2>&1 | head -5
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""

if minikube profile list 2>&1 | grep -q "minikube"; then
    echo "✅ Profile is now working!"
    echo ""
    echo "Try:"
    echo "  sudo minikube tunnel"
else
    echo "⚠ Profile still not detected by minikube CLI"
    echo ""
    echo "But the cluster is running, so try these:"
    echo ""
    echo "1. Try tunnel anyway (might work despite error):"
    echo "   sudo minikube tunnel"
    echo ""
    echo "2. Use root's config directly:"
    echo "   sudo MINIKUBE_HOME=/root/.minikube minikube tunnel"
    echo ""
    echo "3. Have your partner run it (they should have complete profile):"
    echo "   # Partner runs: sudo minikube tunnel"
fi
echo ""

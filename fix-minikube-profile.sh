#!/bin/bash
# Check and fix minikube profile structure

echo "=========================================="
echo "Checking Minikube Profile Structure"
echo "=========================================="
echo ""

# Check root's profile structure
echo "1. Root's profile structure:"
echo "--------------------------------------------"
if [ -d "/root/.minikube/profiles" ]; then
    echo "✓ Root has profiles directory"
    sudo ls -la /root/.minikube/profiles/
    echo ""
    
    # Check what's in the profile
    if [ -d "/root/.minikube/profiles/minikube" ]; then
        echo "Profile 'minikube' contents:"
        sudo ls -la /root/.minikube/profiles/minikube/
        echo ""
        
        # Check for key files
        echo "Checking for required files:"
        [ -f "/root/.minikube/profiles/minikube/config.json" ] && echo "✓ config.json exists" || echo "✗ config.json MISSING"
        [ -f "/root/.minikube/profiles/minikube/client.crt" ] && echo "✓ client.crt exists" || echo "✗ client.crt MISSING"
        [ -f "/root/.minikube/profiles/minikube/client.key" ] && echo "✓ client.key exists" || echo "✗ client.key MISSING"
    fi
else
    echo "✗ Root has no profiles directory"
fi
echo ""

# Check root's config.json
echo "2. Root's main config.json:"
echo "--------------------------------------------"
if [ -f "/root/.minikube/config/config.json" ]; then
    echo "✓ Root has config.json"
    sudo cat /root/.minikube/config/config.json
else
    echo "✗ Root has no config.json"
fi
echo ""

# Check your user's profile
echo "3. Your user's profile:"
echo "--------------------------------------------"
if [ -d "$HOME/.minikube/profiles/minikube" ]; then
    echo "Profile contents:"
    ls -la "$HOME/.minikube/profiles/minikube/"
    echo ""
    
    # Check what's missing
    echo "Checking for required files:"
    [ -f "$HOME/.minikube/profiles/minikube/config.json" ] && echo "✓ config.json exists" || echo "✗ config.json MISSING"
    [ -f "$HOME/.minikube/config/config.json" ] && echo "✓ Main config.json exists" || echo "✗ Main config.json MISSING"
fi
echo ""

# Check if we can copy the complete structure
echo "4. Attempting to fix profile:"
echo "--------------------------------------------"

if [ -f "/root/.minikube/config/config.json" ] && [ -d "/root/.minikube/profiles/minikube" ]; then
    echo "Root has complete structure. Copying everything..."
    
    # Remove incomplete copy
    rm -rf ~/.minikube
    
    # Copy everything from root
    sudo cp -r /root/.minikube ~/.minikube
    sudo chown -R $USER:$USER ~/.minikube
    
    echo "✓ Copied complete minikube structure"
    echo ""
    echo "Now try:"
    echo "  sudo minikube tunnel"
else
    echo "⚠ Root's structure might also be incomplete"
    echo ""
    echo "Try using root's config directly:"
    echo "  sudo MINIKUBE_HOME=/root/.minikube minikube tunnel"
fi

echo ""

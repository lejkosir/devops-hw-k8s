#!/bin/bash
# Check what profiles actually exist in minikube config

echo "=========================================="
echo "Checking Minikube Profiles"
echo "=========================================="
echo ""

# Check root's profiles
echo "1. Root's minikube profiles:"
echo "--------------------------------------------"
if [ -d "/root/.minikube/profiles" ]; then
    echo "Profiles in /root/.minikube/profiles/:"
    ls -la /root/.minikube/profiles/
    echo ""
    
    # Check each profile
    for profile in /root/.minikube/profiles/*; do
        if [ -d "$profile" ]; then
            PROFILE_NAME=$(basename "$profile")
            echo "Profile: $PROFILE_NAME"
            ls -la "$profile" | head -5
            echo ""
        fi
    done
else
    echo "No profiles directory found"
fi

# Check user's profiles (if copied)
echo "2. Your minikube profiles (if copied):"
echo "--------------------------------------------"
if [ -d "$HOME/.minikube/profiles" ]; then
    echo "Profiles in $HOME/.minikube/profiles/:"
    ls -la "$HOME/.minikube/profiles/"
    echo ""
    
    for profile in "$HOME/.minikube/profiles"/*; do
        if [ -d "$profile" ]; then
            PROFILE_NAME=$(basename "$profile")
            echo "Profile: $PROFILE_NAME"
            ls -la "$profile" | head -5
            echo ""
        fi
    done
else
    echo "No profiles directory found in your home"
fi

# Check minikube config file
echo "3. Minikube config file:"
echo "--------------------------------------------"
if [ -f "/root/.minikube/config/config.json" ]; then
    echo "Root's config.json:"
    cat /root/.minikube/config/config.json | head -20
    echo ""
fi

if [ -f "$HOME/.minikube/config/config.json" ]; then
    echo "Your config.json:"
    cat "$HOME/.minikube/config/config.json" | head -20
    echo ""
fi

# Check what minikube sees
echo "4. What minikube CLI sees:"
echo "--------------------------------------------"
echo "As root:"
sudo minikube profile list 2>&1 | head -10
echo ""

echo "As your user:"
minikube profile list 2>&1 | head -10
echo ""

echo "=========================================="
echo "Recommendations"
echo "=========================================="
echo ""

# Check if we can find the actual profile name
if [ -d "/root/.minikube/profiles" ]; then
    PROFILE_COUNT=$(ls -1 /root/.minikube/profiles/ 2>/dev/null | wc -l)
    if [ "$PROFILE_COUNT" -gt 0 ]; then
        FIRST_PROFILE=$(ls -1 /root/.minikube/profiles/ 2>/dev/null | head -1)
        echo "Found profile directory: $FIRST_PROFILE"
        echo ""
        echo "Try using this profile explicitly:"
        echo "  sudo MINIKUBE_HOME=/root/.minikube minikube tunnel -p $FIRST_PROFILE"
        echo ""
        echo "Or try without profile name (use default):"
        echo "  sudo MINIKUBE_HOME=/root/.minikube minikube tunnel"
    fi
fi

echo ""

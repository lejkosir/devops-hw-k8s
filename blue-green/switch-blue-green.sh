#!/bin/bash
# Script to switch traffic between Blue and Green deployments
# Usage: ./switch-blue-green.sh [blue|green]

set -e

NAMESPACE="taprav-fri"
SERVICE_NAME="frontend"
CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')

# If version argument provided, use it; otherwise toggle
if [ "$1" == "blue" ] || [ "$1" == "green" ]; then
    TARGET_VERSION=$1
elif [ -z "$CURRENT_VERSION" ] || [ "$CURRENT_VERSION" == "blue" ]; then
    TARGET_VERSION="green"
else
    TARGET_VERSION="blue"
fi

echo "Current active version: ${CURRENT_VERSION:-none}"
echo "Switching to version: $TARGET_VERSION"

# Update service selector
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"$TARGET_VERSION\"}}}"

echo ""
echo "✓ Traffic switched to $TARGET_VERSION"
echo ""
echo "Verifying switch..."
sleep 2

# Verify the switch
NEW_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
if [ "$NEW_VERSION" == "$TARGET_VERSION" ]; then
    echo "✓ Successfully switched to $TARGET_VERSION"
    echo ""
    echo "Active pods:"
    kubectl get pods -n $NAMESPACE -l app=frontend,version=$TARGET_VERSION
else
    echo "✗ Error: Switch verification failed"
    exit 1
fi

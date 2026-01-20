#!/bin/bash
# Script to switch Kubernetes service selector between blue and green deployments
# Usage: ./switch-blue-green.sh [blue|green]
# If no argument is provided, it toggles the current active version.

NAMESPACE="taprav-fri"
SERVICE_NAME="frontend"

# Get current active version
CURRENT_VERSION=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}')

if [ -z "$1" ]; then
    # Toggle version if no argument provided
    if [ "$CURRENT_VERSION" == "blue" ]; then
        TARGET_VERSION="green"
    else
        TARGET_VERSION="blue"
    fi
else
    TARGET_VERSION="$1"
fi

if [ "$TARGET_VERSION" != "blue" ] && [ "$TARGET_VERSION" != "green" ]; then
    echo "Error: Invalid version specified. Use 'blue' or 'green'."
    exit 1
fi

if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    echo "Service '$SERVICE_NAME' is already pointing to '$TARGET_VERSION'. No change needed."
    exit 0
fi

echo "Switching service '$SERVICE_NAME' from '$CURRENT_VERSION' to '$TARGET_VERSION'..."

kubectl patch service "$SERVICE_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"$TARGET_VERSION\"}}}"

if [ $? -eq 0 ]; then
    echo "Successfully switched service '$SERVICE_NAME' to '$TARGET_VERSION'."
    echo "New active version: $(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}')"
else
    echo "Failed to switch service '$SERVICE_NAME'."
    exit 1
fi

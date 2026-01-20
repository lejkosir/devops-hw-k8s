#!/bin/bash
# Script to check the currently active version (blue or green) of the frontend service

NAMESPACE="taprav-fri"
SERVICE_NAME="frontend"

CURRENT_VERSION=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}' 2>/dev/null)

if [ -z "$CURRENT_VERSION" ]; then
    echo "Service '$SERVICE_NAME' not found or version selector not set in namespace '$NAMESPACE'."
    exit 1
fi

echo "Active version for service '$SERVICE_NAME': $CURRENT_VERSION"

# Optional: Show pods for the active version
echo "Active pods:"
kubectl get pods -n "$NAMESPACE" -l app=frontend,version="$CURRENT_VERSION"

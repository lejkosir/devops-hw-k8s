#!/bin/bash
# Script to check which version (blue/green) is currently active

NAMESPACE="taprav-fri"
SERVICE_NAME="frontend"

ACTIVE_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')

if [ -z "$ACTIVE_VERSION" ]; then
    echo "No version selector found in service"
    exit 1
fi

echo "Active version: $ACTIVE_VERSION"
echo ""

# Show pods for active version
echo "Active pods ($ACTIVE_VERSION):"
kubectl get pods -n $NAMESPACE -l app=frontend,version=$ACTIVE_VERSION

echo ""
echo "Inactive pods:"
if [ "$ACTIVE_VERSION" == "blue" ]; then
    INACTIVE="green"
else
    INACTIVE="blue"
fi

kubectl get pods -n $NAMESPACE -l app=frontend,version=$INACTIVE 2>/dev/null || echo "No $INACTIVE pods found"

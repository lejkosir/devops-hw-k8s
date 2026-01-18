#!/bin/bash
# Script to deploy a new version to Green deployment
# Usage: ./deploy-green.sh <image-tag>
# Example: ./deploy-green.sh sha-abc123

set -e

if [ -z "$1" ]; then
    echo "Error: Image tag required"
    echo "Usage: $0 <image-tag>"
    echo "Example: $0 sha-abc123"
    exit 1
fi

IMAGE_TAG=$1
NAMESPACE="taprav-fri"
DEPLOYMENT_NAME="frontend-green"
IMAGE_NAME="ghcr.io/lejkosir/devops-hw-docker-frontend"

echo "Deploying new version to Green deployment..."
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Update the image in green deployment
kubectl set image deployment/$DEPLOYMENT_NAME frontend=$IMAGE_NAME:$IMAGE_TAG -n $NAMESPACE

echo ""
echo "✓ Image updated. Waiting for rollout..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s

echo ""
echo "✓ Green deployment updated successfully"
echo ""
echo "Green pods:"
kubectl get pods -n $NAMESPACE -l app=frontend,version=green

echo ""
echo "Note: Traffic is still pointing to Blue. Use switch-blue-green.sh to switch traffic after verification."

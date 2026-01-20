#!/bin/bash
# Script to deploy a new image version to the frontend-green deployment
# Usage: ./deploy-green.sh <image-sha-tag>

NAMESPACE="taprav-fri"
DEPLOYMENT_NAME="frontend-green"
CONTAINER_NAME="frontend" # Name of the container in the deployment
IMAGE_REPO="ghcr.io/lejkosir/devops-hw-docker-frontend"

if [ -z "$1" ]; then
    echo "Usage: $0 <image-sha-tag>"
    echo "Example: $0 sha-abc123"
    exit 1
fi

NEW_IMAGE_TAG="$1"
FULL_IMAGE_NAME="$IMAGE_REPO:$NEW_IMAGE_TAG"

echo "Deploying new image '$FULL_IMAGE_NAME' to deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE'..."

kubectl set image deployment/"$DEPLOYMENT_NAME" "$CONTAINER_NAME"="$FULL_IMAGE_NAME" -n "$NAMESPACE"

if [ $? -eq 0 ]; then
    echo "Image update initiated for deployment '$DEPLOYMENT_NAME'."
    echo "Waiting for rollout to complete..."
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    if [ $? -eq 0 ]; then
        echo "Deployment '$DEPLOYMENT_NAME' rollout successfully completed with image '$FULL_IMAGE_NAME'."
    else
        echo "Deployment '$DEPLOYMENT_NAME' rollout failed or timed out."
        exit 1
    fi
else
    echo "Failed to update image for deployment '$DEPLOYMENT_NAME'."
    exit 1
fi

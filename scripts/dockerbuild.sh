#!/bin/bash

# Configuration
DOCKER_USER="marcoliew"
TAG="v0.1.0" # Use a fixed tag for the first release

echo "----------------------------------------"
echo "Building and Pushing Images to Docker Hub"
echo "User: $DOCKER_USER"
echo "Tag: $TAG"
echo "----------------------------------------"

# 1. Build and Push Go Service
echo ">> [1/3] Processing Go Service..."
docker build -t $DOCKER_USER/lgtm-go-service:$TAG apps/go-service
docker push $DOCKER_USER/lgtm-go-service:$TAG

# 2. Build and Push Python Service
echo ">> [2/3] Processing Python Service..."
docker build -t $DOCKER_USER/lgtm-python-service:$TAG apps/python-service
docker push $DOCKER_USER/lgtm-python-service:$TAG

# 3. Build and Push Node Service
echo ">> [3/3] Processing Node.js Service..."
docker build -t $DOCKER_USER/lgtm-node-service:$TAG apps/nodejs-service
docker push $DOCKER_USER/lgtm-node-service:$TAG

echo "----------------------------------------"
echo "Success! All images pushed."
echo "----------------------------------------"
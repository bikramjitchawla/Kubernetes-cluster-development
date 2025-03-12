#!/bin/bash
set -euo pipefail

echo "Creating Kind cluster..."
kind create cluster --config=Kind/cluster.yaml || true

echo "Cluster created successfully."

echo "Deploying manifests with Skaffold..."
cd Kind; skaffold run; cd ..

echo "Skaffold deployment complete."

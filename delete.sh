#!/bin/bash
set -euo pipefail

CLUSTER_NAME="test-cluster"

echo "Deleting Kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME"
echo "Kind cluster '$CLUSTER_NAME' deleted."
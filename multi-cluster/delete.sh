#!/bin/bash
set -euo pipefail

delete_if_exists() {
  local cluster_name="$1"
  if kind get clusters | grep -qx "${cluster_name}"; then
    echo "Deleting cluster '${cluster_name}'..."
    kind delete cluster --name "${cluster_name}" || true
  else
    echo "Cluster '${cluster_name}' does not exist. Skipping."
  fi
}

delete_if_exists "tenant-b-cluster"
delete_if_exists "tenant-a-cluster"
delete_if_exists "platform-cluster"

echo "Multi-cluster environment deleted."

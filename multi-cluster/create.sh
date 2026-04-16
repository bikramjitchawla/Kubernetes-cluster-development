#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIND_DIR="${ROOT_DIR}/kind"

create_if_missing() {
  local cluster_name="$1"
  local config_path="$2"

  if kind get clusters | grep -qx "${cluster_name}"; then
    echo "Cluster '${cluster_name}' already exists. Skipping create."
  else
    echo "Creating cluster '${cluster_name}'..."
    kind create cluster --config "${config_path}"
  fi
}

create_if_missing "platform-cluster" "${KIND_DIR}/platform-cluster.yaml"
create_if_missing "tenant-a-cluster" "${KIND_DIR}/tenant-a-cluster.yaml"
create_if_missing "tenant-b-cluster" "${KIND_DIR}/tenant-b-cluster.yaml"

echo "Creating baseline namespaces..."
kubectl --context kind-platform-cluster create namespace platform-system --dry-run=client -o yaml | kubectl --context kind-platform-cluster apply -f -
kubectl --context kind-tenant-a-cluster create namespace tenant-workloads --dry-run=client -o yaml | kubectl --context kind-tenant-a-cluster apply -f -
kubectl --context kind-tenant-b-cluster create namespace tenant-workloads --dry-run=client -o yaml | kubectl --context kind-tenant-b-cluster apply -f -

echo "Multi-cluster environment is ready."
echo "Contexts:"
echo "  kind-platform-cluster"
echo "  kind-tenant-a-cluster"
echo "  kind-tenant-b-cluster"

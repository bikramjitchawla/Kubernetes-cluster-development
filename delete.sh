#!/bin/bash
set -euo pipefail

CLUSTER_NAME="test-cluster"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking if Kind cluster '$CLUSTER_NAME' exists..."
if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Kind cluster '$CLUSTER_NAME' does not exist. Nothing to delete."
  exit 0
fi

echo "Attempting best-effort Rook Ceph cleanup on context '$KUBE_CONTEXT'..."
if kubectl --context "$KUBE_CONTEXT" get ns rook-ceph >/dev/null 2>&1; then
  if kubectl --context "$KUBE_CONTEXT" get crd cephclusters.ceph.rook.io >/dev/null 2>&1; then
    kubectl --context "$KUBE_CONTEXT" delete -f "${REPO_ROOT}/rook-ceph/cluster.yaml" --ignore-not-found=true || true
    kubectl --context "$KUBE_CONTEXT" delete -f "${REPO_ROOT}/rook-ceph/pool-storageclass.yaml" --ignore-not-found=true || true
  else
    echo "Rook Ceph CRDs already missing; skipping Ceph CR deletion."
    kubectl --context "$KUBE_CONTEXT" delete storageclass rook-ceph-block --ignore-not-found=true || true
  fi

  kubectl --context "$KUBE_CONTEXT" delete -f "${REPO_ROOT}/rook-ceph/operator.yaml" --ignore-not-found=true || true
  kubectl --context "$KUBE_CONTEXT" delete -f "${REPO_ROOT}/rook-ceph/common.yaml" --ignore-not-found=true || true
  kubectl --context "$KUBE_CONTEXT" delete -f "${REPO_ROOT}/rook-ceph/crds.yaml" --ignore-not-found=true || true
  kubectl --context "$KUBE_CONTEXT" delete namespace rook-ceph --ignore-not-found=true --wait=false || true
else
  echo "Namespace 'rook-ceph' not found; skipping Rook cleanup."
fi

echo "Deleting Kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME" || true
echo "Kind cluster '$CLUSTER_NAME' deleted."

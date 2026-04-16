#!/bin/bash
set -euo pipefail

echo "Uninstalling Rook Ceph custom resources (if CRDs exist)..."
if kubectl get crd cephclusters.ceph.rook.io >/dev/null 2>&1; then
  kubectl delete -f cluster.yaml --ignore-not-found=true || true
  kubectl delete -f pool-storageclass.yaml --ignore-not-found=true || true
else
  echo "Ceph CRDs are already missing; skipping CephCluster/CephBlockPool delete."
  kubectl delete storageclass rook-ceph-block --ignore-not-found=true || true
fi

echo "Uninstalling Rook Ceph operator/common resources..."
kubectl delete -f operator.yaml --ignore-not-found=true || true
kubectl delete -f common.yaml --ignore-not-found=true || true

echo "Removing Rook Ceph CRDs (if present)..."
kubectl delete -f crds.yaml --ignore-not-found=true || true

echo "Rook Ceph uninstall completed."

#!/bin/bash
set -euo pipefail

echo "Uninstalling Rook Ceph custom resources (if CRDs exist)..."
if kubectl get crd cephfilesystems.ceph.rook.io >/dev/null 2>&1; then
  kubectl -n rook-ceph delete cephfilesystem rook-ceph-fs --ignore-not-found=true --wait=false || true
  kubectl -n rook-ceph patch cephfilesystem rook-ceph-fs --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1 || true
fi
if kubectl get crd cephblockpools.ceph.rook.io >/dev/null 2>&1; then
  kubectl -n rook-ceph delete cephblockpool rook-ceph-block --ignore-not-found=true --wait=false || true
  kubectl -n rook-ceph patch cephblockpool rook-ceph-block --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1 || true
fi
if kubectl get crd cephclusters.ceph.rook.io >/dev/null 2>&1; then
  kubectl -n rook-ceph delete cephcluster rook-ceph --ignore-not-found=true --wait=false || true
  kubectl -n rook-ceph patch cephcluster rook-ceph --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1 || true
else
  echo "Ceph CRDs are already missing; skipping Ceph custom resource deletion."
fi
kubectl delete storageclass rook-ceph-filesystem --ignore-not-found=true || true
kubectl delete storageclass rook-ceph-block --ignore-not-found=true || true

echo "Uninstalling Rook Ceph operator/common resources..."
kubectl delete -f operator.yaml --ignore-not-found=true --wait=false || true
kubectl delete -f common.yaml --ignore-not-found=true --wait=false || true

echo "Removing Rook Ceph CRDs (if present)..."
kubectl delete -f crds.yaml --ignore-not-found=true --wait=false || true

echo "Rook Ceph uninstall completed."

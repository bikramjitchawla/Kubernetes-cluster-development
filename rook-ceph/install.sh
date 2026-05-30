#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Rook Ceph CRDs..."
kubectl apply -f "${SCRIPT_DIR}/crds.yaml"
kubectl wait --for=condition=Established \
  crd/cephclusters.ceph.rook.io \
  crd/cephfilesystems.ceph.rook.io \
  --timeout=2m

echo "Installing Rook Ceph operator..."
kubectl apply -f "${SCRIPT_DIR}/common.yaml"
kubectl apply -f "${SCRIPT_DIR}/operator.yaml"

echo "Waiting for Rook Ceph operator to become Ready..."
kubectl rollout status -n rook-ceph deployment/rook-ceph-operator --timeout=5m

echo "Creating Rook Ceph cluster..."
kubectl apply -f "${SCRIPT_DIR}/cluster.yaml"

echo "Waiting for Ceph cluster to become Ready..."
kubectl wait -n rook-ceph cephcluster/rook-ceph --for=condition=Ready --timeout=15m

echo "Creating Rook Ceph filesystem and StorageClass..."
kubectl apply -f "${SCRIPT_DIR}/filesystem-storageclass.yaml"
kubectl wait -n rook-ceph cephfilesystem/rook-ceph-fs --for=condition=Ready --timeout=10m

echo "Rook Ceph installation completed."

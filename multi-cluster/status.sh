#!/bin/bash
set -euo pipefail

echo "Kind clusters:"
kind get clusters

echo
for ctx in kind-platform-cluster kind-tenant-a-cluster kind-tenant-b-cluster; do
  if kubectl config get-contexts -o name | grep -qx "${ctx}"; then
    echo "=== ${ctx} ==="
    kubectl --context "${ctx}" get nodes -o wide
    echo
  fi
done

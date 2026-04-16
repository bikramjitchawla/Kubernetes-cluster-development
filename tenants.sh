#!/bin/bash
set -euo pipefail

kubectl apply -f manifests/tenants.yaml
kubectl apply -f manifests/tenant-example-apps.yaml

echo "Tenant architecture resources applied."
echo "Try:"
echo "  curl -k https://app.tenant-a.127.0.0.1.nip.io"
echo "  curl -k https://app.tenant-b.127.0.0.1.nip.io"

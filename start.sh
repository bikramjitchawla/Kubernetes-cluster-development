#!/bin/bash

set -e
set -o pipefail

echo "Creating Kind cluster..."
if kind create cluster --config=Kind/cluster.yaml; then
  echo "Kind cluster created successfully."
else
  echo "Kind cluster already exists or failed to create. Continuing..."
fi

echo "Deploying base manifests with Skaffold..."
(
  cd Kind
  skaffold run
)

echo "Deploying Calico Operator (CRDs & operator)..."
(
  cd calico
  skaffold run --filename skaffold-operator.yaml
)

echo "Deploying Calico Installation resources (Installation & APIServer)..."
(
  cd calico
  skaffold run --filename skaffold-resource.yaml
)

echo "Waiting for Calico pods to appear..."
for i in {1..20}; do
  pods=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l)
  if [ "$pods" -gt 0 ]; then
    echo "Calico pods detected. Waiting for them to be Ready..."
    kubectl wait --for=condition=Ready pods --all -n calico-system --timeout=90s || {
      echo "Some Calico pods failed to become Ready in time."
      exit 1
    }
    break
  fi
  echo "Waiting for Calico pods to be created... (${i}/20)"
  sleep 5
done

pods=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l)
if [ "$pods" -eq 0 ]; then
  echo "No Calico pods were created. Something went wrong with the Installation."
  exit 1
fi

echo "Deploying Traefik (after Calico is ready)..."
(
  cd traefik
  skaffold run
)

echo "Skaffold deployment completed successfully."

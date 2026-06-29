#!/bin/bash

set -e
set -o pipefail

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

# ─── local registry ────────────────────────────────────────────────────────────
# Must exist before the cluster so nodes can resolve it during image pulls.

echo "Ensuring local registry is running..."
if docker inspect "$REGISTRY_NAME" > /dev/null 2>&1; then
  echo "Local registry '$REGISTRY_NAME' already exists."
else
  docker run -d \
    -p "127.0.0.1:${REGISTRY_PORT}:5000" \
    --name "$REGISTRY_NAME" \
    --restart=always \
    registry:2
  echo "Local registry started on localhost:${REGISTRY_PORT}."
fi

# ─── kind cluster ──────────────────────────────────────────────────────────────

echo "Creating Kind cluster..."
if kind create cluster --config=Kind/cluster.yaml; then
  echo "Kind cluster created successfully."
else
  echo "Kind cluster already exists or failed to create. Continuing..."
fi

# Connect registry to Kind network so nodes can reach it as "kind-registry:5000"
if docker network inspect kind | grep -q "\"$REGISTRY_NAME\""; then
  echo "Registry already connected to Kind network."
else
  docker network connect kind "$REGISTRY_NAME"
  echo "Registry connected to Kind network."
fi

# Advertise the registry to tools that understand the standard ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# ─── base manifests ────────────────────────────────────────────────────────────

echo "Deploying base manifests with Skaffold..."
(
  cd Kind
  skaffold run
)

# ─── calico ────────────────────────────────────────────────────────────────────

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

# ─── metallb ───────────────────────────────────────────────────────────────────

echo "Installing MetalLB..."
(
  cd metallb
  skaffold run
)

echo "Configuring MetalLB address pool..."
kubectl apply -f metallb/address-pool.yaml

# ─── cert-manager ──────────────────────────────────────────────────────────────

echo "Installing cert-manager..."
(
  cd cert-manager
  skaffold run
)

echo "Waiting for cert-manager to become Ready..."
kubectl rollout status -n cert-manager deployment/cert-manager --timeout=5m
kubectl rollout status -n cert-manager deployment/cert-manager-webhook --timeout=5m
kubectl rollout status -n cert-manager deployment/cert-manager-cainjector --timeout=5m

echo "Configuring cert-manager ClusterIssuer (self-signed)..."
kubectl apply -f cert-manager/cluster-issuer.yaml

# ─── traefik ───────────────────────────────────────────────────────────────────

echo "Deploying Traefik (after Calico is ready)..."
(
  cd traefik
  skaffold run
)

# ─── polaris ───────────────────────────────────────────────────────────────────

echo "Installing Polaris..."
(
  cd polaris
  skaffold run
)

echo ""
echo "Cluster ready."
echo "  Local registry : localhost:${REGISTRY_PORT}"
echo "  Push images    : docker build -t localhost:${REGISTRY_PORT}/<name>:tag . && docker push localhost:${REGISTRY_PORT}/<name>:tag"
echo "  Skaffold deploy: skaffold run  (in any app repo)"

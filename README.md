# Local Kind Cluster Project

This project provides an easy way to set up a local Kubernetes cluster using Kind (Kubernetes in Docker). The setup includes Calico, Traefik, ArgoCD, and a local container registry. Deployment of resources is managed with Skaffold.

## Features
- Automated Kind cluster creation
- Deploys ArgoCD, Calico, and Traefik
- Includes a local container registry
- Uses Skaffold for deployment automation

## Prerequisites
Ensure you have the following tools installed before using this project:
- [Helm](https://helm.sh/)
- [Skaffold](https://skaffold.dev/)
- [Kind](https://kind.sigs.k8s.io/)
- [Docker](https://www.docker.com/)

## Usage
### Start the Cluster
To create and deploy the Kind cluster, simply run:
```bash
./start.sh
```
This will:
1. Create a Kind cluster based on `Kind/cluster.yaml`.
2. Deploy ArgoCD, Calico, and Traefik using Skaffold.
3. Set up a local container registry.

### Delete the Cluster
To remove the cluster, run:
```bash
./delete.sh
```

### Note on Kind port mappings
Changes to `Kind/cluster.yaml` (like `extraPortMappings`) only take effect after recreating the Kind cluster. Run `./delete.sh` and then `./start.sh` to apply new mappings.

## Cluster Configuration
The cluster consists of:
- **Calico**: For networking and policy enforcement.
- **Traefik**: As an ingress controller.
- **ArgoCD**: For GitOps-style application deployments.
- **Local Container Registry**:
  ```yaml
  kind: ConfigMap
  metadata:
    name: local-registry
    namespace: kube-public
  data:
    local-registry: |
      host: "localhost:5001"
  ```

## Deployment Details
The `start.sh` script executes the following steps:
```bash
echo "Creating Kind cluster..."
kind create cluster --config=Kind/cluster.yaml || true

echo "Cluster created successfully."

echo "Deploying manifests with Skaffold..."

kubectl create namespace argocd || true

cd Kind; skaffold run; cd ..;
cd calico; skaffold run --filename skaffold-operator.yaml; cd ..;
sleep 20
cd calico; skaffold run --filename skaffold-resource.yaml; cd ..;

cd traefik; skaffold run; cd ..;

echo "Skaffold deployment completed.";
```

## Bare-Metal Exposure (Manual DNS)
This repo uses MetalLB to provide a real `LoadBalancer` IP on bare-metal. Traefik is configured as a `LoadBalancer`, so you can map a real DNS name to Traefik and route traffic via Ingress.

### Example setup (manual DNS)
1. Deploy the example app and ingress:
   ```bash
   kubectl apply -f manifests/example-app.yaml
   kubectl apply -f manifests/example-ingress.yaml
   ```
2. Get the MetalLB IP for Traefik:
   ```bash
   kubectl get svc -n traefik
   ```
3. Use a dev wildcard domain (no DNS provider needed):
   - `app.127.0.0.1.nip.io` → resolves to `127.0.0.1` automatically
4. Test:
   ```bash
   curl http://app.127.0.0.1.nip.io
   ```

If you want a different hostname, update `manifests/example-ingress.yaml`.

### macOS note (why MetalLB IP may hang)
MetalLB assigns an IP that exists only inside Docker’s network, not on the macOS host. DNS can be correct and requests still hang because the host cannot route to that IP. Accessing services via `localhost` (port‑forward or port mapping) works because localhost is reachable from the host.
In short: the issue is reachability to the Docker network IP, not DNS.

## HTTPS (self-signed, local dev)
This repo installs cert-manager and a self-signed ClusterIssuer for local HTTPS.

### Example HTTPS access
1. Apply the example ingress (includes TLS):
   ```bash
   kubectl apply -f manifests/example-ingress.yaml
   ```
2. Wait for the certificate to be Ready:
   ```bash
   kubectl get certificate
   ```
3. Test (self-signed, use -k):
   ```bash
   curl -k https://app.127.0.0.1.nip.io
   ```

## Multi-tenant DNS/LB patterns
### Single cluster, multiple namespaces (shared Traefik)
- One Traefik `LoadBalancer` service → one MetalLB IP.
- Every tenant hostname points to the same IP.
- Traefik routes by hostname/path to the correct namespace/service.

Example:
- `app.team1.example.com` → `<traefik-external-ip>`
- `app.team2.example.com` → `<traefik-external-ip>`

### Multiple clusters (per-tenant clusters)
- Each cluster has its own Traefik + MetalLB IP.
- Each tenant domain points to its cluster’s unique IP.

Example:
- `app.team1.example.com` → `<cluster1-traefik-ip>`
- `app.team2.example.com` → `<cluster2-traefik-ip>`

### Management cluster fronting tenant clusters
- If Traefik only runs in the management cluster, it can only route to endpoints it can reach.
- To front other clusters, you need cross-cluster networking, a service mesh, or external endpoints.

## Contributions
Feel free to open issues or submit pull requests to improve this project.

## Argo CD
Agrdo CD will be integrated in coming days in the project 

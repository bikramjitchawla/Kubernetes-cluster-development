# Local Kind Cluster Project

This project provides an easy way to set up a local Kubernetes cluster using Kind (Kubernetes in Docker). The setup includes Calico, Traefik, Polaris, and a local container registry. Deployment of resources is managed with Skaffold.

## Features
- Automated Kind cluster creation
- Deploys Calico, Traefik, and Polaris
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
2. Deploy Calico, Traefik, and Polaris using Skaffold.
3. Set up a local container registry.

### Delete the Cluster
To remove the cluster, run:
```bash
./delete.sh
```

To uninstall only Rook Ceph (without deleting the whole Kind cluster), run:
```bash
cd rook-ceph
./uninstall.sh
```

### Create Tenant Namespaces (Platform + Tenants)
To create a platform namespace and two tenant namespaces with quotas/limits plus demo apps, run:
```bash
./tenants.sh
```

This creates:
- `platform-system` namespace (platform scope)
- `tenant-a` and `tenant-b` namespaces (tenant scope)
- ResourceQuota and LimitRange in each tenant namespace
- Example apps and Ingress routes:
  - `https://app.tenant-a.127.0.0.1.nip.io`
  - `https://app.tenant-b.127.0.0.1.nip.io`

### Note on Kind port mappings
Changes to `Kind/cluster.yaml` (like `extraPortMappings`) only take effect after recreating the Kind cluster. Run `./delete.sh` and then `./start.sh` to apply new mappings.

## Cluster Configuration
The cluster consists of:
- **Calico**: For networking and policy enforcement.
- **Traefik**: As an ingress controller.
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
- **Rook Ceph**: Distributed storage (local dev config).
- **Polaris**: Kubernetes best-practices dashboard and policy checks.

## Storage (Rook Ceph)
Rook Ceph is installed for local, ephemeral storage. A `rook-ceph-block` StorageClass is created for PVCs.

Example PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: rook-ceph-block
```

## Deployment Details
The `start.sh` script executes the following steps:
```bash
echo "Creating Kind cluster..."
kind create cluster --config=Kind/cluster.yaml || true

echo "Cluster created successfully."

echo "Deploying manifests with Skaffold..."

cd Kind; skaffold run; cd ..;
cd calico; skaffold run --filename skaffold-operator.yaml; cd ..;
sleep 20
cd calico; skaffold run --filename skaffold-resource.yaml; cd ..;

cd traefik; skaffold run; cd ..;
cd polaris; skaffold run; cd ..;

echo "Skaffold deployment completed.";
```

## Polaris Dashboard
Polaris is installed in the `polaris` namespace.

To access the dashboard locally:
```bash
kubectl -n polaris port-forward svc/polaris-dashboard 8080:80
```

Then open:
```text
http://localhost:8080
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

## True Multi-Cluster Tenant Architecture (Kind)
This repo includes automation to run one platform cluster and two tenant clusters locally.

### Create all clusters
```bash
./multi-cluster/create.sh
```

This creates:
- `platform-cluster` (`kubectl` context: `kind-platform-cluster`)
- `tenant-a-cluster` (`kubectl` context: `kind-tenant-a-cluster`)
- `tenant-b-cluster` (`kubectl` context: `kind-tenant-b-cluster`)

It also creates baseline namespaces:
- `platform-system` in the platform cluster
- `tenant-workloads` in each tenant cluster

### Check status
```bash
./multi-cluster/status.sh
```

### Delete all clusters
```bash
./multi-cluster/delete.sh
```

### Management cluster fronting tenant clusters
- If Traefik only runs in the management cluster, it can only route to endpoints it can reach.
- To front other clusters, you need cross-cluster networking, a service mesh, or external endpoints.

## Contributions
Feel free to open issues or submit pull requests to improve this project.

## Argo CD
Agrdo CD will be integrated in coming days in the project 

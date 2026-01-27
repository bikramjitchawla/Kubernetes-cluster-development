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
3. Create a DNS A record:
   - `app.batman.com` → `<traefik-external-ip>`
   - Wildcard option: `*.batman.com` → `<traefik-external-ip>` (all subdomains hit Traefik)
4. Test:
   ```bash
   curl http://app.batman.com
   ```

If you want a different hostname, update `manifests/example-ingress.yaml`.

## Contributions
Feel free to open issues or submit pull requests to improve this project.

## Argo CD
Agrdo CD will be integrated in coming days in the project 

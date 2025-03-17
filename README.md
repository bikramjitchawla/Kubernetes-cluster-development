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

## Contributions
Feel free to open issues or submit pull requests to improve this project.



echo "Creating Kind cluster..."
kind create cluster --config=Kind/cluster.yaml || true

echo "Cluster created successfully."

echo "Deploying manifests with Skaffold..."

kubectl create namespace argocd || true
echo "ArgoCD namespace created successfully."

cd Kind; skaffold run; cd ..;
cd calico; skaffold run --filename skaffold-operator.yaml; cd ..;
cd calico; skaffold run --filename skaffold-resource.yaml; cd ..;

echo "Skaffold deployment completed.";
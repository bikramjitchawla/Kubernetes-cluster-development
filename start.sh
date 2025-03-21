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
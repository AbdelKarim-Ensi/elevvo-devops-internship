#!/usr/bin/env bash
# Usage: MONGO_PASSWORD=xxx bash deploy.sh
set -euo pipefail
cd "$(dirname "$0")"
: "${MONGO_PASSWORD:?export MONGO_PASSWORD first}"

# NetworkPolicy needs a CNI that enforces it (Calico)
minikube status >/dev/null 2>&1 || minikube start --cni=calico --memory=3072
minikube addons enable ingress

# Build the Task 5 image inside minikube's Docker daemon
eval "$(minikube docker-env)"
docker build -t elevvo-api:1.0 ../task-05-docker-multistage

kubectl apply -f 00-namespace.yaml
kubectl -n elevvo create secret generic mongo-credentials \
  --from-literal=MONGO_USER=admin --from-literal=MONGO_PASSWORD="$MONGO_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f 10-database.yaml -f 20-backend.yaml -f 30-frontend.yaml
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s
kubectl apply -f 40-ingress.yaml -f 50-networkpolicy.yaml
kubectl -n elevvo rollout status deploy/backend --timeout=180s
kubectl -n elevvo get pods,svc,ingress,networkpolicy
echo "Add to /etc/hosts:  $(minikube ip) elevvo.local"

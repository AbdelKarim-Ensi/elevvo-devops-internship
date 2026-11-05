# Task 9 - Kubernetes & Zero-Trust Networking

## Deploy
```bash
export MONGO_PASSWORD='choose-a-strong-one'
bash deploy.sh
echo "$(minikube ip) elevvo.local" | sudo tee -a /etc/hosts
curl http://elevvo.local/            # nginx page
curl http://elevvo.local/api/        # {"message":..., "visits":N}
```

## Prove the requirements (demo)
```bash
kubectl -n elevvo get pods -o wide
kubectl -n elevvo describe pod -l app=backend | grep -A3 -i -E 'limits|requests'
# Network policy: backend CAN reach db, a random pod CANNOT
kubectl -n elevvo exec deploy/backend -- wget -qO- -T3 db:27017 || true      # connects (Mongo replies, not HTTP)
kubectl -n elevvo run intruder --rm -it --image=busybox:1.36 --restart=Never -- nc -zv -w3 db 27017   # must time out
# Self-healing + rolling update
kubectl -n elevvo delete pod -l app=backend --wait=false && kubectl -n elevvo get pods -w
kubectl -n elevvo set image deploy/frontend nginx=nginx:1.27.1-alpine && kubectl -n elevvo rollout status deploy/frontend
```

## Cleanup
```bash
minikube delete
```

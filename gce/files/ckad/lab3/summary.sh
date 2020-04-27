./docker-compose.sh
./kompose.sh
mkdir -p /tmp/data /tmp/nginx
kubectl create -f localregistry.yaml
kubectl get pods,svc,pvc,pv,deploy
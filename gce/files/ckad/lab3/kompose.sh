sudo curl -L https://bit.ly/2tN0bEa -o kompose
sudo chmod +x kompose
sudo cp ./kompose /usr/local/bin/kompose

###
kubectl create -f vol1.yaml
kubectl create -f vol2.yaml
kubectl get pv

###
cd /localdocker
sudo /usr/local/bin/kompose convert -f docker-compose.yaml -o localregistry.yaml
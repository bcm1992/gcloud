sudo apt-get install -y docker-compose apache2-utils
sudo mkdir -p /localdocker/data
sudo chown -R ubuntu:ubuntu /localdocker/
cd /localdocker/
cp ~/files/ckad/lab3/docker-compose.yaml .
sudo docker-compose up
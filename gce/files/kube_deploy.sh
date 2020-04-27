apt-get update && sudo apt-get upgrade -y
apt-get install jq -y
wget https://training.linuxfoundation.org/cm/LFS258/LFS258_V2019-08-12_SOLUTIONS.tar.bz2 --user=LFtraining --password=Penguin2014
wget https://training.linuxfoundation.org/cm/LFD259/LFD259_V2020-02-03_SOLUTIONS.tar.bz2 --user=LFtraining --password=Penguin2014

tar -xf LFS258_V2019-08-12_SOLUTIONS.tar.bz2
tar -xf LFD259_V2020-02-03_SOLUTIONS.tar.bz2

apt-get install -y docker.io

echo deb http://apt.kubernetes.io/ kubernetes-xenial main >> /etc/apt/sources.list.d/kubernetes.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
#apt-get install -y kubeadm=1.15.1-00 kubelet=1.15.1-00 kubectl=1.15.1-00
apt-get install -y --allow-downgrades kubeadm=1.16.1-00 kubelet=1.16.1-00 kubectl=1.16.1-00

sudo sh -c "echo 10.138.0.10 k8smaster >> /etc/hosts"

### Enabling password-less SSH using ubuntu user, ubuntu.rsa is copied by previous provisioner.
chmod 600 /home/ubuntu/ubuntu.rsa
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDItORXa95VhKFpcJOCW8N0MJPv0QM9YwefcU6ZYluMgc8SRZBT0MFaYtecFGCSwpca5t/wOz/B0+ymECKJXrnqP1eWo3CY5NJ9odmrVRs7m4ySRDMNIHnXMmYgENUqcrhQJvqrkPiXqUPHvGUNaf4kf3MEPPXsqiIArQs4I8gcRLDLDIh7IeWjXbXVDWzvLYUC42tCsc0SlLYFpkTKkilabsEreAKdvap+Mbp0qh91y5elG5Rkif9NfTyG1SyB6Si16vSEobmKd0pYV0RmytThZRFf4dT39qlJWIBZrVvTaGiuUcGin/K7ZElSAh0RPSYLA4e9TMfebS1h6omyv7EN" >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
cp -p /home/ubuntu/ubuntu.rsa /home/ubuntu/.ssh/id_rsa

### Master Node
echo "Private IP Check..."
ip -4 -br address show  ens4  | grep "10.138.0.10/32" 
if [ "$?" -eq 0 ];then
  cd /home/ubuntu
  kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
  #kubeadm init --pod-network-cidr=192.168.0.0/16 | tee kubeadm-init.out
  mkdir -p /home/ubuntu/.kube
  cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  chown -R ubuntu:ubuntu /home/ubuntu/.kube/
  # update URL for the newer version (1.16 compatibility)
  wget https://tinyurl.com/yb4xturm -O rbac-kdd.yaml
  wget https://tinyurl.com/y2vqsobb  -O calico.yaml
#  wget https://tinyurl.com/y8lvqc9g -O calico.yaml
#  wget https://tinyurl.com/yb4xturm -O rbac-kdd.yaml
  kubectl apply -f rbac-kdd.yaml
  kubectl apply -f calico.yaml
  # Enable masster node to work as a woker node
  kubectl taint nodes --all node-role.kubernetes.io/master-
  echo "alias k=kubectl" >> $HOME/.bash_profile
  echo "source <(kubectl completion bash)" >> $HOME/.bash_profile
  # Enable NFS server on the master node
  apt-get install -y nfs-kernel-server
  mkdir /opt/sfw
  chmod 1777 /opt/sfw/
  echo software > /opt/sfw/hello.txt
  echo '/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)' >> /etc/exports
  exportfs -ra

  # Run kubeadm join on the other nodes
  k=$(grep "^kubeadm join k8smaster:6443" /home/ubuntu/kubeadm-init.out | sed 's:\\::')
  i=$(grep "^    --discovery-token-ca-cert-hash" /home/ubuntu/kubeadm-init.out | grep -v ' \\')
  for h in $(seq 2 3)
  do
  host linux-foundation-${h} > /dev/null 2>&1
  if [ $? -eq 0 ];then
    echo "run kubeadm on linux-foundation-${h}"
    ssh -i /home/ubuntu/ubuntu.rsa -l ubuntu -oStrictHostKeyChecking=no linux-foundation-${h} sudo ${k} ${i}
  fi
  done

  # Change owner ship of .kube again because sub directories might has been created.
  chown -R ubuntu:ubuntu /home/ubuntu/.kube/
fi
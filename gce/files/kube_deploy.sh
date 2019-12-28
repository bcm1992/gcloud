apt-get update && sudo apt-get upgrade -y
wget https://training.linuxfoundation.org/cm/LFS258/LFS258_V2019-08-12_SOLUTIONS.tar.bz2 --user=LFtraining --password=Penguin2014
tar -xvf LFS258_V2019-08-12_SOLUTIONS.tar.bz2

apt-get install -y docker.io

echo deb http://apt.kubernetes.io/ kubernetes-xenial main >> /etc/apt/sources.list.d/kubernetes.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
#apt-get install -y kubeadm=1.15.1-00 kubelet=1.15.1-00 kubectl=1.15.1-00
apt-get install -y --allow-downgrades kubeadm=1.16.1-00 kubelet=1.16.1-00 kubectl=1.16.1-00

sudo sh -c "echo 10.138.0.10 k8smaster >> /etc/hosts"

### Master Node
echo "Private IP Check..."
ip -4 -br address show  ens4  | grep "10.138.0.10/32" 
if [ "$?" -eq 0 ];then
  cd /home/ubuntu
  kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
  #kubeadm init --pod-network-cidr=192.168.0.0/16 | tee kubeadm-init.out
  mkdir -p .kube
  cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  chown -R ubuntu:ubuntu /home/ubuntu/.kube/
  wget https://tinyurl.com/y2vqsobb  -O calico.yaml
#  wget https://tinyurl.com/y8lvqc9g -O calico.yaml
  wget https://tinyurl.com/yb4xturm -O rbac-kdd.yaml
#  wget https://tinyurl.com/yb4xturm -O rbac-kdd.yaml
  kubectl apply -f /home/ubuntu/rbac-kdd.yaml
  kubectl apply -f /home/ubuntu/calico.yaml 
  #kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
  kubectl taint nodes --all node-role.kubernetes.io/master-
  echo "alias k=kubectl" >> $HOME/.bash_profile
  echo "source <(kubectl completion bash)" >> $HOME/.bash_profile
  # NFS
  apt-get install -y nfs-kernel-server
  mkdir /opt/sfw
  chmod 1777 /opt/sfw/
  echo software > /opt/sfw/hello.txt
  echo '/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)' >> /etc/exports
  exportfs -ra
fi
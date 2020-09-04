#!/bin/bash
apt-get update && apt-get upgrade -y
apt-get install jq -y
apt-get install vim -y

modprobe overlay
modprobe br_netfilter

printf "%s\n" "net.bridge.bridge-nf-call-iptables = 1" "net.ipv4.ip_forward = 1" "net.bridge.bridge-nf-call-ip6tables = 1">/etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system

apt-get install -y software-properties-common 
add-apt-repository ppa:projectatomic/ppa -y
apt-get update

# Instaill cri-o
apt-get install -y cri-o-1.15
#apt-get install -y docker.io
cp -pi /etc/crio/crio.conf /etc/crio/crio.conf.ORIG

sed -i 's:^conmon = .*:conmon = "/usr/bin/conmon":' /etc/crio/crio.conf
sed -i 's:^image_volumes = .*:&\n\nregistries = [\n  "docker.io",\n  "quay.io",\n  "registry.fedoraproject.orig",\n]:' /etc/crio/crio.conf

systemctl daemon-reload
systemctl enable crio
systemctl start crio

cat <<EOS > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--feature-gates="AllAlpha=false,RunAsGroup=true" --container-runtime=remote --cgroup-driver=systemd --container-runtime-endpoint='unix:///var/run/crio/crio.sock' --runtime-request-timeout=5m
EOS

# Install Kubernetes
echo deb http://apt.kubernetes.io/ kubernetes-xenial main >> /etc/apt/sources.list.d/kubernetes.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
#apt-get install -y --allow-downgrades kubeadm=1.16.1-00 kubelet=1.16.1-00 kubectl=1.16.1-00
apt-get install -y kubeadm=1.18.1-00 kubelet=1.18.1-00 kubectl=1.18.1-00
# Set hold to prevent the packages from being updated
apt-mark hold kubelet kubeadm kubectl

### Add host alias
sh -c "echo 10.138.0.10 k8smaster >> /etc/hosts"

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
  cat <<EOS > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: 1.18.1
controlPlaneEndpoint: "k8smaster:6443"
networking:
  podSubnet: 192.168.0.0/16
EOS

  # --pod-network-cidr=192.168.0.0/16
  kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
  mkdir -p /home/ubuntu/.kube
  cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  chown -R ubuntu:ubuntu /home/ubuntu/.kube/

  # Install Calico
  wget https://docs.projectcalico.org/manifests/calico.yaml
  #sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' calico.yaml
  #sed -i 's!#   value: "192.168.0.0/16"!  value: "192.168.0.0/16"!' calico.yaml

  apt-get install bash-completion -y
  echo "source <(kubectl completion bash)" >> ~/.bashrc

  kubectl taint nodes --all node-role.kubernetes.io/master-
  echo "alias k=kubectl" >> $HOME/.bash_profile

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

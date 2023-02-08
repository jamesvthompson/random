# Deploy Kubernetes Cluster on Ubuntu 20.04 with Containerd

In this guide we’ll go through all the steps you need to set up a Kubernetes cluster Ubuntu 20.04

# Step 1. Install containerd
Follow these steps on all servers

1. Load the br_netfilter module required for networking
```
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

2. To allow iptables to see bridged traffic, as required by Kubernetes, we need to set the values of certain fields to 1
```
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

3. Apply the new settings without restarting
```
sudo sysctl --system
```

4. Install curl.
```
sudo apt install curl -y
```

5. Get the apt-key and then add the repository from which we will install containerd
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

6. Update and then install the containerd package
```
sudo apt update -y 
sudo apt install -y containerd.io
```

7. Set up the default configuration file
```
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

8. Next up, we need to modify the containerd configuration file and ensure that the cgroupDriver is set to systemd. To do so, edit the following file
```
sudo vi /etc/containerd/config.toml
```
Scroll down to the following section
```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
```
And ensure that value of **SystemdCgroup** is set to **true**, Make sure the contents of your section match the following
```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    BinaryName = ""
    CriuImagePath = ""
    CriuPath = ""
    CriuWorkPath = ""
    IoGid = 0
    IoUid = 0
    NoNewKeyring = false
    NoPivotRoot = false
    Root = ""
    ShimCgroup = ""
    SystemdCgroup = true
```
9. Finally, to apply these changes, we need to restart containerd
```
sudo systemctl restart containerd
```
To check that containerd is indeed running, use this command:
```
ps -ef | grep containerd
```
Expect output similar to this:
```
root       63087       1  0 13:16 ?        00:00:00 /usr/bin/containerd
```

# Step 2. Install Kubernetes
With our container runtime installed and configured, we are ready to install Kubernetes

1. Add the repository key and the repository
```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

2. Update your system and install the 3 Kubernetes modules.
```
sudo apt update -y
sudo apt install -y kubelet=1.24.10-00 kubeadm=1.24.10-00 kubectl=1.24.10-00
```

3. To allow kubelet to work properly, we need to disable swap on both machines
```
sudo swapoff –a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

4. Finally, enable the kubelet service on both systems so we can start it
```
sudo systemctl enable kubelet
```

# Step 3. Setting up the cluster
With our container runtime and Kubernetes modules installed, we are ready to initialize our Kubernetes cluster

1. Run the following command on the master node to allow Kubernetes to fetch the required images before cluster initialization
```
sudo kubeadm config images pull
```

2. Initialize the cluster
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
The initialization may take a few moments to finish. Expect an output similar to the following
```
Your Kubernetes control-plane has initialized successfully!
```

3. To start using your cluster, you need to run the following as a regular user:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Alternatively, if you are the root user, you can run:
```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
4. Deploy a pod network to our cluster. This is required to interconnect the different Kubernetes components
```
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```
Expect an output like this:
```
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```
Use the get nodes command to verify that our master node is ready.
```
kubectl get nodes
```
Expect the following output
```
NAME          STATUS   ROLES           AGE     VERSION
master-node   Ready    control-plane   9m50s   v1.24.2
```
Also check whether all the default pods are running
```
kubectl get pods --all-namespaces
```
You should get an output like this:
```
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d4b75cb6d-dxhvf              1/1     Running   0          10m
kube-system   coredns-6d4b75cb6d-nkmj4              1/1     Running   0          10m
kube-system   etcd-master-node                      1/1     Running   0          11m
kube-system   kube-apiserver-master-node            1/1     Running   0          11m
kube-system   kube-controller-manager-master-node   1/1     Running   0          11m
kube-system   kube-flannel-ds-jxbvx                 1/1     Running   0          6m35s
kube-system   kube-proxy-mhfqh                      1/1     Running   0          10m
kube-system   kube-scheduler-master-node            1/1     Running   0          11m
```
# Step 4. Adding nodes tothe cluster
Then you can join any number of worker nodes by running the following on each as root
```
kubeadm join 102.130.122.60:6443 --token s3v1c6.dgufsxikpbn9kflf \
        --discovery-token-ca-cert-hash sha256:b8c63b1aba43ba228c9eb63133df81632a07dc780a92ae2bc5ae101ada623e00
```
You will see a kubeadm join at the end of the output. Copy and save it in some file. We will have to run this command on the worker node to allow it to join the cluster. But fear not, if you forget to save it, or misplace it, you can also regenerate it using this command
```
sudo kubeadm token create --print-join-command
```





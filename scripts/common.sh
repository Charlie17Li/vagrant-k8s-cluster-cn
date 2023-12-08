#! /bin/bash

KUBERNETES_VERSION="1.27.2-00"

# disable swap 
sudo swapoff -a
sudo sed -ri 's/.*swap.*/#&/' /etc/fstab 

echo "Swap diasbled..."

# disable firewall
sudo ufw disable

# fix https://blog.csdn.net/shida_csdn/article/details/99571884
modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward

# 默认127.0.0.53 存在解析域名失败的问题(mac上有这个问题，但是windows下测试没有这个问题)
sed -i 's/127.0.0.53/114.114.114.114/g' /etc/resolv.conf

# 代理
export https_proxy=http://10.10.114.60:7890 http_proxy=http://10.10.114.60:7890 all_proxy=socks5://10.10.114.60:7890

# 安装 containerd
# 参考: https://zhuanlan.zhihu.com/p/636831803
# wget https://github.com/containerd/containerd/releases/download/v1.7.0/containerd-1.7.0-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.7.0-linux-amd64.tar.gz

cat << EOF >> /lib/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
str1="registry.k8s.io/pause:3.8"
str2="registry.aliyuncs.com/google_containers/pause:3.9"
sed -i "/sandbox_image/ s%${str1}%${str2}%g" /etc/containerd/config.toml
sed -i '/SystemdCgroup/ s/false/true/g' /etc/containerd/config.toml
systemctl restart containerd && systemctl status containerd

# wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
# wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
mkdir -p /opt/cni/bin
tar xf  cni-plugins-linux-amd64-v1.1.1.tgz -C /opt/cni/bin/


# install kubelet, kubectl, kubeadm
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl wget software-properties-common
sudo apt-get update -y
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubenetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update -y
sudo apt-get install -y kubelet=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION

sudo systemctl start kubelet  
sudo systemctl enable kubelet   

echo "Installation done..."

# 删掉代理
unset https_proxy http_proxy all_proxy
Vagrant.configure("2") do |config|
  config.vm.box_check_update = false

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt update -y
    echo "10.0.0.80  master" >> /etc/hosts
    echo "10.0.0.81  worker1" >> /etc/hosts
    echo "10.0.0.82  worker2" >> /etc/hosts
    echo "10.0.0.83  worker3" >> /etc/hosts
  SHELL
    
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/bionic64"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "10.0.0.80"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end
    master.vm.provision "file", source: "runc.amd64", destination: "runc.amd64"
    master.vm.provision "file", source: "cni-plugins-linux-amd64-v1.1.1.tgz", destination: "cni-plugins-linux-amd64-v1.1.1.tgz"
    master.vm.provision "file", source: "containerd-1.7.0-linux-amd64.tar.gz", destination: "containerd-1.7.0-linux-amd64.tar.gz"
    master.vm.provision "file", source: "calico.yaml", destination: "calico.yaml"
    master.vm.provision "shell", path: "scripts/common.sh"
    master.vm.provision "shell", path: "scripts/master.sh"
  end

  (1..3).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.box = "ubuntu/bionic64"
      worker.vm.hostname = "worker#{i}"
      worker.vm.network "private_network", ip: "10.0.0.8#{i}"
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 2
      end
      worker.vm.provision "file", source: "runc.amd64", destination: "runc.amd64"
      worker.vm.provision "file", source: "cni-plugins-linux-amd64-v1.1.1.tgz", destination: "cni-plugins-linux-amd64-v1.1.1.tgz"
      worker.vm.provision "file", source: "containerd-1.7.0-linux-amd64.tar.gz", destination: "containerd-1.7.0-linux-amd64.tar.gz"
      worker.vm.provision "shell", path: "scripts/common.sh"
      worker.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end
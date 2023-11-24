# 删除所有虚拟机
vagrant destroy -f

# 重新部署所有虚拟机
vagrant up

# 部署deepflow
helm install deepflow -n deepflow deepflow/deepflow --create-namespace -f values-custom.yaml
# Create a directory for a volume to store settings and a sqlite database
mkdir -p ~/.ara/server

# Start an API server with docker from the image on DockerHub:
docker run --name api-server --detach --tty \
  --volume ~/.ara/server:/opt/ara -p 8000:8000 \
  docker.io/recordsansible/ara-api:latest

# build the runner
docker build -t ansible-runner .

# download vm script and congif file
mkdir -p test

wget -O test/config.yaml https://raw.githubusercontent.com/cloudymax/Scrap-Metal/main/virtual-machines/config.yaml

wget -O vm.sh https://raw.githubusercontent.com/cloudymax/Scrap-Metal/main/virtual-machines/vm.sh

# Create the vm 
bash vm.sh deps
time bash vm.sh create-cloud-vm test

# Run a playbook
bash provision.sh -au testadmin -p ansible_profiles/loop-flow -i sample-inventory.yaml

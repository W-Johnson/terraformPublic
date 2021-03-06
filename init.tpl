#!/bin/bash
sudo apt-get update
sudo apt-get install nfs-common -y
sudo curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
sudo zerotier-cli join 35c192ce9bd669cd
sudo mkdir efs
#sudo mount -t nfs4 -o  nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0ded9dd3c99f5e039.efs.eu-west-3.amazonaws.com:/ efs/
sudo mount -t nfs4 -o  nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}:/ efs/
echo export LB_DNS=${lb_dns} >> /etc/profile

cd home/ubuntu
touch ${lb_dns} 
touch ${efs_id} 

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER
sudo systemctl start docker.service
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
git clone https://github.com/W-Johnson/dockerComposeWordpress.git
cd dockerComposeWordpress
sudo echo "LB_DNS=${lb_dns}
RDS_HOST=10.0.0.154" > .env
sudo docker-compose up -d

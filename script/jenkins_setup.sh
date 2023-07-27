#!/bin/bash

# 필수 패키지 설치 
sudo mkdir -p /home/ec2-user/package/docker/ /home/ec2-user/package/cronie/
sudo yum install docker -y --downloadonly --downloaddir=/home/ec2-user/package/docker/ && sudo rpm -Uvh /home/ec2-user/package/docker/* && sudo systemctl enable docker && sudo systemctl start docker
sudo yum install cronie -y --downloadonly --downloaddir=/home/ec2-user/package/cronie/ && sudo rpm -Uvh /home/ec2-user/package/cronie/* && sudo systemctl enable crond && sudo systemctl start crond
#sudo yum install -y docker 
#sudo systemctl enable docker && systemctl start docker 

# 컨테이너 이미지, AWSCLI Download
sudo docker pull jenkins/jenkins
sudo mkdir -p /home/sysadm/jenkins/terraform_binary /var/jenkins_home
sudo wget "https://releases.hashicorp.com/terraform/1.5.3/terraform_1.5.3_linux_386.zip" -o "terraform.zip"
sudo unzip terraform.zip
sudo mv terraform /home/sysadm/jenkins/terraform_binary

# 컨테이너 기동에 필요한 필수 파일 구성 
chown -R 1000:1000 /home/sysadm/jenkins /var/jenkins_home ## docker 내부에서 실행하는 jenkins 실행계정의 UID/GID
mkdir -p /root/.aws/ 
sudo echo "[profile mine]
region = ap-northeast-2" >> /root/.aws/config

# // Dockerfile as add AWS CLI install 
echo "FROM jenkins/jenkins
MAINTAINER Suyong Ha
USER root
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install" > /home/ec2-user/dockerfile

# image build 
sudo docker build -t jenkins_with_awscli /home/ec2-user/

# container 실행 
sudo echo "sudo docker run -d -p 8080:8080 -p 50000:50000 -v /home/sysadm/jenkins:/var/jenkins_home -v /root/.aws:/root/.aws jenkins_with_awscli:latest" > /home/sysadm/jenkins/jenkins_container.sh && sudo chmod 755 /home/sysadm/jenkins/jenkins_container.sh && sudo echo "@reboot root /home/sysadm/jenkins/jenkins_container.sh">> /etc/crontab && sudo bash /home/sysadm/jenkins/jenkins_container.sh

## 컨테이너 실행 명령어 
## sysadm 홈디렉토리 내부에 jenkins 볼륨 구성 
# sudo docker run -d -p 8080:8080 -p 50000:50000 -v /home/sysadm/jenkins:/var/jenkins_home -v /root/.aws:/root/.aws jenkins_with_awscli:latest 

# 참고 내용
# https://gist.github.com/fortunecookiezen/b3bc3214a07a14529608857d078b32dd




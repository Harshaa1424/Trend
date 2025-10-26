#!/bin/bash
# update and install docker
yum update -y
yum install -y docker git wget
service docker start
usermod -a -G docker ec2-user

# install java and Jenkins
amazon-linux-extras install java-openjdk11 -y
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# Install kubectl and eksctl (optional if you plan to run kubectl from this instance)
curl -o /usr/local/bin/kubectl -L "https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.9/2024-06-10/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# Docker login will be done in Jenkins pipeline

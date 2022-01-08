#!/bin/bash

# Install aws cli
apt update -y
apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Import ssh key
export KEY_NAME="${KEY_PRIVATE}"
export SSH_KEY=$(aws secretsmanager --output text get-secret-value --secret-id $KEY_NAME --query SecretString --region us-east-1)
export EC2_USER=ubuntu

echo "$SSH_KEY" >/home/$EC2_USER/.ssh/id_rsa
chmod 600 /home/$EC2_USER/.ssh/id_rsa
chown $EC2_USER:$EC2_USER /home/$EC2_USER/.ssh/id_rsa

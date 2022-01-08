#!/bin/bash

# Import ssh key
export KEY_NAME="${KEY_PRIVATE}"
export SSH_KEY=$(aws secretsmanager --output text get-secret-value --secret-id $KEY_NAME --query SecretString --region us-east-1)
export EC2_USER=ec2-user

echo "$SSH_KEY" >/home/$EC2_USER/.ssh/id_rsa
chmod 600 /home/$EC2_USER/.ssh/id_rsa
chown $EC2_USER:$EC2_USER /home/$EC2_USER/.ssh/id_rsa


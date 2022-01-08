#!/bin/bash

apt update -y
apt install apache2 -y
systemctl start apache2
systemctl enable apache2

echo "[${ENV}] Hello World from $(hostname -f)" > /var/www/html/index.html


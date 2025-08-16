#!/bin/bash
echo "UD: apt update"
apt update
echo "UD: apt install nginx"
apt install --assume-yes nginx
echo "UD: move files to nginx"
mv /home/ubuntu/* /var/www/html/
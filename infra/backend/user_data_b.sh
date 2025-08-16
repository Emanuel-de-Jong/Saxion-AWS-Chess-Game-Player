#!/bin/bash
echo "UD: apt update"
apt update
echo "UD: apt install docker dependencies"
apt install --assume-yes ca-certificates curl gnupg
echo "UD: add Dockers GPG key"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "UD: set up docker repository"
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "UD: apt update"
apt update
echo "UD: apt install docker packages"
sudo apt install --assume-yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "UD: cd /home/ubuntu/"
cd /home/ubuntu/
echo "UD: chmod dockerize.sh"
chmod 770 dockerize.sh
echo "UD: build docker container"
bash dockerize.sh build
echo "UD: run docker container"
bash dockerize.sh run

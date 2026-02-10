#!/bin/bash

sudo yum update -y
sudo yum install java-21-amazon-corretto -y
sudo yum install screen awscli -y

sudo useradd minecraft
sudo mkdir -p /home/minecraft/server
sudo chown -R minecraft:minecraft /home/minecraft

sudo cp start.sh /home/minecraft/server/
sudo cp minecraft.service /etc/systemd/system/

sudo chmod +x /home/minecraft/server/start.sh

sudo systemctl daemon-reload
sudo systemctl enable minecraft

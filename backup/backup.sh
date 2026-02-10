#!/bin/bash
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP="mc_backup_$DATE.tar.gz"

sudo systemctl stop minecraft

tar -czvf /tmp/$BACKUP \
/home/minecraft/server/world* \
/home/minecraft/server/mods

sudo systemctl start minecraft

aws s3 cp /tmp/$BACKUP s3://minecraft-backups-tu-nombre/
rm /tmp/$BACKUP

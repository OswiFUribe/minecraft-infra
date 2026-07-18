#!/bin/bash
# Script de respaldo diario de Minecraft en EC2
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP="mc_backup_$DATE.tar.gz"

# 1. Detener el servicio temporalmente para evitar corrupción en el mundo
sudo systemctl stop minecraft

# 2. Crear el archivo comprimido respaldando mundos, mods y archivos de configuración
tar -czvf /tmp/$BACKUP \
  /home/minecraft/server/world* \
  /home/minecraft/server/mods \
  /home/minecraft/server/config

# 3. Arrancar de nuevo el servidor
sudo systemctl start minecraft

# 4. Subir el respaldo al bucket de S3
# El setup.sh reemplazará este bucket por el correspondiente de tu CloudFormation
aws s3 cp /tmp/$BACKUP s3://minecraft-backups-tu-nombre/

# 5. Limpiar archivo temporal
rm /tmp/$BACKUP

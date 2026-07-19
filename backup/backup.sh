#!/bin/bash
# Script de respaldo diario de Minecraft en EC2
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP="mc_backup_$DATE.tar.gz"

# 1. Buscar qué carpetas existen realmente en el servidor para evitar que tar falle
PATHS_TO_BACKUP=""
for path in /home/minecraft/server/world* /home/minecraft/server/mods /home/minecraft/server/config; do
  if [ -e "$path" ]; then
    PATHS_TO_BACKUP="$PATHS_TO_BACKUP $path"
  fi
done

if [ -z "$PATHS_TO_BACKUP" ]; then
  echo "Error: No se encontró ningún directorio válido para respaldar (world, mods, config)."
  exit 1
fi

# 2. Detener el servicio temporalmente para evitar corrupción en el mundo
sudo systemctl stop minecraft

# 3. Crear el archivo comprimido con las carpetas existentes
tar -czvf /tmp/$BACKUP $PATHS_TO_BACKUP

# 4. Arrancar de nuevo el servidor
sudo systemctl start minecraft

# 5. Subir el respaldo al bucket de S3
# El setup.sh reemplazará este bucket por el correspondiente de tu CloudFormation
if aws s3 cp /tmp/$BACKUP s3://minecraft-backups-tu-nombre/; then
  # 6. Limpiar archivo temporal solo si la subida fue exitosa
  rm /tmp/$BACKUP
else
  echo "Error: Fallo al subir el respaldo a S3. Conservando el archivo local en /tmp/$BACKUP." >&2
  exit 1
fi

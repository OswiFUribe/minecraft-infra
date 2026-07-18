#!/bin/bash
# Script de configuración del servidor de Minecraft para CurseForge en EC2
# Este script se puede ejecutar de forma manual dentro de la instancia si es necesario.

# 1. Obtener la región e información del stack de CloudFormation
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
if [ -z "$REGION" ]; then
  REGION="us-east-2" # Región por defecto
fi

# Detectar el nombre del bucket de S3 desde CloudFormation
STACK_NAME="minecraft-control"
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BackupBucketName'].OutputValue" \
  --output text 2>/dev/null)

if [ -z "$BUCKET_NAME" ] || [ "$BUCKET_NAME" == "None" ]; then
  echo "Error: No se pudo obtener el nombre del bucket de S3 desde el stack '$STACK_NAME'."
  echo "Por favor asegúrate de haber desplegado la infraestructura usando SAM primero."
  exit 1
fi

echo "Usando el bucket de S3: $BUCKET_NAME"

# 2. Configurar memoria Swap de 4GB (Crucial para instancias del Free Tier como t2.micro/t3.micro)
if [ ! -f /swapfile ]; then
  echo "Configurando 4GB de memoria Swap..."
  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab > /dev/null
else
  echo "Memoria Swap ya está configurada."
fi

# 3. Actualizar sistema e instalar Java y utilidades
echo "Instalando dependencias de sistema..."
sudo yum update -y
sudo yum install java-21-amazon-corretto -y
sudo yum install screen unzip awscli -y

# 4. Crear usuario y directorios para el servidor
if ! id "minecraft" &>/dev/null; then
  sudo useradd minecraft
fi
sudo mkdir -p /home/minecraft/server

# 5. Descargar y extraer el Modpack de CurseForge desde S3
MODPACK_KEY="server-files/modpack.zip"
echo "Descargando el modpack desde s3://$BUCKET_NAME/$MODPACK_KEY..."
sudo aws s3 cp "s3://$BUCKET_NAME/$MODPACK_KEY" /tmp/modpack.zip

if [ -f /tmp/modpack.zip ]; then
  echo "Descomprimiendo el modpack..."
  sudo unzip -o /tmp/modpack.zip -d /home/minecraft/server/
  sudo rm /tmp/modpack.zip
else
  echo "Advertencia: No se encontró el modpack en S3. Levantando servidor vacío..."
fi

# Aceptar EULA
echo "eula=true" | sudo tee /home/minecraft/server/eula.txt > /dev/null

# 6. Copiar scripts del repositorio al servidor
sudo cp start.sh /home/minecraft/server/start.sh
sudo chmod +x /home/minecraft/server/start.sh

# Configurar backup.sh y agregarlo a cron
sudo cp ../backup/backup.sh /home/minecraft/backup.sh
# Reemplazar marcador de bucket en backup.sh con el bucket dinámico
sudo sed -i "s|s3://minecraft-backups-tu-nombre/|s3://$BUCKET_NAME/backups/|g" /home/minecraft/backup.sh
sudo chmod +x /home/minecraft/backup.sh

# Configurar cronjob para respaldos diarios (04:00 AM)
(sudo crontab -u minecraft -l 2>/dev/null; echo "0 4 /home/minecraft/backup.sh") | sudo crontab -u minecraft -

# 7. Copiar y activar servicio Systemd
sudo cp minecraft.service /etc/systemd/system/
sudo chown -R minecraft:minecraft /home/minecraft

sudo systemctl daemon-reload
sudo systemctl enable minecraft

# Arrancar el servidor si hay mods o archivos listos
if [ -d /home/minecraft/server/mods ] || [ -f /home/minecraft/server/run.sh ] || [ -f /home/minecraft/server/server.jar ]; then
  echo "Iniciando servicio de Minecraft..."
  sudo systemctl start minecraft
fi

echo "Configuración completa."

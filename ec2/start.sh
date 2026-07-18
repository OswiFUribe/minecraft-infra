#!/bin/bash
# Script de arranque del servidor Minecraft en EC2
cd /home/minecraft/server

echo "Iniciando servidor de Minecraft..."

# 1. Detectar si el modpack tiene un script de inicio generado por el instalador (Forge/Fabric modernos)
if [ -f run.sh ]; then
  echo "Encontrado run.sh. Iniciando usando la configuración del modpack..."
  bash run.sh
# 2. Detectar si hay un start.sh propio del modpack (evitando recursión de este script)
elif [ -f start.sh ] && [ "$(realpath start.sh)" != "$(realpath /home/minecraft/server/start.sh)" ]; then
  echo "Encontrado start.sh del modpack. Ejecutando..."
  bash start.sh
# 3. Si no, buscar el primer JAR ejecutable compatible y correrlo con flags optimizados
else
  JAR_FILE=$(ls forge-*.jar fabric-server-launch.jar server.jar paper.jar 2>/dev/null | head -n 1)

  if [ -n "$JAR_FILE" ]; then
    echo "Encontrado ejecutable: $JAR_FILE. Iniciando con flags JVM optimizados..."
    # Asignación de memoria recomendada: 4G mínimo / 6G máximo (para una instancia de 8GB RAM como t3.large)
    java -Xms4G -Xmx6G \
      -XX:+UseG1GC \
      -XX:+ParallelRefProcEnabled \
      -XX:MaxGCPauseMillis=200 \
      -XX:+UnlockExperimentalVMOptions \
      -XX:+DisableExplicitGC \
      -XX:+AlwaysPreTouch \
      -XX:G1NewSizePercent=30 \
      -XX:G1MaxNewSizePercent=40 \
      -XX:G1HeapRegionSize=16M \
      -XX:G1ReservePercent=20 \
      -XX:G1HeapWastePercent=5 \
      -jar "$JAR_FILE" nogui
  else
    echo "Error: No se encontró ningún archivo de arranque run.sh ni un archivo JAR compatible."
    exit 1
  fi
fi

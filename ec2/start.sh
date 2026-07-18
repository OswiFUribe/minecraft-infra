#!/bin/bash
# Script de arranque del servidor Minecraft en EC2
cd /home/minecraft/server

echo "Iniciando servidor de Minecraft..."

# Calcular memoria disponible dinámicamente (RAM física + Swap)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$(( (TOTAL_RAM_KB + TOTAL_SWAP_KB) / 1024 ))

# Asignar el 70% de la memoria disponible para el heap de Java
MAX_RAM_MB=$(( TOTAL_MEM_MB * 70 / 100 ))
# Mantener un mínimo razonable de 1GB
MIN_RAM_MB=$(( MAX_RAM_MB / 2 ))
if [ $MIN_RAM_MB -lt 1024 ]; then
  MIN_RAM_MB=1024
fi

# Si el máximo asignado es menor que el mínimo, ajustar
if [ $MAX_RAM_MB -lt $MIN_RAM_MB ]; then
  MAX_RAM_MB=$MIN_RAM_MB
fi

echo "Memoria física + swap detectada: ${TOTAL_MEM_MB}MB"
echo "Asignando a Java: Min=${MIN_RAM_MB}MB, Max=${MAX_RAM_MB}MB"

# 1. Detectar si el modpack tiene un script de inicio generado por el instalador (Forge/Fabric modernos)
if [ -f run.sh ]; then
  echo "Encontrado run.sh. Iniciando usando la configuración del modpack..."
  # Nota: Si el run.sh tiene flags fijos de memoria muy altos en user_jvm_args.txt,
  # puedes modificar ese archivo para alinearlo con la RAM real de tu máquina.
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
    java -Xms${MIN_RAM_MB}M -Xmx${MAX_RAM_MB}M \
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

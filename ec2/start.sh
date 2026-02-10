#!/bin/bash
cd /home/minecraft/server

java -Xms5G -Xmx7G \
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
-jar paper.jar nogui

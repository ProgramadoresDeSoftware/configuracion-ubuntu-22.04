#!/bin/bash
# Script de diagnóstico para el host

echo "=== [HOST] Comprobación de puerto 1111 ==="
echo
echo "[1] Comprobando si el puerto está en escucha:"
ss -ltnp | grep ':1111' || echo " -> No hay procesos escuchando en 1111"

echo
echo "[2] Resolución de localhost vs 127.0.0.1:"
echo "curl -I http://localhost:1111/"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:1111/ || echo " -> Fallo con localhost"
echo "curl -I http://127.0.0.1:1111/"
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:1111/ || echo " -> Fallo con 127.0.0.1"

echo
echo "[3] Forzando IPv4 e IPv6:"
curl -4 -s -o /dev/null -w "IPv4 localhost: % {http_code}\n" http://localhost:1111/ || true
curl -6 -s -o /dev/null -w "IPv6 localhost: % {http_code}\n" http://localhost:1111/ || true

echo
echo "[4] Inspección de Docker container 'clip':"
docker ps --filter name=clip
docker inspect -f '{{json .NetworkSettings.Ports}}' clip 2>/dev/null

echo
echo "[5] sysctl bindv6only:"
sysctl net.ipv6.bindv6only 2>/dev/null || echo " -> No soportado en este sistema"

echo
echo "=== FIN comprobación HOST ==="

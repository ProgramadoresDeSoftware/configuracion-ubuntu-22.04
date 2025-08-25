#!/bin/bash
echo "Instalando Webmin..."
sudo apt update -y
sudo apt install -y software-properties-common wget
wget -q -O - http://www.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin.gpg
echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list > /dev/null
sudo apt update -y
sudo apt install -y webmin
sudo ufw allow 10000/tcp
echo "✅ Webmin instalado: https://$(hostname -I | awk '{print $1}'):10000"
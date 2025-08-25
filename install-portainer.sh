#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
}

# Verificar si Portainer ya está instalado
check_portainer() {
    if docker ps -a --format "{{.Names}}" | grep -q "portainer"; then
        print_warning "Portainer ya está instalado"
        exit 0
    fi
}

# Instalar Portainer
install_portainer() {
    print_status "Creando volumen para datos..."
    docker volume create portainer_data

    print_status "Instalando Portainer..."
    docker run -d \
      -p 8000:8000 \
      -p 9443:9443 \
      --name portainer \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest

    sleep 5
}

# Configurar firewall
configure_firewall() {
    if command -v ufw &> /dev/null && sudo ufw status | grep -q "active"; then
        print_status "Configurando firewall..."
        sudo ufw allow 9443/tcp
        sudo ufw allow 8000/tcp
    fi
}

# Verificar instalación
verify_installation() {
    if docker ps | grep -q "portainer"; then
        print_status "✅ Portainer instalado correctamente"
        
        IP=$(hostname -I | awk '{print $1}')
        echo ""
        echo "========================================"
        echo "🌐 ACCESO A PORTAINER"
        echo "========================================"
        echo "URL: https://$IP:9443"
        echo "Puerto: 9443 (HTTPS)"
        echo "Puerto alternativo: 9000 (HTTP, no recomendado)"
        echo ""
        echo "⚠️  Primera vez: Crear usuario admin"
        echo "⚠️  Certificado auto-firmado (aceptar advertencia)"
        echo "========================================"
    else
        print_error "❌ Error en la instalación"
        docker logs portainer
    fi
}

main() {
    check_docker
    check_portainer
    install_portainer
    configure_firewall
    verify_installation
}

main
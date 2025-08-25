#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Este script no debe ejecutarse como root"
        exit 1
    fi
}

# Función para verificar si Docker ya está instalado
check_docker_installed() {
    if command -v docker &> /dev/null; then
        print_warning "Docker ya está instalado"
        docker --version
        exit 0
    fi
}

# Función para instalar Docker
install_docker() {
    print_status "Actualizando sistema..."
    sudo apt update -y
    sudo apt upgrade -y

    print_status "Instalando dependencias..."
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    print_status "Agregando repositorio oficial de Docker..."
    # Agregar clave GPG
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Agregar repositorio
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    print_status "Actualizando repositorios..."
    sudo apt update -y

    print_status "Instalando Docker Engine..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_status "Habilitando Docker para inicio automático..."
    sudo systemctl enable docker
    sudo systemctl start docker

    print_status "Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER

    print_status "Instalación completada. Docker version:"
    docker --version
    docker compose version

    print_warning "⚠️  Debes cerrar sesión y volver a entrar para que los cambios de grupo surtan efecto"
    print_warning "⚠️  O ejecuta: newgrp docker"
}

# Función para probar la instalación
test_docker() {
    print_status "Probando instalación con hello-world..."
    if sudo docker run hello-world &> /dev/null; then
        print_status "✅ Docker instalado correctamente"
    else
        print_error "❌ Error al probar Docker"
        exit 1
    fi
}

# Función para configurar alias útiles
setup_aliases() {
    print_status "Configurando alias útiles..."
    
    # Agregar al .bashrc si no existen
    if ! grep -q "alias dps" ~/.bashrc; then
        echo -e "\n# Docker aliases" >> ~/.bashrc
        echo "alias dps='docker ps'" >> ~/.bashrc
        echo "alias dpsa='docker ps -a'" >> ~/.bashrc
        echo "alias dimg='docker images'" >> ~/.bashrc
        echo "alias dlog='docker logs'" >> ~/.bashrc
        echo "alias dstop='docker stop'" >> ~/.bashrc
        echo "alias drm='docker rm'" >> ~/.bashrc
        echo "alias dcp='docker compose'" >> ~/.bashrc
    fi
    
    print_status "Aliases configurados. Recarga con: source ~/.bashrc"
}

# Función principal
main() {
    print_status "Iniciando instalación de Docker en Ubuntu 22.04..."
    
    check_root
    check_docker_installed
    install_docker
    test_docker
    setup_aliases
    
    print_status "🎉 Instalación completada exitosamente!"
    print_warning "💡 Recuerda cerrar sesión y volver a entrar o ejecutar: newgrp docker"
    print_status "📋 Comandos útiles:"
    echo "  docker ps          # Listar contenedores"
    echo "  docker images      # Listar imágenes"
    echo "  docker run hello-world  # Probar Docker"
}

# Manejar argumentos
case "${1:-}" in
    -h|--help)
        echo "Uso: $0 [opciones]"
        echo "Opciones:"
        echo "  -h, --help     Mostrar esta ayuda"
        echo "  -v, --version  Mostrar versión del script"
        echo "  -t, --test     Solo probar si Docker está instalado"
        exit 0
        ;;
    -v|--version)
        echo "install-docker.sh v1.0"
        exit 0
        ;;
    -t|--test)
        if command -v docker &> /dev/null; then
            print_status "Docker está instalado:"
            docker --version
            exit 0
        else
            print_error "Docker no está instalado"
            exit 1
        fi
        ;;
    *)
        main
        ;;
esac
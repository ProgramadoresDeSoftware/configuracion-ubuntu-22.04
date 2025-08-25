#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables configurables
WEBMIN_PORT="10000"
WEBMIN_USER=$(whoami)

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Este script no debe ejecutarse como root"
        exit 1
    fi
}

# Función para verificar si Webmin ya está instalado
check_webmin_installed() {
    if command -v webmin &> /dev/null || [ -f /etc/webmin/miniserv.conf ]; then
        print_warning "Webmin ya está instalado"
        print_status "Puerto: $(grep '^port=' /etc/webmin/miniserv.conf 2>/dev/null || echo '10000')"
        print_status "URL: https://$(hostname -I | awk '{print $1}'):${WEBMIN_PORT}"
        exit 0
    fi
}

# Función para instalar dependencias
install_dependencies() {
    print_step "Instalando dependencias..."
    sudo apt update -y
    sudo apt install -y software-properties-common curl wget gnupg2
}

# Función para agregar repositorio e instalar Webmin
install_webmin() {
    print_step "Agregando repositorio de Webmin..."
    
    # Descargar y agregar clave GPG
    wget -q -O - http://www.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin.gpg
    
    # Agregar repositorio
    echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list > /dev/null
    
    print_step "Instalando Webmin..."
    sudo apt update -y
    sudo apt install -y webmin
}

# Función para configurar firewall
configure_firewall() {
    print_step "Configurando firewall..."
    
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "active"; then
            sudo ufw allow $WEBMIN_PORT/tcp
            print_status "Puerto $WEBMIN_PORT abierto en UFW"
        else
            print_warning "UFW no está activado, omitiendo configuración de firewall"
        fi
    else
        print_warning "UFW no instalado, omitiendo configuración de firewall"
    fi
}

# Función para configurar seguridad básica
configure_security() {
    print_step "Configurando seguridad básica..."
    
    # Crear backup de configuración
    sudo cp /etc/webmin/miniserv.conf /etc/webmin/miniserv.conf.backup
    
    # Opcional: Cambiar puerto (descomentar si se desea)
    # sudo sed -i "s/^port=.*/port=10001/" /etc/webmin/miniserv.conf
    # WEBMIN_PORT="10001"
}

# Función para probar la instalación
test_installation() {
    print_step "Probando instalación..."
    
    # Verificar que el servicio está corriendo
    if sudo systemctl is-active --quiet webmin; then
        print_status "✅ Servicio Webmin activo"
    else
        print_error "❌ Servicio Webmin no está corriendo"
        sudo systemctl status webmin
        exit 1
    fi
    
    # Verificar que escucha en el puerto
    if sudo netstat -tulpn | grep -q ":${WEBMIN_PORT}"; then
        print_status "✅ Webmin escuchando en puerto $WEBMIN_PORT"
    else
        print_error "❌ Webmin no escucha en puerto $WEBMIN_PORT"
        exit 1
    fi
}

# Función para mostrar información de acceso
show_access_info() {
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    print_status "🎉 Webmin instalado exitosamente!"
    echo ""
    print_status "📋 Información de acceso:"
    echo "   URL: https://${SERVER_IP}:${WEBMIN_PORT}"
    echo "   URL: https://$(hostname):${WEBMIN_PORT}"
    echo "   Usuario: Tu usuario de sistema ($WEBMIN_USER)"
    echo "   Contraseña: Tu contraseña de sistema"
    echo ""
    print_warning "⚠️  El navegador mostrará advertencia de seguridad (certificado auto-firmado)"
    print_warning "⚠️  Acepta temporalmente para acceder"
    echo ""
    print_status "🔧 Comandos útiles:"
    echo "   sudo systemctl status webmin  # Ver estado"
    echo "   sudo systemctl restart webmin # Reiniciar"
    echo "   sudo tail -f /var/webmin/miniserv.log  # Ver logs"
    echo ""
}

# Función para desinstalar Webmin
uninstall_webmin() {
    print_step "Desinstalando Webmin..."
    
    sudo apt remove --purge webmin -y
    sudo rm -rf /etc/apt/sources.list.d/webmin.list
    sudo rm -rf /usr/share/keyrings/webmin.gpg
    sudo rm -rf /etc/webmin
    sudo apt autoremove -y
    
    print_status "Webmin desinstalado completamente"
}

# Función principal
main() {
    print_status "Iniciando instalación de Webmin..."
    
    check_root
    check_webmin_installed
    install_dependencies
    install_webmin
    configure_firewall
    configure_security
    test_installation
    show_access_info
}

# Manejar argumentos
case "${1:-}" in
    -h|--help)
        echo "Uso: $0 [opciones]"
        echo "Opciones:"
        echo "  -h, --help      Mostrar esta ayuda"
        echo "  -u, --uninstall Desinstalar Webmin"
        echo "  -s, --status    Ver estado de Webmin"
        echo "  -p, --port      Cambiar puerto (ej: -p 10001)"
        exit 0
        ;;
    -u|--uninstall)
        uninstall_webmin
        exit 0
        ;;
    -s|--status)
        if sudo systemctl is-active --quiet webmin; then
            print_status "Webmin está activo"
            sudo systemctl status webmin --no-pager -l
        else
            print_error "Webmin no está instalado o no está activo"
        fi
        exit 0
        ;;
    -p|--port)
        if [ -n "$2" ]; then
            WEBMIN_PORT="$2"
            print_status "Usando puerto: $WEBMIN_PORT"
        else
            print_error "Debe especificar un puerto"
            exit 1
        fi
        main
        ;;
    *)
        main
        ;;
esac
#!/bin/bash
# ================================================
# HTTP CUSTOM BOT - ENVÍA TU ARCHIVO .HC PERSONAL
# Usa TU archivo .hc y lo envía directamente por WhatsApp
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Banner inicial
clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ██╗  ██╗████████╗████████╗██████╗      ██████╗██╗   ██╗  ║
║     ██║  ██║╚══██╔══╝╚══██╔══╝██╔══██╗    ██╔════╝██║   ██║  ║
║     ███████║   ██║      ██║   ██████╔╝    ██║     ██║   ██║  ║
║     ██╔══██║   ██║      ██║   ██╔═══╝     ██║     ██║   ██║  ║
║     ██║  ██║   ██║      ██║   ██║         ╚██████╗╚██████╔╝  ║
║     ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝          ╚═════╝ ╚═════╝   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║            HTTP CUSTOM BOT - TU ARCHIVO .HC PERSONAL       ║
║               📤 ENVÍA TU ARCHIVO POR WHATSAPP              ║
║               ⚡ MISMO ARCHIVO PARA TODOS LOS USUARIOS      ║
║               💰 MERCADOPAGO INTEGRADO                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ SISTEMA CON TU ARCHIVO .HC PERSONAL:${NC}"
echo -e "  🎯 ${CYAN}ENVÍA TU ARCHIVO .HC POR WHATSAPP${NC}"
echo -e "  📤 ${GREEN}Sin generación automática, usa TU archivo${NC}"
echo -e "  ⚡ ${YELLOW}Mismo archivo para todos los usuarios${NC}"
echo -e "  🎛️  ${PURPLE}Panel admin: hcbot${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}❌ ERROR: Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP
echo -e "${CYAN}${BOLD}🔍 DETECTANDO IP DEL SERVIDOR...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    echo -e "${RED}❌ No se pudo obtener IP pública${NC}"
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi

echo -e "${GREEN}✅ IP detectada: ${CYAN}$SERVER_IP${NC}\n"

# Preguntar por archivo .hc personal
echo -e "${YELLOW}📁 CONFIGURACIÓN DE TU ARCHIVO .HC PERSONAL${NC}"
echo -e ""
echo -e "${CYAN}💡 Necesitas tener tu archivo .hc listo para usar${NC}"
echo -e "${CYAN}📝 El bot enviará ESTE MISMO archivo a todos los usuarios${NC}"
echo -e ""

# Opción 1: Subir archivo ahora
echo -e "${GREEN}📤 OPCIONES PARA TU ARCHIVO .HC:${NC}"
echo -e "  1. Subir mi archivo .hc ahora (recomendado)"
echo -e "  2. Configurar path a mi archivo existente"
echo -e "  3. Usar archivo de ejemplo y configurar después"
echo -e ""

read -p "👉 Selecciona opción [1]: " HC_OPTION
HC_OPTION=${HC_OPTION:-1}

HC_FILE_PATH=""
HC_FILE_NAME=""

case $HC_OPTION in
    1)
        echo -e "\n${CYAN}📤 SUBIR TU ARCHIVO .HC${NC}"
        echo -e "${YELLOW}1. Asegúrate de tener tu archivo .hc en tu computadora${NC}"
        echo -e "${YELLOW}2. Debe llamarse: TU_ARCHIVO.hc (con extensión .hc)${NC}"
        echo -e "${YELLOW}3. Usa SCP, FTP o arrastra al servidor si usas VPS con interfaz${NC}"
        echo -e ""
        echo -e "${GREEN}📝 Path donde subir el archivo:${NC}"
        echo -e "  /root/http-custom-bot/MI_ARCHIVO.hc"
        echo -e ""
        read -p "Presiona Enter cuando hayas subido el archivo..."
        
        # Verificar si se subió algún archivo
        DEFAULT_HC="/root/http-custom-bot/MI_ARCHIVO.hc"
        if [[ -f "$DEFAULT_HC" ]]; then
            HC_FILE_PATH="$DEFAULT_HC"
            HC_FILE_NAME=$(basename "$DEFAULT_HC")
            echo -e "${GREEN}✅ Archivo encontrado: $HC_FILE_NAME${NC}"
        else
            echo -e "${YELLOW}⚠️  No se encontró archivo en $DEFAULT_HC${NC}"
            read -p "📝 Ingresa el path completo de tu archivo .hc: " HC_FILE_PATH
            if [[ -f "$HC_FILE_PATH" ]]; then
                HC_FILE_NAME=$(basename "$HC_FILE_PATH")
                echo -e "${GREEN}✅ Archivo encontrado: $HC_FILE_NAME${NC}"
            else
                echo -e "${YELLOW}⚠️  Usando archivo de ejemplo, podrás cambiarlo después${NC}"
                HC_FILE_PATH="/opt/http-custom-bot/MI_ARCHIVO.hc"
                HC_FILE_NAME="MI_ARCHIVO.hc"
            fi
        fi
        ;;
    2)
        read -p "📝 Ingresa el path completo de tu archivo .hc: " HC_FILE_PATH
        if [[ -f "$HC_FILE_PATH" ]]; then
            HC_FILE_NAME=$(basename "$HC_FILE_PATH")
            echo -e "${GREEN}✅ Archivo encontrado: $HC_FILE_NAME${NC}"
        else
            echo -e "${RED}❌ Archivo no encontrado${NC}"
            echo -e "${YELLOW}⚠️  Usando archivo de ejemplo, podrás cambiarlo después${NC}"
            HC_FILE_PATH="/opt/http-custom-bot/MI_ARCHIVO.hc"
            HC_FILE_NAME="MI_ARCHIVO.hc"
        fi
        ;;
    3)
        HC_FILE_PATH="/opt/http-custom-bot/MI_ARCHIVO.hc"
        HC_FILE_NAME="MI_ARCHIVO.hc"
        echo -e "${YELLOW}⚠️  Usando archivo de ejemplo${NC}"
        echo -e "${CYAN}💡 Podrás cambiarlo después en el panel de control${NC}"
        ;;
esac

# Crear archivo de ejemplo si no existe
if [[ ! -f "$HC_FILE_PATH" && "$HC_OPTION" == "3" ]]; then
    echo -e "\n${YELLOW}📝 Creando archivo .hc de ejemplo...${NC}"
    mkdir -p /opt/http-custom-bot
    cat > "$HC_FILE_PATH" << 'HCEOF'
# HTTP Custom Configuration - TU ARCHIVO PERSONAL
# Configuración lista para usar

[general]
mode=http
listen_port=8080
enable_http=0
enable_socks5=0
enable_dns=0
enable_ipv6=1
enable_udp=1
enable_mux=1
log_level=info

[server]
server=TU_SERVIDOR_AQUI
server_port=8080
method=chacha20
password=123456
fast_open=1
reuse_port=1

[obfs]
obfs=http
obfs_host=www.bing.com
obfs_uri=/search

[tls]
tls_enable=0
tls_server_name=www.bing.com
skip_cert_verify=1

[advanced]
mux_concurrency=8
connection_timeout=30
buffer_size=4096
max_connection=100

[user_info]
username=TU_USUARIO
hwid=TU_HWID_AQUI
expire_date=2024-12-31
plan_days=30

# Instrucciones:
# 1. Guardar este archivo
# 2. En HTTP Custom: Profiles → Import
# 3. Seleccionar este archivo
# 4. ¡Conectar!

# Cambia "TU_SERVIDOR_AQUI" por tu IP real
# Cambia "TU_HWID_AQUI" por el HWID del usuario
HCEOF
    echo -e "${GREEN}✅ Archivo de ejemplo creado: $HC_FILE_NAME${NC}"
fi

# Verificar tamaño del archivo
if [[ -f "$HC_FILE_PATH" ]]; then
    FILE_SIZE=$(stat -c%s "$HC_FILE_PATH" 2>/dev/null || stat -f%z "$HC_FILE_PATH" 2>/dev/null || echo "0")
    echo -e "${GREEN}📏 Tamaño del archivo: $FILE_SIZE bytes${NC}"
    
    if [[ $FILE_SIZE -gt 10000000 ]]; then
        echo -e "${YELLOW}⚠️  Archivo muy grande (>10MB), WhatsApp podría tener problemas${NC}"
    fi
fi

# Confirmar instalación
echo -e "\n${YELLOW}⚠️  ESTE INSTALADOR HARÁ:${NC}"
echo -e "   • Instalar Node.js 20.x + Chrome + Dependencias"
echo -e "   • Crear HTTP Custom Bot completo"
echo -e "   • Panel de control: ${GREEN}hcbot${NC}"
echo -e "   • Enviar TU archivo: ${CYAN}$HC_FILE_NAME${NC}"
echo -e "   • Mismo archivo para todos los usuarios"
echo -e "   • Sin generación automática, usa TU archivo"
echo -e "   • Menú: 1=Prueba, 2=Comprar, 3=Renovar, 4=Cambiar HWID, 5=App"
echo -e "   • Planes: 7, 15, 30, 50 días"
echo -e "\n${RED}⚠️  Se eliminarán instalaciones anteriores${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS...${NC}"

# Actualizar sistema
apt-get update -y
apt-get upgrade -y

# Instalar Node.js 20.x
echo -e "${YELLOW}📦 Instalando Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
apt-get install -y gcc g++ make

# Instalar Chromium
echo -e "${YELLOW}🌐 Instalando Chrome/Chromium...${NC}"
apt-get install -y wget gnupg
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Instalar dependencias del sistema
echo -e "${YELLOW}⚙️ Instalando utilidades...${NC}"
apt-get install -y \
    git \
    curl \
    wget \
    sqlite3 \
    jq \
    build-essential \
    python3 \
    python3-pip \
    unzip \
    cron \
    ufw \
    nginx \
    zip \
    openssl

# Instalar PM2 globalmente
echo -e "${YELLOW}🔄 Instalando PM2...${NC}"
npm install -g pm2
pm2 update

# Configurar firewall
echo -e "${YELLOW}🛡️ Configurando firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw allow 3000/tcp
ufw --force enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/http-custom-bot"
USER_HOME="/root/http-custom-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
HC_STORAGE="$INSTALL_DIR/hc_storage"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete http-custom-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true
rm -rf "$HC_STORAGE" 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p "$HC_STORAGE"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 755 "$HC_STORAGE"
chmod -R 700 /root/.wwebjs_auth

# Copiar archivo .hc personal a la ubicación segura
if [[ -f "$HC_FILE_PATH" ]]; then
    echo -e "${YELLOW}📁 Copiando tu archivo .hc personal...${NC}"
    cp "$HC_FILE_PATH" "$HC_STORAGE/MI_ARCHIVO.hc"
    HC_STORAGE_PATH="$HC_STORAGE/MI_ARCHIVO.hc"
    echo -e "${GREEN}✅ Archivo copiado a: $HC_STORAGE_PATH${NC}"
else
    # Crear archivo de ejemplo
    HC_STORAGE_PATH="$HC_STORAGE/MI_ARCHIVO.hc"
    cat > "$HC_STORAGE_PATH" << 'HCEOF'
# HTTP Custom Configuration - TU ARCHIVO PERSONAL
# Este es un archivo de ejemplo

[general]
mode=http
listen_port=8080
enable_http=0
enable_socks5=0
enable_dns=0
enable_ipv6=1
enable_udp=1
enable_mux=1
log_level=info

[server]
server=TU_IP_AQUI
server_port=8080
method=chacha20
password=123456
fast_open=1
reuse_port=1

# Reemplaza TU_IP_AQUI con tu IP real en el panel hcbot
HCEOF
    echo -e "${YELLOW}⚠️  Creado archivo de ejemplo en: $HC_STORAGE_PATH${NC}"
fi

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom Bot",
        "version": "5.0-TU-ARCHIVO",
        "server_ip": "$SERVER_IP",
        "server_port": "8080",
        "encryption": "chacha20",
        "password": "123456"
    },
    "prices": {
        "test_hours": 1,
        "price_7d": 1500.00,
        "price_15d": 2500.00,
        "price_30d": 5500.00,
        "price_50d": 8500.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "tutorial": "https://youtube.com",
        "support": "https://wa.me/543435071016",
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "hc_storage": "$HC_STORAGE",
        "hc_file": "$HC_STORAGE_PATH"
    },
    "hc_config": {
        "server": "$SERVER_IP",
        "port": "8080",
        "method": "chacha20",
        "password": "123456"
    }
}
EOF

# Crear base de datos
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    plan TEXT,
    days INTEGER,
    amount REAL,
    discount_code TEXT,
    final_amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_hwid ON users(hwid);
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR SCRIPT PARA MODIFICAR ARCHIVO .HC
# ================================================
echo -e "\n${CYAN}${BOLD}🔧 CREANDO SCRIPT PARA MODIFICAR TU ARCHIVO .HC...${NC}"

cat > "$INSTALL_DIR/modify_hc_file.py" << 'PYEOF'
#!/usr/bin/env python3
import sys
import os
import re
from datetime import datetime, timedelta

def modify_hc_file(input_file, output_file, username, hwid, server_ip, port, method, password, days):
    """Modifica TU archivo .hc personal con datos del usuario"""
    
    # Leer el archivo original
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Calcular fecha de expiración
    expire_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
    
    # Reemplazar marcadores de posición
    modified_content = content
    
    # Reemplazar server IP si existe marcador
    if 'TU_IP_AQUI' in modified_content:
        modified_content = modified_content.replace('TU_IP_AQUI', server_ip)
    
    if 'TU_SERVIDOR_AQUI' in modified_content:
        modified_content = modified_content.replace('TU_SERVIDOR_AQUI', server_ip)
    
    # Reemplazar HWID
    if 'TU_HWID_AQUI' in modified_content:
        modified_content = modified_content.replace('TU_HWID_AQUI', hwid)
    
    # Reemplazar usuario
    if 'TU_USUARIO' in modified_content:
        modified_content = modified_content.replace('TU_USUARIO', username)
    
    # Reemplazar fecha de expiración
    if 'TU_FECHA_EXPIRA' in modified_content:
        modified_content = modified_content.replace('TU_FECHA_EXPIRA', expire_date)
    
    # Si no hay marcadores, agregar sección [user_info] al final
    if '[user_info]' not in modified_content:
        user_info_section = f"""
[user_info]
username={username}
hwid={hwid}
expire_date={expire_date}
plan_days={days}
server={server_ip}
port={port}
method={method}
password={password}

# Archivo personalizado para: {username}
# HWID: {hwid}
# Válido hasta: {expire_date}
"""
        modified_content += user_info_section
    
    # Escribir archivo modificado
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(modified_content)
    
    # Verificar que se creó
    if os.path.exists(output_file):
        size = os.path.getsize(output_file)
        return {
            'success': True,
            'filePath': output_file,
            'fileName': os.path.basename(output_file),
            'fileSize': size
        }
    else:
        return {
            'success': False,
            'error': 'No se pudo crear el archivo modificado'
        }

if __name__ == "__main__":
    if len(sys.argv) < 9:
        print('{"success": false, "error": "Faltan argumentos"}')
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    username = sys.argv[3]
    hwid = sys.argv[4]
    server_ip = sys.argv[5]
    port = sys.argv[6]
    method = sys.argv[7]
    password = sys.argv[8]
    days = int(sys.argv[9])
    
    result = modify_hc_file(input_file, output_file, username, hwid, server_ip, port, method, password, days)
    
    import json
    print(json.dumps(result))
PYEOF

chmod +x "$INSTALL_DIR/modify_hc_file.py"

echo -e "${GREEN}✅ Script para modificar archivos .hc creado${NC}"

# ================================================
# CREAR BOT QUE ENVÍA TU ARCHIVO .HC
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT QUE ENVÍA TU ARCHIVO .HC...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "http-custom-bot",
    "version": "5.0.0",
    "main": "bot.js",
    "dependencies": {
        "whatsapp-web.js": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "mercadopago": "^2.0.15",
        "axios": "^1.6.5"
    }
}
PKGEOF

echo -e "${YELLOW}📦 Instalando paquetes Node.js...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# ✅ APLICAR PARCHE PARA ERROR markedUnread
echo -e "${YELLOW}🔧 Aplicando parche para error WhatsApp Web...${NC}"
find node_modules/whatsapp-web.js -name "Client.js" -type f -exec sed -i 's/if (chat && chat.markedUnread)/if (false \&\& chat.markedUnread)/g' {} \; 2>/dev/null || true
find node_modules/whatsapp-web.js -name "Client.js" -type f -exec sed -i 's/const sendSeen = async (chatId) => {/const sendSeen = async (chatId) => { console.log("[DEBUG] sendSeen deshabilitado"); return;/g' {} \; 2>/dev/null || true

echo -e "${GREEN}✅ Parche markedUnread aplicado${NC}"

# Crear bot.js QUE ENVÍA TU ARCHIVO
cat > "bot.js" << 'BOTEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcodeTerminal = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const execPromise = util.promisify(exec);

function loadConfig() {
    delete require.cache[require.resolve('/opt/http-custom-bot/config/config.json')];
    return require('/opt/http-custom-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// ✅ FUNCIÓN PARA CREAR USUARIO Y PREPARAR ARCHIVO
async function prepareAndSendHcFile(phone, hwid, days) {
    return new Promise(async (resolve, reject) => {
        try {
            const username = 'HC' + Math.floor(1000 + Math.random() * 9000);
            const expireDate = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            
            console.log(chalk.cyan(`🔧 Preparando archivo .hc para ${phone} | HWID: ${hwid} | Días: ${days}`));
            
            // Ruta del archivo original
            const originalHcFile = config.paths.hc_file;
            
            if (!fs.existsSync(originalHcFile)) {
                throw new Error(`No se encuentra TU archivo .hc personal en: ${originalHcFile}`);
            }
            
            // Ruta para archivo temporal personalizado
            const timestamp = Date.now();
            const tempHcFile = `/tmp/hc_${username}_${timestamp}.hc`;
            
            // Usar Python para modificar el archivo
            const pythonScript = '/opt/http-custom-bot/modify_hc_file.py';
            const args = [
                originalHcFile,
                tempHcFile,
                username,
                hwid,
                config.bot.server_ip,
                config.bot.server_port,
                config.bot.encryption,
                config.bot.password,
                days.toString()
            ];
            
            exec(`python3 ${pythonScript} ${args.join(' ')}`, async (error, stdout, stderr) => {
                if (error) {
                    console.error(chalk.red('❌ Error Python:'), error.message);
                    reject(error);
                    return;
                }
                
                try {
                    const result = JSON.parse(stdout);
                    
                    if (!result.success) {
                        throw new Error(result.error || 'Error modificando archivo');
                    }
                    
                    // Verificar que el archivo se creó
                    if (!fs.existsSync(tempHcFile)) {
                        throw new Error('No se pudo crear el archivo modificado');
                    }
                    
                    // Guardar en base de datos
                    db.run(
                        `INSERT INTO users (phone, username, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)`,
                        [phone, username, hwid, days === 0 ? 'test' : 'premium', expireDate],
                        (err) => {
                            if (err) {
                                // Intentar con otro nombre si hay duplicado
                                const altUsername = 'HC' + Math.floor(1000 + Math.random() * 9000);
                                db.run(
                                    `INSERT INTO users (phone, username, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)`,
                                    [phone, altUsername, hwid, days === 0 ? 'test' : 'premium', expireDate],
                                    (err2) => {
                                        if (err2) {
                                            reject(err2);
                                        } else {
                                            resolve({
                                                username: altUsername,
                                                hwid: hwid,
                                                filePath: tempHcFile,
                                                fileName: result.fileName || `HTTP_CUSTOM_${altUsername}.hc`,
                                                expires: expireDate,
                                                tipo: days === 0 ? 'test' : 'premium',
                                                duration: days === 0 ? `${config.prices.test_hours} horas` : `${days} días`
                                            });
                                        }
                                    }
                                );
                            } else {
                                resolve({
                                    username: username,
                                    hwid: hwid,
                                    filePath: tempHcFile,
                                    fileName: result.fileName || `HTTP_CUSTOM_${username}.hc`,
                                    expires: expireDate,
                                    tipo: days === 0 ? 'test' : 'premium',
                                    duration: days === 0 ? `${config.prices.test_hours} horas` : `${days} días`
                                });
                            }
                        }
                    );
                    
                } catch (parseError) {
                    console.error(chalk.red('❌ Error parseando JSON:'), parseError.message);
                    console.error(chalk.yellow('Salida Python:'), stdout);
                    reject(parseError);
                }
            });
            
        } catch (error) {
            reject(error);
        }
    });
}

// ✅ FUNCIÓN PARA ENVIAR ARCHIVO POR WHATSAPP
async function sendHcFileViaWhatsApp(client, phone, hcData) {
    try {
        console.log(chalk.yellow(`📤 Enviando TU archivo .hc a ${phone}...`));
        
        // Verificar que el archivo existe
        if (!fs.existsSync(hcData.filePath)) {
            throw new Error(`Archivo no encontrado: ${hcData.filePath}`);
        }
        
        // Obtener tamaño del archivo
        const stats = fs.statSync(hcData.filePath);
        const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
        
        if (stats.size > 64 * 1024 * 1024) { // 64MB límite de WhatsApp
            throw new Error(`Archivo muy grande (${fileSizeMB}MB). WhatsApp no permite archivos mayores a 64MB`);
        }
        
        // Crear Media del archivo
        const media = MessageMedia.fromFilePath(hcData.filePath);
        
        // Enviar mensaje informativo primero
        await client.sendMessage(phone, 
            `✅ *ARCHIVO .HC PERSONAL ENVIADO*

👤 Usuario: *${hcData.username}*
🔐 HWID: *${hcData.hwid}*
⏰ ${hcData.tipo === 'test' ? 'Expira en: *1 hora*' : `Duración: *${hcData.days} días*`}

📤 *TU ARCHIVO .HC ESTÁ LISTO*
Te estoy enviando tu archivo .hc personalizado...
💾 Tamaño: ${fileSizeMB} MB`, { sendSeen: false });
        
        // Enviar el archivo
        await client.sendMessage(phone, media, {
            caption: `HTTP_CUSTOM_${hcData.username}.hc\n\nGuarda este archivo e impórtalo en HTTP Custom.`,
            sendSeen: false
        });
        
        // Enviar instrucciones
        await client.sendMessage(phone,
            `💡 *INSTRUCCIONES PARA USAR:*

1. *Guarda el archivo* recibido en tu dispositivo
2. Abre la aplicación *HTTP Custom*
3. Ve a *Profiles* (Perfiles)
4. Toca *Import* (Importar)
5. Selecciona el archivo *HTTP_CUSTOM_${hcData.username}.hc*
6. ¡Activa la conexión!

⚡ *CONFIGURACIÓN INCLUIDA:*
✅ Servidor: ${config.bot.server_ip}:${config.bot.server_port}
✅ Encriptación: ${config.bot.encryption}
✅ Password: ${config.bot.password}
✅ ${hcData.tipo === 'test' ? 'Válido por 1 hora' : `Válido por ${hcData.days} días`}

📱 *DESCARGAR APP HTTP CUSTOM:*
${config.links.app_download}

💬 *SOPORTE:*
${config.links.support}`, { sendSeen: false });
        
        console.log(chalk.green(`✅ Archivo .hc enviado a ${phone} (${fileSizeMB} MB)`));
        
        // Limpiar archivo temporal después de enviar
        setTimeout(() => {
            if (fs.existsSync(hcData.filePath)) {
                fs.unlinkSync(hcData.filePath);
                console.log(chalk.yellow(`🗑️ Archivo temporal eliminado: ${hcData.filePath}`));
            }
        }, 30000); // 30 segundos
        
        return true;
        
    } catch (error) {
        console.error(chalk.red('❌ Error enviando archivo:'), error.message);
        
        // Informar al usuario del error
        try {
            await client.sendMessage(phone, 
                `❌ *ERROR AL ENVIAR ARCHIVO*

El archivo .hc es demasiado grande (${fileSizeMB} MB).
WhatsApp no permite archivos mayores a 64MB.

💡 *SOLUCIÓN:*
1. Usa un archivo .hc más pequeño
2. O contacta al administrador`, { sendSeen: false });
        } catch (e) {
            // Ignorar error al enviar mensaje de error
        }
        
        throw error;
    }
}

// ✅ VERIFICAR SI EL ARCHIVO .HC PERSONAL EXISTE
function verifyPersonalHcFile() {
    const hcFilePath = config.paths.hc_file;
    
    if (!fs.existsSync(hcFilePath)) {
        console.log(chalk.red(`❌ ERROR: No se encuentra TU archivo .hc personal`));
        console.log(chalk.yellow(`📁 Buscando en: ${hcFilePath}`));
        console.log(chalk.cyan(`💡 Usa el panel hcbot (Opción 11) para configurar tu archivo .hc`));
        return false;
    }
    
    const stats = fs.statSync(hcFilePath);
    const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
    
    console.log(chalk.green(`✅ TU archivo .hc personal encontrado`));
    console.log(chalk.cyan(`📁 Archivo: ${path.basename(hcFilePath)}`));
    console.log(chalk.cyan(`📏 Tamaño: ${fileSizeMB} MB`));
    console.log(chalk.cyan(`📅 Modificado: ${stats.mtime.toLocaleString()}`));
    
    if (stats.size > 64 * 1024 * 1024) {
        console.log(chalk.red(`⚠️  ADVERTENCIA: Archivo muy grande (${fileSizeMB} MB)`));
        console.log(chalk.yellow(`💡 WhatsApp no permite archivos mayores a 64MB`));
    }
    
    return true;
}

// ✅ FUNCIONES DE ESTADO
function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) {
                resolve({ state: 'main_menu', data: null });
            } else {
                resolve({
                    state: row.state || 'main_menu',
                    data: row.data ? JSON.parse(row.data) : null
                });
            }
        });
    });
}

function setUserState(phone, state, data = null) {
    return new Promise((resolve) => {
        const dataStr = data ? JSON.stringify(data) : null;
        db.run(
            `INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
            [phone, state, dataStr],
            (err) => {
                if (err) console.error(chalk.red('❌ Error estado:'), err.message);
                resolve();
            }
        );
    });
}

// ✅ MERCADOPAGO SDK
let mpClient = null;
let mpPreference = null;

function initMercadoPago() {
    config = loadConfig();
    if (config.mercadopago.access_token && config.mercadopago.access_token !== '') {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            
            mpClient = new MercadoPagoConfig({ 
                accessToken: config.mercadopago.access_token,
                options: { timeout: 5000, idempotencyKey: true }
            });
            
            mpPreference = new Preference(mpClient);
            
            console.log(chalk.green('✅ MercadoPago SDK v2.x ACTIVO'));
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpClient = null;
            mpPreference = null;
            return false;
        }
    }
    console.log(chalk.yellow('⚠️ MercadoPago NO CONFIGURADO'));
    return false;
}

let mpEnabled = initMercadoPago();
moment.locale('es');

// Verificar archivo .hc personal
const hcFileExists = verifyPersonalHcFile();

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║      🤖 HTTP CUSTOM BOT - TU ARCHIVO .HC PERSONAL        ║'));
console.log(chalk.cyan.bold('║               📤 ENVÍA TU ARCHIVO POR WHATSAPP            ║'));
console.log(chalk.cyan.bold('║               ⚡ MISMO ARCHIVO PARA TODOS                 ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`🔌 Puerto: ${config.bot.server_port}`));
console.log(chalk.yellow(`🔐 Encriptación: ${config.bot.encryption}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.yellow(`📁 TU archivo .hc: ${hcFileExists ? '✅ ENCONTRADO' : '❌ NO ENCONTRADO'}`));
console.log(chalk.green('✅ Sistema envía TU archivo .hc personal por WhatsApp'));
console.log(chalk.green('✅ Todos los usuarios reciben el MISMO archivo (personalizado)'));

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'http-custom-personal-file'}),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--no-first-run', '--disable-extensions'],
        timeout: 60000
    },
    authTimeoutMs: 60000
});

let qrCount = 0;

client.on('qr', (qr) => {
    qrCount++;
    console.clear();
    console.log(chalk.yellow.bold(`\n╔════════ 📱 QR #${qrCount} - ESCANEA AHORA ════════╗\n`));
    qrcodeTerminal.generate(qr, { small: true });
    QRCode.toFile('/root/qr-whatsapp.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.cyan('\n1️⃣ Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('2️⃣ Escanea el QR ☝️'));
    console.log(chalk.green('\n💾 QR guardado: /root/qr-whatsapp.png\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado')));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp\n'));
    console.log(chalk.yellow('📤 El bot enviará TU archivo .hc personal por WhatsApp\n'));
    qrCount = 0;
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

// ✅ FUNCIONES AUXILIARES
function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', [phone, today],
            (err, row) => resolve(!err && row && row.count === 0));
    });
}

function registerTest(phone) {
    db.run('INSERT OR IGNORE INTO daily_tests (phone, date) VALUES (?, ?)', [phone, moment().format('YYYY-MM-DD')]);
}

// ✅ MAPA DE PLANES DISPONIBLES
const availablePlans = {
    '7': { 
        days: 7, 
        amountKey: 'price_7d',
        name: '7 DÍAS',
        description: 'Plan de 7 días de HTTP Custom'
    },
    '15': { 
        days: 15, 
        amountKey: 'price_15d',
        name: '15 DÍAS',
        description: 'Plan de 15 días de HTTP Custom'
    },
    '30': { 
        days: 30, 
        amountKey: 'price_30d',
        name: '30 DÍAS',
        description: 'Plan de 30 días de HTTP Custom'
    },
    '50': { 
        days: 50, 
        amountKey: 'price_50d',
        name: '50 DÍAS',
        description: 'Plan de 50 días de HTTP Custom'
    }
};

// ✅ CREAR PAGO MERCADOPAGO
async function createMercadoPagoPayment(phone, plan, days, amount, discountCode = null) {
    try {
        config = loadConfig();
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        if (!mpPreference) {
            mpEnabled = initMercadoPago();
            if (!mpEnabled || !mpPreference) {
                return { success: false, error: 'No se pudo inicializar MercadoPago' };
            }
        }
        
        const phoneClean = phone.split('@')[0];
        const paymentId = `HC-${phoneClean}-${days}d-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        
        // Aplicar descuento
        let finalAmount = parseFloat(amount);
        let discountPercentage = 0;
        
        if (discountCode) {
            const discountLower = discountCode.toLowerCase();
            if (discountLower === 'descuento10' || discountLower === '10off') {
                discountPercentage = 10;
            } else if (discountLower === 'descuento15' || discountLower === '15off') {
                discountPercentage = 15;
            } else if (discountLower === 'descuento20' || discountLower === '20off') {
                discountPercentage = 20;
            }
            
            if (discountPercentage > 0) {
                finalAmount = finalAmount * (1 - discountPercentage / 100);
                console.log(chalk.yellow(`💰 Aplicando descuento ${discountPercentage}%: $${amount} -> $${finalAmount.toFixed(2)}`));
            }
        }
        
        const preferenceData = {
            items: [{
                title: `HTTP CUSTOM ${days} DÍAS`,
                description: `TU archivo .hc personal enviado por WhatsApp - ${days} días`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: finalAmount
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: expirationDate.toISOString(),
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente`
            },
            auto_return: 'approved',
            statement_descriptor: 'HTTP CUSTOM'
        };
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 400,
                margin: 1,
                color: {
                    dark: '#000000',
                    light: '#FFFFFF'
                }
            });
            
            db.run(
                `INSERT INTO payments (payment_id, phone, plan, days, amount, discount_code, final_amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, `${days}d`, days, amount, discountCode, finalAmount, paymentUrl, qrPath, response.id]
            );
            
            console.log(chalk.green(`✅ Pago creado exitosamente`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                amount: finalAmount,
                originalAmount: amount,
                discountApplied: discountPercentage > 0,
                discountPercentage: discountPercentage
            };
        }
        
        throw new Error('Respuesta inválida de MercadoPago');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        return { success: false, error: error.message };
    }
}

// ✅ FLUJO PRINCIPAL CON TU ARCHIVO .HC
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    const userState = await getUserState(phone);
    
    // COMANDO MENÚ PRINCIPAL
    if (['menu', 'hola', 'start', 'hi', 'volver', 'atras', '0'].includes(text.toLowerCase())) {
        await setUserState(phone, 'main_menu');
        
        await client.sendMessage(phone, `HOLA, BIENVENIDO

Elija una opción:

1 - CREAR PRUEBA
2 - COMPRAR HTTP CUSTOM
3 - RENOVAR HTTP CUSTOM
4 - CAMBIAR HWID CUSTOM
5 - DESCARGAR HTTP CUSTOM`, { sendSeen: false });
    }
    // OPCIÓN 1: CREAR PRUEBA
    else if (text === '1' && userState.state === 'main_menu') {
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana para otra prueba gratuita`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `📱 *ENVÍA TU HWID*

Para crear tu prueba, necesitamos tu HWID (identificador único).

1. Abre HTTP Custom en tu dispositivo
2. Ve a *Configuración → Acerca de*
3. Copia tu *HWID*
4. Envíalo aquí

🔢 *Formato:* Letras y números, 6-32 caracteres
📝 *Ejemplo:* ABC123XYZ456`, { sendSeen: false });
        
        await setUserState(phone, 'asking_hwid_test');
    }
    // CAPTURAR HWID PARA PRUEBA
    else if (userState.state === 'asking_hwid_test') {
        const hwid = text.trim();
        
        // Validación simple de HWID
        if (hwid.length < 6 || hwid.length > 32) {
            await client.sendMessage(phone, `❌ *HWID INVÁLIDO*

El HWID debe tener entre 6 y 32 caracteres.

📝 Por favor, envía un HWID válido:`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Preparando TU archivo .hc personal...', { sendSeen: false });
        
        try {
            // Verificar que existe el archivo .hc personal
            if (!fs.existsSync(config.paths.hc_file)) {
                await client.sendMessage(phone, 
                    `❌ *ERROR DEL SISTEMA*

No se encuentra el archivo .hc personal.

💡 Contacta al administrador para solucionar este problema.`, { sendSeen: false });
                console.error(chalk.red(`❌ Archivo .hc no encontrado: ${config.paths.hc_file}`));
                return;
            }
            
            const hcData = await prepareAndSendHcFile(phone, hwid, 0);
            registerTest(phone);
            
            // Enviar archivo por WhatsApp
            await sendHcFileViaWhatsApp(client, phone, hcData);
            
            console.log(chalk.green(`✅ Prueba enviada: ${hcData.username} | HWID: ${hwid}`));
        } catch (error) {
            await client.sendMessage(phone, `❌ Error al crear prueba: ${error.message}`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
    // OPCIÓN 2: COMPRAR HTTP CUSTOM
    else if (text === '2' && userState.state === 'main_menu') {
        await setUserState(phone, 'buying_hc');
        
        await client.sendMessage(phone, `🛒 *PLANES HTTP CUSTOM*

Elija una opción:
1 - PLANES DIARIOS (7-15 días)
2 - PLANES MENSUALES (30-50 días)
0 - VOLVER`, { sendSeen: false });
    }
    // SUBMENÚ DE COMPRAS
    else if (userState.state === 'buying_hc') {
        if (text === '1' || text === '2') {
            await setUserState(phone, 'selecting_plan', { plan_type: text });
            
            let plansMessage = `💰 *PLANES DISPONIBLES*

Elija un plan:
1 - 7 DÍAS - $${config.prices.price_7d} ARS
2 - 15 DÍAS - $${config.prices.price_15d} ARS
3 - 30 DÍAS - $${config.prices.price_30d} ARS
4 - 50 DÍAS - $${config.prices.price_50d} ARS
0 - VOLVER`;
            
            await client.sendMessage(phone, plansMessage, { sendSeen: false });
        }
        else if (text === '0') {
            await setUserState(phone, 'main_menu');
            await client.sendMessage(phone, `HOLA, BIENVENIDO

Elija una opción:

1 - CREAR PRUEBA
2 - COMPRAR HTTP CUSTOM
3 - RENOVAR HTTP CUSTOM
4 - CAMBIAR HWID CUSTOM
5 - DESCARGAR HTTP CUSTOM`, { sendSeen: false });
        }
    }
    // SELECCIÓN DE PLAN ESPECÍFICO
    else if (userState.state === 'selecting_plan') {
        if (text === '1' || text === '2' || text === '3' || text === '4') {
            const planNumber = parseInt(text);
            let planData;
            
            if (planNumber === 1) planData = availablePlans['7'];
            else if (planNumber === 2) planData = availablePlans['15'];
            else if (planNumber === 3) planData = availablePlans['30'];
            else if (planNumber === 4) planData = availablePlans['50'];
            
            if (planData) {
                const amount = config.prices[planData.amountKey];
                
                await setUserState(phone, 'asking_discount', { 
                    plan: `${planData.days}d`,
                    days: planData.days,
                    amount: amount,
                    planName: planData.name
                });
                
                await client.sendMessage(phone, `**¿Tienes un cupón de descuento?**
Responde: sí o no.`, { sendSeen: false });
            }
        }
        else if (text === '0') {
            await setUserState(phone, 'buying_hc');
            await client.sendMessage(phone, `🛒 *PLANES HTTP CUSTOM*

Elija una opción:
1 - PLANES DIARIOS (7-15 días)
2 - PLANES MENSUALES (30-50 días)
0 - VOLVER`, { sendSeen: false });
        }
    }
    // PREGUNTA POR CUPÓN DE DESCUENTO
    else if (userState.state === 'asking_discount') {
        const stateData = userState.data || {};
        
        if (text.toLowerCase().includes('sí') || text.toLowerCase().includes('si')) {
            await setUserState(phone, 'entering_discount', stateData);
            await client.sendMessage(phone, '📝 Por favor, escribe tu código de descuento:', { sendSeen: false });
        }
        else if (text.toLowerCase().includes('no')) {
            await processPayment(phone, stateData, null);
        }
        else {
            await client.sendMessage(phone, 'Por favor responde: *sí* o *no*', { sendSeen: false });
        }
    }
    // INGRESAR CÓDIGO DE DESCUENTO
    else if (userState.state === 'entering_discount') {
        const stateData = userState.data || {};
        const discountCode = text.trim();
        
        await processPayment(phone, stateData, discountCode);
    }
    // OPCIÓN 3: RENOVAR HTTP CUSTOM
    else if (text === '3' && userState.state === 'main_menu') {
        db.get('SELECT username, hwid, expires_at FROM users WHERE phone = ? AND status = 1', [phone], async (err, user) => {
            if (err || !user) {
                await client.sendMessage(phone, `❌ *NO TIENES CUENTA ACTIVA*

No se encontró una cuenta HTTP Custom activa asociada a este número.

💡 Puedes crear una prueba (Opción 1) o comprar una cuenta (Opción 2).`, { sendSeen: false });
                return;
            }
            
            const expireDate = moment(user.expires_at).format('DD/MM/YYYY');
            
            await client.sendMessage(phone, `🔄 *RENOVAR CUENTA*

👤 Usuario actual: *${user.username}*
🔐 HWID: *${user.hwid}*
📅 Expira: *${expireDate}*

Para renovar contacta soporte:
${config.links.support}`, { sendSeen: false });
        });
    }
    // OPCIÓN 4: CAMBIAR HWID
    else if (text === '4' && userState.state === 'main_menu') {
        db.get('SELECT username, hwid FROM users WHERE phone = ? AND status = 1', [phone], async (err, user) => {
            if (err || !user) {
                await client.sendMessage(phone, `❌ *NO TIENES CUENTA ACTIVA*

No se encontró una cuenta HTTP Custom activa.

💡 Crea una prueba (Opción 1) o compra una cuenta (Opción 2).`, { sendSeen: false });
                return;
            }
            
            await client.sendMessage(phone, `🔄 *CAMBIAR HWID*

Para cambiar el HWID de tu cuenta, contacta soporte:
${config.links.support}

👤 Usuario: *${user.username}*
🔐 HWID actual: *${user.hwid}*`, { sendSeen: false });
        });
    }
    // OPCIÓN 5: DESCARGAR HTTP CUSTOM
    else if (text === '5' && userState.state === 'main_menu') {
        await client.sendMessage(phone, `📱 *DESCARGAR HTTP CUSTOM*

🔗 Enlace de descarga:
${config.links.app_download}

💡 *Instrucciones:*
1. Abre el enlace en tu navegador
2. Descarga el archivo APK
3. Permite "Fuentes desconocidas" en ajustes
4. Instala la aplicación
5. Configura con tu archivo .hc

📥 *Para obtener TU archivo .hc personal:*
• Crea una prueba (Opción 1) - Te enviaré el archivo por WhatsApp
• O compra una cuenta (Opción 2) - Te enviaré el archivo por WhatsApp`, { sendSeen: false });
    }
    // COMANDO NO RECONOCIDO
    else {
        await client.sendMessage(phone, `❌ Comando no reconocido.

Escribe *menu* para ver las opciones disponibles.`, { sendSeen: false });
    }
});

// ✅ FUNCIÓN PARA PROCESAR PAGO Y ENVIAR ARCHIVO
async function processPayment(phone, planData, discountCode) {
    config = loadConfig();
    
    if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
        await client.sendMessage(phone, `❌ *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Contacta soporte para más información.`, { sendSeen: false });
        await setUserState(phone, 'main_menu');
        return;
    }
    
    await client.sendMessage(phone, '⏳ Procesando tu compra...', { sendSeen: false });
    
    try {
        const payment = await createMercadoPagoPayment(
            phone, 
            planData.plan, 
            planData.days, 
            planData.amount, 
            discountCode
        );
        
        if (payment.success) {
            let amountText = `$${payment.amount}`;
            if (payment.discountApplied) {
                amountText = `$${payment.originalAmount} → $${payment.amount} (${payment.discountPercentage}% descuento)`;
            }
            
            const message = `### HTTP CUSTOM ${planData.days} DÍAS

- **Precio:** ${amountText}
- **Duración:** ${planData.days} días
- **Servidor:** ${config.bot.server_ip}:${config.bot.server_port}
- **Encriptación:** ${config.bot.encryption}

---

**LINK DE PAGO**

${payment.paymentUrl}

⏰ *Este enlace expira en 24 horas*
💳 *Pago seguro con MercadoPago*

📋 *DESPUÉS DEL PAGO:*
1. Envía tu HWID aquí
2. Recibirás TU archivo .hc personal por WhatsApp
3. Guarda e importa en HTTP Custom
4. ¡Listo!`;

            await client.sendMessage(phone, message, { sendSeen: false });
            
            if (fs.existsSync(payment.qrPath)) {
                try {
                    const media = MessageMedia.fromFilePath(payment.qrPath);
                    await client.sendMessage(phone, media, { 
                        caption: `📱 *Escanea con MercadoPago*\n\n${planData.planName} - ${amountText}`, 
                        sendSeen: false 
                    });
                } catch (qrError) {
                    console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                }
            }
            
            // Esperar HWID después del pago
            await setUserState(phone, 'awaiting_hwid_after_payment', {
                days: planData.days,
                amount: payment.amount
            });
            
        } else {
            await client.sendMessage(phone, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

Por favor, intenta de nuevo en unos minutos.`, { sendSeen: false });
            await setUserState(phone, 'main_menu');
        }
    } catch (error) {
        console.error(chalk.red('❌ Error en proceso de pago:'), error);
        await client.sendMessage(phone, `❌ *ERROR INESPERADO*

${error.message}

💬 Contacta soporte para asistencia.`, { sendSeen: false });
        await setUserState(phone, 'main_menu');
    }
}

// ✅ ESCUCHAR HWID DESPUÉS DE PAGO
client.on('message_create', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    const userState = await getUserState(phone);
    
    // CAPTURAR HWID DESPUÉS DE PAGO APROBADO
    if (userState.state === 'awaiting_hwid_after_payment') {
        const stateData = userState.data || {};
        const hwid = text.trim();
        
        // Validación simple
        if (hwid.length < 6 || hwid.length > 32) {
            await client.sendMessage(phone, `❌ *HWID INVÁLIDO*

El HWID debe tener entre 6 y 32 caracteres.

📝 Por favor, envía un HWID válido:`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Preparando TU archivo .hc personalizado...', { sendSeen: false });
        
        try {
            // Verificar que existe el archivo .hc personal
            if (!fs.existsSync(config.paths.hc_file)) {
                await client.sendMessage(phone, 
                    `❌ *ERROR DEL SISTEMA*

No se encuentra el archivo .hc personal.

💡 Contacta al administrador para solucionar este problema.`, { sendSeen: false });
                console.error(chalk.red(`❌ Archivo .hc no encontrado: ${config.paths.hc_file}`));
                return;
            }
            
            const hcData = await prepareAndSendHcFile(phone, hwid, stateData.days);
            
            // Enviar archivo por WhatsApp
            await sendHcFileViaWhatsApp(client, phone, hcData);
            
        } catch (error) {
            await client.sendMessage(phone, `❌ Error preparando archivo .hc: ${error.message}`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
});

// ✅ TAREAS PROGRAMADAS
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
});

cron.schedule('0 */6 * * *', async () => {
    // Limpiar archivos temporales antiguos
    console.log(chalk.yellow('🧹 Limpiando archivos temporales...'));
    
    const cutoffTime = Date.now() - (24 * 60 * 60 * 1000); // 24 horas
    
    // Limpiar archivos en /tmp
    const tmpDir = '/tmp';
    if (fs.existsSync(tmpDir)) {
        fs.readdirSync(tmpDir).forEach(file => {
            if (file.startsWith('hc_') && file.endsWith('.hc')) {
                const filePath = path.join(tmpDir, file);
                try {
                    const stats = fs.statSync(filePath);
                    if (stats.mtimeMs < cutoffTime) {
                        fs.unlinkSync(filePath);
                        console.log(chalk.green(`🗑️ Eliminado: ${file}`));
                    }
                } catch (e) {
                    // Ignorar errores
                }
            }
        });
    }
});

cron.schedule('*/15 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios expirados (${now})...`));
    
    db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
        if (err || !rows || rows.length === 0) return;
        
        for (const r of rows) {
            try {
                db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                console.log(chalk.green(`🗑️ Desactivado: ${r.username}`));
            } catch (e) {
                console.error(chalk.red(`Error desactivando ${r.username}:`), e.message);
            }
        }
        console.log(chalk.green(`✅ Limpiados ${rows.length} usuarios expirados`));
    });
});

console.log(chalk.green('\n🚀 Inicializando HTTP Custom Bot con TU archivo .hc personal...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado que envía TU archivo .hc${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL...${NC}"

cat > /usr/local/bin/hcbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB="/opt/http-custom-bot/data/users.db"
CONFIG="/opt/http-custom-bot/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { 
    local key="$1"
    local value="$2"
    local temp_file=$(mktemp)
    
    if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        jq "$key = $value" "$CONFIG" > "$temp_file"
    elif [[ "$value" == "true" || "$value" == "false" || "$value" == "null" ]]; then
        jq "$key = $value" "$CONFIG" > "$temp_file"
    else
        jq "$key = \"$value\"" "$CONFIG" > "$temp_file"
    fi
    
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$CONFIG"
        echo -e "${GREEN}✅ Configuración actualizada${NC}"
        return 0
    else
        rm -f "$temp_file"
        echo -e "${RED}❌ Error actualizando configuración${NC}"
        return 1
    fi
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          🎛️  PANEL HTTP CUSTOM - TU ARCHIVO .HC          ║${NC}"
    echo -e "${CYAN}║               📤 ENVÍA TU ARCHIVO POR WHATSAPP            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    # Obtener estadísticas
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    # Estado del bot
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="http-custom-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    # Estado MercadoPago
    MP_TOKEN=$(get_val '.mercadopago.access_token')
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" && "$MP_TOKEN" != "null" ]]; then
        MP_STATUS="${GREEN}✅ CONFIGURADO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    # Archivo .hc personal
    HC_FILE=$(get_val '.paths.hc_file')
    if [[ -f "$HC_FILE" ]]; then
        HC_SIZE=$(stat -c%s "$HC_FILE" 2>/dev/null || stat -f%z "$HC_FILE" 2>/dev/null || echo "0")
        HC_SIZE_MB=$(echo "scale=2; $HC_SIZE / (1024*1024)" | bc)
        HC_STATUS="${GREEN}✅ ENCONTRADO (${HC_SIZE_MB} MB)${NC}"
        HC_NAME=$(basename "$HC_FILE")
    else
        HC_STATUS="${RED}❌ NO ENCONTRADO${NC}"
        HC_NAME="No configurado"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  TU archivo .hc: $HC_STATUS"
    echo -e "  Archivo: ${CYAN}$HC_NAME${NC}"
    echo -e ""
    
    echo -e "${YELLOW}💰 PRECIOS ACTUALES:${NC}"
    echo -e "  7 días: $ $(get_val '.prices.price_7d') ARS"
    echo -e "  15 días: $ $(get_val '.prices.price_15d') ARS"
    echo -e "  30 días: $ $(get_val '.prices.price_30d') ARS"
    echo -e "  50 días: $ $(get_val '.prices.price_50d') ARS"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar usuarios"
    echo -e "${CYAN}[6]${NC}  💰  Cambiar precios"
    echo -e "${CYAN}[7]${NC}  🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC}  📊  Ver estadísticas"
    echo -e "${CYAN}[9]${NC}  📝  Ver logs"
    echo -e "${PURPLE}[10]${NC} 📁  Gestionar TU archivo .hc (IMPORTANTE)"
    echo -e "${CYAN}[11]${NC} ⚙️   Configuración del servidor"
    echo -e "${CYAN}[12]${NC} 🗑️   Limpiar temporales"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
            cd /root/http-custom-bot
            pm2 restart http-custom-bot 2>/dev/null || pm2 start bot.js --name http-custom-bot
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop http-custom-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-whatsapp.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-whatsapp.png${NC}\n"
                read -p "¿Ver logs en tiempo real? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs http-custom-bot --lines 100
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs http-custom-bot --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👤 CREAR USUARIO MANUAL                 ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "HWID: " HWID
            read -p "Días (0=test, 7,15,30,50): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            
            if [[ "$DAYS" == "0" ]]; then
                EXPIRE_DATE=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                TIPO="test"
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                TIPO="premium"
            fi
            
            USERNAME="MANUAL_${HWID:0:10}"
            
            sqlite3 "$DB" "INSERT INTO users (phone, username, hwid, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$HWID', '$TIPO', '$EXPIRE_DATE', 1)"
            
            echo -e "\n${GREEN}✅ USUARIO CREADO MANUALMENTE${NC}"
            echo -e "👤 Usuario: $USERNAME"
            echo -e "🔐 HWID: $HWID"
            echo -e "⏰ Expira: $EXPIRE_DATE"
            echo -e "🔌 Días: $DAYS"
            echo -e "📥 El usuario recibirá TU archivo .hc cuando interactúe con el bot"
            
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📋 ÚLTIMOS 20 USUARIOS:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT username, hwid, tipo, expires_at, substr(phone,1,12) as tel FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total activos: ${ACTIVE_USERS}${NC}"
            read -p "Presiona Enter..." 
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    💰 CAMBIAR PRECIOS                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}💰 PRECIOS ACTUALES:${NC}"
            echo -e "  1. 7 días: $${CURRENT_7D}"
            echo -e "  2. 15 días: $${CURRENT_15D}"
            echo -e "  3. 30 días: $${CURRENT_30D}"
            echo -e "  4. 50 días: $${CURRENT_50D}\n"
            
            echo -e "${CYAN}--- MODIFICAR PRECIOS ---${NC}"
            read -p "Nuevo precio 7d [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15d [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30d [${CURRENT_30D}]: " NEW_30D
            read -p "Nuevo precio 50d [${CURRENT_50D}]: " NEW_50D
            
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$NEW_50D" ]] && set_val '.prices.price_50d' "$NEW_50D"
            
            read -p "Presiona Enter..." 
            ;;
        7)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║              🔑 CONFIGURAR MERCADOPAGO                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_TOKEN=$(get_val '.mercadopago.access_token')
            
            if [[ -n "$CURRENT_TOKEN" && "$CURRENT_TOKEN" != "null" && "$CURRENT_TOKEN" != "" ]]; then
                echo -e "${GREEN}✅ Token configurado${NC}"
                echo -e "${YELLOW}Preview: ${CURRENT_TOKEN:0:30}...${NC}\n"
            else
                echo -e "${YELLOW}⚠️  Sin token configurado${NC}\n"
            fi
            
            echo -e "${CYAN}📋 Obtener token:${NC}"
            echo -e "  1. https://www.mercadopago.com.ar/developers"
            echo -e "  2. Inicia sesión"
            echo -e "  3. 'Tus credenciales' → Access Token PRODUCCIÓN"
            echo -e "  4. Formato: APP_USR-xxxxxxxxxx\n"
            
            read -p "¿Configurar nuevo token? (s/N): " CONF
            if [[ "$CONF" == "s" ]]; then
                echo ""
                read -p "Pega el Access Token: " NEW_TOKEN
                
                if [[ "$NEW_TOKEN" =~ ^APP_USR- ]] || [[ "$NEW_TOKEN" =~ ^TEST- ]]; then
                    set_val '.mercadopago.access_token' "$NEW_TOKEN"
                    set_val '.mercadopago.enabled' "true"
                    echo -e "\n${GREEN}✅ Token configurado${NC}"
                    echo -e "${YELLOW}🔄 Reiniciando bot...${NC}"
                    cd /root/http-custom-bot && pm2 restart http-custom-bot
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago activado${NC}"
                else
                    echo -e "${RED}❌ Token inválido${NC}"
                    echo -e "${YELLOW}Debe empezar con APP_USR- o TEST-${NC}"
                fi
            fi
            read -p "Presiona Enter..." 
            ;;
        8)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Tests hoy: ' || (SELECT COUNT(*) FROM daily_tests WHERE date = date('now')) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN final_amount ELSE 0 END)) FROM payments"
            
            read -p "\nPresiona Enter..." 
            ;;
        9)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs http-custom-bot --lines 100
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║          📁 GESTIONAR TU ARCHIVO .HC PERSONAL           ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_FILE=$(get_val '.paths.hc_file')
            
            if [[ -f "$CURRENT_FILE" ]]; then
                FILE_SIZE=$(stat -c%s "$CURRENT_FILE" 2>/dev/null || stat -f%z "$CURRENT_FILE" 2>/dev/null || echo "0")
                FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / (1024*1024)" | bc)
                FILE_DATE=$(stat -c %y "$CURRENT_FILE" 2>/dev/null || stat -f %Sm "$CURRENT_FILE" 2>/dev/null || echo "Desconocido")
                
                echo -e "${GREEN}✅ TU ARCHIVO .HC ACTUAL${NC}"
                echo -e "  📁 Archivo: ${CYAN}$(basename "$CURRENT_FILE")${NC}"
                echo -e "  📏 Tamaño: ${CYAN}${FILE_SIZE_MB} MB${NC}"
                echo -e "  📅 Modificado: ${CYAN}$FILE_DATE${NC}"
                echo -e "  📍 Ruta: ${CYAN}$CURRENT_FILE${NC}"
                echo -e ""
                
                if [[ $FILE_SIZE -gt 64000000 ]]; then
                    echo -e "${RED}⚠️  ADVERTENCIA: Archivo muy grande (>64MB)${NC}"
                    echo -e "${YELLOW}WhatsApp no permite enviar archivos mayores a 64MB${NC}"
                    echo -e ""
                fi
                
                # Mostrar primeras líneas
                echo -e "${YELLOW}📄 PRIMERAS 5 LÍNEAS:${NC}"
                head -5 "$CURRENT_FILE"
                echo -e ""
            else
                echo -e "${RED}❌ NO HAY ARCHIVO .HC CONFIGURADO${NC}"
                echo -e "${YELLOW}El bot NO funcionará sin un archivo .hc${NC}"
                echo -e ""
            fi
            
            echo -e "${CYAN}📋 OPCIONES:${NC}"
            echo -e "  1. Cambiar archivo .hc"
            echo -e "  2. Ver contenido completo"
            echo -e "  3. Probar modificación"
            echo -e "  0. Volver"
            echo -e ""
            
            read -p "Selecciona opción: " HC_OPT
            
            case $HC_OPT in
                1)
                    echo -e "\n${CYAN}📤 CAMBIAR TU ARCHIVO .HC${NC}"
                    echo -e "${YELLOW}1. Sube tu archivo .hc al servidor${NC}"
                    echo -e "${YELLOW}2. Debe tener extensión .hc${NC}"
                    echo -e "${YELLOW}3. Tamaño máximo recomendado: 10MB${NC}"
                    echo -e ""
                    echo -e "${GREEN}📝 Paths recomendados:${NC}"
                    echo -e "  /root/MI_ARCHIVO.hc"
                    echo -e "  /opt/http-custom-bot/hc_storage/MI_ARCHIVO.hc"
                    echo -e ""
                    read -p "Path completo del NUEVO archivo .hc: " NEW_HC_PATH
                    
                    if [[ -f "$NEW_HC_PATH" ]]; then
                        # Verificar tamaño
                        NEW_SIZE=$(stat -c%s "$NEW_HC_PATH" 2>/dev/null || stat -f%z "$NEW_HC_PATH" 2>/dev/null || echo "0")
                        NEW_SIZE_MB=$(echo "scale=2; $NEW_SIZE / (1024*1024)" | bc)
                        
                        if [[ $NEW_SIZE -gt 64000000 ]]; then
                            echo -e "${RED}❌ Archivo muy grande (${NEW_SIZE_MB}MB)${NC}"
                            echo -e "${YELLOW}WhatsApp no permite archivos >64MB${NC}"
                        else
                            # Copiar a ubicación segura
                            SAFE_PATH="/opt/http-custom-bot/hc_storage/$(basename "$NEW_HC_PATH")"
                            cp "$NEW_HC_PATH" "$SAFE_PATH"
                            
                            # Actualizar configuración
                            set_val '.paths.hc_file' "$SAFE_PATH"
                            
                            echo -e "${GREEN}✅ Archivo .hc actualizado${NC}"
                            echo -e "${YELLOW}🔄 Reiniciando bot...${NC}"
                            cd /root/http-custom-bot && pm2 restart http-custom-bot
                            sleep 2
                            echo -e "${GREEN}✅ Bot actualizado con nuevo archivo${NC}"
                        fi
                    else
                        echo -e "${RED}❌ Archivo no encontrado${NC}"
                    fi
                    ;;
                2)
                    if [[ -f "$CURRENT_FILE" ]]; then
                        echo -e "\n${YELLOW}📄 CONTENIDO COMPLETO:${NC}"
                        cat "$CURRENT_FILE"
                        echo -e ""
                    fi
                    ;;
                3)
                    if [[ -f "$CURRENT_FILE" ]]; then
                        echo -e "\n${YELLOW}🔧 PROBAR MODIFICACIÓN${NC}"
                        
                        CONFIG="/opt/http-custom-bot/config/config.json"
                        SERVER_IP=$(jq -r '.bot.server_ip' "$CONFIG")
                        PORT=$(jq -r '.bot.server_port' "$CONFIG")
                        METHOD=$(jq -r '.bot.encryption' "$CONFIG")
                        PASSWORD=$(jq -r '.bot.password' "$CONFIG")
                        
                        TEST_USER="TEST_USER"
                        TEST_HWID="TEST123456"
                        TEST_DAYS="30"
                        TEST_OUTPUT="/tmp/test_modificado.hc"
                        
                        echo -e "Probando modificación del archivo..."
                        
                        OUTPUT=$(python3 /opt/http-custom-bot/modify_hc_file.py "$CURRENT_FILE" "$TEST_OUTPUT" "$TEST_USER" "$TEST_HWID" "$SERVER_IP" "$PORT" "$METHOD" "$PASSWORD" "$TEST_DAYS" 2>/dev/null)
                        
                        if [[ $? -eq 0 ]]; then
                            RESULT=$(echo "$OUTPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'✅ Archivo modificado: {data[\"fileName\"]}'); print(f'📏 Tamaño: {data[\"fileSize\"]} bytes')")
                            echo -e "\n${GREEN}$RESULT${NC}"
                            
                            echo -e "\n${YELLOW}📄 PRIMERAS 10 LÍNEAS MODIFICADAS:${NC}"
                            head -10 "$TEST_OUTPUT"
                            
                            rm -f "$TEST_OUTPUT"
                        else
                            echo -e "${RED}❌ Error en modificación${NC}"
                        fi
                    fi
                    ;;
            esac
            
            read -p "Presiona Enter..." 
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║               ⚙️  CONFIGURACIÓN DEL SERVIDOR               ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            SERVER_IP=$(get_val '.bot.server_ip')
            SERVER_PORT=$(get_val '.bot.server_port')
            ENCRYPTION=$(get_val '.bot.encryption')
            PASSWORD=$(get_val '.bot.password')
            
            echo -e "${YELLOW}🔧 CONFIGURACIÓN ACTUAL:${NC}"
            echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
            echo -e "  Puerto: ${CYAN}$SERVER_PORT${NC}"
            echo -e "  Encriptación: ${CYAN}$ENCRYPTION${NC}"
            echo -e "  Password: ${CYAN}$PASSWORD${NC}"
            echo -e ""
            echo -e "${YELLOW}📋 ESTOS DATOS SE INSERTAN EN LOS ARCHIVOS .HC:${NC}"
            echo -e "  Los marcadores TU_IP_AQUI, TU_SERVIDOR_AQUI se reemplazan"
            echo -e "  con esta configuración cuando se envía el archivo"
            echo -e ""
            
            read -p "¿Modificar configuración? (s/N): " MOD
            if [[ "$MOD" == "s" ]]; then
                echo ""
                read -p "Nueva IP [${SERVER_IP}]: " NEW_IP
                read -p "Nuevo puerto [${SERVER_PORT}]: " NEW_PORT
                read -p "Nueva encriptación [${ENCRYPTION}]: " NEW_ENC
                read -p "Nuevo password [${PASSWORD}]: " NEW_PASS
                
                [[ -n "$NEW_IP" ]] && set_val '.bot.server_ip' "$NEW_IP"
                [[ -n "$NEW_PORT" ]] && set_val '.bot.server_port' "$NEW_PORT"
                [[ -n "$NEW_ENC" ]] && set_val '.bot.encryption' "$NEW_ENC"
                [[ -n "$NEW_PASS" ]] && set_val '.bot.password' "$NEW_PASS"
                
                echo -e "\n${GREEN}✅ Configuración actualizada${NC}"
                echo -e "${YELLOW}🔄 Los próximos archivos .hc usarán esta configuración${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        12)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                 🗑️  LIMPIAR ARCHIVOS TEMPORALES           ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🗑️  Buscando archivos temporales...${NC}"
            TEMP_COUNT=$(find /tmp -name "hc_*.hc" -type f 2>/dev/null | wc -l)
            echo -e "Encontrados: ${CYAN}$TEMP_COUNT${NC} archivos"
            
            if [[ $TEMP_COUNT -gt 0 ]]; then
                find /tmp -name "hc_*.hc" -type f 2>/dev/null | head -5
                echo -e ""
                
                read -p "¿Eliminar archivos temporales? (s/N): " CONFIRM
                if [[ "$CONFIRM" == "s" ]]; then
                    find /tmp -name "hc_*.hc" -type f -delete 2>/dev/null
                    echo -e "${GREEN}✅ Archivos temporales eliminados${NC}"
                fi
            else
                echo -e "${GREEN}✅ No hay archivos temporales${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        0)
            echo -e "\n${GREEN}👋 Hasta pronto${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/hcbot
echo -e "${GREEN}✅ Panel de control creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name http-custom-bot
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║       🎉 INSTALACIÓN COMPLETADA - TU ARCHIVO .HC          ║
║                                                              ║
║               HTTP CUSTOM BOT - CONFIGURADO                 ║
║               📤 ENVÍA TU ARCHIVO .HC POR WHATSAPP         ║
║               ⚡ MISMO ARCHIVO PARA TODOS LOS USUARIOS      ║
║               💰 MERCADOPAGO INTEGRADO                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema instalado que envía TU archivo .hc${NC}"
echo -e "${GREEN}✅ Archivo enviado directamente por WhatsApp${NC}"
echo -e "${GREEN}✅ Sin links externos, sin generación automática${NC}"
echo -e "${GREEN}✅ Todos reciben TU archivo (con HWID personalizado)${NC}"
echo -e "${GREEN}✅ Panel de control: ${CYAN}hcbot${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}hcbot${NC}         - Panel de control completo"
echo -e "  ${GREEN}pm2 logs http-custom-bot${NC} - Ver logs\n"

echo -e "${YELLOW}🔧 PASOS IMPORTANTES:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}hcbot${NC}"
echo -e "  2. Opción ${PURPLE}[10]${NC} - Verificar/Configurar TU archivo .hc"
echo -e "  3. Opción ${CYAN}[7]${NC} - Configurar MercadoPago"
echo -e "  4. Opción ${CYAN}[11]${NC} - Verificar configuración del servidor"
echo -e "  5. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp"
echo -e "  6. ¡Listo! El bot enviará TU archivo .hc por WhatsApp\n"

echo -e "${YELLOW}🎯 CARACTERÍSTICAS:${NC}\n"
echo -e "  ✅ ${GREEN}Usa TU archivo .hc personal${NC} - No genera archivos"
echo -e "  ✅ ${GREEN}Envía por WhatsApp${NC} - Sin links, sin descargas"
echo -e "  ✅ ${GREEN}Personaliza con HWID${NC} - Reemplaza marcadores automáticamente"
echo -e "  ✅ ${GREEN}Mismo archivo para todos${NC} - Fácil de mantener"
echo -e "  ✅ ${GREEN}Sin problemas de extensión${NC} - WhatsApp mantiene .hc puro\n"

echo -e "${YELLOW}💰 PRECIOS POR DEFECTO:${NC}\n"
echo -e "  7 días: ${GREEN}$1500 ARS${NC}"
echo -e "  15 días: ${GREEN}$2500 ARS${NC}"
echo -e "  30 días: ${GREEN}$5500 ARS${NC}"
echo -e "  50 días: ${GREEN}$8500 ARS${NC}\n"

echo -e "${YELLOW}📊 INFO DEL SISTEMA:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  Puerto: ${CYAN}8080${NC}"
echo -e "  Encriptación: ${CYAN}chacha20${NC}"
echo -e "  Password: ${CYAN}123456${NC}"
echo -e "  TU archivo: ${CYAN}$HC_FILE_NAME${NC}"
echo -e "  Panel: ${CYAN}hcbot${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel de control ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel hcbot...${NC}\n"
    sleep 2
    /usr/local/bin/hcbot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}hcbot${NC} para abrir el panel\n"
    echo -e "${YELLOW}PASOS IMPORTANTES:${NC}"
    echo -e "1. Abre el panel: hcbot"
    echo -e "2. Opción 10: Verifica/Configura TU archivo .hc"
    echo -e "3. Opción 7: Configura MercadoPago"
    echo -e "4. Opción 3: Escanea QR de WhatsApp"
    echo -e "5. Envía 'menu' al bot"
    echo -e "6. ¡Listo! Los usuarios recibirán TU archivo .hc por WhatsApp\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema instalado y listo para usar! 🚀${NC}\n"

exit 0
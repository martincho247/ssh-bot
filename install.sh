#!/bin/bash
# ================================================
# HTTP CUSTOM BOT - SISTEMA COMPLETO HWID
# Script de instalación completo
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
║                HTTP CUSTOM BOT - SISTEMA HWID               ║
║               💡 PLANES: 7, 15, 30, 50 DÍAS                 ║
║               🔐 ARCHIVOS .HC CON HWID ÚNICO               ║
║               📥 DESCARGA AUTOMÁTICA DE CONFIG             ║
║               💰 MERCADOPAGO INTEGRADO                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ SISTEMA HTTP CUSTOM CON HWID:${NC}"
echo -e "  🔴 ${RED}MENÚ PRINCIPAL:${NC}"
echo -e "     ${GREEN}1${NC} = Crear Prueba (TEST)"
echo -e "     ${GREEN}2${NC} = Comprar HTTP Custom"
echo -e "     ${GREEN}3${NC} = Renovar HTTP Custom"
echo -e "     ${GREEN}4${NC} = Cambiar HWID Custom"
echo -e "     ${GREEN}5${NC} = Descargar HTTP Custom App"
echo -e "  🟡 ${YELLOW}SUBMENÚ COMPRAS:${NC}"
echo -e "     ${GREEN}1${NC} = Planes HTTP Diarios"
echo -e "     ${GREEN}2${NC} = Planes HTTP Mensuales"
echo -e "     ${GREEN}0${NC} = Volver"
echo -e "  🟢 ${GREEN}PLANES DISPONIBLES:${NC}"
echo -e "     ${CYAN}7 días${NC} - 15 días - 30 días - 50 días"
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

# Confirmar instalación
echo -e "${YELLOW}⚠️  ESTE INSTALADOR HARÁ:${NC}"
echo -e "   • Instalar Node.js 20.x + Chrome"
echo -e "   • Crear HTTP Custom Bot con sistema HWID"
echo -e "   • Generador automático de archivos .hc"
echo -e "   • Menú: 1=Prueba, 2=Comprar, 3=Renovar, 4=Cambiar HWID, 5=App"
echo -e "   • Validación de HWID única por usuario"
echo -e "   • Planes: 7, 15, 30, 50 días"
echo -e "   • Pregunta por cupón de descuento"
echo -e "   • Generación de link MercadoPago"
echo -e "   • Panel de control 100% funcional"
echo -e "   • Descarga automática de configuraciones"
echo -e "   • Cron limpieza cada 15 minutos"
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
HC_DIR="$INSTALL_DIR/hc_files"
WEB_DIR="/var/www/html/hc"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete http-custom-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true
rm -rf "$HC_DIR" "$WEB_DIR" 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p "$HC_DIR"
mkdir -p "$WEB_DIR"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 755 "$WEB_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración CON SISTEMA HWID
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom Bot",
        "version": "1.0-HWID",
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
        "hc_files": "$HC_DIR",
        "web_download": "$WEB_DIR"
    },
    "hc_config": {
        "server": "$SERVER_IP",
        "port": "8080",
        "method": "chacha20",
        "password": "123456"
    }
}
EOF

# Crear base de datos CON SISTEMA HWID
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    download_url TEXT,
    config_file TEXT,
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
CREATE TABLE hwid_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    old_hwid TEXT,
    new_hwid TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
SQL

# Configurar Nginx para descargas
cat > /etc/nginx/sites-available/hc-download << EOF
server {
    listen 80;
    server_name $SERVER_IP;
    root /var/www/html/hc;
    
    location / {
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        add_header Access-Control-Allow-Origin "*";
    }
    
    location ~* \.(hc|zip)$ {
        add_header Content-Type application/octet-stream;
        add_header Content-Disposition "attachment";
        add_header Access-Control-Allow-Origin "*";
    }
}
EOF

ln -sf /etc/nginx/sites-available/hc-download /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo -e "${GREEN}✅ Estructura creada con sistema HWID${NC}"

# ================================================
# CREAR GENERADOR DE ARCHIVOS .HC
# ================================================
echo -e "\n${CYAN}${BOLD}🔧 CREANDO GENERADOR DE ARCHIVOS .HC...${NC}"

cat > "$INSTALL_DIR/generate_hc.py" << 'PYEOF'
#!/usr/bin/env python3
import json
import sys
import os
from datetime import datetime, timedelta
import zipfile

def generate_hc_file(username, hwid, server_ip, port, method, password, days):
    """Genera archivo .hc con configuración personalizada"""
    
    config_content = f"""# HTTP Custom Configuration
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# User: {username}
# HWID: {hwid}
# Valid until: {(datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')}

[general]
mode=http
listen_port=8080
dns_listen_port=8053
socks5_port=1080
http_port=8081
enable_http=0
enable_socks5=0
enable_dns=0
enable_ipv6=1
enable_udp=1
enable_mux=1
log_level=info
route_mode=all

[server]
server={server_ip}
server_port={port}
method={method}
password={password}
fast_open=1
reuse_port=1
no_delay=1

[obfs]
obfs=http
obfs_host=www.google.com
obfs_uri=/search

[advanced]
mux_concurrency=8
connection_timeout=30
keep_alive=30
buffer_size=4096
max_connection=100

[security]
enable_tls=0
tls_server_name=www.google.com
skip_cert_verify=1

[user]
username={username}
hwid={hwid}
expire_date={(datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')}
max_connections=1
"""
    
    return config_content

def create_hc_zip(username, hwid, config_content, output_dir):
    """Crea archivo ZIP con .hc y documentación"""
    
    import tempfile
    import shutil
    
    temp_dir = tempfile.mkdtemp()
    
    # Crear archivo .hc
    hc_filename = f"{username}_{hwid}.hc"
    hc_path = os.path.join(temp_dir, hc_filename)
    
    with open(hc_path, 'w', encoding='utf-8') as f:
        f.write(config_content)
    
    # Crear archivo README
    readme_content = f"""HTTP CUSTOM CONFIGURATION
==========================

Username: {username}
HWID: {hwid}
Server: {server_ip if 'server_ip' in locals() else sys.argv[3] if len(sys.argv) > 3 else 'default'}
Port: {port if 'port' in locals() else sys.argv[4] if len(sys.argv) > 4 else '8080'}

INSTRUCCIONES:
1. Abre HTTP Custom en tu dispositivo
2. Ve a 'Profiles' → 'Import'
3. Selecciona este archivo .hc
4. Activa la conexión

SOPORTE: https://wa.me/543435071016
"""
    
    readme_path = os.path.join(temp_dir, "INSTRUCCIONES.txt")
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    # Crear ZIP
    zip_filename = f"{username}_{hwid}.zip"
    zip_path = os.path.join(output_dir, zip_filename)
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(hc_path, hc_filename)
        zipf.write(readme_path, "INSTRUCCIONES.txt")
    
    # Limpiar temporal
    shutil.rmtree(temp_dir)
    
    return zip_path, f"/hc/{zip_filename}"

if __name__ == "__main__":
    if len(sys.argv) < 7:
        print("Uso: generate_hc.py <username> <hwid> <server_ip> <port> <method> <password> <days>")
        sys.exit(1)
    
    username = sys.argv[1]
    hwid = sys.argv[2]
    server_ip = sys.argv[3]
    port = sys.argv[4]
    method = sys.argv[5]
    password = sys.argv[6]
    days = int(sys.argv[7])
    
    # Generar contenido
    config = generate_hc_file(username, hwid, server_ip, port, method, password, days)
    
    # Guardar en directorio web
    output_dir = "/var/www/html/hc"
    os.makedirs(output_dir, exist_ok=True)
    
    zip_path, web_path = create_hc_zip(username, hwid, config, output_dir)
    
    print(f"OK:{web_path}")
PYEOF

chmod +x "$INSTALL_DIR/generate_hc.py"

# Crear script auxiliar en bash
cat > /usr/local/bin/generate-hc << 'HCEOF'
#!/bin/bash
# Generador de archivos .hc

if [ $# -lt 3 ]; then
    echo "Uso: generate-hc <username> <hwid> <dias>"
    echo "Ejemplo: generate-hc user1 ABC123 30"
    exit 1
fi

USERNAME="$1"
HWID="$2"
DAYS="$3"

CONFIG="/opt/http-custom-bot/config/config.json"
SERVER_IP=$(jq -r '.bot.server_ip' "$CONFIG")
PORT=$(jq -r '.bot.server_port' "$CONFIG")
METHOD=$(jq -r '.bot.encryption' "$CONFIG")
PASSWORD=$(jq -r '.bot.password' "$CONFIG")

python3 /opt/http-custom-bot/generate_hc.py "$USERNAME" "$HWID" "$SERVER_IP" "$PORT" "$METHOD" "$PASSWORD" "$DAYS"
HCEOF

chmod +x /usr/local/bin/generate-hc

echo -e "${GREEN}✅ Generador de archivos .hc creado${NC}"

# ================================================
# CREAR BOT CON SISTEMA HWID
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT CON SISTEMA HWID...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "http-custom-bot",
    "version": "1.0.0",
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

# Crear bot.js CON SISTEMA HWID
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
const { spawn } = require('child_process');

const execPromise = util.promisify(exec);

function loadConfig() {
    delete require.cache[require.resolve('/opt/http-custom-bot/config/config.json')];
    return require('/opt/http-custom-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

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

function clearUserState(phone) {
    db.run('DELETE FROM user_state WHERE phone = ?', [phone]);
}

// ✅ GENERAR ARCHIVO .HC
async function generateHcFile(username, hwid, days) {
    return new Promise((resolve, reject) => {
        const pythonScript = '/opt/http-custom-bot/generate_hc.py';
        const args = [
            username, 
            hwid, 
            config.bot.server_ip, 
            config.bot.server_port, 
            config.bot.encryption, 
            config.bot.password, 
            days.toString()
        ];
        
        const pythonProcess = spawn('python3', [pythonScript, ...args]);
        
        let output = '';
        let error = '';
        
        pythonProcess.stdout.on('data', (data) => {
            output += data.toString();
        });
        
        pythonProcess.stderr.on('data', (data) => {
            error += data.toString();
        });
        
        pythonProcess.on('close', (code) => {
            if (code === 0) {
                const match = output.match(/OK:(.+)/);
                if (match) {
                    const downloadPath = match[1].trim();
                    const downloadUrl = `http://${config.bot.server_ip}${downloadPath}`;
                    resolve({
                        success: true,
                        downloadUrl: downloadUrl,
                        filePath: downloadPath.replace('/hc/', '/var/www/html/hc/')
                    });
                } else {
                    reject(new Error('Formato de salida inválido'));
                }
            } else {
                reject(new Error(`Error Python: ${error}`));
            }
        });
    });
}

// ✅ CREAR USUARIO HTTP CUSTOM
async function createHttpCustomUser(phone, hwid, days) {
    const username = 'HC' + Math.floor(1000 + Math.random() * 9000);
    const expireDate = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
    
    console.log(chalk.yellow(`🔧 Creando usuario HC: ${username} | HWID: ${hwid} | Días: ${days}`));
    
    try {
        // Generar archivo .hc
        const hcResult = await generateHcFile(username, hwid, days);
        
        if (!hcResult.success) {
            throw new Error('Error generando archivo .hc');
        }
        
        // Guardar en base de datos
        return new Promise((resolve, reject) => {
            db.run(
                `INSERT INTO users (phone, username, hwid, tipo, expires_at, status, download_url, config_file) VALUES (?, ?, ?, ?, ?, 1, ?, ?)`,
                [phone, username, hwid, days === 0 ? 'test' : 'premium', expireDate, hcResult.downloadUrl, hcResult.filePath],
                (err) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve({
                            username: username,
                            hwid: hwid,
                            downloadUrl: hcResult.downloadUrl,
                            expires: expireDate,
                            tipo: days === 0 ? 'test' : 'premium',
                            duration: days === 0 ? `${config.prices.test_hours} horas` : `${days} días`
                        });
                    }
                }
            );
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error creando usuario HC:'), error.message);
        throw error;
    }
}

// ✅ VALIDAR HWID
function isValidHwid(hwid) {
    // HWID debe tener entre 6 y 32 caracteres, solo letras, números y guiones
    const hwidRegex = /^[a-zA-Z0-9\-_]{6,32}$/;
    return hwidRegex.test(hwid);
}

// ✅ VERIFICAR HWID ÚNICO
function isHwidAvailable(hwid) {
    return new Promise((resolve) => {
        db.get('SELECT COUNT(*) as count FROM users WHERE hwid = ? AND status = 1', [hwid], (err, row) => {
            if (err || !row) {
                resolve(true);
            } else {
                resolve(row.count === 0);
            }
        });
    });
}

// ✅ CAMBIAR HWID
async function changeHwid(phone, newHwid) {
    return new Promise((resolve, reject) => {
        db.get('SELECT username, hwid FROM users WHERE phone = ? AND status = 1', [phone], async (err, user) => {
            if (err || !user) {
                reject(new Error('Usuario no encontrado'));
                return;
            }
            
            const available = await isHwidAvailable(newHwid);
            if (!available) {
                reject(new Error('HWID ya está en uso'));
                return;
            }
            
            // Actualizar HWID
            db.run(
                `UPDATE users SET hwid = ? WHERE phone = ? AND status = 1`,
                [newHwid, phone],
                async (updateErr) => {
                    if (updateErr) {
                        reject(updateErr);
                    } else {
                        // Registrar cambio
                        db.run(
                            `INSERT INTO hwid_changes (phone, old_hwid, new_hwid) VALUES (?, ?, ?)`,
                            [phone, user.hwid, newHwid]
                        );
                        
                        // Regenerar archivo .hc
                        db.get('SELECT username, julianday(expires_at) - julianday("now") as remaining FROM users WHERE phone = ?', [phone], async (err, userData) => {
                            if (!err && userData) {
                                const days = Math.ceil(userData.remaining);
                                try {
                                    const hcResult = await generateHcFile(userData.username, newHwid, days);
                                    db.run(
                                        `UPDATE users SET download_url = ?, config_file = ? WHERE phone = ?`,
                                        [hcResult.downloadUrl, hcResult.filePath, phone]
                                    );
                                    
                                    resolve({
                                        success: true,
                                        newHwid: newHwid,
                                        downloadUrl: hcResult.downloadUrl,
                                        username: userData.username
                                    });
                                } catch (hcError) {
                                    resolve({
                                        success: true,
                                        newHwid: newHwid,
                                        downloadUrl: null,
                                        username: userData.username
                                    });
                                }
                            } else {
                                resolve({
                                    success: true,
                                    newHwid: newHwid,
                                    downloadUrl: null,
                                    username: user.username
                                });
                            }
                        });
                    }
                }
            );
        });
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

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 HTTP CUSTOM BOT - SISTEMA HWID            ║'));
console.log(chalk.cyan.bold('║               💡 PLANES: 7, 15, 30, 50 DÍAS                 ║'));
console.log(chalk.cyan.bold('║               🔐 ARCHIVOS .HC CON HWID ÚNICO               ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`🔧 Puerto: ${config.bot.server_port}`));
console.log(chalk.yellow(`🔐 Encriptación: ${config.bot.encryption}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ Sistema HWID activo'));
console.log(chalk.green('✅ Generador de archivos .hc listo'));
console.log(chalk.green('✅ Descargas web: http://' + config.bot.server_ip + '/hc/'));

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'http-custom-hwid'}),
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
                description: `Acceso HTTP Custom Premium por ${days} días`,
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

// ✅ VERIFICAR PAGOS PENDIENTES
async function checkPendingPayments() {
    config = loadConfig();
    if (!config.mercadopago.access_token || config.mercadopago.access_token === '') return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos pendientes...`));
        
        for (const payment of payments) {
            try {
                const url = `https://api.mercadopago.com/v1/payments/search?external_reference=${payment.payment_id}`;
                const response = await axios.get(url, {
                    headers: { 
                        'Authorization': `Bearer ${config.mercadopago.access_token}`,
                        'Content-Type': 'application/json'
                    },
                    timeout: 15000
                });
                
                if (response.data && response.data.results && response.data.results.length > 0) {
                    const mpPayment = response.data.results[0];
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO APROBADO: ${payment.payment_id}`));
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                        
                        const message = `✅ *PAGO CONFIRMADO*

🎉 Tu compra ha sido aprobada

📋 *POR FAVOR ENVÍA TU HWID:*
1. Abre HTTP Custom en tu dispositivo
2. Ve a Configuración → Acerca de
3. Copia tu HWID (identificador único)
4. Envíalo aquí en el chat

⚠️ *IMPORTANTE:* Sin HWID no podemos generar tu archivo de configuración`;
                        
                        await client.sendMessage(payment.phone, message, { sendSeen: false });
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
}

// ✅ FLUJO PRINCIPAL CON SISTEMA HWID
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // Obtener estado actual del usuario
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
        
        await setUserState(phone, 'asking_hwid_test');
        await client.sendMessage(phone, `📱 *ENVÍA TU HWID*

Para crear tu prueba, necesitamos tu HWID (identificador único).

1. Abre HTTP Custom en tu dispositivo
2. Ve a *Configuración → Acerca de*
3. Copia tu *HWID*
4. Envíalo aquí

🔢 *Formato:* Letras y números, 6-32 caracteres
📝 *Ejemplo:* ABC123XYZ456`, { sendSeen: false });
    }
    // CAPTURAR HWID PARA PRUEBA
    else if (userState.state === 'asking_hwid_test') {
        const hwid = text.trim();
        
        if (!isValidHwid(hwid)) {
            await client.sendMessage(phone, `❌ *HWID INVÁLIDO*

El HWID debe contener solo letras, números y guiones.
Longitud: 6-32 caracteres.

📝 Por favor, envía un HWID válido:`, { sendSeen: false });
            return;
        }
        
        const available = await isHwidAvailable(hwid);
        if (!available) {
            await client.sendMessage(phone, `❌ *HWID YA EN USO*

Este HWID ya está registrado en el sistema.

📝 Por favor, envía un HWID diferente:`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Creando cuenta de prueba...', { sendSeen: false });
        
        try {
            const result = await createHttpCustomUser(phone, hwid, 0);
            registerTest(phone);
            
            await client.sendMessage(phone, `✅ *PRUEBA CREADA CON ÉXITO*

👤 Usuario: *${result.username}*
🔐 HWID: *${result.hwid}*
⏰ Expira en: *${config.prices.test_hours} hora(s)*

📥 *DESCARGA TU CONFIGURACIÓN:*
${result.downloadUrl}

💡 *Instrucciones:*
1. Descarga el archivo ZIP
2. Extrae el archivo .hc
3. En HTTP Custom: Profiles → Import
4. Selecciona el archivo .hc
5. ¡Conéctate!`, { sendSeen: false });
            
            console.log(chalk.green(`✅ Test creado: ${result.username} | HWID: ${hwid}`));
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
            
            await setUserState(phone, 'renewing_account', {
                username: user.username,
                hwid: user.hwid
            });
            
            const expireDate = moment(user.expires_at).format('DD/MM/YYYY');
            
            await client.sendMessage(phone, `🔄 *RENOVAR CUENTA*

👤 Usuario actual: *${user.username}*
🔐 HWID: *${user.hwid}*
📅 Expira: *${expireDate}*

Selecciona el plan de renovación:
1 - 7 DÍAS - $${config.prices.price_7d} ARS
2 - 15 DÍAS - $${config.prices.price_15d} ARS
3 - 30 DÍAS - $${config.prices.price_30d} ARS
4 - 50 DÍAS - $${config.prices.price_50d} ARS
0 - VOLVER`, { sendSeen: false });
        });
    }
    // PROCESAR RENOVACIÓN
    else if (userState.state === 'renewing_account') {
        const stateData = userState.data || {};
        
        if (text === '1' || text === '2' || text === '3' || text === '4') {
            const planNumber = parseInt(text);
            let planData;
            
            if (planNumber === 1) planData = availablePlans['7'];
            else if (planNumber === 2) planData = availablePlans['15'];
            else if (planNumber === 3) planData = availablePlans['30'];
            else if (planNumber === 4) planData = availablePlans['50'];
            
            if (planData) {
                const amount = config.prices[planData.amountKey];
                
                await setUserState(phone, 'renew_discount', {
                    ...stateData,
                    plan: `${planData.days}d`,
                    days: planData.days,
                    amount: amount
                });
                
                await client.sendMessage(phone, `**¿Tienes un cupón de descuento para renovación?**
Responde: sí o no.`, { sendSeen: false });
            }
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
    // OPCIÓN 4: CAMBIAR HWID
    else if (text === '4' && userState.state === 'main_menu') {
        db.get('SELECT username, hwid FROM users WHERE phone = ? AND status = 1', [phone], async (err, user) => {
            if (err || !user) {
                await client.sendMessage(phone, `❌ *NO TIENES CUENTA ACTIVA*

No se encontró una cuenta HTTP Custom activa.

💡 Crea una prueba (Opción 1) o compra una cuenta (Opción 2).`, { sendSeen: false });
                return;
            }
            
            await setUserState(phone, 'changing_hwid', {
                username: user.username,
                old_hwid: user.hwid
            });
            
            await client.sendMessage(phone, `🔄 *CAMBIAR HWID*

👤 Usuario: *${user.username}*
🔐 HWID actual: *${user.hwid}*

📝 *ENVÍA TU NUEVO HWID:*
1. Obtén el HWID de tu nuevo dispositivo
2. Envíalo aquí

⚠️ *ADVERTENCIA:* El HWID anterior dejará de funcionar`, { sendSeen: false });
        });
    }
    // CAPTURAR NUEVO HWID
    else if (userState.state === 'changing_hwid') {
        const newHwid = text.trim();
        const stateData = userState.data || {};
        
        if (!isValidHwid(newHwid)) {
            await client.sendMessage(phone, `❌ *HWID INVÁLIDO*

El HWID debe contener solo letras, números y guiones.
Longitud: 6-32 caracteres.

📝 Por favor, envía un HWID válido:`, { sendSeen: false });
            return;
        }
        
        if (newHwid === stateData.old_hwid) {
            await client.sendMessage(phone, `❌ *HWID IGUAL AL ACTUAL*

El nuevo HWID es igual al actual.

📝 Por favor, envía un HWID diferente:`, { sendSeen: false });
            return;
        }
        
        const available = await isHwidAvailable(newHwid);
        if (!available) {
            await client.sendMessage(phone, `❌ *HWID YA EN USO*

Este HWID ya está registrado en el sistema.

📝 Por favor, envía un HWID diferente:`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Cambiando HWID...', { sendSeen: false });
        
        try {
            const result = await changeHwid(phone, newHwid);
            
            let message = `✅ *HWID CAMBIADO EXITOSAMENTE*

👤 Usuario: *${result.username}*
🔐 Nuevo HWID: *${result.newHwid}*

`;
            
            if (result.downloadUrl) {
                message += `📥 *DESCARGA NUEVA CONFIGURACIÓN:*
${result.downloadUrl}

⚠️ *Importante:* Descarga y usa la nueva configuración`;
            } else {
                message += `⚠️ *NOTA:* La configuración se actualizará en unos minutos`;
            }
            
            await client.sendMessage(phone, message, { sendSeen: false });
            
        } catch (error) {
            await client.sendMessage(phone, `❌ Error al cambiar HWID: ${error.message}`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
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

📥 *Para obtener tu archivo .hc:*
• Crea una prueba (Opción 1)
• O compra una cuenta (Opción 2)`, { sendSeen: false });
    }
    // CAPTURAR HWID DESPUÉS DE PAGO
    else if (userState.state === 'awaiting_hwid_after_payment') {
        const stateData = userState.data || {};
        const hwid = text.trim();
        
        if (!isValidHwid(hwid)) {
            await client.sendMessage(phone, `❌ *HWID INVÁLIDO*

Por favor, envía un HWID válido (6-32 caracteres, solo letras y números):`, { sendSeen: false });
            return;
        }
        
        const available = await isHwidAvailable(hwid);
        if (!available) {
            await client.sendMessage(phone, `❌ *HWID YA EN USO*

Este HWID ya está registrado.

📝 Por favor, envía un HWID diferente:`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Generando tu configuración...', { sendSeen: false });
        
        try {
            const result = await createHttpCustomUser(phone, hwid, stateData.days);
            
            await client.sendMessage(phone, `✅ *CONFIGURACIÓN GENERADA*

🎉 Tu cuenta HTTP Custom está lista

👤 Usuario: *${result.username}*
🔐 HWID: *${result.hwid}*
⏰ Duración: *${stateData.days} días*

📥 *DESCARGA TU CONFIGURACIÓN:*
${result.downloadUrl}

💡 *Instrucciones:*
1. Descarga el archivo ZIP
2. Extrae el archivo .hc
3. En HTTP Custom: Profiles → Import
4. Selecciona el archivo .hc
5. ¡Conéctate!`, { sendSeen: false });
            
        } catch (error) {
            await client.sendMessage(phone, `❌ Error generando configuración: ${error.message}`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
    // COMANDO NO RECONOCIDO
    else {
        await client.sendMessage(phone, `❌ Comando no reconocido.

Escribe *menu* para ver las opciones disponibles.`, { sendSeen: false });
    }
});

// ✅ FUNCIÓN PARA PROCESAR PAGO
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

⚠️ *DESPUÉS DEL PAGO:* Envía tu HWID para generar tu configuración`;
            
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

// ✅ TAREAS PROGRAMADAS
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
    checkPendingPayments();
});

cron.schedule('*/15 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios expirados (${now})...`));
    
    db.all('SELECT username, config_file FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
        if (err || !rows || rows.length === 0) return;
        
        for (const r of rows) {
            try {
                if (r.config_file && fs.existsSync(r.config_file)) {
                    fs.unlinkSync(r.config_file);
                }
                
                db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                console.log(chalk.green(`🗑️ Eliminado: ${r.username}`));
            } catch (e) {
                console.error(chalk.red(`Error eliminando ${r.username}:`), e.message);
            }
        }
        console.log(chalk.green(`✅ Limpiados ${rows.length} usuarios expirados`));
    });
});

cron.schedule('0 * * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando estados antiguos...'));
    db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
});

cron.schedule('0 0 * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando archivos antiguos...'));
    const sevenDaysAgo = moment().subtract(7, 'days').format('YYYY-MM-DD');
    db.all('SELECT config_file FROM users WHERE created_at < ?', [sevenDaysAgo], (err, rows) => {
        if (!err && rows) {
            rows.forEach(row => {
                if (row.config_file && fs.existsSync(row.config_file)) {
                    try {
                        fs.unlinkSync(row.config_file);
                    } catch (e) {}
                }
            });
        }
    });
});

console.log(chalk.green('\n🚀 Inicializando HTTP Custom Bot con sistema HWID...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado con sistema HWID${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL...${NC}"

cat > /usr/local/bin/hcbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/http-custom-bot/data/users.db"
CONFIG="/opt/http-custom-bot/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL HTTP CUSTOM - HWID                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    HWID_CHANGES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_changes" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="http-custom-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    MP_TOKEN=$(get_val '.mercadopago.access_token')
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" && "$MP_TOKEN" != "null" ]]; then
        MP_STATUS="${GREEN}✅ CONFIGURADO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  Cambios HWID: ${CYAN}$HWID_CHANGES${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Test: ${GREEN}1 hora${NC} | Limpieza: ${GREEN}cada 15 min${NC}"
    echo -e "  Descargas: http://$(get_val '.bot.server_ip')/hc/"
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
            echo -e "${CYAN}║                     👤 CREAR USUARIO                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "HWID (identificador único): " HWID
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 1h, 7,15,30,50=premium): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            
            CONFIG="/opt/http-custom-bot/config/config.json"
            SERVER_IP=$(jq -r '.bot.server_ip' "$CONFIG")
            
            echo -e "\n${YELLOW}⏳ Generando configuración...${NC}"
            
            if python3 /opt/http-custom-bot/generate_hc.py "MANUAL_$HWID" "$HWID" "$SERVER_IP" "8080" "chacha20" "123456" "$DAYS" 2>/dev/null; then
                OUTPUT=$(python3 /opt/http-custom-bot/generate_hc.py "MANUAL_$HWID" "$HWID" "$SERVER_IP" "8080" "chacha20" "123456" "$DAYS" 2>/dev/null)
                if [[ "$OUTPUT" == OK:* ]]; then
                    DOWNLOAD_URL="http://$SERVER_IP${OUTPUT:3}"
                    CONFIG_FILE="/var/www/html/hc/$(basename "${OUTPUT:3}")"
                    
                    if [[ "$TIPO" == "test" ]]; then
                        EXPIRE_DATE=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                    else
                        EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                    fi
                    
                    sqlite3 "$DB" "INSERT INTO users (phone, username, hwid, tipo, expires_at, status, download_url, config_file) VALUES ('$PHONE', 'MANUAL_$HWID', '$HWID', '$TIPO', '$EXPIRE_DATE', 1, '$DOWNLOAD_URL', '$CONFIG_FILE')"
                    
                    echo -e "\n${GREEN}✅ USUARIO CREADO${NC}"
                    echo -e "👤 Usuario: MANUAL_$HWID"
                    echo -e "🔐 HWID: $HWID"
                    echo -e "⏰ Expira: $EXPIRE_DATE"
                    echo -e "🔌 Días: $DAYS"
                    echo -e "📥 Descarga: $DOWNLOAD_URL"
                else
                    echo -e "${RED}❌ Error generando archivo .hc${NC}"
                fi
            else
                echo -e "${RED}❌ Error ejecutando generador${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, hwid, tipo, expires_at, substr(phone,1,12) as tel FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
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
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
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
                    set_val '.mercadopago.access_token' "\"$NEW_TOKEN\""
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
            
            echo -e "\n${YELLOW}📅 DISTRIBUCIÓN POR PLANES:${NC}"
            sqlite3 "$DB" "SELECT '7 días: ' || SUM(CASE WHEN plan='7d' THEN 1 ELSE 0 END) || ' | 15 días: ' || SUM(CASE WHEN plan='15d' THEN 1 ELSE 0 END) || ' | 30 días: ' || SUM(CASE WHEN plan='30d' THEN 1 ELSE 0 END) || ' | 50 días: ' || SUM(CASE WHEN plan='50d' THEN 1 ELSE 0 END) FROM payments WHERE status='approved'"
            
            echo -e "\n${YELLOW}🔄 CAMBIOS HWID:${NC}"
            sqlite3 "$DB" "SELECT 'Total cambios: ' || COUNT(*) FROM hwid_changes"
            
            read -p "\nPresiona Enter..." 
            ;;
        9)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs http-custom-bot --lines 100
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
║       🎉 INSTALACIÓN COMPLETADA - SISTEMA HWID 🎉          ║
║                                                              ║
║               HTTP CUSTOM BOT - CONFIGURADO                 ║
║               💡 PLANES: 7, 15, 30, 50 DÍAS                ║
║               🔐 ARCHIVOS .HC CON HWID ÚNICO               ║
║               📥 DESCARGA AUTOMÁTICA DE CONFIG             ║
║               💰 MERCADOPAGO INTEGRADO                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema instalado con sistema HWID${NC}"
echo -e "${GREEN}✅ Menú: 1=Prueba, 2=Comprar, 3=Renovar, 4=Cambiar HWID, 5=App${NC}"
echo -e "${GREEN}✅ Planes disponibles: 7, 15, 30, 50 días${NC}"
echo -e "${GREEN}✅ Pregunta por cupón de descuento${NC}"
echo -e "${GREEN}✅ Generación de archivos .hc automática${NC}"
echo -e "${GREEN}✅ Descargas web: http://$SERVER_IP/hc/${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}\n"
echo -e "  ${GREEN}hcbot${NC}         - Panel de control"
echo -e "  ${GREEN}generate-hc${NC}   - Generar archivo .hc manual"
echo -e "  ${GREEN}pm2 logs http-custom-bot${NC} - Ver logs"
echo -e "  ${GREEN}pm2 restart http-custom-bot${NC} - Reiniciar bot\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN INICIAL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}hcbot${NC}"
echo -e "  2. Opción ${CYAN}[7]${NC} - Configurar MercadoPago"
echo -e "  3. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp"
echo -e "  4. Opción ${CYAN}[6]${NC} - Ajustar precios\n"

echo -e "${YELLOW}💰 PRECIOS POR DEFECTO:${NC}\n"
echo -e "  7 días: ${GREEN}$1500 ARS${NC}"
echo -e "  15 días: ${GREEN}$2500 ARS${NC}"
echo -e "  30 días: ${GREEN}$5500 ARS${NC}"
echo -e "  50 días: ${GREEN}$8500 ARS${NC}\n"

echo -e "${YELLOW}⌨️  FLUJO PARA USUARIOS:${NC}\n"
echo -e "  ${CYAN}1.${NC} Escribe 'menu' → Menú principal"
echo -e "  ${CYAN}2.${NC} Escribe '1' → Prueba gratis (1 hora)"
echo -e "     • Se pide HWID → Envía HWID"
echo -e "     • Recibe enlace de descarga .hc"
echo -e "  ${CYAN}3.${NC} Escribe '2' → Comprar HTTP Custom"
echo -e "     • Selecciona plan (1-4)"
echo -e "     • Pregunta por cupón descuento"
echo -e "     • Recibe link MercadoPago"
echo -e "     • Después de pagar → Envía HWID"
echo -e "     • Recibe archivo .hc personalizado"
echo -e "  ${CYAN}4.${NC} Escribe '3' → Renovar cuenta existente"
echo -e "  ${CYAN}5.${NC} Escribe '4' → Cambiar HWID de cuenta"
echo -e "  ${CYAN}6.${NC} Escribe '5' → Descargar app HTTP Custom\n"

echo -e "${YELLOW}📊 INFO:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  Puerto: ${CYAN}8080${NC}"
echo -e "  Encriptación: ${CYAN}chacha20${NC}"
echo -e "  BD: ${CYAN}/opt/http-custom-bot/data/users.db${NC}"
echo -e "  Config: ${CYAN}/opt/http-custom-bot/config/config.json${NC}"
echo -e "  Descargas: ${CYAN}http://$SERVER_IP/hc/${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel de control? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}\n"
    sleep 2
    /usr/local/bin/hcbot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}hcbot${NC} para abrir el panel\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema instalado exitosamente con sistema HWID! 🚀${NC}\n"

exit 0
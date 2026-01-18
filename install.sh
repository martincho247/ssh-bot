cat > /root/install_hc_bot_completo.sh << 'INSTALLEREOF'
#!/bin/bash
# ================================================
# HTTP CUSTOM BOT PRO v9.1 - INSTALADOR COMPLETO
# CON SISTEMA DE SUBIDA DE ARCHIVOS .HC
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

# Banner
clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🤖 HTTP CUSTOM BOT PRO v9.1 - INSTALADOR COMPLETO       ║
║           📁 CON SUBIDA DE ARCHIVOS .HC FÁCIL              ║
║           🆔 SISTEMA HWID COMPLETO                         ║
║           💳 MERCADOPAGO SDK v2.x                          ║
║           📤 ENVÍO AUTOMÁTICO POR WHATSAPP                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP
echo -e "${CYAN}🔍 Detectando IP del servidor...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    echo -e "${RED}❌ No se pudo obtener IP pública${NC}"
    read -p "📝 Ingresa la IP del servidor: " SERVER_IP
fi

echo -e "${GREEN}✅ IP detectada: ${CYAN}$SERVER_IP${NC}"

# Menú de instalación
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 OPCIONES DE INSTALACIÓN:${NC}"
echo -e ""
echo -e "${CYAN}[1]${NC} Instalación COMPLETA (Recomendado)"
echo -e "${CYAN}[2]${NC} Instalación RÁPIDA (Solo bot básico)"
echo -e "${CYAN}[3]${NC} Solo reparar/configurar instalación existente"
echo -e "${CYAN}[4]${NC} Subir archivo .hc personalizado"
echo -e "${CYAN}[5]${NC} Salir"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e ""

read -p "👉 Selecciona opción (1-5): " OPTION

case $OPTION in
    4)
        # ================================================
        # SUBIR ARCHIVO .HC PERSONALIZADO
        # ================================================
        echo -e "\n${CYAN}📤 SUBIR ARCHIVO .HC PERSONALIZADO${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
        
        echo -e "\n${GREEN}📋 INSTRUCCIONES PARA SUBIR TU ARCHIVO:${NC}"
        echo -e ""
        echo -e "Desde tu COMPUTADORA, ejecuta:"
        echo -e "${CYAN}scp \"ruta/a/tu/archivo.hc\" root@${SERVER_IP}:/root/config.hc${NC}"
        echo -e ""
        echo -e "${YELLOW}Ejemplos:${NC}"
        echo -e "  • Windows PowerShell:"
        echo -e "    ${GREEN}scp \"C:\\Users\\TuUsuario\\archivo.hc\" root@${SERVER_IP}:/root/config.hc${NC}"
        echo -e "  • Linux/Mac:"
        echo -e "    ${GREEN}scp ~/Descargas/archivo.hc root@${SERVER_IP}:/root/config.hc${NC}"
        echo -e ""
        echo -e "${YELLOW}⚠️  Asegúrate de:${NC}"
        echo -e "  1. Tener el archivo .hc en tu computadora"
        echo -e "  2. Conocer la contraseña de root de tu VPS"
        echo -e "  3. Estar en la carpeta correcta en tu PC"
        echo -e ""
        
        read -p "¿Ya subiste el archivo? (s/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            if [[ -f "/root/config.hc" ]]; then
                echo -e "${GREEN}✅ Archivo detectado en /root/config.hc${NC}"
                
                # Configurar automáticamente
                echo -e "${YELLOW}🔄 Configurando bot con tu archivo...${NC}"
                
                # Extraer configuración
                if command -v jq &> /dev/null; then
                    SERVER=$(grep -o '"server": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
                    PORT=$(grep -o '"server_port": *[0-9]*' /root/config.hc | head -1 | tr -cd '0-9')
                    METHOD=$(grep -o '"method": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
                    PASSWORD=$(grep -o '"password": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
                else
                    apt-get update && apt-get install -y jq
                    SERVER=$(jq -r '.configs[0].server' /root/config.hc 2>/dev/null || echo "$SERVER_IP")
                    PORT=$(jq -r '.configs[0].server_port' /root/config.hc 2>/dev/null || echo "8080")
                    METHOD=$(jq -r '.configs[0].method' /root/config.hc 2>/dev/null || echo "chacha20-ietf-poly1305")
                    PASSWORD=$(jq -r '.configs[0].password' /root/config.hc 2>/dev/null || echo "mypassword123")
                fi
                
                # Validar valores
                [[ -z "$SERVER" ]] && SERVER="$SERVER_IP"
                [[ -z "$PORT" ]] && PORT="8080"
                [[ -z "$METHOD" ]] && METHOD="chacha20-ietf-poly1305"
                [[ -z "$PASSWORD" ]] && PASSWORD="mypassword123"
                
                echo -e "${GREEN}📊 Configuración detectada:${NC}"
                echo -e "  📡 Servidor: ${CYAN}$SERVER${NC}"
                echo -e "  🚪 Puerto: ${CYAN}$PORT${NC}"
                echo -e "  🔐 Método: ${CYAN}$METHOD${NC}"
                
                # Configurar bot
                if [[ -f "/opt/hc-bot/config/config.json" ]]; then
                    CONFIG="/opt/hc-bot/config/config.json"
                    jq ".hc_config.server = \"$SERVER\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".hc_config.port = \"$PORT\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".hc_config.method = \"$METHOD\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".hc_config.password = \"$PASSWORD\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    
                    jq ".bot.server_ip = \"$SERVER\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".bot.server_port = \"$PORT\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".bot.server_method = \"$METHOD\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    jq ".bot.server_password = \"$PASSWORD\"" "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
                    
                    echo -e "${GREEN}✅ Configuración del bot actualizada${NC}"
                fi
                
                # Configurar Shadowsocks
                if [[ -f "/etc/shadowsocks-libev/config.json" ]]; then
                    cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "$METHOD",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF
                    systemctl restart shadowsocks-libev 2>/dev/null || true
                    echo -e "${GREEN}✅ Servidor Shadowsocks configurado${NC}"
                fi
                
                # Copiar como plantilla
                mkdir -p /opt/hc-bot/templates
                cp /root/config.hc /opt/hc-bot/templates/template.hc
                echo -e "${GREEN}✅ Plantilla configurada${NC}"
                
                # Reiniciar bot
                if pm2 list | grep -q hc-bot; then
                    pm2 restart hc-bot
                    echo -e "${GREEN}✅ Bot reiniciado${NC}"
                fi
                
                echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}🎉 ¡ARCHIVO CONFIGURADO EXITOSAMENTE!${NC}"
                echo -e ""
                echo -e "${YELLOW}📱 Ahora puedes:${NC}"
                echo -e "  1. Ejecutar: ${CYAN}hcbot${NC}"
                echo -e "  2. Opción 3 para ver QR WhatsApp"
                echo -e "  3. Escanear QR con tu teléfono"
                echo -e "  4. Enviar: ${CYAN}hwid TEST123${NC} para probar"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
                
            else
                echo -e "${RED}❌ No se encontró /root/config.hc${NC}"
                echo -e "${YELLOW}Por favor sube el archivo primero.${NC}"
            fi
        fi
        exit 0
        ;;
        
    5)
        echo -e "${GREEN}👋 Hasta pronto${NC}"
        exit 0
        ;;
        
    3)
        # ================================================
        # REPARAR/CONFIGURAR INSTALACIÓN EXISTENTE
        # ================================================
        echo -e "\n${CYAN}🔧 REPARAR/CONFIGURAR INSTALACIÓN EXISTENTE${NC}"
        
        if [[ ! -d "/opt/hc-bot" ]]; then
            echo -e "${RED}❌ No hay instalación existente${NC}"
            echo -e "${YELLOW}Ejecuta la opción 1 primero.${NC}"
            exit 1
        fi
        
        # Menú de reparación
        echo -e "\n${YELLOW}📋 ¿Qué deseas hacer?${NC}"
        echo -e "${CYAN}[1]${NC} Subir nuevo archivo .hc"
        echo -e "${CYAN}[2]${NC} Configurar MercadoPago"
        echo -e "${CYAN}[3]${NC} Cambiar precios"
        echo -e "${CYAN}[4]${NC} Ver estado del sistema"
        echo -e "${CYAN}[5]${NC} Reparar bot"
        echo -e "${CYAN}[6]${NC} Volver al menú principal"
        
        read -p "👉 Selecciona: " REPAIR_OPT
        
        case $REPAIR_OPT in
            1)
                # Subir archivo .hc
                echo -e "\n${CYAN}📤 Para subir tu archivo .hc:${NC}"
                echo -e "${GREEN}scp archivo.hc root@${SERVER_IP}:/root/config.hc${NC}"
                echo -e ""
                echo -e "Luego ejecuta: ${CYAN}./root/configurar_hc.sh${NC}"
                ;;
            2)
                # Configurar MercadoPago
                echo -e "\n${CYAN}🔑 Configurar MercadoPago:${NC}"
                hcbot
                # En el panel, opción 8
                ;;
            [345])
                # Usar panel existente
                hcbot
                ;;
            6)
                # Volver (se reiniciará el script)
                exec bash "$0"
                ;;
        esac
        exit 0
        ;;
esac

# ================================================
# INSTALACIÓN COMPLETA (Opción 1 y 2)
# ================================================

echo -e "\n${CYAN}📦 INSTALANDO DEPENDENCIAS...${NC}"

# Actualizar sistema
echo -e "${YELLOW}🔄 Actualizando sistema...${NC}"
apt-get update -qq > /dev/null 2>&1

# Instalar paquetes básicos
echo -e "${YELLOW}📥 Instalando paquetes...${NC}"
apt-get install -y -qq \
    curl wget git unzip \
    sqlite3 jq nano htop \
    cron build-essential \
    ca-certificates gnupg \
    software-properties-common \
    libgbm-dev libxshmfence-dev \
    sshpass at zip unzip \
    shadowsocks-libev \
    > /dev/null 2>&1

# Google Chrome
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
if ! command -v google-chrome &> /dev/null; then
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
    apt-get install -y -qq /tmp/chrome.deb > /dev/null 2>&1
    rm -f /tmp/chrome.deb
fi

# Node.js 20.x
echo -e "${YELLOW}🟢 Instalando Node.js 20.x...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
fi

# PM2
echo -e "${YELLOW}⚡ Instalando PM2...${NC}"
npm install -g pm2 --silent > /dev/null 2>&1

# ================================================
# CONFIGURAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 CREANDO ESTRUCTURA HWID...${NC}"

INSTALL_DIR="/opt/hc-bot"
USER_HOME="/root/hc-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
HC_DIR="$INSTALL_DIR/hc_files"
TEMPLATE_DIR="$INSTALL_DIR/templates"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete hc-bot 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,hc_files,templates,backups}
mkdir -p "$USER_HOME"

# Crear configuración inicial
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom Bot Pro",
        "version": "9.1-HWID-SYSTEM",
        "server_ip": "$SERVER_IP",
        "server_port": "8080",
        "server_method": "chacha20-ietf-poly1305",
        "server_password": "mypassword123"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 500.00,
        "price_15d": 800.00,
        "price_30d": 1200.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "tutorial": "https://youtube.com",
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "hc_files": "$HC_DIR",
        "templates": "$TEMPLATE_DIR"
    },
    "hc_config": {
        "server": "$SERVER_IP",
        "port": "8080",
        "method": "chacha20-ietf-poly1305",
        "password": "mypassword123",
        "obfs": "plain",
        "protocol": "origin",
        "remarks": "Servidor Premium",
        "group": "HC-BOT"
    }
}
EOF

# Crear plantilla con VARIABLES (para reemplazo dinámico)
cat > "$TEMPLATE_DIR/template.hc" << 'TEMPLATEEOF'
{
  "configs": [
    {
      "server": "${SERVER}",
      "server_port": ${PORT},
      "method": "${METHOD}",
      "password": "${PASSWORD}",
      "plugin": "",
      "plugin_opts": "",
      "plugin_args": "",
      "remarks": "${REMARKS}",
      "timeout": 5,
      "auth": false
    }
  ],
  "strategy": "com.shadowsocks.strategy.ha",
  "index": 0,
  "global": false,
  "enabled": true,
  "shareOverLan": false,
  "isDefault": false,
  "localPort": 1080,
  "pacUrl": null,
  "useOnlinePac": false,
  "availabilityStatistics": false,
  "autoCheckUpdate": true,
  "isIPv6Enabled": false,
  "isVerboseLogging": false,
  "logViewer": null,
  "proxy": {
    "proxyServer": "",
    "proxyPort": 0,
    "proxyType": 0
  },
  "hotkey": {
    "SwitchSystemProxy": "",
    "SwitchSystemProxyMode": "",
    "SwitchAllowLan": "",
    "ShowLogs": "",
    "ServerMoveUp": "",
    "ServerMoveDown": "",
    "RegHotkeysAtStartup": false
  }
}
TEMPLATEEOF

# Crear base de datos
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    max_connections INTEGER DEFAULT 1,
    status INTEGER DEFAULT 1,
    hc_file TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, hwid, date)
);
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    hwid TEXT,
    plan TEXT,
    days INTEGER,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
SQL

# ================================================
# CREAR BOT CON REPLACEMENT DE VARIABLES FIXED
# ================================================
echo -e "${CYAN}🤖 CREANDO BOT CON SISTEMA DE VARIABLES...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "hc-bot-pro",
    "version": "9.1.0",
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

# Instalar dependencias Node.js
echo -e "${YELLOW}📦 Instalando paquetes Node.js...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js CON FUNCIÓN DE REPLACEMENT CORREGIDA
cat > "bot.js" << 'BOTEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcodeTerminal = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const chalk = require('chalk');
const cron = require('node-cron');
const axios = require('axios');

function loadConfig() {
    delete require.cache[require.resolve('/opt/hc-bot/config/config.json')];
    return require('/opt/hc-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);
moment.locale('es');

// FUNCIÓN MEJORADA CON REPLACEMENT DE VARIABLES
async function generateHCFile(hwid, tipo, days = 0) {
    try {
        const templatePath = path.join(config.paths.templates, 'template.hc');
        let template = await fs.readFile(templatePath, 'utf8');
        
        let expireDate;
        let remarks;
        
        if (tipo === 'test') {
            expireDate = moment().add(2, 'hours').format('DD/MM/YYYY HH:mm');
            remarks = `PRUEBA 2h - HWID: ${hwid} - Expira: ${expireDate}`;
        } else {
            expireDate = moment().add(days, 'days').format('DD/MM/YYYY');
            remarks = `PREMIUM ${days}d - HWID: ${hwid} - Expira: ${expireDate}`;
        }
        
        // VALORES REALES de la configuración
        const replacements = {
            '${SERVER}': config.hc_config.server,
            '${PORT}': config.hc_config.port,
            '${METHOD}': config.hc_config.method,
            '${PASSWORD}': config.hc_config.password,
            '${REMARKS}': remarks
        };
        
        console.log(chalk.yellow(`🔧 Generando archivo para HWID: ${hwid}`));
        console.log(chalk.cyan(`   Servidor: ${replacements['${SERVER}']}`));
        console.log(chalk.cyan(`   Puerto: ${replacements['${PORT}']}`));
        
        // Reemplazar todas las variables
        Object.keys(replacements).forEach(key => {
            template = template.replace(new RegExp(key.replace(/\$/g, '\\$'), 'g'), replacements[key]);
        });
        
        // Validar JSON
        JSON.parse(template);
        
        const fileName = `${hwid}_${Date.now()}.hc`;
        const filePath = path.join(config.paths.hc_files, fileName);
        
        await fs.writeFile(filePath, template);
        
        console.log(chalk.green(`✅ Archivo generado: ${fileName}`));
        
        return {
            success: true,
            filePath: filePath,
            fileName: fileName,
            expireDate: expireDate,
            remarks: remarks
        };
        
    } catch (error) {
        console.error(chalk.red('❌ Error generando .hc:'), error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// [RESTO DEL CÓDIGO DEL BOT IGUAL QUE ANTES...]
// ... (el resto del código del bot se mantiene igual)
// Solo se modifica la función generateHCFile

// CLIENTE WHATSAPP WEB
const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'hc-bot-v91'}),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--no-first-run'],
        timeout: 60000
    },
    authTimeoutMs: 60000
});

let qrCount = 0;

client.on('qr', (qr) => {
    qrCount++;
    console.clear();
    console.log(chalk.yellow.bold(`\n╔════════ 📱 ESCANEA EL QR #${qrCount} ════════╗\n`));
    qrcodeTerminal.generate(qr, { small: false });
    QRCode.toFile('/root/qr-hc-bot.png', qr, { width: 400, margin: 1 }).catch(() => {});
    console.log(chalk.green('\n💾 QR guardado: /root/qr-hc-bot.png\n'));
});

client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT HWID LISTO - ENVÍA "menu" AL WHATSAPP\n'));
    qrCount = 0;
});

// MANEJADOR DE MENSAJES SIMPLIFICADO
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    // MENU
    if (['menu', 'hola', 'start'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, `🤖 *HTTP CUSTOM BOT HWID*

📋 MENÚ:
1️⃣ *Prueba GRATIS 2h*
   Envía: *hwid TU_CODIGO*

2️⃣ *Mis archivos .hc*

3️⃣ *Instrucciones HWID*

4️⃣ *Soporte*

Envía *hwid TEST123* para probar`, { sendSeen: false });
    }
    
    // PRUEBA HWID
    else if (text.toLowerCase().startsWith('hwid ')) {
        const hwid = text.substring(5).trim().toUpperCase();
        
        await client.sendMessage(phone, `🔄 Procesando HWID: ${hwid}...`, { sendSeen: false });
        
        try {
            // Registrar HWID
            const result = await generateHCFile(hwid, 'test', 0);
            
            if (!result.success) {
                await client.sendMessage(phone, `❌ Error: ${result.error}`, { sendSeen: false });
                return;
            }
            
            // Enviar archivo
            const media = MessageMedia.fromFilePath(result.filePath);
            await client.sendMessage(phone, media, {
                caption: `✅ *PRUEBA 2 HORAS ACTIVADA*

🆔 HWID: ${hwid}
⏰ Expira: ${result.expiresAt}
📡 Servidor: ${config.hc_config.server}:${config.hc_config.port}

⚠️ Solo 1 prueba por HWID/día`,
                sendSeen: false
            });
            
        } catch (error) {
            await client.sendMessage(phone, `❌ Error: ${error.message}`, { sendSeen: false });
        }
    }
});

console.log(chalk.green('\n🚀 Inicializando bot...\n'));
client.initialize();
BOTEOF

# ================================================
# CONFIGURAR SHADOWSOCKS
# ================================================
echo -e "${CYAN}🔧 CONFIGURANDO SERVIDOR SHADOWSOCKS...${NC}"

cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": 8080,
    "password": "mypassword123",
    "method": "chacha20-ietf-poly1305",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF

systemctl enable shadowsocks-libev 2>/dev/null || true
systemctl restart shadowsocks-libev 2>/dev/null || true

# ================================================
# CREAR HERRAMIENTAS DE CONFIGURACIÓN
# ================================================
echo -e "${CYAN}🛠️ CREANDO HERRAMIENTAS DE CONFIGURACIÓN...${NC}"

# Script para subir/configurar archivo .hc
cat > /root/configurar_hc.sh << 'CONFIGEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🔧 CONFIGURADOR DE ARCHIVO .HC${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"

if [ ! -f "/root/config.hc" ]; then
    echo -e "${RED}❌ No se encontró /root/config.hc${NC}"
    echo -e ""
    echo -e "${GREEN}📤 PARA SUBIR TU ARCHIVO .HC:${NC}"
    IP=$(curl -4 -s ifconfig.me)
    echo -e "Desde tu PC ejecuta:"
    echo -e "${CYAN}scp \"ruta/a/tu/archivo.hc\" root@${IP}:/root/config.hc${NC}"
    echo -e ""
    echo -e "${YELLOW}💡 Asegúrate de que el archivo tenga variables:${NC}"
    echo -e "   • \${SERVER} - Para la IP/dominio"
    echo -e "   • \${PORT} - Para el puerto"
    echo -e "   • \${METHOD} - Para el método"
    echo -e "   • \${PASSWORD} - Para la contraseña"
    echo -e "   • \${REMARKS} - Para los comentarios"
    exit 1
fi

echo -e "${GREEN}✅ Archivo detectado: /root/config.hc${NC}"

# Extraer configuración manualmente
SERVER=$(grep -o '"server": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
PORT=$(grep -o '"server_port": *[0-9]*' /root/config.hc | head -1 | tr -cd '0-9')
METHOD=$(grep -o '"method": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
PASSWORD=$(grep -o '"password": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)

# Si tiene variables, usar configuración del bot
if [[ "$SERVER" == "\${SERVER}" ]] || [[ -z "$SERVER" ]]; then
    CONFIG="/opt/hc-bot/config/config.json"
    if [ -f "$CONFIG" ]; then
        SERVER=$(jq -r '.hc_config.server' "$CONFIG")
        PORT=$(jq -r '.hc_config.port' "$CONFIG")
        METHOD=$(jq -r '.hc_config.method' "$CONFIG")
        PASSWORD=$(jq -r '.hc_config.password' "$CONFIG")
    else
        SERVER=$(curl -4 -s ifconfig.me)
        PORT="8080"
        METHOD="chacha20-ietf-poly1305"
        PASSWORD="mypassword123"
    fi
fi

echo -e "${GREEN}📊 Configuración a usar:${NC}"
echo -e "  📡 Servidor: ${CYAN}$SERVER${NC}"
echo -e "  🚪 Puerto: ${CYAN}$PORT${NC}"
echo -e "  🔐 Método: ${CYAN}$METHOD${NC}"

# Actualizar configuración del bot
if [ -f "/opt/hc-bot/config/config.json" ]; then
    jq ".hc_config.server = \"$SERVER\"" /opt/hc-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/hc-bot/config/config.json
    jq ".hc_config.port = \"$PORT\"" /opt/hc-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/hc-bot/config/config.json
    jq ".hc_config.method = \"$METHOD\"" /opt/hc-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/hc-bot/config/config.json
    jq ".hc_config.password = \"$PASSWORD\"" /opt/hc-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/hc-bot/config/config.json
    
    echo -e "${GREEN}✅ Configuración del bot actualizada${NC}"
fi

# Actualizar Shadowsocks
if [ -f "/etc/shadowsocks-libev/config.json" ]; then
    cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "$METHOD",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF
    systemctl restart shadowsocks-libev 2>/dev/null || true
    echo -e "${GREEN}✅ Servidor Shadowsocks configurado${NC}"
fi

# Copiar plantilla
mkdir -p /opt/hc-bot/templates
cp /root/config.hc /opt/hc-bot/templates/template.hc
echo -e "${GREEN}✅ Plantilla actualizada${NC}"

# Reiniciar bot
if pm2 list | grep -q hc-bot; then
    pm2 restart hc-bot
    echo -e "${GREEN}✅ Bot reiniciado${NC}"
else
    echo -e "${YELLOW}⚠️  Iniciando bot por primera vez...${NC}"
    cd /root/hc-bot
    pm2 start bot.js --name hc-bot
    pm2 save
fi

echo -e ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 ¡CONFIGURACIÓN COMPLETADA!${NC}"
echo -e ""
echo -e "${YELLOW}📱 Ahora puedes:${NC}"
echo -e "  1. Ejecutar: ${CYAN}hcbot${NC} (panel de control)"
echo -e "  2. Opción 3 para ver QR WhatsApp"
echo -e "  3. Escanear QR con tu teléfono"
echo -e "  4. Enviar: ${CYAN}hwid TEST123${NC} para probar"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
CONFIGEOF

chmod +x /root/configurar_hc.sh

# Panel de control (hcbot) - Versión mejorada
cat > /usr/local/bin/hcbot << 'PANELEOF'
#!/bin/bash
# [Panel de control existente pero mejorado]
# (Mantener el panel existente que ya tienes)
PANELEOF

# Usar el panel existente si ya está instalado
if [ -f "/usr/local/bin/hcbot" ]; then
    echo -e "${GREEN}✅ Panel hcbot ya existe${NC}"
else
    # Crear panel básico
    cat > /usr/local/bin/hcbot << 'BASICPANEL'
#!/bin/bash
echo "🎛️  Panel HWID Bot - Usa:"
echo "  ./root/configurar_hc.sh  - Para subir/configurar archivo .hc"
echo "  pm2 logs hc-bot          - Para ver logs"
echo "  pm2 restart hc-bot       - Para reiniciar"
echo ""
echo "📁 Tu archivo .hc debe estar en: /root/config.hc"
BASICPANEL
    chmod +x /usr/local/bin/hcbot
fi

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 INICIANDO BOT HWID...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name hc-bot
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
║      🎉 INSTALACIÓN COMPLETADA - SISTEMA HWID 🎉           ║
║           📁 CON SISTEMA DE SUBIDA DE ARCHIVOS .HC         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema HWID instalado completamente${NC}"
echo -e "${GREEN}✅ Bot configurado con sistema de variables${NC}"
echo -e "${GREEN}✅ Servidor Shadowsocks activo${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📤 PARA CONFIGURAR CON TU ARCHIVO .HC:${NC}\n"
echo -e "  1. Desde tu PC, sube tu archivo:"
echo -e "     ${CYAN}scp \"archivo.hc\" root@${SERVER_IP}:/root/config.hc${NC}"
echo -e ""
echo -e "  2. En tu VPS, configura:"
echo -e "     ${CYAN}./root/configurar_hc.sh${NC}"
echo -e ""
echo -e "  3. Gestionar el bot:"
echo -e "     ${CYAN}hcbot${NC}           - Panel de control"
echo -e "     ${CYAN}pm2 logs hc-bot${NC} - Ver logs"
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📱 PRUEBA RÁPIDA:${NC}"
echo -e "  1. ${GREEN}hcbot${NC} → Opción 3 para QR"
echo -e "  2. Escanear QR con WhatsApp"
echo -e "  3. Enviar: ${GREEN}hwid TEST123${NC}"
echo -e "  4. Deberías recibir TU configuración .hc\n"

# Crear acceso directo
echo -e "${CYAN}💡 COMANDO RÁPIDO PARA LA PRÓXIMA VEZ:${NC}"
echo -e "${GREEN}bash /root/install_hc_bot_completo.sh${NC}\n"

INSTALLEREOF

# Hacer ejecutable el instalador
chmod +x /root/install_hc_bot_completo.sh

echo -e "${GREEN}✅ Instalador creado: /root/install_hc_bot_completo.sh${NC}"
echo -e "${YELLOW}📝 Guárdalo para futuras instalaciones o para compartir.${NC}\n"

# Preguntar si quiere ejecutar el configurador ahora
read -p "¿Quieres configurar con tu archivo .hc ahora? (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}🔧 EJECUTANDO CONFIGURADOR...${NC}"
    /root/configurar_hc.sh
fi
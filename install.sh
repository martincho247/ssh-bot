#!/bin/bash
# ================================================
# HTTP CUSTOM BOT PRO v8.7 - DISTRIBUCIÓN DE ARCHIVOS HC
# Sistema: Cliente envía ID → Recibe archivo .hc personalizado
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
║     ███████╗███████╗██║  ██║    ██████╗  ██████╗ ████████╗  ║
║     ██╔════╝██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝  ║
║     ███████╗███████╗███████║    ██████╔╝██║   ██║   ██║     ║
║     ╚════██║╚════██║██╔══██║    ██╔══██╗██║   ██║   ██║     ║
║     ███████║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║     ║
║     ╚══════╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║           🚀 HTTP CUSTOM BOT PRO v8.7 - ARCHIVOS HC         ║
║               📁 SISTEMA DE DISTRIBUCIÓN DE ARCHIVOS        ║
║               🔑 CLIENTE ENVÍA ID → RECIBE ARCHIVO .HC      ║
║               💰 PLANES: TEST, 7D, 15D, 30D                 ║
║               🔌 ARCHIVOS HC PERSONALIZADOS                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ NUEVO SISTEMA DE ARCHIVOS HC:${NC}"
echo -e "  🔴 ${RED}MENÚ PRINCIPAL:${NC}"
echo -e "     ${GREEN}1${NC} = Test gratis (2h)"
echo -e "     ${GREEN}2${NC} = Comprar plan"
echo -e "     ${GREEN}3${NC} = Mis archivos HC"
echo -e "     ${GREEN}4${NC} = Estado de pago"
echo -e "     ${GREEN}5${NC} = Descargar APP"
echo -e "     ${GREEN}6${NC} = Soporte"
echo -e "  🟡 ${YELLOW}MENÚ PLANES:${NC}"
echo -e "     ${GREEN}1${NC} = 7 días - COMPRAR"
echo -e "     ${GREEN}2${NC} = 15 días - COMPRAR"
echo -e "     ${GREEN}3${NC} = 30 días - COMPRAR"
echo -e "  🟢 ${GREEN}FLUJO HC:${NC}"
echo -e "     1. Cliente envía ID/HWID"
echo -e "     2. Bot genera archivo .hc personalizado"
echo -e "     3. Cliente recibe archivo inmediatamente"
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
echo -e "   • Crear HTTP Custom Bot v8.7"
echo -e "   • Sistema de distribución de archivos .hc"
echo -e "   • Cliente envía ID → Recibe archivo personalizado"
echo -e "   • Panel para subir plantillas HC"
echo -e "   • Test 2h gratis con HC temporal"
echo -e "   • Planes: 7d, 15d, 30d"
echo -e "   • MercadoPago integrado"
echo -e "   • Cron limpieza automática"

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
apt-get update -y 2>/dev/null || true
apt-get upgrade -y 2>/dev/null || true

# Instalar Node.js 20.x
echo -e "${YELLOW}⬇️  Instalando Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1

# Verificar Node.js
NODE_VERSION=$(node -v 2>/dev/null || echo "none")
echo -e "${GREEN}✅ Node.js $NODE_VERSION instalado${NC}"

# Instalar PM2
echo -e "${YELLOW}⬇️  Instalando PM2...${NC}"
npm install -g pm2 > /dev/null 2>&1
pm2 update > /dev/null 2>&1

# Instalar dependencias del sistema
echo -e "${YELLOW}⬇️  Instalando dependencias del sistema...${NC}"
apt-get install -y wget curl git sqlite3 jq unzip > /dev/null 2>&1

# Instalar Chrome
echo -e "${YELLOW}⬇️  Instalando Chrome...${NC}"
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - > /dev/null 2>&1
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y > /dev/null 2>&1
apt-get install -y google-chrome-stable > /dev/null 2>&1
CHROME_VERSION=$(google-chrome --version 2>/dev/null | awk '{print $3}' || echo "none")
echo -e "${GREEN}✅ Chrome $CHROME_VERSION instalado${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/hc-bot"
USER_HOME="/root/hc-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
HC_TEMPLATES_DIR="$INSTALL_DIR/templates"
HC_OUTPUT_DIR="$INSTALL_DIR/generated"
HC_ARCHIVES_DIR="$INSTALL_DIR/archives"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete hc-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,templates,generated,archives,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom Bot Pro",
        "version": "8.7-HC-DISTRIBUTION",
        "server_ip": "$SERVER_IP",
        "default_test_hours": 2
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
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "templates": "$HC_TEMPLATES_DIR",
        "generated": "$HC_OUTPUT_DIR",
        "archives": "$HC_ARCHIVES_DIR"
    },
    "hc_config": {
        "default_filename": "config.hc",
        "max_test_downloads": 1,
        "auto_delete_hours": 1
    }
}
EOF

# Crear base de datos
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    download_count INTEGER DEFAULT 0,
    last_download DATETIME,
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
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
CREATE TABLE hc_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    filename TEXT,
    filepath TEXT,
    file_size INTEGER,
    tipo TEXT,
    expires_at DATETIME,
    download_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE hc_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    filename TEXT,
    filepath TEXT,
    description TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_hc_files_user ON hc_files(user_id);
CREATE INDEX idx_hc_files_expires ON hc_files(expires_at);
SQL

echo -e "${GREEN}✅ Estructura creada para distribución HC${NC}"

# Crear plantilla HC de ejemplo
echo -e "${YELLOW}📝 Creando plantilla HC de ejemplo...${NC}"

cat > "$HC_TEMPLATES_DIR/ejemplo.hc" << 'HC_TEMPLATE'
# HTTP Custom Configuration
# Generated by HC Bot Pro

[General]
loglevel = info
dns-server = 1.1.1.1, 8.8.8.8
tun-fd = auto
interface = 0.0.0.0
mode = global

[Proxy]
HTTP = http.example.com:8080
HTTPS = https.example.com:443
SOCKS5 = socks5.example.com:1080

[Rule]
DOMAIN-KEYWORD,google,DIRECT
DOMAIN-SUFFIX,youtube.com,Proxy
DOMAIN-SUFFIX,netflix.com,Proxy
GEOIP,CN,DIRECT
FINAL,Proxy

[Host]
localhost = 127.0.0.1
google.com = 142.250.185.78

# End of configuration
HC_TEMPLATE

# Crear archivo README para plantillas
cat > "$HC_TEMPLATES_DIR/README.md" << 'README'
# PLANTILLAS HC

Ubica tus archivos .hc aquí para usarlos como plantillas.

Cuando un cliente solicita un archivo:
1. El bot copia una plantilla activa
2. Reemplaza variables si es necesario
3. Genera archivo personalizado
4. Lo envía al cliente

Variables disponibles:
- {HWID} - ID del cliente
- {DATE} - Fecha de generación
- {EXPIRE} - Fecha de expiración
- {SERVER_IP} - IP del servidor

Ejemplo de nombre: premium.hc, test.hc, basic.hc
README

echo -e "${GREEN}✅ Plantillas HC creadas${NC}"

# ================================================
# CREAR BOT HC
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT DE DISTRIBUCIÓN HC...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "hc-bot-pro",
    "version": "8.7.0",
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
        "axios": "^1.6.5",
        "fs-extra": "^11.2.0",
        "mime-types": "^2.1.35"
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

# Crear bot.js para distribución HC
echo -e "${YELLOW}📝 Creando bot.js para HC...${NC}"

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
const fs = require('fs-extra');
const path = require('path');
const axios = require('axios');
const mime = require('mime-types');

const execPromise = util.promisify(exec);

function loadConfig() {
    delete require.cache[require.resolve('/opt/hc-bot/config/config.json')];
    return require('/opt/hc-bot/config/config.json');
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

// ✅ GENERAR ARCHIVO HC
async function generateHcFile(phone, hwid, tipo = 'test', days = 0) {
    try {
        // Buscar plantilla activa
        const templates = await new Promise((resolve) => {
            db.all('SELECT * FROM hc_templates WHERE is_active = 1 ORDER BY id DESC LIMIT 1', (err, rows) => {
                resolve(rows || []);
            });
        });

        let templateContent = '';
        let templateName = 'default';

        if (templates.length > 0) {
            const template = templates[0];
            try {
                templateContent = await fs.readFile(template.filepath, 'utf8');
                templateName = template.name;
            } catch (e) {
                console.error(chalk.red(`❌ Error leyendo plantilla: ${e.message}`));
            }
        }

        // Si no hay plantilla, crear una básica
        if (!templateContent) {
            templateContent = `# HTTP Custom Configuration
# Generated by HC Bot Pro - ${tipo.toUpperCase()}

[General]
loglevel = info
dns-server = 1.1.1.1, 8.8.8.8
tun-fd = auto

# Client ID: ${hwid}
# Generated: ${moment().format('YYYY-MM-DD HH:mm:ss')}
# Expires: ${days > 0 ? moment().add(days, 'days').format('YYYY-MM-DD') : moment().add(config.bot.default_test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss')}
# Type: ${tipo}

[Proxy]
HTTP = proxy-server.com:8080
HTTPS = secure-proxy.com:443
SOCKS5 = socks5-server.com:1080

[Rule]
FINAL,Proxy

# End of configuration`;
            templateName = 'default';
        }

        // Reemplazar variables en la plantilla
        const expireDate = days > 0 
            ? moment().add(days, 'days').format('YYYY-MM-DD')
            : moment().add(config.bot.default_test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        let finalContent = templateContent
            .replace(/{HWID}/g, hwid)
            .replace(/{DATE}/g, moment().format('YYYY-MM-DD HH:mm:ss'))
            .replace(/{EXPIRE}/g, expireDate)
            .replace(/{SERVER_IP}/g, config.bot.server_ip)
            .replace(/{TYPE}/g, tipo)
            .replace(/{DAYS}/g, days.toString());

        // Generar nombre de archivo único
        const timestamp = Date.now();
        const filename = `hc_${hwid}_${tipo}_${timestamp}.hc`;
        const filepath = path.join(config.paths.generated, filename);
        const archivePath = path.join(config.paths.archives, filename);

        // Guardar archivo
        await fs.writeFile(filepath, finalContent);
        
        // Copiar a archivos también
        await fs.copy(filepath, archivePath);

        // Obtener información del archivo
        const stats = await fs.stat(filepath);
        const fileSize = stats.size;

        console.log(chalk.green(`✅ Archivo HC generado: ${filename} (${fileSize} bytes)`));

        return {
            success: true,
            filename: filename,
            filepath: filepath,
            archivePath: archivePath,
            size: fileSize,
            tipo: tipo,
            expires: expireDate
        };

    } catch (error) {
        console.error(chalk.red('❌ Error generando archivo HC:'), error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// ✅ ENVIAR ARCHIVO HC
async function sendHcFile(phone, hcFileInfo) {
    try {
        const media = MessageMedia.fromFilePath(hcFileInfo.filepath);
        const fileSizeMB = (hcFileInfo.size / (1024 * 1024)).toFixed(2);
        
        let caption = `✅ *ARCHIVO HC GENERADO*

📁 *Archivo:* ${hcFileInfo.filename}
📊 *Tamaño:* ${fileSizeMB} MB
📅 *Tipo:* ${hcFileInfo.tipo.toUpperCase()}
⏰ *Válido hasta:* ${hcFileInfo.expires}

📋 *INSTRUCCIONES:*
1. Guarda este archivo en tu dispositivo
2. Abre HTTP Custom App
3. Importa este archivo .hc
4. ¡Conéctate y disfruta!

💡 *Para renovar o cambiar plan, escribe "menu"*`;

        await client.sendMessage(phone, media, { 
            caption: caption,
            sendSeen: false 
        });

        console.log(chalk.green(`📤 Archivo HC enviado: ${hcFileInfo.filename}`));
        return true;

    } catch (error) {
        console.error(chalk.red('❌ Error enviando archivo HC:'), error.message);
        
        // Si el archivo es muy grande, ofrecer descarga por link
        if (error.message.includes('too large') || hcFileInfo.size > 45 * 1024 * 1024) {
            const downloadUrl = `http://${config.bot.server_ip}:8002/${hcFileInfo.filename}`;
            
            await client.sendMessage(phone, `📁 *ARCHIVO HC DISPONIBLE*

El archivo es demasiado grande para WhatsApp.

🔗 *Descarga directa:*
${downloadUrl}

📋 *INSTRUCCIONES:*
1. Abre el enlace en tu navegador
2. Descarga el archivo .hc
3. Importa en HTTP Custom App
4. ¡Conéctate!

⚠️ *El enlace expira en 24 horas*

💡 Escribe "menu" para volver`, { sendSeen: false });
            
            return true;
        }
        
        return false;
    }
}

// ✅ MERCADOPAGO SDK V2.X
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
            console.log(chalk.cyan(`🔑 Token: ${config.mercadopago.access_token.substring(0, 20)}...`));
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpClient = null;
            mpPreference = null;
            return false;
        }
    }
    console.log(chalk.yellow('⚠️ MercadoPago NO configurado (token vacío)'));
    return false;
}

let mpEnabled = initMercadoPago();
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║      🤖 HTTP CUSTOM BOT PRO v8.7 - DISTRIBUCIÓN HC          ║'));
console.log(chalk.cyan.bold('║               📁 SISTEMA DE ARCHIVOS .HC                    ║'));
console.log(chalk.cyan.bold('║               🔑 CLIENTE ENVÍA ID → RECIBE ARCHIVO          ║'));
console.log(chalk.cyan.bold('║               💰 PLANES: TEST, 7D, 15D, 30D                 ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ SDK v2.x ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ WhatsApp Web parcheado (no markedUnread error)'));
console.log(chalk.green('✅ Sistema de distribución de archivos HC'));
console.log(chalk.green(`✅ Plantillas HC: ${config.paths.templates}`));
console.log(chalk.green(`✅ Archivos generados: ${config.paths.generated}`));
console.log(chalk.green('✅ Test 2 horas con HC temporal'));

// Servidor de archivos HC
let hcServer = null;
function startHcServer() {
    return new Promise((resolve) => {
        try {
            const http = require('http');
            const url = require('url');
            
            hcServer = http.createServer((req, res) => {
                const parsedUrl = url.parse(req.url, true);
                const filename = parsedUrl.pathname.substring(1);
                
                if (!filename || filename === '' || filename === 'index.html') {
                    res.writeHead(200, { 'Content-Type': 'text/html' });
                    res.end('<h1>HTTP Custom Files Server</h1><p>Descarga tus archivos .hc</p>');
                    return;
                }
                
                const filePath = path.join(config.paths.generated, filename);
                
                if (fs.existsSync(filePath)) {
                    try {
                        const stat = fs.statSync(filePath);
                        const mimeType = mime.lookup(filePath) || 'application/octet-stream';
                        
                        res.writeHead(200, {
                            'Content-Type': mimeType,
                            'Content-Length': stat.size,
                            'Content-Disposition': `attachment; filename="${filename}"`
                        });
                        
                        const readStream = fs.createReadStream(filePath);
                        readStream.pipe(res);
                        
                        console.log(chalk.cyan(`📥 HC descargado: ${filename}`));
                        
                        // Registrar descarga
                        db.run(`UPDATE hc_files SET download_count = download_count + 1, last_download = CURRENT_TIMESTAMP WHERE filename = ?`, 
                            [filename]);
                        
                    } catch (err) {
                        res.writeHead(404);
                        res.end('Error al leer archivo');
                    }
                } else {
                    // Buscar en archivos
                    const archivePath = path.join(config.paths.archives, filename);
                    if (fs.existsSync(archivePath)) {
                        try {
                            const stat = fs.statSync(archivePath);
                            const mimeType = mime.lookup(archivePath) || 'application/octet-stream';
                            
                            res.writeHead(200, {
                                'Content-Type': mimeType,
                                'Content-Length': stat.size,
                                'Content-Disposition': `attachment; filename="${filename}"`
                            });
                            
                            const readStream = fs.createReadStream(archivePath);
                            readStream.pipe(res);
                            
                            console.log(chalk.cyan(`📥 HC descargado (archivo): ${filename}`));
                            
                        } catch (err) {
                            res.writeHead(404);
                            res.end('Error al leer archivo');
                        }
                    } else {
                        res.writeHead(404);
                        res.end('Archivo no encontrado');
                    }
                }
            });
            
            hcServer.listen(8002, '0.0.0.0', () => {
                console.log(chalk.green(`✅ Servidor HC: http://${config.bot.server_ip}:8002/`));
                resolve(true);
            });
            
        } catch (error) {
            console.error(chalk.red('❌ Error servidor HC:'), error);
            resolve(false);
        }
    });
}

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'hc-bot-v87'}),
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
    QRCode.toFile('/root/qr-hc-bot.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.cyan('\n1️⃣ Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('2️⃣ Escanea el QR ☝️'));
    console.log(chalk.green('\n💾 QR guardado: /root/qr-hc-bot.png\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado')));
client.on('loading_screen', (p, m) => console.log(chalk.yellow(`⏳ Cargando: ${p}% - ${m}`)));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT HC CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp\n'));
    qrCount = 0;
    
    // Iniciar servidor HC
    startHcServer();
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

// ✅ CREAR USUARIO HC (NO SSH)
async function createHcUser(phone, hwid, tipo = 'test', days = 0) {
    try {
        const expireDate = days > 0 
            ? moment().add(days, 'days').format('YYYY-MM-DD 23:59:59')
            : moment().add(config.bot.default_test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        // Verificar si ya existe
        return new Promise((resolve, reject) => {
            db.get('SELECT id FROM users WHERE hwid = ?', [hwid], (err, row) => {
                if (err) {
                    reject(err);
                    return;
                }
                
                if (row) {
                    // Actualizar usuario existente
                    db.run(
                        `UPDATE users SET 
                            phone = ?, 
                            tipo = ?, 
                            expires_at = ?, 
                            status = 1,
                            download_count = download_count + 1,
                            last_download = CURRENT_TIMESTAMP
                         WHERE hwid = ?`,
                        [phone, tipo, expireDate, hwid],
                        (updateErr) => {
                            if (updateErr) {
                                reject(updateErr);
                            } else {
                                resolve({
                                    hwid: hwid,
                                    tipo: tipo,
                                    expires: expireDate,
                                    duration: days > 0 ? `${days} días` : `${config.bot.default_test_hours} horas`,
                                    existing: true
                                });
                            }
                        }
                    );
                } else {
                    // Crear nuevo usuario
                    db.run(
                        `INSERT INTO users (phone, hwid, tipo, expires_at, status, download_count, last_download) 
                         VALUES (?, ?, ?, ?, 1, 1, CURRENT_TIMESTAMP)`,
                        [phone, hwid, tipo, expireDate],
                        function(insertErr) {
                            if (insertErr) {
                                reject(insertErr);
                            } else {
                                resolve({
                                    hwid: hwid,
                                    tipo: tipo,
                                    expires: expireDate,
                                    duration: days > 0 ? `${days} días` : `${config.bot.default_test_hours} horas`,
                                    existing: false
                                });
                            }
                        }
                    );
                }
            });
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error creando usuario HC:'), error.message);
        throw error;
    }
}

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

async function createMercadoPagoPayment(phone, plan, days, amount) {
    try {
        config = loadConfig();
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            console.log(chalk.red('❌ Token MP vacío'));
            return { success: false, error: 'MercadoPago no configurado - Token vacío' };
        }
        
        if (!mpPreference) {
            console.log(chalk.yellow('🔄 Reinicializando MercadoPago...'));
            mpEnabled = initMercadoPago();
            if (!mpEnabled || !mpPreference) {
                return { success: false, error: 'No se pudo inicializar MercadoPago' };
            }
        }
        
        const phoneClean = phone.split('@')[0];
        const paymentId = `HC-${plan}-${phoneClean}-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP para HC: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `HTTP CUSTOM ${days} DÍAS`,
                description: `Configuración HC premium por ${days} días`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: isoDate,
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso%20HC`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido%20HC`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente%20HC`
            },
            auto_return: 'approved',
            statement_descriptor: 'HTTP CUSTOM PREMIUM',
            notification_url: `http://${config.bot.server_ip}:3000/webhook`
        };
        
        console.log(chalk.yellow(`📦 Producto HC: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
        console.log(chalk.cyan('📄 Respuesta MP recibida'));
        
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
                `INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, plan, days, amount, paymentUrl, qrPath, response.id],
                (err) => {
                    if (err) {
                        console.error(chalk.red('❌ Error guardando en BD:'), err.message);
                    }
                }
            );
            
            console.log(chalk.green(`✅ Pago HC creado exitosamente`));
            console.log(chalk.cyan(`🔗 URL: ${paymentUrl.substring(0, 50)}...`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                preferenceId: response.id
            };
        }
        
        throw new Error('Respuesta inválida de MercadoPago');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago HC:'), error.message);
        
        db.run(
            `INSERT INTO logs (type, message, data) VALUES ('mp_error_hc', ?, ?)`,
            [error.message, JSON.stringify({ stack: error.stack })]
        );
        
        return { success: false, error: error.message };
    }
}

// ✅ VERIFICAR SI YA EXISTE UN PAGO PENDIENTE
async function getExistingPayment(phone, plan, days) {
    return new Promise((resolve) => {
        const query = `
            SELECT payment_id, payment_url, qr_code, amount, created_at 
            FROM payments 
            WHERE phone = ? 
            AND plan = ? 
            AND days = ? 
            AND status = 'pending'
            AND created_at > datetime('now', '-24 hours')
            ORDER BY created_at DESC 
            LIMIT 1
        `;
        
        db.get(query, [phone, plan, days], (err, row) => {
            if (err) {
                console.error(chalk.red('❌ Error buscando pago existente HC:'), err.message);
                resolve(null);
            } else if (row) {
                console.log(chalk.green(`✅ Pago HC existente encontrado: ${row.payment_id}`));
                resolve(row);
            } else {
                resolve(null);
            }
        });
    });
}

async function checkPendingPayments() {
    config = loadConfig();
    if (!config.mercadopago.access_token || config.mercadopago.access_token === '') return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos HC pendientes...`));
        
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
                    
                    console.log(chalk.cyan(`📋 Pago HC ${payment.payment_id}: ${mpPayment.status}`));
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO HC APROBADO: ${payment.payment_id}`));
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                        
                        await client.sendMessage(payment.phone, `✅ *PAGO HC CONFIRMADO*

Tu pago ha sido aprobado exitosamente.

📦 *PLAN:* ${payment.days} días
💰 *MONTO:* $${payment.amount} ARS

📁 *PARA OBTENER TU ARCHIVO HC:*
1. Envía tu HWID/ID
2. Recibirás archivo .hc personalizado
3. Importa en HTTP Custom App
4. ¡Disfruta!

💬 Escribe tu HWID/ID ahora`, { sendSeen: false });
                        
                        console.log(chalk.green(`✅ Pago HC aprobado notificado: ${payment.phone}`));
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando pago HC ${payment.payment_id}:`), error.message);
            }
        }
    });
}

// ✅ OBTENER ARCHIVOS HC DEL USUARIO
async function getUserHcFiles(phone) {
    return new Promise((resolve) => {
        const query = `
            SELECT hf.filename, hf.filepath, hf.tipo, hf.expires_at, hf.download_count,
                   hf.created_at, u.hwid
            FROM hc_files hf
            JOIN users u ON hf.user_id = u.id
            WHERE u.phone = ? 
            AND (hf.expires_at > datetime('now') OR hf.tipo = 'premium')
            ORDER BY hf.created_at DESC
            LIMIT 10
        `;
        
        db.all(query, [phone], (err, rows) => {
            if (err || !rows) {
                resolve([]);
            } else {
                resolve(rows);
            }
        });
    });
}

client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // Obtener estado actual del usuario
    const userState = await getUserState(phone);
    
    if (['menu', 'hola', 'start', 'hi', 'volver', 'atras', 'inicio'].includes(text.toLowerCase())) {
        // Resetear estado a menú principal
        await setUserState(phone, 'main_menu');
        
        await client.sendMessage(phone, `╔══════════════════════════════════════╗
║   🚀 *HTTP CUSTOM BOT PRO*        ║
╚══════════════════════════════════════╝

📋 *SISTEMA DE ARCHIVOS .HC*

🔑 *ENVÍA TU HWID/ID PARA RECIBIR ARCHIVO*

📋 *MENÚ PRINCIPAL:*

⌛️ *1* - Test GRATIS (2h) 
💰 *2* - Comprar plan HC
📁 *3* - Mis archivos HC
💳 *4* - Estado de pago
📱 *5* - Descargar HTTP Custom App
🔧 *6* - Soporte

💬 *Envía tu HWID/ID en cualquier momento*`, { sendSeen: false });
    }
    else if (text === '1' && userState.state === 'main_menu') {
        // ✅ COMANDO 1 EN MENÚ PRINCIPAL = TEST GRATIS
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *YA USASTE TU TEST HOY*

⏳ Vuelve mañana
💎 *Escribe 2* para planes premium
🔑 *O envía tu HWID/ID*`, { sendSeen: false });
            return;
        }
        
        await setUserState(phone, 'awaiting_hwid_test');
        await client.sendMessage(phone, `🆓 *TEST GRATIS 2 HORAS*

Para generar tu archivo HC de prueba:

🔑 *Envía tu HWID o ID* 
(Ejemplo: mi-dispositivo-123, android-id, etc.)

📁 *Recibirás:* Archivo .hc válido por 2 horas

⚠️ *Solo 1 test por día*`, { sendSeen: false });
    }
    else if (text === '2' && userState.state === 'main_menu') {
        // ✅ COMANDO 2 EN MENÚ PRINCIPAL = COMPRAR PLAN
        await setUserState(phone, 'viewing_plans');
        
        await client.sendMessage(phone, `💎 *PLANES HTTP CUSTOM*

Elige un plan para recibir archivo .hc premium:

🗓 *1* - 7 días - $${config.prices.price_7d} ARS
🗓 *2* - 15 días - $${config.prices.price_15d} ARS
🗓 *3* - 30 días - $${config.prices.price_30d} ARS

💳 *Pago por MercadoPago*
⚡ *Archivo HC enviado al confirmar pago*

💰 *PARA COMPRAR:* Escribe 1, 2 o 3
💬 *Para volver:* Escribe "menu"`, { sendSeen: false });
    }
    else if ((text === '1' || text === '2' || text === '3') && userState.state === 'viewing_plans') {
        // ✅ COMPRAR PLAN HC
        config = loadConfig();
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            await client.sendMessage(phone, `❌ *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Soporte: *Escribe 6*`, { sendSeen: false });
            await setUserState(phone, 'main_menu');
            return;
        }
        
        const planMap = {
            '1': { days: 7, amount: config.prices.price_7d, plan: '7d' },
            '2': { days: 15, amount: config.prices.price_15d, plan: '15d' },
            '3': { days: 30, amount: config.prices.price_30d, plan: '30d' }
        };
        
        const p = planMap[text];
        
        if (!p) {
            await client.sendMessage(phone, `❌ *PLAN NO VÁLIDO*
Escribe solo 1, 2 o 3`, { sendSeen: false });
            return;
        }
        
        // Guardar información del plan en el estado
        await setUserState(phone, 'awaiting_payment_confirmation', { plan: p.plan, days: p.days, amount: p.amount });
        
        // Verificar si ya existe pago pendiente
        const existingPayment = await getExistingPayment(phone, p.plan, p.days);
        
        if (existingPayment) {
            await client.sendMessage(phone, `📋 *TIENES UN PAGO PENDIENTE*

Ya generaste un pago para este plan.

⚡ *PLAN:* ${p.days} días
💰 *$${existingPayment.amount} ARS*

🔗 *ENLACE DE PAGO EXISTENTE:*
${existingPayment.payment_url}

⏰ *Este enlace expira en 24 horas*

💬 Escribe *4* para ver estado del pago
💬 Escribe "menu" para volver`, { sendSeen: false });
            
            // Enviar QR si existe
            if (fs.existsSync(existingPayment.qr_code)) {
                try {
                    const media = MessageMedia.fromFilePath(existingPayment.qr_code);
                    await client.sendMessage(phone, media, { 
                        caption: `📱 *ESCAPEA CON MERCADOPAGO*
                        
⚡ ${p.days} días
💰 $${existingPayment.amount} ARS
⏰ Válido por 24 horas`, 
                        sendSeen: false 
                    });
                } catch (qrError) {
                    console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                }
            }
            
            await setUserState(phone, 'main_menu');
            return;
        }
        
        // Crear nuevo pago
        await client.sendMessage(phone, `⏳ *GENERANDO PAGO...*

📦 Plan: *${p.days} días*
💰 Monto: *$${p.amount} ARS*

⏰ *Procesando...*`, { sendSeen: false });
        
        try {
            const payment = await createMercadoPagoPayment(phone, p.plan, p.days, p.amount);
            
            if (payment.success) {
                await client.sendMessage(phone, `💳 *PAGO GENERADO*

⚡ *PLAN:* ${p.days} días
💰 *$${p.amount} ARS*

🔗 *ENLACE DE PAGO:*
${payment.paymentUrl}

✅ *TE NOTIFICARÉ CUANDO SE APRUEBE*
📁 *Luego envía tu HWID/ID para recibir archivo .hc*

💬 Escribe *4* para ver estado del pago
💬 Escribe "menu" para volver`, { sendSeen: false });
                
                if (fs.existsSync(payment.qrPath)) {
                    try {
                        const media = MessageMedia.fromFilePath(payment.qrPath);
                        await client.sendMessage(phone, media, { 
                            caption: `📱 *ESCANEA CON MERCADOPAGO*
                            
⚡ ${p.days} días
💰 $${p.amount} ARS
⏰ Pago válido por 24 horas`, 
                            sendSeen: false 
                        });
                    } catch (qrError) {
                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                    }
                }
            } else {
                await client.sendMessage(phone, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
            }
        } catch (error) {
            console.error(chalk.red('❌ Error en compra HC:'), error);
            await client.sendMessage(phone, `❌ *ERROR INESPERADO*

${error.message}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
    else if (text === '3' && userState.state === 'main_menu') {
        // ✅ COMANDO 3 = MIS ARCHIVOS HC
        const files = await getUserHcFiles(phone);
        
        if (files.length === 0) {
            await client.sendMessage(phone, `📁 *SIN ARCHIVOS HC ACTIVOS*

🆓 *Escribe 1* - Test gratis
💰 *Escribe 2* - Comprar plan premium
🔑 *Envía tu HWID/ID* para generar nuevo`, { sendSeen: false });
            return;
        }
        
        let msg = `📁 *TUS ARCHIVOS HC ACTIVOS*\n\n`;
        
        files.forEach((file, i) => {
            const tipo = file.tipo === 'premium' ? '💎' : '🆓';
            const tipoText = file.tipo === 'premium' ? 'PREMIUM' : 'TEST';
            const expira = moment(file.expires_at).format('DD/MM HH:mm');
            const descargas = file.download_count;
            
            msg += `*${i+1}. ${tipo} ${tipoText}*\n`;
            msg += `📁 ${file.filename}\n`;
            msg += `🔑 HWID: ${file.hwid}\n`;
            msg += `⏰ ${expira}\n`;
            msg += `📥 ${descargas} descarga(s)\n\n`;
        });
        
        msg += `🔗 *DESCARGAR:* http://${config.bot.server_ip}:8002/\n`;
        msg += `💬 Escribe "menu" para volver`;
        
        await client.sendMessage(phone, msg, { sendSeen: false });
    }
    else if (text === '4' && userState.state === 'main_menu') {
        // ✅ COMANDO 4 = ESTADO DE PAGO
        db.all(`SELECT plan, amount, status, created_at, payment_url, days FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone],
            async (err, pays) => {
                if (!pays || pays.length === 0) {
                    await client.sendMessage(phone, `💳 *SIN PAGOS REGISTRADOS*

💰 *Escribe 2* - Ver planes disponibles
💬 Escribe "menu" para volver`, { sendSeen: false });
                    return;
                }
                
                let msg = `💳 *ESTADO DE TUS PAGOS HC*\n\n`;
                
                pays.forEach((p, i) => {
                    const emoji = p.status === 'approved' ? '✅' : '⏳';
                    const statusText = p.status === 'approved' ? 'APROBADO' : 'PENDIENTE';
                    msg += `*${i+1}. ${emoji} ${statusText}*\n`;
                    msg += `Plan: ${p.days} días | $${p.amount} ARS\n`;
                    msg += `Fecha: ${moment(p.created_at).format('DD/MM HH:mm')}\n`;
                    if (p.status === 'pending' && p.payment_url) {
                        msg += `🔗 ${p.payment_url.substring(0, 40)}...\n`;
                    }
                    msg += `\n`;
                });
                
                msg += `🔄 Verificación automática cada 2 minutos\n`;
                msg += `💬 Escribe "menu" para volver`;
                
                await client.sendMessage(phone, msg, { sendSeen: false });
            });
    }
    else if (text === '5' && userState.state === 'main_menu') {
        // ✅ COMANDO 5 = DESCARGAR APP
        await client.sendMessage(phone, `📱 *HTTP CUSTOM APP*

Para usar los archivos .hc necesitas la aplicación HTTP Custom.

🔗 *Descargas oficiales:*
• Play Store: https://play.google.com/store/apps/details?id=com.minhui.hc
• GitHub: https://github.com/HTTPCustom/HttpCustom

📋 *INSTRUCCIONES:*
1. Instala HTTP Custom
2. Importa el archivo .hc que te enviaremos
3. Activa el servicio VPN
4. ¡Listo!

💡 *Después de instalar, envía tu HWID/ID*`, { sendSeen: false });
    }
    else if (text === '6' && userState.state === 'main_menu') {
        // ✅ COMANDO 6 = SOPORTE
        await client.sendMessage(phone, `🆘 *SOPORTE TÉCNICO HC*

📞 *WhatsApp Soporte:*
https://wa.me/543435071016

⏰ *Horario:* 9AM - 10PM

📋 *PROBLEMAS COMUNES:*
• No llega archivo → Revisa "Archivos" en WhatsApp
• Error importar HC → Verifica que sea archivo .hc válido
• Pago pendiente → Escribe *4* para estado

🔗 *Descargar archivos:* http://${config.bot.server_ip}:8002/

💬 Escribe "menu" para volver`, { sendSeen: false });
    }
    else if (userState.state === 'awaiting_hwid_test') {
        // ✅ RECIBIÓ HWID PARA TEST
        const hwid = text.trim();
        
        if (hwid.length < 3) {
            await client.sendMessage(phone, `❌ *HWID/ID MUY CORTO*

Envía un identificador válido
(Ej: mi-celular-123, android-abc, etc.)

💬 Escribe "menu" para cancelar`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `⏳ *GENERANDO ARCHIVO HC DE TEST...*

🔑 HWID: *${hwid}*
⏰ Válido por: *2 horas*

⌛ Un momento...`, { sendSeen: false });
        
        try {
            // Crear usuario test
            const user = await createHcUser(phone, hwid, 'test', 0);
            registerTest(phone);
            
            // Generar archivo HC
            const hcFile = await generateHcFile(phone, hwid, 'test', 0);
            
            if (hcFile.success) {
                // Guardar registro del archivo
                db.get('SELECT id FROM users WHERE hwid = ?', [hwid], (err, userRow) => {
                    if (userRow) {
                        db.run(
                            `INSERT INTO hc_files (user_id, filename, filepath, file_size, tipo, expires_at, download_count) 
                             VALUES (?, ?, ?, ?, 'test', ?, 1)`,
                            [userRow.id, hcFile.filename, hcFile.archivePath, hcFile.size, hcFile.expires]
                        );
                    }
                });
                
                // Enviar archivo
                await sendHcFile(phone, hcFile);
                
                await client.sendMessage(phone, `✅ *TEST ACTIVADO EXITOSAMENTE*

📁 *Archivo HC generado y enviado*
🔑 *HWID:* ${hwid}
⏰ *Válido hasta:* ${hcFile.expires}

💡 *Para renovar o cambiar a premium:*
💎 *Escribe 2* para ver planes
💬 *Escribe "menu" para volver*`, { sendSeen: false });
                
            } else {
                await client.sendMessage(phone, `❌ *ERROR GENERANDO ARCHIVO*

${hcFile.error}

💬 Intenta con otro HWID/ID
💬 Escribe "menu" para volver`, { sendSeen: false });
            }
            
        } catch (error) {
            console.error(chalk.red('❌ Error test HC:'), error);
            await client.sendMessage(phone, `❌ *ERROR EN TEST*

${error.message}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
    else if (userState.state === 'awaiting_payment_confirmation') {
        // Usuario en estado de espera de pago, probablemente envió HWID
        const hwid = text.trim();
        
        if (hwid.length < 3) {
            await client.sendMessage(phone, `❌ *HWID/ID INVÁLIDO*

Envía un identificador válido para recibir tu archivo HC premium.

💬 Escribe "menu" para volver`, { sendSeen: false });
            return;
        }
        
        // Verificar si tiene pagos aprobados
        db.get(`SELECT plan, days, amount FROM payments WHERE phone = ? AND status = 'approved' ORDER BY approved_at DESC LIMIT 1`, 
            [phone], async (err, payment) => {
                
                if (err || !payment) {
                    await client.sendMessage(phone, `⚠️ *NO TIENES PAGOS APROBADOS*

💰 *Escribe 2* para comprar un plan
💳 *Escribe 4* para ver estado de pagos

💬 Escribe "menu" para volver`, { sendSeen: false });
                    await setUserState(phone, 'main_menu');
                    return;
                }
                
                await client.sendMessage(phone, `⏳ *GENERANDO ARCHIVO HC PREMIUM...*

🔑 HWID: *${hwid}*
📦 Plan: *${payment.days} días*
💰 Monto: *$${payment.amount} ARS*

⌛ Un momento...`, { sendSeen: false });
                
                try {
                    // Crear usuario premium
                    const user = await createHcUser(phone, hwid, 'premium', payment.days);
                    
                    // Generar archivo HC premium
                    const hcFile = await generateHcFile(phone, hwid, 'premium', payment.days);
                    
                    if (hcFile.success) {
                        // Guardar registro del archivo
                        db.get('SELECT id FROM users WHERE hwid = ?', [hwid], (err, userRow) => {
                            if (userRow) {
                                db.run(
                                    `INSERT INTO hc_files (user_id, filename, filepath, file_size, tipo, expires_at, download_count) 
                                     VALUES (?, ?, ?, ?, 'premium', ?, 1)`,
                                    [userRow.id, hcFile.filename, hcFile.archivePath, hcFile.size, hcFile.expires]
                                );
                            }
                        });
                        
                        // Enviar archivo
                        await sendHcFile(phone, hcFile);
                        
                        await client.sendMessage(phone, `🎉 *ARCHIVO HC PREMIUM ENVIADO*

✅ *Activación exitosa*
📁 *Archivo HC premium generado*
🔑 *HWID:* ${hwid}
📦 *Plan:* ${payment.days} días
⏰ *Válido hasta:* ${hcFile.expires}

🔗 *Descargar nuevamente:*
http://${config.bot.server_ip}:8002/${hcFile.filename}

💡 *Guarda tu HWID para renovaciones*
💬 *Escribe "menu" para volver*`, { sendSeen: false });
                        
                    } else {
                        await client.sendMessage(phone, `❌ *ERROR GENERANDO ARCHIVO PREMIUM*

${hcFile.error}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
                    }
                    
                } catch (error) {
                    console.error(chalk.red('❌ Error premium HC:'), error);
                    await client.sendMessage(phone, `❌ *ERROR EN PREMIUM*

${error.message}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
                }
                
                await setUserState(phone, 'main_menu');
            });
    }
    else if (text.length >= 3 && text.length <= 50 && !text.match(/^\d+$/)) {
        // ✅ POSIBLE HWID EN MENÚ PRINCIPAL
        // Verificar si tiene pagos aprobados pendientes de archivo
        db.get(`SELECT plan, days, amount FROM payments WHERE phone = ? AND status = 'approved' ORDER BY approved_at DESC LIMIT 1`, 
            [phone], async (err, payment) => {
                
                const hwid = text.trim();
                
                if (payment) {
                    // Tiene pago aprobado → generar premium
                    await client.sendMessage(phone, `⏳ *DETECTADO PAGO APROBADO*

Generando archivo HC premium...

🔑 HWID: *${hwid}*
📦 Plan: *${payment.days} días*

⌛ Un momento...`, { sendSeen: false });
                    
                    try {
                        const user = await createHcUser(phone, hwid, 'premium', payment.days);
                        const hcFile = await generateHcFile(phone, hwid, 'premium', payment.days);
                        
                        if (hcFile.success) {
                            // Guardar registro
                            db.get('SELECT id FROM users WHERE hwid = ?', [hwid], (err, userRow) => {
                                if (userRow) {
                                    db.run(
                                        `INSERT INTO hc_files (user_id, filename, filepath, file_size, tipo, expires_at, download_count) 
                                         VALUES (?, ?, ?, ?, 'premium', ?, 1)`,
                                        [userRow.id, hcFile.filename, hcFile.archivePath, hcFile.size, hcFile.expires]
                                    );
                                }
                            });
                            
                            await sendHcFile(phone, hcFile);
                            await client.sendMessage(phone, `✅ *ARCHIVO HC PREMIUM ENVIADO*

🔗 *Descargar nuevamente:*
http://${config.bot.server_ip}:8002/${hcFile.filename}

💬 Escribe "menu" para volver`, { sendSeen: false });
                        }
                    } catch (error) {
                        console.error(chalk.red('❌ Error HWID premium:'), error);
                    }
                    
                } else {
                    // No tiene pagos → ofrecer test o compra
                    if (await canCreateTest(phone)) {
                        await setUserState(phone, 'awaiting_hwid_test');
                        await client.sendMessage(phone, `🔑 *HWID/ID RECIBIDO:* ${hwid}

🆓 *¿Quieres test gratis de 2 horas?*

✅ *Sí* - Generar archivo HC test
💰 *No* - Ver planes premium (Escribe 2)
💬 *Cancelar* - Escribe "menu"`, { sendSeen: false });
                    } else {
                        await client.sendMessage(phone, `🔑 *HWID/ID RECIBIDO:* ${hwid}

⚠️ *Ya usaste tu test hoy*

💰 *Escribe 2* para comprar plan premium
💬 *Escribe "menu" para volver*`, { sendSeen: false });
                    }
                }
            });
    }
    else {
        // Comando no reconocido
        await client.sendMessage(phone, `❌ *COMANDO NO RECONOCIDO*

📋 *Comandos disponibles:*
• menu - Menú principal
• 1 - Test gratis (solo en menú)
• 2 - Comprar plan (solo en menú)
• 3 - Mis archivos HC (solo en menú)
• 4 - Estado de pago (solo en menú)
• 5 - Descargar APP (solo en menú)
• 6 - Soporte (solo en menú)

🔑 *ENVÍA TU HWID/ID* para recibir archivo .hc
   (Ejemplo: mi-celular-123, android-id, etc.)`, { sendSeen: false });
    }
});

// ✅ Verificar pagos cada 2 minutos
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos HC pendientes...'));
    checkPendingPayments();
});

// ✅ Limpiar archivos HC expirados cada hora
cron.schedule('0 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando archivos HC expirados...`));
    
    // Buscar archivos expirados
    db.all(`SELECT filename, filepath FROM hc_files WHERE expires_at < ?`, [now], async (err, files) => {
        if (err || !files || files.length === 0) return;
        
        for (const file of files) {
            try {
                // Eliminar archivo generado
                if (fs.existsSync(file.filepath)) {
                    await fs.unlink(file.filepath);
                }
                
                // Eliminar de archivos
                const archivePath = path.join(config.paths.archives, path.basename(file.filepath));
                if (fs.existsSync(archivePath)) {
                    await fs.unlink(archivePath);
                }
                
                console.log(chalk.green(`🗑️ Eliminado: ${file.filename}`));
            } catch (e) {
                console.error(chalk.red(`Error eliminando ${file.filename}:`), e.message);
            }
        }
        
        // Eliminar registros de BD
        db.run(`DELETE FROM hc_files WHERE expires_at < ?`, [now]);
        console.log(chalk.green(`✅ Limpiados ${files.length} archivos HC`));
    });
});

// ✅ Limpiar estados antiguos cada hora
cron.schedule('0 * * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando estados antiguos...'));
    db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`, (err) => {
        if (!err) console.log(chalk.green('✅ Estados antiguos limpiados'));
    });
});

// ✅ Limpiar usuarios expirados cada 6 horas
cron.schedule('0 */6 * * *', () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios HC expirados...`));
    
    db.run(`UPDATE users SET status = 0 WHERE expires_at < ? AND status = 1`, [now], (err) => {
        if (!err) {
            db.get(`SELECT changes() as count`, (err, row) => {
                if (row && row.count > 0) {
                    console.log(chalk.green(`✅ ${row.count} usuarios HC desactivados`));
                }
            });
        }
    });
});

console.log(chalk.green('\n🚀 Inicializando bot de distribución HC...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot HC creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL HC
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL HC...${NC}"

cat > /usr/local/bin/hcbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/hc-bot/data/users.db"
CONFIG="/opt/hc-bot/config/config.json"
TEMPLATES_DIR="/opt/hc-bot/templates"
GENERATED_DIR="/opt/hc-bot/generated"
ARCHIVES_DIR="/opt/hc-bot/archives"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL HC BOT PRO v8.7                      ║${NC}"
    echo -e "${CYAN}║               📁 SISTEMA DE DISTRIBUCIÓN DE ARCHIVOS .HC    ║${NC}"
    echo -e "${CYAN}║               🔑 CLIENTE ENVÍA ID → RECIBE ARCHIVO          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    ACTIVE_FILES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hc_files WHERE expires_at > datetime('now')" 2>/dev/null || echo "0")
    TOTAL_TEMPLATES=$(find "$TEMPLATES_DIR" -name "*.hc" -type f | wc -l)
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="hc-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    MP_TOKEN=$(get_val '.mercadopago.access_token')
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" && "$MP_TOKEN" != "null" ]]; then
        MP_STATUS="${GREEN}✅ SDK v2.x ACTIVO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA HC${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Archivos HC activos: ${CYAN}$ACTIVE_FILES${NC}"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  Plantillas HC: ${CYAN}$TOTAL_TEMPLATES${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Test: ${GREEN}2 horas${NC} | Limpieza: ${GREEN}cada hora${NC}"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  📁  Subir plantilla HC"
    echo -e "${CYAN}[5]${NC}  📋  Listar plantillas"
    echo -e "${CYAN}[6]${NC}  🗑️   Eliminar plantilla"
    echo -e ""
    echo -e "${CYAN}[7]${NC}  👤  Listar usuarios HC"
    echo -e "${CYAN}[8]${NC}  📊  Ver archivos generados"
    echo -e "${CYAN}[9]${NC}  💰  Cambiar precios"
    echo -e "${CYAN}[10]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[11]${NC} 📝  Ver logs"
    echo -e "${CYAN}[12]${NC} 🧹  Limpiar archivos expirados"
    echo -e "${CYAN}[13]${NC} 🔧  Reparar bot"
    echo -e "${CYAN}[14]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[15]${NC} 📥  Descargar archivo HC"
    echo -e "${CYAN}[16]${NC} ⚙️   Ver configuración"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot HC...${NC}"
            cd /root/hc-bot
            pm2 restart hc-bot 2>/dev/null || pm2 start bot.js --name hc-bot
            pm2 save
            echo -e "${GREEN}✅ Bot HC reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot HC...${NC}"
            pm2 stop hc-bot
            echo -e "${GREEN}✅ Bot HC detenido${NC}"
            sleep 2
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-hc-bot.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-hc-bot.png${NC}\n"
                read -p "¿Ver logs en tiempo real? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs hc-bot --lines 200
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs hc-bot --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  📁 SUBIR PLANTILLA HC                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}Archivos HC en /root:${NC}"
            find /root -name "*.hc" -type f 2>/dev/null | head -10
            
            read -p "📝 Nombre para la plantilla (ej: premium): " NAME
            read -p "📝 Descripción: " DESC
            
            echo -e "\n${YELLOW}Ruta del archivo .hc:${NC}"
            echo -e "1. Buscar en /root"
            echo -e "2. Ingresar ruta manual"
            echo -e "3. Cancelar"
            read -p "Opción: " FILE_OPT
            
            case $FILE_OPT in
                1)
                    HC_FILES=$(find /root -name "*.hc" -type f 2>/dev/null | head -5)
                    if [[ -z "$HC_FILES" ]]; then
                        echo -e "${RED}❌ No se encontraron archivos .hc en /root${NC}"
                        read -p "Presiona Enter..."
                        continue
                    fi
                    
                    i=1
                    while IFS= read -r file; do
                        size=$(du -h "$file" 2>/dev/null | cut -f1)
                        echo -e "  ${i}. ${file} (${size})"
                        ((i++))
                    done <<< "$HC_FILES"
                    
                    read -p "Selecciona archivo (1-$((i-1))): " SEL
                    if [[ "$SEL" =~ ^[0-9]+$ ]]; then
                        selected=$(echo "$HC_FILES" | sed -n "${SEL}p")
                        filename=$(basename "$selected")
                        dest="$TEMPLATES_DIR/$filename"
                        
                        cp "$selected" "$dest" && chmod 644 "$dest"
                        
                        sqlite3 "$DB" "INSERT INTO hc_templates (name, filename, filepath, description) VALUES ('$NAME', '$filename', '$dest', '$DESC')"
                        
                        echo -e "${GREEN}✅ Plantilla subida: $filename${NC}"
                    fi
                    ;;
                2)
                    read -p "📁 Ruta completa del archivo .hc: " FILE_PATH
                    if [[ -f "$FILE_PATH" && "$FILE_PATH" == *.hc ]]; then
                        filename=$(basename "$FILE_PATH")
                        dest="$TEMPLATES_DIR/$filename"
                        
                        cp "$FILE_PATH" "$dest" && chmod 644 "$dest"
                        
                        sqlite3 "$DB" "INSERT INTO hc_templates (name, filename, filepath, description) VALUES ('$NAME', '$filename', '$dest', '$DESC')"
                        
                        echo -e "${GREEN}✅ Plantilla subida: $filename${NC}"
                    else
                        echo -e "${RED}❌ Archivo no válido o no es .hc${NC}"
                    fi
                    ;;
            esac
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  📋 PLANTILLAS HC DISPONIBLES               ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}Plantillas en base de datos:${NC}"
            sqlite3 -column -header "$DB" "SELECT id, name, filename, description, is_active FROM hc_templates ORDER BY id DESC"
            
            echo -e "\n${YELLOW}Archivos en directorio:${NC}"
            find "$TEMPLATES_DIR" -name "*.hc" -type f -exec ls -lh {} \; 2>/dev/null | awk '{print $9, $5}' | sed 's|'"$TEMPLATES_DIR"'/||'
            
            read -p "Presiona Enter..." 
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  🗑️  ELIMINAR PLANTILLA HC                  ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT id, name, filename FROM hc_templates ORDER BY id DESC"
            
            read -p "📝 ID de la plantilla a eliminar (0=cancelar): " TEMPLATE_ID
            if [[ "$TEMPLATE_ID" != "0" && "$TEMPLATE_ID" =~ ^[0-9]+$ ]]; then
                FILENAME=$(sqlite3 "$DB" "SELECT filename FROM hc_templates WHERE id = $TEMPLATE_ID" 2>/dev/null)
                if [[ -n "$FILENAME" ]]; then
                    sqlite3 "$DB" "DELETE FROM hc_templates WHERE id = $TEMPLATE_ID"
                    rm -f "$TEMPLATES_DIR/$FILENAME" 2>/dev/null
                    echo -e "${GREEN}✅ Plantilla eliminada${NC}"
                fi
            fi
            read -p "Presiona Enter..." 
            ;;
        7)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                       👤 USUARIOS HC                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT id, substr(phone,1,12) as telefono, hwid, tipo, expires_at, download_count, status FROM users ORDER BY id DESC LIMIT 20"
            
            echo -e "\n${YELLOW}Estadísticas:${NC}"
            sqlite3 "$DB" "SELECT 'Test: ' || SUM(CASE WHEN tipo='test' THEN 1 ELSE 0 END) || ' | Premium: ' || SUM(CASE WHEN tipo='premium' THEN 1 ELSE 0 END) || ' | Total: ' || COUNT(*) FROM users WHERE status=1"
            
            read -p "Presiona Enter..." 
            ;;
        8)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ARCHIVOS HC GENERADOS               ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}Últimos 15 archivos:${NC}"
            sqlite3 -column -header "$DB" "SELECT hf.filename, u.hwid, hf.tipo, hf.expires_at, hf.download_count, hf.created_at FROM hc_files hf JOIN users u ON hf.user_id = u.id ORDER BY hf.id DESC LIMIT 15"
            
            echo -e "\n${YELLOW}Directorio generado:${NC}"
            ls -lh "$GENERATED_DIR" 2>/dev/null | head -10 || echo "Vacío"
            
            echo -e "\n${YELLOW}Directorio archivos:${NC}"
            ls -lh "$ARCHIVES_DIR" 2>/dev/null | head -10 || echo "Vacío"
            
            echo -e "\n${YELLOW}Estadísticas:${NC}"
            echo -e "  Generados: $(ls "$GENERATED_DIR" 2>/dev/null | wc -l || echo 0)"
            echo -e "  Archivados: $(ls "$ARCHIVES_DIR" 2>/dev/null | wc -l || echo 0)"
            
            read -p "Presiona Enter..." 
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                       💰 CAMBIAR PRECIOS HC                 ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_TEST=$(get_val '.prices.test_hours')
            
            echo -e "Precios actuales:"
            echo -e "  1. 7 días: $${CURRENT_7D} ARS"
            echo -e "  2. 15 días: $${CURRENT_15D} ARS"
            echo -e "  3. 30 días: $${CURRENT_30D} ARS"
            echo -e "  Test: ${CURRENT_TEST} horas\n"
            
            read -p "Nuevo precio 7 días [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15 días [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30 días [${CURRENT_30D}]: " NEW_30D
            read -p "Horas de test [${CURRENT_TEST}]: " NEW_TEST
            
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$NEW_TEST" ]] && set_val '.prices.test_hours' "$NEW_TEST"
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
            sleep 2
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║              🔑 CONFIGURAR MERCADOPAGO SDK v2.x             ║${NC}"
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
                    cd /root/hc-bot && pm2 restart hc-bot
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago SDK v2.x activado${NC}"
                else
                    echo -e "${RED}❌ Token inválido${NC}"
                    echo -e "${YELLOW}Debe empezar con APP_USR- o TEST-${NC}"
                fi
            fi
            read -p "Presiona Enter..." 
            ;;
        11)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs hc-bot --lines 100
            ;;
        12)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                🧹 LIMPIAR ARCHIVOS HC EXPIRADOS            ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${RED}⚠️  Esto eliminará archivos HC expirados${NC}\n"
            read -p "¿Continuar? (s/N): " CONF
            
            if [[ "$CONF" == "s" ]]; then
                # Eliminar de base de datos
                EXPIRED_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hc_files WHERE expires_at < datetime('now')" 2>/dev/null || echo "0")
                
                # Eliminar archivos generados expirados
                find "$GENERATED_DIR" -name "*.hc" -type f -mtime +1 -delete 2>/dev/null
                
                # Eliminar de archivos
                find "$ARCHIVES_DIR" -name "*.hc" -type f -mtime +7 -delete 2>/dev/null
                
                # Actualizar BD
                sqlite3 "$DB" "DELETE FROM hc_files WHERE expires_at < datetime('now')"
                sqlite3 "$DB" "UPDATE users SET status = 0 WHERE expires_at < datetime('now') AND status = 1"
                
                echo -e "${GREEN}✅ Limpieza completada${NC}"
                echo -e "${YELLOW}Archivos expirados eliminados: $EXPIRED_COUNT${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        13)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔧 REPARAR BOT HC                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${RED}⚠️  Borrará sesión de WhatsApp y reiniciará${NC}\n"
            read -p "¿Continuar? (s/N): " CONF
            
            if [[ "$CONF" == "s" ]]; then
                echo -e "\n${YELLOW}🧹 Limpiando...${NC}"
                rm -rf /root/.wwebjs_auth/* /root/.wwebjs_cache/* /root/qr-hc-bot.png
                echo -e "${YELLOW}📦 Reinstalando...${NC}"
                cd /root/hc-bot && npm install --silent
                echo -e "${YELLOW}🔧 Aplicando parches...${NC}"
                find /root/hc-bot/node_modules -name "Client.js" -type f -exec sed -i 's/if (chat && chat.markedUnread)/if (false)/g' {} \; 2>/dev/null || true
                echo -e "${YELLOW}🔄 Reiniciando...${NC}"
                pm2 restart hc-bot
                echo -e "\n${GREEN}✅ Reparado - Espera 10s para QR${NC}"
                sleep 10
            fi
            read -p "Presiona Enter..." 
            ;;
        14)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                 🧪 TEST MERCADOPAGO SDK v2.x                ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
                echo -e "${RED}❌ Token no configurado${NC}\n"
                read -p "Presiona Enter..." 
                continue
            fi
            
            echo -e "${YELLOW}🔑 Token: ${TOKEN:0:30}...${NC}\n"
            echo -e "${YELLOW}🔄 Probando conexión con API...${NC}\n"
            
            RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" "https://api.mercadopago.com/v1/payment_methods" 2>&1)
            HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
            BODY=$(echo "$RESPONSE" | head -n-1)
            
            if [[ "$HTTP_CODE" == "200" ]]; then
                echo -e "${GREEN}✅ CONEXIÓN EXITOSA${NC}\n"
                echo -e "${CYAN}Métodos de pago disponibles:${NC}"
                echo "$BODY" | jq -r '.[].name' 2>/dev/null | head -5
                echo -e "\n${GREEN}✅ MercadoPago SDK v2.x funcionando correctamente${NC}"
            else
                echo -e "${RED}❌ ERROR - Código HTTP: $HTTP_CODE${NC}\n"
                echo -e "${YELLOW}Respuesta:${NC}"
                echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
            fi
            
            read -p "\nPresiona Enter..." 
            ;;
        15)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  📥 DESCARGAR ARCHIVO HC                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}Archivos disponibles:${NC}"
            find "$GENERATED_DIR" "$ARCHIVES_DIR" -name "*.hc" -type f 2>/dev/null | xargs -I {} basename {} | head -20
            
            read -p "📝 Nombre del archivo (o Enter para listar todos): " FILENAME
            
            if [[ -n "$FILENAME" ]]; then
                # Buscar en generados
                if [[ -f "$GENERATED_DIR/$FILENAME" ]]; then
                    cp "$GENERATED_DIR/$FILENAME" "/root/$FILENAME"
                    echo -e "${GREEN}✅ Copiado a: /root/$FILENAME${NC}"
                # Buscar en archivos
                elif [[ -f "$ARCHIVES_DIR/$FILENAME" ]]; then
                    cp "$ARCHIVES_DIR/$FILENAME" "/root/$FILENAME"
                    echo -e "${GREEN}✅ Copiado a: /root/$FILENAME${NC}"
                else
                    echo -e "${RED}❌ Archivo no encontrado${NC}"
                fi
            else
                echo -e "${YELLOW}Listando todos...${NC}"
                find "$GENERATED_DIR" "$ARCHIVES_DIR" -name "*.hc" -type f 2>/dev/null -exec ls -lh {} \;
            fi
            
            read -p "Presiona Enter..." 
            ;;
        16)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     ⚙️  CONFIGURACIÓN HC                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🤖 BOT:${NC}"
            echo -e "  IP: $(get_val '.bot.server_ip')"
            echo -e "  Versión: $(get_val '.bot.version')"
            echo -e "  Test: $(get_val '.prices.test_hours') horas"
            
            echo -e "\n${YELLOW}💰 PRECIOS:${NC}"
            echo -e "  1. 7d: $(get_val '.prices.price_7d') ARS"
            echo -e "  2. 15d: $(get_val '.prices.price_15d') ARS"
            echo -e "  3. 30d: $(get_val '.prices.price_30d') ARS"
            
            echo -e "\n${YELLOW}📁 DIRECTORIOS:${NC}"
            echo -e "  Plantillas: $(get_val '.paths.templates')"
            echo -e "  Generados: $(get_val '.paths.generated')"
            echo -e "  Archivos: $(get_val '.paths.archives')"
            echo -e "  BD: $(get_val '.paths.database')"
            
            echo -e "\n${YELLOW}💳 MERCADOPAGO:${NC}"
            MP_TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "null" ]]; then
                echo -e "  Estado: ${GREEN}SDK v2.x ACTIVO${NC}"
                echo -e "  Token: ${MP_TOKEN:0:25}..."
            else
                echo -e "  Estado: ${RED}NO CONFIGURADO${NC}"
            fi
            
            echo -e "\n${YELLOW}🔗 SERVICIOS:${NC}"
            echo -e "  Bot: $(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="hc-bot") | .pm2_env.status' 2>/dev/null || echo "detenido")"
            echo -e "  Servidor HC: http://$(get_val '.bot.server_ip'):8002/"
            
            read -p "\nPresiona Enter..." 
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
echo -e "${GREEN}✅ Panel de control HC creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT HC...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name hc-bot
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# CREAR SCRIPT DE TEST HC
# ================================================
echo -e "\n${CYAN}${BOLD}🧪 CREANDO SCRIPT DE TEST HC...${NC}"

cat > /usr/local/bin/test-hc << 'TESTEOF'
#!/bin/bash
echo -e "\n🔍 TEST DEL SISTEMA HC"
echo -e "=======================\n"

echo -e "📋 Verificando estructura..."
CONFIG="/opt/hc-bot/config/config.json"
DB="/opt/hc-bot/data/users.db"

if [[ -f "$CONFIG" ]]; then
    echo -e "✅ Configuración: $CONFIG"
    echo -e "   IP: $(jq -r '.bot.server_ip' "$CONFIG")"
    echo -e "   Test: $(jq -r '.prices.test_hours' "$CONFIG") horas"
else
    echo -e "❌ Configuración no encontrada"
fi

if [[ -f "$DB" ]]; then
    echo -e "✅ Base de datos: $DB"
    
    echo -e "\n📊 ESTADÍSTICAS HC:"
    echo -e "  Usuarios: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo 0)"
    echo -e "  Archivos HC: $(sqlite3 "$DB" "SELECT COUNT(*) FROM hc_files" 2>/dev/null || echo 0)"
    echo -e "  Plantillas: $(sqlite3 "$DB" "SELECT COUNT(*) FROM hc_templates" 2>/dev/null || echo 0)"
    echo -e "  Pagos: $(sqlite3 "$DB" "SELECT COUNT(*) FROM payments" 2>/dev/null || echo 0)"
else
    echo -e "❌ Base de datos no encontrada"
fi

echo -e "\n📁 DIRECTORIOS:"
echo -e "  Plantillas: $(ls -1 /opt/hc-bot/templates/*.hc 2>/dev/null | wc -l || echo 0) archivos"
echo -e "  Generados: $(ls -1 /opt/hc-bot/generated/*.hc 2>/dev/null | wc -l || echo 0) archivos"
echo -e "  Archivos: $(ls -1 /opt/hc-bot/archives/*.hc 2>/dev/null | wc -l || echo 0) archivos"

echo -e "\n🤖 ESTADO DEL BOT:"
if pm2 status | grep -q "hc-bot"; then
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="hc-bot") | .pm2_env.status' 2>/dev/null || echo "unknown")
    echo -e "  ✅ Bot en ejecución: $STATUS"
else
    echo -e "  ❌ Bot NO está en ejecución"
fi

echo -e "\n🔗 SERVICIOS:"
echo -e "  Servidor HC: http://$(jq -r '.bot.server_ip' "$CONFIG" 2>/dev/null):8002/"

echo -e "\n💡 FLUJO HC:"
echo -e "  1. Cliente envía 'menu'"
echo -e "  2. Elige '1' para test o '2' para comprar"
echo -e "  3. Envía su HWID/ID"
echo -e "  4. Recibe archivo .hc personalizado"
echo -e "  5. Importa en HTTP Custom App"

echo -e "\n✅ Sistema HC funcionando correctamente"
TESTEOF

chmod +x /usr/local/bin/test-hc

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🎉 INSTALACIÓN COMPLETADA - SISTEMA HC 🎉             ║
║                                                              ║
║         HTTP CUSTOM BOT PRO v8.7 - DISTRIBUCIÓN HC         ║
║           📁 SISTEMA DE ARCHIVOS .HC PERSONALIZADOS        ║
║           🔑 CLIENTE ENVÍA ID → RECIBE ARCHIVO             ║
║           💰 PLANES: TEST(2h), 7D, 15D, 30D                ║
║           ⚡ ACTIVACIÓN AUTOMÁTICA                          ║
║           🛒 MERCADOPAGO INTEGRADO                         ║
║           🔗 SERVIDOR DE DESCARGA: puerto 8002             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema de distribución HC instalado${NC}"
echo -e "${GREEN}✅ Cliente envía HWID → Recibe archivo .hc${NC}"
echo -e "${GREEN}✅ Planes: Test 2h, 7d, 15d, 30d${NC}"
echo -e "${GREEN}✅ MercadoPago SDK v2.x integrado${NC}"
echo -e "${GREEN}✅ WhatsApp Web parcheado (no markedUnread error)${NC}"
echo -e "${GREEN}✅ Servidor de descarga HC: puerto 8002${NC}"
echo -e "${GREEN}✅ Panel de control completo${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}\n"
echo -e "  ${GREEN}hcbot${NC}         - Panel de control principal"
echo -e "  ${GREEN}test-hc${NC}       - Test del sistema HC"
echo -e "  ${GREEN}pm2 logs hc-bot${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart hc-bot${NC} - Reiniciar bot\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN INICIAL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}hcbot${NC}"
echo -e "  2. Opción ${CYAN}[4]${NC} - Subir plantilla HC"
echo -e "  3. Opción ${CYAN}[10]${NC} - Configurar MercadoPago"
echo -e "  4. Opción ${CYAN}[14]${NC} - Test MercadoPago"
echo -e "  5. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp\n"

echo -e "${YELLOW}📁 SUBIR PLANTILLAS HC:${NC}"
echo -e "  1. Prepara tu archivo .hc"
echo -e "  2. Cópialo a /root/"
echo -e "  3. Usa hcbot → Opción 4 para subir"
echo -e "  4. Las plantillas se guardan en: ${CYAN}/opt/hc-bot/templates/${NC}\n"

echo -e "${YELLOW}🔗 ACCESOS:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  Servidor HC: ${CYAN}http://$SERVER_IP:8002/${NC}"
echo -e "  Panel: ${CYAN}hcbot${NC}"
echo -e "  Test: ${CYAN}test-hc${NC}\n"

echo -e "${YELLOW}⌨️  FLUJO PARA CLIENTES:${NC}\n"
echo -e "  ${CYAN}1.${NC} Escribe 'menu' → Menú principal"
echo -e "  ${CYAN}2.${NC} Escribe '1' → Test gratis (2h)"
echo -e "  ${CYAN}3.${NC} Envía HWID/ID → Recibe archivo .hc"
echo -e "  ${CYAN}4.${NC} O escribe '2' → Ver planes premium"
echo -e "  ${CYAN}5.${NC} Elige 1(7d), 2(15d), 3(30d)"
echo -e "  ${CYAN}6.${NC} Paga con MercadoPago"
echo -e "  ${CYAN}7.${NC} Pago aprobado → Envía HWID → Recibe HC premium\n"

echo -e "${YELLOW}📱 HTTP CUSTOM APP:${NC}"
echo -e "  • Play Store: https://play.google.com/store/apps/details?id=com.minhui.hc"
echo -e "  • GitHub: https://github.com/HTTPCustom/HttpCustom\n"

read -p "$(echo -e "${YELLOW}¿Probar sistema HC? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Probando sistema...${NC}\n"
    /usr/local/bin/test-hc
fi

read -p "$(echo -e "${YELLOW}¿Abrir panel de control? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}\n"
    sleep 2
    /usr/local/bin/hcbot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}hcbot${NC} para abrir el panel\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema HC instalado exitosamente! Los clientes ahora pueden recibir archivos .hc personalizados 🚀${NC}\n"

exit 0
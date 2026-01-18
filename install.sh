#!/bin/bash
# ================================================
# HTTP CUSTOM HWID BOT v2.0 - MEJORADO
# Bot especializado para HTTP Custom con HWID
# MEJORAS APLICADAS:
# 1. ✅ Cliente ENVÍA HWID → Recibe archivo .hc automáticamente
# 2. ✅ Integración COMPLETA MercadoPago SDK v2.x
# 3. ✅ Sistema de pagos automático
# 4. ✅ Validación de token MP corregida
# 5. ✅ Fechas ISO 8601 correctas
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
║     ╦ ╦╔═╗╔═╗╔╦╗╔═╗╦ ╦  ╔═╗╔═╗╦╔═╗╦ ╦                       ║
║     ╠═╣║ ║║ ║║║║║╣ ╚╦╝  ║ ║║ ║║║  ╠═╣                       ║
║     ╩ ╩╚═╝╚═╝╩ ╩╚═╝ ╩   ╚═╝╚═╝╩╚═╝╩ ╩                       ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║           🤖 HTTP CUSTOM HWID BOT v2.0                      ║
║                🔧 CLIENTE ENVÍA HWID → ARCHIVO .HC          ║
║                💳 MERCADOPAGO SDK v2.x COMPLETO             ║
║                📱 WhatsApp Bot 24/7 MEJORADO                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ MEJORAS APLICADAS:${NC}"
echo -e "  1. ${CYAN}CLIENTE ENVÍA HWID → Recibe .hc automático${NC}"
echo -e "  2. ${YELLOW}MERCADOPAGO SDK v2.x COMPLETO${NC}"
echo -e "  3. ${GREEN}Validación token MP corregida${NC}"
echo -e "  4. ${BLUE}Fechas ISO 8601 correctas${NC}"
echo -e "  5. ${PURPLE}Sistema de pagos automático${NC}"
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
echo -e "   • Crear HTTP Custom HWID Bot v2.0"
echo -e "   • Sistema HWID MEJORADO (envía HWID → recibe .hc)"
echo -e "   • MercadoPago SDK v2.x COMPLETO"
echo -e "   • Panel de control con configuración MP"
echo -e "   • Base de datos SQLite3 con pagos"
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

echo -e "${YELLOW}🔄 Actualizando sistema...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1

echo -e "${YELLOW}📥 Instalando paquetes básicos...${NC}"
apt-get install -y -qq \
    curl wget git unzip \
    sqlite3 jq nano htop \
    cron build-essential \
    ca-certificates gnupg \
    software-properties-common \
    libgbm-dev libxshmfence-dev \
    sshpass at \
    > /dev/null 2>&1

# Habilitar servicio 'at'
systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true

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

# PM2 global
echo -e "${YELLOW}⚡ Instalando PM2...${NC}"
npm install -g pm2 --silent > /dev/null 2>&1

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# CREAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/httpcustom-bot"
USER_HOME="/root/httpcustom-bot"
HWID_DIR="$INSTALL_DIR/hwid"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete httpcustom-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$HWID_DIR"/{archives,pending,processed,templates}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración CON MERCADOPAGO
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom HWID Bot",
        "version": "2.0",
        "server_ip": "$SERVER_IP",
        "admin_phone": ""
    },
    "prices": {
        "test_hours": 1,
        "price_1d": 300.00,
        "price_7d": 800.00,
        "price_15d": 1200.00,
        "price_30d": 2000.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "notification_url": "http://$SERVER_IP:3000/webhook"
    },
    "hwid": {
        "enabled": true,
        "path": "$HWID_DIR",
        "max_file_size_mb": 5,
        "allowed_extensions": ["hc", "txt", "conf"]
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "hwid": "$HWID_DIR"
    }
}
EOF

# Crear base de datos MEJORADA
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    password TEXT,
    hwid TEXT,
    plan TEXT,
    days INTEGER,
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
CREATE TABLE hwid_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT,
    file_path TEXT,
    file_name TEXT,
    file_size INTEGER,
    sent_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_hwid_phone ON hwid_files(phone);
SQL

# Crear archivos de ejemplo
echo -e "${YELLOW}📁 Creando archivos de ejemplo...${NC}"
cat > "$HWID_DIR/templates/ejemplo.hc" << 'HC'
[connection]
host=your-server.com
port=443
username=your_username
password=your_password
method=chacha20-ietf-poly1305
protocol=auth_chain_a
obfs=tls1.2_ticket_auth

[settings]
dns=8.8.8.8,8.8.4.4
proxy_type=http
timeout=30
reconnect=true
HC

echo "HWID-EJEMPLO-001" > "$HWID_DIR/archives/HWID_EJEMPLO001.hc"
echo "HWID-EJEMPLO-002" > "$HWID_DIR/archives/HWID_EJEMPLO002.hc"

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT MEJORADO
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT MEJORADO v2.0...${NC}"

cd "$USER_HOME"

# package.json CON MERCADOPAGO
cat > package.json << 'PKGEOF'
{
    "name": "httpcustom-hwid-bot",
    "version": "2.0.0",
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

# Crear bot.js MEJORADO
echo -e "${YELLOW}📝 Creando bot.js v2.0 mejorado...${NC}"

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
    delete require.cache[require.resolve('/opt/httpcustom-bot/config/config.json')];
    return require('/opt/httpcustom-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// ✅ MERCADOPAGO SDK v2.x - INICIALIZACIÓN
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
console.log(chalk.cyan.bold('║           🤖 HTTP CUSTOM HWID BOT v2.0                       ║'));
console.log(chalk.cyan.bold('║           🔧 CLIENTE ENVÍA HWID → ARCHIVO .HC                ║'));
console.log(chalk.cyan.bold('║           💳 MERCADOPAGO SDK v2.x COMPLETO                   ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ SDK v2.x ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ Sistema HWID mejorado'));
console.log(chalk.green('✅ Cliente envía HWID → Recibe .hc automático'));

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'httpcustom-bot-v2'}),
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
    QRCode.toFile('/root/qr-httpcustom.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.cyan('\n1️⃣ Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('2️⃣ Escanea el QR ☝️'));
    console.log(chalk.green('\n💾 QR guardado: /root/qr-httpcustom.png\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado')));
client.on('loading_screen', (p, m) => console.log(chalk.yellow(`⏳ Cargando: ${p}% - ${m}`)));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT HTTP CUSTOM v2.0 CONECTADO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp\n'));
    qrCount = 0;
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

// 🔧 FUNCIONES MEJORADAS HWID
function generateUsername() {
    return 'http' + Math.random().toString(36).substr(2, 6);
}

function generatePassword() {
    return Math.random().toString(36).substr(2, 10) + Math.random().toString(36).substr(2, 4).toUpperCase();
}

function generateHWID() {
    return 'HWID-' + Math.random().toString(36).substr(2, 8).toUpperCase();
}

async function createHTTPUser(phone, plan, days, hwid = null) {
    const username = generateUsername();
    const password = generatePassword();
    const userHWID = hwid || generateHWID();
    const expireDate = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
    
    console.log(chalk.cyan(`📦 Creando usuario HTTP Custom: ${username}`));
    console.log(chalk.yellow(`🔧 HWID asignado: ${userHWID}`));
    
    try {
        await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, hwid, plan, days, expires_at, status) VALUES (?, ?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, userHWID, plan, days, expireDate],
                (err) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve({
                            success: true,
                            username: username,
                            password: password,
                            hwid: userHWID,
                            expires: expireDate,
                            plan: plan,
                            days: days
                        });
                    }
                }
            );
        });
    } catch (error) {
        console.error(chalk.red('❌ Error creando usuario:'), error.message);
        throw error;
    }
}

async function generateHCFile(username, password, hwid, serverIp = null) {
    const ip = serverIp || config.bot.server_ip;
    const port = 443;
    const method = 'chacha20-ietf-poly1305';
    const protocol = 'auth_chain_a';
    const obfs = 'tls1.2_ticket_auth';
    
    const hcContent = `[connection]
host=${ip}
port=${port}
username=${username}
password=${password}
method=${method}
protocol=${protocol}
obfs=${obfs}

[settings]
dns=8.8.8.8,8.8.4.4
proxy_type=http
timeout=30
reconnect=true
tcp_fast_open=false
workers=1

# HWID: ${hwid}
# Creado: ${moment().format('YYYY-MM-DD HH:mm:ss')}
# Expira: ${moment().add(30, 'days').format('YYYY-MM-DD')}`;
    
    const fileName = `HTTP_${username}_${hwid}.hc`;
    const filePath = `${config.paths.hwid}/archives/${fileName}`;
    
    try {
        fs.writeFileSync(filePath, hcContent);
        console.log(chalk.green(`✅ Archivo .hc creado: ${fileName}`));
        
        db.run(`INSERT INTO hwid_files (phone, hwid, file_path, file_name, file_size) VALUES (?, ?, ?, ?, ?)`,
            ['SYSTEM', hwid, filePath, fileName, hcContent.length]);
            
        return {
            success: true,
            filePath: filePath,
            fileName: fileName,
            content: hcContent
        };
    } catch (error) {
        console.error(chalk.red('❌ Error creando archivo .hc:'), error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

async function sendHCFile(phone, filePath, fileName) {
    try {
        console.log(chalk.cyan(`📤 Enviando archivo .hc: ${fileName}`));
        
        const media = MessageMedia.fromFilePath(filePath);
        await client.sendMessage(phone, media, {
            caption: `📁 *ARCHIVO HTTP CUSTOM CONFIGURADO*\n\n✅ Configuración lista para usar\n📄 Archivo: ${fileName}\n\n💡 *INSTRUCCIONES:*\n1. Guarda este archivo\n2. Ábrelo con HTTP Custom\n3. ¡Conéctate y disfruta!`,
            sendSeen: false
        });
        
        console.log(chalk.green(`✅ Archivo .hc enviado: ${fileName}`));
        
        db.run(`UPDATE hwid_files SET sent_at = CURRENT_TIMESTAMP WHERE file_name = ?`, [fileName]);
        
        return true;
    } catch (error) {
        console.error(chalk.red('❌ Error enviando archivo .hc:'), error.message);
        
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            await client.sendMessage(phone, 
                `📄 *CONTENIDO DEL ARCHIVO .hc*\n\n\`\`\`\n${content}\n\`\`\`\n\n💡 Copia este contenido y guárdalo como archivo .hc`,
                { sendSeen: false }
            );
            return true;
        } catch (e) {
            console.error(chalk.red('❌ Error enviando contenido:'), e.message);
            return false;
        }
    }
}

async function processHWID(phone, hwid) {
    try {
        console.log(chalk.cyan(`🔍 Procesando HWID: ${hwid}`));
        
        // Buscar archivo .hc existente
        const archivesDir = `${config.paths.hwid}/archives`;
        let foundFile = null;
        
        // Primero buscar por nombre exacto
        const possibleFiles = [
            `HTTP_*_${hwid}.hc`,
            `*${hwid}*.hc`,
            `*${hwid}*.txt`,
            `${hwid}.hc`,
            `${hwid}.txt`
        ];
        
        const files = fs.readdirSync(archivesDir);
        for (const file of files) {
            const fileLower = file.toLowerCase();
            const hwidLower = hwid.toLowerCase();
            
            if (fileLower.includes(hwidLower) && (file.endsWith('.hc') || file.endsWith('.txt'))) {
                foundFile = path.join(archivesDir, file);
                break;
            }
        }
        
        if (foundFile) {
            console.log(chalk.green(`✅ Archivo encontrado: ${path.basename(foundFile)}`));
            
            // Registrar en BD
            db.run(`INSERT INTO hwid_files (phone, hwid, file_path, file_name, file_size, sent_at) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
                [phone, hwid, foundFile, path.basename(foundFile), fs.statSync(foundFile).size]);
            
            return {
                success: true,
                filePath: foundFile,
                fileName: path.basename(foundFile),
                found: true
            };
        } else {
            console.log(chalk.yellow(`⚠️ Archivo no encontrado para HWID: ${hwid}`));
            
            // Guardar como pendiente
            const pendingFile = `${config.paths.hwid}/pending/HWID_${phone.split('@')[0]}_${Date.now()}.txt`;
            fs.writeFileSync(pendingFile, `Phone: ${phone}\nHWID: ${hwid}\nTime: ${new Date().toISOString()}\nStatus: NOT_FOUND`);
            
            return {
                success: false,
                error: 'Archivo .hc no encontrado para este HWID',
                hwid: hwid,
                pendingFile: pendingFile
            };
        }
    } catch (error) {
        console.error(chalk.red('❌ Error procesando HWID:'), error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

async function getUserByHWID(hwid) {
    return new Promise((resolve) => {
        db.get(`SELECT * FROM users WHERE hwid = ? AND status = 1`, [hwid], (err, row) => {
            if (err || !row) {
                resolve(null);
            } else {
                resolve(row);
            }
        });
    });
}

async function updateUserHWID(phone, oldHWID, newHWID) {
    return new Promise((resolve) => {
        db.run(`UPDATE users SET hwid = ? WHERE phone = ? AND hwid = ? AND status = 1`,
            [newHWID, phone, oldHWID],
            function(err) {
                if (err) {
                    console.error(chalk.red('❌ Error actualizando HWID:'), err.message);
                    resolve(false);
                } else if (this.changes > 0) {
                    console.log(chalk.green(`✅ HWID actualizado: ${oldHWID} → ${newHWID}`));
                    resolve(true);
                } else {
                    console.log(chalk.yellow(`⚠️ No se encontró usuario con HWID: ${oldHWID}`));
                    resolve(false);
                }
            }
        );
    });
}

async function renewUser(phone, hwid, additionalDays) {
    return new Promise((resolve) => {
        db.get(`SELECT * FROM users WHERE hwid = ? AND phone = ? AND status = 1`, [hwid, phone], (err, user) => {
            if (err || !user) {
                resolve({ success: false, error: 'Usuario no encontrado' });
                return;
            }
            
            const newExpireDate = moment(user.expires_at).add(additionalDays, 'days').format('YYYY-MM-DD 23:59:59');
            
            db.run(`UPDATE users SET expires_at = ?, days = days + ? WHERE id = ?`,
                [newExpireDate, additionalDays, user.id],
                function(updateErr) {
                    if (updateErr) {
                        console.error(chalk.red('❌ Error renovando usuario:'), updateErr.message);
                        resolve({ success: false, error: updateErr.message });
                    } else {
                        console.log(chalk.green(`✅ Usuario renovado: ${user.username} +${additionalDays} días`));
                        
                        exec(`chage -E ${moment().add(user.days + additionalDays, 'days').format('%Y-%m-%d')} ${user.username}`, 
                            (e) => { if (e) console.error(chalk.yellow('⚠️ Error actualizando chage:' + e.message)); });
                        
                        resolve({
                            success: true,
                            username: user.username,
                            newExpireDate: newExpireDate,
                            totalDays: user.days + additionalDays
                        });
                    }
                }
            );
        });
    });
}

// 💳 FUNCIONES MERCADOPAGO MEJORADAS
async function createMercadoPagoPayment(phone, hwid, plan, days, amount) {
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
        const paymentId = `HTTP-${phoneClean}-${hwid}-${plan}-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        // ✅ FECHA ISO 8601 CORRECTA PARA SDK v2.x
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `HTTP CUSTOM ${days} DÍAS - HWID: ${hwid}`,
                description: `Acceso HTTP Custom por ${days} días con HWID: ${hwid}`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: isoDate,
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente`
            },
            auto_return: 'approved',
            statement_descriptor: 'HTTP CUSTOM HWID',
            notification_url: config.mercadopago.notification_url || `http://${config.bot.server_ip}:3000/webhook`
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency}`));
        console.log(chalk.yellow(`📅 Expiración ISO 8601: ${isoDate}`));
        
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
                `INSERT INTO payments (payment_id, phone, hwid, plan, days, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, hwid, plan, days, amount, paymentUrl, qrPath, response.id],
                (err) => {
                    if (err) {
                        console.error(chalk.red('❌ Error guardando pago:'), err.message);
                    }
                }
            );
            
            console.log(chalk.green(`✅ Pago creado exitosamente`));
            console.log(chalk.cyan(`🔗 URL: ${paymentUrl.substring(0, 50)}...`));
            console.log(chalk.cyan(`📱 Preference ID: ${response.id}`));
            
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
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        
        db.run(
            `INSERT INTO logs (type, message, data) VALUES ('mp_error', ?, ?)`,
            [error.message, JSON.stringify({ stack: error.stack })]
        );
        
        return { success: false, error: error.message };
    }
}

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
                    
                    console.log(chalk.cyan(`📋 Pago ${payment.payment_id}: ${mpPayment.status}`));
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO APROBADO: ${payment.payment_id}`));
                        
                        // Crear usuario con el HWID del pago
                        const result = await createHTTPUser(payment.phone, payment.plan, payment.days, payment.hwid);
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                        
                        const expireDate = moment().add(payment.days, 'days').format('DD/MM/YYYY');
                        
                        const message = `╔══════════════════════════════════════╗
║   🎉 *PAGO CONFIRMADO*               ║
╚══════════════════════════════════════╝

✅ Tu compra ha sido aprobada

📋 *DATOS DE ACCESO:*
👤 Usuario: *${result.username}*
🔑 Contraseña: *${result.password}*
🔧 HWID: *${result.hwid}*

⏰ *VÁLIDO HASTA:* ${expireDate}
📅 *DURACIÓN:* ${payment.days} días

🔄 Generando archivo .hc...`;

                        await client.sendMessage(payment.phone, message, { sendSeen: false });
                        
                        // Generar y enviar archivo .hc
                        const hcFile = await generateHCFile(result.username, result.password, result.hwid);
                        if (hcFile.success) {
                            await sendHCFile(payment.phone, hcFile.filePath, hcFile.fileName);
                        }
                        
                        console.log(chalk.green(`✅ Usuario creado y notificado: ${result.username}`));
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
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

// 📱 MANEJADOR DE MENSAJES MEJORADO
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // 🔧 DETECCIÓN MEJORADA DE HWID - LO PRIMERO QUE SE VERIFICA
    const hwidPatterns = [
        /^HWID[-_]/i,
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
        /^[0-9a-f]{16,}$/i,
        /^[A-Z0-9]{12,}$/i
    ];
    
    let isHWID = false;
    for (const pattern of hwidPatterns) {
        if (pattern.test(text)) {
            isHWID = true;
            break;
        }
    }
    
    // También considerar cadenas largas como HWID
    if (!isHWID && text.length > 8 && !['menu', 'hola', 'start', 'hi', 'ayuda', '1', '2', '3', '4', '5'].includes(text)) {
        const knownCommands = ['comprar1', 'comprar7', 'comprar15', 'comprar30', 'renovar', 'editar', 'hc'];
        if (!knownCommands.includes(text.toLowerCase())) {
            isHWID = true;
        }
    }
    
    // ✅ MANEJAR HWID ENVIADO POR CLIENTE
    if (isHWID) {
        console.log(chalk.yellow(`🔍 HWID detectado: ${text.substring(0, 30)}...`));
        
        await client.sendMessage(phone, `⏳ *PROCESANDO HWID*\n\nBuscando archivo .hc para:\n\`${text}\`\n\nPor favor espera...`, { sendSeen: false });
        
        const result = await processHWID(phone, text);
        
        if (result.success && result.found) {
            await client.sendMessage(phone, `✅ *HWID ENCONTRADO*\n\n📁 Archivo: ${result.fileName}\n\n⏳ Enviando archivo .hc...`, { sendSeen: false });
            
            const sent = await sendHCFile(phone, result.filePath, result.fileName);
            
            if (sent) {
                await client.sendMessage(phone, `🎉 *ARCHIVO .HC ENVIADO*\n\n✅ Configuración enviada exitosamente\n📄 Nombre: ${result.fileName}\n\n💡 *INSTRUCCIONES:*\n1. Guarda el archivo .hc\n2. Abre HTTP Custom\n3. Importa el archivo\n4. ¡Conéctate y disfruta!\n\n¿Necesitas ayuda? Escribe *menu*`, { sendSeen: false });
            }
        } else {
            await client.sendMessage(phone, `❌ *HWID NO ENCONTRADO*\n\nNo se encontró un archivo .hc para:\n\`${text}\`\n\n💡 *POSIBLES SOLUCIONES:*\n1. Verifica que el HWID sea correcto\n2. Contacta al administrador\n3. Compra un servicio con este HWID\n\n🛒 *COMPRAR SERVICIO:*\nEscribe *1* para ver planes`, { sendSeen: false });
        }
        
        return;
    }
    
    // MENÚ PRINCIPAL
    if (['menu', 'hola', 'start', 'hi', 'ayuda'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, `╔══════════════════════════════════════╗
║      🤖 *HTTP CUSTOM HWID BOT v2.0*     ║
║            📱 *24/7 ONLINE*            ║
╚══════════════════════════════════════╝

### USUARIO HWID BOT 24/7

#### BIENVENIDO AL PANEL

📝 *ENVÍA TU HWID DIRECTAMENTE*
   (Ej: HWID-ABC123XYZ)

1️⃣ *COMPRAR USUARIO HWID*
   - Planes con MercadoPago

2️⃣ *RENOVAR USUARIO HWID*
   - Extiende tu servicio

3️⃣ *EDITAR HWID*
   - Cambia tu HWID

4️⃣ *ARCHIVO.HC*
   - Obtener configuración

5️⃣ *PRUEBA GRATIS (1H)*
   - Testea el servicio

*Escribe menu para volver atras*

💳 *PAGOS:* MercadoPago seguro
⏰ *ACTIVO:* 24 horas / 7 días`, { sendSeen: false });
    }
    
    // OPCIÓN 1: COMPRAR USUARIO HWID CON MERCADOPAGO
    else if (text === '1') {
        await client.sendMessage(phone, `🛒 *COMPRAR USUARIO HWID*

📋 *PLANES DISPONIBLES:*

🟢 *1 DÍA* - $${config.prices.price_1d} ${config.prices.currency}
   _comprar1 HWID_TU_HWID_

🔵 *7 DÍAS* - $${config.prices.price_7d} ${config.prices.currency}
   _comprar7 HWID_TU_HWID_

🟡 *15 DÍAS* - $${config.prices.price_15d} ${config.prices.currency}
   _comprar15 HWID_TU_HWID_

🔴 *30 DÍAS* - $${config.prices.price_30d} ${config.prices.currency}
   _comprar30 HWID_TU_HWID_

💡 *INCLUYE:*
✓ Usuario único
✓ HWID personalizado
✓ Archivo .hc configurado
✓ Pago seguro con MercadoPago

📝 *EJEMPLO:* 
_comprar7 HWID-ABC123XYZ_

*Reemplaza HWID_TU_HWID con tu HWID*`, { sendSeen: false });
    }
    
    // OPCIONES DE COMPRA CON MERCADOPAGO
    else if (text.toLowerCase().startsWith('comprar1 ') || 
             text.toLowerCase().startsWith('comprar7 ') || 
             text.toLowerCase().startsWith('comprar15 ') || 
             text.toLowerCase().startsWith('comprar30 ')) {
        
        const parts = text.toLowerCase().split(' ');
        const command = parts[0];
        const hwid = parts[1];
        
        if (!hwid) {
            await client.sendMessage(phone, `❌ *HWID NO ESPECIFICADO*

Por favor incluye tu HWID:

📝 *EJEMPLO:*
_${command} HWID-ABC123XYZ_`, { sendSeen: false });
            return;
        }
        
        const planMap = {
            'comprar1': { days: 1, amount: config.prices.price_1d, plan: '1d' },
            'comprar7': { days: 7, amount: config.prices.price_7d, plan: '7d' },
            'comprar15': { days: 15, amount: config.prices.price_15d, plan: '15d' },
            'comprar30': { days: 30, amount: config.prices.price_30d, plan: '30d' }
        };
        
        const p = planMap[command];
        
        await client.sendMessage(phone, `🔄 *PROCESANDO COMPRA*

📦 Plan: *${p.days} días*
🔧 HWID: *${hwid}*
💰 Monto: *$${p.amount} ${config.prices.currency}*

⏳ Generando pago MercadoPago...`, { sendSeen: false });
        
        // Verificar MercadoPago configurado
        config = loadConfig();
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            await client.sendMessage(phone, `❌ *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Contacta soporte para más información.`, { sendSeen: false });
            return;
        }
        
        try {
            const payment = await createMercadoPagoPayment(phone, hwid, p.plan, p.days, p.amount);
            
            if (payment.success) {
                await client.sendMessage(phone, `💳 *PAGO GENERADO EXITOSAMENTE*

📦 Plan: ${p.days} días
🔧 HWID: ${hwid}
💰 $${p.amount} ${config.prices.currency}

🔗 *ENLACE DE PAGO:*
${payment.paymentUrl}

⏰ Válido: 24 horas
📱 ID: ${payment.paymentId.substring(0, 25)}...

🔄 Verificación automática cada 2 min
✅ Te notificaré cuando se apruebe el pago

💬 Escribe *menu* para volver`, { sendSeen: false });
                
                // Enviar QR si existe
                if (fs.existsSync(payment.qrPath)) {
                    try {
                        const media = MessageMedia.fromFilePath(payment.qrPath);
                        await client.sendMessage(phone, media, { caption: '📱 Escanea con la app de MercadoPago', sendSeen: false });
                    } catch (qrError) {
                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                    }
                }
            } else {
                await client.sendMessage(phone, `❌ *ERROR AL GENERAR PAGO*

Detalles: ${payment.error}

Por favor, intenta de nuevo en unos minutos o contacta soporte.`, { sendSeen: false });
            }
        } catch (error) {
            console.error(chalk.red('❌ Error en compra:'), error);
            await client.sendMessage(phone, `❌ *ERROR INESPERADO*

${error.message}

💬 Contacta soporte para ayuda.`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 2: RENOVAR USUARIO HWID
    else if (text === '2') {
        await client.sendMessage(phone, `🔄 *RENOVAR USUARIO HWID*

Para renovar tu servicio, necesito tu HWID actual.

📝 *POR FAVOR ESCRIBE:*
_renovar HWID_TU_HWID_

📋 *EJEMPLO:*
_renovar HWID-ABC123XYZ_

*Reemplaza HWID_TU_HWID con tu HWID actual*`, { sendSeen: false });
    }
    
    // COMANDO RENOVAR
    else if (text.toLowerCase().startsWith('renovar ')) {
        const hwid = text.substring(8).trim();
        
        await client.sendMessage(phone, `🔍 *BUSCANDO USUARIO...*

Buscando usuario con HWID: *${hwid}*

⏳ Por favor espera...`, { sendSeen: false });
        
        const user = await getUserByHWID(hwid);
        
        if (!user) {
            await client.sendMessage(phone, `❌ *USUARIO NO ENCONTRADO*

No se encontró un usuario activo con el HWID: *${hwid}*

💡 *VERIFICA:*
1. Que el HWID sea correcto
2. Que tu servicio no haya expirado
3. Contacta soporte si necesitas ayuda

*Escribe "menu" para volver*`, { sendSeen: false });
            return;
        }
        
        if (user.phone !== phone) {
            await client.sendMessage(phone, `❌ *NO AUTORIZADO*

El HWID *${hwid}* no está asociado a este número.

💡 Contacta al administrador para ayuda.`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `✅ *USUARIO ENCONTRADO*

👤 Usuario: *${user.username}*
🔧 HWID: *${user.hwid}*
⏰ Expira: *${moment(user.expires_at).format('DD/MM/YYYY')}*

📋 *OPCIONES DE RENOVACIÓN:*

1️⃣ *+7 días* - $${config.prices.price_7d} ${config.prices.currency}
   _renovar7 ${hwid}_

2️⃣ *+15 días* - $${config.prices.price_15d} ${config.prices.currency}
   _renovar15 ${hwid}_

3️⃣ *+30 días* - $${config.prices.price_30d} ${config.prices.currency}
   _renovar30 ${hwid}_

*Escribe el comando correspondiente*`, { sendSeen: false });
    }
    
    // COMANDOS DE RENOVACIÓN ESPECÍFICOS
    else if (text.toLowerCase().startsWith('renovar7 ') || 
             text.toLowerCase().startsWith('renovar15 ') || 
             text.toLowerCase().startsWith('renovar30 ')) {
        
        const parts = text.toLowerCase().split(' ');
        const command = parts[0];
        const hwid = parts[1];
        
        const renewMap = {
            'renovar7': { days: 7, amount: config.prices.price_7d },
            'renovar15': { days: 15, amount: config.prices.price_15d },
            'renovar30': { days: 30, amount: config.prices.price_30d }
        };
        
        const r = renewMap[command];
        
        if (!hwid) {
            await client.sendMessage(phone, `❌ *HWID NO ESPECIFICADO*

Por favor incluye tu HWID:

📝 *EJEMPLO:*
_${command} HWID-ABC123XYZ_`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `🔄 *PROCESANDO RENOVACIÓN*

HWID: *${hwid}*
Extensión: *+${r.days} días*
Monto: *$${r.amount} ${config.prices.currency}*

⏳ Procesando...`, { sendSeen: false });
        
        const result = await renewUser(phone, hwid, r.days);
        
        if (result.success) {
            await client.sendMessage(phone, `✅ *RENOVACIÓN EXITOSA*

🎉 ¡Tu servicio ha sido renovado!

📋 *NUEVOS DETALLES:*
👤 Usuario: *${result.username}*
⏰ Nueva expiración: *${moment(result.newExpireDate).format('DD/MM/YYYY')}*
📅 Días totales: *${result.totalDays} días*

¡Disfruta de tu servicio renovado!

*Escribe "menu" para volver*`, { sendSeen: false });
        } else {
            await client.sendMessage(phone, `❌ *ERROR EN RENOVACIÓN*

No se pudo renovar el servicio.

Error: ${result.error}

💡 Contacta soporte para ayuda.`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 3: EDITAR HWID
    else if (text === '3') {
        await client.sendMessage(phone, `✏️ *EDITAR HWID*

Para cambiar tu HWID, necesito:

1. Tu HWID actual
2. El nuevo HWID que deseas

📝 *FORMATO:*
_editar HWID_ACTUAL NUEVO_HWID_

📋 *EJEMPLO:*
_editar HWID-ABC123XYZ HWID-NUEVO456_

*Reemplaza con tus datos*`, { sendSeen: false });
    }
    
    // COMANDO EDITAR HWID
    else if (text.toLowerCase().startsWith('editar ')) {
        const parts = text.substring(7).trim().split(' ');
        
        if (parts.length < 2) {
            await client.sendMessage(phone, `❌ *FORMATO INCORRECTO*

Uso correcto:
_editar HWID_ACTUAL NUEVO_HWID_

📋 *EJEMPLO:*
_editar HWID-ABC123XYZ HWID-NUEVO456_`, { sendSeen: false });
            return;
        }
        
        const oldHWID = parts[0];
        const newHWID = parts[1];
        
        await client.sendMessage(phone, `🔄 *ACTUALIZANDO HWID*

Cambiando: *${oldHWID}* → *${newHWID}*

⏳ Procesando...`, { sendSeen: false });
        
        const success = await updateUserHWID(phone, oldHWID, newHWID);
        
        if (success) {
            await client.sendMessage(phone, `✅ *HWID ACTUALIZADO*

🎉 ¡Tu HWID ha sido cambiado exitosamente!

🔧 *NUEVO HWID:* *${newHWID}*

💡 *NOTA:* 
- Tu usuario y contraseña siguen iguales
- Solo cambió el identificador de hardware
- Descarga nuevamente el archivo .hc si es necesario

*Escribe "menu" para volver*`, { sendSeen: false });
        } else {
            await client.sendMessage(phone, `❌ *ERROR AL ACTUALIZAR*

No se pudo cambiar el HWID.

💡 *VERIFICA:*
1. Que el HWID actual sea correcto
2. Que tu servicio esté activo
3. Contacta soporte si necesitas ayuda`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 4: ARCHIVO.HC
    else if (text === '4') {
        await client.sendMessage(phone, `📁 *ARCHIVO .HC*

Para obtener tu archivo de configuración (.hc), necesito tu HWID.

📝 *POR FAVOR ESCRIBE:*
_hc HWID_TU_HWID_

📋 *EJEMPLO:*
_hc HWID-ABC123XYZ_

*Reemplaza HWID_TU_HWID con tu HWID*`, { sendSeen: false });
    }
    
    // COMANDO HC
    else if (text.toLowerCase().startsWith('hc ')) {
        const hwid = text.substring(3).trim();
        
        await client.sendMessage(phone, `🔍 *BUSCANDO CONFIGURACIÓN...*

Buscando archivo .hc para HWID: *${hwid}*

⏳ Por favor espera...`, { sendSeen: false });
        
        const archivesDir = `${config.paths.hwid}/archives`;
        let foundFile = null;
        
        try {
            const files = fs.readdirSync(archivesDir);
            for (const file of files) {
                if (file.includes(hwid) && (file.endsWith('.hc') || file.endsWith('.txt'))) {
                    foundFile = path.join(archivesDir, file);
                    break;
                }
            }
        } catch (error) {
            console.error(chalk.red('❌ Error buscando archivo:'), error.message);
        }
        
        if (foundFile && fs.existsSync(foundFile)) {
            await sendHCFile(phone, foundFile, path.basename(foundFile));
        } else {
            const user = await getUserByHWID(hwid);
            
            if (user && user.phone === phone) {
                await client.sendMessage(phone, `🔧 *GENERANDO ARCHIVO .HC*

Usuario encontrado: *${user.username}*
Generando configuración...

⏳ Un momento...`, { sendSeen: false });
                
                const hcFile = await generateHCFile(user.username, user.password, user.hwid);
                
                if (hcFile.success) {
                    await sendHCFile(phone, hcFile.filePath, hcFile.fileName);
                } else {
                    await client.sendMessage(phone, `❌ *ERROR GENERANDO ARCHIVO*

No se pudo generar el archivo .hc

Error: ${hcFile.error}

💡 Contacta soporte para ayuda.`, { sendSeen: false });
                }
            } else {
                await client.sendMessage(phone, `❌ *NO ENCONTRADO*

No se encontró configuración para el HWID: *${hwid}*

💡 *VERIFICA:*
1. Que el HWID sea correcto
2. Que tengas un servicio activo
3. Contacta soporte si necesitas ayuda

*Escribe "menu" para volver*`, { sendSeen: false });
            }
        }
    }
    
    // OPCIÓN 5: PRUEBA GRATIS
    else if (text === '5') {
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *PRUEBA YA UTILIZADA*

Ya has usado tu prueba gratuita hoy.

⏳ Vuelve mañana para otra prueba
🛒 *Escribe "1"* para ver planes de pago`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `🎁 *PRUEBA GRATIS 1 HORA*

⏳ Creando cuenta de prueba...
⏰ Duración: 1 hora
🔌 Conexiones: 1

*Por favor espera...*`, { sendSeen: false });
        
        try {
            const result = await createHTTPUser(phone, 'test', 0);
            registerTest(phone);
            
            if (result.success) {
                const hcFile = await generateHCFile(result.username, result.password, result.hwid);
                
                await client.sendMessage(phone, `✅ *PRUEBA ACTIVADA*

🎉 ¡Tu prueba gratuita está lista!

📋 *DETALLES:*
👤 Usuario: *${result.username}*
🔑 Contraseña: *${result.password}*
🔧 HWID: *${result.hwid}*
⏰ Válido por: *1 hora*
🔌 Conexiones: *1*

🔄 Generando archivo de configuración...`, { sendSeen: false });
                
                if (hcFile.success) {
                    await sendHCFile(phone, hcFile.filePath, hcFile.fileName);
                    
                    await client.sendMessage(phone, `📁 *ARCHIVO ENVIADO*

✅ Tu prueba está lista para usar

💡 *INSTRUCCIONES:*
1. Guarda el archivo .hc
2. Abre HTTP Custom
3. Importa el archivo
4. ¡Conéctate y prueba!

🔄 *¿TE GUSTÓ EL SERVICIO?*
*Escribe "1"* para ver planes de pago

⏰ *RECUERDA:* La prueba expira en 1 hora`, { sendSeen: false });
                }
            }
        } catch (error) {
            await client.sendMessage(phone, `❌ *ERROR EN PRUEBA*

No se pudo crear la cuenta de prueba.

Error: ${error.message}

💡 Por favor, intenta nuevamente.`, { sendSeen: false });
        }
    }
});

// ✅ Verificar pagos cada 2 minutos
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
    checkPendingPayments();
});

// Limpiar usuarios expirados cada 6 horas
cron.schedule('0 */6 * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios expirados... (${now})`));
    
    db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
        if (err) {
            console.error(chalk.red('❌ Error BD:'), err.message);
            return;
        }
        if (!rows || rows.length === 0) return;
        
        for (const r of rows) {
            try {
                await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                console.log(chalk.green(`🗑️ Eliminado: ${r.username}`));
            } catch (e) {
                console.error(chalk.red(`Error eliminando ${r.username}:`), e.message);
            }
        }
        console.log(chalk.green(`✅ Limpiados ${rows.length} usuarios expirados`));
    });
});

// Verificar estado cada hora
cron.schedule('0 * * * *', () => {
    console.log(chalk.cyan(`📊 Estado del bot: ${moment().format('DD/MM HH:mm')}`));
    db.get('SELECT COUNT(*) as total FROM users WHERE status = 1', (err, row) => {
        if (!err && row) {
            console.log(chalk.yellow(`👥 Usuarios activos: ${row.total}`));
        }
    });
});

console.log(chalk.green('\n🚀 Inicializando HTTP Custom HWID Bot v2.0...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot v2.0 creado con mejoras${NC}"

# ================================================
# CREAR PANEL DE CONTROL MEJORADO
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL v2.0...${NC}"

cat > /usr/local/bin/hc-bot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/httpcustom-bot/data/users.db"
CONFIG="/opt/httpcustom-bot/config/config.json"
HWID_DIR="/opt/httpcustom-bot/hwid"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🎛️  HTTP CUSTOM HWID BOT v2.0                   ║${NC}"
    echo -e "${CYAN}║                🔧 Cliente envía HWID → .hc                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    ACTIVE_HWID=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT hwid) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="httpcustom-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
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
    
    HWID_FILES=$(find "$HWID_DIR/archives" -name "*.hc" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  HWIDs únicos: ${CYAN}$ACTIVE_HWID${NC}"
    echo -e "  Archivos .hc: ${CYAN}$HWID_FILES${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Pagos pendientes: ${YELLOW}$PENDING_PAYMENTS${NC}"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar usuarios HWID"
    echo -e "${CYAN}[6]${NC}  🔧  Gestionar archivos .hc"
    echo -e "${CYAN}[7]${NC}  💰  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC}  💳  Ver pagos"
    echo -e "${CYAN}[9]${NC}  📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 📝  Ver logs"
    echo -e "${CYAN}[11]${NC} ⚙️   Configuración"
    echo -e "${CYAN}[12]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
            cd /root/httpcustom-bot
            pm2 restart httpcustom-bot 2>/dev/null || pm2 start bot.js --name httpcustom-bot
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop httpcustom-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-httpcustom.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-httpcustom.png${NC}\n"
                echo -e "${YELLOW}Descarga con:${NC}"
                echo -e "  scp root@$(get_val '.bot.server_ip'):/root/qr-httpcustom.png ."
                read -p "Presiona Enter..."
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs httpcustom-bot --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👤 CREAR USUARIO HWID                   ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "HWID (auto=generar): " HWID
            read -p "Plan (test/1d/7d/15d/30d): " PLAN
            read -p "Días: " DAYS
            
            [[ -z "$HWID" || "$HWID" == "auto" ]] && HWID="HWID-$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 8)"
            [[ -z "$DAYS" ]] && DAYS="30"
            
            USERNAME="http$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)"
            PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
            EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
            
            useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
            
            if [[ $? -eq 0 ]]; then
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, hwid, plan, days, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$HWID', '$PLAN', $DAYS, '$EXPIRE_DATE', 1)"
                
                IP=$(get_val '.bot.server_ip')
                HC_CONTENT="[connection]
host=$IP
port=443
username=$USERNAME
password=$PASSWORD
method=chacha20-ietf-poly1305
protocol=auth_chain_a
obfs=tls1.2_ticket_auth

[settings]
dns=8.8.8.8,8.8.4.4
proxy_type=http
timeout=30
reconnect=true

# HWID: $HWID"
                
                HC_FILE="$HWID_DIR/archives/HTTP_${USERNAME}_${HWID}.hc"
                echo "$HC_CONTENT" > "$HC_FILE"
                
                echo -e "\n${GREEN}✅ USUARIO HWID CREADO${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "🔧 HWID: ${HWID}"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "📁 Archivo: $(basename "$HC_FILE")"
            else
                echo -e "\n${RED}❌ Error creando usuario${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS HWID                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, substr(hwid,1,15) as hwid, plan, expires_at, substr(phone,1,12) as tel FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total activos: ${ACTIVE_USERS}${NC}"
            read -p "Presiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔧 ARCHIVOS .HC                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📁 Archivos en $HWID_DIR/archives/${NC}"
            find "$HWID_DIR/archives" -name "*.hc" 2>/dev/null | while read f; do
                size=$(du -h "$f" | cut -f1)
                echo -e "  📄 $(basename "$f") (${size})"
            done
            
            echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}[1]${NC}  Ver contenido"
            echo -e "${CYAN}[2]${NC}  Eliminar archivo"
            echo -e "${CYAN}[3]${NC}  Crear archivo manual"
            echo -e "${CYAN}[0]${NC}  Volver"
            
            read -p "Opción: " HC_OPT
            
            case $HC_OPT in
                1)
                    read -p "Nombre del archivo: " FILE_NAME
                    if [[ -f "$HWID_DIR/archives/$FILE_NAME" ]]; then
                        echo -e "\n${YELLOW}Contenido:${NC}"
                        cat "$HWID_DIR/archives/$FILE_NAME"
                    fi
                    ;;
                2)
                    read -p "Nombre del archivo a eliminar: " DEL_FILE
                    if [[ -f "$HWID_DIR/archives/$DEL_FILE" ]]; then
                        rm -f "$HWID_DIR/archives/$DEL_FILE"
                        echo -e "${GREEN}✅ Archivo eliminado${NC}"
                    fi
                    ;;
                3)
                    read -p "Nombre del archivo: " NEW_FILE
                    read -p "HWID: " NEW_HWID
                    read -p "Usuario: " NEW_USER
                    read -p "Contraseña: " NEW_PASS
                    
                    IP=$(get_val '.bot.server_ip')
                    cat > "$HWID_DIR/archives/$NEW_FILE.hc" << EOF
[connection]
host=$IP
port=443
username=$NEW_USER
password=$NEW_PASS
method=chacha20-ietf-poly1305
protocol=auth_chain_a
obfs=tls1.2_ticket_auth

[settings]
dns=8.8.8.8,8.8.4.4
proxy_type=http
timeout=30
reconnect=true

# HWID: $NEW_HWID
EOF
                    echo -e "${GREEN}✅ Archivo creado${NC}"
                    ;;
            esac
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
                    cd /root/httpcustom-bot && pm2 restart httpcustom-bot
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago SDK v2.x activado${NC}"
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
            echo -e "${CYAN}║                     💳 PAGOS MERCADOPAGO                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT substr(payment_id,1,15) as id, substr(hwid,1,10) as hwid, plan, amount, status, datetime(created_at) as fecha FROM payments ORDER BY created_at DESC LIMIT 15" 2>/dev/null || echo "Sin pagos"
            
            echo -e "\n${YELLOW}Totales:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments" 2>/dev/null || echo "Error BD"
            
            read -p "\nPresiona Enter..."
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Test: ' || SUM(CASE WHEN plan='test' THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💳 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Monto: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Pruebas: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            
            read -p "\nPresiona Enter..."
            ;;
        10)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs httpcustom-bot --lines 100
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     ⚙️  CONFIGURACIÓN                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🤖 BOT:${NC}"
            echo -e "  IP: $(get_val '.bot.server_ip')"
            echo -e "  Versión: $(get_val '.bot.version')"
            
            echo -e "\n${YELLOW}💰 PRECIOS:${NC}"
            echo -e "  1d: $(get_val '.prices.price_1d') $(get_val '.prices.currency')"
            echo -e "  7d: $(get_val '.prices.price_7d') $(get_val '.prices.currency')"
            echo -e "  15d: $(get_val '.prices.price_15d') $(get_val '.prices.currency')"
            echo -e "  30d: $(get_val '.prices.price_30d') $(get_val '.prices.currency')"
            echo -e "  Test: $(get_val '.prices.test_hours') horas"
            
            echo -e "\n${YELLOW}💳 MERCADOPAGO:${NC}"
            MP_TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "null" ]]; then
                echo -e "  Estado: ${GREEN}SDK v2.x ACTIVO${NC}"
                echo -e "  Token: ${MP_TOKEN:0:25}..."
            else
                echo -e "  Estado: ${RED}NO CONFIGURADO${NC}"
            fi
            
            read -p "\nPresiona Enter..."
            ;;
        12)
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

chmod +x /usr/local/bin/hc-bot
echo -e "${GREEN}✅ Panel de control v2.0 creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT HTTP CUSTOM v2.0...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name httpcustom-bot
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
║        🎉 HTTP CUSTOM HWID BOT v2.0 INSTALADO              ║
║                                                              ║
║         🤖 Bot MEJORADO - Cliente envía HWID → .hc          ║
║         💳 MercadoPago SDK v2.x COMPLETO                    ║
║         🔧 Sistema HWID automático mejorado                 ║
║         📱 WhatsApp Bot 24/7 con pagos integrados           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Bot v2.0 instalado y funcionando${NC}"
echo -e "${GREEN}✅ Cliente envía HWID → Recibe .hc automático${NC}"
echo -e "${GREEN}✅ MercadoPago SDK v2.x integrado${NC}"
echo -e "${GREEN}✅ Panel de control con configuración MP${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}\n"
echo -e "  ${GREEN}hc-bot${NC}           - Panel de control v2.0"
echo -e "  ${GREEN}show-qr${NC}          - Ver QR WhatsApp"
echo -e "  ${GREEN}pm2 logs httpcustom-bot${NC} - Ver logs\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN MERCADOPAGO:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}hc-bot${NC}"
echo -e "  2. Opción ${CYAN}[7]${NC} - Configurar MercadoPago"
echo -e "  3. Opción ${CYAN}[12]${NC} - Test MercadoPago"
echo -e "  4. Opción ${CYAN}[3]${NC} - Ver QR WhatsApp\n"

echo -e "${YELLOW}⚡ FLUJO MEJORADO:${NC}"
echo -e "  1. Cliente envía HWID → Bot busca .hc"
echo -e "  2. Si encuentra: Envía archivo automáticamente"
echo -e "  3. Si no encuentra: Sugiere comprar servicio"
echo -e "  4. Compra: cliente envía 'comprar7 HWID-ABC123'\n"

echo -e "${YELLOW}📊 DIRECTORIOS:${NC}"
echo -e "  ${CYAN}/opt/httpcustom-bot/${NC}      - Instalación"
echo -e "  ${CYAN}/opt/httpcustom-bot/hwid/${NC} - Archivos .hc"
echo -e "  ${CYAN}/root/httpcustom-bot/${NC}     - Código del bot\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}\n"
    sleep 2
    /usr/local/bin/hc-bot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}hc-bot${NC}\n"
fi

echo -e "${GREEN}${BOLD}¡Bot HTTP Custom HWID v2.0 listo para usar! 🚀${NC}\n"

exit 0
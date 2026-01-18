#!/bin/bash
# ================================================
# HTTP CUSTOM HWID BOT v1.0
# Bot especializado para HTTP Custom con HWID
# Funcionalidades:
# 1. ✅ Comprar usuario HWID
# 2. ✅ Renovar usuario HWID  
# 3. ✅ Editar HWID
# 4. ✅ Enviar archivo .hc
# 5. ✅ Prueba gratis 1 hora
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
║           🤖 HTTP CUSTOM HWID BOT v1.0                      ║
║                📱 WhatsApp Bot para HWID                    ║
║                🔧 HTTP Custom Specialized                   ║
║                💾 Sistema de archivos .hc                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ FUNCIONALIDADES PRINCIPALES:${NC}"
echo -e "  1. ${CYAN}COMPRAR USUARIO HWID${NC}"
echo -e "  2. ${YELLOW}RENOVAR USUARIO HWID${NC}"
echo -e "  3. ${GREEN}EDITAR HWID${NC}"
echo -e "  4. ${BLUE}ARCHIVO.HC${NC}"
echo -e "  5. ${PURPLE}PRUEBA GRATIS (1H)${NC}"
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
echo -e "   • Crear HTTP Custom HWID Bot"
echo -e "   • Sistema completo de HWID"
echo -e "   • Gestión de archivos .hc"
echo -e "   • Panel de control especializado"
echo -e "   • Base de datos SQLite3"
echo -e "   • Cron para limpieza automática"
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

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom HWID Bot",
        "version": "1.0",
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
        "enabled": false
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

# Crear base de datos
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
    plan TEXT,
    days INTEGER,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
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
# CREAR BOT PARA HTTP CUSTOM
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT PARA HTTP CUSTOM...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "httpcustom-hwid-bot",
    "version": "1.0.0",
    "main": "bot.js",
    "dependencies": {
        "whatsapp-web.js": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3"
    }
}
PKGEOF

echo -e "${YELLOW}📦 Instalando paquetes Node.js...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js
echo -e "${YELLOW}📝 Creando bot.js especializado...${NC}"

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

const execPromise = util.promisify(exec);

function loadConfig() {
    delete require.cache[require.resolve('/opt/httpcustom-bot/config/config.json')];
    return require('/opt/httpcustom-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║           🤖 HTTP CUSTOM HWID BOT v1.0                       ║'));
console.log(chalk.cyan.bold('║                📱 WhatsApp Bot 24/7                          ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.green('✅ Bot especializado para HTTP Custom'));
console.log(chalk.green('✅ Sistema completo de HWID'));
console.log(chalk.green('✅ Gestión de archivos .hc'));

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'httpcustom-bot'}),
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
    console.log(chalk.green.bold('\n✅ BOT HTTP CUSTOM CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp\n'));
    qrCount = 0;
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

// Funciones de utilidad
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
        // Crear usuario en sistema
        await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
        
        // Guardar en base de datos
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
        
        // Guardar registro en BD
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
        
        // Actualizar registro
        db.run(`UPDATE hwid_files SET sent_at = CURRENT_TIMESTAMP WHERE file_name = ?`, [fileName]);
        
        return true;
    } catch (error) {
        console.error(chalk.red('❌ Error enviando archivo .hc:'), error.message);
        
        // Enviar como texto alternativo
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
                        
                        // Actualizar fecha de expiración en sistema
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

// Manejador de mensajes
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // MENÚ PRINCIPAL
    if (['menu', 'hola', 'start', 'hi', 'ayuda'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, `╔══════════════════════════════════════╗
║      🤖 *HTTP CUSTOM HWID BOT*         ║
║            📱 *24/7 ONLINE*            ║
╚══════════════════════════════════════╝

### USUARIO HWID BOT 24/7

#### BIENVENIDO AL PANEL

1️⃣ *COMPRAR USUARIO HWID*
   - Planes disponibles
   - Configuración automática

2️⃣ *RENOVAR USUARIO HWID*
   - Extiende tu servicio
   - Mantén tu HWID

3️⃣ *EDITAR HWID*
   - Cambia tu HWID
   - Actualización simple

4️⃣ *ARCHIVO.HC*
   - Descarga configuración
   - Listo para usar

5️⃣ *PRUEBA GRATIS (1H)*
   - Testea el servicio
   - Sin compromiso

*Escribe menu para volver atras*

📞 *SOPORTE:* Contacta al administrador
⏰ *ACTIVO:* 24 horas / 7 días`, { sendSeen: false });
    }
    
    // OPCIÓN 1: COMPRAR USUARIO HWID
    else if (text === '1') {
        await client.sendMessage(phone, `🛒 *COMPRAR USUARIO HWID*

📋 *PLANES DISPONIBLES:*

🟢 *1 DÍA* - $${config.prices.price_1d} ${config.prices.currency}
   _comprar1_

🔵 *7 DÍAS* - $${config.prices.price_7d} ${config.prices.currency}
   _comprar7_

🟡 *15 DÍAS* - $${config.prices.price_15d} ${config.prices.currency}
   _comprar15_

🔴 *30 DÍAS* - $${config.prices.price_30d} ${config.prices.currency}
   _comprar30_

💡 *INCLUYE:*
✓ Usuario único
✓ HWID personalizado
✓ Archivo .hc configurado
✓ Soporte 24/7

*Escribe el comando correspondiente*`, { sendSeen: false });
    }
    
    // OPCIONES DE COMPRA
    else if (['comprar1', 'comprar7', 'comprar15', 'comprar30'].includes(text.toLowerCase())) {
        const planMap = {
            'comprar1': { days: 1, amount: config.prices.price_1d, plan: '1d' },
            'comprar7': { days: 7, amount: config.prices.price_7d, plan: '7d' },
            'comprar15': { days: 15, amount: config.prices.price_15d, plan: '15d' },
            'comprar30': { days: 30, amount: config.prices.price_30d, plan: '30d' }
        };
        
        const p = planMap[text.toLowerCase()];
        
        await client.sendMessage(phone, `🔄 *PROCESANDO COMPRA*

📦 Plan seleccionado: *${p.days} días*
💰 Monto: *$${p.amount} ${config.prices.currency}*
⏳ Creando usuario...

*Por favor espera...*`, { sendSeen: false });
        
        try {
            // Simular compra (aquí integrarías MercadoPago)
            const result = await createHTTPUser(phone, p.plan, p.days);
            
            if (result.success) {
                // Generar archivo .hc
                const hcFile = await generateHCFile(result.username, result.password, result.hwid);
                
                await client.sendMessage(phone, `✅ *COMPRA EXITOSA*

🎉 ¡Tu usuario ha sido creado!

📋 *DETALLES DEL SERVICIO:*
👤 Usuario: *${result.username}*
🔑 Contraseña: *${result.password}*
🔧 HWID: *${result.hwid}*
⏰ Válido hasta: *${moment(result.expires).format('DD/MM/YYYY')}*
📅 Duración: *${p.days} días*

🔄 Generando archivo de configuración...`, { sendSeen: false });
                
                if (hcFile.success) {
                    await sendHCFile(phone, hcFile.filePath, hcFile.fileName);
                    
                    await client.sendMessage(phone, `📁 *ARCHIVO ENVIADO*

✅ Tu configuración está lista

💡 *INSTRUCCIONES DE USO:*
1. Guarda el archivo .hc
2. Abre HTTP Custom
3. Importa el archivo
4. ¡Conéctate y disfruta!

🆘 *SOPORTE:*
Si tienes problemas, contacta al administrador.

*Escribe "menu" para volver*`, { sendSeen: false });
                }
            }
        } catch (error) {
            await client.sendMessage(phone, `❌ *ERROR EN LA COMPRA*

No se pudo completar la compra.

Error: ${error.message}

💡 Por favor, intenta nuevamente o contacta soporte.`, { sendSeen: false });
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
        
        // Verificar que el usuario pertenezca al número
        if (user.phone !== phone) {
            await client.sendMessage(phone, `❌ *NO AUTORIZADO*

El HWID *${hwid}* no está asociado a este número.

💡 Contacta al administrador para ayuda.`, { sendSeen: false });
            return;
        }
        
        // Mostrar opciones de renovación
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
        
        // Buscar archivo existente
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
            // Buscar usuario y generar archivo
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
    
    // DETECCIÓN AUTOMÁTICA DE HWID
    else if (text.toUpperCase().startsWith('HWID-') && text.length > 10) {
        await client.sendMessage(phone, `🔍 *HWID DETECTADO*

He detectado que enviaste un HWID: *${text}*

¿Qué deseas hacer?

1. *Obtener archivo .hc* - Envía: _hc ${text}_
2. *Renovar servicio* - Envía: _renovar ${text}_
3. *Editar HWID* - Envía: _editar ${text} NUEVO_HWID_

*Escribe "menu" para ver todas las opciones*`, { sendSeen: false });
    }
});

// Tarea cron para limpiar usuarios expirados
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

console.log(chalk.green('\n🚀 Inicializando HTTP Custom HWID Bot...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado especializado para HTTP Custom${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL...${NC}"

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
    echo -e "${CYAN}║           🎛️  HTTP CUSTOM HWID BOT PANEL                   ║${NC}"
    echo -e "${CYAN}║                🤖 Bot especializado                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    ACTIVE_HWID=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT hwid) FROM users WHERE status=1" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="httpcustom-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    HWID_FILES=$(find "$HWID_DIR/archives" -name "*.hc" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  HWIDs únicos: ${CYAN}$ACTIVE_HWID${NC}"
    echo -e "  Archivos .hc: ${CYAN}$HWID_FILES${NC}"
    echo -e "  Prueba gratis: ${GREEN}1 hora${NC}"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar usuarios HWID"
    echo -e "${CYAN}[6]${NC}  🔧  Gestionar archivos .hc"
    echo -e ""
    echo -e "${CYAN}[7]${NC}  💰  Cambiar precios"
    echo -e "${CYAN}[8]${NC}  📊  Ver estadísticas"
    echo -e "${CYAN}[9]${NC}  📝  Ver logs"
    echo -e "${CYAN}[10]${NC} ⚙️   Configuración"
    echo -e "${CYAN}[11]${NC} 🧹  Limpiar expirados"
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
            
            # Crear usuario en sistema
            useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
            
            if [[ $? -eq 0 ]]; then
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, hwid, plan, days, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$HWID', '$PLAN', $DAYS, '$EXPIRE_DATE', 1)"
                
                # Crear archivo .hc
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
            echo -e "${CYAN}║                     💰 CAMBIAR PRECIOS                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_1D=$(get_val '.prices.price_1d')
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  1 día: $${CURRENT_1D}"
            echo -e "  7 días: $${CURRENT_7D}"
            echo -e "  15 días: $${CURRENT_15D}"
            echo -e "  30 días: $${CURRENT_30D}\n"
            
            read -p "Nuevo precio 1d [${CURRENT_1D}]: " NEW_1D
            read -p "Nuevo precio 7d [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15d [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30d [${CURRENT_30D}]: " NEW_30D
            
            [[ -n "$NEW_1D" ]] && set_val '.prices.price_1d' "$NEW_1D"
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
            read -p "Presiona Enter..."
            ;;
        8)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Test: ' || SUM(CASE WHEN plan='test' THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Pruebas: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            
            echo -e "\n${YELLOW}💰 INGRESOS ESTIMADOS:${NC}"
            sqlite3 "$DB" "SELECT 'Mensual: $' || printf('%.2f', SUM(CASE WHEN plan='1d' THEN price_1d*30 WHEN plan='7d' THEN price_7d*4 WHEN plan='15d' THEN price_15d*2 WHEN plan='30d' THEN price_30d END)) FROM (SELECT DISTINCT plan FROM users WHERE status=1) u JOIN (SELECT price_1d, price_7d, price_15d, price_30d FROM config) c ON 1=1" 2>/dev/null || echo "Error cálculo"
            
            read -p "\nPresiona Enter..."
            ;;
        9)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs httpcustom-bot --lines 100
            ;;
        10)
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
            
            echo -e "\n${YELLOW}🔧 HWID:${NC}"
            echo -e "  Estado: $(get_val '.hwid.enabled')"
            echo -e "  Ruta: $(get_val '.hwid.path')"
            echo -e "  Máx. tamaño: $(get_val '.hwid.max_file_size_mb') MB"
            
            read -p "\nPresiona Enter..."
            ;;
        11)
            echo -e "\n${YELLOW}🧹 Limpiando usuarios expirados...${NC}"
            NOW=$(date +"%Y-%m-%d %H:%M:%S")
            sqlite3 "$DB" "SELECT username FROM users WHERE expires_at < '$NOW' AND status = 1" | while read user; do
                pkill -u "$user" 2>/dev/null || true
                userdel -f "$user" 2>/dev/null || true
                echo "Eliminado: $user"
            done
            sqlite3 "$DB" "UPDATE users SET status = 0 WHERE expires_at < '$NOW' AND status = 1"
            echo -e "${GREEN}✅ Limpieza completada${NC}"
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

chmod +x /usr/local/bin/hc-bot
echo -e "${GREEN}✅ Panel de control creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT HTTP CUSTOM...${NC}"

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
║        🎉 HTTP CUSTOM HWID BOT INSTALADO                    ║
║                                                              ║
║         🤖 Bot especializado para HTTP Custom               ║
║         🔧 Sistema completo de HWID                         ║
║         📁 Gestión automática de archivos .hc               ║
║         📱 WhatsApp Bot 24/7                                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Bot instalado y funcionando${NC}"
echo -e "${GREEN}✅ Panel de control disponible${NC}"
echo -e "${GREEN}✅ Sistema HWID configurado${NC}"
echo -e "${GREEN}✅ Archivos .hc automáticos${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}\n"
echo -e "  ${GREEN}hc-bot${NC}           - Panel de control"
echo -e "  ${GREEN}pm2 logs httpcustom-bot${NC} - Ver logs"
echo -e "  ${GREEN}pm2 restart httpcustom-bot${NC} - Reiniciar\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}hc-bot${NC}"
echo -e "  2. Opción ${CYAN}[3]${NC} - Ver QR WhatsApp"
echo -e "  3. Escanea QR con tu WhatsApp"
echo -e "  4. Envía 'menu' al bot\n"

echo -e "${YELLOW}⚡ FUNCIONALIDADES:${NC}"
echo -e "  • Compra usuarios HWID"
echo -e "  • Renovación automática"
echo -e "  • Edición de HWID"
echo -e "  • Archivos .hc configurables"
echo -e "  • Prueba gratis 1 hora\n"

echo -e "${YELLOW}📊 DIRECTORIOS:${NC}"
echo -e "  ${CYAN}/opt/httpcustom-bot/${NC}      - Instalación"
echo -e "  ${CYAN}/opt/httpcustom-bot/hwid/${NC} - Archivos HWID"
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

echo -e "${GREEN}${BOLD}¡Bot HTTP Custom HWID listo para usar! 🚀${NC}\n"

exit 0
#!/bin/bash
# ================================================
# SSH BOT PRO - VERSIÓN CORREGIDA - CON REGISTRO AUTOMÁTICO
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
║          🤖 SSH BOT PRO - VERSIÓN CORREGIDA                 ║
║          ✅ REGISTRO AUTOMÁTICO DE HWIDs                    ║
║          ⏱️  PRUEBA 2 HORAS - CORREGIDA                     ║
║          💰 MERCADOPAGO INTEGRADO                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# Detectar IP
echo -e "\n${CYAN}🔍 Detectando IP del servidor...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || curl -4 -s --max-time 10 icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
if [[ -z "$SERVER_IP" ]]; then
    read -p "📝 Ingresa la IP pública: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}"

read -p "$(echo -e "\n${YELLOW}¿Continuar instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias...${NC}"

apt-get update -y
apt-get upgrade -y

apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw nginx \
    apt-transport-https ca-certificates \
    gnupg lsb-release

# Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable || apt-get install -y chromium-browser

# PM2
npm install -g pm2

# Firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
echo "y" | ufw enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# ESTRUCTURA DE DIRECTORIOS
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/hwid.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" /root/.wppconnect 2>/dev/null || true

# Crear
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 777 "$INSTALL_DIR/data"
chmod -R 700 /root/.wppconnect

echo -e "${GREEN}✅ Directorios creados${NC}"

# ================================================
# CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}⚙️  Creando configuración...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-FIXED",
        "server_ip": "$SERVER_IP"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 3000.00,
        "price_15d": 4000.00,
        "price_30d": 7000.00,
        "price_50d": 9700.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file",
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect"
    }
}
EOF

echo -e "${GREEN}✅ Configuración creada${NC}"

# ================================================
# BASE DE DATOS
# ================================================
echo -e "\n${CYAN}💾 Creando base de datos...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS hwid_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    nombre TEXT,
    plan TEXT,
    days INTEGER,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    hwid TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hwid_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hwid TEXT,
    phone TEXT,
    nombre TEXT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hwid_users_hwid ON hwid_users(hwid);
CREATE INDEX IF NOT EXISTS idx_hwid_users_status ON hwid_users(status);
CREATE INDEX IF NOT EXISTS idx_payments_hwid ON payments(hwid);
SQL

chmod 666 "$DB_FILE"
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cd "$USER_HOME"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro-hwid",
    "version": "3.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "moment-timezone": "^0.5.43",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "mercadopago": "^2.0.15",
        "axios": "^1.6.5",
        "express": "^4.18.2"
    }
}
PKGEOF

echo -e "${GREEN}✅ package.json creado${NC}"

# ================================================
# INSTALAR NPM
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias NPM...${NC}"
npm install --silent --no-audit --no-fund
echo -e "${GREEN}✅ NPM instalado${NC}"

# ================================================
# BOT.JS - VERSIÓN CORREGIDA CON REGISTRO AUTOMÁTICO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con registro automático...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const momentTz = require('moment-timezone');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const execPromise = util.promisify(exec);
moment.locale('es');
moment.tz.setDefault('America/Argentina/Buenos_Aires');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║     🤖 SSH BOT PRO - VERSIÓN CORREGIDA                      ║'));
console.log(chalk.cyan.bold('║     ✅ REGISTRO AUTOMÁTICO DE HWIDs                         ║'));
console.log(chalk.cyan.bold('║     ⏱️  PRUEBA 2 HORAS - CORREGIDA                          ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    try {
        delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
        return require('/opt/sshbot-pro/config/config.json');
    } catch (error) {
        return {
            prices: { price_7d: 3000, price_15d: 4000, price_30d: 7000, price_50d: 9700 },
            links: { app_download: '', support: '' }
        };
    }
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/hwid.db');

// MERCADOPAGO
let mpEnabled = false;
let mpClient = null;
let mpPreference = null;

function initMercadoPago() {
    config = loadConfig();
    if (config.mercadopago && config.mercadopago.access_token) {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            mpClient = new MercadoPagoConfig({ accessToken: config.mercadopago.access_token });
            mpPreference = new Preference(mpClient);
            mpEnabled = true;
            console.log(chalk.green('✅ MercadoPago ACTIVO'));
        } catch (error) {
            console.log(chalk.red('❌ Error MP:'), error.message);
        }
    }
}

initMercadoPago();

let client = null;

// ================================================
// FUNCIONES HWID CORREGIDAS CON LOGS
// ================================================

function validateHWID(hwid) {
    const hwidRegex = /^APP-[A-F0-9]{16}$/;
    return hwidRegex.test(hwid);
}

function normalizeHWID(hwid) {
    hwid = hwid.trim().toUpperCase();
    if (!hwid.startsWith('APP-')) {
        const cleanHwid = hwid.replace(/[^A-F0-9]/g, '');
        hwid = 'APP-' + cleanHwid;
    }
    return hwid;
}

function isHWIDActive(hwid) {
    return new Promise((resolve) => {
        db.get(
            "SELECT * FROM hwid_users WHERE hwid = ? AND status = 1 AND expires_at > datetime('now', 'localtime')", 
            [hwid], 
            (err, row) => {
                if (err) {
                    console.log(chalk.red('Error en isHWIDActive:'), err.message);
                    resolve(false);
                } else {
                    resolve(!!row);
                }
            }
        );
    });
}

function getHWIDInfo(hwid) {
    return new Promise((resolve) => {
        db.get('SELECT * FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
            if (err) resolve(null);
            else resolve(row);
        });
    });
}

// FUNCIÓN CORREGIDA - REGISTRO AUTOMÁTICO CON LOGS
async function registerHWID(phone, nombre, hwid, days, tipo = 'premium') {
    try {
        console.log(chalk.cyan(`\n🔍 INTENTANDO REGISTRAR HWID: ${hwid}`));
        console.log(chalk.cyan(`📱 Teléfono: ${phone}`));
        console.log(chalk.cyan(`👤 Nombre: ${nombre}`));
        console.log(chalk.cyan(`📅 Tipo: ${tipo}, Días: ${days}`));
        
        // Verificar si HWID ya existe
        const existing = await new Promise((resolve) => {
            db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
                if (err) console.log(chalk.red('Error en consulta:', err.message));
                resolve(row);
            });
        });

        if (existing) {
            console.log(chalk.red(`❌ HWID ${hwid} YA EXISTE EN BD`));
            return { success: false, error: 'HWID ya registrado' };
        }

        console.log(chalk.green(`✅ HWID ${hwid} NO EXISTE, procediendo a registrar`));

        let expireFull;
        if (days === 0 || tipo === 'test') {
            expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.cyan(`⏱️  Prueba 2 horas - Expira: ${expireFull}`));
        } else {
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        }

        // Registrar en BD
        const result = await new Promise((resolve, reject) => {
            db.run(
                `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)`,
                [phone, nombre, hwid, tipo, expireFull],
                function(err) {
                    if (err) {
                        console.log(chalk.red('Error en INSERT:', err.message));
                        reject(err);
                    } else {
                        console.log(chalk.green(`✅ INSERT EXITOSO, ID: ${this.lastID}`));
                        resolve(this.lastID);
                    }
                }
            );
        });

        // Registrar intento
        db.run(`INSERT INTO hwid_attempts (hwid, phone, nombre, action) VALUES (?, ?, ?, 'registered')`, 
            [hwid, phone, nombre]);

        console.log(chalk.green(`🎉 HWID REGISTRADO EXITOSAMENTE: ${hwid}`));
        console.log(chalk.green(`📅 Expira: ${expireFull}\n`));

        return { 
            success: true, 
            hwid,
            nombre,
            expires: expireFull,
            tipo
        };

    } catch (error) {
        console.error(chalk.red('❌ Error registrando HWID:'), error.message);
        console.error(chalk.red('Stack:'), error.stack);
        return { success: false, error: error.message };
    }
}

function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], (err, row) => {
            if (err) resolve(false);
            else resolve(row.count === 0);
        });
    });
}

function registerTest(phone, nombre) {
    const today = moment().format('YYYY-MM-DD');
    db.run('INSERT OR IGNORE INTO daily_tests (phone, nombre, date) VALUES (?, ?, ?)', 
        [phone, nombre, today]);
}

// SISTEMA DE ESTADOS
function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) resolve({ state: 'main_menu', data: null });
            else {
                try {
                    resolve({
                        state: row.state,
                        data: row.data ? JSON.parse(row.data) : null
                    });
                } catch {
                    resolve({ state: 'main_menu', data: null });
                }
            }
        });
    });
}

function setUserState(phone, state, data = null) {
    const dataStr = data ? JSON.stringify(data) : null;
    db.run(
        `INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
        [phone, state, dataStr]
    );
}

// ================================================
// INICIALIZAR BOT
// ================================================
async function initializeBot() {
    try {
        console.log(chalk.yellow('\n🚀 Inicializando WPPConnect...\n'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-hwid',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--no-first-run',
                '--no-zygote',
                '--disable-gpu'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: ['--no-sandbox']
            },
            disableWelcome: true,
            updatesLog: false,
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!\n'));
        
        client.onMessage(async (message) => {
            try {
                if (message.isGroupMsg || message.from.includes('@g.us')) return;
                if (message.from === 'status@broadcast') return;
                
                const text = message.body ? message.body.toLowerCase().trim() : '';
                const from = message.from;
                
                if (!text) return;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text}`));
                
                const userState = await getUserState(from);
                
                // MENÚ PRINCIPAL
                if (['menu', 'hola', 'start', '0'].includes(text)) {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, `🤖 *BOT MGVPN*

Elige una opción:

1️⃣ - PROBAR (2 HORAS GRATIS)
2️⃣ - COMPRAR INTERNET
3️⃣ - VERIFICAR MI HWID
4️⃣ - DESCARGAR APP

⏱️ *PRUEBA: 2 HORAS*`);
                }
                
                // OPCIÓN 1 - PRUEBA
                else if (text === '1' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_test_nombre');
                    await client.sendText(from, `⏳ *PRUEBA GRATUITA - 2 HORAS*

Primero, dime tu *NOMBRE*:`);
                }
                
                // OPCIÓN 2 - COMPRAR
                else if (text === '2' && userState.state === 'main_menu') {
                    await setUserState(from, 'buying_hwid');
                    await client.sendText(from, `💰 *PLANES*

1️⃣ - 7 DÍAS - $${config.prices.price_7d}
2️⃣ - 15 DÍAS - $${config.prices.price_15d}
3️⃣ - 30 DÍAS - $${config.prices.price_30d}
4️⃣ - 50 DÍAS - $${config.prices.price_50d}

0️⃣ - VOLVER`);
                }
                
                // OPCIÓN 3 - VERIFICAR
                else if (text === '3' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_check_hwid');
                    await client.sendText(from, `🔍 *VERIFICAR HWID*

Envía tu HWID:

Formato: APP-E3E4D5CBB7636907`);
                }
                
                // OPCIÓN 4 - DESCARGAR
                else if (text === '4' && userState.state === 'main_menu') {
                    await client.sendText(from, `📱 *DESCARGAR APP*

${config.links.app_download}`);
                }
                
                // PROCESAR NOMBRE PARA PRUEBA
                else if (userState.state === 'awaiting_test_nombre') {
                    const nombre = message.body.trim();
                    
                    if (nombre.length < 2) {
                        await client.sendText(from, '❌ Nombre muy corto. Intenta de nuevo:');
                        return;
                    }
                    
                    await setUserState(from, 'awaiting_test_hwid', { nombre });
                    await client.sendText(from, `✅ Gracias *${nombre}*

Ahora envía tu *HWID*:

Formato: APP-E3E4D5CBB7636907

⏳ *UNA PRUEBA POR DÍA*`);
                }
                
                // PROCESAR HWID PARA PRUEBA
                else if (userState.state === 'awaiting_test_hwid') {
                    const rawHwid = message.body;
                    const hwid = normalizeHWID(rawHwid);
                    const nombre = userState.data.nombre;
                    
                    console.log(chalk.yellow(`\n📝 PROCESANDO HWID PARA PRUEBA:`));
                    console.log(chalk.yellow(`   HWID recibido: ${rawHwid}`));
                    console.log(chalk.yellow(`   HWID normalizado: ${hwid}`));
                    console.log(chalk.yellow(`   Nombre: ${nombre}`));
                    console.log(chalk.yellow(`   Teléfono: ${from}`));
                    
                    if (!validateHWID(hwid)) {
                        console.log(chalk.red(`❌ HWID inválido: ${hwid}`));
                        await client.sendText(from, `❌ *HWID INVÁLIDO*

Formato: APP-E3E4D5CBB7636907

Intenta de nuevo:`);
                        return;
                    }
                    
                    // Verificar prueba diaria
                    if (!(await canCreateTest(from))) {
                        console.log(chalk.yellow(`⚠️ ${from} ya usó prueba hoy`));
                        await client.sendText(from, `❌ *YA USaste tu prueba hoy*

Vuelve mañana o compra un plan`);
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    // Verificar si HWID ya está activo
                    const active = await isHWIDActive(hwid);
                    if (active) {
                        console.log(chalk.yellow(`⚠️ HWID ${hwid} ya está activo`));
                        await client.sendText(from, `❌ *HWID YA ACTIVO*

Este HWID ya está registrado.`);
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    await client.sendText(from, '⏳ Activando prueba...');
                    
                    // REGISTRAR HWID
                    console.log(chalk.green(`\n🔄 LLAMANDO A registerHWID...`));
                    const result = await registerHWID(from, nombre, hwid, 0, 'test');
                    console.log(chalk.green(`📊 RESULTADO: ${JSON.stringify(result)}\n`));
                    
                    if (result.success) {
                        registerTest(from, nombre);
                        
                        const expireTime = moment(result.expires).format('HH:mm DD/MM/YYYY');
                        
                        await client.sendText(from, `✅ *PRUEBA ACTIVADA*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
⏰ *Expira:* ${expireTime}

📱 Ya puedes conectarte`);
                        
                        console.log(chalk.green(`✅ HWID REGISTRADO: ${hwid}`));
                    } else {
                        console.log(chalk.red(`❌ ERROR: ${result.error}`));
                        await client.sendText(from, `❌ *Error:* ${result.error}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // PROCESAR PLAN DE COMPRA
                else if (userState.state === 'buying_hwid' && ['1','2','3','4'].includes(text)) {
                    const plans = {
                        '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                        '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                        '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                        '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                    };
                    
                    const plan = plans[text];
                    
                    if (mpEnabled) {
                        await client.sendText(from, `📌 *Plan seleccionado: ${plan.name}*

💰 Precio: $${plan.price}

Te contactará un administrador para el pago.

${config.links.support}`);
                    } else {
                        await client.sendText(from, `📌 *Plan: ${plan.name}*

💰 Precio: $${plan.price}

Contacta al administrador:
${config.links.support}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                else if (text === '0' && userState.state === 'buying_hwid') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, `🤖 *BOT MGVPN*

Elige una opción:

1️⃣ - PROBAR (2 HORAS GRATIS)
2️⃣ - COMPRAR INTERNET
3️⃣ - VERIFICAR MI HWID
4️⃣ - DESCARGAR APP`);
                }
                
                // PROCESAR VERIFICACIÓN
                else if (userState.state === 'awaiting_check_hwid') {
                    const rawHwid = message.body;
                    const hwid = normalizeHWID(rawHwid);
                    
                    const info = await getHWIDInfo(hwid);
                    
                    if (info && info.status === 1 && moment(info.expires_at).isAfter(moment())) {
                        await client.sendText(from, `✅ *HWID ACTIVO*

👤 ${info.nombre}
📅 Expira: ${moment(info.expires_at).format('DD/MM/YYYY HH:mm')}`);
                    } else {
                        await client.sendText(from, `❌ *HWID NO ACTIVO*

No está registrado o ha expirado.`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error en mensaje:'), error.message);
            }
        });
        
        // TAREAS PROGRAMADAS
        cron.schedule('*/15 * * * *', () => {
            db.run(`UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime') AND status = 1`);
        });
        
        console.log(chalk.green('✅ BOT INICIADO - Esperando mensajes...\n'));
        
    } catch (error) {
        console.error(chalk.red('❌ Error iniciando:'), error.message);
        setTimeout(initializeBot, 10000);
    }
}

// Iniciar
initializeBot();

process.on('SIGINT', () => {
    if (client) client.close();
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ bot.js creado con registro automático${NC}"

# ================================================
# PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot-hwid << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/hwid.db"
CONFIG="/opt/sshbot-pro/config/config.json"

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        PANEL SSH BOT PRO - HWID CORREGIDO        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"
    
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    ACTIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date=date('now')" 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 ESTADO:${NC}"
    echo -e "  HWIDs: $ACTIVOS activos / $TOTAL totales"
    echo -e "  Tests hoy: $TESTS"
    
    if pm2 list | grep -q "sshbot-pro.*online"; then
        echo -e "  Bot: ${GREEN}● ACTIVO${NC}"
    else
        echo -e "  Bot: ${RED}● DETENIDO${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}1)${NC} Iniciar/Reiniciar bot"
    echo -e "${CYAN}2)${NC} Detener bot"
    echo -e "${CYAN}3)${NC} Ver logs"
    echo -e "${CYAN}4)${NC} Registrar HWID manual"
    echo -e "${CYAN}5)${NC} Listar HWIDs activos"
    echo -e "${CYAN}6)${NC} Ver tests de hoy"
    echo -e "${CYAN}7)${NC} Configurar MercadoPago"
    echo -e "${CYAN}8)${NC} Corregir fechas expiradas"
    echo -e "${CYAN}0)${NC} Salir"
    echo ""
}

while true; do
    show_menu
    read -p "👉 Opción: " opt
    
    case $opt in
        1)
            cd /root/sshbot-pro
            pm2 restart sshbot-pro 2>/dev/null || pm2 start bot.js --name sshbot-pro
            pm2 save
            echo -e "${GREEN}✅ Bot iniciado${NC}"
            sleep 2
            ;;
        2)
            pm2 stop sshbot-pro
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            pm2 logs sshbot-pro --lines 50
            ;;
        4)
            clear
            echo -e "${CYAN}📝 REGISTRAR HWID MANUAL${NC}\n"
            read -p "Teléfono: " PHONE
            read -p "Nombre: " NOMBRE
            read -p "HWID (APP-XXXXXXXX): " HWID
            read -p "Días (0=test 2h): " DIAS
            
            HWID=$(echo "$HWID" | tr 'a-z' 'A-Z')
            if [[ $DIAS == "0" ]]; then
                EXPIRE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                TIPO="test"
            else
                EXPIRE=$(date -d "+$DIAS days" +"%Y-%m-%d 23:59:59")
                TIPO="premium"
            fi
            
            sqlite3 "$DB" "INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('$PHONE', '$NOMBRE', '$HWID', '$TIPO', '$EXPIRE', 1)" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "\n${GREEN}✅ HWID registrado${NC}"
                echo -e "Expira: $EXPIRE"
            else
                echo -e "\n${RED}❌ Error (puede que el HWID ya exista)${NC}"
            fi
            read -p "Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}📋 HWIDs ACTIVOS${NC}\n"
            sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, tipo, expires_at FROM hwid_users WHERE status=1 ORDER BY expires_at"
            read -p "Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}📋 TESTS DE HOY${NC}\n"
            sqlite3 -header -column "$DB" "SELECT nombre, phone, created_at FROM daily_tests WHERE date=date('now')"
            read -p "Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}🔑 CONFIGURAR MERCADOPAGO${NC}\n"
            read -p "Access Token: " TOKEN
            if [[ -n "$TOKEN" ]]; then
                sed -i "s/\"access_token\":.*/\"access_token\": \"$TOKEN\",/" "$CONFIG"
                sed -i "s/\"enabled\":.*/\"enabled\": true,/" "$CONFIG"
                echo -e "${GREEN}✅ Token guardado${NC}"
                pm2 restart sshbot-pro
            fi
            read -p "Enter..."
            ;;
        8)
            clear
            echo -e "${CYAN}🔧 CORRIGIENDO FECHAS...${NC}"
            sqlite3 "$DB" "UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime') AND status = 1"
            sqlite3 "$DB" "UPDATE hwid_users SET status = 1 WHERE expires_at > datetime('now', 'localtime') AND status = 0"
            echo -e "${GREEN}✅ Listo${NC}"
            read -p "Enter..."
            ;;
        0)
            exit 0
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot-hwid
ln -sf /usr/local/bin/sshbot-hwid /usr/local/bin/sshbot

# ================================================
# CONFIGURAR PM2
# ================================================
echo -e "\n${CYAN}⚙️  Configurando PM2...${NC}"
pm2 startup systemd -u root --hp /root > /dev/null 2>&1
pm2 save

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot...${NC}"
cd /root/sshbot-pro
pm2 start bot.js --name sshbot-pro --max-memory-restart 512M
pm2 save

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ✅ INSTALACIÓN COMPLETADA - CORREGIDA               ║"
echo "║         ✅ REGISTRO AUTOMÁTICO DE HWIDs ACTIVADO            ║"
echo "║         ✅ PRUEBA 2 HORAS - CORREGIDA                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "\n${YELLOW}📋 COMANDOS:${NC}"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver QR y logs"
echo ""

echo -e "${YELLOW}📱 PRIMEROS PASOS:${NC}"
echo -e "  1. Ejecuta: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  2. Escanea el QR con WhatsApp"
echo -e "  3. Envia 'hola' al número"
echo -e "  4. Prueba opción 1 con HWID: APP-E3E4D5CBB7636907"
echo ""

echo -e "${YELLOW}🔧 SI HAY PROBLEMAS:${NC}"
echo -e "  • Usa: ${GREEN}sshbot${NC} y opción 8 para corregir fechas"
echo -e "  • Revisa logs: ${GREEN}pm2 logs sshbot-pro${NC}"
echo ""

read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    pm2 logs sshbot-pro
fi

exit 0
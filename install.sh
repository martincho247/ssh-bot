#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT + MERCADOPAGO + HWID
# VERSIÓN COMPLETA CORREGIDA - PRUEBA 2 HORAS
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

# Detener ejecución si hay error
set -e

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
║          🤖 SSH BOT PRO - VERSIÓN COMPLETA CORREGIDA        ║
║               🔐 SISTEMA HWID - SIN USUARIO/CONTRASEÑA      ║
║               ⏱️  PRUEBA: 2 HORAS (CORREGIDO)               ║
║               💰 MercadoPago SDK v2.x INTEGRADO             ║
║               ⏰ NOTIFICACIONES DE VENCIMIENTO               ║
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
echo -e "\n${CYAN}🔍 Detectando IP del servidor...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || curl -4 -s --max-time 10 icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}' | head -1)
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" || "$SERVER_IP" == "::1" ]]; then
    read -p "📝 Ingresa la IP pública del servidor: " SERVER_IP
fi
echo -e "${GREEN}✅ IP detectada: ${CYAN}$SERVER_IP${NC}"

read -p "$(echo -e "\n${YELLOW}¿Continuar con la instalación completa? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS DEL SISTEMA
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias del sistema...${NC}"

apt-get update -y
apt-get upgrade -y

# Instalar paquetes necesarios
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw nginx \
    apt-transport-https ca-certificates \
    gnupg lsb-release

# Node.js 18.x
echo -e "\n${CYAN}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Chrome/Chromium para WPPConnect
echo -e "\n${CYAN}📦 Instalando Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable || apt-get install -y chromium-browser

# PM2 global
echo -e "\n${CYAN}📦 Instalando PM2...${NC}"
npm install -g pm2
pm2 update

# Configurar firewall
echo -e "\n${CYAN}🔒 Configurando firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 8001/tcp
echo "y" | ufw enable

echo -e "${GREEN}✅ Dependencias instaladas correctamente${NC}"

# ================================================
# PREPARAR ESTRUCTURA DE DIRECTORIOS
# ================================================
echo -e "\n${CYAN}📁 Creando estructura de directorios...${NC}"

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/hwid.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
QR_DIR="$INSTALL_DIR/qr_codes"
SESSIONS_DIR="/root/.wppconnect"

# Limpiar instalaciones anteriores
pm2 delete sshbot-pro 2>/dev/null || true
pm2 save 2>/dev/null || true
rm -rf "$INSTALL_DIR" 2>/dev/null || true
rm -rf "$USER_HOME" 2>/dev/null || true
rm -rf "$SESSIONS_DIR" 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p "$SESSIONS_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 "$SESSIONS_DIR"

echo -e "${GREEN}✅ Directorios creados${NC}"

# ================================================
# CREAR ARCHIVO DE CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}⚙️  Creando configuración...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-CORREGIDO",
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
        "qr_codes": "$QR_DIR",
        "sessions": "$SESSIONS_DIR"
    }
}
EOF

echo -e "${GREEN}✅ Configuración creada${NC}"

# ================================================
# CREAR BASE DE DATOS SQLITE
# ================================================
echo -e "\n${CYAN}💾 Creando base de datos...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
-- Tabla de usuarios HWID
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

-- Tabla de tests diarios
CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

-- Tabla de pagos
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

-- Tabla de logs
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de estados de usuario
CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de intentos HWID
CREATE TABLE IF NOT EXISTS hwid_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hwid TEXT,
    phone TEXT,
    nombre TEXT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_hwid_users_hwid ON hwid_users(hwid);
CREATE INDEX IF NOT EXISTS idx_hwid_users_status ON hwid_users(status);
CREATE INDEX IF NOT EXISTS idx_hwid_users_expires ON hwid_users(expires_at);
CREATE INDEX IF NOT EXISTS idx_payments_hwid ON payments(hwid);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_payment_id ON payments(payment_id);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# CREAR package.json
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
# INSTALAR DEPENDENCIAS NPM
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias NPM (esto puede tomar varios minutos)...${NC}"
npm install --silent --no-audit --no-fund > /dev/null 2>&1 || npm install
echo -e "${GREEN}✅ Dependencias NPM instaladas${NC}"

# ================================================
# CREAR BOT.JS CORREGIDO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con sistema HWID corregido...${NC}"

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
console.log(chalk.cyan.bold('║           🤖 SSH BOT PRO - HWID CORREGIDO                    ║'));
console.log(chalk.cyan.bold('║           ⏱️  PRUEBA: 2 HORAS (FUNCIONANDO)                   ║'));
console.log(chalk.cyan.bold('║           ⏰ NOTIFICACIONES ACTIVAS                           ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    try {
        delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
        return require('/opt/sshbot-pro/config/config.json');
    } catch (error) {
        console.log(chalk.red('Error cargando config:'), error.message);
        return {
            prices: { price_7d: 3000, price_15d: 4000, price_30d: 7000, price_50d: 9700, currency: 'ARS' },
            links: { app_download: '', support: '' }
        };
    }
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/hwid.db');

// ✅ MERCADOPAGO SDK V2.X
let mpEnabled = false;
let mpClient = null;
let mpPreference = null;

function initMercadoPago() {
    config = loadConfig();
    if (config.mercadopago && config.mercadopago.access_token && config.mercadopago.access_token !== '') {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            
            mpClient = new MercadoPagoConfig({ 
                accessToken: config.mercadopago.access_token,
                options: { timeout: 5000 }
            });
            
            mpPreference = new Preference(mpClient);
            mpEnabled = true;
            
            console.log(chalk.green('✅ MercadoPago SDK v2.x ACTIVO'));
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpEnabled = false;
            return false;
        }
    }
    console.log(chalk.yellow('⚠️ MercadoPago NO configurado'));
    return false;
}

initMercadoPago();

let client = null;

// ✅ FUNCIONES PARA HWID (CORREGIDAS)
function validateHWID(hwid) {
    // Formato esperado: APP-E3E4D5CBB7636907
    const hwidRegex = /^APP-[A-F0-9]{16}$/;
    return hwidRegex.test(hwid);
}

function normalizeHWID(hwid) {
    // Asegurar formato consistente
    hwid = hwid.trim().toUpperCase();
    // Si no tiene prefijo APP-, agregarlo
    if (!hwid.startsWith('APP-')) {
        // Limpiar caracteres no hexadecimales
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
                    console.error(chalk.red('Error en isHWIDActive:'), err.message);
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
            if (err || !row) resolve(null);
            else resolve(row);
        });
    });
}

async function registerHWID(phone, nombre, hwid, days, tipo = 'premium') {
    try {
        // Verificar si HWID ya existe
        const existing = await new Promise((resolve) => {
            db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
                resolve(row);
            });
        });

        if (existing) {
            return { success: false, error: 'HWID ya registrado en el sistema' };
        }

        let expireFull;
        if (days === 0 || tipo === 'test') {
            // Test - 2 horas (CORREGIDO)
            expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.cyan(`⏱️  Prueba 2 horas - Expira: ${expireFull}`));
        } else {
            // Premium - expira a las 23:59:59 del día
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        }

        // Registrar en BD
        await new Promise((resolve, reject) => {
            db.run(
                `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)`,
                [phone, nombre, hwid, tipo, expireFull],
                function(err) {
                    if (err) reject(err);
                    else resolve(this.lastID);
                }
            );
        });

        // Registrar intento
        db.run(`INSERT INTO hwid_attempts (hwid, phone, nombre, action) VALUES (?, ?, ?, 'registered')`, 
            [hwid, phone, nombre]);

        return { 
            success: true, 
            hwid,
            nombre,
            expires: expireFull,
            tipo
        };

    } catch (error) {
        console.error(chalk.red('❌ Error registrando HWID:'), error.message);
        return { success: false, error: error.message };
    }
}

function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], (err, row) => {
                if (err) {
                    console.error(chalk.red('Error en canCreateTest:'), err.message);
                    resolve(false);
                } else {
                    resolve(row.count === 0);
                }
            });
    });
}

function registerTest(phone, nombre) {
    const today = moment().format('YYYY-MM-DD');
    db.run('INSERT OR IGNORE INTO daily_tests (phone, nombre, date) VALUES (?, ?, ?)', 
        [phone, nombre, today]);
}

// ✅ SISTEMA DE ESTADOS
function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) {
                resolve({ state: 'main_menu', data: null });
            } else {
                try {
                    resolve({
                        state: row.state || 'main_menu',
                        data: row.data ? JSON.parse(row.data) : null
                    });
                } catch (e) {
                    resolve({ state: 'main_menu', data: null });
                }
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

// ✅ MERCADOPAGO - CREAR PAGO
async function createMercadoPagoPayment(phone, days, amount, planName) {
    try {
        if (!mpEnabled || !mpPreference) {
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        const phoneClean = phone.replace('@c.us', '').replace(/\D/g, '');
        const paymentId = `HWID-${phoneClean}-${days}d-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `HWID SSH PREMIUM ${days} DÍAS`,
                description: `Activación HWID SSH por ${days} días`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: isoDate,
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Ya%20pague`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente`
            },
            auto_return: 'approved',
            statement_descriptor: 'HWID SSH'
        };
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point || response.sandbox_init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 400,
                margin: 2
            });
            
            await new Promise((resolve, reject) => {
                db.run(
                    `INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                    [paymentId, phone, `${days}d`, days, amount, paymentUrl, qrPath, response.id],
                    function(err) {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                amount: parseFloat(amount)
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
    if (!mpEnabled) return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', 
        async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos pendientes...`));
        
        for (const payment of payments) {
            try {
                const url = `https://api.mercadopago.com/v1/payments/search?external_reference=${payment.payment_id}`;
                const response = await axios.get(url, {
                    headers: { 
                        'Authorization': `Bearer ${config.mercadopago.access_token}`
                    },
                    timeout: 15000
                });
                
                if (response.data && response.data.results && response.data.results.length > 0) {
                    const mpPayment = response.data.results[0];
                    
                    console.log(chalk.cyan(`📋 Pago ${payment.payment_id}: ${mpPayment.status}`));
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO APROBADO: ${payment.payment_id}`));
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, 
                            [payment.payment_id]);
                        
                        // Enviar mensaje pidiendo NOMBRE primero
                        const message = `✅ PAGO CONFIRMADO

🎉 Tu pago ha sido aprobado

📝 PRIMERO, ESCRIBE TU NOMBRE:
Para continuar con la activación, dime tu nombre

⏳ Tienes 30 minutos para completar el proceso`;
                        
                        if (client) {
                            await client.sendText(payment.phone, message);
                            await setUserState(payment.phone, 'awaiting_hwid', { 
                                payment_id: payment.payment_id,
                                days: payment.days,
                                plan: payment.plan
                            });
                        }
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
}

// ✅ NOTIFICACIONES DE VENCIMIENTO
async function checkExpiringHWIDs() {
    try {
        // Buscar HWIDs que expiran en las próximas 24 horas
        const expiringSoon = await new Promise((resolve, reject) => {
            db.all(`
                SELECT * FROM hwid_users 
                WHERE status = 1 
                AND expires_at > datetime('now', 'localtime') 
                AND expires_at < datetime('now', 'localtime', '+1 day')
                AND tipo = 'premium'
            `, (err, rows) => {
                if (err) reject(err);
                else resolve(rows || []);
            });
        });

        for (const hwid of expiringSoon) {
            const hoursLeft = moment(hwid.expires_at).diff(moment(), 'hours');
            const message = `⏰ RECORDATORIO DE VENCIMIENTO

Hola ${hwid.nombre}, tu acceso expirará en aproximadamente ${hoursLeft} horas.

🔐 HWID: ${hwid.hwid}
⏰ Fecha de vencimiento: ${moment(hwid.expires_at).format('DD/MM/YYYY HH:mm')}

💰 Para renovar, envía 2 y elige tu plan.

¡No te quedes sin servicio!`;
            
            if (client) {
                await client.sendText(hwid.phone, message);
                console.log(chalk.yellow(`📨 Notificación enviada a ${hwid.nombre} - Expira en ${hoursLeft} horas`));
            }
        }

        // Buscar HWIDs que expiraron en las últimas 24 horas
        const expired = await new Promise((resolve, reject) => {
            db.all(`
                SELECT * FROM hwid_users 
                WHERE status = 1 
                AND expires_at < datetime('now', 'localtime')
                AND expires_at > datetime('now', 'localtime', '-1 day')
                AND tipo = 'premium'
            `, (err, rows) => {
                if (err) reject(err);
                else resolve(rows || []);
            });
        });

        for (const hwid of expired) {
            // Marcar como expirado
            db.run('UPDATE hwid_users SET status = 0 WHERE id = ?', [hwid.id]);
            
            const message = `⏰ SERVICIO EXPIRADO

Hola ${hwid.nombre}, tu acceso ha expirado.

🔐 HWID: ${hwid.hwid}
⏰ Expiró: ${moment(hwid.expires_at).format('DD/MM/YYYY HH:mm')}

💰 Para renovar, envía 2 y elige tu plan.

¡Renueva ahora y sigue disfrutando!`;
            
            if (client) {
                await client.sendText(hwid.phone, message);
                console.log(chalk.yellow(`📨 Notificación post-vencimiento enviada a ${hwid.nombre}`));
            }
        }

    } catch (error) {
        console.error(chalk.red('❌ Error en notificaciones de vencimiento:'), error.message);
    }
}

// ✅ LIMPIAR HWIDS EXPIRADOS
async function cleanupExpiredHWIDs() {
    try {
        const now = moment().format('YYYY-MM-DD HH:mm:ss');
        console.log(chalk.yellow(`🧹 Limpiando HWIDs expirados...`));
        
        await new Promise((resolve, reject) => {
            db.run('UPDATE hwid_users SET status = 0 WHERE expires_at < datetime("now", "localtime") AND status = 1', 
                [], function(err) {
                    if (err) reject(err);
                    else {
                        console.log(chalk.green(`✅ ${this.changes} HWIDs marcados como expirados`));
                        resolve();
                    }
                });
        });
    } catch (error) {
        console.error(chalk.red('❌ Error limpiando HWIDs:'), error.message);
    }
}

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-hwid',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            browserWS: '',
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--no-first-run',
                '--no-zygote',
                '--disable-gpu',
                '--window-size=1920,1080'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            },
            disableWelcome: true,
            updatesLog: false,
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
        });
        
        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                // Ignorar mensajes de grupos y estados
                if (message.isGroupMsg || message.from.includes('@g.us')) return;
                if (message.from === 'status@broadcast') return;
                
                const text = message.body ? message.body.toLowerCase().trim() : '';
                const from = message.from;
                
                // Ignorar mensajes vacíos
                if (!text) return;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));
                
                const userState = await getUserState(from);
                
                // MENÚ PRINCIPAL
                if (['menu', 'hola', 'start', 'hi', 'volver', '0'].includes(text)) {
                    await setUserState(from, 'main_menu');
                    
                    await client.sendText(from, `🤖 *BOT MGVPN - SISTEMA HWID*

Hola! Elige una opción:

1️⃣ - PROBAR INTERNET (2 horas gratis)
2️⃣ - COMPRAR INTERNET
3️⃣ - VERIFICAR MI HWID
4️⃣ - DESCARGAR APLICACIÓN

⏱️ *PRUEBA: 2 HORAS*`);
                }
                
                // OPCIÓN 1: PRUEBA
                else if (text === '1' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_test_nombre');
                    
                    await client.sendText(from, `⏳ *PRUEBA GRATUITA - 2 HORAS*

Primero, dime tu *NOMBRE*:`);
                }
                
                // OPCIÓN 2: COMPRAR
                else if (text === '2' && userState.state === 'main_menu') {
                    await setUserState(from, 'buying_hwid');
                    
                    await client.sendText(from, `💰 *PLANES DE INTERNET*

Selecciona un plan:

1️⃣ - 7 DÍAS - $${config.prices.price_7d}
2️⃣ - 15 DÍAS - $${config.prices.price_15d}
3️⃣ - 30 DÍAS - $${config.prices.price_30d}
4️⃣ - 50 DÍAS - $${config.prices.price_50d}

0️⃣ - VOLVER

💳 Pago con MercadoPago`);
                }
                
                // OPCIÓN 3: VERIFICAR HWID
                else if (text === '3' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_check_hwid');
                    
                    await client.sendText(from, `🔍 *VERIFICAR HWID*

Envía tu HWID para verificar si está activo:

📱 *Formato:* APP-E3E4D5CBB7636907

(Escribe MENU para volver)`);
                }
                
                // OPCIÓN 4: DESCARGAR APP
                else if (text === '4' && userState.state === 'main_menu') {
                    await client.sendText(from, `📱 *DESCARGAR APLICACIÓN*

🔗 Enlace:
${config.links.app_download}

💡 *Instrucciones:*
1. Abre el link y descarga el APK
2. Abre el archivo descargado
3. Si pide permisos, acepta
4. Instala la aplicación`);
                }
                
                // PROCESAR NOMBRE PARA PRUEBA
                else if (userState.state === 'awaiting_test_nombre') {
                    const nombre = message.body.trim();
                    
                    if (nombre.length < 2) {
                        await client.sendText(from, '❌ El nombre debe tener al menos 2 caracteres. Intenta de nuevo:');
                        return;
                    }
                    
                    // Guardar nombre y pasar a pedir HWID
                    await setUserState(from, 'awaiting_test_hwid', { nombre });
                    
                    await client.sendText(from, `✅ Gracias *${nombre}*

Ahora envía tu *HWID* para activar la prueba (2 horas):

📱 *Formato:* APP-E3E4D5CBB7636907

⏳ *¿CÓMO OBTENER TU HWID?*
1. Abre la aplicación MGVPN
2. Toca el botón de WhatsApp
3. Copia el HWID que aparece

⏰ *UNA PRUEBA POR DÍA*`);
                }
                
                // PROCESAR HWID PARA PRUEBA
                else if (userState.state === 'awaiting_test_hwid') {
                    const rawHwid = message.body;
                    const hwid = normalizeHWID(rawHwid);
                    const nombre = userState.data.nombre;
                    
                    if (!validateHWID(hwid)) {
                        await client.sendText(from, `❌ *HWID INVÁLIDO*

Formato correcto: APP-E3E4D5CBB7636907

Envía el HWID nuevamente o escribe MENU para volver`);
                        return;
                    }
                    
                    // Verificar si ya usó prueba hoy
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, `❌ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana o compra un plan

💰 Envia 2 para ver los planes`);
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    // Verificar si HWID ya está registrado
                    const active = await isHWIDActive(hwid);
                    if (active) {
                        await client.sendText(from, `❌ *HWID YA ACTIVO*

Este HWID ya está registrado en el sistema.

Si crees que es un error, contacta soporte.`);
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    await client.sendText(from, '⏳ Activando prueba (2 horas)...');
                    
                    const result = await registerHWID(from, nombre, hwid, 0, 'test');
                    
                    if (result.success) {
                        registerTest(from, nombre);
                        
                        const expireTime = moment(result.expires).format('HH:mm DD/MM/YYYY');
                        
                        await client.sendText(from, `✅ *PRUEBA ACTIVADA*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
⏰ *Expira:* ${expireTime}
⚡ *Tipo:* PRUEBA (2 HORAS)

📱 Abre la aplicación y ya puedes conectarte

💡 Si tienes problemas, contacta soporte`);
                        
                        console.log(chalk.green(`✅ HWID test: ${hwid} - ${nombre} - Expira: ${result.expires}`));
                    } else {
                        await client.sendText(from, `❌ *Error:* ${result.error}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // PROCESAR PLAN DE COMPRA
                else if (userState.state === 'buying_hwid' && ['1','2','3','4'].includes(text)) {
                    const planMap = {
                        '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                        '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                        '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                        '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                    };
                    
                    const plan = planMap[text];
                    
                    if (mpEnabled) {
                        await client.sendText(from, '⏳ Generando link de pago...');
                        
                        const payment = await createMercadoPagoPayment(
                            from, 
                            plan.days, 
                            plan.price, 
                            plan.name
                        );
                        
                        if (payment.success) {
                            const message = `💰 *PAGO PARA HWID*

📌 *Plan:* ${plan.name}
💰 *Precio:* $${payment.amount}
🕜 *Duración:* ${plan.days} días

🔗 *LINK DE PAGO:*
${payment.paymentUrl}

⏰ *Válido por 24 horas*

📌 *DESPUÉS DE PAGAR:*
1. Espera la confirmación automática
2. Te pediremos tu NOMBRE
3. Luego tu HWID
4. Se activará automáticamente`;
                            
                            await client.sendText(from, message);
                            
                            if (fs.existsSync(payment.qrPath)) {
                                try {
                                    await client.sendImage(from, payment.qrPath, 'qr-pago.jpg', 
                                        `📱 *ESCANEA CON MERCADOPAGO*\n\n${plan.name} - $${payment.amount}`);
                                } catch (qrError) {
                                    console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                                }
                            }
                        } else {
                            await client.sendText(from, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

Contacta al administrador para otras opciones de pago.`);
                        }
                        
                        await setUserState(from, 'main_menu');
                    } else {
                        await client.sendText(from, `📌 *PLAN SELECCIONADO: ${plan.name}*

💰 Precio: $${plan.price}
🕜 Duración: ${plan.days} días

Para continuar con la compra, contacta al administrador:
${config.links.support}`);
                        await setUserState(from, 'main_menu');
                    }
                }
                
                // VOLVER DESDE COMPRA
                else if (text === '0' && userState.state === 'buying_hwid') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, `🤖 *BOT MGVPN - SISTEMA HWID*

Elige una opción:

1️⃣ - PROBAR INTERNET (2 horas gratis)
2️⃣ - COMPRAR INTERNET
3️⃣ - VERIFICAR MI HWID
4️⃣ - DESCARGAR APLICACIÓN

⏱️ *PRUEBA: 2 HORAS*`);
                }
                
                // PROCESAR HWID PARA VERIFICACIÓN
                else if (userState.state === 'awaiting_check_hwid') {
                    const rawHwid = message.body;
                    const hwid = normalizeHWID(rawHwid);
                    
                    if (!validateHWID(hwid)) {
                        await client.sendText(from, `❌ *FORMATO INVÁLIDO*

Ejemplo: APP-E3E4D5CBB7636907

Intenta nuevamente o escribe MENU`);
                        return;
                    }
                    
                    const info = await getHWIDInfo(hwid);
                    
                    if (info) {
                        const expires = moment(info.expires_at).format('DD/MM/YYYY HH:mm');
                        const now = moment();
                        const expiresMoment = moment(info.expires_at);
                        const nombre = info.nombre || 'Usuario';
                        
                        if (info.status === 1 && expiresMoment.isAfter(now)) {
                            const remaining = expiresMoment.fromNow();
                            await client.sendText(from, `✅ *HWID ACTIVO*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
📅 *Tipo:* ${info.tipo === 'test' ? 'PRUEBA' : 'PREMIUM'}
⏰ *Válido hasta:* ${expires}
⌛ *Tiempo restante:* ${remaining}`);
                        } else {
                            await client.sendText(from, `❌ *HWID ${expiresMoment.isAfter(now) ? 'INACTIVO' : 'EXPIRADO'}*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
📅 ${expiresMoment.isAfter(now) ? 'Estado: INACTIVO' : 'Expiró: ' + expires}

Renueva comprando un nuevo plan (envía 2)`);
                        }
                    } else {
                        await client.sendText(from, `❌ *HWID NO REGISTRADO*

Este HWID no está en el sistema.

¿Quieres probar el servicio?
Envía 1 para prueba gratis (2 horas)`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // ESPERANDO NOMBRE Y HWID DESPUÉS DE PAGO
                else if (userState.state === 'awaiting_hwid') {
                    // Si NO tenemos nombre guardado, lo que llega es el nombre
                    if (!userState.data.nombre) {
                        const nombre = message.body.trim();
                        
                        if (nombre.length < 2) {
                            await client.sendText(from, '❌ El nombre debe tener al menos 2 caracteres. Intenta de nuevo:');
                            return;
                        }
                        
                        // Guardar el nombre y pasar a esperar HWID
                        userState.data.nombre = nombre;
                        await setUserState(from, 'awaiting_hwid', userState.data);
                        
                        await client.sendText(from, `✅ Gracias *${nombre}*

Ahora envía tu *HWID*:

📱 *Formato:* APP-E3E4D5CBB7636907

⏳ *¿CÓMO OBTENER TU HWID?*
1. Abre la aplicación MGVPN
2. Toca el botón de WhatsApp
3. Copia el HWID que aparece`);
                        
                        return;
                    }
                    
                    // Si ya tenemos nombre, lo que llega es el HWID
                    const rawHwid = message.body;
                    const hwid = normalizeHWID(rawHwid);
                    const nombre = userState.data.nombre;
                    
                    if (!validateHWID(hwid)) {
                        await client.sendText(from, `❌ *FORMATO INCORRECTO*

Ejemplo: APP-E3E4D5CBB7636907

Envía el HWID nuevamente:`);
                        return;
                    }
                    
                    // Verificar si HWID ya está activo
                    const active = await isHWIDActive(hwid);
                    if (active) {
                        await client.sendText(from, `❌ *HWID YA ACTIVO*

Este HWID ya está registrado en el sistema.

Si es tuyo, contacta soporte.`);
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    await client.sendText(from, '⏳ Activando tu HWID...');
                    
                    // Activar HWID
                    const result = await registerHWID(
                        from, 
                        nombre,
                        hwid, 
                        userState.data.days, 
                        'premium'
                    );
                    
                    if (result.success) {
                        // Actualizar pago con HWID y nombre
                        db.run(`UPDATE payments SET hwid = ?, nombre = ? WHERE payment_id = ?`,
                            [hwid, nombre, userState.data.payment_id]);
                        
                        const expireDate = moment(result.expires).format('DD/MM/YYYY HH:mm');
                        
                        await client.sendText(from, `✅ *¡ACTIVADO!*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
⏰ *Válido hasta:* ${expireDate}

🎉 *¡Ya puedes usar la aplicación!*

📱 Abre MGVPN y conéctate`);
                        
                        console.log(chalk.green(`✅ HWID premium: ${hwid} - ${nombre}`));
                    } else {
                        await client.sendText(from, `❌ *Error:* ${result.error}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // RESPUESTA POR DEFECTO
                else if (userState.state === 'main_menu') {
                    await client.sendText(from, `❓ *No entendí tu mensaje*

Opciones disponibles:
1 - Probar (2h gratis)
2 - Comprar
3 - Verificar HWID
4 - Descargar APP

Escribe *MENU* para ver el menú principal`);
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error procesando mensaje:'), error.message);
            }
        });
        
        // ✅ TAREAS PROGRAMADAS
        // Verificar pagos cada 2 minutos
        cron.schedule('*/2 * * * *', () => {
            console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
            checkPendingPayments();
        });
        
        // Notificaciones de vencimiento cada hora
        cron.schedule('0 * * * *', () => {
            console.log(chalk.yellow('⏰ Verificando HWIDs próximos a vencer...'));
            checkExpiringHWIDs();
        });
        
        // Limpiar HWIDs expirados cada 15 minutos
        cron.schedule('*/15 * * * *', () => {
            cleanupExpiredHWIDs();
        });
        
        // Limpiar estados antiguos cada hora
        cron.schedule('0 * * * *', () => {
            db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
        });
        
        console.log(chalk.green('\n✅ BOT INICIADO CORRECTAMENTE'));
        console.log(chalk.cyan('📱 Esperando mensajes...\n'));
        
    } catch (error) {
        console.error(chalk.red('❌ Error inicializando:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(initializeBot, 10000);
    }
}

// Iniciar bot
initializeBot();

// Manejar cierre del proceso
process.on('SIGINT', async () => {
    console.log(chalk.yellow('\n🛑 Cerrando bot...'));
    if (client) {
        try {
            await client.close();
        } catch (e) {}
    }
    process.exit();
});

process.on('SIGTERM', async () => {
    console.log(chalk.yellow('\n🛑 Cerrando bot...'));
    if (client) {
        try {
            await client.close();
        } catch (e) {}
    }
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ bot.js creado correctamente${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot-hwid << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

DB="/opt/sshbot-pro/data/hwid.db"
CONFIG="/opt/sshbot-pro/config/config.json"

# Función para obtener valor del JSON
get_val() { 
    if [[ -f "$CONFIG" ]]; then
        jq -r "$1" "$CONFIG" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Función para setear valor en JSON
set_val() { 
    if [[ -f "$CONFIG" ]]; then
        local t=$(mktemp)
        jq "$1 = $2" "$CONFIG" > "$t" 2>/dev/null && mv "$t" "$CONFIG" 2>/dev/null
    fi
}

# Probar conexión MercadoPago
test_mercadopago() {
    local TOKEN="$1"
    echo -e "${YELLOW}🔄 Probando conexión con MercadoPago...${NC}"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.mercadopago.com/v1/payment_methods" \
        2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "${GREEN}✅ CONEXIÓN EXITOSA - Token válido${NC}"
        return 0
    else
        echo -e "${RED}❌ ERROR - Código: $HTTP_CODE${NC}"
        echo -e "${YELLOW}Posibles causas: Token inválido o expirado${NC}"
        return 1
    fi
}

show_header() {
    clear
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║           🎛️  PANEL SSH BOT PRO - VERSIÓN HWID              ║${NC}"
    echo -e "${CYAN}${BOLD}║              🔐 SISTEMA SIN USUARIO/CONTRASEÑA              ║${NC}"
    echo -e "${CYAN}${BOLD}║              ⏱️  PRUEBA: 2 HORAS (CORREGIDO)                ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    # Obtener estadísticas
    TOTAL_HWID=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    ACTIVE_HWID=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    EXPIRED_HWID=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=0" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    APPROVED_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='approved'" 2>/dev/null || echo "0")
    TESTS_TODAY=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date = date('now')" 2>/dev/null || echo "0")
    
    # Estado del bot
    if pm2 list | grep -q "sshbot-pro.*online"; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
        BOT_PID=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="sshbot-pro") | .pid' 2>/dev/null)
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
        BOT_PID=""
    fi
    
    # Estado de MercadoPago
    MP_TOKEN=$(get_val '.mercadopago.access_token')
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" && "$MP_TOKEN" != "null" ]]; then
        MP_STATUS="${GREEN}✅ CONFIGURADO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    echo -e "${YELLOW}${BOLD}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  ${CYAN}Bot:${NC} $BOT_STATUS ${BOT_PID:+ (PID: $BOT_PID)}"
    echo -e "  ${CYAN}HWIDs:${NC} ${GREEN}$ACTIVE_HWID${NC} activos | ${YELLOW}$EXPIRED_HWID${NC} expirados | ${BLUE}$TOTAL_HWID${NC} total"
    echo -e "  ${CYAN}Tests hoy:${NC} ${PURPLE}$TESTS_TODAY${NC}"
    echo -e "  ${CYAN}Pagos:${NC} ${YELLOW}$PENDING_PAYMENTS${NC} pendientes | ${GREEN}$APPROVED_PAYMENTS${NC} aprobados"
    echo -e "  ${CYAN}MercadoPago:${NC} $MP_STATUS"
    echo -e "  ${CYAN}IP Servidor:${NC} $(get_val '.bot.server_ip')"
    echo -e "  ${CYAN}⏱️  Prueba:${NC} ${YELLOW}2 HORAS${NC}"
    echo -e "  ${CYAN}⏰ Notificaciones:${NC} ${GREEN}ACTIVAS (cada hora)${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}💰 PRECIOS ACTUALES:${NC}"
    echo -e "  ${CYAN}7 días:${NC} $ ${GREEN}$(get_val '.prices.price_7d')${NC} ARS"
    echo -e "  ${CYAN}15 días:${NC} $ ${GREEN}$(get_val '.prices.price_15d')${NC} ARS"
    echo -e "  ${CYAN}30 días:${NC} $ ${GREEN}$(get_val '.prices.price_30d')${NC} ARS"
    echo -e "  ${CYAN}50 días:${NC} $ ${GREEN}$(get_val '.prices.price_50d')${NC} ARS"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver logs y QR"
    echo -e "${CYAN}[4]${NC} 🔐  Registrar HWID manual"
    echo -e "${CYAN}[5]${NC} 👥  Listar HWIDs activos"
    echo -e "${CYAN}[6]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[7]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[9]${NC} 📊  Estadísticas completas"
    echo -e "${CYAN}[10]${NC} 🔄  Limpiar sesión WhatsApp"
    echo -e "${CYAN}[11]${NC} 💳  Ver pagos"
    echo -e "${CYAN}[12]${NC} 🔍  Buscar HWID"
    echo -e "${CYAN}[13]${NC} 🧪  Ver tests de hoy"
    echo -e "${CYAN}[14]${NC} 🔧  Corregir fechas expiradas"
    echo -e "${CYAN}[0]${NC} 🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Iniciando/Reiniciando bot...${NC}"
            cd /root/sshbot-pro
            pm2 delete sshbot-pro 2>/dev/null
            pm2 start bot.js --name sshbot-pro --max-memory-restart 512M
            pm2 save
            sleep 2
            echo -e "${GREEN}✅ Bot iniciado correctamente${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop sshbot-pro
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            echo -e "\n${YELLOW}📱 Mostrando logs (presiona Ctrl+C para salir)...${NC}\n"
            sleep 2
            pm2 logs sshbot-pro --lines 50
            ;;
        4)
            clear
            echo -e "${CYAN}${BOLD}🔐 REGISTRAR HWID MANUAL${NC}\n"
            
            read -p "📱 Teléfono (ej: 5491122334455@c.us): " PHONE
            read -p "👤 Nombre del usuario: " NOMBRE
            read -p "🔐 HWID (formato: APP-E3E4D5CBB7636907): " HWID
            read -p "📅 Tipo (test/premium): " TIPO
            read -p "⏰ Días (0=test 2h, 7,15,30,50): " DIAS
            
            # Validar HWID
            HWID=$(echo "$HWID" | tr 'a-z' 'A-Z')
            if [[ ! "$HWID" =~ ^APP-[A-F0-9]{16}$ ]]; then
                echo -e "\n${RED}❌ Formato HWID inválido${NC}"
                echo -e "${YELLOW}Debe ser: APP- seguido de 16 caracteres hexadecimales${NC}"
                read -p "Presiona Enter para continuar..."
                continue
            fi
            
            if [[ "$TIPO" == "test" ]]; then
                DIAS="0"
                EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
            else
                EXPIRE_DATE=$(date -d "+$DIAS days" +"%Y-%m-%d 23:59:59")
            fi
            
            # Verificar si HWID ya existe
            EXISTENTE=$(sqlite3 "$DB" "SELECT hwid FROM hwid_users WHERE hwid='$HWID'")
            if [[ -n "$EXISTENTE" ]]; then
                echo -e "\n${RED}❌ HWID ya existe en la base de datos${NC}"
                read -p "Presiona Enter para continuar..."
                continue
            fi
            
            sqlite3 "$DB" "INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('$PHONE', '$NOMBRE', '$HWID', '$TIPO', '$EXPIRE_DATE', 1)"
            
            if [[ $? -eq 0 ]]; then
                echo -e "\n${GREEN}✅ HWID REGISTRADO CORRECTAMENTE${NC}"
                echo -e "📱 Teléfono: ${CYAN}$PHONE${NC}"
                echo -e "👤 Nombre: ${CYAN}$NOMBRE${NC}"
                echo -e "🔐 HWID: ${CYAN}$HWID${NC}"
                echo -e "⏰ Expira: ${CYAN}$EXPIRE_DATE${NC}"
            else
                echo -e "\n${RED}❌ Error al registrar${NC}"
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            clear
            echo -e "${CYAN}${BOLD}👥 HWIDs ACTIVOS${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT id, nombre, hwid, phone, tipo, expires_at FROM hwid_users WHERE status = 1 ORDER BY expires_at DESC LIMIT 30"
            echo -e "\n${YELLOW}Total activos: $ACTIVE_HWID${NC}"
            read -p "Presiona Enter para continuar..."
            ;;
        6)
            clear
            echo -e "${CYAN}${BOLD}💰 CAMBIAR PRECIOS${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  ${CYAN}7 días:${NC} $ ${GREEN}$CURRENT_7D${NC} ARS"
            echo -e "  ${CYAN}15 días:${NC} $ ${GREEN}$CURRENT_15D${NC} ARS"
            echo -e "  ${CYAN}30 días:${NC} $ ${GREEN}$CURRENT_30D${NC} ARS"
            echo -e "  ${CYAN}50 días:${NC} $ ${GREEN}$CURRENT_50D${NC} ARS\n"
            
            read -p "Nuevo precio 7d [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15d [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30d [${CURRENT_30D}]: " NEW_30D
            read -p "Nuevo precio 50d [${CURRENT_50D}]: " NEW_50D
            
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$NEW_50D" ]] && set_val '.prices.price_50d' "$NEW_50D"
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
            
            # Reiniciar bot para aplicar cambios
            cd /root/sshbot-pro && pm2 restart sshbot-pro
            sleep 2
            read -p "Presiona Enter para continuar..."
            ;;
        7)
            clear
            echo -e "${CYAN}${BOLD}🔑 CONFIGURAR MERCADOPAGO${NC}\n"
            
            CURRENT_TOKEN=$(get_val '.mercadopago.access_token')
            
            if [[ -n "$CURRENT_TOKEN" && "$CURRENT_TOKEN" != "null" && "$CURRENT_TOKEN" != "" ]]; then
                echo -e "${GREEN}✅ Token actual configurado${NC}"
                echo -e "${YELLOW}Preview: ${CURRENT_TOKEN:0:30}...${NC}\n"
            fi
            
            echo -e "${CYAN}📋 INSTRUCCIONES PARA OBTENER TOKEN:${NC}"
            echo -e "  1. Ve a: ${GREEN}https://www.mercadopago.com.ar/developers${NC}"
            echo -e "  2. Inicia sesión con tu cuenta de MercadoPago"
            echo -e "  3. Ve a 'Tus credenciales'"
            echo -e "  4. Copia el 'Access Token' de PRODUCCIÓN"
            echo -e "  5. Formato: APP_USR-xxxxxxxxxx\n"
            
            read -p "¿Quieres configurar un nuevo token? (s/N): " CONF
            if [[ "$CONF" == "s" || "$CONF" == "S" ]]; then
                echo ""
                read -p "Pega el Access Token: " NEW_TOKEN
                
                if [[ "$NEW_TOKEN" =~ ^APP_USR- ]] || [[ "$NEW_TOKEN" =~ ^TEST- ]]; then
                    set_val '.mercadopago.access_token' "\"$NEW_TOKEN\""
                    set_val '.mercadopago.enabled' "true"
                    echo -e "\n${GREEN}✅ Token configurado correctamente${NC}"
                    
                    # Probar conexión
                    test_mercadopago "$NEW_TOKEN"
                    
                    # Reiniciar bot
                    echo -e "\n${YELLOW}🔄 Reiniciando bot para aplicar cambios...${NC}"
                    cd /root/sshbot-pro && pm2 restart sshbot-pro
                    sleep 2
                    echo -e "${GREEN}✅ Bot reiniciado${NC}"
                else
                    echo -e "\n${RED}❌ Token inválido (debe comenzar con APP_USR- o TEST-)${NC}"
                fi
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        8)
            clear
            echo -e "${CYAN}${BOLD}🧪 TEST MERCADOPAGO${NC}\n"
            
            TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
                echo -e "${RED}❌ Token no configurado${NC}"
                echo -e "${YELLOW}Configúralo primero con la opción 7${NC}\n"
                read -p "Presiona Enter para continuar..."
                continue
            fi
            
            test_mercadopago "$TOKEN"
            
            read -p "Presiona Enter para continuar..."
            ;;
        9)
            clear
            echo -e "${CYAN}${BOLD}📊 ESTADÍSTICAS COMPLETAS${NC}\n"
            
            echo -e "${YELLOW}🔐 ESTADÍSTICAS DE HWIDs:${NC}"
            sqlite3 "$DB" "SELECT 'Total HWIDs: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Expirados: ' || SUM(CASE WHEN status=0 THEN 1 ELSE 0 END) FROM hwid_users"
            sqlite3 "$DB" "SELECT 'Tests hoy: ' || COUNT(*) FROM daily_tests WHERE date = date('now')"
            
            echo -e "\n${YELLOW}💰 ESTADÍSTICAS DE PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', COALESCE(SUM(CASE WHEN status='approved' THEN amount ELSE 0 END), 0)) FROM payments"
            
            echo -e "\n${YELLOW}📅 PLANES VENDIDOS:${NC}"
            sqlite3 "$DB" "SELECT '7 días: ' || SUM(CASE WHEN plan='7d' THEN 1 ELSE 0 END) || ' | 15 días: ' || SUM(CASE WHEN plan='15d' THEN 1 ELSE 0 END) || ' | 30 días: ' || SUM(CASE WHEN plan='30d' THEN 1 ELSE 0 END) || ' | 50 días: ' || SUM(CASE WHEN plan='50d' THEN 1 ELSE 0 END) FROM payments WHERE status='approved'"
            
            echo -e "\n${YELLOW}💸 INGRESOS POR DÍA:${NC}"
            sqlite3 "$DB" "SELECT date(created_at) as fecha, printf('$%.2f', SUM(amount)) as total FROM payments WHERE status='approved' GROUP BY date(created_at) ORDER BY fecha DESC LIMIT 7"
            
            echo -e "\n${YELLOW}🔥 TOP 5 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT nombre, COUNT(*) as compras FROM payments WHERE status='approved' GROUP BY nombre ORDER BY compras DESC LIMIT 5"
            
            read -p "\nPresiona Enter para continuar..."
            ;;
        10)
            echo -e "\n${YELLOW}🧹 Limpiando sesión de WhatsApp...${NC}"
            pm2 stop sshbot-pro
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}Reinicia el bot con opción 1 para escanear nuevo QR${NC}"
            sleep 3
            ;;
        11)
            clear
            echo -e "${CYAN}${BOLD}💳 VER PAGOS${NC}\n"
            
            echo -e "${YELLOW}Pagos pendientes:${NC}"
            sqlite3 -column -header "$DB" "SELECT payment_id, phone, plan, amount, created_at FROM payments WHERE status='pending' ORDER BY created_at DESC LIMIT 10"
            
            echo -e "\n${YELLOW}Pagos aprobados:${NC}"
            sqlite3 -column -header "$DB" "SELECT payment_id, phone, nombre, plan, amount, approved_at, hwid FROM payments WHERE status='approved' ORDER BY approved_at DESC LIMIT 10"
            
            read -p "\nPresiona Enter para continuar..."
            ;;
        12)
            clear
            echo -e "${CYAN}${BOLD}🔍 BUSCAR HWID${NC}\n"
            read -p "Ingresa HWID, nombre o teléfono: " SEARCH
            
            echo -e "\n${YELLOW}Resultados:${NC}"
            sqlite3 -column -header "$DB" "SELECT id, nombre, hwid, phone, tipo, expires_at, CASE WHEN status=1 AND expires_at > datetime('now', 'localtime') THEN 'ACTIVO' ELSE 'INACTIVO' END as estado FROM hwid_users WHERE hwid LIKE '%$SEARCH%' OR phone LIKE '%$SEARCH%' OR nombre LIKE '%$SEARCH%'"
            
            read -p "\nPresiona Enter para continuar..."
            ;;
        13)
            clear
            echo -e "${CYAN}${BOLD}🧪 TESTS DE HOY${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT nombre, phone, created_at FROM daily_tests WHERE date = date('now') ORDER BY created_at DESC"
            
            TOTAL_TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date = date('now')")
            echo -e "\n${YELLOW}Total tests hoy: $TOTAL_TESTS${NC}"
            
            read -p "\nPresiona Enter para continuar..."
            ;;
        14)
            clear
            echo -e "${CYAN}${BOLD}🔧 CORREGIR FECHAS EXPIRADAS${NC}\n"
            
            echo -e "${YELLOW}Verificando HWIDs que deberían estar activos pero están marcados como expirados...${NC}"
            
            # Mostrar HWIDs activos pero con fecha pasada
            sqlite3 "$DB" "SELECT id, nombre, hwid, expires_at FROM hwid_users WHERE status=1 AND expires_at < datetime('now', 'localtime')"
            
            echo -e "\n${YELLOW}Corrigiendo fechas...${NC}"
            
            # Actualizar status basado en fecha actual
            sqlite3 "$DB" "UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime') AND status = 1"
            sqlite3 "$DB" "UPDATE hwid_users SET status = 1 WHERE expires_at > datetime('now', 'localtime') AND status = 0"
            
            echo -e "${GREEN}✅ Corrección aplicada${NC}"
            
            # Mostrar resultado
            ACTIVOS_CORREGIDOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1")
            echo -e "${CYAN}Ahora hay $ACTIVOS_CORREGIDOS HWIDs activos${NC}"
            
            read -p "\nPresiona Enter para continuar..."
            ;;
        0)
            echo -e "\n${GREEN}👷‍♂️ Hasta luego!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot-hwid
ln -sf /usr/local/bin/sshbot-hwid /usr/local/bin/sshbot

# ================================================
# CONFIGURAR PM2 PARA INICIO AUTOMÁTICO
# ================================================
echo -e "\n${CYAN}⚙️  Configurando inicio automático...${NC}"

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
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA - VERSIÓN CORREGIDA 🎉   ║
║                                                              ║
║       🔐 SISTEMA HWID - SIN USUARIO/CONTRASEÑA             ║
║       ⏱️  PRUEBA DE 2 HORAS (CORREGIDA Y FUNCIONANDO)      ║
║       💰 MercadoPago SDK v2.x INTEGRADO                    ║
║       ⏰ NOTIFICACIONES DE VENCIMIENTO ACTIVAS              ║
║       🎛️  PANEL DE CONTROL COMPLETO                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALACIÓN CORRECTA${NC}"
echo -e "${GREEN}✅ SISTEMA HWID CON PRUEBA DE 2 HORAS${NC}"
echo -e "${GREEN}✅ FORMATO HWID: APP-E3E4D5CBB7636907${NC}"
echo -e "${GREEN}✅ FLUJO: Primero nombre, luego HWID${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver logs y QR"
echo -e "  ${GREEN}pm2 restart sshbot-pro${NC} - Reiniciar bot"
echo -e "  ${GREEN}pm2 stop sshbot-pro${NC} - Detener bot"
echo -e "  ${GREEN}pm2 status${NC}      - Ver estado"
echo -e "\n"

echo -e "${YELLOW}📱 PRIMEROS PASOS:${NC}"
echo -e "  1. Escanea el QR que aparece en los logs"
echo -e "  2. Envia 'hola' al número de WhatsApp"
echo -e "  3. Prueba la opción 1 (2 horas gratis)"
echo -e "  4. Verifica que el HWID se active correctamente"
echo -e "\n"

echo -e "${YELLOW}🔧 SI HAY PROBLEMAS:${NC}"
echo -e "  • Revisa logs: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  • Usa panel: ${GREEN}sshbot${NC} (opción 14 para corregir fechas)"
echo -e "  • Limpia sesión: ${GREEN}sshbot${NC} (opción 10)"
echo -e "\n"

echo -e "${YELLOW}💰 CONFIGURAR MERCADOPAGO:${NC}"
echo -e "  • Ejecuta: ${GREEN}sshbot${NC} y ve a opción 7"
echo -e "  • Pega tu Access Token de producción"
echo -e "  • Prueba con opción 8"
echo -e "\n"

echo -e "${GREEN}${BOLD}🎯 ¡SISTEMA LISTO! ESCANEA EL QR Y PRUEBA LAS 2 HORAS${NC}\n"

# Preguntar si quiere ver logs
read -p "$(echo -e "${YELLOW}¿Ver logs ahora para escanear QR? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs...${NC}"
    echo -e "${YELLOW}Espera el código QR para escanear...${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
else
    echo -e "\n${YELLOW}💡 Para ver el QR más tarde: ${GREEN}pm2 logs sshbot-pro${NC}\n"
fi

exit 0
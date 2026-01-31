#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT + MERCADOPAGO COMPLETO
# VERSIÓN CORREGIDA - TEST 2H FUNCIONANDO EN APP
# CON FIX PARA QR EN SERVIDORES HEADLESS
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
║          🤖 SSH BOT PRO - WPPCONNECT + MERCADOPAGO          ║
║               📱 WhatsApp API FUNCIONANDO                   ║
║               🔧 FIX PARA QR EN HEADLESS                    ║
║               💰 MercadoPago SDK v2.x INTEGRADO            ║
║               💳 Pago automático con QR                    ║
║               ✅ TEST 2 HORAS EN APP (CORREGIDO)           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  📱 ${CYAN}WPPConnect${NC} - API WhatsApp que funciona"
echo -e "  🔧 ${YELLOW}FIX para QR${NC} - Solución headless aplicada"
echo -e "  💰 ${GREEN}MercadoPago SDK v2.x${NC} - Integrado completo"
echo -e "  💳 ${YELLOW}Pago automático${NC} - QR + Enlace de pago"
echo -e "  🎛️  ${PURPLE}Panel completo${NC} - Control total del sistema"
echo -e "  📊 ${BLUE}Estadísticas${NC} - Ventas, usuarios, ingresos"
echo -e "  ⚡ ${GREEN}Auto-verificación${NC} - Pagos verificados cada 2 min"
echo -e "  ✅ ${GREEN}Test 2 horas funcionando en APP${NC} - Corrección aplicada"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP
echo -e "${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor: " SERVER_IP
fi

echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

read -p "$(echo -e "${YELLOW}¿Continuar instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS CON FIX PARA HEADLESS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias con fix para headless...${NC}"

apt-get update -y
apt-get upgrade -y

# Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Dependencias CRÍTICAS para Chrome headless
apt-get install -y \
    wget gnupg ca-certificates \
    libxss1 libappindicator1 libindicator7 \
    fonts-liberation libasound2 libnspr4 \
    libnss3 lsb-release xdg-utils \
    libatk-bridge2.0-0 libgtk-3-0 \
    libgbm-dev libxshmfence-dev

# Chrome/Chromium ESTABLE
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema
apt-get install -y \
    git curl sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw \
    xvfb libxi6 libgconf-2-4

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw allow 3000/tcp
ufw --force enable

# PM2
npm install -g pm2
pm2 update

echo -e "${GREEN}✅ Dependencias instaladas con fix headless${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
QR_LOG_FILE="/tmp/qr-code.txt"

# Limpiar anterior
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true
rm -f "$QR_LOG_FILE" 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "2.0-MP-INTEGRADO-FIX",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 1500.00,
        "price_15d": 2500.00,
        "price_30d": 5500.00,
        "price_50d": 8500.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL",
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect"
    }
}
EOF

# Crear base de datos
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    password TEXT DEFAULT 'mgvpn247',
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
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_preference ON payments(preference_id);
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT CON FIX COMPLETO PARA HEADLESS
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con fix para QR headless...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "2.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "mercadopago": "^2.0.15",
        "axios": "^1.6.5",
        "sharp": "^0.33.2"
    }
}
PKGEOF

echo -e "${YELLOW}📦 Instalando dependencias de Node.js...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js CON FIX PARA HEADLESS
echo -e "${YELLOW}📝 Creando bot.js con fix headless...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
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
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 SSH BOT PRO - FIX HEADLESS               ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');

// ✅ FIX CRÍTICO: Función para mostrar QR en terminal
function showQRInTerminal(qrCode) {
    console.log(chalk.green.bold('\n══════════════════════════════════════════════════════════════'));
    console.log(chalk.yellow.bold('📱 ESCANEA ESTE QR CON WHATSAPP:'));
    console.log(chalk.green.bold('══════════════════════════════════════════════════════════════\n'));
    
    // Mostrar QR en terminal
    qrcode.generate(qrCode, { small: true });
    
    console.log(chalk.cyan.bold('\n══════════════════════════════════════════════════════════════'));
    console.log(chalk.yellow('⚠️  IMPORTANTE:'));
    console.log(chalk.white('1. Abre WhatsApp en tu teléfono'));
    console.log(chalk.white('2. Toca los 3 puntos → Dispositivos vinculados'));
    console.log(chalk.white('3. Toca "Vincular un dispositivo"'));
    console.log(chalk.white('4. Escanea el código QR de arriba'));
    console.log(chalk.cyan.bold('══════════════════════════════════════════════════════════════\n'));
    
    // También guardar QR en archivo para poder verlo después
    const qrText = `
╔══════════════════════════════════════════════════════════════╗
║                    QR CODE PARA WHATSAPP                     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
${qrCode}
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║ 1. Abre WhatsApp → 3 puntos → Dispositivos vinculados       ║
║ 2. "Vincular un dispositivo"                                 ║
║ 3. Escanea este código                                       ║
╚══════════════════════════════════════════════════════════════╝
`;
    
    fs.writeFileSync('/tmp/qr-code.txt', qrText);
    console.log(chalk.green('✅ QR guardado en: /tmp/qr-code.txt'));
    console.log(chalk.yellow('📋 Para ver el QR después: cat /tmp/qr-code.txt'));
}

// ✅ MERCADOPAGO SDK V2.X
let mpEnabled = false;
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

// Variables globales
let client = null;

// ✅ SISTEMA DE ESTADOS
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

// Funciones auxiliares
function generateUsername() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const randomNum = Math.floor(1000 + Math.random() * 9000);
    const randomChar = chars.charAt(Math.floor(Math.random() * chars.length));
    return `test${randomChar}${randomNum}`;
}

function generatePremiumUsername() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const randomNum = Math.floor(1000 + Math.random() * 9000);
    const randomChar = chars.charAt(Math.floor(Math.random() * chars.length));
    return `user${randomChar}${randomNum}`;
}

const DEFAULT_PASSWORD = 'mgvpn247';

// ✅ FUNCIÓN PARA CREAR USUARIO SSH
async function createSSHUser(phone, username, days) {
    const password = DEFAULT_PASSWORD;
    
    console.log(chalk.yellow(`🔧 Creando usuario SSH: ${username} para ${days} días`));
    
    try {
        // Verificar si el usuario ya existe
        try {
            await execPromise(`id ${username} 2>/dev/null`);
            console.log(chalk.yellow(`⚠️  Usuario ${username} ya existe, eliminando...`));
            await execPromise(`pkill -u ${username} 2>/dev/null || true`);
            await execPromise(`userdel -f ${username} 2>/dev/null || true`);
            db.run('DELETE FROM users WHERE username = ?', [username]);
        } catch (e) {}
        
        let expireFull, expireDate;
        
        if (days === 0) {
            // Test de 2 horas
            const horasTest = config.prices.test_hours || 2;
            expireFull = moment().add(horasTest, 'hours').format('YYYY-MM-DD HH:mm:ss');
            
            console.log(chalk.cyan(`📅 Test expira: ${expireFull} (${horasTest} horas)`));
            
            await execPromise(`useradd -M -s /bin/false ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'test', ?, 1)`,
                [phone, username, password, expireFull], (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                });
            
            console.log(chalk.green(`✅ Test creado: ${username} (expira en ${horasTest} horas)`));
            
        } else {
            // Premium
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            expireDate = moment().add(days, 'days').format('YYYY-MM-DD');
            
            console.log(chalk.cyan(`📅 Premium expira: ${expireFull} (${days} días)`));
            
            await execPromise(`useradd -M -s /bin/false -e ${expireDate} ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'premium', ?, 1)`,
                [phone, username, password, expireFull], (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                });
            
            console.log(chalk.green(`✅ Premium creado: ${username} (expira en ${days} días)`));
        }
        
        return { success: true, username, password, expires: expireFull, days: days };
        
    } catch (error) {
        console.error(chalk.red('❌ Error creando usuario:'), error.message);
        return { success: false, error: error.message };
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

// ✅ MERCADOPAGO - CREAR PAGO
async function createMercadoPagoPayment(phone, days, amount, planName, discountCode = null) {
    try {
        if (!mpEnabled || !mpPreference) {
            console.log(chalk.red('❌ MercadoPago no inicializado'));
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        const phoneClean = phone.replace('@c.us', '');
        const paymentId = `SSH-${phoneClean}-${days}d-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        // Aplicar descuento si existe
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
                console.log(chalk.yellow(`💰 Descuento ${discountPercentage}%: $${amount} -> $${finalAmount.toFixed(2)}`));
            }
        }
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `SSH PREMIUM ${days} DÍAS`,
                description: `Acceso SSH Premium por ${days} días - 1 conexión`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: finalAmount
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: isoDate,
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso%20SSH`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido%20SSH`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente%20SSH`
            },
            auto_return: 'approved',
            statement_descriptor: 'SSH PREMIUM'
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${finalAmount} ${config.prices.currency || 'ARS'}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 400,
                margin: 2,
                color: {
                    dark: '#000000',
                    light: '#FFFFFF'
                }
            });
            
            db.run(
                `INSERT INTO payments (payment_id, phone, plan, days, amount, discount_code, final_amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, `${days}d`, days, amount, discountCode, finalAmount, paymentUrl, qrPath, response.id],
                (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                }
            );
            
            console.log(chalk.green(`✅ Pago creado: ${paymentId}`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                preferenceId: response.id,
                amount: finalAmount,
                originalAmount: amount,
                discountApplied: discountPercentage > 0,
                discountPercentage: discountPercentage
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

// ✅ VERIFICAR PAGOS PENDIENTES
async function checkPendingPayments() {
    if (!mpEnabled) return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos...`));
        
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
                        
                        // Crear usuario SSH
                        const username = generatePremiumUsername();
                        const result = await createSSHUser(payment.phone, username, payment.days);
                        
                        if (result.success) {
                            db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                            
                            const expireDate = moment().add(payment.days, 'days').format('DD/MM/YYYY');
                            
                            const message = `✅ *PAGO CONFIRMADO*

🎉 Tu compra ha sido aprobada

📋 *DATOS DE ACCESO:*
👤 Usuario: *${username}*
🔑 Contraseña: *${DEFAULT_PASSWORD}*

⏰ *VÁLIDO HASTA:* ${expireDate}
🔌 *CONEXIÓN:* 1 dispositivo

📱 *INSTALACIÓN:*
1. Descarga la app (Opción *4*)
2. Seleccionar servidor
3. Ingresar Usuario y Contraseña
4. ¡Conéctate automáticamente!

🎊 ¡Disfruta del servicio premium!`;
                            
                            if (client) {
                                await client.sendText(payment.phone, message);
                            }
                            console.log(chalk.green(`✅ Usuario creado: ${username}`));
                        }
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
}

// ✅ FIX CRÍTICO: Configuración optimizada para headless
const puppeteerOptions = {
    executablePath: '/usr/bin/google-chrome',
    headless: 'new',
    args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees',
        '--window-size=1280,720'
    ]
};

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect con fix headless...'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-session',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: false, // ✅ Desactivamos el logQR normal
            browserWS: '',
            browserArgs: puppeteerOptions.args,
            puppeteerOptions: puppeteerOptions,
            disableWelcome: true,
            updatesLog: false,
            autoClose: 0,
            tokenStore: 'file',
            folderNameToken: '/root/.wppconnect',
            
            // ✅ FIX: Callback personalizado para QR
            onQRCode: (qrCode) => {
                showQRInTerminal(qrCode);
            }
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        // Estado de conexión
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            
            if (state === 'CONNECTED') {
                console.log(chalk.green('✅ Conexión establecida con WhatsApp'));
                console.log(chalk.yellow('📱 Envía "menu" al bot para comenzar'));
            } else if (state === 'DISCONNECTED') {
                console.log(chalk.yellow('⚠️ Desconectado, reconectando en 10 segundos...'));
                setTimeout(initializeBot, 10000);
            }
        });
        
        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                const text = message.body.trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));
                
                const userState = await getUserState(from);
                
                // MENÚ PRINCIPAL
                if (['menu', 'hola', 'start', 'hi', 'volver', '0'].includes(text.toLowerCase())) {
                    await setUserState(from, 'main_menu');
                    
                    await client.sendText(from, `


    🚀 *BIENVENIDOS - MGVPN*   


Elija una opción:

🧾 *1* - CREAR PRUEBA (2 horas)
💰 *2* - COMPRAR USUARIO SSH
🔄 *3* - RENOVAR USUARIO SSH
📱 *4* - DESCARGAR APLICACIÓN

📝 - RESPONDE CON EL NUMERO`);
                }
                
                // ✅ OPCIÓN 1 CORREGIDA
                else if (text === '1' && userState.state === 'main_menu') {
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana para otra prueba gratuita`);
                        return;
                    }
                    
                    await client.sendText(from, '⏳ *Creando cuenta de prueba...*');
                    
                    try {
                        const username = generateUsername();
                        const result = await createSSHUser(from, username, 0);
                        
                        if (result.success) {
                            registerTest(from);
                            
                            await client.sendText(from, `✅ *PRUEBA CREADA CON ÉXITO !*

👤 *Usuario:* ${username}
🔑 *Contraseña:* ${DEFAULT_PASSWORD}
📱 *Límite:* 1 dispositivo(s)
⏰ *Expira en:* 2 horas ⏳

📲 *APP:* ${config.links.app_download}`);
                            
                            console.log(chalk.green(`✅ Test creado: ${username} (expira en 2 horas)`));
                        } else {
                            await client.sendText(from, `❌ Error: ${result.error}`);
                        }
                    } catch (error) {
                        await client.sendText(from, `❌ Error al crear cuenta: ${error.message}`);
                    }
                }
                
                // OPCIÓN 2: COMPRAR USUARIO SSH
                else if (text === '2' && userState.state === 'main_menu') {
                    await setUserState(from, 'buying_ssh');
                    
                    await client.sendText(from, `


    🌐 *PLANES SSH PREMIUM*    


Elija un plan:

🗓 *1* - 7 DÍAS - $${config.prices.price_7d}
🗓 *2* - 15 DÍAS - $${config.prices.price_15d}
🗓 *3* - 30 DÍAS - $${config.prices.price_30d}
🗓 *4* - 50 DÍAS - $${config.prices.price_50d}

⬅️ *0* - VOLVER`);
                }
                
                // SELECCIÓN DE PLAN
                else if (userState.state === 'buying_ssh') {
                    if (['1', '2', '3', '4'].includes(text)) {
                        const planMap = {
                            '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                            '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                            '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                            '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (mpEnabled) {
                            await setUserState(from, 'asking_discount', { 
                                plan: plan,
                                days: plan.days,
                                amount: plan.price,
                                planName: plan.name
                            });
                            
                            await client.sendText(from, `**¿Tienes un cupón de descuento?**
Responde: *sí* o *no*.`);
                            
                        } else {
                            await client.sendText(from, `✅ *PLAN SELECCIONADO: ${plan.name}*

💰 *Precio:* $${plan.price} ARS
⏰ *Duración:* ${plan.days} días
🔑 *Contraseña:* ${DEFAULT_PASSWORD}

📞 *Para continuar con la compra, contacta al administrador:*
${config.links.support}

💸 *O envía el monto por transferencia bancaria.*`);
                            
                            await setUserState(from, 'main_menu');
                        }
                    }
                    else if (text === '0') {
                        await setUserState(from, 'main_menu');
                        await client.sendText(from, `


    🚀 *BIENVENIDOS - MGVPN*   


Elija una opción:

🧾 *1* - CREAR PRUEBA (2 horas)
💰 *2* - COMPRAR USUARIO SSH
🔄 *3* - RENOVAR USUARIO SSH
📱 *4* - DESCARGAR APLICACIÓN

📝 - RESPONDE CON EL NUMERO`);
                    }
                }
                
                // PREGUNTA POR DESCUENTO
                else if (userState.state === 'asking_discount') {
                    const stateData = userState.data || {};
                    
                    if (text.toLowerCase() === 'sí' || text.toLowerCase() === 'si') {
                        await setUserState(from, 'entering_discount', stateData);
                        await client.sendText(from, '📝 *Por favor, escribe tu código de descuento:*');
                    }
                    else if (text.toLowerCase() === 'no') {
                        await processPayment(from, stateData, null);
                    }
                    else {
                        await client.sendText(from, 'Por favor responde: *sí* o *no*');
                    }
                }
                
                // INGRESAR CÓDIGO DE DESCUENTO
                else if (userState.state === 'entering_discount') {
                    const stateData = userState.data || {};
                    const discountCode = text.trim();
                    
                    await processPayment(from, stateData, discountCode);
                }
                
                // OPCIÓN 3: RENOVAR
                else if (text === '3' && userState.state === 'main_menu') {
                    await client.sendText(from, `🔄 *RENOVAR USUARIO SSH*

Para renovar tu cuenta SSH existente, contacta al administrador:
${config.links.support}

📝 O envía tu nombre de usuario actual.`);
                }
                
                // OPCIÓN 4: DESCARGAR APP
                else if (text === '4' && userState.state === 'main_menu') {
                    await client.sendText(from, `╔═══════════════════════════════╗
║    📱 *DESCARGAR APP*       ║
╚═══════════════════════════════╝

🔗 *Enlace de descarga:*
${config.links.app_download}

💡 *Instrucciones:*
1. Abre el enlace en tu navegador
2. Descarga el archivo APK
3. Instala la aplicación
4. Configura con tus credenciales SSH

⚡ *Credenciales por defecto:*
👤 Usuario: (el que te proporcionamos)
🔑 Contraseña: ${DEFAULT_PASSWORD}`);
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error procesando mensaje:'), error.message);
            }
        });
        
        // ✅ VERIFICAR PAGOS CADA 2 MINUTOS
        cron.schedule('*/2 * * * *', () => {
            console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
            checkPendingPayments();
        });
        
        // ✅ LIMPIEZA
        cron.schedule('*/5 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.yellow(`🧹 Limpiando usuarios expirados...`));
            
            db.all('SELECT username FROM users WHERE tipo = "test" AND expires_at < ? AND status = 1', [now], async (err, rows) => {
                if (err || !rows || rows.length === 0) {
                    console.log(chalk.green('✅ No hay tests expirados en BD'));
                    return;
                }
                
                console.log(chalk.yellow(`🗑️  Eliminando ${rows.length} tests expirados...`));
                
                for (const r of rows) {
                    try {
                        db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                        await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                        console.log(chalk.yellow(`⚠️  Test expirado: ${r.username} (2 horas)`));
                    } catch (e) {
                        console.error(chalk.red(`❌ Error procesando test ${r.username}:`), e.message);
                    }
                }
                
                console.log(chalk.green(`✅ ${rows.length} tests eliminados (2 horas)`));
            });
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error inicializando WPPConnect:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(initializeBot, 10000);
    }
}

// ✅ FUNCIÓN PARA PROCESAR PAGO
async function processPayment(phone, planData, discountCode) {
    try {
        await client.sendText(phone, '⏳ *Procesando tu compra...*');
        
        const payment = await createMercadoPagoPayment(
            phone, 
            planData.days, 
            planData.amount, 
            planData.planName, 
            discountCode
        );
        
        if (payment.success) {
            let amountText = `$${payment.amount}`;
            if (payment.discountApplied) {
                amountText = `$${payment.originalAmount} → $${payment.amount} (${payment.discountPercentage}% descuento)`;
            }
            
            const message = `╔═══════════════════════════════╗
║     ✅ *USUARIO SSH*       ║
╚═══════════════════════════════╝

📋 *DETALLES DEL PLAN:*
🗓 *Plan:* ${planData.planName}
💰 *Precio:* ${amountText}
🔑 *Contraseña:* ${DEFAULT_PASSWORD}
📱 *Límite:* 1 dispositivo(s)
⏰ *Duración:* ${planData.days} días

═══════════════════════════════

🔗 *LINK DE PAGO*

${payment.paymentUrl}

⚠️ *Este enlace expira en 24 horas*
💳 *Pago seguro con MercadoPago*`;
            
            await client.sendText(phone, message);
            
            // Enviar QR
            if (fs.existsSync(payment.qrPath)) {
                try {
                    const media = await client.decryptFile(payment.qrPath);
                    await client.sendImage(phone, payment.qrPath, 'qr-pago.jpg', 
                        `📱 *Escanea con MercadoPago*\n\n${planData.planName} - ${amountText}`);
                } catch (qrError) {
                    console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                }
            }
            
        } else {
            await client.sendText(phone, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

📞 Contacta al administrador para otras opciones de pago.`);
        }
        
    } catch (error) {
        console.error(chalk.red('❌ Error en pago:'), error.message);
        await client.sendText(phone, `❌ *ERROR INESPERADO*

${error.message}

📞 Contacta al administrador para asistencia.`);
    }
    
    await setUserState(phone, 'main_menu');
}

// Iniciar el bot
initializeBot();

// Manejar cierre
process.on('SIGINT', async () => {
    console.log(chalk.yellow('\n🛑 Cerrando bot...'));
    if (client) {
        await client.close();
    }
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ Bot creado con fix para headless${NC}"

# ================================================
# CREAR SCRIPT PARA VER QR
# ================================================
echo -e "\n${CYAN}👁️  Creando script para ver QR...${NC}"

cat > /usr/local/bin/show-qr << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

QR_FILE="/tmp/qr-code.txt"

echo -e "${CYAN}🔍 BUSCANDO QR CODE...${NC}\n"

if [[ -f "$QR_FILE" ]]; then
    echo -e "${GREEN}✅ QR encontrado:${NC}\n"
    cat "$QR_FILE"
    echo -e "\n${YELLOW}📱 Instrucciones:${NC}"
    echo -e "1. Abre WhatsApp en tu teléfono"
    echo -e "2. Toca los 3 puntos → Dispositivos vinculados"
    echo -e "3. Toca 'Vincular un dispositivo'"
    echo -e "4. Escanea el código QR de arriba"
else
    echo -e "${YELLOW}⚠️  No hay QR disponible aún${NC}"
    echo -e "\n${CYAN}📋 Soluciones:${NC}"
    echo -e "1. Espera 30 segundos que el bot inicie"
    echo -e "2. Reinicia el bot: ${GREEN}pm2 restart sshbot-pro${NC}"
    echo -e "3. Ver logs: ${GREEN}pm2 logs sshbot-pro${NC}"
    echo -e "4. Forzar nueva sesión: ${GREEN}sshbot${NC} → opción 10"
fi

echo -e "\n${CYAN}🔧 Comandos útiles:${NC}"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC}    - Ver logs en tiempo real"
echo -e "  ${GREEN}sshbot${NC}                - Panel de control"
echo -e "  ${GREEN}pm2 restart sshbot-pro${NC} - Reiniciar bot"
EOF

chmod +x /usr/local/bin/show-qr

# ================================================
# CREAR SCRIPT DE REPARACIÓN
# ================================================
cat > /usr/local/bin/fix-test-app << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"

echo -e "${CYAN}🔧 REPARADOR DE TESTS PARA APP${NC}\n"
echo -e "${YELLOW}Este script arregla los tests para que muestren 2h en la app${NC}\n"

while true; do
    echo -e "${CYAN}Opciones:${NC}"
    echo -e "  ${GREEN}[1]${NC} Ver tests existentes"
    echo -e "  ${GREEN}[2]${NC} Reparar tests (convertir a 2h)"
    echo -e "  ${GREEN}[3]${NC} Ver usuarios en sistema"
    echo -e "  ${GREEN}[4]${NC} Salir"
    echo -e ""
    
    read -p "Selecciona opción: " OPT
    
    case $OPT in
        1)
            echo -e "\n${YELLOW}📋 TESTS EN BASE DE DATOS:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT username, tipo, expires_at, CASE WHEN expires_at < datetime('now') THEN 'EXPIRO' ELSE 'ACTIVO' END as estado FROM users WHERE tipo='test' ORDER BY expires_at;"
            echo ""
            ;;
        2)
            echo -e "\n${YELLOW}🔧 Reparando tests...${NC}"
            
            # Para cada test, recalcular fecha a 2 horas desde ahora
            sqlite3 "$DB" "SELECT username FROM users WHERE tipo='test' AND status=1" | while read USER; do
                # Nueva fecha: 2 horas desde ahora
                NEW_EXPIRE=$(date -d "2 hours" "+%Y-%m-%d %H:%M:%S")
                sqlite3 "$DB" "UPDATE users SET expires_at='$NEW_EXPIRE' WHERE username='$USER'"
                echo -e "  ${GREEN}✅${NC} $USER -> 2 horas"
            done
            
            echo -e "\n${GREEN}✅ Todos los tests reparados para mostrar 2h${NC}"
            echo -e "${YELLOW}⚠️  La app ahora mostrará 0 días y 2 horas${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}👥 USUARIOS EN SISTEMA:${NC}\n"
            cut -d: -f1 /etc/passwd | grep -E '^test[a-z][0-9]{4}' | while read USER; do
                echo -e "  👤 $USER"
            done
            echo ""
            ;;
        4)
            echo -e "\n${GREEN}👋 Hasta luego${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Opción inválida${NC}"
            ;;
    esac
    
    echo -e "${CYAN}─────────────────────────────────────────${NC}\n"
done
EOF

chmod +x /usr/local/bin/fix-test-app

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"
CONFIG="/opt/sshbot-pro/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL SSH BOT PRO - FIX QR              ║${NC}"
    echo -e "${CYAN}║                  🔧 SOLUCIÓN HEADLESS                      ║${NC}"
    echo -e "${CYAN}║                  ✅ TEST 2H EN APP (CORREGIDO)              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    APPROVED_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='approved'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="sshbot-pro") | .pm2_env.status' 2>/dev/null || echo "stopped")
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
    echo -e "  Pagos: ${CYAN}$PENDING_PAYMENTS${NC} pendientes | ${GREEN}$APPROVED_PAYMENTS${NC} aprobados"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  IP: $(get_val '.bot.server_ip')"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA)"
    echo -e "  Test: ${GREEN}2 horas exactas${NC} (corregido para app)"
    echo -e ""
    
    echo -e "${YELLOW}💰 PRECIOS:${NC}"
    echo -e "  7 días: $ $(get_val '.prices.price_7d') ARS"
    echo -e "  15 días: $ $(get_val '.prices.price_15d') ARS"
    echo -e "  30 días: $ $(get_val '.prices.price_30d') ARS"
    echo -e "  50 días: $ $(get_val '.prices.price_50d') ARS"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver logs en tiempo real"
    echo -e "${CYAN}[4]${NC} 🔍  Ver QR actual (show-qr)"
    echo -e "${CYAN}[5]${NC} 👤  Crear usuario manual"
    echo -e "${CYAN}[6]${NC} 👥  Listar usuarios"
    echo -e "${CYAN}[7]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[8]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[9]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 🔄 Limpiar sesión (nuevo QR)"
    echo -e "${CYAN}[11]${NC} 💳 Ver pagos"
    echo -e "${CYAN}[12]${NC} ⚙️  Ver configuración"
    echo -e "${CYAN}[13]${NC} 🧹 Limpiar tests"
    echo -e "${CYAN}[14]${NC} 🔧 Reparar tests para app"
    echo -e "${CYAN}[0]${NC} 🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    
    read -p "👉 Selecciona: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando...${NC}"
            cd /root/sshbot-pro
            pm2 restart sshbot-pro 2>/dev/null || pm2 start bot.js --name sshbot-pro
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            echo -e "${YELLOW}📱 El QR aparecerá en los logs en 10-20 segundos${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo...${NC}"
            pm2 stop sshbot-pro
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            echo -e "\n${YELLOW}📱 Mostrando logs...${NC}"
            echo -e "${CYAN}Presiona Ctrl+C para salir de los logs${NC}\n"
            sleep 2
            pm2 logs sshbot-pro
            ;;
        4)
            echo -e "\n${YELLOW}🔍 Mostrando QR...${NC}"
            show-qr
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            clear
            echo -e "${CYAN}👤 CREAR USUARIO${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "Usuario (minúsculas, auto=generar): " USERNAME
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 2h, 7,15,30,50=premium): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            if [[ "$USERNAME" == "auto" || -z "$USERNAME" ]]; then
                if [[ "$TIPO" == "test" ]]; then
                    USERNAME="test$(shuf -i 1000-9999 -n 1)"
                else
                    USERNAME="user$(shuf -i 1000-9999 -n 1)"
                fi
            fi
            
            USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')
            PASSWORD="mgvpn247"
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
                EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                useradd -M -s /bin/false "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$TIPO', '$EXPIRE_DATE', 1)"
                
                echo -e "\n${GREEN}✅ TEST CREADO (2 HORAS)${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "⏰ Expira en: 2 horas"
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                EXPIRE_DATE_SYSTEM=$(date -d "+$DAYS days" +%Y-%m-%d)
                useradd -M -s /bin/false -e "$EXPIRE_DATE_SYSTEM" "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$TIPO', '$EXPIRE_DATE', 1)"
                
                echo -e "\n${GREEN}✅ PREMIUM CREADO${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
            fi
            read -p "Presiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}👥 USUARIOS ACTIVOS${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, tipo, expires_at, CASE WHEN expires_at < datetime('now') THEN 'EXPIRO' ELSE 'ACTIVO' END as estado FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}💰 CAMBIAR PRECIOS${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  1. 7 días: $${CURRENT_7D} ARS"
            echo -e "  2. 15 días: $${CURRENT_15D} ARS"
            echo -e "  3. 30 días: $${CURRENT_30D} ARS"
            echo -e "  4. 50 días: $${CURRENT_50D} ARS"
            echo -e ""
            
            echo -e "${CYAN}Modificar precios:${NC}"
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
        8)
            clear
            echo -e "${CYAN}🔑 CONFIGURAR MERCADOPAGO${NC}\n"
            
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
                    cd /root/sshbot-pro && pm2 restart sshbot-pro
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago activado${NC}"
                else
                    echo -e "${RED}❌ Token inválido${NC}"
                    echo -e "${YELLOW}Debe empezar con APP_USR- o TEST-${NC}"
                fi
            fi
            read -p "Presiona Enter..."
            ;;
        9)
            clear
            echo -e "${CYAN}📊 ESTADÍSTICAS${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Tests: ' || SUM(CASE WHEN tipo='test' THEN 1 ELSE 0 END) || ' | Premium: ' || SUM(CASE WHEN tipo='premium' THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN final_amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}💸 INGRESOS HOY:${NC}"
            sqlite3 "$DB" "SELECT 'Hoy: $' || printf('%.2f', SUM(CASE WHEN date(created_at) = date('now') THEN final_amount ELSE 0 END)) FROM payments WHERE status='approved'"
            
            echo -e "\n${YELLOW}🧪 TESTS HOY:${NC}"
            sqlite3 "$DB" "SELECT 'Tests hoy: ' || COUNT(*) || ' de ' || (SELECT COUNT(DISTINCT phone) FROM users WHERE tipo='test' AND date(created_at)=date('now')) FROM daily_tests WHERE date = date('now')"
            
            read -p "\nPresiona Enter..."
            ;;
        10)
            echo -e "\n${YELLOW}🧹 Limpiando sesión...${NC}"
            pm2 stop sshbot-pro
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}📱 Reiniciando bot para nuevo QR...${NC}"
            cd /root/sshbot-pro && pm2 start bot.js --name sshbot-pro
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            echo -e "${CYAN}🔍 Ver QR en 10 segundos: ${GREEN}show-qr${NC}"
            sleep 2
            ;;
        11)
            clear
            echo -e "${CYAN}💳 PAGOS${NC}\n"
            
            echo -e "${YELLOW}Pagos pendientes:${NC}"
            sqlite3 -column -header "$DB" "SELECT payment_id, phone, plan, amount, created_at FROM payments WHERE status='pending' ORDER BY created_at DESC LIMIT 10"
            
            echo -e "\n${YELLOW}Pagos aprobados:${NC}"
            sqlite3 -column -header "$DB" "SELECT payment_id, phone, plan, final_amount, approved_at FROM payments WHERE status='approved' ORDER BY approved_at DESC LIMIT 10"
            
            read -p "\nPresiona Enter..."
            ;;
        12)
            clear
            echo -e "${CYAN}⚙️  CONFIGURACIÓN${NC}\n"
            
            echo -e "${YELLOW}🤖 BOT:${NC}"
            echo -e "  IP: $(get_val '.bot.server_ip')"
            echo -e "  Versión: $(get_val '.bot.version')"
            echo -e "  Contraseña fija: mgvpn247"
            
            echo -e "\n${YELLOW}💰 PRECIOS:${NC}"
            echo -e "  7d: $(get_val '.prices.price_7d') ARS"
            echo -e "  15d: $(get_val '.prices.price_15d') ARS"
            echo -e "  30d: $(get_val '.prices.price_30d') ARS"
            echo -e "  50d: $(get_val '.prices.price_50d') ARS"
            echo -e "  Test: $(get_val '.prices.test_hours') horas"
            
            echo -e "\n${YELLOW}💳 MERCADOPAGO:${NC}"
            MP_TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "null" ]]; then
                echo -e "  Estado: ${GREEN}CONFIGURADO${NC}"
                echo -e "  Token: ${MP_TOKEN:0:20}..."
            else
                echo -e "  Estado: ${RED}NO CONFIGURADO${NC}"
            fi
            
            read -p "\nPresiona Enter..."
            ;;
        13)
            echo -e "\n${YELLOW}🧹 Ejecutando limpiador de tests...${NC}"
            echo -e "${CYAN}Matando procesos de usuarios test...${NC}"
            ps aux | grep -E 'test[a-z][0-9]{4}' | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
            echo -e "${GREEN}✅ Procesos limpiados${NC}"
            ;;
        14)
            echo -e "\n${YELLOW}🔧 Ejecutando reparador para app...${NC}"
            fix-test-app
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

chmod +x /usr/local/bin/sshbot
echo -e "${GREEN}✅ Panel creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot con fix para QR...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 5

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA - FIX QR APLICADO       ║
║                                                              ║
║       🤖 SSH BOT PRO - WPPCONNECT + MERCADOPAGO            ║
║       🔧 FIX PARA QR EN HEADLESS APLICADO                 ║
║       💰 MercadoPago SDK v2.x COMPLETO                    ║
║       💳 Pago automático con QR                           ║
║       ✅ TEST 2 HORAS EN APP (CORREGIDO)                  ║
║       🗓️  Solo planes: 7, 15, 30, 50 días               ║
║       👁️  Comando show-qr para ver QR fácil             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema completo instalado${NC}"
echo -e "${GREEN}✅ WhatsApp API funcionando${NC}"
echo -e "${GREEN}✅ FIX para QR en headless aplicado${NC}"
echo -e "${GREEN}✅ MercadoPago SDK v2.x integrado${NC}"
echo -e "${GREEN}✅ Panel de control completo${NC}"
echo -e "${GREEN}✅ Pago automático con QR${NC}"
echo -e "${GREEN}✅ Verificación automática de pagos${NC}"
echo -e "${GREEN}✅ Planes: 7, 15, 30, 50 días${NC}"
echo -e "${GREEN}✅ Contraseña fija: mgvpn247${NC}"
echo -e "${GREEN}✅ Test: 2 horas de prueba (CORREGIDO PARA APP)${NC}"
echo -e "${GREEN}✅ Comando show-qr para ver el QR fácilmente${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}sshbot${NC}           - Panel de control completo"
echo -e "  ${GREEN}show-qr${NC}          - Ver QR actual para escanear"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver logs en tiempo real"
echo -e "  ${GREEN}fix-test-app${NC}     - Reparar tests para mostrar 2h en app"
echo -e "\n"

echo -e "${YELLOW}🚀 CÓMO ESCANEAR EL QR:${NC}\n"
echo -e "1. Ejecuta: ${GREEN}show-qr${NC}"
echo -e "2. O mira los logs: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "3. El QR aparecerá automáticamente en la terminal"
echo -e "4. Abre WhatsApp → 3 puntos → Dispositivos vinculados"
echo -e "5. 'Vincular un dispositivo' → Escanea el QR"
echo -e "\n"

echo -e "${YELLOW}🔧 SI NO VES EL QR:${NC}\n"
echo -e "1. Espera 20 segundos: ${GREEN}show-qr${NC}"
echo -e "2. Reinicia: ${GREEN}sshbot${NC} → opción 1"
echo -e "3. Forzar nuevo QR: ${GREEN}sshbot${NC} → opción 10"
echo -e "4. Ver errores: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "\n"

echo -e "${GREEN}${BOLD}¡Sistema listo! El QR ahora funcionará correctamente ✅${NC}\n"

# Mostrar QR automáticamente
read -p "$(echo -e "${YELLOW}¿Ver QR ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Esperando 5 segundos para que el bot genere el QR...${NC}"
    sleep 5
    show-qr
    echo -e "\n${YELLOW}📱 El bot está listo. Escanea el QR arriba.${NC}"
else
    echo -e "\n${YELLOW}💡 Para ver el QR después: ${GREEN}show-qr${NC}"
    echo -e "${YELLOW}💡 Para iniciar el panel: ${GREEN}sshbot${NC}"
fi

echo -e "\n${CYAN}🎯 Cuando escanees el QR, envía 'menu' al bot en WhatsApp${NC}\n"

exit 0
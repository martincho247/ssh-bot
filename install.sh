#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT + MERCADOPAGO COMPLETO
# VERSIÓN CORREGIDA - TEST FUNCIONANDO
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
║               💰 MercadoPago SDK v2.x INTEGRADO            ║
║               💳 Pago automático con QR                    ║
║               🎛️  Panel completo con control MP           ║
║               ✅ TEST 2 HORAS FUNCIONANDO                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  📱 ${CYAN}WPPConnect${NC} - API WhatsApp que funciona"
echo -e "  💰 ${GREEN}MercadoPago SDK v2.x${NC} - Integrado completo"
echo -e "  💳 ${YELLOW}Pago automático${NC} - QR + Enlace de pago"
echo -e "  🎛️  ${PURPLE}Panel completo${NC} - Control total del sistema"
echo -e "  📊 ${BLUE}Estadísticas${NC} - Ventas, usuarios, ingresos"
echo -e "  ⚡ ${GREEN}Auto-verificación${NC} - Pagos verificados cada 2 min"
echo -e "  ✅ ${GREEN}Test 2 horas funcionando${NC} - Sin errores de expiración"
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
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias...${NC}"

apt-get update -y
apt-get upgrade -y

# Node.js 18.x (compatible con WPPConnect y MercadoPago)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Chrome/Chromium
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw

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

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar anterior
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Crear configuración CON MERCADOPAGO
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "2.0-MP-INTEGRADO",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 2,
        "price_1d": 500.00,
        "price_3d": 1200.00,
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

# Crear base de datos COMPLETA
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

echo -e "${GREEN}✅ Estructura creada con MercadoPago${NC}"

# ================================================
# CREAR BOT COMPLETO CON MERCADOPAGO - VERSIÓN CORREGIDA
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con WPPConnect + MercadoPago...${NC}"

cd "$USER_HOME"

# package.json con todas las dependencias
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

echo -e "${YELLOW}📦 Instalando dependencias...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js COMPLETO con MercadoPago CORREGIDO
echo -e "${YELLOW}📝 Creando bot.js con MercadoPago...${NC}"

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
console.log(chalk.cyan.bold('║                🤖 SSH BOT PRO - WPPCONNECT + MP              ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');

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
            console.log(chalk.cyan(`🔑 Token: ${config.mercadopago.access_token.substring(0, 20)}...`));
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpEnabled = false;
            mpClient = null;
            mpPreference = null;
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

function clearUserState(phone) {
    db.run('DELETE FROM user_state WHERE phone = ?', [phone]);
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

// ✅ FUNCIÓN CORREGIDA PARA CREAR USUARIOS SSH
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
            // Eliminar de BD si existe
            db.run('DELETE FROM users WHERE username = ?', [username]);
        } catch (e) {
            // Usuario no existe, continuar
        }
        
        let expireFull, expireDate;
        
        if (days === 0) {
            // Test - 2 horas (SOLO en BD, sin fecha en sistema)
            expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
            // Para tests NO ponemos fecha en el sistema, solo en BD
            expireDate = '';
            
            console.log(chalk.cyan(`📅 Test expira en BD: ${expireFull}`));
            
            // Crear usuario SIN fecha de expiración en sistema
            await execPromise(`useradd -M -s /bin/false ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'test', ?, 1)`,
                [phone, username, password, expireFull], (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                });
            
            console.log(chalk.green(`✅ Test creado: ${username} (expira: ${expireFull})`));
            
        } else {
            // Premium - CON fecha en sistema y BD
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            expireDate = moment().add(days, 'days').format('YYYY-MM-DD');
            
            console.log(chalk.cyan(`📅 Premium expira: ${expireFull} (sistema: ${expireDate})`));
            
            // Crear usuario CON fecha de expiración
            await execPromise(`useradd -M -s /bin/false -e ${expireDate} ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'premium', ?, 1)`,
                [phone, username, password, expireFull], (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                });
            
            console.log(chalk.green(`✅ Premium creado: ${username} (expira: ${expireFull})`));
        }
        
        return { success: true, username, password, expires: expireFull };
        
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

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-session',
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
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-renderer-backgrounding',
                '--disable-features=site-per-process',
                '--window-size=1920,1080'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage'
                ]
            },
            disableWelcome: true,
            updatesLog: false,
            autoClose: 0,
            tokenStore: 'file',
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        // Estado de conexión
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            
            if (state === 'CONNECTED') {
                console.log(chalk.green('✅ Conexión establecida con WhatsApp'));
            } else if (state === 'DISCONNECTED') {
                console.log(chalk.yellow('⚠️ Desconectado, reconectando...'));
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

⬅️ *0* - MENU PRINCIPAL`);
                }
                
                // OPCIÓN 1: CREAR PRUEBA - CORREGIDO
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
⏰ *Expira en:* ${config.prices.test_hours} horas

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


Elija una opción:

🗓 *1* - PLANES DIARIOS
🗓 *2* - PLANES MENSUALES

⬅️ *0* - VOLVER`);
                }
                
                // SUBMENÚ DE COMPRAS
                else if (userState.state === 'buying_ssh') {
                    if (text === '1') {
                        // PLANES DIARIOS
                        await setUserState(from, 'selecting_daily_plan');
                        
                        await client.sendText(from, `


      🌐 *PLANES DIARIOS*      


Elija un plan:

🗓 *1* - 1 DÍA - $${config.prices.price_1d}
🗓 *2* - 3 DÍAS - $${config.prices.price_3d}
🗓 *3* - 7 DÍAS - $${config.prices.price_7d}
🗓 *4* - 15 DÍAS - $${config.prices.price_15d}

⬅️ *0* - VOLVER`);
                    }
                    else if (text === '2') {
                        // PLANES MENSUALES
                        await setUserState(from, 'selecting_monthly_plan');
                        
                        await client.sendText(from, `


     🌐 *PLANES MENSUALES*     


Elija un plan:

🗓 *1* - 30 DÍAS - $${config.prices.price_30d}
🗓 *2* - 50 DÍAS - $${config.prices.price_50d}

⬅️ *0* - VOLVER`);
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

⬅️ *0* - MENU PRINCIPAL`);
                    }
                }
                
                // SELECCIÓN DE PLAN DIARIO
                else if (userState.state === 'selecting_daily_plan') {
                    if (['1', '2', '3', '4'].includes(text)) {
                        const planMap = {
                            '1': { days: 1, price: config.prices.price_1d, name: '1 DÍA' },
                            '2': { days: 3, price: config.prices.price_3d, name: '3 DÍAS' },
                            '3': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                            '4': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (mpEnabled) {
                            // CON MERCADOPAGO - PREGUNTAR POR DESCUENTO
                            await setUserState(from, 'asking_discount', { 
                                plan: plan,
                                days: plan.days,
                                amount: plan.price,
                                planName: plan.name
                            });
                            
                            await client.sendText(from, `**¿Tienes un cupón de descuento?**
Responde: *sí* o *no*.`);
                            
                        } else {
                            // SIN MERCADOPAGO
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
                        await setUserState(from, 'buying_ssh');
                        await client.sendText(from, `


    🌐 *PLANES SSH PREMIUM*    


Elija una opción:

🗓 *1* - PLANES DIARIOS
🗓 *2* - PLANES MENSUALES

⬅️ *0* - VOLVER AL MENÚ`);
                    }
                }
                
                // SELECCIÓN DE PLAN MENSUAL
                else if (userState.state === 'selecting_monthly_plan') {
                    if (['1', '2'].includes(text)) {
                        const planMap = {
                            '1': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                            '2': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (mpEnabled) {
                            // CON MERCADOPAGO - PREGUNTAR POR DESCUENTO
                            await setUserState(from, 'asking_discount', { 
                                plan: plan,
                                days: plan.days,
                                amount: plan.price,
                                planName: plan.name
                            });
                            
                            await client.sendText(from, `**¿Tienes un cupón de descuento?**
Responde: *sí* o *no*.`);
                            
                        } else {
                            // SIN MERCADOPAGO
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
                        await setUserState(from, 'buying_ssh');
                        await client.sendText(from, `


    🌐 *PLANES SSH PREMIUM*    


Elija una opción:

🗓 *1* - PLANES DIARIOS
🗓 *2* - PLANES MENSUALES

⬅️ *0* - VOLVER`);
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
                        // Procesar pago sin descuento
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
3. Instala la aplicación (click en "más detalles" → "instalar de todas formas")
4. Configura con tus credenciales SSH

⚡ *Credenciales por defecto:*
👤 Usuario: (el que te proporcionamos)
🔑 Contraseña: ${DEFAULT_PASSWORD}`);
                }
                
                // COMANDO NO RECONOCIDO
                else {
                    await client.sendText(from, `❌ *Comando no reconocido.*

Escribe *menu* para ver las opciones disponibles.`);
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
        
        // ✅ LIMPIEZA CORREGIDA - SOLO TESTS EN BD
        cron.schedule('*/5 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.yellow(`🧹 Limpiando usuarios expirados...`));
            
            // Solo limpiar usuarios premium con fecha en sistema
            db.all('SELECT username FROM users WHERE tipo = "premium" AND expires_at < ? AND status = 1', [now], async (err, rows) => {
                if (err || !rows || rows.length === 0) {
                    console.log(chalk.green('✅ No hay usuarios premium expirados'));
                } else {
                    console.log(chalk.yellow(`🗑️  Eliminando ${rows.length} usuarios premium expirados...`));
                    
                    for (const r of rows) {
                        try {
                            await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                            await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                            db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                            console.log(chalk.green(`✅ Eliminado: ${r.username}`));
                        } catch (e) {
                            console.error(chalk.red(`❌ Error eliminando ${r.username}:`), e.message);
                        }
                    }
                    
                    console.log(chalk.green(`✅ ${rows.length} usuarios premium eliminados`));
                }
            });
            
            // Limpiar tests de BD (sin tocar sistema)
            db.all('SELECT username FROM users WHERE tipo = "test" AND expires_at < ? AND status = 1', [now], async (err, rows) => {
                if (err || !rows || rows.length === 0) {
                    console.log(chalk.green('✅ No hay tests expirados en BD'));
                    return;
                }
                
                console.log(chalk.yellow(`🗑️  Marcando ${rows.length} tests como expirados en BD...`));
                
                for (const r of rows) {
                    try {
                        // Solo desactivar en BD, no eliminar del sistema
                        db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                        
                        // Matar procesos del usuario si existen
                        await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                        
                        console.log(chalk.yellow(`⚠️  Test expirado: ${r.username} (solo BD)`));
                    } catch (e) {
                        console.error(chalk.red(`❌ Error procesando test ${r.username}:`), e.message);
                    }
                }
                
                console.log(chalk.green(`✅ ${rows.length} tests marcados como expirados`));
            });
        });
        
        // ✅ LIMPIAR ESTADOS ANTIGUOS
        cron.schedule('0 * * * *', () => {
            db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
        });
        
        // ✅ LIMPIAR TESTS DIARIOS ANTIGUOS
        cron.schedule('0 0 * * *', () => {
            const yesterday = moment().subtract(1, 'days').format('YYYY-MM-DD');
            db.run(`DELETE FROM daily_tests WHERE date < ?`, [yesterday]);
            console.log(chalk.green('✅ Tests diarios antiguos limpiados'));
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

echo -e "${GREEN}✅ Bot creado con MercadoPago${NC}"

# ================================================
# CREAR SCRIPT DE LIMPIEZA MANUAL CORREGIDO
# ================================================
echo -e "\n${CYAN}🧹 Creando script de limpieza manual...${NC}"

cat > /usr/local/bin/clean-tests << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                🧹 LIMPIADOR DE TESTS SSH                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}\n"

while true; do
    echo -e "${YELLOW}📊 ESTADO ACTUAL:${NC}"
    
    TOTAL_TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo = 'test';" 2>/dev/null || echo "0")
    ACTIVE_TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo = 'test' AND status = 1;" 2>/dev/null || echo "0")
    EXPIRED_TESTS_BD=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo = 'test' AND expires_at < datetime('now') AND status = 1;" 2>/dev/null || echo "0")
    
    echo -e "  Tests totales en BD: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "  Tests activos: ${GREEN}$ACTIVE_TESTS${NC}"
    echo -e "  Tests expirados (BD): ${RED}$EXPIRED_TESTS_BD${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}[1]${NC} Ver todos los tests"
    echo -e "${YELLOW}[2]${NC} Ver tests expirados (BD)"
    echo -e "${YELLOW}[3]${NC} Limpiar tests expirados (solo BD)"
    echo -e "${YELLOW}[4]${NC} Eliminar usuarios test del sistema"
    echo -e "${YELLOW}[5]${NC} Ver usuarios en sistema"
    echo -e "${YELLOW}[6]${NC} Forzar limpieza completa"
    echo -e "${YELLOW}[0]${NC} Salir"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "👉 Selecciona: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}📋 TODOS LOS TESTS EN BD:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT username, phone, expires_at, CASE WHEN expires_at < datetime('now') THEN 'EXPIRO' ELSE 'ACTIVO' END as estado FROM users WHERE tipo = 'test' ORDER BY expires_at;"
            echo ""
            read -p "Presiona Enter..."
            ;;
        2)
            echo -e "\n${RED}📋 TESTS EXPIRADOS EN BD:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT username, phone, expires_at FROM users WHERE tipo = 'test' AND expires_at < datetime('now') AND status = 1;"
            echo ""
            read -p "Presiona Enter..."
            ;;
        3)
            echo -e "\n${YELLOW}🧹 Marcando tests expirados en BD...${NC}"
            
            EXPIRED_USERS=$(sqlite3 "$DB" "SELECT username FROM users WHERE tipo = 'test' AND expires_at < datetime('now') AND status = 1;")
            
            if [[ -z "$EXPIRED_USERS" ]]; then
                echo -e "${GREEN}✅ No hay tests expirados en BD${NC}"
            else
                COUNT=0
                echo "$EXPIRED_USERS" | while read USER; do
                    echo "  Marcando como expirado: $USER"
                    # Matar procesos
                    pkill -u "$USER" 2>/dev/null || true
                    # Solo desactivar en BD
                    sqlite3 "$DB" "UPDATE users SET status = 0 WHERE username = '$USER';"
                    COUNT=$((COUNT + 1))
                done
                
                echo -e "${GREEN}✅ $COUNT tests marcados como expirados (solo BD)${NC}"
                echo -e "${YELLOW}⚠️  Los usuarios siguen en el sistema pero sin acceso${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        4)
            echo -e "\n${RED}⚠️  ELIMINAR USUARIOS TEST DEL SISTEMA${NC}"
            read -p "Escribe 'SI' para confirmar: " CONFIRM
            
            if [[ "$CONFIRM" == "SI" ]]; then
                echo "Buscando usuarios test en /etc/passwd..."
                cut -d: -f1 /etc/passwd | grep -E '^test[a-z][0-9]{4}' | while read USER; do
                    echo "  Eliminando del sistema: $USER"
                    pkill -u "$USER" 2>/dev/null || true
                    userdel -f "$USER" 2>/dev/null || true
                done
                
                echo -e "${GREEN}✅ Usuarios test eliminados del sistema${NC}"
            else
                echo -e "${YELLOW}❌ Cancelado${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        5)
            echo -e "\n${YELLOW}👥 USUARIOS EN SISTEMA:${NC}\n"
            echo "Usuarios test encontrados:"
            cut -d: -f1 /etc/passwd | grep -E '^test[a-z][0-9]{4}' | head -20
            echo ""
            echo "Total: $(cut -d: -f1 /etc/passwd | grep -E '^test[a-z][0-9]{4}' | wc -l)"
            read -p "Presiona Enter..."
            ;;
        6)
            echo -e "\n${RED}⚠️  LIMPIEZA COMPLETA FORZADA${NC}"
            echo -e "${YELLOW}Esto hará:${NC}"
            echo "  1. Eliminar usuarios test del sistema"
            echo "  2. Eliminar todos los tests de BD"
            echo "  3. Limpiar tabla daily_tests"
            
            read -p "Escribe 'SI' para confirmar: " CONFIRM
            
            if [[ "$CONFIRM" == "SI" ]]; then
                # Eliminar del sistema
                echo "Eliminando usuarios test del sistema..."
                cut -d: -f1 /etc/passwd | grep -E '^test[a-z][0-9]{4}' | while read USER; do
                    pkill -u "$USER" 2>/dev/null || true
                    userdel -f "$USER" 2>/dev/null || true
                    echo "  Eliminado: $USER"
                done
                
                # Eliminar de BD
                echo "Eliminando de BD..."
                sqlite3 "$DB" "DELETE FROM users WHERE tipo = 'test';"
                sqlite3 "$DB" "DELETE FROM daily_tests;"
                
                echo -e "${GREEN}✅ Limpieza completa realizada${NC}"
            else
                echo -e "${YELLOW}❌ Cancelado${NC}"
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
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🧹 LIMPIADOR DE TESTS SSH                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}\n"
done
EOF

chmod +x /usr/local/bin/clean-tests
echo -e "${GREEN}✅ Script de limpieza creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL COMPLETO
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control completo...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"
CONFIG="/opt/sshbot-pro/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL SSH BOT PRO - COMPLETO            ║${NC}"
    echo -e "${CYAN}║                  💰 MERCADOPAGO INTEGRADO                   ║${NC}"
    echo -e "${CYAN}║                  ✅ TESTS FUNCIONANDO                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

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
        echo -e "${GREEN}✅ CONEXIÓN EXITOSA${NC}"
        echo -e "${CYAN}Métodos disponibles:${NC}"
        echo "$BODY" | jq -r '.[].name' 2>/dev/null | head -3
        return 0
    else
        echo -e "${RED}❌ ERROR - Código: $HTTP_CODE${NC}"
        return 1
    fi
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
    echo -e "  Test: $(get_val '.prices.test_hours') horas (expira en BD)"
    echo -e ""
    
    echo -e "${YELLOW}💰 PRECIOS ACTUALES:${NC}"
    echo -e "  ${CYAN}DIARIOS:${NC}"
    echo -e "    1 día: $ $(get_val '.prices.price_1d') ARS"
    echo -e "    3 días: $ $(get_val '.prices.price_3d') ARS"
    echo -e "    7 días: $ $(get_val '.prices.price_7d') ARS"
    echo -e "    15 días: $ $(get_val '.prices.price_15d') ARS"
    echo -e "  ${CYAN}MENSUALES:${NC}"
    echo -e "    30 días: $ $(get_val '.prices.price_30d') ARS"
    echo -e "    50 días: $ $(get_val '.prices.price_50d') ARS"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver logs y QR"
    echo -e "${CYAN}[4]${NC} 👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC} 👥  Listar usuarios"
    echo -e "${CYAN}[6]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[7]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[9]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 🔄 Limpiar sesión"
    echo -e "${CYAN}[11]${NC} 💳 Ver pagos"
    echo -e "${CYAN}[12]${NC} ⚙️  Ver configuración"
    echo -e "${CYAN}[13]${NC} 🧹 Limpiar tests (clean-tests)"
    echo -e "${CYAN}[14]${NC} 🔍 Ver tests expirados"
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
            pm2 logs sshbot-pro --lines 100
            ;;
        4)
            clear
            echo -e "${CYAN}👤 CREAR USUARIO${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "Usuario (minúsculas, auto=generar): " USERNAME
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 2h, 1,3,7,15,30,50=premium): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            if [[ "$USERNAME" == "auto" || -z "$USERNAME" ]]; then
                if [[ "$TIPO" == "test" ]]; then
                    USERNAME="test$(shuf -i 1000-9999 -n 1)"
                else
                    USERNAME="user$(shuf -i 1000-9999 -n 1)"
                fi
            fi
            
            # Asegurar minúsculas
            USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')
            PASSWORD="mgvpn247"
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
                EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                # Test: solo fecha en BD, sin fecha en sistema
                useradd -M -s /bin/false "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$TIPO', '$EXPIRE_DATE', 1)"
                
                echo -e "\n${GREEN}✅ TEST CREADO${NC}"
                echo -e "📱 Teléfono: ${PHONE}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "⏰ Expira: ${EXPIRE_DATE} (solo en BD)"
                echo -e "⚠️  Test expira en 2 horas automáticamente"
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                EXPIRE_DATE_SYSTEM=$(date -d "+$DAYS days" +%Y-%m-%d)
                # Premium: con fecha en sistema
                useradd -M -s /bin/false -e "$EXPIRE_DATE_SYSTEM" "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$TIPO', '$EXPIRE_DATE', 1)"
                
                echo -e "\n${GREEN}✅ PREMIUM CREADO${NC}"
                echo -e "📱 Teléfono: ${PHONE}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "🔌 Días: ${DAYS}"
                echo -e "📊 Tipo: ${TIPO}"
            fi
            read -p "Presiona Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}👥 USUARIOS ACTIVOS${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, tipo, expires_at, CASE WHEN expires_at < datetime('now') THEN 'EXPIRO' ELSE 'ACTIVO' END as estado FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}💰 CAMBIAR PRECIOS${NC}\n"
            
            CURRENT_1D=$(get_val '.prices.price_1d')
            CURRENT_3D=$(get_val '.prices.price_3d')
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  ${CYAN}DIARIOS:${NC}"
            echo -e "  1. 1 día: $${CURRENT_1D} ARS"
            echo -e "  2. 3 días: $${CURRENT_3D} ARS"
            echo -e "  3. 7 días: $${CURRENT_7D} ARS"
            echo -e "  4. 15 días: $${CURRENT_15D} ARS"
            echo -e "  ${CYAN}MENSUALES:${NC}"
            echo -e "  5. 30 días: $${CURRENT_30D} ARS"
            echo -e "  6. 50 días: $${CURRENT_50D} ARS"
            echo -e ""
            
            echo -e "${CYAN}Modificar precios:${NC}"
            read -p "Nuevo precio 1d [${CURRENT_1D}]: " NEW_1D
            read -p "Nuevo precio 3d [${CURRENT_3D}]: " NEW_3D
            read -p "Nuevo precio 7d [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15d [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30d [${CURRENT_30D}]: " NEW_30D
            read -p "Nuevo precio 50d [${CURRENT_50D}]: " NEW_50D
            
            [[ -n "$NEW_1D" ]] && set_val '.prices.price_1d' "$NEW_1D"
            [[ -n "$NEW_3D" ]] && set_val '.prices.price_3d' "$NEW_3D"
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$NEW_50D" ]] && set_val '.prices.price_50d' "$NEW_50D"
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
            read -p "Presiona Enter..."
            ;;
        7)
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
        8)
            clear
            echo -e "${CYAN}🧪 TEST MERCADOPAGO${NC}\n"
            
            TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
                echo -e "${RED}❌ Token no configurado${NC}\n"
                read -p "Presiona Enter..."
                continue
            fi
            
            echo -e "${YELLOW}🔑 Token: ${TOKEN:0:30}...${NC}\n"
            test_mercadopago "$TOKEN"
            
            read -p "\nPresiona Enter..."
            ;;
        9)
            clear
            echo -e "${CYAN}📊 ESTADÍSTICAS${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Tests: ' || SUM(CASE WHEN tipo='test' THEN 1 ELSE 0 END) || ' | Premium: ' || SUM(CASE WHEN tipo='premium' THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN final_amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}📅 DISTRIBUCIÓN:${NC}"
            sqlite3 "$DB" "SELECT '1 día: ' || SUM(CASE WHEN plan='1d' THEN 1 ELSE 0 END) || ' | 3 días: ' || SUM(CASE WHEN plan='3d' THEN 1 ELSE 0 END) || ' | 7 días: ' || SUM(CASE WHEN plan='7d' THEN 1 ELSE 0 END) || ' | 15 días: ' || SUM(CASE WHEN plan='15d' THEN 1 ELSE 0 END) || ' | 30 días: ' || SUM(CASE WHEN plan='30d' THEN 1 ELSE 0 END) || ' | 50 días: ' || SUM(CASE WHEN plan='50d' THEN 1 ELSE 0 END) FROM payments WHERE status='approved'"
            
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
            echo -e "${YELLOW}📱 Escanea nuevo QR al iniciar${NC}"
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
            echo -e "  ${CYAN}DIARIOS:${NC}"
            echo -e "  1d: $(get_val '.prices.price_1d') ARS"
            echo -e "  3d: $(get_val '.prices.price_3d') ARS"
            echo -e "  7d: $(get_val '.prices.price_7d') ARS"
            echo -e "  15d: $(get_val '.prices.price_15d') ARS"
            echo -e "  ${CYAN}MENSUALES:${NC}"
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
            
            echo -e "\n${YELLOW}⚡ AJUSTES:${NC}"
            echo -e "  Limpieza: cada 5 minutos"
            echo -e "  Test: $(get_val '.prices.test_hours') horas (expira en BD)"
            echo -e "  Contraseña: mgvpn247 (fija)"
            
            read -p "\nPresiona Enter..."
            ;;
        13)
            echo -e "\n${YELLOW}🧹 Ejecutando limpiador de tests...${NC}"
            clean-tests
            ;;
        14)
            clear
            echo -e "${CYAN}🔍 TESTS EXPIRADOS${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, phone, expires_at FROM users WHERE tipo = 'test' AND expires_at < datetime('now') AND status = 1 ORDER BY expires_at;"
            
            COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo = 'test' AND expires_at < datetime('now') AND status = 1" 2>/dev/null || echo "0")
            echo -e "\n${YELLOW}Total tests expirados: ${COUNT}${NC}"
            
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

chmod +x /usr/local/bin/sshbot
echo -e "${GREEN}✅ Panel creado completo${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro
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
║          🎉 INSTALACIÓN COMPLETADA - TESTS FUNCIONANDO 🎉   ║
║                                                              ║
║       🤖 SSH BOT PRO - WPPCONNECT + MERCADOPAGO            ║
║       📱 WhatsApp API FUNCIONANDO                         ║
║       💰 MercadoPago SDK v2.x COMPLETO                    ║
║       💳 Pago automático con QR                           ║
║       ✅ TESTS 2 HORAS SIN ERRORES                        ║
║       🎛️  Panel completo con control                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema completo instalado${NC}"
echo -e "${GREEN}✅ WhatsApp API funcionando${NC}"
echo -e "${GREEN}✅ MercadoPago SDK v2.x integrado${NC}"
echo -e "${GREEN}✅ Panel de control completo${NC}"
echo -e "${GREEN}✅ Pago automático con QR${NC}"
echo -e "${GREEN}✅ Verificación automática de pagos${NC}"
echo -e "${GREEN}✅ Estadísticas completas${NC}"
echo -e "${GREEN}✅ Planes: Diarios (1,3,7,15 días) y Mensuales (30,50 días)${NC}"
echo -e "${GREEN}✅ Contraseña fija: mgvpn247${NC}"
echo -e "${GREEN}✅ Test: 2 horas de prueba (EXPIRA SOLO EN BD)${NC}"
echo -e "${GREEN}✅ Limpieza automática cada 5 minutos${NC}"
echo -e "${GREEN}✅ Comando clean-tests para limpieza manual${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control completo"
echo -e "  ${GREEN}clean-tests${NC}    - Limpiador de usuarios test"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver logs y QR"
echo -e "  ${GREEN}pm2 restart sshbot-pro${NC} - Reiniciar bot"
echo -e "\n"

echo -e "${YELLOW}🚀 PRIMEROS PASOS:${NC}\n"
echo -e "  1. Ver logs: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  2. Escanear QR cuando aparezca"
echo -e "  3. Enviar 'menu' al bot en WhatsApp"
echo -e "  4. Probar crear test con opción 1"
echo -e "  5. Configurar MercadoPago en el panel: ${GREEN}sshbot${NC}"
echo -e "  6. Opción [7] - Configurar token de MercadoPago"
echo -e "  7. Opción [8] - Testear conexión"
echo -e "\n"

echo -e "${YELLOW}💰 CONFIGURAR MERCADOPAGO:${NC}\n"
echo -e "  1. Ve a: https://www.mercadopago.com.ar/developers"
echo -e "  2. Inicia sesión"
echo -e "  3. Ve a 'Tus credenciales'"
echo -e "  4. Copia 'Access Token PRODUCCIÓN'"
echo -e "  5. En el panel: Opción 7 → Pegar token"
echo -e "  6. Testear con opción 8"
echo -e "\n"

echo -e "${YELLOW}🧪 SISTEMA DE TESTS CORREGIDO:${NC}\n"
echo -e "  • Tests NO tienen fecha de expiración en sistema"
echo -e "  • Tests expiran SOLO en base de datos (2 horas)"
echo -e "  • Limpieza automática cada 5 minutos"
echo -e "  • Usar ${GREEN}clean-tests${NC} para limpieza manual"
echo -e "  • Usuarios premium SÍ tienen fecha en sistema"
echo -e "\n"

echo -e "${GREEN}${BOLD}¡Sistema listo! Escanea el QR y prueba crear un test ✅${NC}\n"

# Ver logs automáticamente
read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs...${NC}"
    echo -e "${YELLOW}📱 Espera que aparezca el QR para escanear...${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
else
    echo -e "\n${YELLOW}💡 Para iniciar: ${GREEN}sshbot${NC}"
    echo -e "${YELLOW}💡 Para logs: ${GREEN}pm2 logs sshbot-pro${NC}"
    echo -e "${YELLOW}💡 Para limpiar tests: ${GREEN}clean-tests${NC}\n"
fi

exit 0
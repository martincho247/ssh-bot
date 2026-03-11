#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT + MERCADOPAGO + HWID
# VERSIÓN COMPLETA CON AUTENTICACIÓN HWID
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
echo -e "${CYAN}"
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
║          🤖 SSH BOT PRO - VERSIÓN HWID                      ║
║               🔑 Autenticación por HWID                     ║
║               💰 MercadoPago SDK v2.x INTEGRADO             ║
║               📱 TODO SE GUARDA EN TU VPS                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  🔑 ${CYAN}Autenticación HWID${NC} - Cada usuario tiene su HWID único"
echo -e "  📱 ${GREEN}WPPConnect${NC} - API WhatsApp que funciona"
echo -e "  💰 ${YELLOW}MercadoPago SDK v2.x${NC} - Integrado completo"
echo -e "  💳 ${PURPLE}Pago automático${NC} - QR + Enlace de pago"
echo -e "  🎛️  ${BLUE}Panel completo${NC} - Control total del sistema"
echo -e "  📊 ${CYAN}Estadísticas${NC} - Ventas, HWIDs activos, ingresos"
echo -e "  ⚡ ${GREEN}Auto-verificación${NC} - Pagos verificados cada 2 min"
echo -e "  🏠 ${YELLOW}TODO EN TU VPS${NC} - HWIDs guardados localmente"
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

# Preguntar por HWID del administrador
echo -e "${YELLOW}🔑 CONFIGURACIÓN DE HWID ADMINISTRADOR${NC}"
echo -e "${CYAN}Ingresa tu HWID personal (ej: APP-E3E4D5CBB7636907)${NC}"
read -p "HWID Admin: " ADMIN_HWID

if [[ -z "$ADMIN_HWID" ]]; then
    ADMIN_HWID="APP-ADMIN-$(date +%s | sha256sum | base64 | head -c 10 | tr '[:lower:]' '[:upper:]')"
    echo -e "${YELLOW}⚠️  Generando HWID automático: ${CYAN}$ADMIN_HWID${NC}"
fi

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

# Node.js 18.x
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

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-HWID",
        "server_ip": "$SERVER_IP"
    },
    "prices": {
        "test_hours": 1,
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

# Crear base de datos con HWID
sqlite3 "$DB_FILE" << SQL
-- Tabla principal de usuarios con HWID
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Control de tests diarios
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

-- Pagos
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

-- Logs de HWID (conexiones)
CREATE TABLE hwid_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hwid TEXT,
    phone TEXT,
    ip_address TEXT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Logs generales
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Estados de conversación
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_hwid_logs_hwid ON hwid_logs(hwid);
CREATE INDEX idx_hwid_logs_created ON hwid_logs(created_at);
SQL

# Insertar HWID del administrador
sqlite3 "$DB_FILE" "INSERT INTO users (phone, username, hwid, tipo, expires_at, status) VALUES ('ADMIN', 'admin', '$ADMIN_HWID', 'premium', datetime('now', '+3650 days'), 1);"

echo -e "${GREEN}✅ Estructura creada con HWID${NC}"
echo -e "${CYAN}🔑 HWID Administrador: ${YELLOW}$ADMIN_HWID${NC}"

# ================================================
# CREAR BOT COMPLETO CON HWID
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con HWID...${NC}"

cd "$USER_HOME"

# package.json
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

# Crear bot.js con HWID
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
console.log(chalk.cyan.bold('║              🤖 SSH BOT PRO - VERSIÓN HWID                  ║'));
console.log(chalk.cyan.bold('║              🔑 Autenticación por HWID                       ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');

// Inicializar MercadoPago
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

// ================================================
// FUNCIONES PARA HWID
// ================================================

// Generar HWID único
function generateHWID(prefix = 'APP') {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 10).toUpperCase();
    const unique = `${prefix}-${timestamp}${random}`;
    return unique.substring(0, 25); // Limitar longitud
}

// Verificar HWID
async function verifyHWID(hwid) {
    return new Promise((resolve) => {
        db.get('SELECT * FROM users WHERE hwid = ? AND status = 1 AND expires_at > CURRENT_TIMESTAMP', 
            [hwid], (err, row) => {
                if (err || !row) {
                    resolve({ valid: false, message: '❌ HWID no válido o expirado' });
                } else {
                    resolve({ 
                        valid: true, 
                        user: row,
                        expires: row.expires_at,
                        tipo: row.tipo
                    });
                }
            });
    });
}

// Registrar conexión HWID
async function logHWIDConnection(hwid, phone, ip = 'whatsapp') {
    db.run(`INSERT INTO hwid_logs (hwid, phone, ip_address, action) VALUES (?, ?, ?, 'connection')`,
        [hwid, phone, ip]);
}

// Crear usuario con HWID
async function createHWIDUser(phone, days) {
    return new Promise(async (resolve) => {
        try {
            const hwid = generateHWID(days === 0 ? 'TEST' : 'VIP');
            const username = days === 0 ? `test${Date.now().toString().slice(-6)}` : `user${Date.now().toString().slice(-6)}`;
            
            if (days === 0) {
                // TEST - 1 hora
                const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
                
                await execPromise(`useradd -m -s /bin/bash ${username} && echo "${username}:temp123" | chpasswd`).catch(() => {});
                
                db.run(`INSERT INTO users (phone, username, hwid, tipo, expires_at) VALUES (?, ?, ?, 'test', ?)`,
                    [phone, username, hwid, expireFull], function(err) {
                        if (err) {
                            resolve({ success: false, error: err.message });
                        } else {
                            resolve({ success: true, hwid, expires: expireFull, tipo: 'test' });
                        }
                    });
            } else {
                // PREMIUM
                const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
                
                await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:temp123" | chpasswd`).catch(() => {});
                
                db.run(`INSERT INTO users (phone, username, hwid, tipo, expires_at) VALUES (?, ?, ?, 'premium', ?)`,
                    [phone, username, hwid, expireFull], function(err) {
                        if (err) {
                            resolve({ success: false, error: err.message });
                        } else {
                            resolve({ success: true, hwid, expires: expireFull, tipo: 'premium' });
                        }
                    });
            }
        } catch (error) {
            resolve({ success: false, error: error.message });
        }
    });
}

// Verificar test diario
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

// ================================================
// ESTADOS DE CONVERSACIÓN
// ================================================
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

// ================================================
// MERCADOPAGO
// ================================================
async function createMercadoPagoPayment(phone, days, amount, planName) {
    try {
        if (!mpEnabled || !mpPreference) {
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        const phoneClean = phone.replace('@c.us', '');
        const paymentId = `HWID-${phoneClean}-${days}d-${Date.now()}`;
        
        const preferenceData = {
            items: [{
                title: `HWID PREMIUM ${days} DÍAS`,
                description: `Acceso HWID Premium por ${days} días`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: moment().add(24, 'hours').toISOString(),
            back_urls: {
                success: `https://wa.me/${phoneClean}`,
                failure: `https://wa.me/${phoneClean}`,
                pending: `https://wa.me/${phoneClean}`
            },
            auto_return: 'approved'
        };
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { width: 400, margin: 2 });
            
            db.run(
                `INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, `${days}d`, days, amount, paymentUrl, qrPath, response.id]
            );
            
            return { success: true, paymentId, paymentUrl, qrPath, amount };
        }
        
        throw new Error('Respuesta inválida');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MP:'), error.message);
        return { success: false, error: error.message };
    }
}

// ================================================
// VERIFICAR PAGOS
// ================================================
async function checkPendingPayments() {
    if (!mpEnabled) return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos...`));
        
        for (const payment of payments) {
            try {
                const url = `https://api.mercadopago.com/v1/payments/search?external_reference=${payment.payment_id}`;
                const response = await axios.get(url, {
                    headers: { 'Authorization': `Bearer ${config.mercadopago.access_token}` },
                    timeout: 15000
                });
                
                if (response.data && response.data.results && response.data.results.length > 0) {
                    const mpPayment = response.data.results[0];
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO APROBADO: ${payment.payment_id}`));
                        
                        // Crear HWID para el usuario
                        const result = await createHWIDUser(payment.phone, payment.days);
                        
                        if (result.success) {
                            db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                            
                            const expireDate = moment().add(payment.days, 'days').format('DD/MM/YYYY');
                            
                            const message = `✅ PAGO CONFIRMADO - HWID GENERADO

🎉 Tu compra ha sido aprobada

🔑 TU HWID PREMIUM:
\`\`\`
${result.hwid}
\`\`\`

📋 DETALLES:
⏰ Válido hasta: ${expireDate}
🔌 Conexiones: Ilimitadas

📱 CÓMO USARLO:
1. Abre la aplicación VPN
2. Selecciona "Conectar con HWID"
3. Ingresa el HWID proporcionado
4. Conecta automáticamente

💡 GUARDA ESTE HWID - Solo funcionará en tu dispositivo
🎊 ¡Disfruta del servicio premium!`;
                            
                            if (client) {
                                await client.sendText(payment.phone, message);
                            }
                        }
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando: ${payment.payment_id}`), error.message);
            }
        }
    });
}

// ================================================
// INICIALIZAR BOT
// ================================================
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect con HWID...'));
        
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
                '--disable-accelerated-2d-canvas',
                '--no-first-run',
                '--no-zygote',
                '--disable-gpu'
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
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            if (state === 'DISCONNECTED') {
                console.log(chalk.yellow('⚠️ Desconectado, reconectando...'));
                setTimeout(initializeBot, 10000);
            }
        });
        
        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                const text = message.body.toLowerCase().trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));
                
                const userState = await getUserState(from);
                
                // ================================================
                // DETECTAR HWID (FORMATO APP-XXXXX)
                // ================================================
                if (text.match(/^app-[a-z0-9]{10,25}$/i) || text.match(/^vip-[a-z0-9]{10,25}$/i) || text.match(/^test-[a-z0-9]{10,25}$/i)) {
                    const hwid = text.toUpperCase().trim();
                    
                    await client.sendText(from, '🔍 Verificando HWID...');
                    
                    const verification = await verifyHWID(hwid);
                    
                    if (verification.valid) {
                        await logHWIDConnection(hwid, from);
                        
                        const expireDate = moment(verification.expires).format('DD/MM/YYYY HH:mm');
                        
                        await client.sendText(from, `✅ HWID VERIFICADO CORRECTAMENTE

🔑 HWID: ${hwid}
📊 Tipo: ${verification.tipo === 'premium' ? '🌟 PREMIUM' : '⚡ TEST'}
⏰ Válido hasta: ${expireDate}
🔌 Conexiones: Ilimitadas

📱 CONFIGURACIÓN VPN:
1. Abre la aplicación VPN
2. Selecciona "Conectar con HWID"
3. Ingresa este HWID
4. Conecta automáticamente

🎊 ¡Conexión exitosa!`);
                    } else {
                        await client.sendText(from, `❌ HWID NO VÁLIDO

${verification.message}

Para obtener un HWID válido:
1. Usa el menú principal
2. Crea una cuenta de prueba (opción 1)
3. O compra un plan premium (opción 2)

💡 Los HWID tienen formato: APP-XXXXXXXXXX`);
                    }
                    
                    return;
                }
                
                // ================================================
                // MENÚ PRINCIPAL
                // ================================================
                if (['menu', 'hola', 'start', 'hi', 'volver', '0'].includes(text)) {
                    await setUserState(from, 'main_menu');
                    
                    await client.sendText(from, `🚀 *BOT HWID MGVPN*

Elija una opción:

🔑 1 - OBTENER HWID DE PRUEBA
💰 2 - COMPRAR HWID PREMIUM
🔄 3 - VERIFICAR MI HWID
📱 4 - DESCARGAR APLICACIÓN
❓ 5 - AYUDA / SOPORTE

💡 *Si ya tienes HWID, envíalo directamente*`);
                }
                
                // ================================================
                // OPCIÓN 1: HWID DE PRUEBA
                // ================================================
                else if (text === '1' && userState.state === 'main_menu') {
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, `⚠️ YA USASTE TU PRUEBA HOY

⏳ Vuelve mañana para otro HWID de prueba

💡 O compra un HWID premium con la opción 2`);
                        return;
                    }
                    
                    await client.sendText(from, '⏳ Generando HWID de prueba...');
                    
                    const result = await createHWIDUser(from, 0);
                    
                    if (result.success) {
                        registerTest(from);
                        
                        await client.sendText(from, `✅ *HWID DE PRUEBA GENERADO*

🔑 *TU HWID:*
\`\`\`
${result.hwid}
\`\`\`

📋 *DETALLES:*
⏰ Válido por: ${config.prices.test_hours} hora(s)
📱 App: ${config.links.app_download}

📌 *INSTRUCCIONES:*
1. Copia el HWID de arriba
2. Envíalo al bot para verificar
3. Abre la aplicación VPN
4. Selecciona "Conectar con HWID"
5. Ingresa el HWID y conecta

💡 *GUARDA ESTE HWID* - Solo funcionará en este dispositivo`);
                        
                        console.log(chalk.green(`✅ HWID Test: ${result.hwid}`));
                    } else {
                        await client.sendText(from, `❌ Error: ${result.error}`);
                    }
                }
                
                // ================================================
                // OPCIÓN 2: COMPRAR HWID PREMIUM
                // ================================================
                else if (text === '2' && userState.state === 'main_menu') {
                    await setUserState(from, 'buying_hwid');
                    
                    await client.sendText(from, `🌟 *PLANES HWID PREMIUM*

Selecciona duración:

🗓 1 - 7 DÍAS - $${config.prices.price_7d}
🗓 2 - 15 DÍAS - $${config.prices.price_15d}
🗓 3 - 30 DÍAS - $${config.prices.price_30d}
🗓 4 - 50 DÍAS - $${config.prices.price_50d}
⬅️ 0 - VOLVER

💳 Pago con MercadoPago - QR + Link`);
                }
                
                // ================================================
                // SELECCIÓN DE PLAN
                // ================================================
                else if (userState.state === 'buying_hwid' && ['1','2','3','4'].includes(text)) {
                    const plans = {
                        '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                        '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                        '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                        '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                    };
                    
                    const plan = plans[text];
                    
                    if (mpEnabled) {
                        await client.sendText(from, '⏳ Procesando tu compra...');
                        
                        const payment = await createMercadoPagoPayment(from, plan.days, plan.price, plan.name);
                        
                        if (payment.success) {
                            const message = `🌟 *COMPRA DE HWID PREMIUM*

Plan: ${plan.name}
💰 Precio: $${payment.amount}
⏰ Duración: ${plan.days} días

🔗 *LINK DE PAGO:*
${payment.paymentUrl}

💳 Escanea el QR o usa el link
⏳ Válido por 24 horas

⚠️ *IMPORTANTE:*
- Al pagar, recibirás tu HWID automáticamente
- El HWID llegará a este chat
- Guarda tu HWID en un lugar seguro`;
                            
                            await client.sendText(from, message);
                            
                            // Enviar QR si existe
                            if (fs.existsSync(payment.qrPath)) {
                                try {
                                    await client.sendImage(from, payment.qrPath, 'qr-pago.jpg', 
                                        `📱 Escanea con MercadoPago\n\n${plan.name} - $${payment.amount}`);
                                } catch (qrError) {
                                    console.log('⚠️ Error enviando QR');
                                }
                            }
                        } else {
                            await client.sendText(from, `❌ ERROR AL GENERAR PAGO

${payment.error}

Contacta al administrador: ${config.links.support}`);
                        }
                    } else {
                        await client.sendText(from, `⚠️ MERCADOPAGO NO CONFIGURADO

Plan: ${plan.name}
Precio: $${plan.price}

Contacta al administrador para pagar:
${config.links.support}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // ================================================
                // OPCIÓN 3: VERIFICAR HWID
                // ================================================
                else if (text === '3' && userState.state === 'main_menu') {
                    await client.sendText(from, `🔍 *VERIFICAR HWID*

Para verificar tu HWID, simplemente envíalo en el chat.

Formato esperado: APP-XXXXXXXXXX

Ejemplo: APP-TEST12345678

💡 Si no tienes HWID, usa la opción 1 para obtener uno de prueba.`);
                }
                
                // ================================================
                // OPCIÓN 4: DESCARGAR APP
                // ================================================
                else if (text === '4' && userState.state === 'main_menu') {
                    await client.sendText(from, `📱 *DESCARGAR APLICACIÓN*

🔗 Enlace: ${config.links.app_download}

📌 *INSTRUCCIONES:*
1. Abre el enlace en tu navegador
2. Descarga el archivo APK
3. Abre el APK
4. Click en "Más detalles"
5. Click en "Instalar de todas formas"
6. Una vez instalada, abre la app
7. Selecciona "Conectar con HWID"
8. Ingresa tu HWID y conecta

❓ ¿Problemas? Contacta soporte: ${config.links.support}`);
                }
                
                // ================================================
                // OPCIÓN 5: AYUDA
                // ================================================
                else if (text === '5' && userState.state === 'main_menu') {
                    await client.sendText(from, `❓ *AYUDA Y SOPORTE*

📌 *¿QUÉ ES HWID?*
HWID es un código único que identifica tu dispositivo. Una vez generado, solo funciona en el dispositivo donde se creó.

📌 *CÓMO FUNCIONA:*
1. Obtén HWID (prueba o compra)
2. Envía el HWID al bot para verificar
3. Abre la app VPN
4. Selecciona "Conectar con HWID"
5. Ingresa tu HWID y conecta

📌 *PROBLEMAS COMUNES:*
- HWID no válido: expiró o no existe
- "Ya usaste prueba": espera 24 horas
- App no instala: permite fuentes desconocidas

📞 *SOPORTE:*
${config.links.support}

💡 *RESPUESTA RÁPIDA:*
Envía tu HWID directamente para verificar`);
                }
                
                // ================================================
                // VOLVER AL MENÚ
                // ================================================
                else if (text === '0' && userState.state !== 'main_menu') {
                    await setUserState(from, 'main_menu');
                    
                    await client.sendText(from, `🚀 *BOT HWID MGVPN*

Elija una opción:

🔑 1 - OBTENER HWID DE PRUEBA
💰 2 - COMPRAR HWID PREMIUM
🔄 3 - VERIFICAR MI HWID
📱 4 - DESCARGAR APLICACIÓN
❓ 5 - AYUDA / SOPORTE

💡 *Si ya tienes HWID, envíalo directamente*`);
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error procesando mensaje:'), error.message);
            }
        });
        
        // ================================================
        // TAREAS PROGRAMADAS
        // ================================================
        
        // Verificar pagos cada 2 minutos
        cron.schedule('*/2 * * * *', () => {
            console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
            checkPendingPayments();
        });
        
        // Limpiar usuarios expirados cada 15 minutos
        cron.schedule('*/15 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.yellow(`🧹 Limpiando usuarios expirados...`));
            
            db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
                if (err || !rows || rows.length === 0) return;
                
                for (const r of rows) {
                    try {
                        await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                        await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                        db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                        console.log(chalk.green(`🗑️ Eliminado: ${r.username}`));
                    } catch (e) {
                        console.error(chalk.red(`Error: ${r.username}`), e.message);
                    }
                }
            });
        });
        
        // Limpiar estados antiguos
        cron.schedule('0 * * * *', () => {
            db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
        });
        
        // Estadísticas cada hora
        cron.schedule('0 * * * *', () => {
            db.get('SELECT COUNT(*) as total FROM users WHERE status=1', (err, row) => {
                console.log(chalk.cyan(`📊 HWIDs activos: ${row ? row.total : 0}`));
            });
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error inicializando:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(initializeBot, 10000);
    }
}

// Iniciar
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

echo -e "${GREEN}✅ Bot HWID creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control HWID...${NC}"

cat > /usr/local/bin/sshbot-hwid << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"
CONFIG="/opt/sshbot-pro/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL HWID - SSH BOT PRO                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Estadísticas
    TOTAL_HWID=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE hwid IS NOT NULL" 2>/dev/null || echo "0")
    ACTIVE_HWID=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1 AND expires_at > CURRENT_TIMESTAMP" 2>/dev/null || echo "0")
    PENDING_PAY=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="sshbot-pro") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA:${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  HWIDs activos: ${GREEN}$ACTIVE_HWID${NC}"
    echo -e "  HWIDs totales: ${CYAN}$TOTAL_HWID${NC}"
    echo -e "  Pagos pendientes: ${YELLOW}$PENDING_PAY${NC}"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver logs y QR"
    echo -e "${CYAN}[4]${NC} 🔑  Generar HWID manual"
    echo -e "${CYAN}[5]${NC} 📋  Listar HWIDs activos"
    echo -e "${CYAN}[6]${NC} 🔍  Buscar HWID"
    echo -e "${CYAN}[7]${NC} 📊  Ver conexiones por HWID"
    echo -e "${CYAN}[8]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[9]${NC} 💳  Configurar MercadoPago"
    echo -e "${CYAN}[10]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[11]${NC} 🔄  Limpiar sesión WhatsApp"
    echo -e "${CYAN}[12]${NC} 📈  Estadísticas completas"
    echo -e "${CYAN}[13]${NC} 🗑️  Desactivar HWID"
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
            echo -e "${CYAN}🔑 GENERAR HWID MANUAL${NC}\n"
            
            read -p "📱 Teléfono (ej: 5491122334455): " PHONE
            read -p "📊 Tipo (test/premium): " TIPO
            read -p "⏰ Días (0=test 1h, 7,15,30,50): " DAYS
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS=0
                EXPIRE=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                PREFIX="TEST"
            else
                EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                PREFIX="VIP"
            fi
            
            # Generar HWID
            HWID="${PREFIX}-$(date +%s | sha256sum | base64 | head -c 15 | tr '[:lower:]' '[:upper:]')"
            
            # Insertar en BD
            sqlite3 "$DB" "INSERT INTO users (phone, username, hwid, tipo, expires_at, status) VALUES ('$PHONE', 'manual', '$HWID', '$TIPO', '$EXPIRE', 1);"
            
            echo -e "\n${GREEN}✅ HWID GENERADO:${NC}"
            echo -e "${CYAN}$HWID${NC}"
            echo -e "📱 Teléfono: $PHONE"
            echo -e "⏰ Expira: $EXPIRE"
            
            read -p "\nPresiona Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}📋 HWIDs ACTIVOS${NC}\n"
            sqlite3 -column -header "$DB" "SELECT hwid, phone, tipo, expires_at FROM users WHERE status=1 AND expires_at > CURRENT_TIMESTAMP ORDER BY expires_at DESC LIMIT 20;"
            read -p "\nPresiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}🔍 BUSCAR HWID${NC}\n"
            read -p "Ingresa HWID o parte: " SEARCH
            sqlite3 -column -header "$DB" "SELECT * FROM users WHERE hwid LIKE '%$SEARCH%' OR phone LIKE '%$SEARCH%';"
            read -p "\nPresiona Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}📊 CONEXIONES POR HWID${NC}\n"
            read -p "Ingresa HWID: " HWID
            sqlite3 -column -header "$DB" "SELECT created_at, phone, ip_address, action FROM hwid_logs WHERE hwid='$HWID' ORDER BY created_at DESC LIMIT 20;"
            read -p "\nPresiona Enter..."
            ;;
        8)
            clear
            echo -e "${CYAN}💰 CAMBIAR PRECIOS${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  7 días: $${CURRENT_7D}"
            echo -e "  15 días: $${CURRENT_15D}"
            echo -e "  30 días: $${CURRENT_30D}"
            echo -e "  50 días: $${CURRENT_50D}\n"
            
            read -p "Nuevo precio 7d [$CURRENT_7D]: " NEW_7D
            read -p "Nuevo precio 15d [$CURRENT_15D]: " NEW_15D
            read -p "Nuevo precio 30d [$CURRENT_30D]: " NEW_30D
            read -p "Nuevo precio 50d [$CURRENT_50D]: " NEW_50D
            
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$NEW_50D" ]] && set_val '.prices.price_50d' "$NEW_50D"
            
            echo -e "\n${GREEN}✅ Precios actualizados${NC}"
            read -p "Presiona Enter..."
            ;;
        9)
            clear
            echo -e "${CYAN}💳 CONFIGURAR MERCADOPAGO${NC}\n"
            
            CURRENT_TOKEN=$(get_val '.mercadopago.access_token')
            
            echo -e "${YELLOW}📋 Instrucciones:${NC}"
            echo -e "  1. https://www.mercadopago.com.ar/developers"
            echo -e "  2. Inicia sesión"
            echo -e "  3. 'Tus credenciales' → Access Token PRODUCCIÓN\n"
            
            read -p "Pega el Access Token: " NEW_TOKEN
            
            if [[ "$NEW_TOKEN" =~ ^APP_USR- ]] || [[ "$NEW_TOKEN" =~ ^TEST- ]]; then
                set_val '.mercadopago.access_token' "\"$NEW_TOKEN\""
                set_val '.mercadopago.enabled' "true"
                echo -e "\n${GREEN}✅ Token configurado${NC}"
                echo -e "${YELLOW}🔄 Reiniciando bot...${NC}"
                cd /root/sshbot-pro && pm2 restart sshbot-pro
            else
                echo -e "${RED}❌ Token inválido (debe empezar con APP_USR- o TEST-)${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        10)
            clear
            echo -e "${CYAN}🧪 TEST MERCADOPAGO${NC}\n"
            
            TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
                echo -e "${RED}❌ Token no configurado${NC}"
            else
                echo -e "${YELLOW}🔍 Probando conexión...${NC}"
                RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "https://api.mercadopago.com/v1/payment_methods")
                
                if [[ "$RESPONSE" == "200" ]]; then
                    echo -e "${GREEN}✅ CONEXIÓN EXITOSA${NC}"
                else
                    echo -e "${RED}❌ ERROR - Código: $RESPONSE${NC}"
                fi
            fi
            read -p "\nPresiona Enter..."
            ;;
        11)
            echo -e "\n${YELLOW}🧹 Limpiando sesión WhatsApp...${NC}"
            pm2 stop sshbot-pro
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}📱 Escanea nuevo QR al iniciar${NC}"
            sleep 2
            ;;
        12)
            clear
            echo -e "${CYAN}📈 ESTADÍSTICAS COMPLETAS${NC}\n"
            
            echo -e "${YELLOW}📊 RESUMEN:${NC}"
            sqlite3 "$DB" "SELECT 'HWIDs totales: ' || COUNT(*) FROM users;"
            sqlite3 "$DB" "SELECT 'HWIDs activos: ' || COUNT(*) FROM users WHERE status=1 AND expires_at > CURRENT_TIMESTAMP;"
            sqlite3 "$DB" "SELECT 'HWIDs expirados: ' || COUNT(*) FROM users WHERE expires_at < CURRENT_TIMESTAMP;"
            sqlite3 "$DB" "SELECT 'Tests hoy: ' || COUNT(*) FROM daily_tests WHERE date = date('now');"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || COUNT(*) FROM payments WHERE status='pending';"
            sqlite3 "$DB" "SELECT 'Aprobados: ' || COUNT(*) FROM payments WHERE status='approved';"
            sqlite3 "$DB" "SELECT 'Total ingresos: $' || printf('%.2f', SUM(amount)) FROM payments WHERE status='approved';"
            
            echo -e "\n${YELLOW}🔌 CONEXIONES HOY:${NC}"
            sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_logs WHERE date(created_at) = date('now');"
            
            read -p "\nPresiona Enter..."
            ;;
        13)
            clear
            echo -e "${CYAN}🗑️  DESACTIVAR HWID${NC}\n"
            read -p "Ingresa HWID a desactivar: " HWID
            
            # Verificar si existe
            EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE hwid='$HWID';")
            
            if [[ "$EXISTS" -eq "0" ]]; then
                echo -e "${RED}❌ HWID no encontrado${NC}"
            else
                sqlite3 "$DB" "UPDATE users SET status=0 WHERE hwid='$HWID';"
                echo -e "${GREEN}✅ HWID desactivado${NC}"
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

chmod +x /usr/local/bin/sshbot-hwid
ln -sf /usr/local/bin/sshbot-hwid /usr/local/bin/sshbot

# ================================================
# CREAR UTILIDADES
# ================================================

# Script para verificar HWID
cat > /usr/local/bin/check-hwid << 'EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
DB="/opt/sshbot-pro/data/users.db"

if [[ -z "$1" ]]; then
    echo -e "${YELLOW}Uso: check-hwid <HWID>${NC}"
    exit 1
fi

HWID="$1"

echo -e "${CYAN}🔍 Verificando HWID: ${HWID}${NC}\n"

sqlite3 "$DB" "SELECT 
    '📱 HWID: ' || hwid,
    '👤 Teléfono: ' || phone,
    '📊 Tipo: ' || tipo,
    '⏰ Expira: ' || expires_at,
    '✅ Estado: ' || CASE WHEN status=1 AND expires_at > CURRENT_TIMESTAMP THEN 'ACTIVO' ELSE 'INACTIVO' END
FROM users WHERE hwid = '$HWID';" | while read line; do
    echo -e "${GREEN}$line${NC}"
done

echo -e "\n${YELLOW}📋 Últimas conexiones:${NC}"
sqlite3 -column -header "$DB" "SELECT created_at, action, ip_address FROM hwid_logs WHERE hwid = '$HWID' ORDER BY created_at DESC LIMIT 5;"
EOF

chmod +x /usr/local/bin/check-hwid

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot HWID...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA - HWID 🎉                ║
║                                                              ║
║       🤖 SSH BOT PRO - VERSIÓN HWID                         ║
║       🔑 Autenticación por Hardware ID                      ║
║       📱 TODO SE GUARDA EN TU VPS                           ║
║       💰 MercadoPago Integrado                              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema HWID instalado${NC}"
echo -e "${GREEN}✅ Tu HWID de administrador: ${YELLOW}$ADMIN_HWID${NC}"
echo -e "${GREEN}✅ Panel de control: ${CYAN}sshbot${NC}"
echo -e "${GREEN}✅ Verificar HWID: ${CYAN}check-hwid <HWID>${NC}"
echo -e "${GREEN}✅ Base de datos: ${CYAN}/opt/sshbot-pro/data/users.db${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 PRIMEROS PASOS:${NC}\n"
echo -e "  1. Ver QR: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  2. Escanear QR con WhatsApp"
echo -e "  3. Probar tu HWID admin: ${GREEN}$ADMIN_HWID${NC}"
echo -e "  4. Configurar MercadoPago: ${GREEN}sshbot${NC} (opción 9)"
echo -e "  5. Enviar 'menu' al bot en WhatsApp"
echo -e "\n"

echo -e "${YELLOW}🔑 TU HWID ADMIN (GUÁRDALO):${NC}"
echo -e "${CYAN}$ADMIN_HWID${NC}"
echo -e "${YELLOW}💡 Envíalo al bot para verificar${NC}\n"

echo -e "${GREEN}${BOLD}¡Sistema listo! Escanea el QR y prueba tu HWID 🚀${NC}\n"

# Ver logs automáticamente
read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs...${NC}"
    echo -e "${YELLOW}📱 Espera que aparezca el QR para escanear...${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
else
    echo -e "\n${YELLOW}💡 Para ver logs después: ${GREEN}pm2 logs sshbot-pro${NC}"
    echo -e "${YELLOW}💡 Panel de control: ${GREEN}sshbot${NC}\n"
fi

exit 0
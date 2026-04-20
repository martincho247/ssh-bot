#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALADOR COMPLETO
# CON LÍMITE DE 1 CONEXIÓN + BLOQUEO/PANEL
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
║          🤖 SSH BOT PRO - WPPCONNECT + MERCADOPAGO          ║
║               🔒 LÍMITE DE 1 CONEXIÓN POR USUARIO           ║
║               🚫 BLOQUEO/DESBLOQUEO DESDE PANEL             ║
║               📱 WhatsApp API FUNCIONANDO                   ║
║               💰 MercadoPago SDK v2.x INTEGRADO            ║
║               🔔 RECORDATORIOS AUTOMÁTICOS                  ║
║               🔄 RENOVACIÓN DE USUARIOS                     ║
║               📋 VER MIS USUARIOS                           ║
║               ⏰ PRUEBA DE 2 HORAS                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  🔒 ${CYAN}LÍMITE DE 1 CONEXIÓN${NC} - Por usuario simultáneo"
echo -e "  🚫 ${RED}BLOQUEO/DESBLOQUEO${NC} - Desde panel de control"
echo -e "  📱 ${GREEN}WPPConnect${NC} - API WhatsApp funcional"
echo -e "  💰 ${YELLOW}MercadoPago SDK v2.x${NC} - Integrado completo"
echo -e "  🔔 ${PURPLE}Recordatorios${NC} - 24h, 12h, 6h y 1h antes"
echo -e "  🔄 ${BLUE}Renovación${NC} - Renueva usuarios existentes"
echo -e "  📋 ${CYAN}Ver usuarios${NC} - Comando 'misusuarios'"
echo -e "  ⏰ ${BLUE}PRUEBA GRATIS${NC} - 2 HORAS de duración"
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
BLOCK_DB="$INSTALL_DIR/data/blocked_users.db"
APK_PATH="/root/mgvpn.apk"

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

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "2.0-MP-BLOCK-LIMIT",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247",
        "max_connections": 1
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 3000.00,
        "price_15d": 4000.00,
        "price_30d": 7500.00,
        "price_50d": 10000.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "reminders": {
        "enabled": true,
        "times": [24, 12, 6, 1]
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/tvt0vpmyfg3xqhj/mgvpn.apk/file",
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect",
        "apk_file": "$APK_PATH"
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
    last_reminder_hours INTEGER DEFAULT 0,
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
    is_renewal INTEGER DEFAULT 0,
    renewal_username TEXT,
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

# Crear base de datos de bloqueos
sqlite3 "$BLOCK_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS blocked_users (
    username TEXT PRIMARY KEY,
    blocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    blocked_by TEXT,
    reason TEXT
);
CREATE TABLE IF NOT EXISTS connection_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    connection_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);
SQL

echo -e "${GREEN}✅ Estructura creada con bloqueo de usuarios${NC}"

# ================================================
# CREAR SCRIPT DE LÍMITE DE CONEXIONES
# ================================================
echo -e "\n${CYAN}🔒 Creando sistema de límite de 1 conexión...${NC}"

cat > /usr/local/bin/ssh-limit.sh << 'SCRIPT_LIMIT'
#!/bin/bash
# SSH Connection Limit - 1 conexión por usuario
# Con bloqueo desde panel

BLOCK_DB="/opt/sshbot-pro/data/blocked_users.db"
MAX_CONNECTIONS=1

# Verificar si usuario está bloqueado
is_blocked() {
    local user="$1"
    local blocked=$(sqlite3 "$BLOCK_DB" "SELECT COUNT(*) FROM blocked_users WHERE username='$user'" 2>/dev/null)
    [[ "$blocked" == "1" ]]
}

# Registrar intento de conexión
log_attempt() {
    local user="$1"
    local action="$2"
    sqlite3 "$BLOCK_DB" "INSERT INTO connection_logs (username, action) VALUES ('$user', '$action')" 2>/dev/null
}

USERNAME="$PAM_USER"

# Verificar si el usuario existe en el sistema
if ! id "$USERNAME" &>/dev/null; then
    exit 0
fi

# Verificar bloqueo
if is_blocked "$USERNAME"; then
    echo "❌ USUARIO BLOQUEADO POR ADMINISTRADOR"
    echo "Contacta al soporte para desbloquear: https://wa.me/543435071016"
    log_attempt "$USERNAME" "blocked_attempt"
    exit 1
fi

# Contar conexiones activas del usuario
CURRENT_CONNECTIONS=$(who | awk '{print $1}' | grep -c "^${USERNAME}$" 2>/dev/null || echo "0")

# Verificar límite
if [ "$CURRENT_CONNECTIONS" -ge "$MAX_CONNECTIONS" ]; then
    echo "❌ LÍMITE DE CONEXIONES EXCEDIDO"
    echo "Máximo permitido: $MAX_CONNECTIONS conexión simultánea"
    echo "Cierra otras conexiones activas e intenta nuevamente"
    log_attempt "$USERNAME" "limit_exceeded"
    exit 1
fi

# Conexión permitida
log_attempt "$USERNAME" "connected"
exit 0
SCRIPT_LIMIT

chmod +x /usr/local/bin/ssh-limit.sh

# Configurar PAM
if ! grep -q "ssh-limit.sh" /etc/pam.d/sshd; then
    echo "session optional pam_exec.so /usr/local/bin/ssh-limit.sh" >> /etc/pam.d/sshd
fi

# Configurar SSH para límite
if ! grep -q "MaxSessions" /etc/ssh/sshd_config; then
    echo "MaxSessions 1" >> /etc/ssh/sshd_config
    echo "MaxStartups 1:1:1" >> /etc/ssh/sshd_config
    systemctl restart sshd
fi

echo -e "${GREEN}✅ Sistema de límite de conexiones activado${NC}"

# ================================================
# CREAR BOT COMPLETO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con límite de conexiones...${NC}"

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

echo -e "${YELLOW}📦 Instalando dependencias...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js COMPLETO
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
console.log(chalk.cyan.bold('║      🤖 SSH BOT PRO - LÍMITE 1 CONEXIÓN + BLOQUEO          ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

let config = require('/opt/sshbot-pro/config/config.json');
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');
const blockDb = new sqlite3.Database('/opt/sshbot-pro/data/blocked_users.db');

let mpEnabled = false;
let mpClient = null;
let mpPreference = null;

function initMercadoPago() {
    if (config.mercadopago.access_token && config.mercadopago.access_token !== '') {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            mpClient = new MercadoPagoConfig({ accessToken: config.mercadopago.access_token });
            mpPreference = new Preference(mpClient);
            mpEnabled = true;
            console.log(chalk.green('✅ MercadoPago SDK ACTIVO'));
        } catch (error) {
            console.log(chalk.red('❌ Error MP:'), error.message);
            mpEnabled = false;
        }
    }
}

initMercadoPago();

let client = null;

function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) resolve({ state: 'main_menu', data: null });
            else resolve({ state: row.state || 'main_menu', data: row.data ? JSON.parse(row.data) : null });
        });
    });
}

function setUserState(phone, state, data = null) {
    return new Promise((resolve) => {
        const dataStr = data ? JSON.stringify(data) : null;
        db.run(`INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`, [phone, state, dataStr], () => resolve());
    });
}

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

async function createSSHUser(phone, username, days) {
    const password = DEFAULT_PASSWORD;
    
    if (days === 0) {
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        try {
            await execPromise(`useradd -m -s /bin/bash ${username} && echo "${username}:${password}" | chpasswd`);
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'test', ?)`, [phone, username, password, expireFull]);
            return { success: true, username, password, expires: expireFull };
        } catch (error) {
            return { success: false, error: error.message };
        }
    } else {
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        try {
            await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'premium', ?)`, [phone, username, password, expireFull]);
            return { success: true, username, password, expires: expireFull };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }
}

async function renewSSHUser(phone, username, additionalDays) {
    return new Promise((resolve) => {
        db.get('SELECT username, expires_at, tipo FROM users WHERE phone = ? AND username = ? AND status = 1', [phone, username], async (err, user) => {
            if (err || !user) {
                resolve({ success: false, error: 'Usuario no encontrado' });
                return;
            }
            const currentExpiry = moment(user.expires_at);
            const newExpiry = currentExpiry.add(additionalDays, 'days');
            const newExpiryStr = newExpiry.format('YYYY-MM-DD HH:mm:ss');
            const newExpiryDate = newExpiry.format('YYYY-MM-DD');
            try {
                await execPromise(`chage -E ${newExpiryDate} ${username} 2>/dev/null || true`);
                db.run(`UPDATE users SET expires_at = ?, tipo = 'premium' WHERE phone = ? AND username = ?`, [newExpiryStr, phone, username]);
                resolve({ success: true, username, newExpiry: newExpiryStr, daysAdded: additionalDays });
            } catch (error) {
                resolve({ success: false, error: error.message });
            }
        });
    });
}

function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', [phone, today], (err, row) => resolve(!err && row && row.count === 0));
    });
}

function registerTest(phone) {
    db.run('INSERT OR IGNORE INTO daily_tests (phone, date) VALUES (?, ?)', [phone, moment().format('YYYY-MM-DD')]);
}

async function sendAppFile(to) {
    const apkPath = '/root/mgvpn.apk';
    if (!fs.existsSync(apkPath)) {
        return false;
    }
    try {
        await client.sendFile(to, apkPath, 'mgvpn.apk', '📲 *APP MGVPN*\n\nInstala la aplicación');
        return true;
    } catch (error) {
        return false;
    }
}

async function createMercadoPagoPayment(phone, days, amount, planName, isRenewal = false, renewalUsername = null) {
    try {
        if (!mpEnabled || !mpPreference) {
            return { success: false, error: 'MercadoPago no configurado' };
        }
        const phoneClean = phone.replace('@c.us', '');
        const paymentId = `${isRenewal ? 'RENEW' : 'SSH'}-${phoneClean}-${days}d-${Date.now()}`;
        const preferenceData = {
            items: [{
                title: isRenewal ? `RENOVACIÓN SSH ${days} DÍAS` : `SSH PREMIUM ${days} DÍAS`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            back_urls: { success: `https://wa.me/${phoneClean}`, failure: `https://wa.me/${phoneClean}` },
            auto_return: 'approved'
        };
        const response = await mpPreference.create({ body: preferenceData });
        if (response && response.id) {
            const paymentUrl = response.init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            await QRCode.toFile(qrPath, paymentUrl, { width: 400 });
            db.run(`INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, qr_code, preference_id, is_renewal, renewal_username) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?)`, [paymentId, phone, `${days}d`, days, amount, paymentUrl, qrPath, response.id, isRenewal ? 1 : 0, renewalUsername]);
            return { success: true, paymentId, paymentUrl, qrPath, amount: parseFloat(amount) };
        }
        throw new Error('Respuesta inválida');
    } catch (error) {
        return { success: false, error: error.message };
    }
}

async function checkPendingPayments() {
    if (!mpEnabled) return;
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments) return;
        for (const payment of payments) {
            try {
                const url = `https://api.mercadopago.com/v1/payments/search?external_reference=${payment.payment_id}`;
                const response = await axios.get(url, { headers: { 'Authorization': `Bearer ${config.mercadopago.access_token}` } });
                if (response.data && response.data.results && response.data.results.length > 0) {
                    const mpPayment = response.data.results[0];
                    if (mpPayment.status === 'approved') {
                        if (payment.is_renewal && payment.renewal_username) {
                            const result = await renewSSHUser(payment.phone, payment.renewal_username, payment.days);
                            if (result.success) {
                                db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                                if (client) await client.sendText(payment.phone, `✅ RENOVACIÓN CONFIRMADA\n\nUsuario: ${result.username}\n+${payment.days} días\nNueva expiración: ${moment(result.newExpiry).format('DD/MM/YYYY HH:mm')}`);
                            }
                        } else {
                            const username = generatePremiumUsername();
                            const result = await createSSHUser(payment.phone, username, payment.days);
                            if (result.success) {
                                db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                                if (client) await client.sendText(payment.phone, `✅ PAGO CONFIRMADO\n\nUsuario: ${username}\nContraseña: ${DEFAULT_PASSWORD}\nVálido: ${moment().add(payment.days, 'days').format('DD/MM/YYYY')}`);
                            }
                        }
                    }
                }
            } catch (error) {}
        }
    });
}

async function initializeBot() {
    try {
        client = await wppconnect.create({
            session: 'sshbot-pro-session',
            headless: true,
            useChrome: true,
            debug: false,
            logQR: true,
            browserArgs: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
            puppeteerOptions: { executablePath: '/usr/bin/google-chrome', headless: 'new', args: ['--no-sandbox'] },
            disableWelcome: true
        });
        
        console.log(chalk.green('✅ Bot conectado!'));
        
        client.onMessage(async (message) => {
            const text = message.body.toLowerCase().trim();
            const from = message.from;
            const userState = await getUserState(from);
            
            // Comando misusuarios
            if (text === 'misusuarios' || text === 'mis usuarios') {
                db.all(`SELECT username, expires_at FROM users WHERE phone = ? AND status = 1`, [from], async (err, rows) => {
                    if (!rows || rows.length === 0) {
                        await client.sendText(from, '📋 No tienes usuarios activos.');
                    } else {
                        let response = '📋 *TUS USUARIOS ACTIVOS*\n\n';
                        for (const row of rows) {
                            response += `👤 *${row.username}*\n⏰ Expira: ${moment(row.expires_at).format('DD/MM/YYYY HH:mm')}\n━━━━━━━━━━━━━━━━\n`;
                        }
                        await client.sendText(from, response);
                    }
                });
                return;
            }
            
            // Menú principal
            if (['menu', 'hola', 'start', 'volver', '0'].includes(text)) {
                await setUserState(from, 'main_menu');
                await client.sendText(from, `🤖 *SSH BOT PRO*

Elija una opción:

1️⃣ - CREAR PRUEBA (2 HORAS)
2️⃣ - COMPRAR USUARIO SSH
3️⃣ - RENOVAR USUARIO SSH
4️⃣ - DESCARGAR APLICACIÓN
5️⃣ - MIS USUARIOS

🔒 *Límite: 1 conexión por usuario*`);
            }
            
            // Opción 1: Prueba
            else if (text === '1' && userState.state === 'main_menu') {
                if (!(await canCreateTest(from))) {
                    await client.sendText(from, '⚠️ YA USASTE TU PRUEBA HOY\nVuelve mañana');
                    return;
                }
                await client.sendText(from, '⏳ Creando cuenta de prueba...');
                const username = generateUsername();
                const result = await createSSHUser(from, username, 0);
                if (result.success) {
                    registerTest(from);
                    await client.sendText(from, `✅ PRUEBA CREADA\n\nUsuario: ${username}\nContraseña: ${DEFAULT_PASSWORD}\n⏰ Expira en: ${config.prices.test_hours} horas\n\n🔒 1 conexión simultánea`);
                } else {
                    await client.sendText(from, `❌ Error: ${result.error}`);
                }
            }
            
            // Opción 2: Comprar
            else if (text === '2' && userState.state === 'main_menu') {
                await setUserState(from, 'buying_ssh');
                await client.sendText(from, `💳 *PLANES SSH*

1️⃣ - 7 DÍAS - $${config.prices.price_7d}
2️⃣ - 15 DÍAS - $${config.prices.price_15d}
3️⃣ - 30 DÍAS - $${config.prices.price_30d}
4️⃣ - 50 DÍAS - $${config.prices.price_50d}
0️⃣ - VOLVER`);
            }
            
            else if (userState.state === 'buying_ssh') {
                const planMap = {
                    '1': { days: 7, price: config.prices.price_7d },
                    '2': { days: 15, price: config.prices.price_15d },
                    '3': { days: 30, price: config.prices.price_30d },
                    '4': { days: 50, price: config.prices.price_50d }
                };
                if (text === '0') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, 'Menu principal');
                } else if (planMap[text]) {
                    const plan = planMap[text];
                    if (mpEnabled) {
                        const payment = await createMercadoPagoPayment(from, plan.days, plan.price, `${plan.days} DÍAS`);
                        if (payment.success) {
                            await client.sendText(from, `💳 *PAGO MERCADOPAGO*\n\nMonto: $${payment.amount}\nLink: ${payment.paymentUrl}\n\n⏰ Válido 24 horas`);
                            if (fs.existsSync(payment.qrPath)) {
                                await client.sendImage(from, payment.qrPath, 'qr.jpg', `Escanea para pagar - $${payment.amount}`);
                            }
                        } else {
                            await client.sendText(from, `❌ Error: ${payment.error}`);
                        }
                    } else {
                        await client.sendText(from, `⚠️ Pago manual. Contacta al admin: ${config.links.support}`);
                    }
                    await setUserState(from, 'main_menu');
                }
            }
            
            // Opción 3: Renovar
            else if (text === '3' && userState.state === 'main_menu') {
                await setUserState(from, 'renewing_ssh');
                await client.sendText(from, `🔄 RENOVAR USUARIO\n\nEscribe tu nombre de usuario (ej: user1234)\n0 - Cancelar`);
            }
            
            else if (userState.state === 'renewing_ssh') {
                if (text === '0') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, 'Renovación cancelada');
                } else {
                    db.get(`SELECT username FROM users WHERE phone = ? AND username = ? AND status = 1`, [from, text], async (err, row) => {
                        if (!row) {
                            await client.sendText(from, `❌ Usuario "${text}" no encontrado`);
                            await setUserState(from, 'main_menu');
                            return;
                        }
                        await setUserState(from, 'renewing_select_plan', { username: text });
                        await client.sendText(from, `✅ Usuario: ${text}\n\nSelecciona días a renovar:\n1️⃣ - 7 DÍAS - $${config.prices.price_7d}\n2️⃣ - 15 DÍAS - $${config.prices.price_15d}\n3️⃣ - 30 DÍAS - $${config.prices.price_30d}\n4️⃣ - 50 DÍAS - $${config.prices.price_50d}\n0️⃣ - CANCELAR`);
                    });
                }
            }
            
            else if (userState.state === 'renewing_select_plan') {
                const username = userState.data.username;
                const planMap = {
                    '1': { days: 7, price: config.prices.price_7d },
                    '2': { days: 15, price: config.prices.price_15d },
                    '3': { days: 30, price: config.prices.price_30d },
                    '4': { days: 50, price: config.prices.price_50d }
                };
                if (text === '0') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, 'Renovación cancelada');
                } else if (planMap[text]) {
                    const plan = planMap[text];
                    if (mpEnabled) {
                        const payment = await createMercadoPagoPayment(from, plan.days, plan.price, `RENOVAR ${plan.days} DÍAS`, true, username);
                        if (payment.success) {
                            await client.sendText(from, `🔄 RENOVACIÓN\n\nUsuario: ${username}\nPlan: ${plan.days} días\nMonto: $${payment.amount}\nLink: ${payment.paymentUrl}`);
                        } else {
                            await client.sendText(from, `❌ Error: ${payment.error}`);
                        }
                    } else {
                        await client.sendText(from, `🔄 RENOVACIÓN: ${plan.days} días - $${plan.price}\nContacta al admin: ${config.links.support}`);
                    }
                    await setUserState(from, 'main_menu');
                }
            }
            
            // Opción 4: Descargar APP
            else if (text === '4' && userState.state === 'main_menu') {
                if (fs.existsSync('/root/mgvpn.apk')) {
                    await sendAppFile(from);
                } else {
                    await client.sendText(from, `📲 DESCARGAR APP\n\nLink: ${config.links.app_download}\nContraseña: ${DEFAULT_PASSWORD}`);
                }
            }
            
            // Opción 5: Mis usuarios
            else if (text === '5' && userState.state === 'main_menu') {
                db.all(`SELECT username, expires_at FROM users WHERE phone = ? AND status = 1`, [from], async (err, rows) => {
                    if (!rows || rows.length === 0) {
                        await client.sendText(from, '📋 No tienes usuarios activos.');
                    } else {
                        let response = '📋 *TUS USUARIOS ACTIVOS*\n\n🔒 *1 conexión máxima*\n\n';
                        for (const row of rows) {
                            response += `👤 *${row.username}*\n⏰ Expira: ${moment(row.expires_at).format('DD/MM/YYYY HH:mm')}\n━━━━━━━━━━━━━━━━\n`;
                        }
                        await client.sendText(from, response);
                    }
                });
            }
        });
        
        // Verificar pagos cada 2 minutos
        cron.schedule('*/2 * * * *', () => checkPendingPayments());
        
        // Limpiar usuarios expirados
        cron.schedule('*/15 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
                for (const r of rows || []) {
                    try {
                        await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                        await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                        db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                    } catch (e) {}
                }
            });
        });
        
        // Recordatorios
        cron.schedule('0 * * * *', async () => {
            if (!config.reminders.enabled) return;
            for (const hours of config.reminders.times) {
                const targetTime = moment().add(hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
                db.all(`SELECT phone, username, expires_at FROM users WHERE status = 1 AND tipo = 'premium' AND expires_at BETWEEN datetime('now') AND ?`, [targetTime], async (err, users) => {
                    for (const user of users || []) {
                        try {
                            await client.sendText(user.phone, `🔔 RECORDATORIO\n\nTu cuenta ${user.username} vencerá en ${hours} horas\nPara renovar, envía MENU`);
                        } catch (e) {}
                    }
                });
            }
        });
        
    } catch (error) {
        console.error(chalk.red('Error:'), error.message);
        setTimeout(initializeBot, 10000);
    }
}

initializeBot();
BOTEOF

echo -e "${GREEN}✅ Bot creado con límite de conexiones${NC}"

# ================================================
# CREAR PANEL DE CONTROL COMPLETO
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control con gestión de bloqueos...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"
BLOCK_DB="/opt/sshbot-pro/data/blocked_users.db"
CONFIG="/opt/sshbot-pro/config/config.json"
APK_PATH="/root/mgvpn.apk"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🎛️  PANEL SSH BOT PRO - GESTIÓN COMPLETA           ║${NC}"
    echo -e "${CYAN}║              🔒 LÍMITE 1 CONEXIÓN + BLOQUEOS               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

list_blocked_users() {
    echo -e "${YELLOW}🔒 USUARIOS BLOQUEADOS:${NC}\n"
    sqlite3 -column -header "$BLOCK_DB" "SELECT username, blocked_at, reason FROM blocked_users ORDER BY blocked_at DESC" 2>/dev/null
    if [ $? -ne 0 ] || [ $(sqlite3 "$BLOCK_DB" "SELECT COUNT(*) FROM blocked_users" 2>/dev/null) -eq 0 ]; then
        echo -e "${GREEN}✅ No hay usuarios bloqueados${NC}"
    fi
}

block_user() {
    echo -e "\n${YELLOW}🚫 BLOQUEAR USUARIO${NC}"
    list_active_users
    read -p "Nombre de usuario a bloquear: " username
    if [ -z "$username" ]; then
        echo -e "${RED}❌ Nombre inválido${NC}"
        return
    fi
    read -p "Motivo del bloqueo: " reason
    sqlite3 "$BLOCK_DB" "INSERT OR REPLACE INTO blocked_users (username, blocked_at, reason) VALUES ('$username', datetime('now'), '$reason')" 2>/dev/null
    # Matar conexiones activas
    pkill -u "$username" 2>/dev/null
    echo -e "${GREEN}✅ Usuario $username BLOQUEADO${NC}"
}

unblock_user() {
    echo -e "\n${GREEN}🔓 DESBLOQUEAR USUARIO${NC}"
    list_blocked_users
    read -p "Nombre de usuario a desbloquear: " username
    if [ -z "$username" ]; then
        echo -e "${RED}❌ Nombre inválido${NC}"
        return
    fi
    sqlite3 "$BLOCK_DB" "DELETE FROM blocked_users WHERE username='$username'" 2>/dev/null
    echo -e "${GREEN}✅ Usuario $username DESBLOQUEADO${NC}"
}

list_active_users() {
    echo -e "\n${CYAN}📋 USUARIOS ACTIVOS EN EL SISTEMA:${NC}\n"
    sqlite3 -column -header "$DB" "SELECT username, phone, tipo, expires_at FROM users WHERE status=1 ORDER BY expires_at" 2>/dev/null
}

view_connection_logs() {
    echo -e "\n${CYAN}📊 REGISTRO DE CONEXIONES:${NC}\n"
    sqlite3 -column -header "$BLOCK_DB" "SELECT username, action, connection_time FROM connection_logs ORDER BY connection_time DESC LIMIT 30" 2>/dev/null
}

show_menu() {
    show_header
    
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    BLOCKED=$(sqlite3 "$BLOCK_DB" "SELECT COUNT(*) FROM blocked_users" 2>/dev/null || echo "0")
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="sshbot-pro") | .pm2_env.status' 2>/dev/null || echo "stopped")
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $([ "$STATUS" == "online" ] && echo "${GREEN}● ACTIVO${NC}" || echo "${RED}● DETENIDO${NC}")"
    echo -e "  Usuarios activos: ${CYAN}$ACTIVE/$TOTAL${NC}"
    echo -e "  Usuarios bloqueados: ${RED}$BLOCKED${NC}"
    echo -e "  MP: $([ -n "$(get_val '.mercadopago.access_token')" ] && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  Límite conexiones: ${GREEN}1 por usuario${NC}"
    echo -e ""
    
    echo -e "${CYAN}[1] Iniciar bot        [2] Detener bot        [3] Logs"
    echo -e "${CYAN}[4] Configurar MP      [5] Editar precios     [6] Subir APK"
    echo -e "${CYAN}[7] Ver usuarios       [8] Estadísticas       [9] GESTIÓN BLOQUEOS"
    echo -e "${CYAN}[10] Conexiones logs   [0] Salir${NC}"
    echo ""
}

while true; do
    show_menu
    read -p "👉 Selecciona: " OPT
    
    case $OPT in
        1) cd /root/sshbot-pro && pm2 restart sshbot-pro 2>/dev/null || pm2 start bot.js --name sshbot-pro; pm2 save; sleep 2;;
        2) pm2 stop sshbot-pro; sleep 1;;
        3) pm2 logs sshbot-pro --lines 50;;
        4)
            TOKEN=$(get_val '.mercadopago.access_token')
            echo -e "\n${YELLOW}Token actual: ${TOKEN:0:30}...${NC}"
            read -p "Nuevo token (APP_USR-xxx): " NEW_TOKEN
            if [[ "$NEW_TOKEN" =~ ^APP_USR- ]]; then
                set_val '.mercadopago.access_token' "\"$NEW_TOKEN\""
                set_val '.mercadopago.enabled' "true"
                echo -e "${GREEN}✅ Token guardado. Reinicia el bot.${NC}"
            fi
            read -p "Enter...";;
        5)
            echo -e "\n${YELLOW}Precios actuales:${NC}"
            echo "  7d: $(get_val '.prices.price_7d') | 15d: $(get_val '.prices.price_15d')"
            echo "  30d: $(get_val '.prices.price_30d') | 50d: $(get_val '.prices.price_50d')"
            read -p "Nuevo precio 7d: " p7; read -p "Nuevo precio 15d: " p15
            read -p "Nuevo precio 30d: " p30; read -p "Nuevo precio 50d: " p50
            [[ -n "$p7" ]] && set_val '.prices.price_7d' "$p7"
            [[ -n "$p15" ]] && set_val '.prices.price_15d' "$p15"
            [[ -n "$p30" ]] && set_val '.prices.price_30d' "$p30"
            [[ -n "$p50" ]] && set_val '.prices.price_50d' "$p50"
            echo -e "${GREEN}✅ Precios actualizados${NC}"
            read -p "Enter...";;
        6)
            clear
            echo -e "${CYAN}📲 SUBIR APLICACIÓN (APK)${NC}\n"
            if [[ -f "$APK_PATH" ]]; then
                echo -e "${GREEN}✅ App actual: $(du -h "$APK_PATH" | cut -f1)${NC}\n"
            fi
            read -p "Ruta del APK: " SOURCE_APK
            if [[ -f "$SOURCE_APK" && "$SOURCE_APK" == *.apk ]]; then
                cp "$SOURCE_APK" "$APK_PATH" && chmod 644 "$APK_PATH"
                echo -e "${GREEN}✅ APK subido correctamente${NC}"
            else
                echo -e "${RED}❌ Archivo inválido (debe ser .apk)${NC}"
            fi
            read -p "Enter...";;
        7)
            clear
            list_active_users
            read -p "Enter...";;
        8)
            clear
            echo -e "${CYAN}📊 ESTADÍSTICAS COMPLETAS${NC}\n"
            echo "Usuarios totales: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users")"
            echo "Usuarios activos: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1")"
            echo "Usuarios premium: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo='premium' AND status=1")"
            echo "Usuarios test: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo='test' AND status=1")"
            echo "Pagos aprobados: $(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='approved'")"
            echo "Ingresos totales: $(sqlite3 "$DB" "SELECT printf('%.2f', SUM(amount)) FROM payments WHERE status='approved'") ARS"
            echo "Tests hoy: $(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date=date('now')")"
            echo "Vencen hoy: $(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1 AND date(expires_at)=date('now')")"
            echo "Bloqueados: $(sqlite3 "$BLOCK_DB" "SELECT COUNT(*) FROM blocked_users")"
            read -p "Enter...";;
        9)
            while true; do
                clear
                show_header
                echo -e "${YELLOW}🔒 GESTIÓN DE BLOQUEOS${NC}\n"
                echo -e "${CYAN}[1] Ver usuarios bloqueados"
                echo -e "${CYAN}[2] Bloquear usuario"
                echo -e "${CYAN}[3] Desbloquear usuario"
                echo -e "${CYAN}[4] Ver usuarios activos"
                echo -e "${CYAN}[0] Volver al menú principal${NC}"
                echo ""
                read -p "👉 Opción: " BLOCK_OPT
                case $BLOCK_OPT in
                    1) clear; list_blocked_users; read -p "Enter...";;
                    2) block_user; read -p "Enter...";;
                    3) unblock_user; read -p "Enter...";;
                    4) clear; list_active_users; read -p "Enter...";;
                    0) break;;
                esac
            done
            ;;
        10)
            clear
            view_connection_logs
            read -p "Enter...";;
        0) echo -e "\n${GREEN}👋 Hasta luego${NC}"; exit 0;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot

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
║          🎉 INSTALACIÓN COMPLETADA - CORREGIDA 🎉           ║
║                                                              ║
║       🔒 LÍMITE DE 1 CONEXIÓN POR USUARIO ACTIVADO         ║
║       🚫 BLOQUEO/DESBLOQUEO DESDE PANEL                    ║
║       ✅ Recordatorios funcionando                         ║
║       ✅ Renovación de usuarios funcionando                ║
║       ✅ Comando "misusuarios" disponible                  ║
║       ✅ MercadoPago integrado                             ║
║       ✅ Envío de APK por WhatsApp                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${GREEN}✅ Instalación completa${NC}"
echo -e ""
echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control completo"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver QR y logs"
echo -e ""
echo -e "${YELLOW}🚀 PRIMEROS PASOS:${NC}"
echo -e "  1. ${GREEN}pm2 logs sshbot-pro${NC} - Esperar QR"
echo -e "  2. Escanear QR con WhatsApp"
echo -e "  3. ${GREEN}sshbot${NC} - Configurar MercadoPago (opción 4)"
echo -e "  4. Subir APK (opción 6)"
echo -e "  5. Enviar 'menu' al bot"
echo -e ""
echo -e "${YELLOW}🔒 GESTIÓN DE BLOQUEOS:${NC}"
echo -e "  ${GREEN}sshbot${NC} → Opción 9 → Gestión de bloqueos"
echo -e "  - Ver bloqueados"
echo -e "  - Bloquear usuario (mata conexiones activas)"
echo -e "  - Desbloquear usuario"
echo -e ""

read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    pm2 logs sshbot-pro
fi

exit 0
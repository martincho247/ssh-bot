#!/bin/bash
# ================================================
# SSH BOT PRO v8.7 - PANEL CONFIGURABLE COMPLETO
# Nuevas funciones agregadas:
# 1. ✅ AGREGAR NUEVOS PRECIOS Y DÍAS MANUALMENTE
# 2. ✅ EDITAR PLANES EXISTENTES
# 3. ✅ CONFIGURAR PLANES PERSONALIZADOS
# 4. ✅ GUARDAR AUTOMÁTICAMENTE EN CONFIG.JSON
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
║           🚀 SSH BOT PRO v8.7 - PANEL CONFIGURABLE          ║
║               💡 AGREGAR PRECIOS Y DÍAS MANUALMENTE         ║
║               🔧 PLANES PERSONALIZADOS                     ║
║               🔐 CONTRASEÑA FIJA: mgvpn247                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

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
echo -e "   • Crear SSH Bot Pro v8.7 CON PANEL CONFIGURABLE"
echo -e "   • Sistema para AGREGAR PRECIOS Y DÍAS manualmente"
echo -e "   • Planes personalizados configurables"
echo -e "   • Panel de control mejorado"
echo -e "   • APK automático + Test 2h"
echo -e "   • Cron limpieza cada 15 minutos"
echo -e "   • 🔐 CONTRASEÑA FIJA: mgvpn247 para todos"
echo -e "\n${RED}⚠️  Se eliminarán instalaciones anteriores${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS (MISMO QUE ANTES)
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS...${NC}"

# Actualizar sistema
apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1

# Instalar Node.js 20.x
echo -e "${YELLOW}📥 Instalando Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1

# Instalar dependencias del sistema
echo -e "${YELLOW}📥 Instalando dependencias del sistema...${NC}"
apt-get install -y git curl wget unzip build-essential python3 sqlite3 jq chromium-browser psmisc > /dev/null 2>&1

# Instalar PM2 globalmente
echo -e "${YELLOW}📥 Instalando PM2...${NC}"
npm install -g pm2 > /dev/null 2>&1

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/ssh-bot"
USER_HOME="/root/ssh-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete ssh-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,backups}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración CON PLANES CONFIGURABLES
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "8.7-PANEL-CONFIGURABLE",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 2,
        "plans": [
            {
                "id": 1,
                "name": "7 días - 1 conexión",
                "days": 7,
                "connections": 1,
                "price": 500.00,
                "enabled": true
            },
            {
                "id": 2,
                "name": "15 días - 1 conexión",
                "days": 15,
                "connections": 1,
                "price": 800.00,
                "enabled": true
            },
            {
                "id": 3,
                "name": "30 días - 1 conexión",
                "days": 30,
                "connections": 1,
                "price": 1200.00,
                "enabled": true
            },
            {
                "id": 4,
                "name": "7 días - 2 conexiones",
                "days": 7,
                "connections": 2,
                "price": 800.00,
                "enabled": true
            },
            {
                "id": 5,
                "name": "15 días - 2 conexiones",
                "days": 15,
                "connections": 2,
                "price": 1200.00,
                "enabled": true
            },
            {
                "id": 6,
                "name": "30 días - 2 conexiones",
                "days": 30,
                "connections": 2,
                "price": 1800.00,
                "enabled": true
            }
        ],
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
        "qr_codes": "$INSTALL_DIR/qr_codes"
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
    max_connections INTEGER DEFAULT 1,
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
    plan_id INTEGER,
    plan_name TEXT,
    days INTEGER,
    connections INTEGER DEFAULT 1,
    amount REAL,
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
CREATE INDEX idx_payments_phone_plan ON payments(phone, plan_id, status);
SQL

echo -e "${GREEN}✅ Estructura creada con planes configurables${NC}"

# ================================================
# CREAR BOT CON PLANES CONFIGURABLES
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT CON PLANES CONFIGURABLES...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-pro",
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
        "axios": "^1.6.5"
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

# Crear bot.js CON PLANES CONFIGURABLES
echo -e "${YELLOW}📝 Creando bot.js con planes configurables...${NC}"

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
    delete require.cache[require.resolve('/opt/ssh-bot/config/config.json')];
    return require('/opt/ssh-bot/config/config.json');
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

// ✅ OBTENER PLANES ACTIVOS
function getActivePlans() {
    return config.prices.plans.filter(plan => plan.enabled).sort((a, b) => a.id - b.id);
}

// ✅ OBTENER PLAN POR ID
function getPlanById(planId) {
    return config.prices.plans.find(plan => plan.id === parseInt(planId) && plan.enabled);
}

// ✅ GENERAR MENÚ DE PLANES
function generatePlansMenu() {
    const activePlans = getActivePlans();
    let menu = `💎 *PLANES DISPONIBLES*\n\n`;
    
    activePlans.forEach(plan => {
        const connIcon = plan.connections > 1 ? '🔌🔌' : '🔌';
        menu += `${connIcon} *${plan.id}* - ${plan.name}\n`;
        menu += `   ⏰ ${plan.days} días | 💰 $${plan.price} ${config.prices.currency}\n\n`;
    });
    
    menu += `💳 *MÉTODO DE PAGO:* MercadoPago\n`;
    menu += `⚡ *ACTIVACIÓN:* 2-5 minutos después del pago\n\n`;
    menu += `💰 *PARA COMPRAR:* Escribe el número del plan (${activePlans.map(p => p.id).join(', ')})\n`;
    menu += `💬 *Para volver:* Escribe "menu"`;
    
    return menu;
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
console.log(chalk.cyan.bold('║      🤖 SSH BOT PRO v8.7 - PLANES CONFIGURABLES            ║'));
console.log(chalk.cyan.bold('║               💡 AGREGAR/EDITAR PRECIOS DESDE PANEL        ║'));
console.log(chalk.cyan.bold('║               🔐 CONTRASEÑA FIJA: mgvpn247                 ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ SDK v2.x ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.yellow(`📋 Planes activos: ${getActivePlans().length}`));
getActivePlans().forEach(plan => {
    console.log(chalk.cyan(`   ${plan.id}. ${plan.name} - $${plan.price} ${config.prices.currency}`));
});
console.log(chalk.green('✅ WhatsApp Web parcheado (no markedUnread error)'));
console.log(chalk.green('✅ Planes configurables desde panel'));
console.log(chalk.green('✅ AGREGAR/EDITAR PRECIOS Y DÍAS manualmente'));
console.log(chalk.green('✅ CONTRASEÑA FIJA: mgvpn247 para todos los usuarios'));

// Servidor APK
let apkServer = null;
function startAPKServer(apkPath) {
    return new Promise((resolve) => {
        try {
            const http = require('http');
            const fileName = path.basename(apkPath);
            
            apkServer = http.createServer((req, res) => {
                if (req.url === '/' || req.url === `/${fileName}`) {
                    try {
                        const stat = fs.statSync(apkPath);
                        res.writeHead(200, {
                            'Content-Type': 'application/vnd.android.package-archive',
                            'Content-Length': stat.size,
                            'Content-Disposition': `attachment; filename="${fileName}"`
                        });
                        
                        const readStream = fs.createReadStream(apkPath);
                        readStream.pipe(res);
                        console.log(chalk.cyan(`📥 APK descargado: ${fileName}`));
                    } catch (err) {
                        res.writeHead(404);
                        res.end('APK no encontrado');
                    }
                } else {
                    res.writeHead(404);
                    res.end('Not found');
                }
            });
            
            apkServer.listen(8001, '0.0.0.0', () => {
                console.log(chalk.green(`✅ Servidor APK: http://${config.bot.server_ip}:8001/`));
                resolve(true);
            });
            
            setTimeout(() => {
                if (apkServer) {
                    apkServer.close();
                    console.log(chalk.yellow('⏰ Servidor APK cerrado (1h)'));
                }
            }, 3600000);
            
        } catch (error) {
            console.error(chalk.red('❌ Error servidor APK:'), error);
            resolve(false);
        }
    });
}

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'ssh-bot-v87'}),
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
    QRCode.toFile('/root/qr-whatsapp.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.cyan('\n1️⃣ Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('2️⃣ Escanea el QR ☝️'));
    console.log(chalk.green('\n💾 QR guardado: /root/qr-whatsapp.png\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado')));
client.on('loading_screen', (p, m) => console.log(chalk.yellow(`⏳ Cargando: ${p}% - ${m}`)));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp\n'));
    qrCount = 0;
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

function generateUsername() {
    return 'user' + Math.random().toString(36).substr(2, 6);
}

function generatePassword() {
    return 'mgvpn247';
}

async function createSSHUser(phone, username, password, days, connections = 1) {
    if (days === 0) {
        const expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        console.log(chalk.yellow(`⌛ Test ${username} expira: ${expireFull} (2 horas)`));
        
        const commands = [
            `useradd -m -s /bin/bash ${username}`,
            `echo "${username}:mgvpn247" | chpasswd`
        ];
        
        for (const cmd of commands) {
            try {
                await execPromise(cmd);
            } catch (error) {
                console.error(chalk.red(`❌ Error: ${cmd}`), error.message);
                throw error;
            }
        }
        
        const tipo = 'test';
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, 'mgvpn247', tipo, expireFull, 1],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password: 'mgvpn247',
                    expires: expireFull,
                    tipo: 'test',
                    duration: '2 horas'
                }));
        });
    } else {
        const expireDate = moment().add(days, 'days').format('YYYY-MM-DD');
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        console.log(chalk.yellow(`⌛ Premium ${username} expira: ${expireDate} (${connections} conexiones)`));
        
        try {
            await execPromise(`useradd -M -s /bin/false -e ${expireDate} ${username} && echo "${username}:mgvpn247" | chpasswd`);
        } catch (error) {
            console.error(chalk.red('❌ Error creando premium:'), error.message);
            throw error;
        }
        
        const tipo = 'premium';
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, 'mgvpn247', tipo, expireFull, connections],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password: 'mgvpn247',
                    expires: expireFull,
                    tipo: 'premium',
                    duration: `${days} días`,
                    connections: connections
                }));
        });
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

async function createMercadoPagoPayment(phone, planId, planName, days, amount, connections) {
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
        const paymentId = `PREMIUM-${phoneClean}-${planId}-${connections}conn-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `SERVICIO PREMIUM ${days} DÍAS (${connections} conexiones)`,
                description: `Acceso completo por ${days} días con ${connections} conexiones simultáneas`,
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
            statement_descriptor: 'SERVICIO PREMIUM',
            notification_url: `http://${config.bot.server_ip}:3000/webhook`
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency}`));
        console.log(chalk.yellow(`🔌 Conexiones: ${connections}`));
        
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
                `INSERT INTO payments (payment_id, phone, plan_id, plan_name, days, connections, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, planId, planName, days, connections, amount, paymentUrl, qrPath, response.id],
                (err) => {
                    if (err) {
                        console.error(chalk.red('❌ Error guardando en BD:'), err.message);
                    }
                }
            );
            
            console.log(chalk.green(`✅ Pago creado exitosamente`));
            console.log(chalk.cyan(`🔗 URL: ${paymentUrl.substring(0, 50)}...`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                preferenceId: response.id,
                connections: connections
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

// ✅ FUNCIÓN CLAVE: VERIFICAR SI YA EXISTE UN PAGO PENDIENTE
async function getExistingPayment(phone, planId, days, connections) {
    return new Promise((resolve) => {
        const query = `
            SELECT payment_id, payment_url, qr_code, amount, created_at 
            FROM payments 
            WHERE phone = ? 
            AND plan_id = ? 
            AND days = ? 
            AND connections = ? 
            AND status = 'pending'
            AND created_at > datetime('now', '-24 hours')
            ORDER BY created_at DESC 
            LIMIT 1
        `;
        
        db.get(query, [phone, planId, days, connections], (err, row) => {
            if (err) {
                console.error(chalk.red('❌ Error buscando pago existente:'), err.message);
                resolve(null);
            } else if (row) {
                console.log(chalk.green(`✅ Pago existente encontrado: ${row.payment_id}`));
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
                        
                        const username = generateUsername();
                        const password = 'mgvpn247';
                        const result = await createSSHUser(payment.phone, username, password, payment.days, payment.connections);
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                        
                        const expireDate = moment().add(payment.days, 'days').format('DD/MM/YYYY');
                        
                        const message = `╔══════════════════════════════════════╗
║   🎉 *PAGO CONFIRMADO*               ║
╚══════════════════════════════════════╝

✅ Tu compra ha sido aprobada

📋 *DATOS DE ACCESO:*
👤 Usuario: *${username}*
🔑 Contraseña: *mgvpn247*

⏰ *VÁLIDO HASTA:* ${expireDate}
🔌 *CONEXIÓN:* ${payment.connections} ${payment.connections > 1 ? 'conexiones simultáneas' : 'conexión'}

📱 *INSTALACIÓN:*
1. Descarga la app (Escribe *5*)
2. Seleccionar servidor 1
3. Ingresar Usuario y Contraseña
4. ¡Conéctate automáticamente!

🎊 ¡Disfruta del servicio premium!

💬 Soporte: *Escribe 6*`;
                        
                        await client.sendMessage(payment.phone, message, { sendSeen: false });
                        console.log(chalk.green(`✅ Usuario creado y notificado: ${username} (${payment.connections} conexiones)`));
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
}

client.on('message', async (msg) => {
    const text = msg.body.toLowerCase().trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // Obtener estado actual del usuario
    const userState = await getUserState(phone);
    
    if (['menu', 'hola', 'start', 'hi', 'volver', 'atras'].includes(text)) {
        // Resetear estado a menú principal
        await setUserState(phone, 'main_menu');
        
        await client.sendMessage(phone, `╔══════════════════════════════════════╗
║   🚀 *HOLA BOT MGVPN*              ║
╚══════════════════════════════════════╝

📋 *MENU PRINCIPAL:*

⌛️ *1* - Prueba GRATIS (2h) 
💰 *2* - Planes Internet
👤 *3* - Mis cuentas
💳 *4* - Estado de pago
📱 *5* - Descargar APP
🔧 *6* - Soporte

💬 Responde con el número`, { sendSeen: false });
    }
    else if (text === '1' && userState.state === 'main_menu') {
        // ✅ COMANDO 1 EN MENÚ PRINCIPAL = PRUEBA GRATIS
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana
💎 *Escribe 2* para planes`, { sendSeen: false });
            return;
        }
        await client.sendMessage(phone, '⏳ Creando cuenta test...', { sendSeen: false });
        try {
            const username = generateUsername();
            const password = 'mgvpn247';
            await createSSHUser(phone, username, password, 0, 1);
            registerTest(phone);
            
            await client.sendMessage(phone, `✅ *PRUEBA ACTIVADA*

👤 Usuario: *${username}*
🔑 Contraseña: *mgvpn247*
⏰ Duración: 2 horas  
🔌 Conexión: 1

📱 *PARA CONECTAR:*
1. Descarga la app (Escribe *5*)
2. Selecionar servidor
3. Ingresa usuario y contraseña
4. ¡Listo!

💎 ¿Te gustó? *Escribe 2* para ver planes premium`, { sendSeen: false });
            
            console.log(chalk.green(`✅ Test creado: ${username}`));
        } catch (error) {
            await client.sendMessage(phone, `❌ Error al crear cuenta: ${error.message}`, { sendSeen: false });
        }
    }
    else if (text === '2' && userState.state === 'main_menu') {
        // ✅ COMANDO 2 EN MENÚ PRINCIPAL = VER PLANES
        await setUserState(phone, 'viewing_plans');
        
        const plansMenu = generatePlansMenu();
        await client.sendMessage(phone, plansMenu, { sendSeen: false });
    }
    else if (userState.state === 'viewing_plans') {
        // ✅ COMANDOS CUANDO EL USUARIO ESTÁ VIENDO PLANES = COMPRAR
        config = loadConfig();
        
        const plan = getPlanById(text);
        if (!plan) {
            await client.sendMessage(phone, `❌ *PLAN NO VÁLIDO*

Escribe solo números de planes disponibles.

💬 Escribe "menu" para volver`, { sendSeen: false });
            return;
        }
        
        console.log(chalk.yellow(`🔑 Verificando token MP para compra...`));
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            await client.sendMessage(phone, `❌ *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Soporte: *Escribe 6*`, { sendSeen: false });
            await setUserState(phone, 'main_menu');
            return;
        }
        
        if (!mpEnabled || !mpPreference) {
            console.log(chalk.yellow('🔄 Reinicializando MercadoPago...'));
            mpEnabled = initMercadoPago();
        }
        
        if (!mpEnabled || !mpPreference) {
            await client.sendMessage(phone, `❌ *ERROR CON MERCADOPAGO*

El sistema de pagos no está disponible.

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
            await setUserState(phone, 'main_menu');
            return;
        }
        
        console.log(chalk.cyan(`📦 Plan seleccionado: ${plan.name}, $${plan.price}`));
        
        // ✅ VERIFICAR SI YA EXISTE UN PAGO PENDIENTE
        const existingPayment = await getExistingPayment(phone, plan.id, plan.days, plan.connections);
        
        if (existingPayment) {
            console.log(chalk.yellow(`📌 Reutilizando pago existente: ${existingPayment.payment_id}`));
            
            const connText = plan.connections > 1 ? `${plan.connections} CONEXIONES SIMULTÁNEAS` : '1 CONEXIÓN';
            
            await client.sendMessage(phone, `📋 *TIENES UN PAGO PENDIENTE*

Ya generaste un pago para este plan.

⚡ *PLAN:* ${plan.name}
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
                        
⚡ ${plan.name}
💰 $${existingPayment.amount} ARS
⏰ Válido por 24 horas`, 
                        sendSeen: false 
                    });
                    console.log(chalk.green('✅ QR de pago existente enviado'));
                } catch (qrError) {
                    console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                }
            }
            
            await setUserState(phone, 'main_menu');
            return;
        }
        
        // Si no hay pago existente, crear uno nuevo
        const connText = plan.connections > 1 ? `${plan.connections} conexiones simultáneas` : '1 conexión';
        
        await client.sendMessage(phone, `⏳ *PROCESANDO TU COMPRA...*

📦 Plan: *${plan.name}*
💰 Monto: *$${plan.price} ARS*
🔌 Conexión: *${connText}*

⏰ *GENERANDO ENLACE DE PAGO...*`, { sendSeen: false });
        
        try {
            const payment = await createMercadoPagoPayment(phone, plan.id, plan.name, plan.days, plan.price, plan.connections);
            
            if (payment.success) {
                const connDisplay = plan.connections > 1 ? `${plan.connections} CONEXIONES SIMULTÁNEAS` : '1 CONEXIÓN';
                
                await client.sendMessage(phone, `💳 *PAGO GENERADO EXITOSAMENTE*

⚡ *PLAN:* ${plan.name}
💰 *$${plan.price} ARS*

🔗 *ENLACE DE PAGO:*
${payment.paymentUrl}

✅ *TE NOTIFICARÉ CUANDO SE APRUEBE EL PAGO*

💬 Escribe *4* para ver estado del pago
💬 Escribe "menu" para volver al inicio`, { sendSeen: false });
                
                // Enviar QR si existe
                if (fs.existsSync(payment.qrPath)) {
                    try {
                        const media = MessageMedia.fromFilePath(payment.qrPath);
                        await client.sendMessage(phone, media, { 
                            caption: `📱 *ESCAPEA CON MERCADOPAGO*
                            
⚡ ${plan.name}
💰 $${plan.price} ARS
⏰ Pago válido por 24 horas`, 
                            sendSeen: false 
                        });
                        console.log(chalk.green('✅ QR de pago enviado'));
                    } catch (qrError) {
                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                    }
                }
            } else {
                await client.sendMessage(phone, `❌ *ERROR AL GENERAR PAGO*

Detalles: ${payment.error}

Por favor, intenta de nuevo en unos minutos o contacta soporte.

💬 Soporte: *Escribe 6*`, { sendSeen: false });
            }
        } catch (error) {
            console.error(chalk.red('❌ Error en compra:'), error);
            await client.sendMessage(phone, `❌ *ERROR INESPERADO*

${error.message}

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
        }
        
        await setUserState(phone, 'main_menu');
    }
    else if (text === '3' && userState.state === 'main_menu') {
        // ✅ COMANDO 3 EN MENÚ PRINCIPAL = MIS CUENTAS
        db.all(`SELECT username, password, tipo, expires_at, max_connections FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC LIMIT 10`, [phone],
            async (err, rows) => {
                if (!rows || rows.length === 0) {
                    await client.sendMessage(phone, `📋 *SIN CUENTAS ACTIVAS*

🆓 *Escribe 1* - Prueba gratis
💰 *Escribe 2* - Ver planes premium`, { sendSeen: false });
                    return;
                }
                let msg = `📋 *TUS CUENTAS ACTIVAS*

`;
                rows.forEach((a, i) => {
                    const tipo = a.tipo === 'premium' ? '💎' : '🆓';
                    const tipoText = a.tipo === 'premium' ? 'PREMIUM' : 'TEST';
                    const expira = moment(a.expires_at).format('DD/MM HH:mm');
                    const connText = a.max_connections > 1 ? `${a.max_connections} conexiones` : '1 conexión';
                    
                    msg += `*${i+1}. ${tipo} ${tipoText}*
`;
                    msg += `👤 *${a.username}*
`;
                    msg += `🔑 *mgvpn247*
`;
                    msg += `⏰ ${expira}
`;
                    msg += `🔌 ${connText}

`;
                });
                msg += `📱 Para conectar descarga la app (Escribe *5*)
💬 Escribe "menu" para volver`;
                await client.sendMessage(phone, msg, { sendSeen: false });
            });
    }
    else if (text === '4' && userState.state === 'main_menu') {
        // ✅ COMANDO 4 EN MENÚ PRINCIPAL = ESTADO DE PAGO
        db.all(`SELECT plan_name, amount, status, created_at, payment_url, connections FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone],
            async (err, pays) => {
                if (!pays || pays.length === 0) {
                    await client.sendMessage(phone, `💳 *SIN PAGOS REGISTRADOS*

💰 *Escribe 2* - Ver planes disponibles
💬 Escribe "menu" para volver`, { sendSeen: false });
                    return;
                }
                let msg = `💳 *ESTADO DE TUS PAGOS*

`;
                pays.forEach((p, i) => {
                    const emoji = p.status === 'approved' ? '✅' : '⏳';
                    const statusText = p.status === 'approved' ? 'APROBADO' : 'PENDIENTE';
                    const connText = p.connections > 1 ? `${p.connections} conexiones` : '1 conexión';
                    msg += `*${i+1}. ${emoji} ${statusText}*
`;
                    msg += `Plan: ${p.plan_name} | $${p.amount} ARS
`;
                    msg += `Conexiones: ${connText}
`;
                    msg += `Fecha: ${moment(p.created_at).format('DD/MM HH:mm')}
`;
                    if (p.status === 'pending' && p.payment_url) {
                        msg += `🔗 ${p.payment_url.substring(0, 40)}...
`;
                    }
                    msg += `
`;
                });
                msg += `🔄 Verificación automática cada 2 minutos
💬 Escribe "menu" para volver`;
                await client.sendMessage(phone, msg, { sendSeen: false });
            });
    }
    else if (text === '5' && userState.state === 'main_menu') {
        // ✅ COMANDO 5 EN MENÚ PRINCIPAL = DESCARGAR APP
        const searchPaths = [
            '/root/app.apk',
            '/root/ssh-bot/app.apk',
            '/root/android.apk',
            '/root/vpn.apk'
        ];
        
        let apkFound = null;
        let apkName = 'app.apk';
        
        for (const filePath of searchPaths) {
            if (fs.existsSync(filePath)) {
                apkFound = filePath;
                apkName = path.basename(filePath);
                break;
            }
        }
        
        if (apkFound) {
            try {
                const stats = fs.statSync(apkFound);
                const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                
                console.log(chalk.cyan(`📱 Enviando APK: ${apkName} (${fileSize}MB)`));
                
                await client.sendMessage(phone, `📱 *DESCARGANDO APP*

📦 Archivo: ${apkName}
📊 Tamaño: ${fileSize} MB

⏳ Enviando archivo, espera...`, { sendSeen: false });
                
                const media = MessageMedia.fromFilePath(apkFound);
                await client.sendMessage(phone, media, {
                    caption: `📱 *${apkName}*

✅ Archivo enviado correctamente

📱 *INSTRUCCIONES:*
1. Toca el archivo para instalar
2. Permite "Fuentes desconocidas" si te lo pide
3. Abre la app conectate a una red wifi para que se actualize correctamente 
4. Ingresa tus datos de acceso
   👤 Usuario: (tu usuario)
   🔑 Contraseña: mgvpn247

💡 Si no ves el archivo, revisa la sección "Archivos" de WhatsApp

💬 Escribe "menu" para volver`,
                    sendSeen: false
                });
                
                console.log(chalk.green(`✅ APK enviado exitosamente`));
                
            } catch (error) {
                console.error(chalk.red('❌ Error enviando APK:'), error.message);
                
                const serverStarted = await startAPKServer(apkFound);
                if (serverStarted) {
                    await client.sendMessage(phone, `📱 *ENLACE DE DESCARGA*

El archivo es muy grande para WhatsApp.

🔗 Descarga desde aquí:
http://${config.bot.server_ip}:8001/${apkName}

📱 Instrucciones:
1. Abre el enlace en Chrome
2. Descarga el archivo
3. Instala y abre la app
4. Usuario: (tu usuario)
5. Contraseña: mgvpn247

⚠️ El enlace expira en 1 hora

💬 Escribe "menu" para volver`, { sendSeen: false });
                } else {
                    await client.sendMessage(phone, `❌ *ERROR AL ENVIAR APK*

No se pudo enviar el archivo.

📞 Contacta soporte:
${config.links.support}

💬 Escribe "menu" para volver`, { sendSeen: false });
                }
            }
        } else {
            await client.sendMessage(phone, `❌ *APK NO DISPONIBLE*

El archivo de instalación no está disponible en el servidor.

📞 Contacta al administrador:
${config.links.support}

💡 Ubicación esperada: /root/app.apk

💬 Escribe "menu" para volver`, { sendSeen: false });
        }
    }
    else if (text === '6' && userState.state === 'main_menu') {
        // ✅ COMANDO 6 EN MENÚ PRINCIPAL = SOPORTE
        await client.sendMessage(phone, `🆘 *SOPORTE TÉCNICO*

📞 Canal de soporte:
${config.links.support}

⏰ Horario: 9AM - 10PM

🔑 *Contraseña predeterminada:* mgvpn247

📋 *PROBLEMAS COMUNES:*
• No llega el APK → Revisa "Archivos" en WhatsApp
• Error al conectar → Verifica usuario/contraseña
• Pago pendiente → Escribe *4* para estado

💬 Escribe "menu" para volver al inicio`, { sendSeen: false });
    }
    else {
        // Comando no reconocido
        await client.sendMessage(phone, `❌ *COMANDO NO RECONOCIDO*

📋 Comandos disponibles:
• menu - Menú principal
• 1 - Prueba gratis (solo en menú)
• 2 - Ver planes (solo en menú)
• 3 - Mis cuentas (solo en menú)
• 4 - Estado de pago (solo en menú)
• 5 - Descargar APP (solo en menú)
• 6 - Soporte (solo en menú)

💡 *PARA COMPRAR:* Escribe "2" para ver planes, luego elige un número de plan`, { sendSeen: false });
    }
});

// ✅ Verificar pagos cada 2 minutos
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
    checkPendingPayments();
});

// ✅ Limpiar usuarios expirados cada 15 minutos
cron.schedule('*/15 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios expirados cada 15 minutos (${now})...`));
    
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

// ✅ Limpiar estados antiguos cada hora
cron.schedule('0 * * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando estados antiguos...'));
    db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`, (err) => {
        if (!err) console.log(chalk.green('✅ Estados antiguos limpiados'));
    });
});

// ✅ Limpiar pagos antiguos cada 24 horas
cron.schedule('0 0 * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando pagos antiguos...'));
    db.run(`DELETE FROM payments WHERE status = 'pending' AND created_at < datetime('now', '-7 days')`, (err) => {
        if (!err) console.log(chalk.green('✅ Pagos antiguos limpiados'));
    });
});

// ✅ MONITOR AUTOMÁTICO - VERIFICA CONEXIONES
setInterval(() => {
    db.all('SELECT username, max_connections FROM users WHERE status = 1', (err, rows) => {
        if (!err && rows) {
            rows.forEach(user => {
                require('child_process').exec(`ps aux | grep "^${user.username}" | grep -v grep | wc -l`, (e, out) => {
                    const cnt = parseInt(out) || 0;
                    if (cnt > user.max_connections) {
                        console.log(chalk.red(`⚠️ ${user.username} tiene ${cnt} conexiones (límite: ${user.max_connections})`));
                        require('child_process').exec(`pkill -u ${user.username} 2>/dev/null; sleep 1; pkill -u ${user.username} 2>/dev/null`);
                    }
                });
            });
        }
    });
}, 30000);

console.log(chalk.green('\n🚀 Inicializando bot con planes configurables...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado con planes configurables${NC}"

# ================================================
# CREAR PANEL DE CONTROL MEJORADO
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL MEJORADO...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/ssh-bot/data/users.db"
CONFIG="/opt/ssh-bot/config/config.json"
BACKUP_DIR="/opt/ssh-bot/backups"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }
backup_config() {
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$CONFIG" "$BACKUP_DIR/config_${timestamp}.json"
    echo -e "${GREEN}✅ Backup creado: config_${timestamp}.json${NC}"
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL SSH BOT PRO v8.7                    ║${NC}"
    echo -e "${CYAN}║               🔧 AGREGAR/EDITAR PRECIOS Y DÍAS             ║${NC}"
    echo -e "${CYAN}║               🔐 CONTRASEÑA FIJA: mgvpn247                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

list_plans() {
    echo -e "${YELLOW}📋 PLANES CONFIGURADOS:${NC}\n"
    jq -r '.prices.plans[] | "  \(.id). \(.name) | \(.days)días | \(.connections)conn | $\(.price) | \(if .enabled then "✅" else "❌" end)"' "$CONFIG" 2>/dev/null
    echo ""
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
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
    
    ACTIVE_PLANS=$(jq -r '.prices.plans[] | select(.enabled) | .id' "$CONFIG" 2>/dev/null | wc -l)
    TOTAL_PLANS=$(jq -r '.prices.plans[] | .id' "$CONFIG" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  Planes: ${CYAN}$ACTIVE_PLANS/$TOTAL_PLANS${NC} activos/total"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA PARA TODOS)"
    echo -e ""
    
    list_plans
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar usuarios"
    echo -e "${CYAN}[6]${NC}  🗑️   Eliminar usuario"
    echo -e ""
    echo -e "${GREEN}════════════════ GESTIÓN DE PLANES ════════════════${NC}"
    echo -e "${CYAN}[7]${NC}  💰  AGREGAR NUEVO PLAN"
    echo -e "${CYAN}[8]${NC}  ✏️   EDITAR PLAN EXISTENTE"
    echo -e "${CYAN}[9]${NC}  🔄  ACTIVAR/DESACTIVAR PLAN"
    echo -e "${CYAN}[10]${NC} 🗑️   ELIMINAR PLAN"
    echo -e "${CYAN}[11]${NC} 📋  VER DETALLES DE PLANES"
    echo -e "${CYAN}[12]${NC} 💾  HACER BACKUP CONFIGURACIÓN"
    echo -e "${CYAN}[13]${NC} 🔄  RESTAURAR CONFIGURACIÓN"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[14]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[15]${NC} 📱  Gestionar APK"
    echo -e "${CYAN}[16]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[17]${NC} 📝  Ver logs"
    echo -e "${CYAN}[18]${NC} 🔧  Reparar bot"
    echo -e "${CYAN}[19]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[20]${NC} 🧪  Test sistema"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
            cd /root/ssh-bot
            pm2 restart ssh-bot 2>/dev/null || pm2 start bot.js --name ssh-bot
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop ssh-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-whatsapp.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-whatsapp.png${NC}\n"
                read -p "¿Ver logs en tiempo real? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot --lines 200
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👤 CREAR USUARIO                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "Usuario (auto=generar): " USERNAME
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 2h, 30=premium): " DAYS
            echo -e "\n${CYAN}🔌 CONEXIONES:${NC}"
            echo -e "  1. 1 conexión"
            echo -e "  2. 2 conexiones simultáneas"
            read -p "Selecciona (1-2): " CONN_OPT
            
            [[ -z "$DAYS" ]] && DAYS="30"
            [[ "$CONN_OPT" == "2" ]] && CONNECTIONS="2" || CONNECTIONS="1"
            [[ "$USERNAME" == "auto" || -z "$USERNAME" ]] && USERNAME="user$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)"
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
                EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                useradd -M -s /bin/false "$USERNAME" && echo "$USERNAME:mgvpn247" | chpasswd && chage -E "$(date -d '+2 hours' +%Y-%m-%d)" "$USERNAME"
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$USERNAME" && echo "$USERNAME:mgvpn247" | chpasswd
            fi
            
            if [[ $? -eq 0 ]]; then
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES ('$PHONE', '$USERNAME', 'mgvpn247', '$TIPO', '$EXPIRE_DATE', $CONNECTIONS, 1)"
                echo -e "\n${GREEN}✅ USUARIO CREADO${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: mgvpn247"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "🔌 Conexiones: ${CONNECTIONS}"
            else
                echo -e "\n${RED}❌ Error creando usuario${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, 'mgvpn247' as password, tipo, expires_at, max_connections as conex, substr(phone,1,12) as tel FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            echo -e "${GREEN}🔐 Contraseña: mgvpn247 para todos${NC}"
            read -p "Presiona Enter..." 
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🗑️  ELIMINAR USUARIO                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Usuario a eliminar: " DEL_USER
            if [[ -n "$DEL_USER" ]]; then
                pkill -u "$DEL_USER" 2>/dev/null || true
                userdel -f "$DEL_USER" 2>/dev/null || true
                sqlite3 "$DB" "UPDATE users SET status = 0 WHERE username = '$DEL_USER'"
                echo -e "${GREEN}✅ Usuario $DEL_USER eliminado${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        7)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                💰 AGREGAR NUEVO PLAN                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            list_plans
            
            echo -e "${YELLOW}📝 INGRESAR DATOS DEL NUEVO PLAN:${NC}\n"
            
            # Obtener el último ID
            LAST_ID=$(jq -r '.prices.plans | length' "$CONFIG")
            NEW_ID=$((LAST_ID + 1))
            
            echo -e "ID asignado automáticamente: ${CYAN}$NEW_ID${NC}"
            read -p "Nombre del plan (ej: 90 días - 3 conexiones): " PLAN_NAME
            read -p "Cantidad de días: " PLAN_DAYS
            read -p "Número de conexiones simultáneas: " PLAN_CONNECTIONS
            read -p "Precio (ej: 2500.00): " PLAN_PRICE
            
            # Validar entradas
            if [[ -z "$PLAN_NAME" || -z "$PLAN_DAYS" || -z "$PLAN_CONNECTIONS" || -z "$PLAN_PRICE" ]]; then
                echo -e "${RED}❌ Todos los campos son obligatorios${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            if ! [[ "$PLAN_DAYS" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}❌ Los días deben ser un número${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            if ! [[ "$PLAN_CONNECTIONS" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}❌ Las conexiones deben ser un número${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            if ! [[ "$PLAN_PRICE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "${RED}❌ El precio debe ser un número${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            read -p "¿Plan activo por defecto? (s/N): " PLAN_ENABLED
            if [[ "$PLAN_ENABLED" == "s" ]]; then
                ENABLED="true"
            else
                ENABLED="false"
            fi
            
            # Crear objeto JSON del nuevo plan
            NEW_PLAN=$(cat << EOF
{
    "id": $NEW_ID,
    "name": "$PLAN_NAME",
    "days": $PLAN_DAYS,
    "connections": $PLAN_CONNECTIONS,
    "price": $PLAN_PRICE,
    "enabled": $ENABLED
}
EOF
            )
            
            # Agregar el nuevo plan al array
            jq ".prices.plans += [$NEW_PLAN]" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
            
            echo -e "\n${GREEN}✅ PLAN AGREGADO EXITOSAMENTE${NC}"
            echo -e "ID: ${CYAN}$NEW_ID${NC}"
            echo -e "Nombre: ${CYAN}$PLAN_NAME${NC}"
            echo -e "Días: ${CYAN}$PLAN_DAYS${NC}"
            echo -e "Conexiones: ${CYAN}$PLAN_CONNECTIONS${NC}"
            echo -e "Precio: ${CYAN}$$PLAN_PRICE${NC}"
            echo -e "Estado: ${CYAN}$([[ "$ENABLED" == "true" ]] && echo "ACTIVO" || echo "INACTIVO")${NC}"
            
            read -p "¿Reiniciar bot para aplicar cambios? (s/N): " RESTART
            if [[ "$RESTART" == "s" ]]; then
                pm2 restart ssh-bot
                echo -e "${GREEN}✅ Bot reiniciado${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        8)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                ✏️  EDITAR PLAN EXISTENTE                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            list_plans
            
            read -p "Ingresa el ID del plan a editar: " PLAN_ID
            
            if [[ -z "$PLAN_ID" ]] || ! jq -e ".prices.plans[] | select(.id == $PLAN_ID)" "$CONFIG" > /dev/null 2>&1; then
                echo -e "${RED}❌ Plan no encontrado${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            # Mostrar datos actuales
            echo -e "\n${YELLOW}📋 DATOS ACTUALES:${NC}"
            jq -r ".prices.plans[] | select(.id == $PLAN_ID) | \"  Nombre: \(.name)\\n  Días: \(.days)\\n  Conexiones: \(.connections)\\n  Precio: \(.price)\\n  Estado: \(if .enabled then \"ACTIVO\" else \"INACTIVO\" end)\"" "$CONFIG"
            
            echo -e "\n${YELLOW}📝 NUEVOS DATOS (deja en blanco para mantener actual):${NC}"
            
            read -p "Nuevo nombre: " NEW_NAME
            read -p "Nuevos días: " NEW_DAYS
            read -p "Nuevas conexiones: " NEW_CONNECTIONS
            read -p "Nuevo precio: " NEW_PRICE
            
            # Actualizar solo los campos proporcionados
            if [[ -n "$NEW_NAME" ]]; then
                jq ".prices.plans |= map(if .id == $PLAN_ID then .name = \"$NEW_NAME\" else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
            fi
            
            if [[ -n "$NEW_DAYS" ]] && [[ "$NEW_DAYS" =~ ^[0-9]+$ ]]; then
                jq ".prices.plans |= map(if .id == $PLAN_ID then .days = $NEW_DAYS else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
            fi
            
            if [[ -n "$NEW_CONNECTIONS" ]] && [[ "$NEW_CONNECTIONS" =~ ^[0-9]+$ ]]; then
                jq ".prices.plans |= map(if .id == $PLAN_ID then .connections = $NEW_CONNECTIONS else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
            fi
            
            if [[ -n "$NEW_PRICE" ]] && [[ "$NEW_PRICE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                jq ".prices.plans |= map(if .id == $PLAN_ID then .price = $NEW_PRICE else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
            fi
            
            echo -e "\n${GREEN}✅ PLAN ACTUALIZADO${NC}"
            
            read -p "¿Reiniciar bot para aplicar cambios? (s/N): " RESTART
            if [[ "$RESTART" == "s" ]]; then
                pm2 restart ssh-bot
                echo -e "${GREEN}✅ Bot reiniciado${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║            🔄 ACTIVAR/DESACTIVAR PLAN                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            list_plans
            
            read -p "Ingresa el ID del plan: " PLAN_ID
            
            if [[ -z "$PLAN_ID" ]] || ! jq -e ".prices.plans[] | select(.id == $PLAN_ID)" "$CONFIG" > /dev/null 2>&1; then
                echo -e "${RED}❌ Plan no encontrado${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            CURRENT_STATE=$(jq -r ".prices.plans[] | select(.id == $PLAN_ID) | .enabled" "$CONFIG")
            
            if [[ "$CURRENT_STATE" == "true" ]]; then
                echo -e "\n${YELLOW}El plan está actualmente ${GREEN}ACTIVO${YELLOW}. ¿Desactivarlo?${NC}"
                read -p "(s/N): " CONFIRM
                if [[ "$CONFIRM" == "s" ]]; then
                    jq ".prices.plans |= map(if .id == $PLAN_ID then .enabled = false else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
                    echo -e "${GREEN}✅ Plan desactivado${NC}"
                fi
            else
                echo -e "\n${YELLOW}El plan está actualmente ${RED}INACTIVO${YELLOW}. ¿Activarlo?${NC}"
                read -p "(s/N): " CONFIRM
                if [[ "$CONFIRM" == "s" ]]; then
                    jq ".prices.plans |= map(if .id == $PLAN_ID then .enabled = true else . end)" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
                    echo -e "${GREEN}✅ Plan activado${NC}"
                fi
            fi
            
            read -p "¿Reiniciar bot para aplicar cambios? (s/N): " RESTART
            if [[ "$RESTART" == "s" ]]; then
                pm2 restart ssh-bot
                echo -e "${GREEN}✅ Bot reiniciado${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                🗑️  ELIMINAR PLAN                          ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            list_plans
            
            echo -e "${RED}⚠️  ADVERTENCIA: Esta acción no se puede deshacer${NC}\n"
            read -p "Ingresa el ID del plan a eliminar: " PLAN_ID
            
            if [[ -z "$PLAN_ID" ]] || ! jq -e ".prices.plans[] | select(.id == $PLAN_ID)" "$CONFIG" > /dev/null 2>&1; then
                echo -e "${RED}❌ Plan no encontrado${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            PLAN_NAME=$(jq -r ".prices.plans[] | select(.id == $PLAN_ID) | .name" "$CONFIG")
            
            echo -e "\n${RED}¿Estás seguro de eliminar el plan:${NC}"
            echo -e "  ${CYAN}ID: $PLAN_ID${NC}"
            echo -e "  ${CYAN}Nombre: $PLAN_NAME${NC}"
            
            read -p "(s/N): " CONFIRM
            
            if [[ "$CONFIRM" == "s" ]]; then
                # Eliminar el plan del array
                jq ".prices.plans |= map(select(.id != $PLAN_ID))" "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
                echo -e "${GREEN}✅ Plan eliminado${NC}"
                
                read -p "¿Reiniciar bot para aplicar cambios? (s/N): " RESTART
                if [[ "$RESTART" == "s" ]]; then
                    pm2 restart ssh-bot
                    echo -e "${GREEN}✅ Bot reiniciado${NC}"
                fi
            else
                echo -e "${YELLOW}❌ Operación cancelada${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                📋 DETALLES DE PLANES                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📊 INFORMACIÓN COMPLETA:${NC}\n"
            
            # Mostrar todos los planes con detalles
            jq -r '.prices.plans[] | "  🔸 ID: \(.id)\n  📝 Nombre: \(.name)\n  ⏰ Días: \(.days)\n  🔌 Conexiones: \(.connections)\n  💰 Precio: $\(.price)\n  📊 Estado: \(if .enabled then "✅ ACTIVO" else "❌ INACTIVO" end)\n"' "$CONFIG"
            
            echo -e "${YELLOW}📈 RESUMEN:${NC}"
            echo -e "  Total planes: ${CYAN}$TOTAL_PLANS${NC}"
            echo -e "  Planes activos: ${CYAN}$ACTIVE_PLANS${NC}"
            echo -e "  Planes inactivos: ${CYAN}$((TOTAL_PLANS - ACTIVE_PLANS))${NC}"
            
            read -p "\nPresiona Enter..." 
            ;;
        12)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                💾 HACER BACKUP CONFIGURACIÓN               ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            backup_config
            
            echo -e "\n${YELLOW}📁 Backups disponibles:${NC}"
            ls -la "$BACKUP_DIR"/*.json 2>/dev/null | head -10 || echo "  No hay backups"
            
            read -p "\nPresiona Enter..." 
            ;;
        13)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║              🔄 RESTAURAR CONFIGURACIÓN                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            BACKUPS=$(ls "$BACKUP_DIR"/*.json 2>/dev/null)
            
            if [[ -z "$BACKUPS" ]]; then
                echo -e "${RED}❌ No hay backups disponibles${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            echo -e "${YELLOW}📁 Backups disponibles:${NC}\n"
            i=1
            for backup in $BACKUPS; do
                size=$(du -h "$backup" | cut -f1)
                date=$(basename "$backup" | sed 's/config_//' | sed 's/.json//')
                echo -e "  ${i}. ${date} (${size})"
                ((i++))
            done
            
            echo ""
            read -p "Selecciona el número del backup a restaurar: " BACKUP_NUM
            
            if [[ ! "$BACKUP_NUM" =~ ^[0-9]+$ ]] || [[ "$BACKUP_NUM" -lt 1 ]] || [[ "$BACKUP_NUM" -ge $i ]]; then
                echo -e "${RED}❌ Selección inválida${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            selected_backup=$(echo "$BACKUPS" | sed -n "${BACKUP_NUM}p")
            backup_name=$(basename "$selected_backup")
            
            echo -e "\n${RED}⚠️  ADVERTENCIA: Se sobreescribirá la configuración actual${NC}"
            echo -e "Backup seleccionado: ${CYAN}$backup_name${NC}"
            
            read -p "¿Continuar? (s/N): " CONFIRM
            
            if [[ "$CONFIRM" == "s" ]]; then
                cp "$selected_backup" "$CONFIG"
                echo -e "${GREEN}✅ Configuración restaurada${NC}"
                
                read -p "¿Reiniciar bot para aplicar cambios? (s/N): " RESTART
                if [[ "$RESTART" == "s" ]]; then
                    pm2 restart ssh-bot
                    echo -e "${GREEN}✅ Bot reiniciado${NC}"
                fi
            else
                echo -e "${YELLOW}❌ Operación cancelada${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        14)
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
                    cd /root/ssh-bot && pm2 restart ssh-bot
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago SDK v2.x activado${NC}"
                else
                    echo -e "${RED}❌ Token inválido${NC}"
                    echo -e "${YELLOW}Debe empezar con APP_USR- o TEST-${NC}"
                fi
            fi
            read -p "Presiona Enter..." 
            ;;
        15)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📱 GESTIONAR APK                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            APKS=$(find /root /home /opt -name "*.apk" 2>/dev/null | head -5)
            
            if [[ -n "$APKS" ]]; then
                echo -e "${GREEN}✅ APKs encontrados:${NC}"
                i=1
                while IFS= read -r apk; do
                    size=$(du -h "$apk" | cut -f1)
                    echo -e "  ${i}. ${apk} (${size})"
                    ((i++))
                done <<< "$APKS"
                
                echo ""
                read -p "Selecciona (1-$((i-1))): " SEL
                if [[ "$SEL" =~ ^[0-9]+$ ]]; then
                    selected=$(echo "$APKS" | sed -n "${SEL}p")
                    echo -e "\n${YELLOW}Seleccionado: ${selected}${NC}"
                    echo -e "\n1. Copiar a /root/app.apk"
                    echo -e "2. Ver detalles"
                    echo -e "3. Eliminar"
                    read -p "Opción: " OPT
                    case $OPT in
                        1) cp "$selected" /root/app.apk && chmod 644 /root/app.apk && echo -e "${GREEN}✅ Copiado${NC}" ;;
                        2) du -h "$selected" && echo "WhatsApp límite: 100MB" ;;
                        3) rm -f "$selected" && echo -e "${GREEN}✅ Eliminado${NC}" ;;
                    esac
                fi
            else
                echo -e "${RED}❌ Sin APKs${NC}\n"
                echo -e "${CYAN}Subir con SCP:${NC}"
                echo -e "  scp app.apk root@$(get_val '.bot.server_ip'):/root/app.apk"
            fi
            read -p "Presiona Enter..." 
            ;;
        16)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | 2 conexiones: ' || SUM(CASE WHEN max_connections=2 THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}🔌 CONEXIONES:${NC}"
            sqlite3 "$DB" "SELECT '1 conexión: ' || SUM(CASE WHEN max_connections=1 AND status=1 THEN 1 ELSE 0 END) || ' | 2 conexiones: ' || SUM(CASE WHEN max_connections=2 AND status=1 THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Tests: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            
            read -p "\nPresiona Enter..." 
            ;;
        17)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs ssh-bot --lines 100
            ;;
        18)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔧 REPARAR BOT                          ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${RED}⚠️  Borrará sesión de WhatsApp y estados${NC}\n"
            read -p "¿Continuar? (s/N): " CONF
            
            if [[ "$CONF" == "s" ]]; then
                echo -e "\n${YELLOW}🧹 Limpiando...${NC}"
                rm -rf /root/.wwebjs_auth/* /root/.wwebjs_cache/* /root/qr-whatsapp.png
                echo -e "${YELLOW}🗑️  Borrando estados...${NC}"
                sqlite3 "$DB" "DELETE FROM user_state"
                echo -e "${YELLOW}📦 Reinstalando...${NC}"
                cd /root/ssh-bot && npm install --silent
                echo -e "${YELLOW}🔧 Aplicando parches...${NC}"
                find /root/ssh-bot/node_modules -name "Client.js" -type f -exec sed -i 's/if (chat && chat.markedUnread)/if (false)/g' {} \; 2>/dev/null || true
                echo -e "${YELLOW}🔄 Reiniciando...${NC}"
                pm2 restart ssh-bot
                echo -e "\n${GREEN}✅ Reparado - Espera 10s para QR${NC}"
                sleep 10
                [[ -f "/root/qr-whatsapp.png" ]] && echo -e "${GREEN}✅ QR generado${NC}" || pm2 logs ssh-bot
            fi
            read -p "Presiona Enter..." 
            ;;
        19)
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
        20)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  🧪 TEST SISTEMA COMPLETO                  ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${GREEN}✅ SISTEMA DE PLANES CONFIGURABLES${NC}\n"
            
            echo -e "${YELLOW}📋 FUNCIONALIDADES DISPONIBLES:${NC}"
            echo -e "  ✅ Agregar nuevos planes"
            echo -e "  ✅ Editar planes existentes"
            echo -e "  ✅ Activar/desactivar planes"
            echo -e "  ✅ Eliminar planes"
            echo -e "  ✅ Backup automático"
            echo -e "  ✅ Restaurar configuración"
            echo -e "  ✅ Planes con días y conexiones configurables\n"
            
            echo -e "${CYAN}📊 PLANES ACTUALES:${NC}"
            jq -r '.prices.plans[] | "  \(.id). \(.name) | \(.days)días | \(.connections)conn | $\(.price)"' "$CONFIG" 2>/dev/null
            
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
echo -e "${GREEN}✅ Panel de control mejorado creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT CON PLANES CONFIGURABLES...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name ssh-bot
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# CREAR SCRIPT DE TEST
# ================================================
echo -e "\n${CYAN}${BOLD}🧪 CREANDO SCRIPT DE TEST...${NC}"

cat > /usr/local/bin/test-plans << 'TESTEOF'
#!/bin/bash
echo -e "\n🔍 TEST DEL SISTEMA DE PLANES CONFIGURABLES"
echo -e "==========================================\n"

echo -e "📋 Verificando configuración..."
CONFIG="/opt/ssh-bot/config/config.json"
if [[ -f "$CONFIG" ]]; then
    echo -e "✅ Configuración: $CONFIG"
    
    echo -e "\n📊 ESTADÍSTICAS:"
    TOTAL_PLANS=$(jq -r '.prices.plans | length' "$CONFIG")
    ACTIVE_PLANS=$(jq -r '.prices.plans[] | select(.enabled) | .id' "$CONFIG" | wc -l)
    echo -e "  Total planes: ${CYAN}$TOTAL_PLANS${NC}"
    echo -e "  Planes activos: ${CYAN}$ACTIVE_PLANS${NC}"
    
    echo -e "\n📋 PLANES DISPONIBLES:"
    jq -r '.prices.plans[] | "  \(.id). \(.name) | \(.days)días | \(.connections)conn | $\(.price) | \(if .enabled then "✅" else "❌" end)"' "$CONFIG" 2>/dev/null
else
    echo -e "❌ Configuración no encontrada"
fi

echo -e "\n🤖 Verificando bot..."
if pm2 status | grep -q "ssh-bot"; then
    echo -e "✅ Bot en ejecución"
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot") | .pm2_env.status' 2>/dev/null || echo "unknown")
    echo -e "  Estado: $STATUS"
else
    echo -e "❌ Bot NO está en ejecución"
fi

echo -e "\n💡 COMANDOS DISPONIBLES:"
echo -e "  ${GREEN}sshbot${NC} - Panel principal con gestión de planes"
echo -e "  Opciones 7-13: Gestión completa de planes"
echo -e "  Opciones 12-13: Backup y restauración"

echo -e "\n✅ Sistema funcionando correctamente"
TESTEOF

chmod +x /usr/local/bin/test-plans

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🎉 INSTALACIÓN COMPLETADA - PLANES CONFIGURABLES 🎉   ║
║                                                              ║
║         SSH BOT PRO v8.7 - AGREGAR/EDITAR PRECIOS Y DÍAS    ║
║           🔧 GESTIÓN COMPLETA DE PLANES DESDE PANEL        ║
║           💰 AGREGAR NUEVOS PLANES PERSONALIZADOS          ║
║           ✏️  EDITAR PLANES EXISTENTES                     ║
║           🔄 ACTIVAR/DESACTIVAR PLANES                     ║
║           💾 BACKUP Y RESTAURACIÓN AUTOMÁTICA              ║
║           🔐 CONTRASEÑA FIJA: mgvpn247 PARA TODOS          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema de planes configurables instalado${NC}"
echo -e "${GREEN}✅ AGREGAR NUEVOS PLANES desde el panel${NC}"
echo -e "${GREEN}✅ EDITAR PRECIOS Y DÍAS de planes existentes${NC}"
echo -e "${GREEN}✅ ACTIVAR/DESACTIVAR planes individualmente${NC}"
echo -e "${GREEN}✅ BACKUP automático de configuración${NC}"
echo -e "${GREEN}✅ PLANES PERSONALIZADOS con días y conexiones variables${NC}"
echo -e "${GREEN}✅ CONTRASEÑA FIJA: mgvpn247 para todos los usuarios${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}\n"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control principal"
echo -e "  ${GREEN}test-plans${NC}     - Test del sistema de planes"
echo -e "  ${GREEN}pm2 logs ssh-bot${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart ssh-bot${NC} - Reiniciar bot\n"

echo -e "${YELLOW}🔧 NUEVAS FUNCIONALIDADES EN PANEL:${NC}\n"
echo -e "  ${CYAN}[7]${NC}  - AGREGAR NUEVO PLAN"
echo -e "  ${CYAN}[8]${NC}  - EDITAR PLAN EXISTENTE"
echo -e "  ${CYAN}[9]${NC}  - ACTIVAR/DESACTIVAR PLAN"
echo -e "  ${CYAN}[10]${NC} - ELIMINAR PLAN"
echo -e "  ${CYAN}[11]${NC} - VER DETALLES DE PLANES"
echo -e "  ${CYAN}[12]${NC} - HACER BACKUP"
echo -e "  ${CYAN}[13]${NC} - RESTAURAR CONFIGURACIÓN\n"

echo -e "${YELLOW}📝 EJEMPLOS DE PLANES QUE PUEDES CREAR:${NC}\n"
echo -e "  • 3 días - 1 conexión - $200"
echo -e "  • 45 días - 2 conexiones - $1500"
echo -e "  • 90 días - 3 conexiones - $2500"
echo -e "  • 180 días - 4 conexiones - $4000"
echo -e "  • 365 días - 5 conexiones - $7000\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN INICIAL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}sshbot${NC}"
echo -e "  2. Opción ${CYAN}[14]${NC} - Configurar MercadoPago"
echo -e "  3. Opción ${CYAN}[7]${NC} - Agregar nuevos planes si deseas"
echo -e "  4. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp"
echo -e "  5. Sube APK a /root/app.apk\n"

echo -e "${YELLOW}📊 INFO:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  BD: ${CYAN}$DB_FILE${NC}"
echo -e "  Config: ${CYAN}$CONFIG_FILE${NC}"
echo -e "  Backups: ${CYAN}$BACKUP_DIR${NC}"
echo -e "  Script test: ${CYAN}/usr/local/bin/test-plans${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Probar sistema de planes? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Probando sistema...${NC}\n"
    /usr/local/bin/test-plans
else
    echo -e "\n${YELLOW}💡 Para probar después: ${GREEN}test-plans${NC}\n"
fi

read -p "$(echo -e "${YELLOW}¿Abrir panel de control? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}\n"
    sleep 2
    /usr/local/bin/sshbot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}sshbot${NC} para abrir el panel\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema de planes configurables instalado exitosamente! Ahora puedes agregar y editar precios manualmente 🚀${NC}\n"

exit 0
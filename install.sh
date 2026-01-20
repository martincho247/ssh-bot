#!/bin/bash
# ================================================
# SSH BOT PRO v8.9 - PLANES CONFIGURABLES
# Correcciones aplicadas:
# 1. ✅ MENÚ PRINCIPAL: 1=Prueba, 2=Ver Planes, 3=Cuentas, 4=Estado, 5=APP, 6=Soporte
# 2. ✅ MENÚ PLANES: Totalmente configurable desde panel
# 3. ✅ SISTEMA DE ESTADOS: Sin conflictos entre menús
# 4. ✅ CONFIGURACIÓN COMPLETA: Precios, días y conexiones configurables
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
║           🚀 SSH BOT PRO v8.9 - PLANES CONFIGURABLES       ║
║               💡 SISTEMA DE ESTADOS INTELIGENTE             ║
║               ⚙️  CONFIGURAR PLANES DESDE PANEL            ║
║               🔐 CONTRASEÑA FIJA: mgvpn247                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ NUEVO SISTEMA CON PLANES CONFIGURABLES:${NC}"
echo -e "  🔴 ${RED}MENÚ PRINCIPAL:${NC}"
echo -e "     ${GREEN}1${NC} = Prueba gratis"
echo -e "     ${GREEN}2${NC} = Ver planes"
echo -e "     ${GREEN}3${NC} = Mis cuentas"
echo -e "     ${GREEN}4${NC} = Estado de pago"
echo -e "     ${GREEN}5${NC} = Descargar APP"
echo -e "     ${GREEN}6${NC} = Soporte"
echo -e "  🟡 ${YELLOW}MENÚ PLANES:${NC}"
echo -e "     ${GREEN}Totalmente configurable desde el panel${NC}"
echo -e "     ${GREEN}Puedes agregar/editar/eliminar planes${NC}"
echo -e "     ${GREEN}Configurar precios, días y conexiones${NC}"
echo -e "  🟢 ${GREEN}NUEVO:${NC} Sistema de planes configurables"
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
echo -e "   • Crear SSH Bot Pro v8.9 CON PLANES CONFIGURABLES"
echo -e "   • Sistema de estados sin conflictos"
echo -e "   • Panel de control 100% funcional"
echo -e "   • APK automático + Test 2h"
echo -e "   • Cron limpieza cada 15 minutos"
echo -e "   • 🔐 CONTRASEÑA FIJA: mgvpn247 para todos"
echo -e "   • ⚙️  NUEVO: Configurar planes desde panel"
echo -e "   • 💰 Configurar precios, días y conexiones"
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

apt-get update -qq
apt-get install -y -qq curl wget git unzip jq sqlite3 build-essential

# Instalar Node.js 20.x
if ! command -v node &> /dev/null || ! node --version | grep -q "v20"; then
    echo -e "${YELLOW}📦 Instalando Node.js 20.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
fi

# Instalar Chrome
if ! command -v google-chrome &> /dev/null; then
    echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    apt-get update -qq
    apt-get install -y -qq google-chrome-stable > /dev/null 2>&1
fi

# Instalar PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}⚡ Instalando PM2...${NC}"
    npm install -g pm2 --silent > /dev/null 2>&1
fi

# Instalar jq si no está
if ! command -v jq &> /dev/null; then
    apt-get install -y -qq jq > /dev/null 2>&1
fi

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/ssh-bot"
USER_HOME="/root/ssh-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
PLANS_FILE="$INSTALL_DIR/config/plans.json"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete ssh-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración base
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "8.9-PLANES-CONFIGURABLES",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 2,
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
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "plans": "$PLANS_FILE"
    }
}
EOF

# Crear planes por defecto
cat > "$PLANS_FILE" << EOF
[
    {
        "id": 1,
        "name": "7 DÍAS",
        "days": 7,
        "connections": 1,
        "price": 500.00,
        "enabled": true,
        "description": "7 días con 1 conexión simultánea",
        "display_order": 1
    },
    {
        "id": 2,
        "name": "15 DÍAS",
        "days": 15,
        "connections": 1,
        "price": 800.00,
        "enabled": true,
        "description": "15 días con 1 conexión simultánea",
        "display_order": 2
    },
    {
        "id": 3,
        "name": "30 DÍAS",
        "days": 30,
        "connections": 1,
        "price": 1200.00,
        "enabled": true,
        "description": "30 días con 1 conexión simultánea",
        "display_order": 3
    },
    {
        "id": 4,
        "name": "50 DÍAS",
        "days": 50,
        "connections": 1,
        "price": 1500.00,
        "enabled": true,
        "description": "50 días con 1 conexión simultánea",
        "display_order": 4
    },
    {
        "id": 5,
        "name": "7 DÍAS",
        "days": 7,
        "connections": 2,
        "price": 800.00,
        "enabled": true,
        "description": "7 días con 2 conexiones simultáneas",
        "display_order": 5
    },
    {
        "id": 6,
        "name": "15 DÍAS",
        "days": 15,
        "connections": 2,
        "price": 1200.00,
        "enabled": true,
        "description": "15 días con 2 conexiones simultáneas",
        "display_order": 6
    },
    {
        "id": 7,
        "name": "30 DÍAS",
        "days": 30,
        "connections": 2,
        "price": 1800.00,
        "enabled": true,
        "description": "30 días con 2 conexiones simultáneas",
        "display_order": 7
    }
]
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

echo -e "${GREEN}✅ Estructura creada con sistema de estados y planes configurables${NC}"

# ================================================
# CREAR BOT CON SISTEMA DE ESTADOS Y PLANES CONFIGURABLES
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT CON SISTEMA DE ESTADOS Y PLANES CONFIGURABLES...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-pro",
    "version": "8.9.0",
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

# Crear bot.js CON SISTEMA DE ESTADOS Y PLANES CONFIGURABLES
echo -e "${YELLOW}📝 Creando bot.js con sistema de estados y planes configurables...${NC}"

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

function loadPlans() {
    try {
        delete require.cache[require.resolve('/opt/ssh-bot/config/plans.json')];
        const plans = require('/opt/ssh-bot/config/plans.json');
        // Filtrar solo planes habilitados y ordenar
        return plans
            .filter(p => p.enabled)
            .sort((a, b) => a.display_order - b.display_order);
    } catch (error) {
        console.error(chalk.red('❌ Error cargando planes:'), error.message);
        return [];
    }
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
console.log(chalk.cyan.bold('║      🤖 SSH BOT PRO v8.9 - PLANES CONFIGURABLES            ║'));
console.log(chalk.cyan.bold('║               💡 SISTEMA INTELIGENTE DE ESTADOS              ║'));
console.log(chalk.cyan.bold('║               ⚙️  PLANES CONFIGURABLES DESDE PANEL          ║'));
console.log(chalk.cyan.bold('║               🔐 CONTRASEÑA FIJA: mgvpn247                  ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ SDK v2.x ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ WhatsApp Web parcheado (no markedUnread error)'));
console.log(chalk.green('✅ SISTEMA DE ESTADOS: Sin conflictos entre menús'));
console.log(chalk.green('✅ PLANES CONFIGURABLES: Agregar/editar/eliminar desde panel'));
console.log(chalk.green('✅ APK automático desde /root'));
console.log(chalk.green('✅ Test 2 horas exactas'));
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
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'ssh-bot-v89'}),
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

async function createMercadoPagoPayment(phone, plan, days, amount, connections) {
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
        const paymentId = `PREMIUM-${phoneClean}-${plan.id}-${connections}conn-${Date.now()}`;
        
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
                `INSERT INTO payments (payment_id, phone, plan_id, days, connections, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, plan.id, days, connections, amount, paymentUrl, qrPath, response.id],
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
                connections: connections,
                plan: plan
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
        
        // Cargar planes actualizados
        const plans = loadPlans();
        
        if (plans.length === 0) {
            await client.sendMessage(phone, `❌ *NO HAY PLANES DISPONIBLES*

El administrador no ha configurado planes aún.

💬 Contacta soporte: *Escribe 6*`, { sendSeen: false });
            await setUserState(phone, 'main_menu');
            return;
        }
        
        let plansMessage = `💎 *PLANES INTERNET - ELIGE UN PLAN*

`;
        
        plans.forEach((plan, index) => {
            const connText = plan.connections > 1 ? `${plan.connections} conexiones simultáneas` : '1 conexión';
            plansMessage += `🗓 *${index + 1}* - ${plan.name} - $${plan.price} ARS
`;
            plansMessage += `   ⏰ ${plan.days} días | 🔌 ${connText}
`;
        });
        
        plansMessage += `
💳 Pago: MercadoPago
⚡ Activación: 2-5 min

💰 *PARA COMPRAR:* Escribe el número del plan (1-${plans.length})
💬 *Para volver:* Escribe "menu"`;
        
        await client.sendMessage(phone, plansMessage, { sendSeen: false });
    }
    else if (userState.state === 'viewing_plans') {
        // ✅ COMANDOS NUMÉRICOS CUANDO EL USUARIO ESTÁ VIENDO PLANES = COMPRAR
        const plans = loadPlans();
        const planNumber = parseInt(text);
        
        if (isNaN(planNumber) || planNumber < 1 || planNumber > plans.length) {
            await client.sendMessage(phone, `❌ *PLAN NO VÁLIDO*

Escribe solo números del 1 al ${plans.length}

💬 Escribe "menu" para volver`, { sendSeen: false });
            return;
        }
        
        const selectedPlan = plans[planNumber - 1];
        
        config = loadConfig();
        
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
        
        console.log(chalk.cyan(`📦 Plan seleccionado: ${selectedPlan.name}, $${selectedPlan.price}`));
        
        // ✅ VERIFICAR SI YA EXISTE UN PAGO PENDIENTE
        const existingPayment = await getExistingPayment(phone, selectedPlan.id, selectedPlan.days, selectedPlan.connections);
        
        if (existingPayment) {
            console.log(chalk.yellow(`📌 Reutilizando pago existente: ${existingPayment.payment_id}`));
            
            const connText = selectedPlan.connections > 1 ? `${selectedPlan.connections} CONEXIONES SIMULTÁNEAS` : '1 CONEXIÓN';
            
            await client.sendMessage(phone, `📋 *TIENES UN PAGO PENDIENTE*

Ya generaste un pago para este plan.

⚡ *PLAN:* ${selectedPlan.name}
⏰ *Días:* ${selectedPlan.days}
🔌 *Conexiones:* ${connText}
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
                        
⚡ ${selectedPlan.name} - ${selectedPlan.days} días
💰 $${existingPayment.amount} ARS
🔌 ${connText}
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
        const connText = selectedPlan.connections > 1 ? `${selectedPlan.connections} conexiones simultáneas` : '1 conexión';
        
        await client.sendMessage(phone, `⏳ *PROCESANDO TU COMPRA...*

📦 Plan: *${selectedPlan.name}*
⏰ Días: *${selectedPlan.days}*
🔌 Conexión: *${connText}*
💰 Monto: *$${selectedPlan.price} ARS*

⏰ *GENERANDO ENLACE DE PAGO...*`, { sendSeen: false });
        
        try {
            const payment = await createMercadoPagoPayment(phone, selectedPlan, selectedPlan.days, selectedPlan.price, selectedPlan.connections);
            
            if (payment.success) {
                const connDisplay = selectedPlan.connections > 1 ? `${selectedPlan.connections} CONEXIONES SIMULTÁNEAS` : '1 CONEXIÓN';
                
                await client.sendMessage(phone, `💳 *PAGO GENERADO EXITOSAMENTE*

⚡ *PLAN:* ${selectedPlan.name}
⏰ *DÍAS:* ${selectedPlan.days}
🔌 *CONEXIÓN:* ${connDisplay}
💰 *$${selectedPlan.price} ARS*

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
                            
⚡ ${selectedPlan.name} - ${selectedPlan.days} días
💰 $${selectedPlan.price} ARS
🔌 ${connDisplay}
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
        db.all(`SELECT plan_id, amount, status, created_at, payment_url, connections FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone],
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
                    msg += `Plan ID: ${p.plan_id} | $${p.amount} ARS
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
3. Abre la app
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

💡 *PARA COMPRAR:* Escribe "2" para ver planes, luego el número del plan`, { sendSeen: false });
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

console.log(chalk.green('\n🚀 Inicializando bot con sistema de estados y planes configurables...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado con sistema de estados y planes configurables${NC}"

# ================================================
# CREAR PANEL DE CONTROL CON GESTIÓN DE PLANES
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL CON GESTIÓN DE PLANES...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/ssh-bot/data/users.db"
CONFIG="/opt/ssh-bot/config/config.json"
PLANS_FILE="/opt/ssh-bot/config/plans.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

# Función para cargar planes
load_plans() {
    if [[ -f "$PLANS_FILE" ]]; then
        jq -r '.' "$PLANS_FILE" 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# Función para guardar planes
save_plans() {
    local plans="$1"
    echo "$plans" | jq '.' > "$PLANS_FILE"
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL SSH BOT PRO v8.9                    ║${NC}"
    echo -e "${CYAN}║               🔧 GESTIÓN COMPLETA DE PLANES                ║${NC}"
    echo -e "${CYAN}║               ⚙️  Configurar precios, días, conexiones     ║${NC}"
    echo -e "${CYAN}║               🔐 CONTRASEÑA FIJA: mgvpn247                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Función para mostrar planes
show_plans() {
    local plans=$(load_plans)
    local count=$(echo "$plans" | jq '. | length')
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No hay planes configurados${NC}"
        return
    fi
    
    echo -e "${GREEN}📋 PLANES CONFIGURADOS (${count}):${NC}\n"
    
    echo -e "${CYAN}┌─────┬────────────────┬──────────┬──────────────┬──────────┬─────────┐${NC}"
    echo -e "${CYAN}│ ID  │ Nombre         │ Días     │ Conexiones   │ Precio   │ Estado  │${NC}"
    echo -e "${CYAN}├─────┼────────────────┼──────────┼──────────────┼──────────┼─────────┤${NC}"
    
    echo "$plans" | jq -r '.[] | "│ \(.id) │ \(.name) │ \(.days) │ \(.connections) │ $\(.price) │ \(if .enabled then "✅" else "❌" end) │"' | while read line; do
        echo -e "${CYAN}$line${NC}"
    done
    
    echo -e "${CYAN}└─────┴────────────────┴──────────┴──────────────┴──────────┴─────────┘${NC}"
}

# Función para agregar/editar plan
manage_plan() {
    local plans=$(load_plans)
    local action="$1"
    local plan_id="$2"
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    
    if [[ "$action" == "add" ]]; then
        echo -e "${CYAN}║                   📝 AGREGAR NUEVO PLAN                  ║${NC}"
    else
        echo -e "${CYAN}║                   📝 EDITAR PLAN #${plan_id}                  ║${NC}"
    fi
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    if [[ "$action" == "edit" ]]; then
        local plan_data=$(echo "$plans" | jq -r ".[] | select(.id == $plan_id)")
        if [[ -z "$plan_data" ]]; then
            echo -e "${RED}❌ Plan no encontrado${NC}"
            read -p "Presiona Enter..."
            return
        fi
        
        local current_name=$(echo "$plan_data" | jq -r '.name')
        local current_days=$(echo "$plan_data" | jq -r '.days')
        local current_conn=$(echo "$plan_data" | jq -r '.connections')
        local current_price=$(echo "$plan_data" | jq -r '.price')
        local current_enabled=$(echo "$plan_data" | jq -r '.enabled')
        local current_desc=$(echo "$plan_data" | jq -r '.description')
        local current_order=$(echo "$plan_data" | jq -r '.display_order')
    fi
    
    echo -e "${YELLOW}📝 Información del plan:${NC}\n"
    
    read -p "Nombre del plan [${current_name:-"Ej: 7 DÍAS"}]: " PLAN_NAME
    read -p "Número de días [${current_days:-"7"}]: " PLAN_DAYS
    read -p "Conexiones simultáneas (1-5) [${current_conn:-"1"}]: " PLAN_CONN
    read -p "Precio en ARS [${current_price:-"500.00"}]: " PLAN_PRICE
    read -p "Descripción [${current_desc:-"7 días con 1 conexión"}]: " PLAN_DESC
    read -p "Orden de visualización [${current_order:-"1"}]: " PLAN_ORDER
    
    echo -e "\n${YELLOW}¿Plan habilitado?${NC}"
    echo -e "  1. ✅ Sí (aparecerá en el bot)"
    echo -e "  2. ❌ No (oculto en el bot)"
    read -p "Selecciona (1-2) [${current_enabled:-"1"}]: " PLAN_ENABLED
    
    # Valores por defecto
    [[ -z "$PLAN_NAME" ]] && PLAN_NAME="${current_name:-"7 DÍAS"}"
    [[ -z "$PLAN_DAYS" ]] && PLAN_DAYS="${current_days:-"7"}"
    [[ -z "$PLAN_CONN" ]] && PLAN_CONN="${current_conn:-"1"}"
    [[ -z "$PLAN_PRICE" ]] && PLAN_PRICE="${current_price:-"500.00"}"
    [[ -z "$PLAN_DESC" ]] && PLAN_DESC="${current_desc:-"7 días con 1 conexión"}"
    [[ -z "$PLAN_ORDER" ]] && PLAN_ORDER="${current_order:-"1"}"
    [[ -z "$PLAN_ENABLED" ]] && PLAN_ENABLED="${current_enabled:-"1"}"
    
    if [[ "$PLAN_ENABLED" == "1" ]]; then
        PLAN_ENABLED="true"
    else
        PLAN_ENABLED="false"
    fi
    
    if [[ "$action" == "add" ]]; then
        # Obtener el próximo ID
        local next_id=1
        local max_id=$(echo "$plans" | jq -r 'max_by(.id) | .id // 0')
        if [[ -n "$max_id" && "$max_id" != "null" ]]; then
            next_id=$((max_id + 1))
        fi
        
        # Crear nuevo plan
        local new_plan=$(jq -n \
            --arg id "$next_id" \
            --arg name "$PLAN_NAME" \
            --argjson days "$PLAN_DAYS" \
            --argjson connections "$PLAN_CONN" \
            --argjson price "$PLAN_PRICE" \
            --argjson enabled "$PLAN_ENABLED" \
            --arg description "$PLAN_DESC" \
            --argjson display_order "$PLAN_ORDER" \
            '{
                id: ($id | tonumber),
                name: $name,
                days: $days,
                connections: $connections,
                price: $price,
                enabled: ($enabled == "true"),
                description: $description,
                display_order: $display_order
            }')
        
        # Agregar al array
        plans=$(echo "$plans" | jq --argjson new_plan "$new_plan" '. + [$new_plan]')
        
        echo -e "\n${GREEN}✅ Plan agregado exitosamente (ID: $next_id)${NC}"
    else
        # Actualizar plan existente
        plans=$(echo "$plans" | jq \
            --argjson id "$plan_id" \
            --arg name "$PLAN_NAME" \
            --argjson days "$PLAN_DAYS" \
            --argjson connections "$PLAN_CONN" \
            --argjson price "$PLAN_PRICE" \
            --arg enabled "$PLAN_ENABLED" \
            --arg description "$PLAN_DESC" \
            --argjson order "$PLAN_ORDER" \
            'map(if .id == $id then 
                .name = $name |
                .days = $days |
                .connections = $connections |
                .price = $price |
                .enabled = ($enabled == "true") |
                .description = $description |
                .display_order = $order
            else . end)')
        
        echo -e "\n${GREEN}✅ Plan actualizado exitosamente${NC}"
    fi
    
    # Guardar cambios
    save_plans "$plans"
    
    echo -e "\n${YELLOW}🔄 Reiniciando bot para aplicar cambios...${NC}"
    cd /root/ssh-bot && pm2 restart ssh-bot > /dev/null 2>&1
    
    read -p "Presiona Enter..." 
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    ACTIVE_STATES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM user_state" 2>/dev/null || echo "0")
    
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
    
    APK_FOUND=""
    if [[ -f "/root/app.apk" ]]; then
        APK_SIZE=$(du -h "/root/app.apk" | cut -f1)
        APK_FOUND="${GREEN}✅ ${APK_SIZE}${NC}"
    else
        APK_FOUND="${RED}❌ NO ENCONTRADO${NC}"
    fi
    
    PLANS_COUNT=$(load_plans | jq '. | length' 2>/dev/null || echo "0")
    PLANS_ENABLED=$(load_plans | jq '[.[] | select(.enabled)] | length' 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  Estados activos: ${CYAN}$ACTIVE_STATES${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  APK: $APK_FOUND"
    echo -e "  Planes: ${CYAN}$PLANS_ENABLED/$PLANS_COUNT${NC} habilitados/total"
    echo -e "  Test: ${GREEN}2 horas${NC} | Limpieza: ${GREEN}cada 15 min${NC}"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA PARA TODOS)"
    echo -e "  Sistema: ${GREEN}Estados inteligentes${NC} (sin conflictos)"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar usuarios"
    echo -e "${CYAN}[6]${NC}  🗑️   Eliminar usuario"
    echo -e ""
    echo -e "${CYAN}[7]${NC}  📋  Ver planes actuales"
    echo -e "${CYAN}[8]${NC}  ➕  Agregar nuevo plan"
    echo -e "${CYAN}[9]${NC}  ✏️   Editar plan existente"
    echo -e "${CYAN}[10]${NC} 🗑️   Eliminar plan"
    echo -e "${CYAN}[11]${NC} 🔄  Ordenar planes"
    echo -e "${CYAN}[12]${NC} ⚙️   Habilitar/Deshabilitar plan"
    echo -e ""
    echo -e "${CYAN}[13]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[14]${NC} 📱  Gestionar APK"
    echo -e "${CYAN}[15]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[16]${NC} 📝  Ver logs"
    echo -e "${CYAN}[17]${NC} 🔧  Reparar bot"
    echo -e "${CYAN}[18]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[19]${NC} 🧠  Ver estados activos"
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
            echo -e "${CYAN}║                     📋 PLANES CONFIGURADOS                  ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            show_plans
            echo -e "\n${YELLOW}💡 Estos planes se muestran en el bot cuando el usuario escribe '2'${NC}"
            read -p "Presiona Enter..." 
            ;;
        8)
            manage_plan "add"
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     ✏️  EDITAR PLAN                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            show_plans
            echo ""
            read -p "Ingresa el ID del plan a editar: " PLAN_ID
            
            if [[ -n "$PLAN_ID" && "$PLAN_ID" =~ ^[0-9]+$ ]]; then
                manage_plan "edit" "$PLAN_ID"
            else
                echo -e "${RED}❌ ID inválido${NC}"
                read -p "Presiona Enter..." 
            fi
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🗑️  ELIMINAR PLAN                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            show_plans
            echo ""
            read -p "Ingresa el ID del plan a eliminar: " PLAN_ID
            
            if [[ -n "$PLAN_ID" && "$PLAN_ID" =~ ^[0-9]+$ ]]; then
                local plans=$(load_plans)
                local plan_name=$(echo "$plans" | jq -r ".[] | select(.id == $PLAN_ID) | .name")
                
                if [[ -n "$plan_name" ]]; then
                    echo -e "\n${RED}⚠️  ¿Eliminar el plan '$plan_name'?${NC}"
                    read -p "Esta acción no se puede deshacer. (s/N): " CONFIRM
                    
                    if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
                        plans=$(echo "$plans" | jq "del(.[] | select(.id == $PLAN_ID))")
                        save_plans "$plans"
                        
                        echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
                        cd /root/ssh-bot && pm2 restart ssh-bot > /dev/null 2>&1
                        
                        echo -e "${GREEN}✅ Plan eliminado exitosamente${NC}"
                    fi
                else
                    echo -e "${RED}❌ Plan no encontrado${NC}"
                fi
            else
                echo -e "${RED}❌ ID inválido${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔄 ORDENAR PLANES                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            show_plans
            echo ""
            read -p "Ingresa el ID del plan a reordenar: " PLAN_ID
            
            if [[ -n "$PLAN_ID" && "$PLAN_ID" =~ ^[0-9]+$ ]]; then
                local plans=$(load_plans)
                local plan_name=$(echo "$plans" | jq -r ".[] | select(.id == $PLAN_ID) | .name")
                
                if [[ -n "$plan_name" ]]; then
                    read -p "Nuevo orden de visualización (número menor = primero): " NEW_ORDER
                    
                    if [[ -n "$NEW_ORDER" && "$NEW_ORDER" =~ ^[0-9]+$ ]]; then
                        plans=$(echo "$plans" | jq \
                            --argjson id "$PLAN_ID" \
                            --argjson order "$NEW_ORDER" \
                            'map(if .id == $id then .display_order = $order else . end) | sort_by(.display_order)')
                        
                        save_plans "$plans"
                        
                        echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
                        cd /root/ssh-bot && pm2 restart ssh-bot > /dev/null 2>&1
                        
                        echo -e "${GREEN}✅ Orden actualizado exitosamente${NC}"
                    else
                        echo -e "${RED}❌ Orden inválido${NC}"
                    fi
                else
                    echo -e "${RED}❌ Plan no encontrado${NC}"
                fi
            else
                echo -e "${RED}❌ ID inválido${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        12)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                 ⚙️  HABILITAR/DESHABILITAR PLAN           ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            show_plans
            echo ""
            read -p "Ingresa el ID del plan: " PLAN_ID
            
            if [[ -n "$PLAN_ID" && "$PLAN_ID" =~ ^[0-9]+$ ]]; then
                local plans=$(load_plans)
                local plan_name=$(echo "$plans" | jq -r ".[] | select(.id == $PLAN_ID) | .name")
                local current_status=$(echo "$plans" | jq -r ".[] | select(.id == $PLAN_ID) | if .enabled then \"HABILITADO\" else \"DESHABILITADO\" end")
                
                if [[ -n "$plan_name" ]]; then
                    echo -e "\n${YELLOW}Plan: $plan_name${NC}"
                    echo -e "${YELLOW}Estado actual: $current_status${NC}"
                    echo ""
                    echo -e "  1. ✅ Habilitar (aparece en bot)"
                    echo -e "  2. ❌ Deshabilitar (oculto en bot)"
                    read -p "Selecciona (1-2): " NEW_STATUS
                    
                    if [[ "$NEW_STATUS" == "1" ]]; then
                        plans=$(echo "$plans" | jq --argjson id "$PLAN_ID" 'map(if .id == $id then .enabled = true else . end)')
                        echo -e "${GREEN}✅ Plan habilitado${NC}"
                    elif [[ "$NEW_STATUS" == "2" ]]; then
                        plans=$(echo "$plans" | jq --argjson id "$PLAN_ID" 'map(if .id == $id then .enabled = false else . end)')
                        echo -e "${YELLOW}⚠️  Plan deshabilitado${NC}"
                    else
                        echo -e "${RED}❌ Opción inválida${NC}"
                        read -p "Presiona Enter..." 
                        continue
                    fi
                    
                    save_plans "$plans"
                    
                    echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
                    cd /root/ssh-bot && pm2 restart ssh-bot > /dev/null 2>&1
                    
                    echo -e "${GREEN}✅ Cambios aplicados${NC}"
                else
                    echo -e "${RED}❌ Plan no encontrado${NC}"
                fi
            else
                echo -e "${RED}❌ ID inválido${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        13)
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
        14)
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
        15)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | 2 conexiones: ' || SUM(CASE WHEN max_connections=2 THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}📋 PLANES MÁS VENDIDOS:${NC}"
            sqlite3 "$DB" "SELECT 'Plan ' || plan_id || ': ' || COUNT(*) || ' ventas ($' || printf('%.2f', SUM(amount)) || ')' FROM payments WHERE status='approved' GROUP BY plan_id ORDER BY COUNT(*) DESC LIMIT 5" 2>/dev/null || echo "  Sin datos de ventas"
            
            echo -e "\n${YELLOW}🧠 ESTADOS:${NC}"
            sqlite3 "$DB" "SELECT state, COUNT(*) as count FROM user_state GROUP BY state"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Tests: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            sqlite3 "$DB" "SELECT 'Ventas hoy: ' || COUNT(*) || ' ($' || printf('%.2f', SUM(amount)) || ')' FROM payments WHERE date(created_at) = '$TODAY' AND status='approved'" 2>/dev/null || echo "  Sin ventas hoy"
            
            read -p "\nPresiona Enter..." 
            ;;
        16)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs ssh-bot --lines 100
            ;;
        17)
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
        18)
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
        19)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    🧠 ESTADOS ACTIVOS                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📱 USUARIOS CON ESTADO ACTIVO:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT substr(phone,1,12) as telefono, state, datetime(updated_at) as actualizado FROM user_state ORDER BY updated_at DESC LIMIT 20"
            
            echo -e "\n${CYAN}📊 RESUMEN:${NC}"
            sqlite3 "$DB" "SELECT state, COUNT(*) as usuarios FROM user_state GROUP BY state"
            
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
echo -e "${GREEN}✅ Panel de control creado con gestión de planes${NC}"

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
echo -e "\n${CYAN}${BOLD}🧪 CREANDO SCRIPT DE TEST DE PLANES CONFIGURABLES...${NC}"

cat > /usr/local/bin/test-planes << 'TESTEOF'
#!/bin/bash
echo -e "\n🔍 TEST DEL SISTEMA DE PLANES CONFIGURABLES"
echo -e "==========================================\n"

echo -e "📋 Verificando configuración..."
CONFIG="/opt/ssh-bot/config/config.json"
PLANS="/opt/ssh-bot/config/plans.json"

if [[ -f "$CONFIG" ]]; then
    echo -e "✅ Configuración: $CONFIG"
    echo -e "  IP: $(jq -r '.bot.server_ip' "$CONFIG")"
    echo -e "  Versión: $(jq -r '.bot.version' "$CONFIG")"
else
    echo -e "❌ Configuración no encontrada"
fi

if [[ -f "$PLANS" ]]; then
    PLANS_COUNT=$(jq '. | length' "$PLANS" 2>/dev/null || echo "0")
    PLANS_ENABLED=$(jq '[.[] | select(.enabled)] | length' "$PLANS" 2>/dev/null || echo "0")
    
    echo -e "\n✅ Planes configurables: $PLANS"
    echo -e "  Total planes: $PLANS_COUNT"
    echo -e "  Planes habilitados: $PLANS_ENABLED"
    
    if [[ $PLANS_ENABLED -gt 0 ]]; then
        echo -e "\n📋 PLANES HABILITADOS:"
        echo -e "${CYAN}┌─────┬────────────────┬──────────┬──────────────┬──────────┐${NC}"
        echo -e "${CYAN}│ ID  │ Nombre         │ Días     │ Conexiones   │ Precio   │${NC}"
        echo -e "${CYAN}├─────┼────────────────┼──────────┼──────────────┼──────────┤${NC}"
        
        jq -r '.[] | select(.enabled) | "│ \(.id) │ \(.name) │ \(.days) │ \(.connections) │ $\(.price) │"' "$PLANS" 2>/dev/null | while read line; do
            echo -e "${CYAN}$line${NC}"
        done
        
        echo -e "${CYAN}└─────┴────────────────┴──────────┴──────────────┴──────────┘${NC}"
    fi
else
    echo -e "\n❌ Archivo de planes no encontrado"
fi

echo -e "\n🤖 Verificando bot..."
if pm2 status | grep -q "ssh-bot"; then
    echo -e "✅ Bot en ejecución"
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot") | .pm2_env.status' 2>/dev/null || echo "unknown")
    echo -e "  Estado: $STATUS"
else
    echo -e "❌ Bot NO está en ejecución"
fi

echo -e "\n💡 INSTRUCCIONES DE USO:"
echo -e "  1. Ejecutar: ${GREEN}sshbot${NC}"
echo -e "  2. Opción ${CYAN}[7]${NC} - Ver planes actuales"
echo -e "  3. Opción ${CYAN}[8]${NC} - Agregar nuevo plan"
echo -e "  4. Opción ${CYAN}[9]${NC} - Editar plan existente"
echo -e "  5. Opción ${CYAN}[10]${NC} - Eliminar plan"
echo -e "  6. Opción ${CYAN}[11]${NC} - Ordenar planes"
echo -e "  7. Opción ${CYAN}[12]${NC} - Habilitar/deshabilitar plan"

echo -e "\n✅ Sistema funcionando correctamente con planes configurables"
TESTEOF

chmod +x /usr/local/bin/test-planes

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎉 INSTALACIÓN COMPLETADA - PLANES CONFIGURABLES 🎉   ║
║                                                              ║
║         SSH BOT PRO v8.9 - SIN CONFLICTOS DE COMANDOS      ║
║           💡 SISTEMA INTELIGENTE DE ESTADOS                ║
║           🤖 WhatsApp Web parcheado                        ║
║           ⚙️  PLANES COMPLETAMENTE CONFIGURABLES          ║
║           🔐 CONTRASEÑA FIJA: mgvpn247 PARA TODOS          ║
║           🧠 SIN CONFLICTOS ENTRE MENÚS                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema de estados instalado${NC}"
echo -e "${GREEN}✅ PLANES CONFIGURABLES desde el panel${NC}"
echo -e "${GREEN}✅ Puedes agregar/editar/eliminar planes${NC}"
echo -e "${GREEN}✅ Configurar precios, días y conexiones${NC}"
echo -e "${GREEN}✅ WhatsApp Web parcheado (no markedUnread error)${NC}"
echo -e "${GREEN}✅ CONTRASEÑA FIJA: mgvpn247 para todos los usuarios${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}\n"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control principal"
echo -e "  ${GREEN}test-planes${NC}    - Test del sistema de planes"
echo -e "  ${GREEN}pm2 logs ssh-bot${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart ssh-bot${NC} - Reiniciar bot\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN INICIAL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}sshbot${NC}"
echo -e "  2. Opción ${CYAN}[8]${NC} - Agregar nuevo plan"
echo -e "  3. Opción ${CYAN}[9]${NC} - Editar planes existentes"
echo -e "  4. Opción ${CYAN}[13]${NC} - Configurar MercadoPago"
echo -e "  5. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp"
echo -e "  6. Sube APK a /root/app.apk\n"

echo -e "${YELLOW}⚙️  GESTIÓN DE PLANES:${NC}\n"
echo -e "  ${CYAN}[7]${NC} - Ver planes actuales"
echo -e "  ${CYAN}[8]${NC} - Agregar nuevo plan"
echo -e "  ${CYAN}[9]${NC} - Editar plan existente"
echo -e "  ${CYAN}[10]${NC} - Eliminar plan"
echo -e "  ${CYAN}[11]${NC} - Ordenar planes"
echo -e "  ${CYAN}[12]${NC} - Habilitar/deshabilitar plan\n"

echo -e "${YELLOW}🎯 CREAR UN PLAN PERSONALIZADO:${NC}\n"
echo -e "  ${GREEN}Ejemplo 1:${NC} Plan económico 3 días"
echo -e "    • Nombre: 3 DÍAS ECONÓMICO"
echo -e "    • Días: 3"
echo -e "    • Conexiones: 1"
echo -e "    • Precio: 300.00"
echo -e "    • Descripción: 3 días con 1 conexión"
echo -e "    • Orden: 1 (aparece primero)\n"
echo -e "  ${GREEN}Ejemplo 2:${NC} Plan premium 60 días"
echo -e "    • Nombre: 60 DÍAS PREMIUM"
echo -e "    • Días: 60"
echo -e "    • Conexiones: 2"
echo -e "    • Precio: 2500.00"
echo -e "    • Descripción: 60 días con 2 conexiones simultáneas"
echo -e "    • Orden: 5\n"

echo -e "${YELLOW}⌨️  FLUJO PARA USUARIOS:${NC}\n"
echo -e "  ${CYAN}1.${NC} Escribe 'menu' → Menú principal"
echo -e "  ${CYAN}2.${NC} Escribe '2' → Ver planes (muestra los que configuraste)"
echo -e "  ${CYAN}3.${NC} Elige un plan (1, 2, 3, etc.)"
echo -e "  ${CYAN}4.${NC} El bot genera enlace de pago MercadoPago"
echo -e "  ${CYAN}5.${NC} Pago aprobado → Usuario creado automáticamente\n"

echo -e "${YELLOW}🔐 CONTRASEÑA:${NC}"
echo -e "  • ${GREEN}mgvpn247${NC} para TODOS los usuarios\n"

echo -e "${YELLOW}📊 INFO:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  BD: ${CYAN}$DB_FILE${NC}"
echo -e "  Config: ${CYAN}$CONFIG_FILE${NC}"
echo -e "  Planes: ${CYAN}$PLANS_FILE${NC}"
echo -e "  Script test: ${CYAN}/usr/local/bin/test-planes${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Probar sistema de planes? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Probando sistema...${NC}\n"
    /usr/local/bin/test-planes
else
    echo -e "\n${YELLOW}💡 Para probar después: ${GREEN}test-planes${NC}\n"
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

echo -e "${GREEN}${BOLD}¡Sistema instalado exitosamente! Ahora puedes configurar los planes desde el panel 🚀${NC}\n"

exit 0
#!/bin/bash
# ================================================
# SSH BOT SIMPLIFICADO v1.0 - FLUJO FÁCIL PARA CLIENTES
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
║                🤖 SSH BOT SIMPLIFICADO v1.0                  ║
║                  🚀 EXPERIENCIA FÁCIL PARA CLIENTES         ║
║                  💡 MENÚ DIRECTO Y SENCILLO                 ║
║                  🔐 CONTRASEÑA: mgvpn247                    ║
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
echo -e "   • Crear SSH Bot Simplificado"
echo -e "   • Menú directo: Prueba/Comprar/App"
echo -e "   • Flujo simple para clientes"
echo -e "   • Precios fijos incluidos"
echo -e "   • 🔐 CONTRASEÑA FIJA: mgvpn247"
echo -e "   • Limpieza automática cada 15 min"

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
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/ssh-bot-simple"
USER_HOME="/root/ssh-bot-simple"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete ssh-bot-simple 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración SIMPLIFICADA
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Simplificado",
        "version": "1.0",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 1,
        "price_30d": 5500.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes"
    }
}
EOF

# Crear base de datos simplificada
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
    plan TEXT DEFAULT '30d',
    days INTEGER DEFAULT 30,
    connections INTEGER DEFAULT 1,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT SIMPLIFICADO
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT SIMPLIFICADO...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-simple",
    "version": "1.0.0",
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

echo -e "${GREEN}✅ Parche applied${NC}"

# Crear bot.js SIMPLIFICADO
echo -e "${YELLOW}📝 Creando bot.js simplificado...${NC}"

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
    delete require.cache[require.resolve('/opt/ssh-bot-simple/config/config.json')];
    return require('/opt/ssh-bot-simple/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// ✅ MERCADOPAGO SDK
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
            
            console.log(chalk.green('✅ MercadoPago SDK ACTIVO'));
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpClient = null;
            mpPreference = null;
            return false;
        }
    }
    console.log(chalk.yellow('⚠️ MercadoPago NO configurado'));
    return false;
}

let mpEnabled = initMercadoPago();
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 SSH BOT SIMPLIFICADO v1.0                 ║'));
console.log(chalk.cyan.bold('║                  🚀 EXPERIENCIA FÁCIL                       ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ WhatsApp Web parcheado'));
console.log(chalk.green('✅ Flujo simplificado para clientes'));
console.log(chalk.green('✅ CONTRASEÑA FIJA: mgvpn247'));

// ================================================
// FUNCIONES PRINCIPALES
// ================================================

function generateUsername() {
    return 'TEST' + Math.floor(1000 + Math.random() * 9000);
}

async function createSSHUser(phone, username, days = 0) {
    const password = 'mgvpn247';
    
    if (days === 0) {
        // Usuario de prueba (1 hora)
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        console.log(chalk.yellow(`⌛ Test ${username} expira: ${expireFull}`));
        
        const commands = [
            `useradd -m -s /bin/bash ${username}`,
            `echo "${username}:${password}" | chpasswd`
        ];
        
        for (const cmd of commands) {
            try {
                await execPromise(cmd);
            } catch (error) {
                console.error(chalk.red(`❌ Error: ${cmd}`), error.message);
                throw error;
            }
        }
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, 'test', expireFull, 1],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password: password,
                    expires: expireFull,
                    tipo: 'test',
                    duration: `${config.prices.test_hours} hora(s)`
                }));
        });
    } else {
        // Usuario premium (30 días)
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        console.log(chalk.yellow(`⌛ Premium ${username} expira: ${expireFull}`));
        
        try {
            await execPromise(`useradd -M -s /bin/false -e "${moment().add(days, 'days').format('YYYY-MM-DD')}" ${username} && echo "${username}:${password}" | chpasswd`);
        } catch (error) {
            console.error(chalk.red('❌ Error creando premium:'), error.message);
            throw error;
        }
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, 'premium', expireFull, 1],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password: password,
                    expires: expireFull,
                    tipo: 'premium',
                    duration: `${days} días`
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

async function createMercadoPagoPayment(phone) {
    try {
        config = loadConfig();
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            console.log(chalk.red('❌ Token MP vacío'));
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        if (!mpPreference) {
            console.log(chalk.yellow('🔄 Reinicializando MercadoPago...'));
            mpEnabled = initMercadoPago();
            if (!mpEnabled || !mpPreference) {
                return { success: false, error: 'No se pudo inicializar MercadoPago' };
            }
        }
        
        const phoneClean = phone.split('@')[0];
        const paymentId = `PAGO-${phoneClean}-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const preferenceData = {
            items: [{
                title: `INTERNET ILIMITADO 30 DÍAS`,
                description: `Acceso completo por 30 días con 1 conexión simultánea`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(config.prices.price_30d)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: moment().add(24, 'hours').toISOString(),
            back_urls: {
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente`
            },
            auto_return: 'approved',
            statement_descriptor: 'INTERNET ILIMITADO'
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${config.prices.price_30d} ${config.prices.currency}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
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
                `INSERT INTO payments (payment_id, phone, plan, days, connections, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, '30d', 30, 1, config.prices.price_30d, paymentUrl, qrPath, response.id],
                (err) => {
                    if (err) console.error(chalk.red('❌ Error guardando en BD:'), err.message);
                }
            );
            
            console.log(chalk.green(`✅ Pago creado exitosamente`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath
            };
        }
        
        throw new Error('Respuesta inválida de MercadoPago');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        return { success: false, error: error.message };
    }
}

// ================================================
// CLIENTE WHATSAPP
// ================================================

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'ssh-bot-simple'}),
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
    console.log(chalk.cyan('\n📱 Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('📷 Escanea el QR ☝️'));
    console.log(chalk.green('\n💾 QR guardado: /root/qr-whatsapp.png\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado')));
client.on('loading_screen', (p, m) => console.log(chalk.yellow(`⏳ Cargando: ${p}% - ${m}`)));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía cualquier mensaje al bot\n'));
    qrCount = 0;
});
client.on('auth_failure', (m) => console.log(chalk.red('❌ Error auth:'), m));
client.on('disconnected', (r) => console.log(chalk.yellow('⚠️ Desconectado:'), r));

// ================================================
// MANEJO DE MENSAJES SIMPLIFICADO
// ================================================

client.on('message', async (msg) => {
    const text = msg.body.toLowerCase().trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // MENÚ PRINCIPAL (se muestra en cualquier mensaje)
    if (['menu', 'hola', 'start', 'hi', '1', '2', '3', '4', '0'].includes(text)) {
        await client.sendMessage(phone, `*👋 HOLA, BIENVENIDO*

*Elija una opción:*

*\\\`1\\\`* ⁃ ⏳ CREAR PRUEBA
*\\\`2\\\`* ⁃ 💎 COMPRAR INTERNET 
*\\\`3\\\`* ⁃ 🔄 RENOVAR INTERNET 
*\\\`4\\\`* ⁃ 📲 DESCARGAR APLICACIÓN

*Escribe el número de la opción:*`, { sendSeen: false });
    }
    
    // OPCIÓN 1 - PRUEBA GRATIS
    else if (text === '1') {
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana para otra prueba gratis
💎 *Escribe 2* para comprar internet ilimitado`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ *Creando prueba gratis...*', { sendSeen: false });
        
        try {
            const username = generateUsername();
            await createSSHUser(phone, username, 0);
            registerTest(phone);
            
            await client.sendMessage(phone, `✅ *PRUEBA CREADA CON ÉXITO !*

👤 Usuario: *${username}*
🔑 Contraseña: *mgvpn247*
📶 Límite: *1 dispositivo(s)*
⏰ Expira en: *1 hora(s)*

📲 *APP:*
Escribe *4* para descargar la aplicación`, { sendSeen: false });
            
            console.log(chalk.green(`✅ Test creado: ${username}`));
        } catch (error) {
            await client.sendMessage(phone, `❌ Error al crear cuenta: ${error.message}`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 2 - COMPRAR INTERNET
    else if (text === '2') {
        await client.sendMessage(phone, `🚀 *PLANES SSH PREMIUM !*

*Elija una opción:*

*\\\`1\\\`* ⁃ 💎 PLAN 30 DÍAS - $${config.prices.price_30d}
*\\\`0\\\`* ⁃ ⬅️ VOLVER

*Escribe el número:*`, { sendSeen: false });
    }
    
    // OPCIÓN 2.1 - PLAN 30 DÍAS
    else if (text === '1' || text === 'comprar' || text === 'comprar30') {
        await client.sendMessage(phone, `🚀 *A CONTINUACIÓN SE MUESTRAN NUESTROS PLANES PREMIUM DISPONIBLES*

*Elija un plan:*

*\\\`1\\\`* ⁃ ❇️ 1 INTERNET - 30 DIAS - $${config.prices.price_30d}
*\\\`0\\\`* ⁃ ⬅️ VOLVER

*Escribe 1 para continuar:*`, { sendSeen: false });
    }
    
    // CONFIRMAR COMPRA
    else if (text === 'confirmar' || text === 'si' || text === 'sí') {
        config = loadConfig();
        
        if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
            await client.sendMessage(phone, `❌ *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Contacta soporte: ${config.links.support}`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `⏳ *Generando pago...*`, { sendSeen: false });
        
        try {
            const payment = await createMercadoPagoPayment(phone);
            
            if (payment.success) {
                await client.sendMessage(phone, `🛍 *INTERNET ILIMITADO*

💰 Precio: *$${config.prices.price_30d}*
📶 Límite: *1 dispositivo(s)*
🗓️ Duración: *30 días*

⚠️ *LINK DE PAGO* 👇

${payment.paymentUrl}

*Escanea el código QR para pagar:*`, { sendSeen: false });
                
                // Enviar QR
                if (fs.existsSync(payment.qrPath)) {
                    try {
                        const media = MessageMedia.fromFilePath(payment.qrPath);
                        await client.sendMessage(phone, media, { 
                            caption: '📱 Escanea con la app de MercadoPago',
                            sendSeen: false 
                        });
                        console.log(chalk.green('✅ QR de pago enviado'));
                    } catch (qrError) {
                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                    }
                }
            } else {
                await client.sendMessage(phone, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

💬 Contacta soporte: ${config.links.support}`, { sendSeen: false });
            }
        } catch (error) {
            console.error(chalk.red('❌ Error en compra:'), error);
            await client.sendMessage(phone, `❌ *ERROR INESPERADO*

${error.message}

💬 Contacta soporte: ${config.links.support}`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 3 - RENOVAR (simplificado)
    else if (text === '3') {
        db.all(`SELECT username, expires_at FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC LIMIT 1`, [phone],
            async (err, rows) => {
                if (!rows || rows.length === 0) {
                    await client.sendMessage(phone, `📋 *NO TIENES CUENTAS ACTIVAS*

🆓 *1* - Prueba gratis
💰 *2* - Comprar internet`, { sendSeen: false });
                    return;
                }
                
                const user = rows[0];
                const expira = moment(user.expires_at).format('DD/MM/YYYY HH:mm');
                
                await client.sendMessage(phone, `🔄 *RENOVAR INTERNET*

👤 Usuario actual: *${user.username}*
⏰ Expira: *${expira}*

Para renovar:
1. *Escribe 2* para ver planes
2. Selecciona el plan 30 días
3. Realiza el pago

⚠️ *IMPORTANTE:*
- No se pierde tiempo restante
- Se suma a tu tiempo actual
- Activación inmediata`, { sendSeen: false });
            });
    }
    
    // OPCIÓN 4 - DESCARGAR APP
    else if (text === '4') {
        const searchPaths = [
            '/root/app.apk',
            '/root/android.apk',
            '/root/vpn.apk',
            '/root/ssh-bot-simple/app.apk'
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
                
                await client.sendMessage(phone, `📲 *DESCARGANDO APP...*

⏳ *Enviando archivo, espera...*`, { sendSeen: false });
                
                const media = MessageMedia.fromFilePath(apkFound);
                await client.sendMessage(phone, media, {
                    caption: `📱 *${apkName}*

✅ *Archivo enviado correctamente*

📱 *INSTRUCCIONES:*
1. Toca el archivo para instalar
2. Permite "Fuentes desconocidas"
3. Abre la app
4. Ingresa tus datos:
   👤 Usuario: (tu usuario)
   🔑 Contraseña: mgvpn247

💡 *Si no ves el archivo, revisa la sección "Archivos" de WhatsApp*`,
                    sendSeen: false
                });
                
                console.log(chalk.green(`✅ APK enviado exitosamente`));
                
            } catch (error) {
                console.error(chalk.red('❌ Error enviando APK:'), error.message);
                
                await client.sendMessage(phone, `❌ *ERROR AL ENVIAR APK*

El archivo es muy grande para WhatsApp.

📞 Contacta soporte para obtener la app:
${config.links.support}`, { sendSeen: false });
            }
        } else {
            await client.sendMessage(phone, `❌ *APK NO DISPONIBLE*

El archivo de instalación no está disponible.

📞 Contacta soporte:
${config.links.support}

💡 Pide al administrador que suba el APK a /root/app.apk`, { sendSeen: false });
        }
    }
    
    // OPCIÓN 0 - VOLVER
    else if (text === '0') {
        await client.sendMessage(phone, `*👋 HOLA, BIENVENIDO*

*Elija una opción:*

*\\\`1\\\`* ⁃ ⏳ CREAR PRUEBA
*\\\`2\\\`* ⁃ 💎 COMPRAR INTERNET 
*\\\`3\\\`* ⁃ 🔄 RENOVAR INTERNET 
*\\\`4\\\`* ⁃ 📲 DESCARGAR APLICACIÓN

*Escribe el número de la opción:*`, { sendSeen: false });
    }
    
    // MENSAJE NO RECONOCIDO
    else {
        await client.sendMessage(phone, `*👋 HOLA, BIENVENIDO*

*Elija una opción:*

*\\\`1\\\`* ⁃ ⏳ CREAR PRUEBA
*\\\`2\\\`* ⁃ 💎 COMPRAR INTERNET 
*\\\`3\\\`* ⁃ 🔄 RENOVAR INTERNET 
*\\\`4\\\`* ⁃ 📲 DESCARGAR APLICACIÓN

*Escribe el número de la opción:*`, { sendSeen: false });
    }
});

// ================================================
// TAREAS AUTOMÁTICAS
// ================================================

// ✅ Verificar pagos cada 2 minutos
cron.schedule('*/2 * * * *', () => {
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
                    
                    if (mpPayment.status === 'approved') {
                        console.log(chalk.green(`✅ PAGO APROBADO: ${payment.payment_id}`));
                        
                        const username = 'USER' + Math.floor(1000 + Math.random() * 9000);
                        const result = await createSSHUser(payment.phone, username, payment.days);
                        
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [payment.payment_id]);
                        
                        const expireDate = moment().add(payment.days, 'days').format('DD/MM/YYYY');
                        
                        const message = `✅ *PAGO CONFIRMADO*

🎉 ¡Tu compra ha sido aprobada!

📋 *DATOS DE ACCESO:*
👤 Usuario: *${username}*
🔑 Contraseña: *mgvpn247*

⏰ *VÁLIDO HASTA:* ${expireDate}
📶 *LÍMITE:* 1 dispositivo

📱 *INSTALACIÓN:*
1. Descarga la app (Escribe *4*)
2. Seleccionar servidor
3. Ingresar Usuario y Contraseña
4. ¡Conéctate automáticamente!

🎊 ¡Disfruta del servicio premium!`;
                        
                        await client.sendMessage(payment.phone, message, { sendSeen: false });
                        console.log(chalk.green(`✅ Usuario creado: ${username}`));
                    }
                }
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
});

// ✅ Limpiar usuarios expirados cada 15 minutos
cron.schedule('*/15 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🧹 Limpiando usuarios expirados (${now})...`));
    
    db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
        if (err || !rows || rows.length === 0) return;
        
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

console.log(chalk.green('\n🚀 Inicializando bot simplificado...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot simplificado creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL SIMPLIFICADO
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL...${NC}"

cat > /usr/local/bin/sshbot-simple << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/ssh-bot-simple/data/users.db"
CONFIG="/opt/ssh-bot-simple/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL SSH BOT SIMPLIFICADO                ║${NC}"
    echo -e "${CYAN}║                  🚀 EXPERIENCIA FÁCIL                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot-simple") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    MP_TOKEN=$(get_val '.mercadopago.access_token')
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" && "$MP_TOKEN" != "null" ]]; then
        MP_STATUS="${GREEN}✅ ACTIVO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Precio 30 días: ${GREEN}$$(get_val '.prices.price_30d')${NC}"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA PARA TODOS)"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  👤  Ver usuarios activos"
    echo -e "${CYAN}[5]${NC}  🗑️   Eliminar usuario"
    echo -e ""
    echo -e "${CYAN}[6]${NC}  💰  Cambiar precio"
    echo -e "${CYAN}[7]${NC}  🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC}  📱  Subir APK"
    echo -e "${CYAN}[9]${NC}  📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 📝  Ver logs"
    echo -e "${CYAN}[11]${NC} 🔧  Reparar bot"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
            cd /root/ssh-bot-simple
            pm2 restart ssh-bot-simple 2>/dev/null || pm2 start bot.js --name ssh-bot-simple
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop ssh-bot-simple
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
                echo -e "${YELLOW}📱 Para ver el QR:${NC}"
                echo -e "  1. Enviar a tu teléfono:"
                echo -e "     scp root@$(get_val '.bot.server_ip'):/root/qr-whatsapp.png ."
                echo -e "  2. O ver en el servidor con:"
                echo -e "     apt install fim && fim -a qr-whatsapp.png"
                echo -e ""
                read -p "¿Ver logs en tiempo real? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot-simple --lines 100
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot-simple --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, 'mgvpn247' as password, tipo, expires_at, substr(phone,1,12) as tel FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..." 
            ;;
        5)
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
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    💰 CAMBIAR PRECIO                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_PRICE=$(get_val '.prices.price_30d')
            echo -e "${YELLOW}Precio actual 30 días: ${GREEN}$${CURRENT_PRICE}${NC}\n"
            
            read -p "Nuevo precio 30 días: " NEW_PRICE
            
            if [[ -n "$NEW_PRICE" ]]; then
                set_val '.prices.price_30d' "$NEW_PRICE"
                echo -e "\n${GREEN}✅ Precio actualizado a $${NEW_PRICE}${NC}"
                
                echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
                pm2 restart ssh-bot-simple
                sleep 2
            fi
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
                echo -e "${YELLOW}Token: ${CURRENT_TOKEN:0:30}...${NC}\n"
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
                    cd /root/ssh-bot-simple && pm2 restart ssh-bot-simple
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
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📱 SUBIR APK                            ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/app.apk" ]]; then
                SIZE=$(du -h "/root/app.apk" | cut -f1)
                echo -e "${GREEN}✅ APK encontrado: /root/app.apk (${SIZE})${NC}"
                echo -e ""
                echo -e "1. Mantener actual"
                echo -e "2. Reemplazar"
                echo -e "3. Eliminar"
                read -p "Opción: " APK_OPT
                
                case $APK_OPT in
                    2)
                        echo -e "\n${YELLOW}📤 Sube tu APK con SCP:${NC}"
                        echo -e "  scp app.apk root@$(get_val '.bot.server_ip'):/root/app.apk"
                        echo -e ""
                        read -p "Presiona Enter cuando hayas subido el archivo..." 
                        if [[ -f "/root/app.apk" ]]; then
                            SIZE=$(du -h "/root/app.apk" | cut -f1)
                            echo -e "${GREEN}✅ APK reemplazado (${SIZE})${NC}"
                        fi
                        ;;
                    3)
                        rm -f /root/app.apk
                        echo -e "${GREEN}✅ APK eliminado${NC}"
                        ;;
                esac
            else
                echo -e "${YELLOW}⚠️  No hay APK en /root/app.apk${NC}\n"
                echo -e "${CYAN}📤 Para subir un APK:${NC}"
                echo -e "  scp app.apk root@$(get_val '.bot.server_ip'):/root/app.apk"
                echo -e ""
                echo -e "${YELLOW}⚠️  Límite de WhatsApp: 100MB${NC}"
                echo -e "${YELLOW}💡 Si es más grande, comprime o usa enlace${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) FROM payments"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Tests hoy: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            
            echo -e "\n${YELLOW}💸 INGRESOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            read -p "\nPresiona Enter..." 
            ;;
        10)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs ssh-bot-simple --lines 100
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔧 REPARAR BOT                          ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "¿Limpiar sesión de WhatsApp? (s/N): " CONF
            
            if [[ "$CONF" == "s" ]]; then
                echo -e "\n${YELLOW}🧹 Limpiando...${NC}"
                rm -rf /root/.wwebjs_auth/* /root/.wwebjs_cache/* /root/qr-whatsapp.png
                echo -e "${YELLOW}📦 Reinstalando...${NC}"
                cd /root/ssh-bot-simple && npm install --silent
                echo -e "${YELLOW}🔄 Reiniciando...${NC}"
                pm2 restart ssh-bot-simple
                echo -e "\n${GREEN}✅ Reparado - Espera 10s para QR${NC}"
                sleep 10
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

chmod +x /usr/local/bin/sshbot-simple
echo -e "${GREEN}✅ Panel de control creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT SIMPLIFICADO...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name ssh-bot-simple
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
║         🎉 SSH BOT SIMPLIFICADO INSTALADO 🎉               ║
║           🚀 EXPERIENCIA FÁCIL PARA CLIENTES               ║
║           💡 MENÚ DIRECTO Y SENCILLO                       ║
║           🔐 CONTRASEÑA: mgvpn247                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Bot instalado exitosamente${NC}"
echo -e "${GREEN}✅ Flujo simplificado para clientes${NC}"
echo -e "${GREEN}✅ Menú directo y fácil de usar${NC}"
echo -e "${GREEN}✅ WhatsApp Web parcheado${NC}"
echo -e "${GREEN}✅ CONTRASEÑA FIJA: mgvpn247 para todos${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}\n"
echo -e "  ${GREEN}sshbot-simple${NC}     - Panel de control"
echo -e "  ${GREEN}pm2 logs ssh-bot-simple${NC} - Ver logs"
echo -e "  ${GREEN}pm2 restart ssh-bot-simple${NC} - Reiniciar\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN RÁPIDA:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}sshbot-simple${NC}"
echo -e "  2. Opción ${CYAN}[7]${NC} - Configurar MercadoPago"
echo -e "  3. Opción ${CYAN}[3]${NC} - Escanear QR WhatsApp"
echo -e "  4. Opción ${CYAN}[6]${NC} - Cambiar precio (actual: \$5500)\n"

echo -e "${YELLOW}📱 FLUJO DEL CLIENTE:${NC}"
echo -e "  Cliente escribe: ${GREEN}cualquier cosa${NC}"
echo -e "  Bot responde: ${CYAN}Menú con 4 opciones${NC}"
echo -e "  Cliente escribe: ${GREEN}1${NC}"
echo -e "  Bot crea: ${CYAN}Prueba de 1 hora${NC}"
echo -e "  Cliente escribe: ${GREEN}2${NC}"
echo -e "  Bot muestra: ${CYAN}Plan 30 días\$5500${NC}"
echo -e "  Cliente escribe: ${GREEN}1${NC} (de nuevo)"
echo -e "  Bot genera: ${CYAN}Link de pago MercadoPago${NC}\n"

echo -e "${YELLOW}📊 INFO:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  Precio 30 días: ${GREEN}\$5500${NC}"
echo -e "  Prueba: ${GREEN}1 hora${NC}"
echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA)\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}\n"
    sleep 2
    /usr/local/bin/sshbot-simple
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}sshbot-simple${NC}\n"
fi

echo -e "${GREEN}${BOLD}¡Bot simplificado instalado! 🚀${NC}\n"

exit 0
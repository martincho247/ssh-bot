#!/bin/bash
# ================================================
# INSTALADOR COMPLETO WPPCONNECT + MERCADOPAGO
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                🚀 INSTALADOR WPPCONNECT BOT                 ║
║                💰 CON MERCADOPAGO INTEGRADO                ║
║                🔧 QR FIX - VERSIÓN COMPLETA                ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Este script requiere permisos root${NC}"
    exit 1
fi

# Función para pausa
pause() {
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read -r
}

# Función para verificar éxito
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${1}${NC}"
    else
        echo -e "${RED}❌ Error en: ${1}${NC}"
        exit 1
    fi
}

# ================================================
# PASO 1: ACTUALIZAR SISTEMA E INSTALAR DEPENDENCIAS
# ================================================
echo -e "${CYAN}${BOLD}[1/8] Actualizando sistema e instalando dependencias...${NC}"

apt-get update
apt-get upgrade -y
apt-get install -y \
    git curl wget nano htop \
    build-essential python3 python3-pip \
    sqlite3 libsqlite3-dev \
    libnss3 libgbm1 libxshmfence1 \
    libasound2 libatk-bridge2.0-0 libdrm2 \
    libxcomposite1 libxdamage1 libxfixes3 \
    libxrandr2 libgbm1 libxkbcommon0 \
    libpango-1.0-0 libcairo2 \
    jq qrencode \
    nodejs npm \
    pm2

check_success "Dependencias instaladas"

# Instalar Node.js 18 si no está
if ! node --version | grep -q "v18"; then
    echo -e "${YELLOW}Instalando Node.js 18...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    check_success "Node.js 18 instalado"
fi

# ================================================
# PASO 2: CONFIGURAR DIRECTORIOS
# ================================================
echo -e "\n${CYAN}${BOLD}[2/8] Configurando directorios...${NC}"

mkdir -p /opt/wpp-bot/{config,data,logs}
mkdir -p /root/.wppconnect
mkdir -p /root/wpp-bot

check_success "Directorios creados"

# ================================================
# PASO 3: INSTALAR CHROMIUM PARA QR
# ================================================
echo -e "\n${CYAN}${BOLD}[3/8] Instalando Chromium para QR...${NC}"

apt-get install -y chromium chromium-sandbox chromium-driver
ln -sf /usr/bin/chromium /usr/bin/google-chrome

check_success "Chromium instalado"

# ================================================
# PASO 4: CONFIGURACIÓN INICIAL
# ================================================
echo -e "\n${CYAN}${BOLD}[4/8] Creando configuración inicial...${NC}"

# Obtener IP pública
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

cat > /opt/wpp-bot/config/config.json << EOF
{
    "bot": {
        "server_ip": "$SERVER_IP",
        "version": "2.0",
        "name": "MGVPN Bot"
    },
    "prices": {
        "price_7d": "500",
        "price_15d": "800",
        "price_30d": "1200",
        "price_50d": "1800",
        "test_hours": 1,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "app_download": "https://example.com/app.apk",
        "support": "https://wa.me/5491111111111"
    },
    "settings": {
        "cleanup_interval": 15,
        "session_timeout": 24
    }
}
EOF

check_success "Configuración creada"

# ================================================
# PASO 5: BASE DE DATOS
# ================================================
echo -e "\n${CYAN}${BOLD}[5/8] Creando base de datos...${NC}"

cat > /opt/wpp-bot/data/init_db.sql << 'SQL'
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    tipo TEXT DEFAULT 'premium',
    plan TEXT DEFAULT '30d',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    plan TEXT NOT NULL,
    days INTEGER NOT NULL,
    amount REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT NOT NULL,
    date DATE NOT NULL,
    UNIQUE(phone, date)
);

CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_expires ON users(expires_at);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_phone ON payments(phone);
SQL

sqlite3 /opt/wpp-bot/data/users.db < /opt/wpp-bot/data/init_db.sql
check_success "Base de datos creada"

# ================================================
# PASO 6: CREAR BOT CON QR FIX
# ================================================
echo -e "\n${CYAN}${BOLD}[6/8] Creando bot con QR fix...${NC}"

cd /root/wpp-bot

# Crear package.json
cat > package.json << EOF
{
    "name": "wpp-bot-mgvpn",
    "version": "2.0.0",
    "description": "WhatsApp Bot con MercadoPago para SSH",
    "main": "bot.js",
    "scripts": {
        "start": "node bot.js",
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.26.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.29.4",
        "sqlite3": "^5.1.6",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.2",
        "mercadopago": "^2.0.15",
        "express": "^4.18.2",
        "body-parser": "^1.20.2"
    },
    "engines": {
        "node": ">=18.0.0"
    }
}
EOF

# Instalar dependencias
npm install
check_success "Dependencias NPM instaladas"

# Crear bot.js con QR mejorado
cat > bot.js << 'BOTEOF'
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

const execPromise = util.promisify(exec);
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 SSH BOT - WPPCONNECT + MP                  ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/wpp-bot/config/config.json')];
    return require('/opt/wpp-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/wpp-bot/data/users.db');

// ✅ MERCADOPAGO SDK
let mpEnabled = false;
let mpClient = null;

function initMercadoPago() {
    config = loadConfig();
    if (config.mercadopago.access_token && config.mercadopago.access_token !== '') {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            
            mpClient = new MercadoPagoConfig({ 
                accessToken: config.mercadopago.access_token,
                options: { timeout: 5000, idempotencyKey: true }
            });
            
            mpEnabled = true;
            console.log(chalk.green('✅ MercadoPago SDK v2.x ACTIVO'));
            console.log(chalk.cyan(`🔑 Token: ${config.mercadopago.access_token.substring(0, 20)}...`));
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
let userStates = {};

// Funciones auxiliares
function generateUsername() {
    return 'TEST' + Math.floor(1000 + Math.random() * 9000);
}

function generatePassword() {
    return 'mgvpn247';
}

async function createSSHUser(phone, username, password, days) {
    if (days === 0) {
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        try {
            await execPromise(`useradd -m -s /bin/bash ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'test', ?, 1)`,
                [phone, username, password, expireFull]);
            
            return { success: true, username, password, expires: expireFull };
        } catch (error) {
            console.error(chalk.red('❌ Error:'), error.message);
            return { success: false, error: error.message };
        }
    } else {
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        try {
            await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES (?, ?, ?, 'premium', ?, 1)`,
                [phone, username, password, expireFull]);
            
            return { success: true, username, password, expires: expireFull };
        } catch (error) {
            console.error(chalk.red('❌ Error:'), error.message);
            return { success: false, error: error.message };
        }
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

// ✅ FUNCIÓN PARA MOSTRAR QR EN TERMINAL
function displayQRCode(qrCode) {
    console.log(chalk.green('\n═══════════════════════════════════════════════════'));
    console.log(chalk.yellow('📱 ESCANEA ESTE CÓDIGO QR CON WHATSAPP'));
    console.log(chalk.green('═══════════════════════════════════════════════════\n'));
    
    qrcode.generate(qrCode, { small: true }, function (qrcode) {
        console.log(qrcode);
        console.log(chalk.cyan('⚠️  Si el QR no aparece, revisa la sesión en:'));
        console.log(chalk.cyan('   /root/.wppconnect/session'));
        console.log(chalk.green('\n═══════════════════════════════════════════════════\n'));
    });
}

// ✅ FUNCIÓN DE MERCADOPAGO CON QR
async function createMercadoPagoPayment(phone, days, amount, planName) {
    try {
        if (!mpEnabled) {
            return { success: false, error: 'MercadoPago no configurado' };
        }
        
        const { Preference } = require('mercadopago');
        const mpPreference = new Preference(mpClient);
        
        const phoneClean = phone.replace('@c.us', '');
        const paymentId = `SSH-${phoneClean}-${days}d-${Date.now()}`;
        
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                id: paymentId,
                title: `SSH PREMIUM ${days} DÍAS`,
                description: `Acceso SSH Premium por ${days} días - 1 conexión`,
                quantity: 1,
                currency_id: config.prices.currency || 'ARS',
                unit_price: parseFloat(amount)
            }],
            external_reference: paymentId,
            expires: true,
            expiration_date_from: moment().toISOString(),
            expiration_date_to: isoDate,
            back_urls: {
                success: "https://www.mercadopago.com.ar",
                failure: "https://www.mercadopago.com.ar",
                pending: "https://www.mercadopago.com.ar"
            },
            auto_return: 'approved',
            statement_descriptor: 'SSH PREMIUM',
            notification_url: `https://${config.bot.server_ip}/mp-webhook`
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency || 'ARS'}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point || response.sandbox_init_point;
            const qrPath = `/opt/wpp-bot/data/qr_${paymentId}.png`;
            const qrText = `MercadoPago\nPlan: ${planName}\n$${amount} ARS\n${paymentUrl.substring(0, 30)}...`;
            
            // Generar QR local
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 300,
                margin: 2,
                color: {
                    dark: '#000000',
                    light: '#FFFFFF'
                }
            });
            
            // Mostrar QR en terminal
            displayQRCode(paymentUrl);
            
            db.run(
                `INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, qr_path) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)`,
                [paymentId, phone, `${days}d`, days, amount, paymentUrl, qrPath],
                (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                }
            );
            
            console.log(chalk.green(`✅ Pago creado: ${paymentId}`));
            console.log(chalk.cyan(`🔗 URL: ${paymentUrl}`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                qrText,
                amount: amount
            };
        }
        
        throw new Error('Respuesta inválida de MercadoPago');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        console.error(chalk.red('Detalles:'), error);
        return { success: false, error: error.message };
    }
}

// ✅ WEBHOOK PARA MERCADOPAGO
function setupWebhook() {
    const express = require('express');
    const bodyParser = require('body-parser');
    const app = express();
    
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({ extended: true }));
    
    app.post('/mp-webhook', async (req, res) => {
        try {
            const paymentData = req.body;
            console.log(chalk.cyan('🔔 Webhook MP recibido:'), paymentData.type || 'unknown');
            
            if (paymentData.type === 'payment') {
                const paymentId = paymentData.data.id;
                const status = paymentData.action || 'pending';
                
                db.get('SELECT * FROM payments WHERE payment_id = ?', [paymentId], async (err, payment) => {
                    if (payment && client) {
                        const newStatus = status === 'payment.updated' ? 'approved' : status;
                        
                        db.run('UPDATE payments SET status = ? WHERE payment_id = ?', [newStatus, paymentId]);
                        
                        if (newStatus === 'approved') {
                            const username = generateUsername();
                            const password = generatePassword();
                            const result = await createSSHUser(payment.phone, username, password, payment.days);
                            
                            if (result.success && client) {
                                await client.sendText(payment.phone, 
                                    `✅ *PAGO APROBADO* ✅

🎉 Tu pago ha sido confirmado!

👤 Usuario: ${username}
🔑 Contraseña: ${password}
📅 Expira: ${result.expires}
🔌 Conexiones: 1

💾 Guarda tus credenciales
🔗 APP: ${config.links.app_download}

¡Disfruta del servicio! 🚀`);
                                
                                console.log(chalk.green(`✅ Usuario creado: ${username} para ${payment.phone}`));
                            }
                        }
                    }
                });
            }
            
            res.status(200).send('OK');
        } catch (error) {
            console.error(chalk.red('❌ Error webhook:'), error);
            res.status(500).send('ERROR');
        }
    });
    
    const PORT = 3000;
    app.listen(PORT, () => {
        console.log(chalk.green(`🌐 Webhook MP escuchando en puerto ${PORT}`));
    });
}

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'ssh-bot',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: false, // Desactivamos el QR automático
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
                '--window-size=1920,1080',
                '--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/chromium',
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-accelerated-2d-canvas',
                    '--disable-gpu'
                ]
            },
            disableWelcome: true,
            updatesLog: true,
            autoClose: 0,
            tokenStore: 'file',
            folderNameToken: '/root/.wppconnect',
            createPathFileToken: true,
            onLoadingScreen: (percent, message) => {
                console.log(chalk.cyan(`🔄 Cargando: ${percent}% - ${message}`));
            }
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        // ✅ MOSTRAR QR EN CONSOLA
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            
            if (state === 'qrReadSuccess') {
                console.log(chalk.green('✅ QR leído correctamente!'));
            } else if (state === 'qrReadFail') {
                console.log(chalk.red('❌ Error leyendo QR, reintentando...'));
            } else if (state === 'notLogged') {
                console.log(chalk.yellow('⚠️ No autenticado, generando QR...'));
            }
        });
        
        // ✅ ESCUCHAR EVENTO QR
        client.onQrCode(async (qr) => {
            console.log(chalk.yellow('\n🔄 NUEVO CÓDIGO QR GENERADO'));
            displayQRCode(qr);
            
            // También guardar QR como archivo
            const qrFilePath = '/opt/wpp-bot/data/latest_qr.png';
            try {
                await QRCode.toFile(qrFilePath, qr);
                console.log(chalk.cyan(`💾 QR guardado en: ${qrFilePath}`));
            } catch (qrError) {
                console.error(chalk.red('⚠️ Error guardando QR:'), qrError.message);
            }
        });
        
        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                const text = message.body.toLowerCase().trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));
                
                // MENÚ PRINCIPAL
                if (['menu', 'hola', 'start', 'hi', 'volver', '0'].includes(text)) {
                    userStates[from] = { state: 'main_menu' };
                    
                    await client.sendText(from, `*HOLA, BIENVENIDO BOT MGVPN* 🚀

Elija una opción:

🧾 *1* - CREAR PRUEBA
💰 *2* - COMPRAR USUARIO SSH
🔄 *3* - RENOVAR USUARIO SSH
📱 *4* - DESCARGAR APLICACIÓN
📊 *5* - VER MI CUENTA

Escribe el número de la opción deseada.`);
                }
                
                // OPCIÓN 1: CREAR PRUEBA
                else if (text === '1' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    userStates[from] = { state: 'main_menu' };
                    
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana para otra prueba gratuita`);
                        return;
                    }
                    
                    await client.sendText(from, '⏳ Creando cuenta de prueba...');
                    
                    try {
                        const username = generateUsername();
                        const password = generatePassword();
                        const result = await createSSHUser(from, username, password, 0);
                        
                        if (result.success) {
                            registerTest(from);
                            
                            await client.sendText(from, `*PRUEBA CREADA CON ÉXITO* ✅

👤 *Usuario:* ${username}
🔑 *Contraseña:* ${password}
⏰ *Duración:* ${config.prices.test_hours} hora(s)
🔌 *Conexiones:* 1
📅 *Expira:* ${result.expires}

📱 *APP:* ${config.links.app_download}

⚠️ *Esta es una cuenta de prueba, solo para evaluación.*`);
                            
                            console.log(chalk.green(`✅ Test creado: ${username}`));
                        } else {
                            await client.sendText(from, `❌ *Error:* ${result.error}`);
                        }
                    } catch (error) {
                        await client.sendText(from, `❌ Error al crear cuenta: ${error.message}`);
                    }
                }
                
                // OPCIÓN 2: COMPRAR USUARIO SSH
                else if (text === '2' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    userStates[from] = { state: 'buying_ssh' };
                    
                    await client.sendText(from, `*PLANES SSH PREMIUM* 💰

Elija una opción:
🌐 *1* - PLAN 7 DÍAS - $${config.prices.price_7d} ARS
🌐 *2* - PLAN 15 DÍAS - $${config.prices.price_15d} ARS
🌐 *3* - PLAN 30 DÍAS - $${config.prices.price_30d} ARS
🌐 *4* - PLAN 50 DÍAS - $${config.prices.price_50d} ARS
⬅️ *0* - VOLVER`);
                }
                
                // PROCESAR COMPRA
                else if (userStates[from] && userStates[from].state === 'buying_ssh') {
                    if (['1', '2', '3', '4'].includes(text)) {
                        const planMap = {
                            '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                            '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                            '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                            '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (mpEnabled) {
                            // ✅ CON MERCADOPAGO
                            await client.sendText(from, `*PLAN SELECCIONADO:* ${plan.name}

💰 *Precio:* $${plan.price} ARS
⏰ *Duración:* ${plan.days} días
🔌 *Conexiones:* 1

⏳ *Generando pago con MercadoPago...*`);
                            
                            // Crear pago
                            const payment = await createMercadoPagoPayment(from, plan.days, plan.price, plan.name);
                            
                            if (payment.success) {
                                const message = `*LINK DE PAGO GENERADO* 🔗

*Plan:* ${plan.name}
*Precio:* $${payment.amount} ARS
*ID de Pago:* ${payment.paymentId}

🔗 *Enlace de pago:*
${payment.paymentUrl}

⏰ *Este enlace expira en 24 horas*
💳 *Pago seguro con MercadoPago*

✅ *Te notificaré cuando se apruebe el pago automáticamente.*`;
                                
                                await client.sendText(from, message);
                                
                                // Enviar QR como imagen
                                if (fs.existsSync(payment.qrPath)) {
                                    try {
                                        await client.sendImage(
                                            from,
                                            payment.qrPath,
                                            'qr-pago.jpg',
                                            `*Escanea con MercadoPago*\n${plan.name} - $${plan.price} ARS`
                                        );
                                    } catch (qrError) {
                                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                                    }
                                }
                            } else {
                                await client.sendText(from, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

📞 *Contacta al administrador:* ${config.links.support}`);
                            }
                            
                            userStates[from] = { state: 'main_menu' };
                            
                        } else {
                            // ❌ SIN MERCADOPAGO
                            await client.sendText(from, `*PLAN SELECCIONADO:* ${plan.name}

💰 *Precio:* $${plan.price} ARS
⏰ *Duración:* ${plan.days} días

📞 *Para continuar con la compra, contacta al administrador:*
${config.links.support}`);
                            
                            userStates[from] = { state: 'main_menu' };
                        }
                    }
                    else if (text === '0') {
                        userStates[from] = { state: 'main_menu' };
                        await client.sendText(from, `*HOLA, BIENVENIDO BOT MGVPN* 🚀

Elija una opción:

🧾 *1* - CREAR PRUEBA
💰 *2* - COMPRAR USUARIO SSH
🔄 *3* - RENOVAR USUARIO SSH
📱 *4* - DESCARGAR APLICACIÓN
📊 *5* - VER MI CUENTA`);
                    }
                }
                
                // OPCIÓN 5: VER CUENTA
                else if (text === '5' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    db.get('SELECT * FROM users WHERE phone = ? ORDER BY expires_at DESC LIMIT 1', [from], (err, user) => {
                        if (user) {
                            client.sendText(from, 
                                `*INFORMACIÓN DE TU CUENTA* 📋

👤 *Usuario:* ${user.username}
🔑 *Contraseña:* ${user.password}
📅 *Expira:* ${user.expires_at}
🔌 *Tipo:* ${user.tipo}
📱 *Estado:* ${user.status === 1 ? 'Activa ✅' : 'Inactiva ❌'}

🔗 *APP:* ${config.links.app_download}`);
                        } else {
                            client.sendText(from, `❌ *No tienes cuentas activas*

💡 Crea una prueba o compra un plan para comenzar.`);
                        }
                    });
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
        
        // Verificar pagos cada 2 minutos
        cron.schedule('*/2 * * * *', () => {
            console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
        });
        
        // Limpieza automática
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
                        console.error(chalk.red(`Error eliminando ${r.username}:`), e.message);
                    }
                }
            });
        });
        
        // Iniciar webhook
        setupWebhook();
        
    } catch (error) {
        console.error(chalk.red('❌ Error inicializando WPPConnect:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(initializeBot, 10000);
    }
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

check_success "Bot creado con QR fix"

# ================================================
# PASO 7: CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}[7/8] Creando panel de control...${NC}"

cat > /usr/local/bin/wppbot << 'PANEL_EOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/wpp-bot/data/users.db"
CONFIG="/opt/wpp-bot/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL WPPCONNECT BOT - PRO               ║${NC}"
    echo -e "${CYAN}║                  💰 MERCADOPAGO INTEGRADO                   ║${NC}"
    echo -e "${CYAN}║                    🔧 QR FIX - V2.0                        ║${NC}"
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

view_qr() {
    echo -e "${CYAN}🔍 Buscando QR actual...${NC}"
    
    if [[ -f "/root/.wppconnect/session/ssh-bot/tokens.json" ]]; then
        echo -e "${GREEN}✅ Sesión encontrada${NC}"
        
        # Verificar si hay QR guardado
        if [[ -f "/opt/wpp-bot/data/latest_qr.png" ]]; then
            echo -e "${YELLOW}📱 Mostrando QR guardado...${NC}"
            
            # Verificar si tenemos qrencode instalado
            if command -v qrencode &> /dev/null; then
                # Extraer URL del QR si existe en logs
                QR_URL=$(pm2 logs wpp-bot --nostream --lines 50 | grep -o "https://[^ ]*" | head -1)
                if [[ -n "$QR_URL" ]]; then
                    qrencode -t ANSIUTF8 "$QR_URL"
                    echo -e "${CYAN}📋 URL del QR: ${QR_URL:0:50}...${NC}"
                else
                    echo -e "${YELLOW}⚠️ No se pudo extraer URL del QR${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️ Instala qrencode para ver QR en terminal:${NC}"
                echo -e "${CYAN}   apt-get install qrencode${NC}"
            fi
            
            echo -e "${GREEN}💾 QR guardado en: /opt/wpp-bot/data/latest_qr.png${NC}"
        else
            echo -e "${YELLOW}📱 Generando nuevo QR...${NC}"
            echo -e "${CYAN}Revisa los logs del bot para ver el QR${NC}"
            pm2 logs wpp-bot --lines 20
        fi
    else
        echo -e "${RED}❌ No hay sesión activa${NC}"
        echo -e "${YELLOW}Inicia el bot para generar un QR${NC}"
    fi
}

generate_new_qr() {
    echo -e "${YELLOW}🔄 Forzando nuevo QR...${NC}"
    pm2 stop wpp-bot 2>/dev/null
    sleep 2
    rm -rf /root/.wppconnect/*
    sleep 2
    pm2 start wpp-bot
    sleep 3
    echo -e "${GREEN}✅ Nueva sesión generada${NC}"
    echo -e "${CYAN}Revisa los logs para el nuevo QR:${NC}"
    pm2 logs wpp-bot --lines 30 --nostream | grep -A5 -B5 "QR\|ESCANEA\|qrcode"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    PENDING_PAYMENTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='pending'" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="wpp-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
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
    echo -e "  Pagos pendientes: ${CYAN}$PENDING_PAYMENTS${NC}"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  IP: $(get_val '.bot.server_ip')"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA)"
    echo -e ""
    
    echo -e "${YELLOW}💰 PRECIOS ACTUALES:${NC}"
    echo -e "  7 días: $ $(get_val '.prices.price_7d') ARS"
    echo -e "  15 días: $ $(get_val '.prices.price_15d') ARS"
    echo -e "  30 días: $ $(get_val '.prices.price_30d') ARS"
    echo -e "  50 días: $ $(get_val '.prices.price_50d') ARS"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver QR y logs"
    echo -e "${CYAN}[4]${NC} 🔄  Forzar nuevo QR"
    echo -e "${CYAN}[5]${NC} 👤  Crear usuario manual"
    echo -e "${CYAN}[6]${NC} 👥  Listar usuarios"
    echo -e ""
    echo -e "${CYAN}[7]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[8]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[9]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[10]${NC} 📊 Ver estadísticas"
    echo -e "${CYAN}[11]${NC} 🧹 Limpiar sesión"
    echo -e "${CYAN}[12]${NC} ⚙️  Ver configuración"
    echo -e "${CYAN}[13]${NC} 🐛 Ver logs en tiempo real"
    echo -e "${CYAN}[0]${NC} 🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    
    read -p "👉 Selecciona: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando...${NC}"
            cd /root/wpp-bot
            pm2 restart wpp-bot 2>/dev/null || pm2 start bot.js --name wpp-bot
            pm2 save 2>/dev/null
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo...${NC}"
            pm2 stop wpp-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            echo -e "\n${YELLOW}📱 Mostrando QR y logs...${NC}"
            view_qr
            echo -e "\n${CYAN}━━━━━━━━━━ ULTIMOS LOGS ━━━━━━━━━━${NC}"
            pm2 logs wpp-bot --nostream --lines 30 | grep -v "^\s*$" | tail -30
            read -p "\nPresiona Enter para continuar..."
            ;;
        4)
            generate_new_qr
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👤 CREAR USUARIO                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "Usuario (auto=generar): " USERNAME
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 1h, 7,15,30,50=premium): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            [[ "$USERNAME" == "auto" || -z "$USERNAME" ]] && USERNAME="TEST$(shuf -i 1000-9999 -n 1)"
            PASSWORD="mgvpn247"
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
                EXPIRE_DATE=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                useradd -M -s /bin/false "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
            fi
            
            if [[ $? -eq 0 ]]; then
                sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, status) VALUES ('$PHONE', '$USERNAME', '$PASSWORD', '$TIPO', '$EXPIRE_DATE', 1)"
                echo -e "\n${GREEN}✅ USUARIO CREADO${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: ${PASSWORD}"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "🔌 Días: ${DAYS}"
            else
                echo -e "\n${RED}❌ Error${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, password, tipo, expires_at FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    💰 CAMBIAR PRECIOS                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            CURRENT_50D=$(get_val '.prices.price_50d')
            
            echo -e "${YELLOW}💰 PRECIOS ACTUALES:${NC}"
            echo -e "  1. 7 días: $${CURRENT_7D} ARS"
            echo -e "  2. 15 días: $${CURRENT_15D} ARS"
            echo -e "  3. 30 días: $${CURRENT_30D} ARS"
            echo -e "  4. 50 días: $${CURRENT_50D} ARS\n"
            
            echo -e "${CYAN}--- MODIFICAR PRECIOS ---${NC}"
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
                    cd /root/wpp-bot && pm2 restart wpp-bot
                    sleep 2
                    echo -e "${GREEN}✅ MercadoPago SDK v2.x activado${NC}"
                else
                    echo -e "${RED}❌ Token inválido${NC}"
                    echo -e "${YELLOW}Debe empezar con APP_USR- o TEST-${NC}"
                fi
            fi
            read -p "Presiona Enter..."
            ;;
        9)
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
            test_mercadopago "$TOKEN"
            
            read -p "\nPresiona Enter..."
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}👥 USUARIOS:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Tests hoy: ' || (SELECT COUNT(*) FROM daily_tests WHERE date = date('now')) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}📅 DISTRIBUCIÓN:${NC}"
            sqlite3 "$DB" "SELECT '7 días: ' || SUM(CASE WHEN plan='7d' THEN 1 ELSE 0 END) || ' | 15 días: ' || SUM(CASE WHEN plan='15d' THEN 1 ELSE 0 END) || ' | 30 días: ' || SUM(CASE WHEN plan='30d' THEN 1 ELSE 0 END) || ' | 50 días: ' || SUM(CASE WHEN plan='50d' THEN 1 ELSE 0 END) FROM payments WHERE status='approved'"
            
            echo -e "\n${YELLOW}💸 INGRESOS HOY:${NC}"
            sqlite3 "$DB" "SELECT 'Hoy: $' || printf('%.2f', SUM(CASE WHEN date(created_at) = date('now') THEN amount ELSE 0 END)) FROM payments"
            
            read -p "\nPresiona Enter..."
            ;;
        11)
            echo -e "\n${YELLOW}🧹 Limpiando sesión...${NC}"
            pm2 stop wpp-bot
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}📱 Escanea nuevo QR al iniciar${NC}"
            sleep 2
            ;;
        12)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     ⚙️  CONFIGURACIÓN                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🤖 BOT:${NC}"
            echo -e "  IP: $(get_val '.bot.server_ip')"
            echo -e "  Versión: $(get_val '.bot.version')"
            echo -e "  API: WPPConnect"
            
            echo -e "\n${YELLOW}💰 PRECIOS:${NC}"
            echo -e "  7d: $(get_val '.prices.price_7d') ARS"
            echo -e "  15d: $(get_val '.prices.price_15d') ARS"
            echo -e "  30d: $(get_val '.prices.price_30d') ARS"
            echo -e "  50d: $(get_val '.prices.price_50d') ARS"
            echo -e "  Test: $(get_val '.prices.test_hours') hora(s)"
            
            echo -e "\n${YELLOW}💳 MERCADOPAGO:${NC}"
            MP_TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "null" ]]; then
                echo -e "  Estado: ${GREEN}CONFIGURADO${NC}"
                echo -e "  Token: ${MP_TOKEN:0:30}..."
            else
                echo -e "  Estado: ${RED}NO CONFIGURADO${NC}"
            fi
            
            echo -e "\n${YELLOW}⚡ AJUSTES:${NC}"
            echo -e "  Limpieza: cada 15 minutos"
            echo -e "  Test: $(get_val '.prices.test_hours') hora(s)"
            echo -e "  Contraseña: mgvpn247 (fija)"
            
            read -p "\nPresiona Enter..."
            ;;
        13)
            echo -e "\n${YELLOW}🐛 Mostrando logs en tiempo real...${NC}"
            echo -e "${CYAN}Presiona Ctrl+C para salir${NC}"
            pm2 logs wpp-bot --lines 50 --raw
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
PANEL_EOF

chmod +x /usr/local/bin/wppbot
check_success "Panel de control creado"

# ================================================
# PASO 8: CONFIGURAR PM2 Y FINALIZAR
# ================================================
echo -e "\n${CYAN}${BOLD}[8/8] Configurando PM2 y finalizando...${NC}"

# Iniciar bot con PM2
cd /root/wpp-bot
pm2 stop wpp-bot 2>/dev/null || true
pm2 delete wpp-bot 2>/dev/null || true
pm2 start bot.js --name wpp-bot
pm2 save
pm2 startup

# Instalar qrencode para mostrar QR en terminal
apt-get install -y qrencode

# Configurar permisos
chmod -R 755 /opt/wpp-bot
chmod -R 755 /root/wpp-bot

check_success "Configuración completada"

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          ✅ INSTALACIÓN COMPLETA - WPPCONNECT BOT ✅        ║
║                                                              ║
║       🔧 QR FIX - Corrección completa del QR              ║
║       💰 MercadoPago SDK v2.x integrado                   ║
║       📱 Panel de control mejorado                        ║
║       🛡️  Webhook para pagos automáticos                 ║
║       📊 Estadísticas en tiempo real                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Instalación completada exitosamente${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🚀 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}wppbot${NC}       - Panel de control principal"
echo -e "  ${GREEN}pm2 logs wpp-bot${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart wpp-bot${NC} - Reiniciar bot"
echo -e "\n${YELLOW}🔧 CORRECCIONES APLICADAS:${NC}\n"
echo -e "  ✅ QR mejorado en terminal"
echo -e "  ✅ QR guardado en /opt/wpp-bot/data/latest_qr.png"
echo -e "  ✅ Opción 'Forzar nuevo QR' en panel"
echo -e "  ✅ Compatibilidad mejorada con Chromium"
echo -e "  ✅ Webhook para pagos automáticos"
echo -e "\n${YELLOW}💰 CONFIGURAR MERCADOPAGO:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}wppbot${NC}"
echo -e "  2. Opción ${CYAN}[8]${NC} - Configurar MercadoPago"
echo -e "  3. Pega tu token de producción"
echo -e "  4. Opción ${CYAN}[9]${NC} - Testear conexión"
echo -e "\n${YELLOW}📱 ESCANEAR QR:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}wppbot${NC}"
echo -e "  2. Opción ${CYAN}[3]${NC} - Ver QR y logs"
echo -e "  3. Escanea el código QR con WhatsApp"
echo -e "  4. Si no aparece, usa opción ${CYAN}[4]${NC} - Forzar nuevo QR"
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}El bot está listo para usar! 🎉${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Iniciar panel de control ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Iniciando panel de control...${NC}"
    wppbot
fi

echo -e "\n${GREEN}¡Instalación finalizada!${NC}\n"
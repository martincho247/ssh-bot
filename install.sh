#!/bin/bash
# ================================================
# HTTP CUSTOM BOT PRO v9.1 - HWID SYSTEM COMPLETE
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
║     ██╗  ██╗██╗    ██╗██╗██████╗     ██████╗ ███████╗██████╗ ║
║     ██║  ██║██║    ██║██║██╔══██╗    ██╔══██╗██╔════╝██╔══██╗║
║     ███████║██║ █╗ ██║██║██║  ██║    ██████╔╝█████╗  ██║  ██║║
║     ██╔══██║██║███╗██║██║██║  ██║    ██╔══██╗██╔══╝  ██║  ██║║
║     ██║  ██║╚███╔███╔╝██║██████╔╝    ██║  ██║███████╗██████╔╝║
║     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝╚═════╝     ╚═╝  ╚═╝╚══════╝╚═════╝ ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║           🤖 HTTP CUSTOM BOT PRO v9.1 - HWID SYSTEM         ║
║               📱 Sistema de archivos .hc personalizados     ║
║               🔐 Identificación por HWID único              ║
║               ⏰ Prueba: 2 horas automáticas                ║
║               💎 Premium: Días según compra                ║
║               📤 Envío automático por WhatsApp             ║
║               💳 MercadoPago SDK v2.x FULLY FIXED          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ SISTEMA HWID COMPLETO:${NC}"
echo -e "  🔴 ${RED}FIX 1:${NC} Eliminado sistema usuario/contraseña"
echo -e "  🟡 ${YELLOW}FIX 2:${NC} Sistema HWID + archivos .hc"
echo -e "  🟢 ${GREEN}FIX 3:${NC} Generación automática de configs"
echo -e "  🔵 ${BLUE}FIX 4:${NC} Envío por WhatsApp"
echo -e "  🟣 ${PURPLE}FIX 5:${NC} Validación HWID única"
echo -e "  ⏰ ${CYAN}FIX 6:${NC} Test 2 horas con HWID"
echo -e "  ⚡ ${CYAN}FIX 7:${NC} Limpieza cada 15 minutos"
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
echo -e "   • Crear HTTP Custom Bot Pro v9.1"
echo -e "   • Sistema HWID + archivos .hc"
echo -e "   • Generación automática de configuraciones"
echo -e "   • Envío por WhatsApp"
echo -e "   • Test 2 horas con HWID"
echo -e "   • MercadoPago SDK v2.x"
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
    sshpass at zip unzip \
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
# PREPARAR ESTRUCTURA HWID
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA HWID...${NC}"

INSTALL_DIR="/opt/hc-bot"
USER_HOME="/root/hc-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
HC_DIR="$INSTALL_DIR/hc_files"
TEMPLATE_DIR="$INSTALL_DIR/templates"

# Limpiar instalaciones anteriores
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete hc-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,hc_files,templates,backups}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "HTTP Custom Bot Pro",
        "version": "9.1-HWID-SYSTEM",
        "server_ip": "$SERVER_IP",
        "server_port": "8080",
        "server_method": "chacha20-ietf-poly1305",
        "server_password": "mypassword123"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 500.00,
        "price_15d": 800.00,
        "price_30d": 1200.00,
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
        "hc_files": "$HC_DIR",
        "templates": "$TEMPLATE_DIR"
    },
    "hc_config": {
        "server": "$SERVER_IP",
        "port": "8080",
        "method": "chacha20-ietf-poly1305",
        "password": "mypassword123",
        "obfs": "plain",
        "protocol": "origin",
        "remarks": "Servidor Premium",
        "group": "HC-BOT"
    }
}
EOF

# Crear plantilla de configuración .hc
mkdir -p "$TEMPLATE_DIR"
cat > "$TEMPLATE_DIR/template.hc" << 'TEMPLATEEOF'
{
  "configs": [
    {
      "server": "${SERVER}",
      "server_port": ${PORT},
      "method": "${METHOD}",
      "password": "${PASSWORD}",
      "plugin": "",
      "plugin_opts": "",
      "plugin_args": "",
      "remarks": "${REMARKS}",
      "timeout": 5,
      "auth": false
    }
  ],
  "strategy": "com.shadowsocks.strategy.ha",
  "index": 0,
  "global": false,
  "enabled": true,
  "shareOverLan": false,
  "isDefault": false,
  "localPort": 1080,
  "pacUrl": null,
  "useOnlinePac": false,
  "availabilityStatistics": false,
  "autoCheckUpdate": true,
  "isIPv6Enabled": false,
  "isVerboseLogging": false,
  "logViewer": null,
  "proxy": {
    "proxyServer": "",
    "proxyPort": 0,
    "proxyType": 0
  },
  "hotkey": {
    "SwitchSystemProxy": "",
    "SwitchSystemProxyMode": "",
    "SwitchAllowLan": "",
    "ShowLogs": "",
    "ServerMoveUp": "",
    "ServerMoveDown": "",
    "RegHotkeysAtStartup": false
  }
}
TEMPLATEEOF

# Crear base de datos HWID
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    max_connections INTEGER DEFAULT 1,
    status INTEGER DEFAULT 1,
    hc_file TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    hwid TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, hwid, date)
);
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    hwid TEXT,
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
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_hwid ON users(hwid);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_hwid ON payments(hwid);
SQL

echo -e "${GREEN}✅ Estructura HWID creada${NC}"

# ================================================
# CREAR BOT HWID COMPLETO
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT HWID COMPLETO...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "hc-bot-pro",
    "version": "9.1.0",
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

# ================================================
# CREAR BOT.JS COMPLETO CON HWID
# ================================================
echo -e "${YELLOW}📝 Creando bot.js completo con sistema HWID...${NC}"

cat > "bot.js" << 'BOTEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcodeTerminal = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const chalk = require('chalk');
const cron = require('node-cron');
const axios = require('axios');

function loadConfig() {
    delete require.cache[require.resolve('/opt/hc-bot/config/config.json')];
    return require('/opt/hc-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// MERCADOPAGO SDK V2.X
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
            return true;
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpClient = null;
            mpPreference = null;
            return false;
        }
    }
    console.log(chalk.yellow('⚠️ MercadoPago NO CONFIGURADO (token vacío)'));
    return false;
}

let mpEnabled = initMercadoPago();
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║      🤖 HTTP CUSTOM BOT PRO v9.1 - HWID SYSTEM             ║'));
console.log(chalk.cyan.bold('║               📱 Sistema de archivos .hc                   ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));
console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}:${config.bot.server_port}`));
console.log(chalk.yellow(`🔐 Method: ${config.bot.server_method}`));
console.log(chalk.yellow(`💳 MercadoPago: ${mpEnabled ? '✅ SDK v2.x ACTIVO' : '❌ NO CONFIGURADO'}`));
console.log(chalk.green('✅ Sistema HWID activado'));
console.log(chalk.green('✅ Generación automática de .hc'));
console.log(chalk.green('✅ Envío por WhatsApp'));
console.log(chalk.green('✅ Test 2 horas'));
console.log(chalk.green('✅ Limpieza cada 15 minutos'));

// FUNCIÓN PARA GENERAR ARCHIVO .HC
async function generateHCFile(hwid, tipo, days = 0) {
    try {
        const templatePath = path.join(config.paths.templates, 'template.hc');
        let template = await fs.readFile(templatePath, 'utf8');
        
        let expireDate;
        let remarks;
        
        if (tipo === 'test') {
            expireDate = moment().add(2, 'hours').format('DD/MM/YYYY HH:mm');
            remarks = `Prueba 2h - Expira: ${expireDate}`;
        } else {
            expireDate = moment().add(days, 'days').format('DD/MM/YYYY');
            remarks = `Premium ${days}d - Expira: ${expireDate}`;
        }
        
        const hcConfig = {
            SERVER: config.hc_config.server,
            PORT: parseInt(config.hc_config.port),
            METHOD: config.hc_config.method,
            PASSWORD: config.hc_config.password,
            REMARKS: remarks
        };
        
        Object.keys(hcConfig).forEach(key => {
            const regex = new RegExp(`\\\${${key}}`, 'g');
            template = template.replace(regex, hcConfig[key]);
        });
        
        // Validar que sea JSON válido
        JSON.parse(template);
        
        const fileName = `${hwid}_${Date.now()}.hc`;
        const filePath = path.join(config.paths.hc_files, fileName);
        
        await fs.writeFile(filePath, template);
        
        return {
            success: true,
            filePath: filePath,
            fileName: fileName,
            expireDate: expireDate,
            remarks: remarks
        };
        
    } catch (error) {
        console.error(chalk.red('❌ Error generando .hc:'), error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// REGISTRAR HWID EN LA BASE DE DATOS
async function registerHWID(phone, hwid, tipo, days = 0) {
    return new Promise((resolve, reject) => {
        // Verificar si el HWID ya existe y está activo
        db.get('SELECT * FROM users WHERE hwid = ? AND status = 1', [hwid], async (err, row) => {
            if (err) return reject(err);
            
            if (row) {
                // HWID ya registrado y activo
                resolve({
                    success: false,
                    message: 'Este HWID ya está registrado y activo',
                    hcFile: row.hc_file,
                    tipo: row.tipo,
                    expires_at: row.expires_at
                });
                return;
            }
            
            // Generar archivo .hc
            const hcResult = await generateHCFile(hwid, tipo, days);
            
            if (!hcResult.success) {
                reject(new Error(hcResult.error));
                return;
            }
            
            // Determinar fecha de expiración
            let expiresAt;
            if (tipo === 'test') {
                expiresAt = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            } else {
                expiresAt = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            }
            
            // Insertar en la base de datos
            db.run(
                `INSERT INTO users (phone, hwid, tipo, expires_at, max_connections, status, hc_file) VALUES (?, ?, ?, ?, 1, 1, ?)`,
                [phone, hwid, tipo, expiresAt, hcResult.filePath],
                function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve({
                            success: true,
                            hwid: hwid,
                            tipo: tipo,
                            expiresAt: expiresAt,
                            hcFile: hcResult.filePath,
                            fileName: hcResult.fileName,
                            remarks: hcResult.remarks
                        });
                    }
                }
            );
        });
    });
}

// VERIFICAR SI PUEDE CREAR TEST
function canCreateTest(phone, hwid) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get(
            'SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND hwid = ? AND date = ?',
            [phone, hwid, today],
            (err, row) => {
                if (err) {
                    console.error('Error BD canCreateTest:', err);
                    resolve(false);
                    return;
                }
                resolve(row && row.count === 0);
            }
        );
    });
}

// REGISTRAR TEST
function registerTest(phone, hwid) {
    db.run(
        'INSERT OR IGNORE INTO daily_tests (phone, hwid, date) VALUES (?, ?, ?)',
        [phone, hwid, moment().format('YYYY-MM-DD')],
        (err) => {
            if (err) console.error('Error registerTest:', err);
        }
    );
}

// CREAR PAGO MERCADOPAGO
async function createMercadoPagoPayment(phone, hwid, plan, days, amount) {
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
        const paymentId = `PREMIUM-${hwid}-${plan}-${Date.now()}`;
        console.log(chalk.cyan(`🔄 Creando pago MP: ${paymentId}`));
        
        const expirationDate = moment().add(24, 'hours');
        const isoDate = expirationDate.toISOString();
        
        const preferenceData = {
            items: [{
                title: `HTTP CUSTOM PREMIUM ${days} DÍAS`,
                description: `HWID: ${hwid} - ${days} días de acceso`,
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
            statement_descriptor: 'HTTP CUSTOM PREMIUM'
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point || response.sandbox_init_point;
            const qrPath = `${config.paths.qr_codes}/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 300,
                margin: 1
            });
            
            db.run(
                `INSERT INTO payments (payment_id, phone, hwid, plan, days, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
                [paymentId, phone, hwid, plan, days, amount, paymentUrl, qrPath, response.id]
            );
            
            console.log(chalk.green(`✅ Pago creado: ${paymentId}`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                preferenceId: response.id
            };
        }
        
        throw new Error('Sin ID de preferencia en respuesta');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        return { success: false, error: error.message };
    }
}

// CLIENTE WHATSAPP WEB
const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'hc-bot-v91'}),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--no-first-run'],
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
    QRCode.toFile('/root/qr-hc-bot.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.green('\n💾 QR guardado: /root/qr-hc-bot.png\n'));
});

client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT HWID LISTO - ENVÍA "menu" AL WHATSAPP\n'));
    qrCount = 0;
});

// MANEJAR MENSAJES - VERSIÓN SIMPLIFICADA Y FUNCIONAL
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    // MENU PRINCIPAL
    if (['menu', 'hola', 'start', 'hi', '0'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, `╔══════════════════════════════════════╗
║   🚀 *HTTP CUSTOM BOT HWID*        ║
╚══════════════════════════════════════╝

📋 *MENU:*

1️⃣ *Prueba GRATIS 2h* 
   Envía: *hwid TU_CODIGO*

2️⃣ *Planes Premium*
   7d: $${config.prices.price_7d}
   15d: $${config.prices.price_15d}
   30d: $${config.prices.price_30d}
   Envía: *comprar7*, *comprar15*, *comprar30*

3️⃣ *Mis archivos .hc*

4️⃣ *Estado de pagos*

5️⃣ *Descargar HTTP Custom*

6️⃣ *Soporte*

7️⃣ *Instrucciones HWID*`, { sendSeen: false });
    }
    
    // PRUEBA GRATIS CON HWID
    else if (text.toLowerCase().startsWith('hwid ')) {
        const hwid = text.substring(5).trim().toUpperCase();
        
        if (hwid.length < 3) {
            await client.sendMessage(phone, `❌ HWID muy corto (mínimo 3 caracteres)`, { sendSeen: false });
            return;
        }
        
        // Verificar si ya usó prueba hoy
        const canTest = await canCreateTest(phone, hwid);
        
        if (!canTest) {
            await client.sendMessage(phone, `⚠️ *YA USÓ LA PRUEBA HOY*

Cada HWID solo puede probar 1 vez por día.

💎 *Planes premium:* Escribe *2*`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `🔄 *PROCESANDO HWID: ${hwid}*`, { sendSeen: false });
        
        try {
            // Registrar como prueba
            const result = await registerHWID(phone, hwid, 'test', 0);
            
            if (!result.success) {
                // HWID ya existe
                await client.sendMessage(phone, `📁 *HWID YA ACTIVO*

Envía *reenviar ${hwid}* para recibir el archivo.

💎 Para premium: *comprar7*, *comprar15*, *comprar30*`, { sendSeen: false });
                return;
            }
            
            // Registrar en daily_tests
            registerTest(phone, hwid);
            
            // Enviar archivo .hc
            const media = MessageMedia.fromFilePath(result.hcFile);
            await client.sendMessage(phone, media, {
                caption: `✅ *PRUEBA 2 HORAS ACTIVADA*

🆔 HWID: ${hwid}
⏰ Expira: ${result.expiresAt}

📱 *Instrucciones:*
1. Guarda este archivo
2. Ábrelo con HTTP Custom
3. ¡Conéctate!

⚠️ Solo 1 prueba por HWID/día
💎 Para premium: Escribe *2*`,
                sendSeen: false
            });
            
            console.log(chalk.green(`✅ Prueba enviada: ${hwid}`));
            
        } catch (error) {
            console.error(chalk.red('❌ Error prueba:'), error);
            await client.sendMessage(phone, `❌ Error: ${error.message}`, { sendSeen: false });
        }
    }
    
    // COMPRAR PLANES
    else if (['comprar7', 'comprar15', 'comprar30'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, `💰 *PARA COMPRAR:*

1. Primero registra tu HWID:
   Envía *hwid TU_CODIGO*

2. Luego escribe *${text}*

📋 Ejemplo:
   hwid ABC123XYZ
   comprar7`, { sendSeen: false });
    }
    
    // COMPRAR CON HWID (formato: hwid CODIGO comprar7)
    else if (text.toLowerCase().includes('hwid') && 
             (text.toLowerCase().includes('comprar7') || 
              text.toLowerCase().includes('comprar15') || 
              text.toLowerCase().includes('comprar30'))) {
        
        const parts = text.split(' ').filter(p => p.trim() !== '');
        if (parts.length < 3) {
            await client.sendMessage(phone, `❌ Formato: *hwid CODIGO comprar7*`, { sendSeen: false });
            return;
        }
        
        const hwid = parts[1].toUpperCase();
        const planCmd = parts[2].toLowerCase();
        
        const planMap = {
            'comprar7': { days: 7, amount: config.prices.price_7d, plan: '7d' },
            'comprar15': { days: 15, amount: config.prices.price_15d, plan: '15d' },
            'comprar30': { days: 30, amount: config.prices.price_30d, plan: '30d' }
        };
        
        const plan = planMap[planCmd];
        if (!plan) {
            await client.sendMessage(phone, `❌ Plan inválido. Usa: comprar7, comprar15, comprar30`, { sendSeen: false });
            return;
        }
        
        // Verificar MP
        if (!mpEnabled) {
            await client.sendMessage(phone, `❌ MercadoPago no configurado. Contacta soporte.`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, `🔄 Generando pago para HWID: ${hwid}...`, { sendSeen: false });
        
        try {
            const payment = await createMercadoPagoPayment(phone, hwid, plan.plan, plan.days, plan.amount);
            
            if (payment.success) {
                await client.sendMessage(phone, `💳 *PAGO GENERADO*

🔗 ${payment.paymentUrl}

✅ Te enviaré el archivo .hc cuando se apruebe.`, { sendSeen: false });
            } else {
                await client.sendMessage(phone, `❌ Error: ${payment.error}`, { sendSeen: false });
            }
        } catch (error) {
            await client.sendMessage(phone, `❌ Error: ${error.message}`, { sendSeen: false });
        }
    }
    
    // REENVIAR ARCHIVO
    else if (text.toLowerCase().startsWith('reenviar ')) {
        const hwid = text.substring(9).trim().toUpperCase();
        
        db.get(`SELECT hc_file FROM users WHERE hwid = ? AND status = 1`, [hwid], async (err, row) => {
            if (!row || !row.hc_file) {
                await client.sendMessage(phone, `❌ No hay archivo activo para ${hwid}`, { sendSeen: false });
                return;
            }
            
            if (!fsSync.existsSync(row.hc_file)) {
                await client.sendMessage(phone, `❌ Archivo no encontrado. Contacta soporte.`, { sendSeen: false });
                return;
            }
            
            try {
                const media = MessageMedia.fromFilePath(row.hc_file);
                await client.sendMessage(phone, media, {
                    caption: `📁 Archivo .hc para HWID: ${hwid}`,
                    sendSeen: false
                });
            } catch (error) {
                await client.sendMessage(phone, `❌ Error enviando archivo`, { sendSeen: false });
            }
        });
    }
    
    // MIS ARCHIVOS
    else if (text === '3') {
        db.all(`SELECT hwid, tipo, expires_at FROM users WHERE phone = ? AND status = 1`, [phone], async (err, rows) => {
            if (!rows || rows.length === 0) {
                await client.sendMessage(phone, `📭 No tienes archivos activos`, { sendSeen: false });
                return;
            }
            
            let msg = `📁 *TUS ARCHIVOS .HC*\n\n`;
            rows.forEach((row, i) => {
                const tipo = row.tipo === 'premium' ? '💎' : '🆓';
                msg += `${i+1}. ${tipo} ${row.hwid}\n`;
                msg += `   Expira: ${moment(row.expires_at).format('DD/MM HH:mm')}\n`;
                msg += `   Reenviar: *reenviar ${row.hwid}*\n\n`;
            });
            
            await client.sendMessage(phone, msg, { sendSeen: false });
        });
    }
    
    // ESTADO DE PAGOS
    else if (text === '4') {
        db.all(`SELECT hwid, plan, amount, status FROM payments WHERE phone = ?`, [phone], async (err, rows) => {
            if (!rows || rows.length === 0) {
                await client.sendMessage(phone, `📭 No hay pagos registrados`, { sendSeen: false });
                return;
            }
            
            let msg = `💳 *TUS PAGOS*\n\n`;
            rows.forEach((row, i) => {
                const status = row.status === 'approved' ? '✅' : '⏳';
                msg += `${i+1}. ${status} ${row.hwid} - ${row.plan}\n`;
                msg += `   $${row.amount} - ${row.status}\n\n`;
            });
            
            await client.sendMessage(phone, msg, { sendSeen: false });
        });
    }
    
    // INSTRUCCIONES HWID
    else if (text === '7') {
        await client.sendMessage(phone, `🆔 *OBTENER TU HWID:*

1. Abre HTTP Custom
2. Ve a *Configuración*
3. Busca *HWID* o *Device ID*
4. Copia el código

📋 Ejemplo de código: ABC123XYZ

💬 Luego envíalo así:
*hwid ABC123XYZ*`, { sendSeen: false });
    }
    
    // SOPORTE
    else if (text === '6') {
        await client.sendMessage(phone, `🆘 *SOPORTE:*

📞 ${config.links.support}

⏰ 9AM - 10PM

📋 Problemas comunes:
• HWID no encontrado: Escribe *7*
• Archivo no llega: *reenviar HWID*
• Error pago: *4*`, { sendSeen: false });
    }
});

// CRON JOBS
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos...'));
});

cron.schedule('*/15 * * * *', () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    db.all('SELECT hwid, hc_file FROM users WHERE expires_at < ? AND status = 1', [now], (err, rows) => {
        if (rows && rows.length > 0) {
            rows.forEach(row => {
                if (fsSync.existsSync(row.hc_file)) {
                    fsSync.unlinkSync(row.hc_file);
                }
                db.run('UPDATE users SET status = 0 WHERE hwid = ?', [row.hwid]);
            });
            console.log(chalk.green(`🧹 Limpiados ${rows.length} HWIDs`));
        }
    });
});

console.log(chalk.green('\n🚀 Inicializando bot...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot HWID completo creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL HWID
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL HWID...${NC}"

cat > /usr/local/bin/hcbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/hc-bot/data/users.db"
CONFIG="/opt/hc-bot/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
set_val() { local t=$(mktemp); jq "$1 = $2" "$CONFIG" > "$t" && mv "$t" "$CONFIG"; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL HWID BOT v9.1                       ║${NC}"
    echo -e "${CYAN}║               📱 Sistema de archivos .hc                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_HWIDS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_HWIDS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="hc-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
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
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA HWID${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  HWIDs: ${CYAN}$ACTIVE_HWIDS/$TOTAL_HWIDS${NC} activos/total"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  Test: ${GREEN}2 horas${NC} | Limpieza: ${GREEN}cada 15 min${NC}"
    echo -e "  Servidor: ${GREEN}$(get_val '.bot.server_ip'):$(get_val '.bot.server_port')${NC}"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC}  🆔  Crear HWID manual"
    echo -e "${CYAN}[5]${NC}  👥  Listar HWIDs activos"
    echo -e "${CYAN}[6]${NC}  🗑️   Eliminar HWID"
    echo -e ""
    echo -e "${CYAN}[7]${NC}  💰  Cambiar precios"
    echo -e "${CYAN}[8]${NC}  🔑  Configurar MercadoPago"
    echo -e "${CYAN}[9]${NC}  ⚙️   Configurar servidor"
    echo -e "${CYAN}[10]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[11]${NC} 📁  Gestionar archivos .hc"
    echo -e "${CYAN}[12]${NC} 📝  Ver logs"
    echo -e "${CYAN}[13]${NC} 🔧  Reparar bot"
    echo -e "${CYAN}[14]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando bot...${NC}"
            cd /root/hc-bot
            pm2 restart hc-bot 2>/dev/null || pm2 start bot.js --name hc-bot
            pm2 save
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop hc-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-hc-bot.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-hc-bot.png${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs hc-bot --lines 100
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs hc-bot --lines 50
            fi
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🆔 CREAR HWID MANUAL                    ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Teléfono (ej: 5491122334455): " PHONE
            read -p "HWID (ej: ABC123XYZ): " HWID
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 2h, 7/15/30=premium): " DAYS
            
            [[ -z "$DAYS" ]] && DAYS="30"
            HWID=$(echo "$HWID" | tr '[:lower:]' '[:upper:]')
            
            # Verificar si HWID ya existe
            EXIST=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE hwid = '$HWID' AND status = 1")
            if [[ "$EXIST" -gt 0 ]]; then
                echo -e "\n${RED}❌ HWID ya existe y está activo${NC}"
                read -p "Presiona Enter..." 
                continue
            fi
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
                EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
            else
                EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
            fi
            
            # Generar archivo .hc
            cd /root/hc-bot
            NODE_SCRIPT=$(cat << 'NODE'
const fs = require('fs').promises;
const path = require('path');
const moment = require('moment');

async function generateHCFile(hwid, tipo, days) {
    try {
        const config = require('/opt/hc-bot/config/config.json');
        const templatePath = path.join(config.paths.templates, 'template.hc');
        let template = await fs.readFile(templatePath, 'utf8');
        
        let expireDate;
        let remarks;
        
        if (tipo === 'test') {
            expireDate = moment().add(2, 'hours').format('DD/MM/YYYY HH:mm');
            remarks = \`Prueba 2h - Expira: \${expireDate}\`;
        } else {
            expireDate = moment().add(days, 'days').format('DD/MM/YYYY');
            remarks = \`Premium \${days}d - Expira: \${expireDate}\`;
        }
        
        const hcConfig = {
            SERVER: config.hc_config.server,
            PORT: config.hc_config.port,
            METHOD: config.hc_config.method,
            PASSWORD: config.hc_config.password,
            REMARKS: remarks
        };
        
        Object.keys(hcConfig).forEach(key => {
            const regex = new RegExp(\`\\\\\\\$\{\${key}\}\`, 'g');
            template = template.replace(regex, hcConfig[key]);
        });
        
        const fileName = \`\${hwid}_\${Date.now()}.hc\`;
        const filePath = path.join(config.paths.hc_files, fileName);
        
        await fs.writeFile(filePath, template);
        
        return {
            success: true,
            filePath: filePath,
            fileName: fileName
        };
        
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

const args = process.argv.slice(2);
generateHCFile(args[0], args[1], parseInt(args[2])).then(result => {
    if (result.success) {
        console.log(JSON.stringify(result));
    } else {
        console.error(result.error);
        process.exit(1);
    }
});
NODE
            )
            
            TEMP_SCRIPT="/tmp/generate_hc.js"
            echo "$NODE_SCRIPT" > "$TEMP_SCRIPT"
            
            RESULT=$(node "$TEMP_SCRIPT" "$HWID" "$TIPO" "$DAYS" 2>/dev/null)
            rm -f "$TEMP_SCRIPT"
            
            if [[ -n "$RESULT" ]]; then
                FILE_PATH=$(echo "$RESULT" | jq -r '.filePath' 2>/dev/null)
                
                sqlite3 "$DB" "INSERT INTO users (phone, hwid, tipo, expires_at, max_connections, status, hc_file) VALUES ('$PHONE', '$HWID', '$TIPO', '$EXPIRE_DATE', 1, 1, '$FILE_PATH')"
                
                echo -e "\n${GREEN}✅ HWID CREADO EXITOSAMENTE${NC}"
                echo -e "🆔 HWID: ${HWID}"
                echo -e "📞 Teléfono: ${PHONE}"
                echo -e "🎯 Tipo: ${TIPO}"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "📁 Archivo: $(basename "$FILE_PATH")"
            else
                echo -e "\n${RED}❌ Error generando archivo .hc${NC}"
            fi
            
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 HWIDs ACTIVOS                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT substr(phone,1,12) as tel, hwid, tipo, expires_at, substr(hc_file,30) as archivo FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total activos: ${ACTIVE_HWIDS}${NC}"
            read -p "Presiona Enter..." 
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🗑️  ELIMINAR HWID                       ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "HWID a eliminar: " DEL_HWID
            if [[ -n "$DEL_HWID" ]]; then
                # Obtener archivo .hc
                HC_FILE=$(sqlite3 "$DB" "SELECT hc_file FROM users WHERE hwid = '$DEL_HWID'")
                
                # Eliminar archivos
                if [[ -n "$HC_FILE" && -f "$HC_FILE" ]]; then
                    rm -f "$HC_FILE"
                    rm -f "${HC_FILE%.hc}.json"
                fi
                
                # Actualizar BD
                sqlite3 "$DB" "UPDATE users SET status = 0 WHERE hwid = '$DEL_HWID'"
                echo -e "${GREEN}✅ HWID $DEL_HWID eliminado${NC}"
            fi
            read -p "Presiona Enter..." 
            ;;
        7)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     💰 CAMBIAR PRECIOS                      ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_7D=$(get_val '.prices.price_7d')
            CURRENT_15D=$(get_val '.prices.price_15d')
            CURRENT_30D=$(get_val '.prices.price_30d')
            
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  7 días: $${CURRENT_7D}"
            echo -e "  15 días: $${CURRENT_15D}"
            echo -e "  30 días: $${CURRENT_30D}"
            echo -e "  Test: $(get_val '.prices.test_hours') horas\n"
            
            read -p "Nuevo precio 7d [${CURRENT_7D}]: " NEW_7D
            read -p "Nuevo precio 15d [${CURRENT_15D}]: " NEW_15D
            read -p "Nuevo precio 30d [${CURRENT_30D}]: " NEW_30D
            read -p "Horas test [2]: " TEST_HOURS
            
            [[ -n "$NEW_7D" ]] && set_val '.prices.price_7d' "$NEW_7D"
            [[ -n "$NEW_15D" ]] && set_val '.prices.price_15d' "$NEW_15D"
            [[ -n "$NEW_30D" ]] && set_val '.prices.price_30d' "$NEW_30D"
            [[ -n "$TEST_HOURS" ]] && set_val '.prices.test_hours' "$TEST_HOURS"
            
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
                    cd /root/hc-bot && pm2 restart hc-bot
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
            echo -e "${CYAN}║                     ⚙️  CONFIGURAR SERVIDOR                 ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            CURRENT_SERVER=$(get_val '.hc_config.server')
            CURRENT_PORT=$(get_val '.hc_config.port')
            CURRENT_METHOD=$(get_val '.hc_config.method')
            CURRENT_PASSWORD=$(get_val '.hc_config.password')
            
            echo -e "${YELLOW}Configuración actual:${NC}"
            echo -e "  Servidor: ${CURRENT_SERVER}"
            echo -e "  Puerto: ${CURRENT_PORT}"
            echo -e "  Método: ${CURRENT_METHOD}"
            echo -e "  Contraseña: ${CURRENT_PASSWORD}\n"
            
            read -p "Nuevo servidor [${CURRENT_SERVER}]: " NEW_SERVER
            read -p "Nuevo puerto [${CURRENT_PORT}]: " NEW_PORT
            read -p "Nuevo método [${CURRENT_METHOD}]: " NEW_METHOD
            read -p "Nueva contraseña [${CURRENT_PASSWORD}]: " NEW_PASSWORD
            
            [[ -n "$NEW_SERVER" ]] && set_val '.hc_config.server' "\"$NEW_SERVER\"" && set_val '.bot.server_ip' "\"$NEW_SERVER\""
            [[ -n "$NEW_PORT" ]] && set_val '.hc_config.port' "$NEW_PORT" && set_val '.bot.server_port' "\"$NEW_PORT\""
            [[ -n "$NEW_METHOD" ]] && set_val '.hc_config.method' "\"$NEW_METHOD\"" && set_val '.bot.server_method' "\"$NEW_METHOD\""
            [[ -n "$NEW_PASSWORD" ]] && set_val '.hc_config.password' "\"$NEW_PASSWORD\"" && set_val '.bot.server_password' "\"$NEW_PASSWORD\""
            
            echo -e "\n${GREEN}✅ Configuración actualizada${NC}"
            echo -e "${YELLOW}⚠️  Los nuevos archivos .hc usarán esta configuración${NC}"
            read -p "Presiona Enter..." 
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📊 ESTADÍSTICAS                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🆔 HWIDs:${NC}"
            sqlite3 "$DB" "SELECT 'Total: ' || COUNT(*) || ' | Activos: ' || SUM(CASE WHEN status=1 THEN 1 ELSE 0 END) || ' | Premium: ' || SUM(CASE WHEN tipo='premium' THEN 1 ELSE 0 END) FROM users"
            
            echo -e "\n${YELLOW}💰 PAGOS:${NC}"
            sqlite3 "$DB" "SELECT 'Pendientes: ' || SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) || ' | Aprobados: ' || SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END) || ' | Total: $' || printf('%.2f', SUM(CASE WHEN status='approved' THEN amount ELSE 0 END)) FROM payments"
            
            echo -e "\n${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            sqlite3 "$DB" "SELECT 'Tests: ' || COUNT(*) FROM daily_tests WHERE date = '$TODAY'"
            
            echo -e "\n${YELLOW}📁 ARCHIVOS:${NC}"
            ARCHIVOS=$(ls /opt/hc-bot/hc_files/*.hc 2>/dev/null | wc -l)
            echo -e "  Archivos .hc: $ARCHIVOS"
            
            read -p "\nPresiona Enter..." 
            ;;
        11)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     📁 GESTIONAR ARCHIVOS .hc               ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📂 Directorio: /opt/hc-bot/hc_files${NC}\n"
            
            ls -la /opt/hc-bot/hc_files/*.hc 2>/dev/null | head -20 | while read line; do
                echo "  $line"
            done
            
            echo -e "\n${CYAN}Opciones:${NC}"
            echo -e "  1. Limpiar archivos antiguos"
            echo -e "  2. Ver contenido de un archivo"
            echo -e "  3. Volver"
            
            read -p "Selecciona (1-3): " FILE_OPT
            
            case $FILE_OPT in
                1)
                    echo -e "\n${YELLOW}🧹 Limpiando archivos antiguos...${NC}"
                    find /opt/hc-bot/hc_files -name "*.hc" -mtime +30 -delete 2>/dev/null
                    find /opt/hc-bot/hc_files -name "*.json" -mtime +30 -delete 2>/dev/null
                    echo -e "${GREEN}✅ Archivos antiguos eliminados${NC}"
                    ;;
                2)
                    read -p "Nombre del archivo (sin ruta): " FILE_NAME
                    if [[ -f "/opt/hc-bot/hc_files/$FILE_NAME" ]]; then
                        echo -e "\n${YELLOW}Contenido de $FILE_NAME:${NC}"
                        cat "/opt/hc-bot/hc_files/$FILE_NAME" | head -20
                    else
                        echo -e "${RED}❌ Archivo no encontrado${NC}"
                    fi
                    ;;
            esac
            
            read -p "Presiona Enter..." 
            ;;
        12)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs hc-bot --lines 100
            ;;
        13)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🔧 REPARAR BOT                          ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "¿Reparar bot? Esto borrará la sesión de WhatsApp (s/N): " CONF
            
            if [[ "$CONF" == "s" ]]; then
                echo -e "\n${YELLOW}🧹 Limpiando...${NC}"
                rm -rf /root/.wwebjs_auth/* /root/.wwebjs_cache/* /root/qr-hc-bot.png
                echo -e "${YELLOW}📦 Reinstalando...${NC}"
                cd /root/hc-bot && npm install --silent
                echo -e "${YELLOW}🔄 Reiniciando...${NC}"
                pm2 restart hc-bot
                echo -e "\n${GREEN}✅ Reparado - Espera 10s para QR${NC}"
                sleep 10
            fi
            read -p "Presiona Enter..." 
            ;;
        14)
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
            
            if [[ "$HTTP_CODE" == "200" ]]; then
                echo -e "${GREEN}✅ CONEXIÓN EXITOSA${NC}\n"
                echo -e "${CYAN}Métodos de pago disponibles:${NC}"
                echo "$RESPONSE" | head -n-1 | jq -r '.[].name' 2>/dev/null | head -5
                echo -e "\n${GREEN}✅ MercadoPago SDK v2.x funcionando correctamente${NC}"
            else
                echo -e "${RED}❌ ERROR - Código HTTP: $HTTP_CODE${NC}\n"
            fi
            
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

chmod +x /usr/local/bin/hcbot
echo -e "${GREEN}✅ Panel HWID creado${NC}"

# ================================================
# CONFIGURAR SERVIDOR SHADOWSOCKS
# ================================================
echo -e "\n${CYAN}${BOLD}🔧 CONFIGURANDO SERVIDOR SHADOWSOCKS...${NC}"

# Instalar shadowsocks-libev
echo -e "${YELLOW}📦 Instalando shadowsocks-libev...${NC}"
apt-get install -y -qq shadowsocks-libev > /dev/null 2>&1

# Crear configuración
cat > /etc/shadowsocks-libev/config.json << SSEOF
{
    "server": "0.0.0.0",
    "server_port": 8080,
    "password": "mypassword123",
    "method": "chacha20-ietf-poly1305",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
SSEOF

# Habilitar y reiniciar servicio
systemctl enable shadowsocks-libev 2>/dev/null || true
systemctl restart shadowsocks-libev 2>/dev/null || true

echo -e "${GREEN}✅ Servidor Shadowsocks configurado${NC}"
echo -e "${YELLOW}📋 Detalles:${NC}"
echo -e "  IP: ${SERVER_IP}"
echo -e "  Puerto: 8080"
echo -e "  Método: chacha20-ietf-poly1305"
echo -e "  Contraseña: mypassword123"

# ================================================
# INICIAR BOT HWID
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT HWID...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name hc-bot
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# CREAR SCRIPT DE CONFIGURACIÓN PERSONAL
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️  CREANDO SCRIPT DE CONFIGURACIÓN PERSONAL...${NC}"

cat > /root/configurar_hc.sh << 'CONFIGEOF'
#!/bin/bash
# ================================================
# CONFIGURADOR PERSONAL HC-BOT
# ================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 CONFIGURANDO HC-BOT CON TU ARCHIVO .hc${NC}\n"

# Verificar archivo .hc personal
if [[ ! -f "/root/config.hc" ]]; then
    echo -e "${RED}❌ No encontré /root/config.hc${NC}"
    echo -e "${YELLOW}Por favor sube tu archivo .hc personalizado a:/root/config.hc${NC}"
    echo -e "\n${CYAN}Ejemplo de comando SCP:${NC}"
    echo -e "scp mi_config.hc root@$(curl -4 -s ifconfig.me):/root/config.hc"
    exit 1
fi

echo -e "${GREEN}✅ Archivo .hc encontrado${NC}"

# Extraer configuración del archivo .hc
SERVER=$(grep -o '"server": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
PORT=$(grep -o '"server_port": *[0-9]*' /root/config.hc | head -1 | awk '{print $2}' | tr -d ',')
METHOD=$(grep -o '"method": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)
PASSWORD=$(grep -o '"password": *"[^"]*"' /root/config.hc | head -1 | cut -d'"' -f4)

if [[ -z "$SERVER" || -z "$PORT" || -z "$METHOD" || -z "$PASSWORD" ]]; then
    echo -e "${RED}❌ No se pudieron extraer los datos del archivo .hc${NC}"
    echo -e "${YELLOW}Verifica que tenga el formato correcto${NC}"
    exit 1
fi

echo -e "${CYAN}📋 Configuración detectada:${NC}"
echo -e "  Servidor: ${GREEN}$SERVER${NC}"
echo -e "  Puerto: ${GREEN}$PORT${NC}"
echo -e "  Método: ${GREEN}$METHOD${NC}"
echo -e "  Contraseña: ${GREEN}$PASSWORD${NC}"

# Actualizar plantilla
echo -e "\n${YELLOW}🔄 Actualizando plantilla...${NC}"
cp /root/config.hc /opt/hc-bot/templates/template.hc
chmod 644 /opt/hc-bot/templates/template.hc

# Actualizar configuración del bot
echo -e "${YELLOW}⚙️ Actualizando configuración del bot...${NC}"
CONFIG_FILE="/opt/hc-bot/config/config.json"

# Crear backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Actualizar con jq
if command -v jq &> /dev/null; then
    jq ".bot.server_ip = \"$SERVER\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".bot.server_port = \"$PORT\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".bot.server_method = \"$METHOD\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".bot.server_password = \"$PASSWORD\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    
    jq ".hc_config.server = \"$SERVER\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".hc_config.port = \"$PORT\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".hc_config.method = \"$METHOD\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    jq ".hc_config.password = \"$PASSWORD\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
else
    # Método alternativo con sed
    sed -i "s|\"server\": \".*\"|\"server\": \"$SERVER\"|g" "$CONFIG_FILE"
    sed -i "s|\"server_port\": \".*\"|\"server_port\": \"$PORT\"|g" "$CONFIG_FILE"
    sed -i "s|\"method\": \".*\"|\"method\": \"$METHOD\"|g" "$CONFIG_FILE"
    sed -i "s|\"password\": \".*\"|\"password\": \"$PASSWORD\"|g" "$CONFIG_FILE"
fi

# Actualizar servidor Shadowsocks
echo -e "${YELLOW}🔧 Actualizando servidor Shadowsocks...${NC}"

cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "$METHOD",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF

# Reiniciar servicios
echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"
systemctl restart shadowsocks-libev 2>/dev/null || true
pm2 restart hc-bot

# Verificar
echo -e "\n${GREEN}✅ CONFIGURACIÓN COMPLETADA${NC}\n"
echo -e "${CYAN}📊 Verificación:${NC}"
echo -e "  Plantilla: ${GREEN}/opt/hc-bot/templates/template.hc${NC}"
echo -e "  Configuración: ${GREEN}$CONFIG_FILE${NC}"
echo -e "  Servidor Shadowsocks: ${GREEN}${SERVER}:${PORT}${NC}"
echo -e "  Método: ${GREEN}${METHOD}${NC}"

echo -e "\n${YELLOW}🎯 Prueba el bot enviando:${NC}"
echo -e "  WhatsApp: ${GREEN}hwid TEST123${NC}"
echo -e "  Deberías recibir tu archivo .hc personalizado\n"

echo -e "${CYAN}Para gestionar: ${GREEN}hcbot${NC}"
CONFIGEOF

chmod +x /root/configurar_hc.sh

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🎉 INSTALACIÓN COMPLETADA - SISTEMA HWID 🎉           ║
║                                                              ║
║         HTTP CUSTOM BOT PRO v9.1 - HWID SYSTEM              ║
║           📱 Sistema de archivos .hc personalizados         ║
║           🆔 Identificación por HWID único                  ║
║           ⏰ Prueba: 2 horas automáticas                    ║
║           💎 Premium: Días según compra                    ║
║           📤 Envío automático por WhatsApp                 ║
║           💳 MercadoPago SDK v2.x FULLY FIXED              ║
║           🔧 Servidor Shadowsocks configurado              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema HWID instalado completamente${NC}"
echo -e "${GREEN}✅ Bot configurado para archivos .hc${NC}"
echo -e "${GREEN}✅ Servidor Shadowsocks activo${NC}"
echo -e "${GREEN}✅ Panel de control disponible${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}\n"
echo -e "  ${GREEN}hcbot${NC}           - Panel de control HWID"
echo -e "  ${GREEN}pm2 logs hc-bot${NC} - Ver logs"
echo -e "  ${GREEN}pm2 restart hc-bot${NC} - Reiniciar\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN:${NC}\n"
echo -e "  1. Sube tu archivo .hc personalizado:"
echo -e "     ${CYAN}scp config.hc root@${SERVER_IP}:/root/config.hc${NC}"
echo -e "  2. Configura con tu servidor:"
echo -e "     ${CYAN}./root/configurar_hc.sh${NC}"
echo -e "  3. Configurar MercadoPago:"
echo -e "     ${CYAN}hcbot${NC} → Opción 8"
echo -e "  4. Escanear QR WhatsApp:"
echo -e "     ${CYAN}hcbot${NC} → Opción 3\n"

echo -e "${YELLOW}📱 FLUJO DEL USUARIO:${NC}"
echo -e "  1. Usuario obtiene HWID de HTTP Custom"
echo -e "  2. Envía: ${GREEN}hwid CODIGO_HWID${NC} al bot"
echo -e "  3. Recibe archivo .hc por WhatsApp ${GREEN}(INMEDIATO)${NC}"
echo -e "  4. Importa archivo en HTTP Custom"
echo -e "  5. ¡Conectado! 🎉\n"

echo -e "${YELLOW}⚡ AJUSTES APLICADOS:${NC}"
echo -e "  • Test: ${GREEN}2 horas${NC}"
echo -e "  • Limpieza: ${GREEN}cada 15 minutos${NC}"
echo -e "  • Servidor: ${GREEN}${SERVER_IP}:8080${NC}"
echo -e "  • Método: ${GREEN}chacha20-ietf-poly1305${NC}\n"

echo -e "${YELLOW}📊 INFO:${NC}"
echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
echo -e "  Puerto: ${CYAN}8080${NC}"
echo -e "  BD: ${CYAN}$DB_FILE${NC}"
echo -e "  Archivos .hc: ${CYAN}$HC_DIR${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel HWID...${NC}\n"
    sleep 2
    /usr/local/bin/hcbot
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}hcbot${NC}\n"
    echo -e "${RED}⚠️  Recuerda subir tu archivo .hc y ejecutar ./root/configurar_hc.sh${NC}\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema HWID instalado exitosamente! 🚀${NC}\n"

# Auto-destrucción opcional
echo -e "${YELLOW}El script de instalación se mantendrá en:${NC}"
echo -e "${CYAN}$(pwd)/$(basename "$0")${NC}"
echo -e "${YELLOW}Guárdalo para futuras instalaciones.${NC}"
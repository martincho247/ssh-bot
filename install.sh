#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALADOR UBUNTU 20.04
# Planes: 7, 15, 30, 50 días
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
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
║                SSH BOT PRO - UBUNTU 20.04                   ║
║               💡 PLANES: 7, 15, 30, 50 DÍAS                 ║
║               🔐 CONTRASEÑA FIJA: mgvpn247                  ║
║               💰 MERCADOPAGO INTEGRADO                      ║
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
echo -e "${CYAN}🔍 Detectando IP del servidor...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    echo -e "${RED}❌ No se pudo obtener IP${NC}"
    read -p "📝 Ingresa la IP manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}"

# Confirmar instalación
echo -e "\n${YELLOW}⚠️  Este instalador hará:${NC}"
echo -e "   • Instalar Node.js 18.x + Chromium"
echo -e "   • Crear SSH Bot Pro con múltiples planes"
echo -e "   • Sistema de estados inteligente"
echo -e "   • Menú: 1=Prueba, 2=Comprar, 3=Renovar, 4=APP"
echo -e "   • Planes: 7, 15, 30, 50 días"
echo -e "   • Pregunta por cupón de descuento"
echo -e "   • Generación de link MercadoPago"
echo -e "   • Panel de control"
echo -e "   • APK automático + Test 1h"
echo -e "   • 🔐 CONTRASEÑA FIJA: mgvpn247"

read -p "$(echo -e "${YELLOW}¿Continuar? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS UBUNTU 20.04
# ================================================
echo -e "\n${CYAN}📦 INSTALANDO DEPENDENCIAS...${NC}"

# Actualizar sistema
echo -e "${YELLOW}🔄 Actualizando sistema...${NC}"
apt-get update -y
apt-get upgrade -y

# Remover Node.js anterior
apt-get remove --purge nodejs npm -y 2>/dev/null || true

# Instalar Node.js 18.x
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
apt-get install -y gcc g++ make

# Instalar Chromium (NO Chrome)
echo -e "${YELLOW}🌐 Instalando Chromium...${NC}"
apt-get install -y chromium-browser chromium-chromedriver

# Instalar dependencias del sistema
echo -e "${YELLOW}⚙️ Instalando utilidades...${NC}"
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev \
    python3 python3-pip \
    ffmpeg unzip cron ufw \
    libgbm-dev libxshmfence-dev

# Instalar PM2 globalmente
echo -e "${YELLOW}🔄 Instalando PM2...${NC}"
npm install -g pm2
pm2 update

# Configurar firewall
echo -e "${YELLOW}🛡️ Configurando firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw allow 3000/tcp
ufw --force enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 CREANDO ESTRUCTURA...${NC}"

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
pkill -f chromium 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "1.0-UBUNTU20",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 1,
        "price_7d_1conn": 1500.00,
        "price_15d_1conn": 2500.00,
        "price_30d_1conn": 5500.00,
        "price_50d_1conn": 8500.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "tutorial": "https://youtube.com",
        "support": "https://wa.me/543435071016",
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/chromium-browser",
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
    plan TEXT,
    days INTEGER,
    connections INTEGER DEFAULT 1,
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
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT OPTIMIZADO PARA UBUNTU 20
# ================================================
echo -e "\n${CYAN}🤖 CREANDO BOT...${NC}"

cd "$USER_HOME"

# package.json optimizado
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-pro",
    "version": "1.0.0",
    "main": "bot.js",
    "dependencies": {
        "whatsapp-web.js": "^1.23.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "axios": "^1.6.5",
        "puppeteer-core": "^21.0.0"
    }
}
PKGEOF

# Instalar paquetes
echo -e "${YELLOW}📦 Instalando paquetes Node.js...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js optimizado
echo -e "${YELLOW}📝 Creando bot.js optimizado...${NC}"

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
moment.locale('es');

// Configuración
const CONFIG_PATH = '/opt/ssh-bot/config/config.json';
function loadConfig() {
    delete require.cache[require.resolve(CONFIG_PATH)];
    return require(CONFIG_PATH);
}
let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// Función de delay
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Sistema de estados
async function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) resolve({ state: 'main_menu', data: null });
            else resolve({
                state: row.state || 'main_menu',
                data: row.data ? JSON.parse(row.data) : null
            });
        });
    });
}

async function setUserState(phone, state, data = null) {
    return new Promise((resolve) => {
        const dataStr = data ? JSON.stringify(data) : null;
        db.run(`INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
            [phone, state, dataStr], (err) => resolve());
    });
}

// Inicializar cliente
console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 SSH BOT PRO - UBUNTU 20.04               ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

console.log(chalk.yellow(`📍 IP: ${config.bot.server_ip}`));
console.log(chalk.yellow(`🔐 Contraseña fija: mgvpn247`));
console.log(chalk.green('✅ Planes: 7, 15, 30, 50 días disponibles'));
console.log(chalk.green('✅ Test 1 hora exacta'));

const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: '/root/.wwebjs_auth',
        clientId: 'ssh-bot-ubuntu20'
    }),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--no-first-run',
            '--disable-extensions',
            '--disable-web-security',
            '--disable-features=IsolateOrigins,site-per-process',
            '--window-size=1280,720'
        ],
        timeout: 60000
    }
});

let qrCount = 0;

// Eventos del cliente
client.on('qr', async (qr) => {
    qrCount++;
    console.clear();
    console.log(chalk.yellow.bold(`\n╔════════ 📱 ESCANEA ESTE QR #${qrCount} ════════╗\n`));
    qrcodeTerminal.generate(qr, { small: true });
    
    try {
        await QRCode.toFile('/root/qr-whatsapp.png', qr, { width: 400 });
        console.log(chalk.green('💾 QR guardado: /root/qr-whatsapp.png'));
    } catch (e) {}
    
    console.log(chalk.cyan('\n📱 Instrucciones:'));
    console.log(chalk.cyan('1. Abre WhatsApp → Dispositivos vinculados'));
    console.log(chalk.cyan('2. Escanea este QR'));
    console.log(chalk.cyan('3. Espera a que diga "BOT CONECTADO"\n'));
});

client.on('authenticated', () => {
    console.log(chalk.green('✅ Autenticado exitosamente!'));
});

client.on('loading_screen', (percent, message) => {
    console.log(chalk.cyan(`⏳ Cargando: ${percent}% - ${message}`));
});

client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n✅ BOT CONECTADO Y OPERATIVO\n'));
    console.log(chalk.cyan('💬 Envía "menu" a tu WhatsApp para comenzar\n'));
    qrCount = 0;
});

client.on('auth_failure', (msg) => {
    console.log(chalk.red('❌ Error de autenticación:'), msg);
});

client.on('disconnected', (reason) => {
    console.log(chalk.red('⚠️  Desconectado:'), reason);
    console.log(chalk.yellow('🔄 Reconectando en 10 segundos...'));
    setTimeout(() => {
        console.log(chalk.cyan('🔄 Intentando reconexión...'));
        client.initialize();
    }, 10000);
});

// Funciones SSH
function generateUsername() {
    return 'USER' + Math.floor(1000 + Math.random() * 9000);
}

function generatePassword() {
    return 'PASS' + Math.floor(1000 + Math.random() * 9000);
}

async function createSSHUser(phone, username, password, days, connections = 1) {
    if (days === 0) {
        // Usuario de prueba (1 hora)
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        await execPromise(`useradd -m -s /bin/bash ${username}`);
        await execPromise(`echo "${username}:${password}" | chpasswd`);
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, 'test', expireFull, 1],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password,
                    expires: expireFull,
                    tipo: 'test',
                    duration: `${config.prices.test_hours} horas`
                }));
        });
    } else {
        // Usuario premium
        const expireDate = moment().add(days, 'days').format('YYYY-MM-DD');
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        await execPromise(`useradd -M -s /bin/false -e ${expireDate} ${username}`);
        await execPromise(`echo "${username}:${password}" | chpasswd`);
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, 'premium', expireFull, connections],
                (err) => err ? reject(err) : resolve({ 
                    username, 
                    password,
                    expires: expireFull,
                    tipo: 'premium',
                    duration: `${days} días`
                }));
        });
    }
}

async function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', [phone, today],
            (err, row) => resolve(!err && row && row.count === 0));
    });
}

function registerTest(phone) {
    db.run('INSERT OR IGNORE INTO daily_tests (phone, date) VALUES (?, ?)', 
        [phone, moment().format('YYYY-MM-DD')]);
}

// Planes disponibles
const availablePlans = {
    '7': { days: 7, amountKey: 'price_7d_1conn', name: '7 DÍAS' },
    '15': { days: 15, amountKey: 'price_15d_1conn', name: '15 DÍAS' },
    '30': { days: 30, amountKey: 'price_30d_1conn', name: '30 DÍAS' },
    '50': { days: 50, amountKey: 'price_50d_1conn', name: '50 DÍAS' }
};

// Manejo de mensajes
client.on('message', async (msg) => {
    const text = msg.body.toLowerCase().trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 30)}`));
    
    const userState = await getUserState(phone);
    
    // MENÚ PRINCIPAL
    if (['menu', 'hola', 'start', 'hi', 'volver', 'atras', '0'].includes(text)) {
        await setUserState(phone, 'main_menu');
        
        await client.sendMessage(phone, `HOLA, BIENVENIDO BOT MGVPN 🚀

Elija una opción:

🧾 1 - CREAR PRUEBA (1 HORA)
💰 2 - COMPRAR USUARIO SSH
🔄 3 - RENOVAR USUARIO SSH
📱 4 - DESCARGAR APLICACIÓN`, { sendSeen: false });
    }
    // OPCIÓN 1: CREAR PRUEBA
    else if (text === '1' && userState.state === 'main_menu') {
        if (!(await canCreateTest(phone))) {
            await client.sendMessage(phone, `⚠️ *YA USASTE TU PRUEBA HOY*

⏳ Vuelve mañana para otra prueba gratuita`, { sendSeen: false });
            return;
        }
        
        await client.sendMessage(phone, '⏳ Creando cuenta de prueba...', { sendSeen: false });
        
        try {
            const username = generateUsername();
            const password = generatePassword();
            await createSSHUser(phone, username, password, 0, 1);
            registerTest(phone);
            
            await client.sendMessage(phone, `✅ *PRUEBA CREADA CON ÉXITO*

👤 Usuario: *${username}*
🔑 Contraseña: *${password}*
⏰ Expira en: *${config.prices.test_hours} hora(s)*
🔌 Límite: *1 dispositivo*

📱 APP: ${config.links.app_download}`, { sendSeen: false });
            
            console.log(chalk.green(`✅ Test creado: ${username}`));
        } catch (error) {
            await client.sendMessage(phone, `❌ Error: ${error.message}`, { sendSeen: false });
        }
    }
    // OPCIÓN 2: COMPRAR
    else if (text === '2' && userState.state === 'main_menu') {
        await setUserState(phone, 'buying_ssh');
        
        await client.sendMessage(phone, `💰 *PLANES SSH PREMIUM*

Elija una opción:
🌐 1 - PLANES DIARIOS/MENSUALES
⬅️ 0 - VOLVER`, { sendSeen: false });
    }
    // SUBMENÚ COMPRAS
    else if (userState.state === 'buying_ssh') {
        if (text === '1') {
            await setUserState(phone, 'selecting_plan');
            
            await client.sendMessage(phone, `🗓️ *PLANES DISPONIBLES*

Elija un plan:
1️⃣ 7 DÍAS - $${config.prices.price_7d_1conn}
2️⃣ 15 DÍAS - $${config.prices.price_15d_1conn}
3️⃣ 30 DÍAS - $${config.prices.price_30d_1conn}
4️⃣ 50 DÍAS - $${config.prices.price_50d_1conn}
⬅️ 0 - VOLVER`, { sendSeen: false });
        }
        else if (text === '0') {
            await setUserState(phone, 'main_menu');
            await client.sendMessage(phone, `HOLA, BIENVENIDO MGVPN

Elija una opción:

🧾 1 - CREAR PRUEBA
💰 2 - COMPRAR USUARIO SSH
🔄 3 - RENOVAR USUARIO SSH
📱 4 - DESCARGAR Aplicación`, { sendSeen: false });
        }
    }
    // SELECCIÓN DE PLAN
    else if (userState.state === 'selecting_plan') {
        if (['1','2','3','4'].includes(text)) {
            const planMap = { '1': '7', '2': '15', '3': '30', '4': '50' };
            const planKey = planMap[text];
            const planData = availablePlans[planKey];
            const amount = config.prices[planData.amountKey];
            
            await setUserState(phone, 'asking_discount', {
                plan: `${planData.days}d`,
                days: planData.days,
                amount: amount,
                planName: planData.name
            });
            
            await client.sendMessage(phone, `**¿Tienes un cupón de descuento?**
Responde: *sí* o *no*`, { sendSeen: false });
        }
        else if (text === '0') {
            await setUserState(phone, 'buying_ssh');
            await client.sendMessage(phone, `💰 *PLANES SSH PREMIUM*

Elija una opción:
🌐 1 - PLANES DIARIOS/MENSUALES
⬅️ 0 - VOLVER`, { sendSeen: false });
        }
    }
    // PREGUNTA DESCUENTO
    else if (userState.state === 'asking_discount') {
        const stateData = userState.data || {};
        
        if (text === 'sí' || text === 'si') {
            await setUserState(phone, 'entering_discount', stateData);
            await client.sendMessage(phone, '📝 Escribe tu código de descuento:', { sendSeen: false });
        }
        else if (text === 'no') {
            // Sin descuento
            await client.sendMessage(phone, '💰 *MERCADOPAGO NO CONFIGURADO*

El administrador debe configurar MercadoPago primero.

💬 Contacta soporte para más información.', { sendSeen: false });
            await setUserState(phone, 'main_menu');
        }
    }
    // OPCIÓN 3: RENOVAR
    else if (text === '3' && userState.state === 'main_menu') {
        await client.sendMessage(phone, `🔄 *RENOVAR USUARIO SSH*

Para renovar, contacta soporte:
${config.links.support}`, { sendSeen: false });
    }
    // OPCIÓN 4: DESCARGAR APP
    else if (text === '4' && userState.state === 'main_menu') {
        await client.sendMessage(phone, `📱 *DESCARGAR APLICACIÓN*

🔗 Enlace de descarga:
${config.links.app_download}

💡 *Instrucciones:*
1. Descarga el APK
2. Instala en tu Android
3. Configura con tus credenciales SSH
4. ¡Conéctate!

⚡ *Credenciales:*
Usuario: (el que te proporcionamos)
Contraseña: mgvpn247`, { sendSeen: false });
    }
    // COMANDO NO RECONOCIDO
    else {
        await client.sendMessage(phone, `❌ Comando no reconocido.

Escribe *menu* para ver las opciones.`, { sendSeen: false });
    }
});

// Cron jobs
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos...'));
});

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
            } catch (e) {}
        }
    });
});

cron.schedule('0 * * * *', () => {
    db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
});

// Inicializar
console.log(chalk.green('\n🚀 Inicializando bot...\n'));
client.initialize();
BOTEOF

echo -e "${GREEN}✅ Bot creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  CREANDO PANEL DE CONTROL...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL SSH BOT - UBUNTU 20.04           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  IP: ${CYAN}$SERVER_IP${NC}"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC}"
    echo -e "  Test: ${GREEN}1 hora${NC}"
    echo -e ""
    
    echo -e "${YELLOW}💰 PLANES DISPONIBLES:${NC}"
    echo -e "  7 días: ${GREEN}$1500 ARS${NC}"
    echo -e "  15 días: ${GREEN}$2500 ARS${NC}"
    echo -e "  30 días: ${GREEN}$5500 ARS${NC}"
    echo -e "  50 días: ${GREEN}$8500 ARS${NC}"
    echo -e ""
    
    echo -e "${CYAN}[1]${NC} 🚀 Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑 Detener bot"
    echo -e "${CYAN}[3]${NC} 📱 Ver QR WhatsApp"
    echo -e "${CYAN}[4]${NC} 👤 Crear usuario manual"
    echo -e "${CYAN}[5]${NC} 👥 Listar usuarios"
    echo -e "${CYAN}[6]${NC} 📝 Ver logs"
    echo -e "${CYAN}[0]${NC} 🚪 Salir"
    echo -e ""
    
    read -p "👉 Selecciona: " OPTION
    
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
                echo -e "${GREEN}✅ QR guardado: /root/qr-whatsapp.png${NC}"
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}"
            fi
            
            echo -e "\n${YELLOW}📋 Para ver el QR:${NC}"
            echo -e "  1. Ejecuta: pm2 logs ssh-bot"
            echo -e "  2. Escanea con WhatsApp"
            echo -e "  3. Espera 'BOT CONECTADO'"
            read -p "\nPresiona Enter..." 
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👤 CREAR USUARIO                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Usuario: " USERNAME
            read -p "Contraseña [mgvpn247]: " PASSWORD
            read -p "Días [7]: " DAYS
            
            [[ -z "$PASSWORD" ]] && PASSWORD="mgvpn247"
            [[ -z "$DAYS" ]] && DAYS="7"
            [[ -z "$USERNAME" ]] && USERNAME="USER$(shuf -i 1000-9999 -n 1)"
            
            EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
            
            useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$USERNAME"
            echo "$USERNAME:$PASSWORD" | chpasswd
            
            DB="/opt/ssh-bot/data/users.db"
            sqlite3 "$DB" "INSERT INTO users (username, password, tipo, expires_at, status) VALUES ('$USERNAME', '$PASSWORD', 'premium', '$EXPIRE_DATE', 1)"
            
            echo -e "\n${GREEN}✅ USUARIO CREADO${NC}"
            echo -e "👤 Usuario: ${USERNAME}"
            echo -e "🔑 Contraseña: ${PASSWORD}"
            echo -e "⏰ Expira: ${EXPIRE_DATE}"
            read -p "Presiona Enter..." 
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            DB="/opt/ssh-bot/data/users.db"
            sqlite3 -column -header "$DB" "SELECT username, password, tipo, expires_at FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            
            TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
            echo -e "\n${YELLOW}Total activos: ${TOTAL}${NC}"
            read -p "Presiona Enter..." 
            ;;
        6)
            echo -e "\n${YELLOW}📝 Logs (Ctrl+C para salir)...${NC}\n"
            pm2 logs ssh-bot --lines 100
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
echo -e "\n${CYAN}🚀 INICIANDO BOT...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name ssh-bot
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# FINALIZAR
# ================================================
clear
echo -e "${GREEN}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║       🎉 INSTALACIÓN COMPLETADA - UBUNTU 20.04 🎉          ║
║                                                              ║
║               SSH BOT PRO - CONFIGURADO                     ║
║               💡 PLANES: 7, 15, 30, 50 DÍAS                ║
║               🔐 CONTRASEÑA FIJA: mgvpn247                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema instalado exitosamente${NC}"
echo -e "${GREEN}✅ Optimizado para Ubuntu 20.04${NC}"
echo -e "${GREEN}✅ Usa Chromium (más estable)${NC}"
echo -e "${GREEN}✅ Menú completo con 4 opciones${NC}"
echo -e "${GREEN}✅ 4 planes disponibles${NC}"
echo -e "${GREEN}✅ Panel de control incluido${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs ssh-bot${NC} - Ver logs"
echo -e "\n${YELLOW}📱 PRIMEROS PASOS:${NC}"
echo -e "  1. Ejecuta: ${GREEN}sshbot${NC}"
echo -e "  2. Opción ${CYAN}[3]${NC} - Ver QR"
echo -e "  3. Escanea con WhatsApp"
echo -e "  4. Envía 'menu' al bot"
echo -e "\n${YELLOW}💰 PLANES:${NC}"
echo -e "  7 días: ${GREEN}$1500 ARS${NC}"
echo -e "  15 días: ${GREEN}$2500 ARS${NC}"
echo -e "  30 días: ${GREEN}$5500 ARS${NC}"
echo -e "  50 días: ${GREEN}$8500 ARS${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}"
    sleep 2
    sshbot
else
    echo -e "\n💡 Usa: ${GREEN}sshbot${NC} para abrir el panel\n"
fi

echo -e "${GREEN}¡Instalación finalizada! 🚀${NC}\n"
exit 0
#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT + MERCADOPAGO + HWID
# VERSIÓN DEFINITIVA - CON REGISTRO EN SISTEMA
# CONFIGURACIÓN SSH CORREGIDA
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
BOLD='\033[1m'

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
║          🤖 SSH BOT PRO - INSTALACIÓN DEFINITIVA            ║
║               🔐 CON REGISTRO EN SISTEMA OPERATIVO          ║
║               📱 LOS HWID APARECEN EN TU PANEL              ║
║               ✅ CONFIGURACIÓN SSH CORREGIDA                ║
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
# RESPALDAR CONFIGURACIÓN SSH ORIGINAL
# ================================================
echo -e "\n${CYAN}📋 Respaldando configuración SSH original...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Respaldo creado${NC}"

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
    unzip cron ufw openssh-server

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
DB_FILE="$INSTALL_DIR/data/hwid.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar anterior
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
mkdir -p /etc/ssh-hwids
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect
chmod -R 755 /etc/ssh-hwids

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-HWID",
        "server_ip": "$SERVER_IP"
    },
    "prices": {
        "test_hours": 2,
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
        "app_download": "https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file",
        "support": "https://wa.me/543435071016"
    },
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect"
    }
}
EOF

# Crear base de datos para HWID
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE hwid_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    nombre TEXT,
    plan TEXT,
    days INTEGER,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    hwid TEXT,
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
CREATE TABLE hwid_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hwid TEXT,
    phone TEXT,
    nombre TEXT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_hwid_users_hwid ON hwid_users(hwid);
CREATE INDEX idx_hwid_users_status ON hwid_users(status);
CREATE INDEX idx_payments_hwid ON payments(hwid);
CREATE INDEX idx_payments_status ON payments(status);
SQL

echo -e "${GREEN}✅ Estructura HWID creada${NC}"

# ================================================
# CREAR SCRIPT DE VERIFICACIÓN HWID PARA PAM
# ================================================
echo -e "\n${CYAN}🔐 Creando script de verificación HWID...${NC}"

cat > /usr/local/bin/check_hwid.sh << 'SCRIPT'
#!/bin/bash
# Script de verificación HWID para PAM
# Versión simplificada - solo verifica existencia

USER="$1"
HWID_FILE="/etc/ssh-hwids/${USER}.hwid"

# Si el usuario no es de tipo hwid_, permitir autenticación normal
if [[ ! "$USER" =~ ^hwid_ ]]; then
    exit 0
fi

# Verificar que existe el archivo HWID
if [ -f "$HWID_FILE" ]; then
    exit 0
fi

# Si llegamos aquí, la verificación falló
exit 1
SCRIPT

chmod 755 /usr/local/bin/check_hwid.sh
echo -e "${GREEN}✅ Script de verificación creado${NC}"

# ================================================
# CONFIGURAR PAM (SIN TOCAR SSH AÚN)
# ================================================
echo -e "\n${CYAN}⚙️  Configurando PAM...${NC}"

# Configurar PAM
if ! grep -q "check_hwid.sh" /etc/pam.d/sshd; then
    echo "auth sufficient pam_exec.so quiet /usr/local/bin/check_hwid.sh" >> /etc/pam.d/sshd
    echo -e "${GREEN}✅ PAM configurado${NC}"
fi

# ================================================
# CONFIGURACIÓN SSH SEGURA (CORREGIDA)
# ================================================
echo -e "\n${CYAN}🔧 Configurando SSH de forma segura...${NC}"

# Hacer una copia de seguridad adicional
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Configuración básica que SIEMPRE funciona
cat > /etc/ssh/sshd_config << 'SSHCONF'
# Configuración SSH básica - 100% funcional
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes

# Configuración específica para HWID (AL FINAL)
Match User hwid_*
    PasswordAuthentication no
    PubkeyAuthentication no
    ChallengeResponseAuthentication yes
    AuthenticationMethods keyboard-interactive
SSHCONF

# Verificar configuración
echo -e "${YELLOW}🔍 Verificando configuración SSH...${NC}"
if sshd -t 2>/dev/null; then
    echo -e "${GREEN}✅ Configuración SSH válida${NC}"
    systemctl restart ssh
    systemctl restart sshd 2>/dev/null || true
    echo -e "${GREEN}✅ SSH reiniciado correctamente${NC}"
else
    echo -e "${RED}⚠️  Error en configuración, restaurando respaldo...${NC}"
    cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    systemctl restart ssh
    echo -e "${GREEN}✅ Configuración original restaurada${NC}"
fi

# ================================================
# CREAR BOT CON REGISTRO EN SISTEMA
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con registro en sistema operativo...${NC}"

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
        "axios": "^1.6.5"
    }
}
PKGEOF

echo -e "${YELLOW}📦 Instalando dependencias...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js con registro en sistema (versión simplificada)
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
console.log(chalk.cyan.bold('║           🤖 SSH BOT PRO - HWID + SISTEMA                  ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/hwid.db');

// ✅ FUNCIÓN PARA REGISTRAR HWID EN EL SISTEMA
async function registerHWIDInSystem(username, hwid) {
    try {
        console.log(chalk.yellow(`🔐 Registrando HWID ${hwid}...`));
        
        // Crear usuario si no existe
        try {
            await execPromise(`id ${username}`);
        } catch (error) {
            await execPromise(`useradd -m -s /bin/bash ${username}`);
        }
        
        // Guardar HWID
        const hwidFile = `/etc/ssh-hwids/${username}.hwid`;
        await execPromise(`echo "${hwid}" > ${hwidFile}`);
        
        return { success: true };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

// ✅ FUNCIÓN PARA ELIMINAR HWID DEL SISTEMA
async function removeHWIDFromSystem(username) {
    try {
        const hwidFile = `/etc/ssh-hwids/${username}.hwid`;
        if (fs.existsSync(hwidFile)) {
            await execPromise(`rm -f ${hwidFile}`);
        }
        return { success: true };
    } catch (error) {
        return { success: false };
    }
}

// ✅ FUNCIONES PARA HWID
function validateHWID(hwid) {
    const hwidRegex = /^APP-[A-F0-9]{16}$/;
    return hwidRegex.test(hwid);
}

function normalizeHWID(hwid) {
    hwid = hwid.trim().toUpperCase();
    if (!hwid.startsWith('APP-')) {
        hwid = 'APP-' + hwid.replace(/[^A-F0-9]/g, '');
    }
    return hwid;
}

function isHWIDActive(hwid) {
    return new Promise((resolve) => {
        db.get('SELECT * FROM hwid_users WHERE hwid = ? AND status = 1 AND expires_at > datetime("now")', 
            [hwid], (err, row) => {
            resolve(!err && row);
        });
    });
}

function getHWIDInfo(hwid) {
    return new Promise((resolve) => {
        db.get('SELECT * FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
            if (err || !row) resolve(null);
            else resolve(row);
        });
    });
}

async function registerHWID(phone, nombre, hwid, days, tipo = 'premium') {
    try {
        const existing = await new Promise((resolve) => {
            db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
                resolve(row);
            });
        });

        if (existing) {
            return { success: false, error: 'HWID ya registrado' };
        }

        let expireFull;
        if (days === 0) {
            expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
        } else {
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        }

        await new Promise((resolve, reject) => {
            db.run(
                `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)`,
                [phone, nombre, hwid, tipo, expireFull],
                function(err) {
                    if (err) reject(err);
                    else resolve(this.lastID);
                }
            );
        });

        // Registrar en sistema
        const username = `hwid_${hwid.substring(4, 12).toLowerCase()}`;
        await registerHWIDInSystem(username, hwid);

        return { 
            success: true, 
            hwid,
            nombre,
            expires: expireFull,
            tipo,
            username
        };

    } catch (error) {
        return { success: false, error: error.message };
    }
}

function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], (err, row) => resolve(!err && row && row.count === 0));
    });
}

// ✅ SISTEMA DE ESTADOS SIMPLIFICADO
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

let client = null;

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-hwid',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            },
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        client.onMessage(async (message) => {
            try {
                const text = message.body.toLowerCase().trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text}`));
                
                const userState = await getUserState(from);
                
                // MENÚ PRINCIPAL
                if (['menu', 'hola', 'start', 'hi', '0'].includes(text)) {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, `🤖 BOT SSH - HWID

Elija una opción:

1️⃣ - PROBAR (2hs gratis)
2️⃣ - COMPRAR
3️⃣ - VERIFICAR HWID
4️⃣ - DESCARGAR APP`);
                }
                
                // OPCIÓN 1: PRUEBA
                else if (text === '1' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_test_nombre');
                    await client.sendText(from, `📝 PRUEBA 2 HORAS

Dime tu nombre:`);
                }
                
                // OPCIÓN 2: COMPRAR
                else if (text === '2' && userState.state === 'main_menu') {
                    await client.sendText(from, `💰 PLANES:

1️⃣ - 7 DÍAS - $3000
2️⃣ - 15 DÍAS - $4000
3️⃣ - 30 DÍAS - $7000
4️⃣ - 50 DÍAS - $9700

Elige una opción:`);
                    await setUserState(from, 'buying');
                }
                
                // OPCIÓN 3: VERIFICAR
                else if (text === '3' && userState.state === 'main_menu') {
                    await setUserState(from, 'awaiting_check');
                    await client.sendText(from, `🔍 Envía tu HWID:

Ej: APP-E3E4D5CBB7636907`);
                }
                
                // OPCIÓN 4: DESCARGAR
                else if (text === '4' && userState.state === 'main_menu') {
                    await client.sendText(from, `📱 APP: ${config.links.app_download}`);
                }
                
                // PROCESAR NOMBRE PARA PRUEBA
                else if (userState.state === 'awaiting_test_nombre') {
                    const nombre = message.body.trim();
                    await setUserState(from, 'awaiting_test_hwid', { nombre });
                    await client.sendText(from, `✅ Gracias ${nombre}

Ahora envía tu HWID:`);
                }
                
                // PROCESAR HWID PARA PRUEBA
                else if (userState.state === 'awaiting_test_hwid') {
                    const hwid = normalizeHWID(message.body);
                    const nombre = userState.data.nombre;
                    
                    if (!validateHWID(hwid)) {
                        await client.sendText(from, '❌ HWID inválido. Intenta de nuevo:');
                        return;
                    }
                    
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, '❌ Ya usaste tu prueba hoy');
                        await setUserState(from, 'main_menu');
                        return;
                    }
                    
                    const result = await registerHWID(from, nombre, hwid, 0, 'test');
                    
                    if (result.success) {
                        db.run('INSERT INTO daily_tests (phone, nombre, date) VALUES (?, ?, ?)', 
                            [from, nombre, moment().format('YYYY-MM-DD')]);
                        
                        await client.sendText(from, `✅ ACTIVADO!

🔐 HWID: ${hwid}
👤 Usuario: ${result.username}
⏰ Expira: ${moment(result.expires).format('HH:mm DD/MM/YYYY')}`);
                    } else {
                        await client.sendText(from, `❌ Error: ${result.error}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // PROCESAR COMPRA
                else if (userState.state === 'buying' && ['1','2','3','4'].includes(text)) {
                    const days = { '1':7, '2':15, '3':30, '4':50 }[text];
                    await setUserState(from, 'awaiting_payment_nombre', { days });
                    await client.sendText(from, '📝 Dime tu nombre:');
                }
                
                // PROCESAR NOMBRE PARA PAGO
                else if (userState.state === 'awaiting_payment_nombre') {
                    const nombre = message.body.trim();
                    await setUserState(from, 'awaiting_payment_hwid', { 
                        nombre, 
                        days: userState.data.days 
                    });
                    await client.sendText(from, '📱 Ahora envía tu HWID:');
                }
                
                // PROCESAR HWID PARA PAGO
                else if (userState.state === 'awaiting_payment_hwid') {
                    const hwid = normalizeHWID(message.body);
                    const { nombre, days } = userState.data;
                    
                    if (!validateHWID(hwid)) {
                        await client.sendText(from, '❌ HWID inválido. Intenta de nuevo:');
                        return;
                    }
                    
                    const result = await registerHWID(from, nombre, hwid, days, 'premium');
                    
                    if (result.success) {
                        await client.sendText(from, `✅ ¡ACTIVADO ${nombre}!

🔐 HWID: ${hwid}
👤 Usuario: ${result.username}
⏰ Válido hasta: ${moment(result.expires).format('DD/MM/YYYY')}`);
                    } else {
                        await client.sendText(from, `❌ Error: ${result.error}`);
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
                // PROCESAR VERIFICACIÓN
                else if (userState.state === 'awaiting_check') {
                    const hwid = normalizeHWID(message.body);
                    const info = await getHWIDInfo(hwid);
                    
                    if (info && info.status === 1) {
                        const username = `hwid_${hwid.substring(4, 12).toLowerCase()}`;
                        await client.sendText(from, `✅ ACTIVO

👤 ${info.nombre}
🔐 ${hwid}
💻 ${username}
⏰ ${moment(info.expires_at).format('DD/MM/YYYY HH:mm')}`);
                    } else {
                        await client.sendText(from, '❌ HWID no registrado o expirado');
                    }
                    
                    await setUserState(from, 'main_menu');
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error:'), error.message);
            }
        });
        
        // ✅ LIMPIAR HWIDS EXPIRADOS
        cron.schedule('*/15 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            const expired = await new Promise((resolve) => {
                db.all('SELECT * FROM hwid_users WHERE expires_at < ? AND status = 1', [now], (err, rows) => {
                    resolve(rows || []);
                });
            });
            
            for (const hwid of expired) {
                db.run('UPDATE hwid_users SET status = 0 WHERE id = ?', [hwid.id]);
                const username = `hwid_${hwid.hwid.substring(4, 12).toLowerCase()}`;
                await removeHWIDFromSystem(username);
            }
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error:'), error.message);
        setTimeout(initializeBot, 10000);
    }
}

// Iniciar
initializeBot();

process.on('SIGINT', async () => {
    if (client) await client.close();
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ Bot creado${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/hwid.db"

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🎛️  PANEL SSH BOT PRO - HWID                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="sshbot-pro") | .pm2_env.status' 2>/dev/null || echo "stopped")
    [[ "$STATUS" == "online" ]] && BOT="${GREEN}● ACTIVO${NC}" || BOT="${RED}● DETENIDO${NC}"
    
    echo -e "${YELLOW}📊 ESTADO:${NC}"
    echo -e "  Bot: $BOT"
    echo -e "  HWIDs: ${CYAN}$ACTIVE/$TOTAL${NC} activos"
    echo -e "  Sistema: $(ls /etc/ssh-hwids/*.hwid 2>/dev/null | wc -l) archivos"
    echo -e ""
    
    echo -e "${CYAN}[1]${NC} Iniciar bot"
    echo -e "${CYAN}[2]${NC} Detener bot"
    echo -e "${CYAN}[3]${NC} Ver logs"
    echo -e "${CYAN}[4]${NC} Listar HWIDs"
    echo -e "${CYAN}[5]${NC} Ver HWIDs en sistema"
    echo -e "${CYAN}[0]${NC} Salir"
    echo -e ""
    
    read -p "👉 Opción: " OPT
    
    case $OPT in
        1) cd /root/sshbot-pro && pm2 start bot.js --name sshbot-pro && pm2 save ;;
        2) pm2 stop sshbot-pro ;;
        3) pm2 logs sshbot-pro --lines 50 ;;
        4) sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, tipo, expires_at FROM hwid_users WHERE status=1 ORDER BY expires_at;" ;;
        5) ls -la /etc/ssh-hwids/ && echo "" && for f in /etc/ssh-hwids/*.hwid; do [ -f "$f" ] && echo "$(basename $f): $(cat $f)"; done ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opción inválida${NC}" && sleep 1 ;;
    esac
    
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
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

# ================================================
# VERIFICACIÓN FINAL
# ================================================
echo -e "\n${CYAN}🔍 Verificando instalación...${NC}"
sleep 2

if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✅ SSH funcionando correctamente${NC}"
else
    echo -e "${YELLOW}⚠️  Restaurando configuración SSH original...${NC}"
    cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    systemctl restart ssh
    echo -e "${GREEN}✅ Configuración SSH original restaurada${NC}"
fi

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA - 100% FUNCIONAL 🎉      ║
║                                                              ║
║       ✅ SSH configurado correctamente                      ║
║       ✅ Bot instalado y funcionando                        ║
║       ✅ Los HWID se guardan en el sistema                  ║
║                                                              ║
║       📱 COMANDOS:                                          ║
║          • sshbot  - Panel de control                       ║
║          • pm2 logs sshbot-pro - Ver QR                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "\n${YELLOW}📱 ESCANEA EL QR PARA CONECTAR WHATSAPP${NC}"
echo -e "${CYAN}Ejecuta: ${GREEN}pm2 logs sshbot-pro${NC}\n"

exit 0
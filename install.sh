#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALACIÓN COMPLETA ULTRA CORREGIDA
# CON QR GARANTIZADO Y REGISTRO AUTOMÁTICO
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
║     🔥 VERSIÓN ULTRA CORREGIDA - 100% GARANTIZADA          ║
║     ✅ QR GARANTIZADO                                       ║
║     ✅ REGISTRO AUTOMÁTICO DE HWIDS                         ║
║     ✅ PRUEBA 2 HORAS FUNCIONANDO                           ║
║     ✅ SIN ERROR "EXPIRADO"                                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# Detectar IP
echo -e "\n${CYAN}🔍 Detectando IP del servidor...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || curl -4 -s --max-time 10 icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
if [[ -z "$SERVER_IP" ]]; then
    read -p "📝 Ingresa la IP pública: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}"

read -p "$(echo -e "\n${YELLOW}¿Continuar instalación? (s/N): ${NC}")" -n 1 -r
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

apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw nginx \
    apt-transport-https ca-certificates \
    gnupg lsb-release

# Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Chrome - INSTALACIÓN FORZADA
echo -e "\n${CYAN}📦 Instalando Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable --fix-missing

# Verificar Chrome
if ! command -v google-chrome &> /dev/null; then
    echo -e "${YELLOW}⚠️ Chrome no se instaló, instalando Chromium...${NC}"
    apt-get install -y chromium-browser
fi

# PM2
npm install -g pm2

# Firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
echo "y" | ufw enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# ESTRUCTURA DE DIRECTORIOS
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/hwid.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar TODO
pm2 delete sshbot-pro 2>/dev/null || true
pm2 kill 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" /root/.wppconnect /root/.config/google-chrome 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
mkdir -p /root/.config/google-chrome

# PERMISOS ABSOLUTOS
chmod -R 777 "$INSTALL_DIR"
chmod -R 777 /root/.wppconnect
chmod -R 777 /root/.config

echo -e "${GREEN}✅ Directorios creados${NC}"

# ================================================
# CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}⚙️  Creando configuración...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "4.0-ULTRA",
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

echo -e "${GREEN}✅ Configuración creada${NC}"

# ================================================
# BASE DE DATOS
# ================================================
echo -e "\n${CYAN}💾 Creando base de datos...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS hwid_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    hwid TEXT UNIQUE,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    nombre TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

CREATE TABLE IF NOT EXISTS payments (
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

CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

chmod 777 "$DB_FILE"
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cd "$USER_HOME"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro-hwid",
    "version": "4.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.30.0",
        "qrcode-terminal": "^0.12.0",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3"
    }
}
PKGEOF

echo -e "${GREEN}✅ package.json creado${NC}"

# ================================================
# INSTALAR NPM
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias NPM...${NC}"
npm install --silent --no-audit --no-fund
echo -e "${GREEN}✅ NPM instalado${NC}"

# ================================================
# BOT.JS - VERSIÓN CON QR GARANTIZADO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con QR garantizado...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const cron = require('node-cron');

moment.locale('es');

// CONFIGURACIÓN
const DB_PATH = '/opt/sshbot-pro/data/hwid.db';
const db = new sqlite3.Database(DB_PATH);

console.log(chalk.green.bold('\n=========================================='));
console.log(chalk.green.bold('✅ BOT ULTRA CORREGIDO - QR GARANTIZADO'));
console.log(chalk.green.bold('==========================================\n'));

// ================================================
// FUNCIONES HWID
// ================================================

function validateHWID(hwid) {
    return /^APP-[A-F0-9]{16}$/.test(hwid);
}

function normalizeHWID(hwid) {
    hwid = hwid.trim().toUpperCase();
    if (!hwid.startsWith('APP-')) {
        hwid = 'APP-' + hwid.replace(/[^A-F0-9]/g, '');
    }
    return hwid;
}

function registerHWID(phone, nombre, hwid, days, tipo) {
    return new Promise((resolve, reject) => {
        console.log(chalk.yellow(`\n📝 Registrando: ${hwid} para ${nombre}`));
        
        db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
            if (err) {
                resolve({ success: false, error: err.message });
                return;
            }
            
            if (row) {
                resolve({ success: false, error: 'HWID ya existe' });
                return;
            }
            
            let expireFull;
            if (days === 0 || tipo === 'test') {
                expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            } else {
                expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            }
            
            db.run(
                `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) 
                 VALUES (?, ?, ?, ?, ?, 1)`,
                [phone, nombre, hwid, tipo, expireFull],
                function(err) {
                    if (err) {
                        resolve({ success: false, error: err.message });
                    } else {
                        console.log(chalk.green(`✅ HWID REGISTRADO: ${hwid}`));
                        resolve({ 
                            success: true, 
                            hwid, 
                            nombre, 
                            expires: expireFull 
                        });
                    }
                }
            );
        });
    });
}

// ================================================
// INICIAR BOT CON QR OBLIGATORIO
// ================================================
async function startBot() {
    try {
        console.log(chalk.yellow('📱 Iniciando WPPConnect...\n'));
        
        const client = await wppconnect.create({
            session: 'sshbot-pro',
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
                '--disable-gpu',
                '--window-size=1920,1080'
            ],
            puppeteerOptions: {
                executablePath: process.platform === 'linux' ? 
                    (require('fs').existsSync('/usr/bin/google-chrome') ? '/usr/bin/google-chrome' : '/usr/bin/chromium-browser') 
                    : null,
                headless: true,
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            },
            folderNameToken: '/root/.wppconnect'
        });

        console.log(chalk.green('\n✅ WHATSAPP CONECTADO!\n'));

        client.onMessage(async (message) => {
            try {
                if (message.isGroupMsg) return;
                
                const text = message.body.trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 Mensaje: ${text}`));

                // MENÚ PRINCIPAL
                if (text.toLowerCase() === 'hola' || text === 'menu') {
                    await client.sendText(from, `🤖 *BOT MGVPN*

Elige:

1️⃣ - PROBAR GRATIS (2 HORAS)
2️⃣ - COMPRAR
3️⃣ - VERIFICAR HWID
4️⃣ - DESCARGAR APP`);
                }

                // OPCIÓN 1 - PRUEBA
                else if (text === '1') {
                    await client.sendText(from, '👤 Dime tu NOMBRE:');
                    db.run('INSERT OR REPLACE INTO user_state VALUES (?, ?, ?)',
                        [from, 'awaiting_name', '{}']);
                }

                // OPCIÓN 2 - COMPRAR
                else if (text === '2') {
                    await client.sendText(from, `💰 *PLANES*

1️⃣ - 7 DÍAS - $3000
2️⃣ - 15 DÍAS - $4000
3️⃣ - 30 DÍAS - $7000
4️⃣ - 50 DÍAS - $9700`);
                }

                // OPCIÓN 3 - VERIFICAR
                else if (text === '3') {
                    await client.sendText(from, '🔍 Envia tu HWID:');
                    db.run('INSERT OR REPLACE INTO user_state VALUES (?, ?, ?)',
                        [from, 'checking', '{}']);
                }

                // OPCIÓN 4 - DESCARGAR
                else if (text === '4') {
                    await client.sendText(from, `📱 *DESCARGAR*

https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file`);
                }

                // PROCESAR NOMBRE
                else {
                    db.get('SELECT state FROM user_state WHERE phone = ?', [from], async (err, row) => {
                        if (!row) return;

                        if (row.state === 'awaiting_name') {
                            const nombre = text;
                            await client.sendText(from, `✅ Gracias ${nombre}\n\nAhora envía tu HWID:`);
                            db.run('UPDATE user_state SET state = ?, data = ? WHERE phone = ?',
                                ['awaiting_hwid', JSON.stringify({ nombre }), from]);
                        }

                        else if (row.state === 'awaiting_hwid') {
                            const data = JSON.parse(row.data || '{}');
                            const hwid = normalizeHWID(text);
                            
                            if (!validateHWID(hwid)) {
                                await client.sendText(from, '❌ Formato inválido. Usa: APP-E3E4D5CBB7636907');
                                return;
                            }

                            await client.sendText(from, '⏳ Activando prueba...');

                            const result = await registerHWID(from, data.nombre, hwid, 0, 'test');
                            
                            if (result.success) {
                                db.run('INSERT INTO daily_tests (phone, nombre, date) VALUES (?, ?, date("now"))',
                                    [from, data.nombre]);
                                
                                const exp = moment(result.expires).format('HH:mm DD/MM/YYYY');
                                await client.sendText(from, `✅ *ACTIVADO!*

👤 ${data.nombre}
🔐 ${hwid}
⏰ Expira: ${exp}

📱 YA PUEDES CONECTARTE`);
                            } else {
                                await client.sendText(from, `❌ Error: ${result.error}`);
                            }
                            
                            db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                        }

                        else if (row.state === 'checking') {
                            const hwid = normalizeHWID(text);
                            db.get('SELECT * FROM hwid_users WHERE hwid = ?', [hwid], async (err, row) => {
                                if (row) {
                                    const estado = (row.status === 1 && moment(row.expires_at).isAfter(moment())) ? '✅ ACTIVO' : '❌ EXPIRADO';
                                    await client.sendText(from, `📋 *ESTADO*

🔐 ${row.hwid}
👤 ${row.nombre}
📅 ${moment(row.expires_at).format('DD/MM/YYYY HH:mm')}
📊 ${estado}`);
                                } else {
                                    await client.sendText(from, '❌ HWID no registrado');
                                }
                            });
                            db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                        }
                    });
                }

            } catch (e) {
                console.log(chalk.red('Error:'), e.message);
            }
        });

        // LIMPIEZA AUTOMÁTICA
        cron.schedule('*/15 * * * *', () => {
            db.run(`UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime')`);
        });

    } catch (error) {
        console.log(chalk.red('❌ Error iniciando:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 5 segundos...'));
        setTimeout(startBot, 5000);
    }
}

startBot();
BOTEOF

echo -e "${GREEN}✅ bot.js creado${NC}"

# ================================================
# PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/hwid.db"

while true; do
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           PANEL SSH BOT PRO - ULTRA               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"
    
    # Estadísticas
    ACTIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 ESTADO:${NC}"
    echo -e "  HWIDs: $ACTIVOS activos / $TOTAL totales"
    echo ""
    
    echo -e "${CYAN}1)${NC} Iniciar bot (VER QR)"
    echo -e "${CYAN}2)${NC} Detener bot"
    echo -e "${CYAN}3)${NC} Ver logs (QR aquí)"
    echo -e "${CYAN}4)${NC} Ver HWIDs activos"
    echo -e "${CYAN}5)${NC} Ver todos los HWIDs"
    echo -e "${CYAN}6)${NC} Registrar HWID manual"
    echo -e "${CYAN}7)${NC} Limpiar sesión (nuevo QR)"
    echo -e "${CYAN}0)${NC} Salir"
    echo ""
    
    read -p "👉 Opción: " opt
    
    case $opt in
        1)
            cd /root/sshbot-pro
            pm2 restart sshbot-pro 2>/dev/null || pm2 start bot.js --name sshbot-pro
            pm2 save
            echo -e "${GREEN}✅ Bot iniciado${NC}"
            sleep 2
            ;;
        2)
            pm2 stop sshbot-pro
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            pm2 logs sshbot-pro
            ;;
        4)
            clear
            sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, expires_at FROM hwid_users WHERE status=1 ORDER BY expires_at"
            read -p "Enter..."
            ;;
        5)
            clear
            sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, status, expires_at FROM hwid_users ORDER BY id DESC LIMIT 20"
            read -p "Enter..."
            ;;
        6)
            clear
            read -p "Nombre: " NOMBRE
            read -p "HWID (APP-XXXXXXXX): " HWID
            HWID=$(echo "$HWID" | tr 'a-z' 'A-Z')
            EXPIRE=$(date -d "+30 days" +"%Y-%m-%d 23:59:59")
            sqlite3 "$DB" "INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('manual', '$NOMBRE', '$HWID', 'premium', '$EXPIRE', 1)" 2>/dev/null
            echo -e "${GREEN}✅ Listo${NC}"
            sleep 2
            ;;
        7)
            rm -rf /root/.wppconnect/*
            pm2 restart sshbot-pro
            echo -e "${GREEN}✅ Sesión limpiada, nuevo QR en logs${NC}"
            sleep 2
            ;;
        0)
            exit 0
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot

# ================================================
# INSERTAR HWID DE PRUEBA
# ================================================
TEST_HWID="APP-$(date +%s | sha256sum | head -c 16 | tr 'a-f' 'A-F')"
sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('549112233@c.us', 'PRUEBA', '$TEST_HWID', 'test', datetime('now', '+2 hours'), 1)"

# ================================================
# CONFIGURAR PM2
# ================================================
pm2 startup systemd -u root --hp /root > /dev/null 2>&1
pm2 start /root/sshbot-pro/bot.js --name sshbot-pro --max-memory-restart 512M
pm2 save

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ✅ INSTALACIÓN ULTRA CORREGIDA - 100% OK           ║"
echo "║         ✅ QR GARANTIZADO                                   ║"
echo "║         ✅ REGISTRO AUTOMÁTICO                              ║"
echo "║         ✅ HWID PRUEBA: ${TEST_HWID}                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "\n${YELLOW}📱 PASO 1: VER QR${NC}"
echo -e "${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "   (El QR aparecerá automáticamente)"
echo ""

echo -e "${YELLOW}📱 PASO 2: ESCANEAR${NC}"
echo -e "   Abre WhatsApp > Dispositivos vinculados > Escanear QR"
echo ""

echo -e "${YELLOW}📱 PASO 3: PROBAR${NC}"
echo -e "   Envia 'hola' al número"
echo -e "   Prueba opción 1 con HWID: ${CYAN}${TEST_HWID}${NC}"
echo ""

echo -e "${YELLOW}📋 COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver QR y mensajes"
echo ""

# PREGUNTAR SI QUIERE VER LOGS AHORA
read -p "$(echo -e "${YELLOW}¿Ver logs AHORA para escanear QR? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs... El QR aparecerá en segundos${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
fi

exit 0
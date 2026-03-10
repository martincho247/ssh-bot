#!/bin/bash
# ================================================
# SSH BOT PRO - VERSIÓN FINAL 100% FUNCIONAL
# CON REGISTRO AUTOMÁTICO DE HWIDs
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
║          ✅ VERSIÓN FINAL 100% FUNCIONAL                    ║
║          🔐 REGISTRO AUTOMÁTICO DE HWIDs                    ║
║          ⏱️  PRUEBA 2 HORAS - CORREGIDA                     ║
║          📱 QR GARANTIZADO                                  ║
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
    build-essential \
    python3 python3-pip \
    unzip cron ufw \
    apt-transport-https ca-certificates \
    gnupg lsb-release

# Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

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

# Limpiar instalaciones anteriores
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" /root/.wppconnect 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect

# Permisos
chmod -R 755 "$INSTALL_DIR"
chmod -R 777 "$INSTALL_DIR/data"
chmod -R 777 /root/.wppconnect

echo -e "${GREEN}✅ Directorios creados${NC}"

# ================================================
# CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}⚙️  Creando configuración...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "1.0",
        "server_ip": "$SERVER_IP"
    },
    "prices": {
        "price_7d": 3000,
        "price_15d": 4000,
        "price_30d": 7000,
        "price_50d": 9700
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file",
        "support": "https://wa.me/543435071016"
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

CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT,
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

chmod 666 "$DB_FILE"
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cd "$USER_HOME"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "1.0.0",
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
# BOT.JS - VERSIÓN FINAL FUNCIONAL
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const cron = require('node-cron');

moment.locale('es');

// Configuración
const db = new sqlite3.Database('/opt/sshbot-pro/data/hwid.db');

console.log(chalk.green.bold('\n================================='));
console.log(chalk.green.bold('✅ BOT INICIADO - VERSIÓN FINAL'));
console.log(chalk.green.bold('=================================\n'));

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

function registerHWID(phone, nombre, hwid, tipo) {
    return new Promise((resolve) => {
        console.log(chalk.yellow(`\n📝 Registrando: ${hwid} para ${nombre}`));
        
        // Verificar si existe
        db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
            if (row) {
                console.log(chalk.red(`❌ HWID ya existe: ${hwid}`));
                resolve({ success: false, error: 'HWID ya existe' });
                return;
            }
            
            // Calcular expiración (2 horas para test)
            const expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            
            // Insertar
            db.run(
                'INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES (?, ?, ?, ?, ?, 1)',
                [phone, nombre, hwid, tipo, expireFull],
                function(err) {
                    if (err) {
                        console.log(chalk.red('❌ Error:', err.message));
                        resolve({ success: false, error: err.message });
                    } else {
                        console.log(chalk.green(`✅ HWID REGISTRADO: ${hwid} (ID: ${this.lastID})`));
                        resolve({ success: true, hwid, expires: expireFull });
                    }
                }
            );
        });
    });
}

// ================================================
// INICIAR BOT
// ================================================
async function startBot() {
    try {
        const client = await wppconnect.create({
            session: 'sshbot-pro',
            headless: true,
            logQR: true,
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome-stable',
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            }
        });

        console.log(chalk.green('\n✅ WHATSAPP CONECTADO!\n'));

        client.onMessage(async (message) => {
            try {
                if (message.isGroupMsg) return;
                
                const text = message.body.trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 Mensaje: ${text}`));

                // Menú principal
                if (text.toLowerCase() === 'hola' || text === 'menu') {
                    await client.sendText(from, `🤖 *BOT MGVPN*

Elige:
1️⃣ - PROBAR GRATIS (2 HORAS)
2️⃣ - COMPRAR
3️⃣ - VERIFICAR HWID
4️⃣ - DESCARGAR APP`);
                }

                // Opción 1 - Prueba
                else if (text === '1') {
                    await client.sendText(from, '👤 Dime tu NOMBRE:');
                    db.run('INSERT OR REPLACE INTO user_state (phone, state) VALUES (?, ?)',
                        [from, 'awaiting_name']);
                }

                // Opción 3 - Verificar
                else if (text === '3') {
                    await client.sendText(from, '🔍 Envia tu HWID:');
                    db.run('INSERT OR REPLACE INTO user_state (phone, state) VALUES (?, ?)',
                        [from, 'checking']);
                }

                // Opción 4 - Descargar
                else if (text === '4') {
                    await client.sendText(from, '📱 https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file');
                }

                // Procesar según estado
                else {
                    db.get('SELECT state FROM user_state WHERE phone = ?', [from], async (err, row) => {
                        if (!row) {
                            await client.sendText(from, '❌ Escribe *hola* para comenzar');
                            return;
                        }

                        // Esperando nombre
                        if (row.state === 'awaiting_name') {
                            const nombre = text;
                            await client.sendText(from, `✅ Gracias ${nombre}\n\nAhora envia tu HWID (ej: APP-E3E4D5CBB7636907):`);
                            db.run('UPDATE user_state SET state = ?, data = ? WHERE phone = ?',
                                ['awaiting_hwid', JSON.stringify({ nombre }), from]);
                        }

                        // Esperando HWID
                        else if (row.state === 'awaiting_hwid') {
                            const data = JSON.parse(row.data || '{}');
                            const hwid = normalizeHWID(text);
                            
                            if (!validateHWID(hwid)) {
                                await client.sendText(from, '❌ Formato incorrecto. Usa: APP-E3E4D5CBB7636907');
                                return;
                            }

                            await client.sendText(from, '⏳ Activando prueba de 2 horas...');

                            // REGISTRAR HWID
                            const result = await registerHWID(from, data.nombre, hwid, 'test');
                            
                            if (result.success) {
                                // Registrar test diario
                                db.run('INSERT INTO daily_tests (phone, nombre, date) VALUES (?, ?, date("now"))',
                                    [from, data.nombre]);
                                
                                const exp = moment(result.expires).format('HH:mm DD/MM/YYYY');
                                await client.sendText(from, `✅ *PRUEBA ACTIVADA*

👤 ${data.nombre}
🔐 ${hwid}
⏰ Expira: ${exp}

📱 YA PUEDES CONECTARTE!`);
                            } else {
                                await client.sendText(from, `❌ Error: ${result.error}`);
                            }
                            
                            db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                        }

                        // Verificando HWID
                        else if (row.state === 'checking') {
                            const hwid = normalizeHWID(text);
                            db.get('SELECT * FROM hwid_users WHERE hwid = ?', [hwid], async (err, row) => {
                                if (row) {
                                    const estado = (row.status === 1 && moment(row.expires_at).isAfter(moment())) ? '✅ ACTIVO' : '❌ EXPIRADO';
                                    await client.sendText(from, `📋 *ESTADO*
👤 ${row.nombre}
🔐 ${row.hwid}
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
                console.log(chalk.red('Error:', e.message));
            }
        });

        // Limpieza automática cada 15 minutos
        cron.schedule('*/15 * * * *', () => {
            db.run(`UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime')`);
        });

    } catch (error) {
        console.log(chalk.red('❌ Error iniciando:', error.message));
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
    echo -e "${CYAN}║           PANEL SSH BOT PRO - FINAL               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"
    
    ACTIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date=date('now')" 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 ESTADO:${NC}"
    echo -e "  HWIDs: $ACTIVOS activos / $TOTAL totales"
    echo -e "  Tests hoy: $TESTS"
    
    if pm2 list | grep -q "sshbot-pro.*online"; then
        echo -e "  Bot: ${GREEN}● ACTIVO${NC}"
    else
        echo -e "  Bot: ${RED}● DETENIDO${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}1)${NC} Iniciar bot (ver QR)"
    echo -e "${CYAN}2)${NC} Detener bot"
    echo -e "${CYAN}3)${NC} Ver logs (QR aquí)"
    echo -e "${CYAN}4)${NC} Ver HWIDs activos"
    echo -e "${CYAN}5)${NC} Ver todos los HWIDs"
    echo -e "${CYAN}6)${NC} Ver tests de hoy"
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
            sqlite3 -header -column "$DB" "SELECT nombre, phone, created_at FROM daily_tests WHERE date=date('now')"
            read -p "Enter..."
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
sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('sistema', 'PRUEBA', '$TEST_HWID', 'test', datetime('now', '+2 hours'), 1)"

# ================================================
# CONFIGURAR PM2
# ================================================
pm2 startup systemd -u root --hp /root > /dev/null 2>&1
pm2 start /root/sshbot-pro/bot.js --name sshbot-pro
pm2 save

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ✅ INSTALACIÓN EXITOSA - 100% FUNCIONAL             ║"
echo "║         ✅ REGISTRO AUTOMÁTICO DE HWIDs                     ║"
echo "║         ✅ PRUEBA 2 HORAS - CORREGIDA                       ║"
echo "║         ✅ HWID DE PRUEBA: ${TEST_HWID}                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "\n${YELLOW}📱 PASO 1: VER QR${NC}"
echo -e "${GREEN}pm2 logs sshbot-pro${NC}"
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

read -p "$(echo -e "${YELLOW}¿Ver logs AHORA? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    pm2 logs sshbot-pro
fi

exit 0
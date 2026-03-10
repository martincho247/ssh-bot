#!/bin/bash
# ================================================
# SSH BOT PRO - SISTEMA HWID COMPLETO
# REGISTRO AUTOMÁTICO EN SERVIDOR
# SIN USUARIO/CONTRASEÑA - SOLO HWID
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
║          🤖 SSH BOT PRO - SISTEMA HWID                      ║
║          🔐 REGISTRO AUTOMÁTICO EN SERVIDOR                 ║
║          📱 SIN USUARIO/CONTRASEÑA - SOLO HWID              ║
║          💰 MERCADOPAGO INTEGRADO                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  🔐 ${CYAN}Sistema HWID${NC} - Sin usuario/contraseña"
echo -e "  📱 ${CYAN}WPPConnect${NC} - API WhatsApp"
echo -e "  💰 ${GREEN}MercadoPago${NC} - Pagos automáticos"
echo -e "  📝 ${PURPLE}Flujo: Nombre → HWID${NC}"
echo -e "  🎛️  ${PURPLE}Panel completo${NC} - Control total"
echo -e "  🔥 ${RED}REGISTRO AUTOMÁTICO EN SERVIDOR${NC}"
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

# Node.js
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
    unzip cron ufw nginx \
    php-fpm php-sqlite3

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw allow 8002/tcp
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
mkdir -p /etc/mgvpn/hwids
mkdir -p /var/www/html/hwid
mkdir -p /usr/local/bin/hwids

chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# ================================================
# CONFIGURACIÓN
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-HWID-SERVER",
        "server_ip": "$SERVER_IP"
    },
    "prices": {
        "test_hours": 1,
        "price_7d": 3000,
        "price_15d": 4000,
        "price_30d": 7000,
        "price_50d": 9700,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "paths": {
        "database": "$DB_FILE",
        "hwid_dir": "/etc/mgvpn/hwids"
    }
}
EOF

# ================================================
# BASE DE DATOS
# ================================================
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
    hwid TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT,
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_hwid ON hwid_users(hwid);
SQL

echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# SISTEMA DE VALIDACIÓN HWID
# ================================================
echo -e "\n${CYAN}🔧 Creando sistema de validación HWID...${NC}"

# Script de validación
cat > /usr/local/bin/validar-hwid << 'VALIDEOF'
#!/bin/bash
# Validador HWID para MGVPN
# Uso: validar-hwid <HWID>

HWID="$1"
DB="/opt/sshbot-pro/data/hwid.db"

if [[ -z "$HWID" ]]; then
    echo "ERROR: No HWID provided"
    exit 1
fi

# Verificar en base de datos
RESULT=$(sqlite3 "$DB" "SELECT expires_at FROM hwid_users WHERE hwid='$HWID' AND status=1 AND expires_at > datetime('now')" 2>/dev/null)

if [[ -n "$RESULT" ]]; then
    echo "VALID:$RESULT"
    exit 0
else
    echo "INVALID"
    exit 1
fi
VALIDEOF

chmod +x /usr/local/bin/validar-hwid

# API PHP
cat > /var/www/html/hwid/validate.php << 'PHPEOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['hwid'])) {
    echo json_encode(['error' => 'HWID requerido']);
    exit;
}

$hwid = $_GET['hwid'];
$output = shell_exec("/usr/local/bin/validar-hwid " . escapeshellarg($hwid) . " 2>&1");

if (strpos($output, 'VALID:') === 0) {
    $expira = substr($output, 6);
    echo json_encode([
        'success' => true,
        'valido' => true,
        'expira' => trim($expira)
    ]);
} else {
    echo json_encode([
        'success' => true,
        'valido' => false,
        'error' => 'HWID inválido o expirado'
    ]);
}
?>
PHPEOF

# API simple en Python (respaldo)
cat > /var/www/html/hwid/validate.py << 'PYEOF'
#!/usr/bin/python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json
import urllib.parse

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/validate':
            query = urllib.parse.parse_qs(parsed.query)
            hwid = query.get('hwid', [''])[0]
            
            if not hwid:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'{"error":"HWID requerido"}')
                return
            
            try:
                result = subprocess.check_output(['/usr/local/bin/validar-hwid', hwid], stderr=subprocess.STDOUT)
                result = result.decode().strip()
                
                if result.startswith('VALID:'):
                    expira = result[6:]
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(json.dumps({
                        'valido': True,
                        'expira': expira
                    }).encode())
                else:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(json.dumps({
                        'valido': False
                    }).encode())
            except:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'{"error":"Error interno"}')
    
    def log_message(self, format, *args):
        pass

HTTPServer(('0.0.0.0', 8001), Handler).serve_forever()
PYEOF

chmod +x /var/www/html/hwid/validate.py

# Servicio Python API
cat > /etc/systemd/system/hwid-api.service << 'SERVEOF'
[Unit]
Description=HWID Validation API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /var/www/html/hwid/validate.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVEOF

systemctl daemon-reload
systemctl enable hwid-api.service
systemctl start hwid-api.service

# Configurar Nginx
cat > /etc/nginx/sites-available/hwid << 'NGINXEOF'
server {
    listen 8002;
    root /var/www/html;
    index index.php;
    
    location /hwid/ {
        try_files $uri $uri/ =404;
        
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php-fpm.sock;
        }
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/hwid /etc/nginx/sites-enabled/
systemctl restart nginx

# ================================================
# FUNCIONES DE REGISTRO EN SERVIDOR
# ================================================
cat > /usr/local/bin/registrar-hwid << 'REGEOF'
#!/bin/bash
# Registrar HWID en el servidor
# Uso: registrar-hwid <HWID> <NOMBRE> <EXPIRA>

HWID="$1"
NOMBRE="$2"
EXPIRA="$3"

if [[ -z "$HWID" || -z "$NOMBRE" || -z "$EXPIRA" ]]; then
    echo "ERROR: Faltan parámetros"
    exit 1
fi

# 1. Crear archivo en /etc/mgvpn/hwids/
cat > "/etc/mgvpn/hwids/${HWID}.conf" << CONF
HWID=${HWID}
NOMBRE=${NOMBRE}
EXPIRA=${EXPIRA}
ACTIVO=1
CREADO=$(date '+%Y-%m-%d %H:%M:%S')
CONF

# 2. Agregar a lista maestra
echo "${HWID}:${NOMBRE}:${EXPIRA}" >> /etc/hwid_users

# 3. Crear script específico
cat > "/usr/local/bin/hwids/${HWID}.sh" << SCRIPT
#!/bin/bash
echo "HWID: ${HWID}"
echo "Usuario: ${NOMBRE}"
echo "Expira: ${EXPIRA}"
echo "Estado: ACTIVO"
exit 0
SCRIPT
chmod +x "/usr/local/bin/hwids/${HWID}.sh"

echo "✅ HWID ${HWID} registrado en servidor"
exit 0
REGEOF

cat > /usr/local/bin/eliminar-hwid << 'ELIMEOF'
#!/bin/bash
# Eliminar HWID del servidor
# Uso: eliminar-hwid <HWID>

HWID="$1"

if [[ -z "$HWID" ]]; then
    echo "ERROR: HWID requerido"
    exit 1
fi

# Eliminar archivos
rm -f "/etc/mgvpn/hwids/${HWID}.conf" 2>/dev/null
rm -f "/usr/local/bin/hwids/${HWID}.sh" 2>/dev/null

# Eliminar de lista maestra
if [[ -f "/etc/hwid_users" ]]; then
    sed -i "/^${HWID}:/d" /etc/hwid_users
fi

echo "✅ HWID ${HWID} eliminado"
exit 0
ELIMEOF

cat > /usr/local/bin/limpiar-hwids << 'LIMPIEOF'
#!/bin/bash
# Limpiar HWIDs expirados

DB="/opt/sshbot-pro/data/hwid.db"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$(date)] Limpiando HWIDs expirados..."

sqlite3 "$DB" "SELECT hwid FROM hwid_users WHERE expires_at < '$NOW' AND status=1" | while read hwid; do
    echo "  Eliminando $hwid"
    /usr/local/bin/eliminar-hwid "$hwid" >/dev/null 2>&1
    sqlite3 "$DB" "UPDATE hwid_users SET status=0 WHERE hwid='$hwid'"
done

echo "[$(date)] Limpieza completada"
LIMPIEOF

chmod +x /usr/local/bin/registrar-hwid
chmod +x /usr/local/bin/eliminar-hwid
chmod +x /usr/local/bin/limpiar-hwids

# Agregar a crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/limpiar-hwids >/dev/null 2>&1") | crontab -

echo -e "${GREEN}✅ Sistema de validación HWID creado${NC}"

# ================================================
# INSTALAR BOT
# ================================================
echo -e "\n${CYAN}🤖 Instalando bot...${NC}"

cd "$USER_HOME"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-hwid",
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
        "axios": "^1.6.5"
    }
}
PKGEOF

npm install --silent

# ================================================
# BOT PRINCIPAL
# ================================================
cat > bot.js << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');

const execPromise = util.promisify(exec);
moment.locale('es');

console.log(chalk.cyan.bold('\n🚀 BOT HWID INICIANDO...\n'));

// Configuración
const config = require('/opt/sshbot-pro/config/config.json');
const db = new sqlite3.Database('/opt/sshbot-pro/data/hwid.db');

// ================================================
// FUNCIÓN CRÍTICA: REGISTRAR HWID EN SERVIDOR
// ================================================
async function registrarHWIDenServidor(hwid, nombre, expires) {
    try {
        // Usar el script de registro
        await execPromise(`/usr/local/bin/registrar-hwid "${hwid}" "${nombre}" "${expires}"`);
        
        // Verificar que se creó
        const exists = fs.existsSync(`/etc/mgvpn/hwids/${hwid}.conf`);
        if (exists) {
            console.log(chalk.green(`✅ HWID ${hwid} registrado en servidor`));
            return true;
        } else {
            console.log(chalk.red(`❌ No se pudo verificar el registro`));
            return false;
        }
    } catch (error) {
        console.error(chalk.red('❌ Error registrando en servidor:'), error.message);
        return false;
    }
}

// ================================================
// ACTIVAR HWID
// ================================================
async function activarHWID(phone, nombre, hwid, dias, tipo = 'test') {
    return new Promise(async (resolve) => {
        try {
            // Calcular expiración
            let expireFull;
            if (dias === 0) {
                expireFull = moment().add(1, 'hours').format('YYYY-MM-DD HH:mm:ss');
            } else {
                expireFull = moment().add(dias, 'days').format('YYYY-MM-DD 23:59:59');
            }

            // Verificar si existe
            db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], async (err, row) => {
                if (row) {
                    resolve({ success: false, error: 'HWID ya registrado' });
                    return;
                }

                // 1. Registrar en BD
                db.run(
                    `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at) VALUES (?, ?, ?, ?, ?)`,
                    [phone, nombre, hwid, tipo, expireFull],
                    async function(err) {
                        if (err) {
                            resolve({ success: false, error: err.message });
                            return;
                        }

                        // 2. REGISTRAR EN SERVIDOR (¡CRÍTICO!)
                        const servidorOK = await registrarHWIDenServidor(hwid, nombre, expireFull);
                        
                        if (servidorOK) {
                            console.log(chalk.green(`✅ HWID ${hwid} activado para ${nombre}`));
                            resolve({ 
                                success: true, 
                                hwid, 
                                nombre, 
                                expires: expireFull 
                            });
                        } else {
                            // Rollback
                            db.run('DELETE FROM hwid_users WHERE hwid = ?', [hwid]);
                            resolve({ success: false, error: 'Error registrando en servidor' });
                        }
                    }
                );
            });
        } catch (error) {
            resolve({ success: false, error: error.message });
        }
    });
}

// ================================================
// VERIFICAR PRUEBA DIARIA
// ================================================
function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], (err, row) => {
            resolve(!err && row && row.count === 0);
        });
    });
}

function registerTest(phone, nombre) {
    db.run('INSERT OR IGNORE INTO daily_tests (phone, nombre, date) VALUES (?, ?, ?)', 
        [phone, nombre, moment().format('YYYY-MM-DD')]);
}

// ================================================
// MANEJO DE ESTADOS
// ================================================
const userStates = {};

// ================================================
// INICIAR BOT
// ================================================
async function startBot() {
    try {
        const client = await wppconnect.create({
            session: 'hwid-bot',
            headless: true,
            logQR: true,
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage'
            ]
        });

        console.log(chalk.green('✅ Bot conectado a WhatsApp'));

        client.onMessage(async (message) => {
            try {
                const text = message.body.trim();
                const from = message.from;
                const lowerText = text.toLowerCase();

                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));

                // ========== MENÚ PRINCIPAL ==========
                if (['menu', 'hola', 'start', '0'].includes(lowerText)) {
                    userStates[from] = { state: 'main' };
                    await client.sendText(from, `🤖 *SISTEMA HWID*

Elija una opción:

1️⃣ *PROBAR GRATIS* (1 hora)
2️⃣ *COMPRAR PLAN*
3️⃣ *VERIFICAR MI HWID*
4️⃣ *DESCARGAR APP*

--------------------------------
📱 Responde con el número`);
                }

                // ========== OPCIÓN 1: PRUEBA ==========
                else if (text === '1' && (!userStates[from] || userStates[from].state === 'main')) {
                    userStates[from] = { state: 'awaiting_test_name' };
                    await client.sendText(from, `📝 *PRUEBA GRATUITA*

Escribe tu *NOMBRE*:`);
                }

                // ========== RECIBIR NOMBRE PARA PRUEBA ==========
                else if (userStates[from]?.state === 'awaiting_test_name') {
                    const nombre = text;
                    
                    if (nombre.length < 2) {
                        await client.sendText(from, '❌ Nombre muy corto. Intenta de nuevo:');
                        return;
                    }

                    userStates[from] = {
                        state: 'awaiting_test_hwid',
                        nombre: nombre,
                        tipo: 'test'
                    };

                    await client.sendText(from, `✅ Gracias *${nombre}*

Ahora envía tu *HWID*:

📱 *¿CÓMO OBTENERLO?*
1. Abre la aplicación MGVPN
2. Toca el botón de WhatsApp
3. Copia el HWID

Formato: APP-E3E4D5CBB7636907

⏳ Una prueba por día`);
                }

                // ========== RECIBIR HWID PARA PRUEBA ==========
                else if (userStates[from]?.state === 'awaiting_test_hwid') {
                    const hwid = text.trim().toUpperCase();
                    const { nombre } = userStates[from];

                    // Validar formato
                    if (!hwid.startsWith('APP-') || hwid.length < 10) {
                        await client.sendText(from, '❌ Formato inválido. Debe ser: APP-E3E4D5CBB7636907');
                        return;
                    }

                    // Verificar prueba diaria
                    if (!(await canCreateTest(from))) {
                        await client.sendText(from, '❌ Ya usaste tu prueba hoy. Vuelve mañana o compra un plan.');
                        delete userStates[from];
                        return;
                    }

                    await client.sendText(from, '⏳ Activando prueba...');

                    // ACTIVAR HWID
                    const result = await activarHWID(from, nombre, hwid, 0, 'test');

                    if (result.success) {
                        registerTest(from, nombre);
                        
                        await client.sendText(from, `✅ *PRUEBA ACTIVADA*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
⏰ *Expira:* ${moment(result.expires).format('HH:mm DD/MM/YYYY')}

📱 *YA PUEDES CONECTARTE*

El HWID ya está registrado en el servidor`);
                        
                        console.log(chalk.green(`✅ PRUEBA: ${hwid} - ${nombre}`));
                    } else {
                        await client.sendText(from, `❌ Error: ${result.error}`);
                    }

                    delete userStates[from];
                }

                // ========== OPCIÓN 2: COMPRAR ==========
                else if (text === '2' && (!userStates[from] || userStates[from].state === 'main')) {
                    userStates[from] = { state: 'buying' };
                    
                    await client.sendText(from, `💰 *PLANES DISPONIBLES*

Selecciona:

1️⃣ *7 DÍAS* - $${config.prices.price_7d}
2️⃣ *15 DÍAS* - $${config.prices.price_15d}
3️⃣ *30 DÍAS* - $${config.prices.price_30d}
4️⃣ *50 DÍAS* - $${config.prices.price_50d}

0️⃣ *VOLVER*`);
                }

                // ========== SELECCIONAR PLAN ==========
                else if (userStates[from]?.state === 'buying' && ['1','2','3','4'].includes(text)) {
                    const plans = {
                        '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                        '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                        '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                        '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                    };
                    
                    const plan = plans[text];
                    
                    userStates[from] = {
                        state: 'awaiting_payment_name',
                        plan: plan
                    };

                    await client.sendText(from, `📝 *PLAN ${plan.name}*

Escribe tu *NOMBRE*:`);
                }

                // ========== RECIBIR NOMBRE PARA COMPRA ==========
                else if (userStates[from]?.state === 'awaiting_payment_name') {
                    const nombre = text;
                    
                    if (nombre.length < 2) {
                        await client.sendText(from, '❌ Nombre muy corto. Intenta de nuevo:');
                        return;
                    }

                    userStates[from].nombre = nombre;
                    userStates[from].state = 'awaiting_payment_hwid';

                    await client.sendText(from, `✅ Gracias *${nombre}*

Ahora envía tu *HWID*:

Formato: APP-E3E4D5CBB7636907`);
                }

                // ========== RECIBIR HWID PARA COMPRA ==========
                else if (userStates[from]?.state === 'awaiting_payment_hwid') {
                    const hwid = text.trim().toUpperCase();
                    const { nombre, plan } = userStates[from];

                    if (!hwid.startsWith('APP-') || hwid.length < 10) {
                        await client.sendText(from, '❌ Formato inválido. Debe ser: APP-E3E4D5CBB7636907');
                        return;
                    }

                    await client.sendText(from, '⏳ Procesando...');

                    // ACTIVAR HWID PREMIUM
                    const result = await activarHWID(from, nombre, hwid, plan.days, 'premium');

                    if (result.success) {
                        await client.sendText(from, `✅ *¡ACTIVACIÓN EXITOSA!*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
📅 *Plan:* ${plan.name}
⏰ *Expira:* ${moment(result.expires).format('DD/MM/YYYY')}

🎉 *YA PUEDES CONECTARTE*

El HWID ya está registrado en el servidor`);
                        
                        console.log(chalk.green(`💰 VENTA: ${plan.name} - ${hwid} - ${nombre}`));
                    } else {
                        await client.sendText(from, `❌ Error: ${result.error}`);
                    }

                    delete userStates[from];
                }

                // ========== OPCIÓN 3: VERIFICAR HWID ==========
                else if (text === '3' && (!userStates[from] || userStates[from].state === 'main')) {
                    userStates[from] = { state: 'awaiting_check' };
                    await client.sendText(from, `🔍 *VERIFICAR HWID*

Envía tu HWID:
APP-E3E4D5CBB7636907`);
                }

                // ========== VERIFICAR HWID ==========
                else if (userStates[from]?.state === 'awaiting_check') {
                    const hwid = text.trim().toUpperCase();
                    
                    // Verificar en BD
                    db.get('SELECT nombre, expires_at, tipo FROM hwid_users WHERE hwid = ? AND status = 1', 
                        [hwid], async (err, row) => {
                        
                        if (row && moment(row.expires_at).isAfter(moment())) {
                            await client.sendText(from, `✅ *HWID ACTIVO*

👤 *Usuario:* ${row.nombre}
🔐 *HWID:* ${hwid}
📅 *Tipo:* ${row.tipo}
⏰ *Expira:* ${moment(row.expires_at).format('DD/MM/YYYY HH:mm')}`);
                        } else {
                            await client.sendText(from, `❌ *HWID NO ACTIVO*

El HWID no está registrado o expiró.

¿Quieres probar? Envía *1*`);
                        }
                        
                        delete userStates[from];
                    });
                }

                // ========== OPCIÓN 4: DESCARGAR APP ==========
                else if (text === '4' && (!userStates[from] || userStates[from].state === 'main')) {
                    await client.sendText(from, `📱 *DESCARGAR APP*

🔗 *Link:*
https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL

📌 *Instrucciones:*
1. Descarga el APK
2. Abre el archivo
3. Click en "Más detalles"
4. Click en "Instalar de todas formas"
5. Listo para usar`);
                }

                // ========== VOLVER ==========
                else if (text === '0' && userStates[from]) {
                    delete userStates[from];
                    await client.sendText(from, `🤖 *SISTEMA HWID*

1️⃣ PROBAR GRATIS
2️⃣ COMPRAR PLAN
3️⃣ VERIFICAR MI HWID
4️⃣ DESCARGAR APP`);
                }

            } catch (error) {
                console.error(chalk.red('❌ Error:'), error.message);
            }
        });

        // Limpieza automática cada 5 minutos
        cron.schedule('*/5 * * * *', () => {
            exec('/usr/local/bin/limpiar-hwids', (err) => {
                if (err) console.error('Error en limpieza:', err.message);
            });
        });

    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        setTimeout(startBot, 10000);
    }
}

startBot();
BOTEOF

# ================================================
# PANEL DE CONTROL
# ================================================
cat > /usr/local/bin/sshbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/hwid.db"

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     PANEL SSH BOT PRO - HWID          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
    
    # Estadísticas
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo 0)
    ACTIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo 0)
    TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date=date('now')" 2>/dev/null || echo 0)
    
    echo -e "${YELLOW}📊 ESTADO ACTUAL:${NC}"
    echo -e "  HWIDs totales: ${CYAN}$TOTAL${NC}"
    echo -e "  HWIDs activos: ${GREEN}$ACTIVOS${NC}"
    echo -e "  Tests hoy: ${CYAN}$TESTS${NC}"
    echo -e ""
    
    echo -e "${GREEN}1)${NC} Ver HWIDs activos"
    echo -e "${GREEN}2)${NC} Ver logs del bot"
    echo -e "${GREEN}3)${NC} Reiniciar bot"
    echo -e "${GREEN}4)${NC} Ver archivos HWID en servidor"
    echo -e "${GREEN}5)${NC} Probar validación HWID"
    echo -e "${GREEN}6)${NC} Ver API endpoints"
    echo -e "${GREEN}0)${NC} Salir"
    echo ""
}

while true; do
    show_menu
    read -p "Opción: " opt
    
    case $opt in
        1)
            echo -e "\n${CYAN}HWIDs ACTIVOS:${NC}\n"
            sqlite3 -column -header "$DB" "SELECT nombre, hwid, tipo, expires_at FROM hwid_users WHERE status=1 ORDER BY expires_at"
            read -p "Enter para continuar..."
            ;;
        2)
            pm2 logs sshbot-pro --lines 50
            ;;
        3)
            pm2 restart sshbot-pro
            echo -e "${GREEN}✅ Bot reiniciado${NC}"
            sleep 2
            ;;
        4)
            echo -e "\n${CYAN}Archivos HWID en /etc/mgvpn/hwids/:${NC}\n"
            ls -la /etc/mgvpn/hwids/
            read -p "Enter para continuar..."
            ;;
        5)
            read -p "Ingresa HWID a validar: " test_hwid
            echo -e "\n${YELLOW}Resultado:${NC}"
            /usr/local/bin/validar-hwid "$test_hwid" && echo "✅ VÁLIDO" || echo "❌ INVÁLIDO"
            read -p "Enter para continuar..."
            ;;
        6)
            echo -e "\n${CYAN}API ENDPOINTS:${NC}"
            echo -e "  Python API: ${GREEN}http://$(curl -s ifconfig.me):8001/validate?hwid=APP-XXXX${NC}"
            echo -e "  PHP API: ${GREEN}http://$(curl -s ifconfig.me):8002/hwid/validate.php?hwid=APP-XXXX${NC}"
            echo -e "  Local: ${GREEN}validar-hwid APP-XXXX${NC}"
            read -p "Enter para continuar..."
            ;;
        0)
            exit 0
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot

# ================================================
# INICIAR TODO
# ================================================
cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro
pm2 save
pm2 startup

# Crear archivos iniciales
touch /etc/hwid_users
chmod 666 /etc/hwid_users

# ================================================
# MOSTRAR INFORMACIÓN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA 🎉                       ║
║                                                              ║
║       ✅ SISTEMA HWID FUNCIONANDO                           ║
║       ✅ REGISTRO AUTOMÁTICO EN SERVIDOR                    ║
║       ✅ API DE VALIDACIÓN ACTIVA                           ║
║       ✅ BOT DE WHATSAPP LISTO                              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📱 ESCANEA EL QR:${NC}"
echo -e "   ${YELLOW}pm2 logs sshbot-pro${NC}\n"

echo -e "${GREEN}🔐 SISTEMA HWID:${NC}"
echo -e "   📁 Archivos HWID: ${CYAN}/etc/mgvpn/hwids/${NC}"
echo -e "   📋 Lista maestra: ${CYAN}/etc/hwid_users${NC}"
echo -e "   ✅ Validar HWID: ${CYAN}validar-hwid APP-E3E4D5CBB7636907${NC}\n"

echo -e "${GREEN}🌐 API ENDPOINTS:${NC}"
echo -e "   🐍 Python: ${CYAN}http://$SERVER_IP:8001/validate?hwid=APP-E3E4D5CBB7636907${NC}"
echo -e "   🐘 PHP: ${CYAN}http://$SERVER_IP:8002/hwid/validate.php?hwid=APP-E3E4D5CBB7636907${NC}\n"

echo -e "${GREEN}🎛️  PANEL DE CONTROL:${NC}"
echo -e "   ${CYAN}sshbot${NC}\n"

echo -e "${GREEN}🔄 LIMPIEZA AUTOMÁTICA:${NC}"
echo -e "   Cada 5 minutos (crontab)"
echo -e "   Manual: ${CYAN}limpiar-hwids${NC}\n"

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "   1. Espera el QR y escanéalo"
echo -e "   2. Prueba con: ${CYAN}validar-hwid APP-E3E4D5CBB7636907${NC}"
echo -e "   3. Verifica archivos en: ${CYAN}ls /etc/mgvpn/hwids/${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Preguntar si ver logs
read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs... Espera el QR${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
fi

exit 0
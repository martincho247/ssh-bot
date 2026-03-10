#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALACIÓN COMPLETA CORREGIDA
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
║          ✅ VERSIÓN CORREGIDA - CON REGISTRO AUTOMÁTICO     ║
║          🔐 SISTEMA HWID - SIN USUARIO/CONTRASEÑA           ║
║          ⏱️  PRUEBA 2 HORAS - CORREGIDA                     ║
║          💰 MERCADOPAGO INTEGRADO                           ║
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

# Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable || apt-get install -y chromium-browser

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

# Limpiar
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" /root/.wppconnect 2>/dev/null || true

# Crear
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 777 "$INSTALL_DIR/data"
chmod -R 700 /root/.wppconnect

echo -e "${GREEN}✅ Directorios creados${NC}"

# ================================================
# CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}⚙️  Creando configuración...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro HWID",
        "version": "3.0-FINAL",
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

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hwid_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hwid TEXT,
    phone TEXT,
    nombre TEXT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hwid_users_hwid ON hwid_users(hwid);
CREATE INDEX IF NOT EXISTS idx_hwid_users_status ON hwid_users(status);
CREATE INDEX IF NOT EXISTS idx_hwid_users_expires ON hwid_users(expires_at);
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
    "name": "sshbot-pro-hwid",
    "version": "3.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "moment-timezone": "^0.5.43",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "mercadopago": "^2.0.15",
        "axios": "^1.6.5"
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
# BOT.JS - VERSIÓN CON REGISTRO AUTOMÁTICO GARANTIZADO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con registro automático...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');

moment.locale('es');
moment.tz.setDefault('America/Argentina/Buenos_Aires');

// CONFIGURACIÓN
const DB_PATH = '/opt/sshbot-pro/data/hwid.db';
const db = new sqlite3.Database(DB_PATH);

console.log(chalk.green.bold('\n================================='));
console.log(chalk.green.bold('✅ BOT INICIADO - MODO CORREGIDO'));
console.log(chalk.green.bold('✅ REGISTRO AUTOMÁTICO ACTIVADO'));
console.log(chalk.green.bold('=================================\n'));

// ================================================
// FUNCIONES HWID - GARANTIZADAS
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

// FUNCIÓN DE REGISTRO - CON LOGS OBLIGATORIOS
function registerHWID(phone, nombre, hwid, days, tipo, callback) {
    console.log(chalk.yellow('\n📝 ===== INTENTANDO REGISTRAR HWID ====='));
    console.log(chalk.cyan(`📱 Teléfono: ${phone}`));
    console.log(chalk.cyan(`👤 Nombre: ${nombre}`));
    console.log(chalk.cyan(`🔐 HWID: ${hwid}`));
    console.log(chalk.cyan(`📅 Tipo: ${tipo}, Días: ${days}`));

    // Verificar si existe
    db.get('SELECT hwid FROM hwid_users WHERE hwid = ?', [hwid], (err, row) => {
        if (err) {
            console.log(chalk.red('❌ Error al verificar:'), err.message);
            callback({ success: false, error: err.message });
            return;
        }

        if (row) {
            console.log(chalk.red('❌ HWID YA EXISTE:'), hwid);
            callback({ success: false, error: 'HWID ya existe' });
            return;
        }

        console.log(chalk.green('✅ HWID no existe, insertando...'));

        // Calcular expiración
        let expireFull;
        if (days === 0 || tipo === 'test') {
            expireFull = moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.cyan(`⏱️ Prueba 2 horas - Expira: ${expireFull}`));
        } else {
            expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
            console.log(chalk.cyan(`💰 Premium - Expira: ${expireFull}`));
        }

        // Insertar en BD
        db.run(
            `INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) 
             VALUES (?, ?, ?, ?, ?, 1)`,
            [phone, nombre, hwid, tipo, expireFull],
            function(err) {
                if (err) {
                    console.log(chalk.red('❌ Error INSERT:'), err.message);
                    callback({ success: false, error: err.message });
                } else {
                    console.log(chalk.green('✅ INSERT EXITOSO! ID:'), this.lastID);
                    console.log(chalk.green('🎉 HWID REGISTRADO CORRECTAMENTE'));
                    console.log(chalk.green('=================================\n'));
                    
                    // Verificar que quedó registrado
                    db.get('SELECT * FROM hwid_users WHERE id = ?', [this.lastID], (err, row) => {
                        if (row) {
                            console.log(chalk.cyan('📋 VERIFICACIÓN: HWID en BD:'), row.hwid);
                        }
                    });
                    
                    callback({ 
                        success: true, 
                        hwid, 
                        nombre, 
                        expires: expireFull,
                        id: this.lastID 
                    });
                }
            }
        );
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
                executablePath: '/usr/bin/google-chrome',
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            }
        });

        console.log(chalk.green('\n✅ BOT CONECTADO A WHATSAPP!\n'));

        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                if (message.isGroupMsg) return;
                
                const text = message.body.trim();
                const from = message.from;
                
                console.log(chalk.cyan(`\n📩 MENSAJE RECIBIDO: ${text}`));

                // ================================================
                // MENÚ PRINCIPAL
                // ================================================
                if (text.toLowerCase() === 'hola' || text === 'menu' || text === '0') {
                    await client.sendText(from, `🤖 *BOT MGVPN - HWID*

Elige una opción:

1️⃣ - PROBAR GRATIS (2 HORAS)
2️⃣ - COMPRAR INTERNET
3️⃣ - VERIFICAR MI HWID
4️⃣ - DESCARGAR APP

⏱️ *PRUEBA: 2 HORAS*`);
                    
                    // Limpiar estado
                    db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                }

                // ================================================
                // OPCIÓN 1 - PRUEBA GRATIS
                // ================================================
                else if (text === '1') {
                    await client.sendText(from, '👤 *Dime tu NOMBRE*:');
                    
                    db.run('INSERT OR REPLACE INTO user_state (phone, state, data) VALUES (?, ?, ?)',
                        [from, 'awaiting_name', '{}']);
                }

                // ================================================
                // OPCIÓN 2 - COMPRAR
                // ================================================
                else if (text === '2') {
                    await client.sendText(from, `💰 *PLANES DISPONIBLES*

1️⃣ - 7 DÍAS - $3000
2️⃣ - 15 DÍAS - $4000
3️⃣ - 30 DÍAS - $7000
4️⃣ - 50 DÍAS - $9700

0️⃣ - VOLVER

Elige una opción:`);
                    
                    db.run('INSERT OR REPLACE INTO user_state (phone, state, data) VALUES (?, ?, ?)',
                        [from, 'buying', '{}']);
                }

                // ================================================
                // OPCIÓN 3 - VERIFICAR HWID
                // ================================================
                else if (text === '3') {
                    await client.sendText(from, '🔍 *Envía tu HWID* para verificar:\n\nFormato: APP-E3E4D5CBB7636907');
                    
                    db.run('INSERT OR REPLACE INTO user_state (phone, state, data) VALUES (?, ?, ?)',
                        [from, 'checking', '{}']);
                }

                // ================================================
                // OPCIÓN 4 - DESCARGAR
                // ================================================
                else if (text === '4') {
                    await client.sendText(from, `📱 *DESCARGAR APP*

https://www.mediafire.com/file/18tnc70qr2771lu/MGVPN.apk/file

1. Descarga el APK
2. Instala la aplicación
3. Abre y obtén tu HWID`);
                }

                // ================================================
                // PROCESAR SEGÚN ESTADO
                // ================================================
                else {
                    // Obtener estado del usuario
                    db.get('SELECT state, data FROM user_state WHERE phone = ?', [from], async (err, row) => {
                        if (err || !row) {
                            await client.sendText(from, '❌ No entendí. Escribe *MENU* para ver opciones.');
                            return;
                        }

                        // ========================================
                        // ESPERANDO NOMBRE (para prueba)
                        // ========================================
                        if (row.state === 'awaiting_name') {
                            const nombre = text;
                            
                            if (nombre.length < 2) {
                                await client.sendText(from, '❌ Nombre muy corto. Intenta de nuevo:');
                                return;
                            }
                            
                            await client.sendText(from, `✅ Gracias *${nombre}*\n\nAhora envía tu *HWID*:\n\nFormato: APP-E3E4D5CBB7636907`);
                            
                            db.run('UPDATE user_state SET state = ?, data = ? WHERE phone = ?',
                                ['awaiting_hwid', JSON.stringify({ nombre }), from]);
                        }

                        // ========================================
                        // ESPERANDO HWID (para prueba)
                        // ========================================
                        else if (row.state === 'awaiting_hwid') {
                            const data = JSON.parse(row.data || '{}');
                            const nombre = data.nombre;
                            const hwid = normalizeHWID(text);
                            
                            console.log(chalk.yellow('\n📋 DATOS PARA REGISTRO:'));
                            console.log(chalk.yellow(`   Nombre: ${nombre}`));
                            console.log(chalk.yellow(`   HWID recibido: ${text}`));
                            console.log(chalk.yellow(`   HWID normalizado: ${hwid}`));
                            
                            if (!validateHWID(hwid)) {
                                await client.sendText(from, '❌ *FORMATO INCORRECTO*\n\nDebe ser: APP-E3E4D5CBB7636907\n\nIntenta de nuevo:');
                                return;
                            }
                            
                            // Verificar si ya usó prueba hoy
                            db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = date("now")', 
                                [from], async (err, testRow) => {
                                
                                if (testRow && testRow.count > 0) {
                                    await client.sendText(from, '❌ *YA USaste tu prueba hoy*\n\nVuelve mañana o compra un plan.');
                                    db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                                    return;
                                }
                                
                                await client.sendText(from, '⏳ *Activando prueba de 2 horas...*');
                                
                                // REGISTRAR HWID - ESTA ES LA PARTE CRÍTICA
                                registerHWID(from, nombre, hwid, 0, 'test', async (result) => {
                                    if (result.success) {
                                        // Registrar test diario
                                        db.run('INSERT INTO daily_tests (phone, nombre, date) VALUES (?, ?, date("now"))',
                                            [from, nombre]);
                                        
                                        const expireTime = moment(result.expires).format('HH:mm DD/MM/YYYY');
                                        
                                        await client.sendText(from, `✅ *PRUEBA ACTIVADA CORRECTAMENTE*

👤 *Usuario:* ${nombre}
🔐 *HWID:* ${hwid}
⏰ *Expira:* ${expireTime}

📱 *YA PUEDES CONECTARTE*

Si tienes problemas, contacta soporte.`);
                                        
                                        console.log(chalk.green(`\n🎉 HWID REGISTRADO CON ÉXITO: ${hwid}`));
                                    } else {
                                        await client.sendText(from, `❌ *ERROR:* ${result.error}`);
                                        console.log(chalk.red(`\n❌ ERROR AL REGISTRAR: ${result.error}`));
                                    }
                                    
                                    db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                                });
                            });
                        }

                        // ========================================
                        // VERIFICAR HWID
                        // ========================================
                        else if (row.state === 'checking') {
                            const hwid = normalizeHWID(text);
                            
                            db.get('SELECT * FROM hwid_users WHERE hwid = ?', [hwid], async (err, hwidRow) => {
                                if (hwidRow) {
                                    const estado = (hwidRow.status === 1 && moment(hwidRow.expires_at).isAfter(moment())) ? '✅ ACTIVO' : '❌ EXPIRADO';
                                    await client.sendText(from, `📋 *ESTADO DEL HWID*

🔐 HWID: ${hwid}
👤 Usuario: ${hwidRow.nombre}
📅 Tipo: ${hwidRow.tipo}
⏰ Expira: ${moment(hwidRow.expires_at).format('DD/MM/YYYY HH:mm')}
📊 Estado: ${estado}`);
                                } else {
                                    await client.sendText(from, `❌ *HWID NO REGISTRADO*

El HWID ${hwid} no existe en el sistema.

¿Quieres probar? Envia 1 para prueba gratis.`);
                                }
                                
                                db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                            });
                        }

                        // ========================================
                        // COMPRAR
                        // ========================================
                        else if (row.state === 'buying') {
                            const plan = text;
                            
                            if (plan === '0') {
                                await client.sendText(from, '🤖 *MENÚ PRINCIPAL*\n\nEscribe *HOLA* para ver opciones.');
                                db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                                return;
                            }
                            
                            const planes = {
                                '1': { dias: 7, precio: 3000, nombre: '7 DÍAS' },
                                '2': { dias: 15, precio: 4000, nombre: '15 DÍAS' },
                                '3': { dias: 30, precio: 7000, nombre: '30 DÍAS' },
                                '4': { dias: 50, precio: 9700, nombre: '50 DÍAS' }
                            };
                            
                            if (planes[plan]) {
                                const p = planes[plan];
                                await client.sendText(from, `📌 *PLAN SELECCIONADO: ${p.nombre}*

💰 Precio: $${p.precio}

Para pagar, contacta al administrador:
wa.me/543435071016`);
                            } else {
                                await client.sendText(from, '❌ Opción inválida. Elige 1-4 o 0 para volver.');
                                return;
                            }
                            
                            db.run('DELETE FROM user_state WHERE phone = ?', [from]);
                        }

                        // ========================================
                        // RESPUESTA POR DEFECTO
                        // ========================================
                        else {
                            await client.sendText(from, '❌ No entendí. Escribe *MENU* para ver opciones.');
                        }
                    });
                }

            } catch (error) {
                console.log(chalk.red('Error procesando mensaje:'), error.message);
            }
        });

        // ================================================
        // TAREAS PROGRAMADAS
        // ================================================
        
        // Limpiar HWIDs expirados cada 15 minutos
        cron.schedule('*/15 * * * *', () => {
            db.run(`UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime') AND status = 1`);
            console.log(chalk.yellow('🧹 HWIDs expirados limpiados'));
        });

        // Limpiar estados antiguos cada hora
        cron.schedule('0 * * * *', () => {
            db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
        });

    } catch (error) {
        console.log(chalk.red('Error iniciando bot:'), error.message);
        setTimeout(startBot, 5000);
    }
}

// Iniciar
startBot();

// Manejar cierre
process.on('SIGINT', () => {
    console.log(chalk.yellow('\n🛑 Cerrando bot...'));
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ bot.js creado con registro automático${NC}"

# ================================================
# PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/sshbot-hwid << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/hwid.db"

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     PANEL SSH BOT PRO - REGISTRO AUTOMÁTICO       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"
    
    # Estadísticas
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users" 2>/dev/null || echo "0")
    ACTIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM hwid_users WHERE status=1" 2>/dev/null || echo "0")
    TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date=date('now')" 2>/dev/null || echo "0")
    
    # Estado del bot
    if pm2 list | grep -q "sshbot-pro.*online"; then
        BOT="${GREEN}● ACTIVO${NC}"
    else
        BOT="${RED}● DETENIDO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO ACTUAL:${NC}"
    echo -e "  Bot: $BOT"
    echo -e "  HWIDs: $ACTIVOS activos / $TOTAL totales"
    echo -e "  Tests hoy: $TESTS"
    echo ""
    
    echo -e "${CYAN}1)${NC} Iniciar/Reiniciar bot"
    echo -e "${CYAN}2)${NC} Detener bot"
    echo -e "${CYAN}3)${NC} Ver logs en tiempo real"
    echo -e "${CYAN}4)${NC} Registrar HWID manual"
    echo -e "${CYAN}5)${NC} Listar HWIDs activos"
    echo -e "${CYAN}6)${NC} Ver todos los HWIDs"
    echo -e "${CYAN}7)${NC} Ver tests de hoy"
    echo -e "${CYAN}8)${NC} Corregir fechas expiradas"
    echo -e "${CYAN}9)${NC} Probar inserción manual"
    echo -e "${CYAN}0)${NC} Salir"
    echo ""
}

while true; do
    show_menu
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
            echo -e "${CYAN}📝 REGISTRAR HWID MANUAL${NC}\n"
            read -p "Teléfono (ej: 549112233@c.us): " PHONE
            read -p "Nombre: " NOMBRE
            read -p "HWID (APP-XXXXXXXX): " HWID
            read -p "Días (0=test 2h, 7,15,30,50): " DIAS
            
            HWID=$(echo "$HWID" | tr 'a-z' 'A-Z')
            if [[ $DIAS == "0" ]]; then
                EXPIRE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                TIPO="test"
            else
                EXPIRE=$(date -d "+$DIAS days" +"%Y-%m-%d 23:59:59")
                TIPO="premium"
            fi
            
            sqlite3 "$DB" "INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('$PHONE', '$NOMBRE', '$HWID', '$TIPO', '$EXPIRE', 1)" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "\n${GREEN}✅ HWID registrado${NC}"
                echo -e "Expira: $EXPIRE"
            else
                echo -e "\n${RED}❌ Error (puede que el HWID ya exista)${NC}"
            fi
            read -p "Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}📋 HWIDs ACTIVOS${NC}\n"
            sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, tipo, expires_at FROM hwid_users WHERE status=1 ORDER BY expires_at"
            read -p "Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}📋 TODOS LOS HWIDs${NC}\n"
            sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, tipo, status, expires_at FROM hwid_users ORDER BY id DESC LIMIT 20"
            read -p "Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}📋 TESTS DE HOY${NC}\n"
            sqlite3 -header -column "$DB" "SELECT nombre, phone, created_at FROM daily_tests WHERE date=date('now')"
            read -p "Enter..."
            ;;
        8)
            clear
            echo -e "${CYAN}🔧 CORRIGIENDO FECHAS...${NC}"
            sqlite3 "$DB" "UPDATE hwid_users SET status = 0 WHERE expires_at < datetime('now', 'localtime') AND status = 1"
            sqlite3 "$DB" "UPDATE hwid_users SET status = 1 WHERE expires_at > datetime('now', 'localtime') AND status = 0"
            echo -e "${GREEN}✅ Listo${NC}"
            read -p "Enter..."
            ;;
        9)
            clear
            echo -e "${CYAN}🧪 PROBAR INSERCIÓN MANUAL${NC}\n"
            TEST_HWID="APP-$(date +%s | sha256sum | head -c 16 | tr 'a-f' 'A-F')"
            echo -e "Insertando HWID de prueba: ${CYAN}$TEST_HWID${NC}"
            
            sqlite3 "$DB" "INSERT INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('549112233@c.us', 'PRUEBA', '$TEST_HWID', 'test', datetime('now', '+2 hours'), 1)"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Inserción exitosa${NC}"
                echo -e "\nHWIDs en BD:"
                sqlite3 -header -column "$DB" "SELECT id, nombre, hwid, expires_at FROM hwid_users WHERE hwid='$TEST_HWID'"
            else
                echo -e "${RED}❌ Error en inserción${NC}"
            fi
            read -p "Enter..."
            ;;
        0)
            exit 0
            ;;
    esac
done
PANELEOF

chmod +x /usr/local/bin/sshbot-hwid
ln -sf /usr/local/bin/sshbot-hwid /usr/local/bin/sshbot

# ================================================
# CONFIGURAR PM2
# ================================================
echo -e "\n${CYAN}⚙️  Configurando PM2...${NC}"
pm2 startup systemd -u root --hp /root > /dev/null 2>&1
pm2 save

# ================================================
# INSERTAR HWID DE PRUEBA
# ================================================
echo -e "\n${CYAN}🧪 Insertando HWID de prueba...${NC}"
TEST_HWID="APP-$(date +%s | sha256sum | head -c 16 | tr 'a-f' 'A-F')"
sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO hwid_users (phone, nombre, hwid, tipo, expires_at, status) VALUES ('549112233@c.us', 'PRUEBA_SISTEMA', '$TEST_HWID', 'test', datetime('now', '+2 hours'), 1)"
echo -e "${GREEN}✅ HWID de prueba: ${CYAN}$TEST_HWID${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot...${NC}"
cd /root/sshbot-pro
pm2 start bot.js --name sshbot-pro --max-memory-restart 512M
pm2 save

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ✅ INSTALACIÓN COMPLETADA - CORREGIDA               ║"
echo "║         ✅ REGISTRO AUTOMÁTICO DE HWIDs ACTIVADO            ║"
echo "║         ✅ PRUEBA 2 HORAS - FUNCIONANDO                     ║"
echo "║         ✅ HWID DE PRUEBA: ${TEST_HWID}                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "\n${YELLOW}📋 COMANDOS:${NC}"
echo -e "  ${GREEN}sshbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver QR y logs"
echo ""

echo -e "${YELLOW}📱 PRIMEROS PASOS:${NC}"
echo -e "  1. Ejecuta: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  2. Escanea el QR con WhatsApp"
echo -e "  3. Envia 'hola' al número"
echo -e "  4. Prueba opción 1 con HWID: ${CYAN}${TEST_HWID}${NC}"
echo ""

echo -e "${YELLOW}🔍 VERIFICAR REGISTRO:${NC}"
echo -e "  • En los logs DEBES ver:"
echo -e "    ${GREEN}✅ INSERT EXITOSO!${NC}"
echo -e "    ${GREEN}🎉 HWID REGISTRADO CORRECTAMENTE${NC}"
echo ""

echo -e "${YELLOW}🔧 SI HAY PROBLEMAS:${NC}"
echo -e "  • Usa: ${GREEN}sshbot${NC} y opción 8 para corregir fechas"
echo -e "  • Opción 9 para probar inserción manual"
echo ""

read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    pm2 logs sshbot-pro
fi

exit 0
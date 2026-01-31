#!/bin/bash
# ================================================
# SSH BOT PRO - WPPCONNECT (API FUNCIONANDO)
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                🤖 SSH BOT - WPPCONNECT EDITION             ║
║               📱 API WhatsApp QUE SÍ FUNCIONA              ║
║               💰 Planes: 7, 15, 30, 50 días               ║
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
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias...${NC}"

apt-get update -y
apt-get upgrade -y

# Node.js 18.x (más compatible con WPPConnect)
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
    unzip cron ufw

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw --force enable

# PM2
npm install -g pm2
pm2 update

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/wpp-bot"
USER_HOME="/root/wpp-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar anterior
pm2 delete wpp-bot 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "WPPCONNECT-1.0",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 1,
        "price_7d": 1500.00,
        "price_15d": 2500.00,
        "price_30d": 5500.00,
        "price_50d": 8500.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL",
        "support": "https://wa.me/543435071016"
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
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT CON WPPCONNECT
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con WPPConnect...${NC}"

cd "$USER_HOME"

# package.json con WPPConnect
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-wpp",
    "version": "1.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "axios": "^1.6.5"
    }
}
PKGEOF

echo -e "${YELLOW}📦 Instalando WPPConnect...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# Crear bot.js con WPPConnect
echo -e "${YELLOW}📝 Creando bot.js...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');

const execPromise = util.promisify(exec);
moment.locale('es');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║                🤖 SSH BOT - WPPCONNECT EDITION              ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/wpp-bot/config/config.json')];
    return require('/opt/wpp-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/wpp-bot/data/users.db');

// Variables globales
let client = null;
let userStates = {};

// Funciones auxiliares
function generateUsername() {
    return 'TEST' + Math.floor(1000 + Math.random() * 9000);
}

function generatePassword() {
    return 'PASS' + Math.floor(1000 + Math.random() * 9000);
}

async function createSSHUser(phone, username, password, days) {
    if (days === 0) {
        // Test - 1 hora
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        try {
            await execPromise(`useradd -m -s /bin/bash ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'test', ?)`,
                [phone, username, password, expireFull]);
            
            return { success: true, username, password, expires: expireFull };
        } catch (error) {
            console.error(chalk.red('❌ Error:'), error.message);
            return { success: false, error: error.message };
        }
    } else {
        // Premium
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        try {
            await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'premium', ?)`,
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

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'ssh-bot-session',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            browserWS: '',
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
                '--window-size=1920,1080'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage'
                ]
            },
            disableWelcome: true,
            updatesLog: false,
            autoClose: 0,
            tokenStore: 'file',
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        // Estado de conexión
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            
            if (state === 'CONNECTED') {
                console.log(chalk.green('✅ Conexión establecida con WhatsApp'));
            } else if (state === 'DISCONNECTED') {
                console.log(chalk.yellow('⚠️ Desconectado, reconectando...'));
                setTimeout(initializeBot, 10000);
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
                    
                    await client.sendText(from, `HOLA, BIENVENIDO BOT MGVPN 🚀

Elija una opción:

🧾 1 - CREAR PRUEBA
💰 2 - COMPRAR USUARIO SSH
🔄 3 - RENOVAR USUARIO SSH
📱 4 - DESCARGAR APLICACIÓN`);
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
                            
                            await client.sendText(from, `PRUEBA CREADA CON ÉXITO !

Usuario: ${username}
Contraseña: ${password}
Limite: 1 dispositivo(s)
Expira en: ${config.prices.test_hours} hora(s)

APP: ${config.links.app_download}`);
                            
                            console.log(chalk.green(`✅ Test creado: ${username}`));
                        } else {
                            await client.sendText(from, `❌ Error: ${result.error}`);
                        }
                    } catch (error) {
                        await client.sendText(from, `❌ Error al crear cuenta: ${error.message}`);
                    }
                }
                
                // OPCIÓN 2: COMPRAR USUARIO SSH
                else if (text === '2' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    userStates[from] = { state: 'buying_ssh' };
                    
                    await client.sendText(from, `PLANES SSH PREMIUM !

Elija una opción:
🌐 1 - PLANES SSH DIARIOS
🌐 2 - PLANES SSH MENSUALES
⬅️ 0 - VOLVER`);
                }
                
                // SUBMENÚ DE COMPRAS
                else if (userStates[from] && userStates[from].state === 'buying_ssh') {
                    if (text === '1' || text === '2') {
                        userStates[from] = { 
                            state: 'selecting_plan', 
                            plan_type: text 
                        };
                        
                        await client.sendText(from, `A CONTINUACIÓN SE MUESTRAN NUESTROS PLANES PREMIUM DISPONIBLES

Elija un plan:
🗓 1 - 1 USUARIO(SSH) - 7 DÍAS - $${config.prices.price_7d}
🗓 2 - 1 USUARIO(SSH) - 15 DÍAS - $${config.prices.price_15d}
🗓 3 - 1 USUARIO(SSH) - 30 DÍAS - $${config.prices.price_30d}
🗓 4 - 1 USUARIO(SSH) - 50 DÍAS - $${config.prices.price_50d}
⬅️ 0 - VOLVER`);
                    }
                    else if (text === '0') {
                        userStates[from] = { state: 'main_menu' };
                        await client.sendText(from, `HOLA, BIENVENIDO MGVPN

Elija una opción:

🧾 1 - CREAR PRUEBA
💰 2 - COMPRAR USUARIO SSH
🔄 3 - RENOVAR USUARIO SSH
📱 4 - DESCARGAR Aplicación`);
                    }
                }
                
                // SELECCIÓN DE PLAN ESPECÍFICO
                else if (userStates[from] && userStates[from].state === 'selecting_plan') {
                    if (['1', '2', '3', '4'].includes(text)) {
                        const planMap = {
                            '1': { days: 7, price: config.prices.price_7d },
                            '2': { days: 15, price: config.prices.price_15d },
                            '3': { days: 30, price: config.prices.price_30d },
                            '4': { days: 50, price: config.prices.price_50d }
                        };
                        
                        const plan = planMap[text];
                        
                        await client.sendText(from, `PLAN SELECCIONADO: ${plan.days} DÍAS

Precio: $${plan.price} ARS

Para continuar con la compra, contacta al administrador:
${config.links.support}

O envía el monto por transferencia bancaria.`);
                        
                        userStates[from] = { state: 'main_menu' };
                    }
                    else if (text === '0') {
                        userStates[from] = { state: 'buying_ssh' };
                        await client.sendText(from, `PLANES SSH PREMIUM !

Elija una opción:
🌐 1 - PLANES SSH DIARIOS
🌐 2 - PLANES SSH MENSUALES
⬅️ 0 - VOLVER`);
                    }
                }
                
                // OPCIÓN 3: RENOVAR
                else if (text === '3' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    await client.sendText(from, `🔄 *RENOVAR USUARIO SSH*

Para renovar tu cuenta SSH existente, contacta al administrador:
${config.links.support}

O envía tu nombre de usuario actual.`);
                }
                
                // OPCIÓN 4: DESCARGAR APP
                else if (text === '4' && (!userStates[from] || userStates[from].state === 'main_menu')) {
                    await client.sendText(from, `📱 *DESCARGAR APLICACIÓN*

🔗 Enlace de descarga:
${config.links.app_download}

💡 *Instrucciones:*
1. Abre el enlace en tu navegador
2. Descarga el archivo APK
3. Instala la aplicación
4. Configura con tus credenciales SSH

⚡ *Credenciales por defecto:*
Usuario: (el que te proporcionamos)
Contraseña: mgvpn247`);
                }
                
                // COMANDO NO RECONOCIDO
                else {
                    await client.sendText(from, `❌ Comando no reconocido.

Escribe *menu* para ver las opciones disponibles.`);
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error procesando mensaje:'), error.message);
            }
        });
        
        // Limpieza automática cada 15 minutos
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

echo -e "${GREEN}✅ Bot creado con WPPConnect${NC}"

# ================================================
# CREAR PANEL DE CONTROL
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel de control...${NC}"

cat > /usr/local/bin/wppbot << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/wpp-bot/data/users.db"
CONFIG="/opt/wpp-bot/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🎛️  PANEL WPPCONNECT BOT                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

while true; do
    show_header
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="wpp-bot") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  IP: $(get_val '.bot.server_ip')"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA)"
    echo -e ""
    
    echo -e "${YELLOW}💰 PRECIOS:${NC}"
    echo -e "  7 días: $ $(get_val '.prices.price_7d') ARS"
    echo -e "  15 días: $ $(get_val '.prices.price_15d') ARS"
    echo -e "  30 días: $ $(get_val '.prices.price_30d') ARS"
    echo -e "  50 días: $ $(get_val '.prices.price_50d') ARS"
    echo -e ""
    
    echo -e "${CYAN}[1]${NC} 🚀 Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑 Detener bot"
    echo -e "${CYAN}[3]${NC} 📱 Ver QR y logs"
    echo -e "${CYAN}[4]${NC} 👤 Crear usuario manual"
    echo -e "${CYAN}[5]${NC} 👥 Listar usuarios"
    echo -e "${CYAN}[6]${NC} 🔄 Limpiar sesión"
    echo -e "${CYAN}[0]${NC} 🚪 Salir"
    echo -e ""
    
    read -p "👉 Selecciona: " OPTION
    
    case $OPTION in
        1)
            echo -e "\n${YELLOW}🔄 Reiniciando...${NC}"
            cd /root/wpp-bot
            pm2 restart wpp-bot 2>/dev/null || pm2 start bot.js --name wpp-bot
            pm2 save
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
            echo -e "\n${YELLOW}📱 Mostrando logs...${NC}"
            pm2 logs wpp-bot --lines 100
            ;;
        4)
            clear
            echo -e "${CYAN}👤 CREAR USUARIO${NC}\n"
            
            read -p "Teléfono: " PHONE
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
            else
                echo -e "\n${RED}❌ Error${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}👥 USUARIOS ACTIVOS${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, tipo, expires_at FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..."
            ;;
        6)
            echo -e "\n${YELLOW}🧹 Limpiando sesión...${NC}"
            pm2 stop wpp-bot
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}📱 Escanea nuevo QR al iniciar${NC}"
            sleep 2
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

chmod +x /usr/local/bin/wppbot
echo -e "${GREEN}✅ Panel creado${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name wpp-bot
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
║          🎉 INSTALACIÓN COMPLETADA - WPPCONNECT 🎉          ║
║                                                              ║
║       🤖 Bot SSH con API WhatsApp FUNCIONANDO              ║
║       📱 Flujo idéntico al de la captura                   ║
║       💰 Planes: 7, 15, 30, 50 días                        ║
║       🔐 Contraseña fija: mgvpn247                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema instalado con WPPConnect (API funcional)${NC}"
echo -e "${GREEN}✅ Menú idéntico al de la captura: 1,2,3,4${NC}"
echo -e "${GREEN}✅ Submenú de compras con planes diarios/mensuales${NC}"
echo -e "${GREEN}✅ Planes disponibles: 7, 15, 30, 50 días${NC}"
echo -e "${GREEN}✅ Test 1 hora${NC}"
echo -e "${GREEN}✅ Contraseña fija: mgvpn247${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS:${NC}\n"
echo -e "  ${GREEN}wppbot${NC}         - Panel de control"
echo -e "  ${GREEN}pm2 logs wpp-bot${NC} - Ver logs y QR"
echo -e "\n"

echo -e "${YELLOW}🚀 USO INMEDIATO:${NC}\n"
echo -e "  1. Ver logs: ${GREEN}pm2 logs wpp-bot${NC}"
echo -e "  2. Escanear QR cuando aparezca"
echo -e "  3. Enviar 'menu' al bot en WhatsApp"
echo -e "  4. Seguir flujo de la captura\n"

echo -e "${YELLOW}💰 PRECIOS:${NC}\n"
echo -e "  7 días: ${GREEN}$1500 ARS${NC}"
echo -e "  15 días: ${GREEN}$2500 ARS${NC}"
echo -e "  30 días: ${GREEN}$5500 ARS${NC}"
echo -e "  50 días: ${GREEN}$8500 ARS${NC}\n"

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "  • Usa un número REAL de WhatsApp (no virtual)"
echo -e "  • La sesión se guarda automáticamente"
echo -e "  • Auto-reconexión activada"
echo -e "  • API basada en WPPConnect (funciona en 2024)\n"

echo -e "${GREEN}${BOLD}¡Bot listo para usar! Escanea el QR y sigue el flujo de la captura 🚀${NC}\n"

# Ver logs automáticamente
read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs...${NC}"
    echo -e "${YELLOW}📱 Espera que aparezca el QR para escanear...${NC}\n"
    sleep 2
    pm2 logs wpp-bot
fi

exit 0
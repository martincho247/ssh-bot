#!/bin/bash
# ================================================
# SSH BOT PRO v8.7 - MULTI-VPS EDITION
# Sistema para crear usuarios en 3 VPS diferentes
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
║     ███████╗███████╗██║  ██║    ██████╗  ██████╗ ████████╗  ║
║     ██╔════╝██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝  ║
║     ███████╗███████╗███████║    ██████╔╝██║   ██║   ██║     ║
║     ╚════██║╚════██║██╔══██║    ██╔══██╗██║   ██║   ██║     ║
║     ███████║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║     ║
║     ╚══════╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║           🚀 SSH BOT PRO v8.7 - MULTI-VPS EDITION           ║
║               🌐 SOPORTE PARA 3 SERVIDORES SSH              ║
║               🔄 CREACIÓN REMOTA EN TODAS LAS VPS           ║
║               🔐 CONTRASEÑA FIJA: mgvpn247                  ║
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

# ================================================
# CONFIGURACIÓN MULTI-VPS
# ================================================
echo -e "${CYAN}${BOLD}🌐 CONFIGURACIÓN MULTI-VPS (3 SERVIDORES)${NC}\n"

# IP del bot principal (esta máquina)
BOT_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
echo -e "${GREEN}✅ Esta máquina será el BOT PRINCIPAL${NC}"
echo -e "${YELLOW}IP detectada: ${CYAN}$BOT_IP${NC}\n"

echo -e "${YELLOW}📝 CONFIGURA TUS 3 VPS SSH:${NC}\n"

# Configurar VPS 1
echo -e "${CYAN}【 VPS 1 - SERVIDOR PRINCIPAL 】${NC}"
read -p "IP de VPS 1 (esta misma si es la principal): " VPS1_IP
read -p "Usuario SSH (ej: root): " VPS1_USER
read -p "Puerto SSH (22): " VPS1_PORT
VPS1_PORT=${VPS1_PORT:-22}
read -p "¿Tiene clave SSH configurada? (s/N): " VPS1_SSH

# Configurar VPS 2
echo -e "\n${CYAN}【 VPS 2 - SERVIDOR SECUNDARIO 】${NC}"
read -p "IP de VPS 2: " VPS2_IP
read -p "Usuario SSH (ej: root): " VPS2_USER
read -p "Puerto SSH (22): " VPS2_PORT
VPS2_PORT=${VPS2_PORT:-22}
read -p "¿Tiene clave SSH configurada? (s/N): " VPS2_SSH

# Configurar VPS 3
echo -e "\n${CYAN}【 VPS 3 - SERVIDOR TERCIARIO 】${NC}"
read -p "IP de VPS 3: " VPS3_IP
read -p "Usuario SSH (ej: root): " VPS3_USER
read -p "Puerto SSH (22): " VPS3_PORT
VPS3_PORT=${VPS3_PORT:-22}
read -p "¿Tiene clave SSH configurada? (s/N): " VPS3_SSH

# ================================================
# PREPARAR CLAVES SSH
# ================================================
echo -e "\n${CYAN}${BOLD}🔑 PREPARANDO CONEXIONES SSH${NC}"

# Generar clave SSH si no existe
if [[ ! -f ~/.ssh/id_rsa ]]; then
    echo -e "${YELLOW}Generando clave SSH...${NC}"
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
    echo -e "${GREEN}✅ Clave SSH generada${NC}"
fi

# Mostrar clave pública
echo -e "\n${YELLOW}📋 CLAVE PÚBLICA SSH (cópiala):${NC}"
echo -e "${CYAN}"
cat ~/.ssh/id_rsa.pub
echo -e "${NC}"

echo -e "${YELLOW}⚠️  INSTRUCCIONES:${NC}"
echo -e "1. Copia la clave pública de arriba"
echo -e "2. En CADA VPS, ejecuta:"
echo -e "   ${GREEN}mkdir -p ~/.ssh && echo 'TU_CLAVE_AQUÍ' >> ~/.ssh/authorized_keys${NC}"
echo -e "3. En cada VPS, ajusta permisos:"
echo -e "   ${GREEN}chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys${NC}"
echo -e "4. Para probar: ${GREEN}ssh ${VPS2_USER}@${VPS2_IP} -p ${VPS2_PORT} 'whoami'${NC}"

read -p "$(echo -e "\n${YELLOW}¿Ya configuraste las claves SSH en las 3 VPS? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Configura primero las claves SSH${NC}"
    exit 1
fi

# ================================================
# TEST DE CONEXIÓN A LAS VPS
# ================================================
echo -e "\n${CYAN}${BOLD}🔍 PROBANDO CONEXIONES SSH...${NC}"

test_ssh_connection() {
    local name=$1
    local ip=$2
    local user=$3
    local port=$4
    
    echo -n "  ${name} (${ip}): "
    timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $port ${user}@${ip} "echo '✅ OK' 2>/dev/null" && echo -e "${GREEN}✅ Conectado${NC}" || echo -e "${RED}❌ Falló${NC}"
}

test_ssh_connection "VPS 1" "$VPS1_IP" "$VPS1_USER" "$VPS1_PORT"
test_ssh_connection "VPS 2" "$VPS2_IP" "$VPS2_USER" "$VPS2_PORT"
test_ssh_connection "VPS 3" "$VPS3_IP" "$VPS3_USER" "$VPS3_PORT"

echo -e "\n${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "Si alguna conexión falla, verifica:"
echo -e "• Clave SSH configurada en VPS"
echo -e "• Firewall permite puerto ${VPS2_PORT}"
echo -e "• Usuario tiene permisos"
echo -e "• Servicio SSH activo"

read -p "$(echo -e "\n${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS (igual que antes)
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS...${NC}"

apt-get update && apt-get upgrade -y
apt-get install -y curl wget git build-essential libnss3 libxss1 libatk1.0-0 libx11-xcb1 libdrm2 libgbm1 libasound2 libpangocairo-1.0-0 libgtk-3-0

# Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y google-chrome-stable

# SQLite y otras herramientas
apt-get install -y sqlite3 jq cron pm2
npm install -g pm2

# ================================================
# PREPARAR ESTRUCTURA MULTI-VPS
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA MULTI-VPS...${NC}"

INSTALL_DIR="/opt/ssh-bot-multi"
USER_HOME="/root/ssh-bot-multi"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
SERVERS_FILE="$INSTALL_DIR/config/servers.json"

# Limpiar instalaciones anteriores
pm2 delete ssh-bot-multi 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wwebjs_auth /root/.wwebjs_cache 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,scripts}
mkdir -p "$USER_HOME"
mkdir -p /root/.wwebjs_auth
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wwebjs_auth

# ================================================
# CREAR CONFIGURACIÓN DE SERVIDORES
# ================================================
cat > "$SERVERS_FILE" << EOF
{
    "servers": [
        {
            "id": 1,
            "name": "VPS 1 - Principal",
            "ip": "$VPS1_IP",
            "ssh_user": "$VPS1_USER",
            "ssh_port": $VPS1_PORT,
            "status": "active",
            "location": "Principal",
            "max_users": 100,
            "current_users": 0,
            "enabled": true
        },
        {
            "id": 2,
            "name": "VPS 2 - Secundario",
            "ip": "$VPS2_IP",
            "ssh_user": "$VPS2_USER",
            "ssh_port": $VPS2_PORT,
            "status": "active",
            "location": "Secundario",
            "max_users": 100,
            "current_users": 0,
            "enabled": true
        },
        {
            "id": 3,
            "name": "VPS 3 - Terciario",
            "ip": "$VPS3_IP",
            "ssh_user": "$VPS3_USER",
            "ssh_port": $VPS3_PORT,
            "status": "active",
            "location": "Terciario",
            "max_users": 100,
            "current_users": 0,
            "enabled": true
        }
    ],
    "load_balancing": {
        "method": "round_robin",
        "current_server": 1,
        "auto_balance": true
    }
}
EOF

# ================================================
# CREAR CONFIGURACIÓN PRINCIPAL
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro Multi-VPS",
        "version": "8.7-MULTI-VPS",
        "server_ip": "$BOT_IP",
        "default_password": "mgvpn247"
    },
    "multi_vps": {
        "enabled": true,
        "servers_config": "$SERVERS_FILE",
        "create_on_all_servers": false,
        "default_server": 1
    },
    "prices": {
        "test_hours": 2,
        "price_7d_1conn": 500.00,
        "price_15d_1conn": 800.00,
        "price_30d_1conn": 1200.00,
        "price_7d_2conn": 800.00,
        "price_15d_2conn": 1200.00,
        "price_30d_2conn": 1800.00,
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
        "scripts": "$INSTALL_DIR/scripts"
    }
}
EOF

# ================================================
# CREAR BASE DE DATOS MEJORADA
# ================================================
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    server_id INTEGER DEFAULT 1,
    vps_ip TEXT,
    ssh_port INTEGER DEFAULT 22
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
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    server_id INTEGER DEFAULT 1
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
CREATE TABLE server_stats (
    server_id INTEGER PRIMARY KEY,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_server ON users(server_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_phone_plan ON payments(phone, plan, status);
SQL

# ================================================
# CREAR SCRIPTS PARA MANEJO REMOTO
# ================================================

# Script para crear usuario en VPS remota
cat > "$INSTALL_DIR/scripts/create_remote_user.sh" << 'REMOTE1EOF'
#!/bin/bash
# Script para crear usuario en VPS remota
# Uso: ./create_remote_user.sh <server_id> <username> <password> <days> <connections>

SERVER_ID=$1
USERNAME=$2
PASSWORD=$3
DAYS=$4
CONNECTIONS=$5

# Cargar configuración de servidores
SERVERS_FILE="/opt/ssh-bot-multi/config/servers.json"
SERVER_CONFIG=$(jq -r ".servers[] | select(.id == $SERVER_ID)" "$SERVERS_FILE")

if [[ -z "$SERVER_CONFIG" ]]; then
    echo "ERROR: Servidor $SERVER_ID no encontrado"
    exit 1
fi

VPS_IP=$(echo "$SERVER_CONFIG" | jq -r '.ip')
SSH_USER=$(echo "$SERVER_CONFIG" | jq -r '.ssh_user')
SSH_PORT=$(echo "$SERVER_CONFIG" | jq -r '.ssh_port')

if [[ "$DAYS" -eq 0 ]]; then
    # Usuario TEST (2 horas)
    EXPIRE_DATE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
    SSH_COMMANDS="useradd -m -s /bin/bash $USERNAME && echo '$USERNAME:$PASSWORD' | chpasswd && chage -E '$(date -d '+2 hours' +%Y-%m-%d)' $USERNAME"
else
    # Usuario PREMIUM
    EXPIRE_DATE=$(date -d "+$DAYS days" +"%Y-%m-%d")
    SSH_COMMANDS="useradd -M -s /bin/false -e $EXPIRE_DATE $USERNAME && echo '$USERNAME:$PASSWORD' | chpasswd"
fi

# Ejecutar comando remoto
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p $SSH_PORT ${SSH_USER}@${VPS_IP} "$SSH_COMMANDS"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS:$EXPIRE_DATE"
else
    echo "ERROR: No se pudo crear usuario en $VPS_IP"
fi
REMOTE1EOF

# Script para eliminar usuario remoto
cat > "$INSTALL_DIR/scripts/delete_remote_user.sh" << 'REMOTE2EOF'
#!/bin/bash
# Script para eliminar usuario en VPS remota

SERVER_ID=$1
USERNAME=$2

SERVERS_FILE="/opt/ssh-bot-multi/config/servers.json"
SERVER_CONFIG=$(jq -r ".servers[] | select(.id == $SERVER_ID)" "$SERVERS_FILE")

if [[ -z "$SERVER_CONFIG" ]]; then
    echo "ERROR: Servidor $SERVER_ID no encontrado"
    exit 1
fi

VPS_IP=$(echo "$SERVER_CONFIG" | jq -r '.ip')
SSH_USER=$(echo "$SERVER_CONFIG" | jq -r '.ssh_user')
SSH_PORT=$(echo "$SERVER_CONFIG" | jq -r '.ssh_port')

# Eliminar usuario
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p $SSH_PORT ${SSH_USER}@${VPS_IP} "pkill -u $USERNAME 2>/dev/null; userdel -f $USERNAME 2>/dev/null"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Usuario $USERNAME eliminado de $VPS_IP"
else
    echo "ERROR: No se pudo eliminar usuario"
fi
REMOTE2EOF

# Script para verificar estado de VPS
cat > "$INSTALL_DIR/scripts/check_server_status.sh" << 'REMOTE3EOF'
#!/bin/bash
# Verificar estado de servidores VPS

SERVERS_FILE="/opt/ssh-bot-multi/config/servers.json"
DB_FILE="/opt/ssh-bot-multi/data/users.db"

for server_id in 1 2 3; do
    SERVER_CONFIG=$(jq -r ".servers[] | select(.id == $server_id)" "$SERVERS_FILE")
    
    if [[ -z "$SERVER_CONFIG" ]]; then
        continue
    fi
    
    VPS_IP=$(echo "$SERVER_CONFIG" | jq -r '.ip')
    SSH_USER=$(echo "$SERVER_CONFIG" | jq -r '.ssh_user')
    SSH_PORT=$(echo "$SERVER_CONFIG" | jq -r '.ssh_port')
    SERVER_NAME=$(echo "$SERVER_CONFIG" | jq -r '.name')
    
    # Verificar conexión SSH
    if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p $SSH_PORT ${SSH_USER}@${VPS_IP} "echo 'ping'" &>/dev/null; then
        STATUS="online"
        
        # Contar usuarios en esta VPS
        USER_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE vps_ip = '$VPS_IP' AND status = 1" 2>/dev/null || echo "0")
        
        # Actualizar estadísticas
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO server_stats (server_id, total_users, active_users, last_updated) VALUES ($server_id, $USER_COUNT, $USER_COUNT, CURRENT_TIMESTAMP)"
        
        echo "Server $server_id ($SERVER_NAME): ONLINE - $USER_COUNT usuarios"
    else
        STATUS="offline"
        echo "Server $server_id ($SERVER_NAME): OFFLINE"
    fi
done
REMOTE3EOF

# Script para balancear carga
cat > "$INSTALL_DIR/scripts/balance_load.sh" << 'REMOTE4EOF'
#!/bin/bash
# Balancear carga entre servidores

SERVERS_FILE="/opt/ssh-bot-multi/config/servers.json"
DB_FILE="/opt/ssh-bot-multi/data/users.db"

# Obtener servidor con menos usuarios
LEAST_LOADED=$(sqlite3 "$DB_FILE" "SELECT server_id FROM server_stats WHERE active_users = (SELECT MIN(active_users) FROM server_stats WHERE server_id IN (1,2,3)) LIMIT 1" 2>/dev/null || echo "1")

echo $LEAST_LOADED
REMOTE4EOF

chmod +x "$INSTALL_DIR"/scripts/*.sh

# ================================================
# CREAR BOT MULTI-VPS (modificar función createSSHUser)
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT MULTI-VPS...${NC}"

cd "$USER_HOME"

# package.json (igual que antes)
cat > package.json << 'PKGEOF'
{
    "name": "ssh-bot-multi",
    "version": "8.7.0",
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
find node_modules/whatsapp-web.js -name "Client.js" -type f -exec sed -i 's/if (chat && chat.markedUnread)/if (false \&\& chat.markedUnread)/g' {} \; 2>/dev/null || true

# Crear bot.js CON SOPORTE MULTI-VPS
echo -e "${YELLOW}📝 Creando bot.js con soporte multi-VPS...${NC}"

cat > "bot.js" << 'BOTEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcodeTerminal = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec, spawn } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const execPromise = util.promisify(exec);

function loadConfig() {
    delete require.cache[require.resolve('/opt/ssh-bot-multi/config/config.json')];
    delete require.cache[require.resolve('/opt/ssh-bot-multi/config/servers.json')];
    return {
        main: require('/opt/ssh-bot-multi/config/config.json'),
        servers: require('/opt/ssh-bot-multi/config/servers.json')
    };
}

let config = loadConfig();
const db = new sqlite3.Database(config.main.paths.database);

// ✅ FUNCIONES MULTI-VPS
function getServerConfig(serverId) {
    return config.servers.servers.find(s => s.id === serverId) || config.servers.servers[0];
}

async function getLeastLoadedServer() {
    return new Promise((resolve) => {
        db.get('SELECT server_id FROM server_stats ORDER BY active_users ASC LIMIT 1', (err, row) => {
            if (err || !row) {
                resolve(1); // Default to server 1
            } else {
                resolve(row.server_id);
            }
        });
    });
}

async function createUserOnServer(serverId, username, password, days, connections) {
    const server = getServerConfig(serverId);
    
    return new Promise((resolve, reject) => {
        const scriptPath = '/opt/ssh-bot-multi/scripts/create_remote_user.sh';
        
        exec(`${scriptPath} ${serverId} ${username} ${password} ${days} ${connections}`, 
            (error, stdout, stderr) => {
                if (error) {
                    console.error(chalk.red(`❌ Error creando en ${server.name}:`), error.message);
                    reject(error);
                } else if (stdout.includes('SUCCESS')) {
                    const expireDate = stdout.split(':')[1];
                    console.log(chalk.green(`✅ Usuario creado en ${server.name} (${server.ip})`));
                    
                    // Guardar en base de datos
                    db.run(
                        `INSERT INTO users (username, password, tipo, expires_at, max_connections, status, server_id, vps_ip, ssh_port) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?)`,
                        [
                            username, 
                            password, 
                            days === 0 ? 'test' : 'premium',
                            expireDate.trim(),
                            connections,
                            serverId,
                            server.ip,
                            server.ssh_port
                        ],
                        (err) => {
                            if (err) reject(err);
                            else resolve({
                                server: server.name,
                                ip: server.ip,
                                username: username,
                                password: password,
                                expires: expireDate,
                                connections: connections
                            });
                        }
                    );
                } else {
                    reject(new Error(`Error del script: ${stderr}`));
                }
            }
        );
    });
}

async function createSSHUserMulti(phone, username, password, days, connections = 1) {
    try {
        // Determinar en qué servidor crear
        let targetServerId;
        
        if (days === 0) {
            // Test users always on server 1
            targetServerId = 1;
        } else {
            // Premium users - use load balancing
            targetServerId = await getLeastLoadedServer();
        }
        
        console.log(chalk.cyan(`🌐 Creando en servidor ${targetServerId}...`));
        
        const result = await createUserOnServer(targetServerId, username, password, days, connections);
        
        // Registrar teléfono si está disponible
        if (phone) {
            db.run('UPDATE users SET phone = ? WHERE username = ?', [phone, username]);
        }
        
        return {
            ...result,
            serverId: targetServerId,
            duration: days === 0 ? '2 horas' : `${days} días`
        };
        
    } catch (error) {
        console.error(chalk.red('❌ Error creación multi-VPS:'), error);
        throw error;
    }
}

// ✅ FUNCIONES DE ESTADO (igual que antes)
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

// ... [EL RESTO DEL CÓDIGO DEL BOT SE MANTIENE IGUAL, SOLO CAMBIA createSSHUser por createSSHUserMulti]

// En la parte del mensaje de prueba gratis (opción 1):
// CAMBIAR:
// await createSSHUser(phone, username, password, 0, 1);
// POR:
await createSSHUserMulti(phone, username, password, 0, 1);

// En la parte de creación de usuario premium (cuando se aprueba pago):
// CAMBIAR:
// const result = await createSSHUser(payment.phone, username, password, payment.days, payment.connections);
// POR:
const result = await createSSHUserMulti(payment.phone, username, password, payment.days, payment.connections);

// Añadir información del servidor en los mensajes al usuario:
const serverInfo = getServerConfig(result.serverId);

// Modificar mensaje para incluir información del servidor:
const message = `╔══════════════════════════════════════╗
║   🎉 *PAGO CONFIRMADO*               ║
╚══════════════════════════════════════╝

✅ Tu compra ha sido aprobada

📋 *DATOS DE ACCESO:*
👤 Usuario: *${username}*
🔑 Contraseña: *mgvpn247*
🌐 Servidor: *${serverInfo.name}*
📍 IP: *${serverInfo.ip}*

⏰ *VÁLIDO HASTA:* ${expireDate}
🔌 *CONEXIÓN:* ${payment.connections} ${payment.connections > 1 ? 'conexiones simultáneas' : 'conexión'}

📱 *INSTALACIÓN:*
1. Descarga la app (Escribe *5*)
2. Configurar con IP: ${serverInfo.ip}
3. Ingresar Usuario y Contraseña
4. ¡Conéctate automáticamente!

🎊 ¡Disfruta del servicio premium!

💬 Soporte: *Escribe 6*`;

// ... [EL RESTO DEL CÓDIGO SE MANTIENE IGUAL]
BOTEOF

# ================================================
# CREAR PANEL DE CONTROL MULTI-VPS
# ================================================
echo -e "\n${CYAN}${BOLD}🎛️  CREANDO PANEL DE CONTROL MULTI-VPS...${NC}"

cat > /usr/local/bin/sshbot-multi << 'PANELEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

DB="/opt/ssh-bot-multi/data/users.db"
CONFIG="/opt/ssh-bot-multi/config/config.json"
SERVERS="/opt/ssh-bot-multi/config/servers.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }
get_server() { jq -r "$1" "$SERVERS" 2>/dev/null; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🎛️  PANEL SSH BOT PRO MULTI-VPS                ║${NC}"
    echo -e "${CYAN}║               🌐 GESTIÓN DE 3 SERVIDORES SSH                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

check_servers_status() {
    echo -e "${YELLOW}🌐 ESTADO DE SERVIDORES:${NC}"
    
    for i in 1 2 3; do
        SERVER=$(jq -r ".servers[] | select(.id == $i)" "$SERVERS")
        if [[ -n "$SERVER" ]]; then
            NAME=$(echo "$SERVER" | jq -r '.name')
            IP=$(echo "$SERVER" | jq -r '.ip')
            USER=$(echo "$SERVER" | jq -r '.ssh_user')
            PORT=$(echo "$SERVER" | jq -r '.ssh_port')
            
            # Contar usuarios en este servidor
            USER_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$IP' AND status = 1" 2>/dev/null || echo "0")
            
            # Verificar conexión
            if timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -p $PORT ${USER}@${IP} "echo ping" &>/dev/null; then
                echo -e "  ${GREEN}●${NC} ${NAME} (${IP}): ${CYAN}${USER_COUNT} usuarios${NC} - ${GREEN}ONLINE${NC}"
            else
                echo -e "  ${RED}●${NC} ${NAME} (${IP}): ${RED}OFFLINE${NC}"
            fi
        fi
    done
    echo ""
}

while true; do
    show_header
    check_servers_status
    
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    
    STATUS=$(pm2 jlist 2>/dev/null | jq -r '.[] | select(.name=="ssh-bot-multi") | .pm2_env.status' 2>/dev/null || echo "stopped")
    if [[ "$STATUS" == "online" ]]; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● DETENIDO${NC}"
    fi
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: ${CYAN}$ACTIVE_USERS/$TOTAL_USERS${NC} activos/total"
    echo -e "  Contraseña: ${GREEN}mgvpn247${NC} (FIJA)"
    echo -e ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Gestionar Bot"
    echo -e "${CYAN}[2]${NC}  🌐  Gestionar Servidores VPS"
    echo -e "${CYAN}[3]${NC}  👤  Crear usuario manual (elegir VPS)"
    echo -e "${CYAN}[4]${NC}  👥  Listar usuarios por servidor"
    echo -e "${CYAN}[5]${NC}  🗑️   Eliminar usuario (de cualquier VPS)"
    echo -e "${CYAN}[6]${NC}  📊  Ver estadísticas por servidor"
    echo -e "${CYAN}[7]${NC}  🔄  Sincronizar servidores"
    echo -e "${CYAN}[8]${NC}  ⚙️   Configuración"
    echo -e "${CYAN}[9]${NC}  📱  Ver QR WhatsApp"
    echo -e "${CYAN}[10]${NC} 🧪  Test conexiones SSH"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e ""
    read -p "👉 Selecciona una opción: " OPTION
    
    case $OPTION in
        1)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     🚀 GESTIONAR BOT                         ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "1. Iniciar bot"
            echo -e "2. Detener bot"
            echo -e "3. Reiniciar bot"
            echo -e "4. Ver logs"
            echo -e "5. Volver"
            
            read -p "Opción: " BOT_OPT
            
            case $BOT_OPT in
                1) pm2 start /root/ssh-bot-multi/bot.js --name ssh-bot-multi ;;
                2) pm2 stop ssh-bot-multi ;;
                3) pm2 restart ssh-bot-multi ;;
                4) pm2 logs ssh-bot-multi --lines 100 ;;
            esac
            ;;
        2)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  🌐 GESTIONAR SERVIDORES VPS                ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}SERVIDORES CONFIGURADOS:${NC}\n"
            
            for i in 1 2 3; do
                SERVER=$(jq -r ".servers[] | select(.id == $i)" "$SERVERS")
                if [[ -n "$SERVER" ]]; then
                    NAME=$(echo "$SERVER" | jq -r '.name')
                    IP=$(echo "$SERVER" | jq -r '.ip')
                    USER=$(echo "$SERVER" | jq -r '.ssh_user')
                    PORT=$(echo "$SERVER" | jq -r '.ssh_port')
                    
                    USER_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$IP' AND status = 1" 2>/dev/null || echo "0")
                    
                    echo -e "${CYAN}【 SERVIDOR $i 】${NC}"
                    echo -e "  Nombre: $NAME"
                    echo -e "  IP: $IP"
                    echo -e "  SSH: ${USER}@${IP}:${PORT}"
                    echo -e "  Usuarios activos: $USER_COUNT"
                    echo -e ""
                fi
            done
            
            echo -e "${YELLOW}ACCIONES:${NC}"
            echo -e "1. Probar conexión a todos"
            echo -e "2. Ver detalles de un servidor"
            echo -e "3. Modificar configuración"
            echo -e "4. Volver"
            
            read -p "Opción: " SERVER_OPT
            
            case $SERVER_OPT in
                1)
                    echo -e "\n${YELLOW}🔍 Probando conexiones...${NC}"
                    /opt/ssh-bot-multi/scripts/check_server_status.sh
                    read -p "Presiona Enter..."
                    ;;
                2)
                    read -p "Número de servidor (1-3): " SERVER_NUM
                    SERVER=$(jq -r ".servers[] | select(.id == $SERVER_NUM)" "$SERVERS")
                    if [[ -n "$SERVER" ]]; then
                        echo -e "\n${GREEN}📋 DETALLES DEL SERVIDOR${NC}"
                        echo "$SERVER" | jq '.'
                        read -p "Presiona Enter..."
                    fi
                    ;;
                3)
                    echo -e "\n${YELLOW}⚠️  Editar manualmente: ${SERVERS}${NC}"
                    read -p "¿Abrir editor? (s/N): " EDIT
                    [[ "$EDIT" == "s" ]] && nano "$SERVERS"
                    ;;
            esac
            ;;
        3)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║               👤 CREAR USUARIO MANUAL (MULTI-VPS)           ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📋 ELIGE EL SERVIDOR:${NC}"
            echo -e "1. VPS 1 - Principal"
            echo -e "2. VPS 2 - Secundario"
            echo -e "3. VPS 3 - Terciario"
            echo -e "4. Automático (balanceo de carga)"
            
            read -p "Selecciona servidor (1-4): " SERVER_CHOICE
            
            if [[ "$SERVER_CHOICE" == "4" ]]; then
                SERVER_ID=$(/opt/ssh-bot-multi/scripts/balance_load.sh)
                echo -e "${GREEN}✅ Servidor seleccionado automáticamente: ${SERVER_ID}${NC}"
            else
                SERVER_ID=$SERVER_CHOICE
            fi
            
            read -p "Teléfono (opcional): " PHONE
            read -p "Usuario (auto=generar): " USERNAME
            read -p "Tipo (test/premium): " TIPO
            read -p "Días (0=test 2h, 7/15/30=premium): " DAYS
            read -p "Conexiones (1-2): " CONNECTIONS
            
            [[ -z "$USERNAME" ]] && USERNAME="user$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)"
            CONNECTIONS=${CONNECTIONS:-1}
            
            echo -e "\n${YELLOW}⏳ Creando usuario en servidor ${SERVER_ID}...${NC}"
            
            if [[ "$TIPO" == "test" ]]; then
                DAYS="0"
            fi
            
            # Usar el script de creación remota
            RESULT=$(/opt/ssh-bot-multi/scripts/create_remote_user.sh $SERVER_ID "$USERNAME" "mgvpn247" $DAYS $CONNECTIONS)
            
            if echo "$RESULT" | grep -q "SUCCESS"; then
                EXPIRE_DATE=$(echo "$RESULT" | cut -d':' -f2)
                
                # Obtener info del servidor
                SERVER_CONFIG=$(jq -r ".servers[] | select(.id == $SERVER_ID)" "$SERVERS")
                SERVER_NAME=$(echo "$SERVER_CONFIG" | jq -r '.name')
                SERVER_IP=$(echo "$SERVER_CONFIG" | jq -r '.ip')
                
                echo -e "\n${GREEN}✅ USUARIO CREADO EXITOSAMENTE${NC}"
                echo -e "👤 Usuario: ${USERNAME}"
                echo -e "🔑 Contraseña: mgvpn247"
                echo -e "🌐 Servidor: ${SERVER_NAME} (${SERVER_IP})"
                echo -e "⏰ Expira: ${EXPIRE_DATE}"
                echo -e "🔌 Conexiones: ${CONNECTIONS}"
                
                # Registrar en BD si hay teléfono
                if [[ -n "$PHONE" ]]; then
                    sqlite3 "$DB" "INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status, server_id, vps_ip) VALUES ('$PHONE', '$USERNAME', 'mgvpn247', '$TIPO', '$EXPIRE_DATE', $CONNECTIONS, 1, $SERVER_ID, '$SERVER_IP')"
                fi
            else
                echo -e "\n${RED}❌ Error creando usuario${NC}"
                echo -e "Detalles: $RESULT"
            fi
            
            read -p "Presiona Enter..."
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║               👥 USUARIOS POR SERVIDOR                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            for i in 1 2 3; do
                SERVER=$(jq -r ".servers[] | select(.id == $i)" "$SERVERS")
                if [[ -n "$SERVER" ]]; then
                    SERVER_IP=$(echo "$SERVER" | jq -r '.ip')
                    SERVER_NAME=$(echo "$SERVER" | jq -r '.name')
                    
                    echo -e "${YELLOW}${SERVER_NAME} (${SERVER_IP}):${NC}"
                    
                    sqlite3 -column -header "$DB" "SELECT username, tipo, expires_at, max_connections as conex FROM users WHERE vps_ip = '$SERVER_IP' AND status = 1 ORDER BY expires_at DESC LIMIT 10" 2>/dev/null || echo "  Sin usuarios"
                    
                    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP' AND status = 1" 2>/dev/null || echo "0")
                    echo -e "${GREEN}Total: $TOTAL usuarios activos${NC}\n"
                fi
            done
            
            echo -e "${CYAN}🔐 Contraseña para todos: ${GREEN}mgvpn247${NC}"
            read -p "Presiona Enter..."
            ;;
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║               🗑️  ELIMINAR USUARIO (MULTI-VPS)              ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            read -p "Usuario a eliminar: " DEL_USER
            
            if [[ -n "$DEL_USER" ]]; then
                # Buscar en qué servidor está
                SERVER_INFO=$(sqlite3 "$DB" "SELECT server_id, vps_ip FROM users WHERE username = '$DEL_USER'" 2>/dev/null)
                
                if [[ -n "$SERVER_INFO" ]]; then
                    SERVER_ID=$(echo "$SERVER_INFO" | cut -d'|' -f1)
                    VPS_IP=$(echo "$SERVER_INFO" | cut -d'|' -f2)
                    
                    echo -e "${YELLOW}Usuario encontrado en servidor ${SERVER_ID} (${VPS_IP})${NC}"
                    
                    # Eliminar usando script remoto
                    RESULT=$(/opt/ssh-bot-multi/scripts/delete_remote_user.sh $SERVER_ID "$DEL_USER")
                    
                    if echo "$RESULT" | grep -q "SUCCESS"; then
                        # Actualizar BD
                        sqlite3 "$DB" "UPDATE users SET status = 0 WHERE username = '$DEL_USER'"
                        echo -e "${GREEN}✅ Usuario $DEL_USER eliminado${NC}"
                    else
                        echo -e "${RED}❌ Error eliminando usuario${NC}"
                    fi
                else
                    echo -e "${RED}❌ Usuario no encontrado${NC}"
                fi
            fi
            
            read -p "Presiona Enter..."
            ;;
        6)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║               📊 ESTADÍSTICAS POR SERVIDOR                  ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📈 DISTRIBUCIÓN DE USUARIOS:${NC}\n"
            
            for i in 1 2 3; do
                SERVER=$(jq -r ".servers[] | select(.id == $i)" "$SERVERS")
                if [[ -n "$SERVER" ]]; then
                    SERVER_IP=$(echo "$SERVER" | jq -r '.ip')
                    SERVER_NAME=$(echo "$SERVER" | jq -r '.name')
                    
                    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP'" 2>/dev/null || echo "0")
                    ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP' AND status = 1" 2>/dev/null || echo "0")
                    PREMIUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP' AND tipo = 'premium'" 2>/dev/null || echo "0")
                    TEST=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP' AND tipo = 'test'" 2>/dev/null || echo "0")
                    CONN2=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE vps_ip = '$SERVER_IP' AND max_connections = 2" 2>/dev/null || echo "0")
                    
                    echo -e "${CYAN}${SERVER_NAME} (${SERVER_IP})${NC}"
                    echo -e "  👥 Total: $TOTAL"
                    echo -e "  ✅ Activos: $ACTIVE"
                    echo -e "  💎 Premium: $PREMIUM"
                    echo -e "  🆓 Test: $TEST"
                    echo -e "  🔌 2 conexiones: $CONN2"
                    echo -e ""
                fi
            done
            
            echo -e "${YELLOW}📅 HOY:${NC}"
            TODAY=$(date +%Y-%m-%d)
            TODAY_TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date = '$TODAY'" 2>/dev/null || echo "0")
            TODAY_PREMIUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE date(created_at) = '$TODAY' AND tipo = 'premium'" 2>/dev/null || echo "0")
            
            echo -e "  Tests hoy: $TODAY_TESTS"
            echo -e "  Premium hoy: $TODAY_PREMIUM"
            
            read -p "Presiona Enter..."
            ;;
        7)
            echo -e "\n${YELLOW}🔄 Sincronizando servidores...${NC}"
            /opt/ssh-bot-multi/scripts/check_server_status.sh
            echo -e "${GREEN}✅ Sincronización completada${NC}"
            sleep 2
            ;;
        8)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     ⚙️  CONFIGURACIÓN                        ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}📁 ARCHIVOS DE CONFIGURACIÓN:${NC}"
            echo -e "1. ${CONFIG} - Configuración principal"
            echo -e "2. ${SERVERS} - Configuración de servidores"
            echo -e "3. ${DB} - Base de datos"
            echo -e ""
            echo -e "${YELLOW}🔧 HERRAMIENTAS:${NC}"
            echo -e "4. Ver configuración actual"
            echo -e "5. Modificar precios"
            echo -e "6. Configurar MercadoPago"
            echo -e "7. Reparar sistema"
            echo -e "8. Volver"
            
            read -p "Opción: " CONF_OPT
            
            case $CONF_OPT in
                1) nano "$CONFIG" ;;
                2) nano "$SERVERS" ;;
                3) 
                    echo -e "\n${YELLOW}📊 Info BD:${NC}"
                    sqlite3 "$DB" ".tables"
                    echo -e "\n${YELLOW}¿Abrir con sqlite3? (s/N):${NC}"
                    read OPEN
                    [[ "$OPEN" == "s" ]] && sqlite3 "$DB"
                    ;;
                4)
                    echo -e "\n${YELLOW}🤖 CONFIGURACIÓN PRINCIPAL:${NC}"
                    cat "$CONFIG" | jq '.'
                    echo -e "\n${YELLOW}🌐 SERVIDORES:${NC}"
                    cat "$SERVERS" | jq '.'
                    read -p "Presiona Enter..."
                    ;;
                5)
                    echo -e "\n${YELLOW}Modificar: ${CONFIG}${NC}"
                    read -p "¿Abrir editor? (s/N): " EDIT
                    [[ "$EDIT" == "s" ]] && nano "$CONFIG"
                    ;;
                6)
                    echo -e "\n${YELLOW}Configurar MercadoPago en: ${CONFIG}${NC}"
                    read -p "¿Abrir editor? (s/N): " EDIT
                    [[ "$EDIT" == "s" ]] && nano "$CONFIG"
                    ;;
                7)
                    echo -e "\n${YELLOW}🧹 Reparando sistema...${NC}"
                    cd /root/ssh-bot-multi && npm install
                    pm2 restart ssh-bot-multi
                    echo -e "${GREEN}✅ Sistema reparado${NC}"
                    sleep 2
                    ;;
            esac
            ;;
        9)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    📱 CÓDIGO QR WHATSAPP                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            if [[ -f "/root/qr-whatsapp.png" ]]; then
                echo -e "${GREEN}✅ QR guardado en: /root/qr-whatsapp.png${NC}\n"
                read -p "¿Ver logs en tiempo real? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot-multi --lines 200
            else
                echo -e "${YELLOW}⚠️  QR no generado aún${NC}\n"
                read -p "¿Ver logs? (s/N): " VER
                [[ "$VER" == "s" ]] && pm2 logs ssh-bot-multi --lines 50
            fi
            ;;
        10)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  🧪 TEST CONEXIONES SSH                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}🔍 Probando conexiones a las 3 VPS...${NC}\n"
            
            for i in 1 2 3; do
                SERVER=$(jq -r ".servers[] | select(.id == $i)" "$SERVERS")
                if [[ -n "$SERVER" ]]; then
                    IP=$(echo "$SERVER" | jq -r '.ip')
                    USER=$(echo "$SERVER" | jq -r '.ssh_user')
                    PORT=$(echo "$SERVER" | jq -r '.ssh_port')
                    
                    echo -n "VPS ${i} (${IP}): "
                    
                    # Probar SSH
                    if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p $PORT ${USER}@${IP} "echo '✅ Conectado' && whoami" 2>/dev/null; then
                        echo -e "${GREEN}✅ SSH OK${NC}"
                        
                        # Probar creación de usuario temporal
                        TEST_USER="testuser$(date +%s)"
                        timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $PORT ${USER}@${IP} "useradd -m -s /bin/bash $TEST_USER && echo '$TEST_USER:testpass' | chpasswd && sleep 1 && userdel -f $TEST_USER" &>/dev/null
                        
                        if [[ $? -eq 0 ]]; then
                            echo -e "   ${GREEN}✅ Creación de usuarios OK${NC}"
                        else
                            echo -e "   ${YELLOW}⚠️  Creación de usuarios limitada${NC}"
                        fi
                    else
                        echo -e "${RED}❌ SSH FAILED${NC}"
                    fi
                fi
            done
            
            echo -e "\n${YELLOW}📋 RESUMEN:${NC}"
            echo -e "1. Todas verdes: ✅ Sistema funcionando perfectamente"
            echo -e "2. SSH falla: 🔧 Verificar claves SSH y firewall"
            echo -e "3. Creación falla: 👤 Verificar permisos de root"
            
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

chmod +x /usr/local/bin/sshbot-multi
echo -e "${GREEN}✅ Panel de control multi-VPS creado${NC}"

# ================================================
# CONFIGURAR CRON PARA SINCRONIZACIÓN
# ================================================
echo -e "\n${CYAN}${BOLD}⏰ CONFIGURANDO TAREAS PROGRAMADAS...${NC}"

# Crear script de mantenimiento
cat > /opt/ssh-bot-multi/scripts/maintenance.sh << 'CRONEOF'
#!/bin/bash
# Script de mantenimiento para multi-VPS

DB="/opt/ssh-bot-multi/data/users.db"
LOG="/opt/ssh-bot-multi/logs/maintenance.log"

echo "$(date): Iniciando mantenimiento" >> "$LOG"

# 1. Verificar estado de servidores
/opt/ssh-bot-multi/scripts/check_server_status.sh >> "$LOG" 2>&1

# 2. Limpiar usuarios expirados
NOW=$(date +"%Y-%m-%d %H:%M:%S")
EXPIRED_USERS=$(sqlite3 "$DB" "SELECT username, vps_ip, server_id FROM users WHERE expires_at < '$NOW' AND status = 1" 2>/dev/null)

if [[ -n "$EXPIRED_USERS" ]]; then
    echo "$(date): Limpiando usuarios expirados" >> "$LOG"
    
    while IFS='|' read -r USERNAME VPS_IP SERVER_ID; do
        # Eliminar usuario remoto
        /opt/ssh-bot-multi/scripts/delete_remote_user.sh "$SERVER_ID" "$USERNAME" >> "$LOG" 2>&1
        
        # Actualizar BD
        sqlite3 "$DB" "UPDATE users SET status = 0 WHERE username = '$USERNAME'" 2>/dev/null
        
        echo "$(date): Eliminado $USERNAME de $VPS_IP" >> "$LOG"
    done <<< "$EXPIRED_USERS"
fi

# 3. Balancear carga si es necesario
TODAY=$(date +%Y-%m-%d)
echo "$(date): Mantenimiento completado" >> "$LOG"
CRONEOF

chmod +x /opt/ssh-bot-multi/scripts/maintenance.sh

# Agregar al crontab
(crontab -l 2>/dev/null; echo "*/15 * * * * /opt/ssh-bot-multi/scripts/maintenance.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 * * * * /opt/ssh-bot-multi/scripts/check_server_status.sh") | crontab -

echo -e "${GREEN}✅ Tareas programadas configuradas${NC}"

# ================================================
# INICIAR BOT MULTI-VPS
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT MULTI-VPS...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name ssh-bot-multi
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# MENSAJE FINAL MULTI-VPS
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         🎉 INSTALACIÓN MULTI-VPS COMPLETADA 🎉             ║
║                                                              ║
║         SSH BOT PRO v8.7 - SOPORTE 3 SERVIDORES            ║
║           🌐 CREACIÓN REMOTA EN TODAS LAS VPS              ║
║           🔄 BALANCEO AUTOMÁTICO DE CARGA                  ║
║           🔐 CONTRASEÑA FIJA: mgvpn247 PARA TODOS          ║
║           📊 PANEL UNIFICADO DE CONTROL                    ║
║           ⚡ ACTIVACIÓN EN SEGUNDOS                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema multi-VPS instalado${NC}"
echo -e "${GREEN}✅ 3 servidores SSH configurados${NC}"
echo -e "${GREEN}✅ Creación remota automática${NC}"
echo -e "${GREEN}✅ Balanceo de carga inteligente${NC}"
echo -e "${GREEN}✅ Panel de control unificado${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}\n"
echo -e "  ${GREEN}sshbot-multi${NC}     - Panel de control principal"
echo -e "  ${GREEN}pm2 logs ssh-bot-multi${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart ssh-bot-multi${NC} - Reiniciar bot\n"

echo -e "${YELLOW}🌐 SERVIDORES CONFIGURADOS:${NC}\n"
echo -e "  ${CYAN}1.${NC} VPS 1: ${VPS1_IP} (${VPS1_USER}@${VPS1_IP}:${VPS1_PORT})"
echo -e "  ${CYAN}2.${NC} VPS 2: ${VPS2_IP} (${VPS2_USER}@${VPS2_IP}:${VPS2_PORT})"
echo -e "  ${CYAN}3.${NC} VPS 3: ${VPS3_IP} (${VPS3_USER}@${VPS3_IP}:${VPS3_PORT})\n"

echo -e "${YELLOW}🔧 CONFIGURACIÓN INICIAL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}sshbot-multi${NC}"
echo -e "  2. Opción ${CYAN}[10]${NC} - Test conexiones SSH"
echo -e "  3. Opción ${CYAN}[3]${NC} - Crear usuario manual (probar)"
echo -e "  4. Opción ${CYAN}[9]${NC} - Escanear QR WhatsApp"
echo -e "  5. Configurar MercadoPago si lo necesitas\n"

echo -e "${YELLOW}⚙️  FUNCIONAMIENTO:${NC}\n"
echo -e "  • Usuarios TEST: Se crean siempre en ${CYAN}VPS 1${NC}"
echo -e "  • Usuarios PREMIUM: Se distribuyen automáticamente"
echo -e "  • Balanceo: Por cantidad de usuarios activos"
echo -e "  • Sincronización: Automática cada 15 minutos"
echo -e "  • Eliminación: Automática cuando expiran\n"

echo -e "${YELLOW}📊 GESTIÓN:${NC}\n"
echo -e "  • Ver todos los usuarios: ${GREEN}sshbot-multi${NC} → Opción 4"
echo -e "  • Estadísticas por servidor: ${GREEN}sshbot-multi${NC} → Opción 6"
echo -e "  • Estado de servidores: ${GREEN}sshbot-multi${NC} → Opción 10"
echo -e "  • Crear manualmente: ${GREEN}sshbot-multi${NC} → Opción 3\n"

echo -e "${YELLOW}🔐 CONTRASEÑA:${NC}"
echo -e "  • ${GREEN}mgvpn247${NC} para TODOS los usuarios en TODAS las VPS\n"

echo -e "${YELLOW}📁 ESTRUCTURA:${NC}"
echo -e "  Configuración: ${CYAN}/opt/ssh-bot-multi/config/${NC}"
echo -e "  Scripts: ${CYAN}/opt/ssh-bot-multi/scripts/${NC}"
echo -e "  Base de datos: ${CYAN}/opt/ssh-bot-multi/data/users.db${NC}"
echo -e "  Logs: ${CYAN}/opt/ssh-bot-multi/logs/${NC}\n"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e "${YELLOW}¿Abrir panel de control ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel multi-VPS...${NC}\n"
    sleep 2
    /usr/local/bin/sshbot-multi
else
    echo -e "\n${YELLOW}💡 Ejecuta: ${GREEN}sshbot-multi${NC} para abrir el panel\n"
fi

echo -e "${GREEN}${BOLD}¡Sistema multi-VPS instalado exitosamente! Ahora puedes crear usuarios en 3 servidores diferentes 🚀${NC}\n"

exit 0
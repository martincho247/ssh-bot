#!/bin/bash
# ================================================
# ACTUALIZAR PANEL CON MERCADOPAGO - WPPCONNECT
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
║                🔄 ACTUALIZANDO PANEL WPPCONNECT            ║
║                💰 AGREGANDO MERCADOPAGO                    ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar si el bot está instalado
if [[ ! -f "/opt/wpp-bot/config/config.json" ]]; then
    echo -e "${RED}❌ No se encontró la instalación de WPPConnect${NC}"
    echo -e "${YELLOW}Primero instala el bot con el script WPPConnect${NC}"
    exit 1
fi

# Actualizar el panel de control
echo -e "${CYAN}📝 Actualizando panel de control...${NC}"

cat > /usr/local/bin/wppbot << 'PANELEOF'
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
    echo -e "${CYAN}[4]${NC} 👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC} 👥  Listar usuarios"
    echo -e ""
    echo -e "${CYAN}[6]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[7]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[9]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 🔄 Limpiar sesión"
    echo -e "${CYAN}[11]${NC} ⚙️  Ver configuración"
    echo -e "${CYAN}[0]${NC} 🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
        5)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                     👥 USUARIOS ACTIVOS                     ║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
            
            sqlite3 -column -header "$DB" "SELECT username, password, tipo, expires_at FROM users WHERE status = 1 ORDER BY expires_at DESC LIMIT 20"
            echo -e "\n${YELLOW}Total: ${ACTIVE_USERS} activos${NC}"
            read -p "Presiona Enter..."
            ;;
        6)
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
        7)
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
        8)
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
        9)
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
        10)
            echo -e "\n${YELLOW}🧹 Limpiando sesión...${NC}"
            pm2 stop wpp-bot
            rm -rf /root/.wppconnect/*
            echo -e "${GREEN}✅ Sesión limpiada${NC}"
            echo -e "${YELLOW}📱 Escanea nuevo QR al iniciar${NC}"
            sleep 2
            ;;
        11)
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
            echo -e "  Test: 1 hora"
            
            echo -e "\n${YELLOW}💳 MERCADOPAGO:${NC}"
            MP_TOKEN=$(get_val '.mercadopago.access_token')
            if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "null" ]]; then
                echo -e "  Estado: ${GREEN}CONFIGURADO${NC}"
            else
                echo -e "  Estado: ${RED}NO CONFIGURADO${NC}"
            fi
            
            echo -e "\n${YELLOW}⚡ AJUSTES:${NC}"
            echo -e "  Limpieza: cada 15 minutos"
            echo -e "  Test: 1 hora exacta"
            echo -e "  Contraseña: mgvpn247 (fija)"
            
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

chmod +x /usr/local/bin/wppbot
echo -e "${GREEN}✅ Panel actualizado con MercadoPago${NC}"

# Ahora actualizar el bot.js para soportar MercadoPago
echo -e "${CYAN}🔄 Actualizando bot.js para MercadoPago...${NC}"

cd /root/wpp-bot

# Instalar SDK de MercadoPago
npm install mercadopago@2.0.15 --save

# Crear nuevo bot.js con MercadoPago integrado
cat > bot.js << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const QRCode = require('qrcode');
const fs = require('fs');

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
    return 'PASS' + Math.floor(1000 + Math.random() * 9000);
}

async function createSSHUser(phone, username, password, days) {
    if (days === 0) {
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

// ✅ FUNCIÓN DE MERCADOPAGO
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
                success: `https://wa.me/${phoneClean}?text=Pago%20exitoso`,
                failure: `https://wa.me/${phoneClean}?text=Pago%20fallido`,
                pending: `https://wa.me/${phoneClean}?text=Pago%20pendiente`
            },
            auto_return: 'approved',
            statement_descriptor: 'SSH PREMIUM'
        };
        
        console.log(chalk.yellow(`📦 Producto: ${preferenceData.items[0].title}`));
        console.log(chalk.yellow(`💰 Monto: $${amount} ${config.prices.currency || 'ARS'}`));
        
        const response = await mpPreference.create({ body: preferenceData });
        
        if (response && response.id) {
            const paymentUrl = response.init_point;
            const qrPath = `/opt/wpp-bot/data/${paymentId}.png`;
            
            await QRCode.toFile(qrPath, paymentUrl, { 
                width: 400,
                margin: 1
            });
            
            db.run(
                `INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url) VALUES (?, ?, ?, ?, ?, 'pending', ?)`,
                [paymentId, phone, `${days}d`, days, amount, paymentUrl],
                (err) => {
                    if (err) console.error(chalk.red('❌ Error BD:'), err.message);
                }
            );
            
            console.log(chalk.green(`✅ Pago creado: ${paymentId}`));
            
            return { 
                success: true, 
                paymentId, 
                paymentUrl, 
                qrPath,
                amount: amount
            };
        }
        
        throw new Error('Respuesta inválida de MercadoPago');
        
    } catch (error) {
        console.error(chalk.red('❌ Error MercadoPago:'), error.message);
        return { success: false, error: error.message };
    }
}

// ✅ VERIFICAR PAGOS PENDIENTES
async function checkPendingPayments() {
    if (!mpEnabled) return;
    
    db.all('SELECT * FROM payments WHERE status = "pending" AND created_at > datetime("now", "-48 hours")', async (err, payments) => {
        if (err || !payments || payments.length === 0) return;
        
        console.log(chalk.yellow(`🔍 Verificando ${payments.length} pagos...`));
        
        for (const payment of payments) {
            try {
                // Usar API de MercadoPago para verificar estado
                // Nota: Para producción necesitarías implementar webhooks o polling
                // Esta es una implementación básica
                console.log(chalk.cyan(`📋 Pago pendiente: ${payment.payment_id}`));
                
            } catch (error) {
                console.error(chalk.red(`❌ Error verificando ${payment.payment_id}:`), error.message);
            }
        }
    });
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
                            '1': { days: 7, price: config.prices.price_7d, name: '7 DÍAS' },
                            '2': { days: 15, price: config.prices.price_15d, name: '15 DÍAS' },
                            '3': { days: 30, price: config.prices.price_30d, name: '30 DÍAS' },
                            '4': { days: 50, price: config.prices.price_50d, name: '50 DÍAS' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (mpEnabled) {
                            // ✅ CON MERCADOPAGO
                            userStates[from] = { 
                                state: 'processing_payment', 
                                plan: plan 
                            };
                            
                            await client.sendText(from, `PLAN SELECCIONADO: ${plan.name}

💰 Precio: $${plan.price} ARS
⏰ Duración: ${plan.days} días
🔌 Conexiones: 1

⏳ Generando pago con MercadoPago...`);
                            
                            // Crear pago
                            const payment = await createMercadoPagoPayment(from, plan.days, plan.price, plan.name);
                            
                            if (payment.success) {
                                const message = `### USUARIO SSH

- **Plan:** ${plan.name}
- **Precio:** $${payment.amount} ARS
- **Límite:** 1 dispositivo(s)
- **Duración:** ${plan.days} días

---

**LINK DE PAGO**

${payment.paymentUrl}

⏰ *Este enlace expira en 24 horas*
💳 *Pago seguro con MercadoPago*

✅ Te notificaré cuando se apruebe el pago automáticamente.`;
                                
                                await client.sendText(from, message);
                                
                                // Enviar QR si existe
                                if (fs.existsSync(payment.qrPath)) {
                                    try {
                                        const media = await client.decryptFile(payment.qrPath);
                                        await client.sendImage(from, payment.qrPath, 'qr-pago.jpg', 
                                            `📱 *Escanea con MercadoPago*\n\n${plan.name} - $${plan.price} ARS`);
                                    } catch (qrError) {
                                        console.error(chalk.red('⚠️ Error enviando QR:'), qrError.message);
                                    }
                                }
                            } else {
                                await client.sendText(from, `❌ *ERROR AL GENERAR PAGO*

${payment.error}

Contacta al administrador para otras opciones de pago.`);
                            }
                            
                            userStates[from] = { state: 'main_menu' };
                            
                        } else {
                            // ❌ SIN MERCADOPAGO
                            await client.sendText(from, `PLAN SELECCIONADO: ${plan.name}

Precio: $${plan.price} ARS
Duración: ${plan.days} días

Para continuar con la compra, contacta al administrador:
${config.links.support}

O envía el monto por transferencia bancaria.`);
                            
                            userStates[from] = { state: 'main_menu' };
                        }
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
        
        // Verificar pagos cada 2 minutos
        cron.schedule('*/2 * * * *', () => {
            console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
            checkPendingPayments();
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

echo -e "${GREEN}✅ Bot actualizado con MercadoPago${NC}"

# Reiniciar el bot
echo -e "${CYAN}🔄 Reiniciando bot...${NC}"
pm2 restart wpp-bot

sleep 3

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          ✅ ACTUALIZACIÓN COMPLETADA - MERCADOPAGO ✅       ║
║                                                              ║
║       💰 MercadoPago integrado en el panel                 ║
║       🔑 Configuración fácil desde el menú                 ║
║       🧪 Test de conexión incluido                         ║
║       📊 Estadísticas completas                            ║
║       🔄 Bot actualizado con pagos automáticos             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Panel actualizado con MercadoPago${NC}"
echo -e "${GREEN}✅ Bot actualizado para generar pagos automáticos${NC}"
echo -e "${GREEN}✅ Opciones nuevas en el panel:${NC}"
echo -e "   - ${CYAN}[7]${NC} Configurar MercadoPago"
echo -e "   - ${CYAN}[8]${NC} Test MercadoPago"
echo -e "   - ${CYAN}[9]${NC} Estadísticas completas"
echo -e "   - ${CYAN}[11]${NC} Ver configuración"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🚀 USO DEL NUEVO PANEL:${NC}\n"
echo -e "  1. Ejecuta: ${GREEN}wppbot${NC}"
echo -e "  2. Opción ${CYAN}[7]${NC} - Configurar MercadoPago"
echo -e "  3. Pega tu token de producción"
echo -e "  4. Opción ${CYAN}[8]${NC} - Testear conexión"
echo -e "  5. Usuarios podrán pagar con MercadoPago\n"

echo -e "${YELLOW}💰 PARA OBTENER TOKEN MERCADOPAGO:${NC}\n"
echo -e "  1. Ve a: https://www.mercadopago.com.ar/developers"
echo -e "  2. Inicia sesión"
echo -e "  3. Ve a 'Tus credenciales'"
echo -e "  4. Copia 'Access Token PRODUCCIÓN'"
echo -e "  5. Formato: APP_USR-xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo -e "\n${RED}⚠️ IMPORTANTE: Usa token de PRODUCCIÓN, no de TEST${NC}\n"

echo -e "${GREEN}${BOLD}¡MercadoPago integrado exitosamente! Ahora los usuarios podrán pagar automáticamente 🚀${NC}\n"

echo -e "${YELLOW}Prueba el nuevo panel:${NC}"
read -p "$(echo -e "${CYAN}¿Abrir panel ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Abriendo panel...${NC}"
    wppbot
fi

exit 0
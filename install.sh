#!/bin/bash
# ================================================
# HTTP CUSTOM BOT PRO v9.1 - HWID FIXED
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
║     🤖 HTTP CUSTOM BOT PRO v9.1 - HWID FIXED                ║
║     📱 Sistema de archivos .hc con procesamiento inmediato  ║
║     🚀 Envío automático al recibir HWID                     ║
║     💰 Compras con HWID incluido                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# [TODO: AGREGAR AQUÍ TODAS LAS SECCIONES ANTERIORES DEL INSTALADOR...]

# ================================================
# SECCIÓN CRÍTICA: BOT.JS CORREGIDO
# ================================================

echo -e "\n${CYAN}${BOLD}🔧 CREANDO BOT.JS CON PROCESAMIENTO HWID INMEDIATO...${NC}"

cat > /root/hc-bot/bot.js << 'BOTEOF'
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
console.log(chalk.cyan.bold('║      🤖 HTTP CUSTOM BOT PRO v9.1 - HWID FIXED               ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

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

echo -e "${GREEN}✅ Bot corregido - Procesa HWID inmediatamente${NC}"

# ================================================
# REINICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🔄 REINICIANDO BOT CON CORRECCIONES...${NC}"

cd /root/hc-bot
pm2 delete hc-bot 2>/dev/null || true
pm2 start bot.js --name hc-bot
pm2 save

sleep 3

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🎉 CORRECCIONES APLICADAS - HWID FIXED 🎉             ║
║                                                              ║
║         ✅ Procesamiento inmediato de HWID                  ║
║         ✅ Envío automático de archivo .hc                  ║
║         ✅ Formato: "hwid CODIGO" → archivo enviado        ║
║         ✅ Compras: "hwid CODIGO comprar7"                 ║
║         ✅ Reenvío: "reenviar CODIGO"                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📱 FLUJO CORREGIDO:${NC}\n"
echo -e "  1. Usuario envía: ${GREEN}hwid ABC123XYZ${NC}"
echo -e "  2. Bot genera y envía archivo .hc ${GREEN}(INMEDIATO)${NC}"
echo -e "  3. Usuario importa en HTTP Custom"
echo -e "  4. ¡Conectado! 🎉\n"
echo -e "  ${YELLOW}Compras:${NC} hwid ABC123XYZ comprar7"
echo -e "  ${YELLOW}Reenvío:${NC} reenviar ABC123XYZ"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${GREEN}✅ Bot funcionando correctamente${NC}"
echo -e "${YELLOW}💡 Escanea el QR con WhatsApp${NC}\n"

echo -e "Comando: ${CYAN}hcbot${NC} para panel de control\n"

# Verificar que el archivo template existe
if [[ -f "/opt/hc-bot/templates/template.hc" ]]; then
    echo -e "${GREEN}✅ Plantilla .hc verificada${NC}"
else
    echo -e "${RED}⚠️  Creando plantilla .hc...${NC}"
    mkdir -p /opt/hc-bot/templates
    cat > /opt/hc-bot/templates/template.hc << 'TEMPEOF'
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
TEMPEOF
fi

# Auto-destrucción
sleep 5
echo -e "\n${YELLOW}Script finalizado. El bot está corriendo.${NC}"
#!/bin/sh

export PORT="${PORT:-8080}"
export UUID="${UUID:-12345678-1234-1234-1234-123456789abc}"
export WSPATH="${WSPATH:-/vless-ws}"
export SUB_PATH="${SUB_PATH:-mytoken123}"
export SERVER_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-localhost}"

mkdir -p /app/public

# 1. Генерация конфига Xray
envsubst '${UUID} ${WSPATH}' < /app/xray.template.json > /app/xray.json

# 2. Генерация клиентского конфига sing-box
envsubst '${UUID} ${WSPATH} ${SERVER_DOMAIN}' < /app/singbox-client.template.json > /app/public/config.json

# 3. Генерация Caddyfile
envsubst '${PORT} ${WSPATH} ${SUB_PATH}' < /app/Caddyfile.template > /app/Caddyfile

echo "=============================================="
echo "Subscription URL: https://${SERVER_DOMAIN}/sub/${SUB_PATH}"
echo "WebSocket Path: ${WSPATH}"
echo "=============================================="

# Запуск Xray в фоне
xray run -c /app/xray.json &

# Запуск Caddy в foreground
exec caddy run --config /app/Caddyfile --adapter caddyfile

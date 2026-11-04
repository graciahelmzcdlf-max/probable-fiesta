#!/bin/sh

# Дефолтный порт Railway, если переменная не задана локально
export PORT="${PORT:-8080}"
export UUID="${UUID:-12345678-1234-1234-1234-123456789abc}"
export WSPATH="${WSPATH:-/vless-ws}"

echo "Starting Xray on port $PORT with path $WSPATH..."

# Подстановка переменных окружения в шаблон конфига
envsubst '${PORT} ${UUID} ${WSPATH}' < /etc/xray/config.template.json > /etc/xray/config.json

# Запуск Xray с сгенерированным конфигом
exec xray run -c /etc/xray/config.json

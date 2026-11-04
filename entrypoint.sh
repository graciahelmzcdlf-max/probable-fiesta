#!/bin/sh

export PORT="${PORT:-8080}"
export UUID="${UUID:-b831381d-6324-4d53-ad4f-8cda48b30811}"
export WSPATH="${WSPATH:-/vless-ws}"
export SUB_PATH="${SUB_PATH:-user-key-771a}"
# Подставляем реальный домен Railway
export SERVER_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-probable-fiesta-production-cb96.up.railway.app}"

mkdir -p /app/public

# 1. Конфигурация ядра Xray
cat <<EOF > /app/xray.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${WSPATH}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# 2. Формирование универсальной ссылки vless:// и Base64 подписки
VLESS_URL="vless://${UUID}@${SERVER_DOMAIN}:443?encryption=none&security=tls&sni=${SERVER_DOMAIN}&type=ws&path=${WSPATH}#Railway-VLESS"

# Сохраняем и чистую ссылку, и base64 версию
echo "${VLESS_URL}" > /app/public/sub.txt
echo -n "${VLESS_URL}" | base64 | tr -d '\n' > /app/public/sub_b64.txt

# 3. Конфигурация Caddy для отдачи подписки
cat <<EOF > /app/Caddyfile
:${PORT} {
    # Отдача подписки для приложений (Hiddify, v2rayNG, NekoBox)
    handle /sub/${SUB_PATH} {
        header Content-Type "text/plain; charset=utf-8"
        file_server {
            root /app/public
        }
        rewrite * /sub.txt
    }

    # Проброс входящего VLESS WebSocket трафика
    handle ${WSPATH}* {
        reverse_proxy 127.0.0.1:10000
    }

    handle {
        respond "OK" 200
    }
}
EOF

echo "=================================================="
echo "VLESS Link: ${VLESS_URL}"
echo "Subscription URL: https://${SERVER_DOMAIN}/sub/${SUB_PATH}"
echo "=================================================="

/usr/bin/xray run -c /app/xray.json &
exec caddy run --config /app/Caddyfile --adapter caddyfile

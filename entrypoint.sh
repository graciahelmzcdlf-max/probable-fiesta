#!/bin/sh

export PORT="${PORT:-8080}"
export UUID="${UUID:-b831381d-6324-4d53-ad4f-8cda48b30811}"
export WSPATH="${WSPATH:-/vless-ws}"
export SUB_PATH="${SUB_PATH:-mysecrettoken}"
export SERVER_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-localhost}"

mkdir -p /app/public

# 1. Генерация конфига сервера Xray
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

# 2. Генерация клиентского конфига sing-box для подписки
cat <<EOF > /app/public/config.json
{
  "log": {
    "level": "warn",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "remote-dns",
        "address": "https://1.1.1.1/dns-query",
        "detour": "proxy"
      },
      {
        "tag": "local-dns",
        "address": "local",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "outbound": "any",
        "server": "local-dns"
      }
    ],
    "strategy": "prefer_ipv4"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true,
      "stack": "system",
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "${SERVER_DOMAIN}",
      "server_port": 443,
      "uuid": "${UUID}",
      "tls": {
        "enabled": true,
        "server_name": "${SERVER_DOMAIN}",
        "insecure": false
      },
      "transport": {
        "type": "ws",
        "path": "${WSPATH}"
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "auto_detect_interface": true
  }
}
EOF

# 3. Генерация конфигурации Caddy
cat <<EOF > /app/Caddyfile
:${PORT} {
    handle /sub/${SUB_PATH} {
        header Content-Type "application/json; charset=utf-8"
        file_server {
            root /app/public
        }
        rewrite * /config.json
    }

    handle ${WSPATH}* {
        reverse_proxy 127.0.0.1:10000
    }

    handle {
        respond "OK" 200
    }
}
EOF

echo "=================================================="
echo "Starting VLESS + Caddy on port ${PORT}"
echo "Client subscription URL: https://${SERVER_DOMAIN}/sub/${SUB_PATH}"
echo "=================================================="

# Запуск Xray в фоне
/usr/bin/xray run -c /app/xray.json &

# Запуск Caddy на основном процессе
exec caddy run --config /app/Caddyfile --adapter caddyfile

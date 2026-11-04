FROM teddysun/xray:latest

# Установка envsubst (пакет gettext) для подстановки env-переменных
RUN apk add --no-cache gettext

WORKDIR /etc/xray

COPY config.template.json /etc/xray/config.template.json
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

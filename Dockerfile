FROM alpine:edge

RUN apk add --no-cache xray caddy gettext curl jq

WORKDIR /app

COPY Caddyfile.template /app/Caddyfile.template
COPY xray.template.json /app/xray.template.json
COPY singbox-client.template.json /app/singbox-client.template.json
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

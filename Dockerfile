FROM node:20-bookworm-slim AS web-builder

WORKDIR /src
COPY hermes-agent-src/ /src/

WORKDIR /src/web
RUN npm install && npm run build

FROM python:3.11-slim AS app-builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /src
COPY hermes-agent-src/ /src/
COPY --from=web-builder /src/hermes_cli/web_dist /src/hermes_cli/web_dist
RUN pip install --no-cache-dir ".[web]"

FROM caddy:2.8.4-alpine AS caddy-bin

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PROXY_PORT=9119 \
    DASHBOARD_HOST=127.0.0.1 \
    DASHBOARD_PORT=9120

COPY --from=app-builder /usr/local /usr/local
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 9119

CMD ["/entrypoint.sh"]

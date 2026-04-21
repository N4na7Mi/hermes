FROM nousresearch/hermes-agent:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then NODE_ARCH="x64"; else NODE_ARCH="$ARCH"; fi \
    && curl -fsSL "https://nodejs.org/dist/v23.11.0/node-v23.11.0-linux-${NODE_ARCH}.tar.gz" -o /tmp/node.tar.gz \
    && tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.gz \
    && node --version

WORKDIR /app

COPY hermes-web-ui-src/package*.json ./
RUN npm install

COPY hermes-web-ui-src/ /app/
RUN npm run build && npm prune --omit=dev

ENV NODE_ENV=production \
    HOME=/home/agent \
    HERMES_HOME=/home/agent/.hermes \
    HERMES_BIN=/opt/hermes/.venv/bin/hermes \
    PORT=9119 \
    UPSTREAM=http://127.0.0.1:8642

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /home/agent/.hermes /home/agent/.hermes-web-ui

EXPOSE 9119

ENTRYPOINT ["/entrypoint.sh"]

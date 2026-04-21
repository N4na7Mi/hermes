FROM node:20-bookworm-slim AS web-builder

ARG HERMES_REF=main

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch ${HERMES_REF} https://github.com/NousResearch/hermes-agent.git .

WORKDIR /src/web
RUN npm install && npm run build

FROM python:3.11-slim AS app-builder

ARG HERMES_REF=main

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch ${HERMES_REF} https://github.com/NousResearch/hermes-agent.git .
COPY --from=web-builder /src/hermes_cli/web_dist /src/hermes_cli/web_dist
RUN pip install --no-cache-dir ".[web]"

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HERMES_HOST=0.0.0.0 \
    HERMES_PORT=9119

COPY --from=app-builder /usr/local /usr/local

EXPOSE 9119

CMD ["sh", "-lc", "hermes dashboard --host ${HERMES_HOST} --port ${HERMES_PORT}"]

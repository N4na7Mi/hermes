FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HERMES_HOST=0.0.0.0 \
    HERMES_PORT=9119

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install "hermes-agent[web]"

EXPOSE 9119

CMD ["sh", "-lc", "hermes dashboard --host ${HERMES_HOST} --port ${HERMES_PORT}"]

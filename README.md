# Hermes Web Chat on Claw Cloud

This repo builds a Docker image for `hermes-web-ui`, publishes it to GHCR with GitHub Actions, and runs it on Claw Cloud so you can open a web page and chat directly.

## What it does

- Uses the upstream `nousresearch/hermes-agent` image as the Hermes runtime
- Builds the upstream `EKKOLearnAI/hermes-web-ui` frontend and server
- Exposes a real web chat UI instead of the official management dashboard
- Runs Hermes gateway and `hermes-web-ui` together in one container
- Keeps the Hermes gateway on `127.0.0.1:8642` inside the container
- Protects the UI with the built-in token login page

## Fastest path to go live

### 1. Push this repo to GitHub

Push to `main`. GitHub Actions will build and publish:

```text
ghcr.io/<your-github-username>/hermes-clawcloud:latest
```

If the GHCR package is private, make it public in GitHub package settings or configure Claw Cloud with registry credentials.

### 2. Deploy on Claw Cloud

Create a new app and use this image:

```text
ghcr.io/<your-github-username>/hermes-clawcloud:latest
```

Set the container port to:

```text
9119
```

### 3. Add environment variables in Claw Cloud

Minimum required:

```text
OPENAI_API_KEY=your_api_key
OPENAI_BASE_URL=https://your-provider.example.com/v1
AUTH_TOKEN=change-this-to-a-long-random-string
```

Recommended optional values:

```text
PORT=9119
UPSTREAM=http://127.0.0.1:8642
GATEWAY_ALLOW_ALL_USERS=true
DATA_DIR=/data
HERMES_HOME=/data/.hermes
HERMES_BIN=/opt/hermes/.venv/bin/hermes
```

### 4. Open the app

When the container is ready:

- open the Claw Cloud app URL
- you will see the Hermes Web UI login page
- paste the `AUTH_TOKEN` value
- enter the chat page and start talking

## Notes

- This is the fastest path to a real chat frontend.
- The login page uses `AUTH_TOKEN`, not username/password.
- The Hermes gateway stays internal to the container and is not exposed publicly.
- `GATEWAY_ALLOW_ALL_USERS=true` is only for the internal loopback gateway used by the web UI.
- This single-container setup runs two long-lived processes in one pod: Hermes gateway and the web UI server.
- Mount persistent storage to `/data` so both `/data/.hermes` and `/data/.hermes-web-ui` survive redeploys.
- Do not commit real API keys or auth tokens.

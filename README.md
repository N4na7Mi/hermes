# Hermes Agent on Claw Cloud

This repo builds a source-based Docker image for the official Hermes Agent web dashboard and publishes it to GHCR with GitHub Actions.

## What it does

- Builds the official Hermes dashboard from source
- Installs Hermes with the web dependencies included
- Starts the dashboard with `hermes dashboard`
- Binds to `0.0.0.0:9119`
- Lets Claw Cloud inject your API key and base URL as environment variables

## Fastest path to go live

### 1. Create a new GitHub repo

Create an empty repo and upload these files.

### 2. Push to `main`

Once pushed, GitHub Actions will build and publish:

- `ghcr.io/<your-github-username>/hermes-clawcloud:latest`

If your package is private, make it public in the GHCR package settings or configure Claw Cloud with registry credentials.

### 3. Deploy on Claw Cloud

Create a new app and use this image:

```text
ghcr.io/<your-github-username>/hermes-clawcloud:latest
```

Set container port to:

```text
9119
```

### 4. Add environment variables in Claw Cloud

Minimum required:

```text
OPENAI_API_KEY=your_api_key
OPENAI_BASE_URL=https://your-provider.example.com/v1
```

Optional:

```text
DASHBOARD_HOST=0.0.0.0
DASHBOARD_PORT=9119
```

## Notes

- This setup assumes your provider is OpenAI-compatible.
- Do not commit real API keys.
- If you use OpenRouter or another provider later, replace the environment variables accordingly.

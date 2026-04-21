import os
from urllib.parse import quote

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, PlainTextResponse, RedirectResponse, Response
from itsdangerous import BadSignature, URLSafeSerializer

AUTH_USER = os.getenv("BASIC_AUTH_USER", "admin")
AUTH_PASSWORD = os.getenv("BASIC_AUTH_PASSWORD", "change-me-now")
SESSION_SECRET = os.getenv("SESSION_SECRET", "replace-this-session-secret")
DASHBOARD_PORT = int(os.getenv("DASHBOARD_PORT", "9120"))
DASHBOARD_BASE = f"http://127.0.0.1:{DASHBOARD_PORT}"
SESSION_COOKIE = "hermes_session"
serializer = URLSafeSerializer(SESSION_SECRET, salt="hermes-login")
HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "content-length",
}

app = FastAPI()


def render_login(next_path: str, error: str = "") -> str:
    error_html = f'<p style="color:#dc2626;margin:0 0 12px;">{error}</p>' if error else ""
    return f"""
<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Hermes Login</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background:#0f172a; color:#e2e8f0; display:grid; place-items:center; min-height:100vh; margin:0; }}
    .card {{ width:min(92vw, 360px); background:#111827; border:1px solid #1f2937; border-radius:16px; padding:24px; box-shadow:0 20px 60px rgba(0,0,0,.35); }}
    h1 {{ margin:0 0 8px; font-size:24px; }}
    p {{ margin:0 0 16px; color:#94a3b8; }}
    label {{ display:block; margin:12px 0 6px; font-size:14px; }}
    input {{ width:100%; box-sizing:border-box; border:1px solid #334155; border-radius:10px; background:#0b1220; color:#e2e8f0; padding:10px 12px; }}
    button {{ width:100%; margin-top:16px; border:0; border-radius:10px; background:#2563eb; color:white; padding:10px 12px; font-weight:600; cursor:pointer; }}
  </style>
</head>
<body>
  <form class=\"card\" method=\"post\" action=\"/_auth/login\">
    <h1>Hermes</h1>
    <p>Sign in to continue.</p>
    {error_html}
    <input type=\"hidden\" name=\"next\" value=\"{next_path}\">
    <label for=\"username\">Username</label>
    <input id=\"username\" name=\"username\" autocomplete=\"username\" required>
    <label for=\"password\">Password</label>
    <input id=\"password\" name=\"password\" type=\"password\" autocomplete=\"current-password\" required>
    <button type=\"submit\">Login</button>
  </form>
</body>
</html>
"""


@app.get("/_auth/health")
async def auth_health() -> PlainTextResponse:
    return PlainTextResponse("ok")


@app.get("/_auth/login")
async def login_page(request: Request, next: str = "/") -> HTMLResponse:
    return HTMLResponse(render_login(next))


@app.post("/_auth/login")
async def login_submit(request: Request) -> Response:
    form = await request.form()
    username = str(form.get("username", ""))
    password = str(form.get("password", ""))
    next_path = str(form.get("next", "/")) or "/"

    if not next_path.startswith("/"):
        next_path = "/"

    if username != AUTH_USER or password != AUTH_PASSWORD:
        return HTMLResponse(render_login(next_path, "Invalid username or password."), status_code=401)

    response = RedirectResponse(next_path, status_code=303)
    response.set_cookie(
        SESSION_COOKIE,
        serializer.dumps({"authenticated": True}),
        httponly=True,
        secure=True,
        samesite="lax",
        path="/",
    )
    return response


@app.get("/_auth/logout")
async def logout(request: Request) -> RedirectResponse:
    response = RedirectResponse("/_auth/login", status_code=303)
    response.delete_cookie(SESSION_COOKIE, path="/")
    return response


async def proxy_request(request: Request) -> Response:
    target = httpx.URL(DASHBOARD_BASE).join(request.url.path)
    if request.url.query:
        target = target.copy_with(query=request.url.query.encode())

    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_HEADERS and key.lower() != "host"
    }
    headers["x-forwarded-host"] = request.headers.get("host", "")
    headers["x-forwarded-proto"] = request.url.scheme

    async with httpx.AsyncClient(follow_redirects=False, timeout=60.0) as client:
        upstream = await client.request(
            request.method,
            target,
            headers=headers,
            content=await request.body(),
        )

    response = Response(content=upstream.content, status_code=upstream.status_code)
    for key, value in upstream.headers.items():
        if key.lower() not in HOP_HEADERS:
            response.headers[key] = value
    return response


@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path.startswith("/_auth/"):
        return await call_next(request)

    authenticated = False
    token = request.cookies.get(SESSION_COOKIE)
    if token:
        try:
            payload = serializer.loads(token)
            authenticated = bool(payload.get("authenticated"))
        except BadSignature:
            authenticated = False

    if not authenticated:
        next_path = request.url.path
        if request.url.query:
            next_path = f"{next_path}?{request.url.query}"
        return RedirectResponse(f"/_auth/login?next={quote(next_path, safe='/?=&%')}", status_code=303)

    return await proxy_request(request)

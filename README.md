# Demo Home Page (Raspberry Pi / Home Server)

Small home-server stack designed to run on a Raspberry Pi (or any Linux box) using Docker Compose:

- `app`: Flask app serving a simple landing page (`/`) and a health endpoint (`/ping`)
- `caddy`: Reverse proxy + automatic HTTPS (Let's Encrypt) for the app and an admin UI
- `lazydocker`: Web UI to view/manage Docker on the server (proxied behind auth)
- `ddns`: Dynamic DNS updater for FreeDNS (keeps your domain pointing to your home IP)

## Architecture

- Internet -> `caddy` (ports `80`/`443`)
- `caddy` -> `app` on `app:5000`
- `caddy` -> `lazydocker` on `lazydocker:7681` (protected via Basic Auth)
- `ddns` runs on a schedule and updates your DNS provider

## Services

### app (Flask + Gunicorn)

- Source: [app.py](./app.py), [templates/index.html](./templates/index.html)
- Endpoints:
  - `/` renders the HTML page
  - `/ping` returns `{"msg":"pong"}` (used for health checks)
- Container entrypoint:
  - [Dockerfile](./Dockerfile) runs `gunicorn app:app` via `uv`
  - `GUNICORN_CMD_ARGS` is set in Compose (workers/threads/timeouts/bind)

### caddy (Reverse proxy + HTTPS)

- Config: [Caddyfile](./Caddyfile)
- Exposes:
  - `80:80` (HTTP, redirected to HTTPS)
  - `443:443` (HTTPS)
- Routes:
  - `APP_DOMAIN` -> `reverse_proxy app:5000`
  - `LOGS_DOMAIN` -> `reverse_proxy lazydocker:7681` with Basic Auth

To change the Basic Auth password:

1. Generate a new hash on any machine with Caddy installed:
   ```bash
   caddy hash-password
   ```
2. Replace the hash in [Caddyfile](./Caddyfile) under `basic_auth`.

Default Basic Auth username is `mst` (see [Caddyfile](./Caddyfile)).

### lazydocker (Docker web UI)

- Image: `dhimanparas20/lazydocker-web:latest`
- Exposes port `7681` internally (Compose does not publish it directly)
- Mounted:
  - `/var/run/docker.sock:/var/run/docker.sock` (required to control Docker)
- Access:
  - Via `https://$LOGS_DOMAIN` (through Caddy)

### ddns (FreeDNS dynamic DNS updater)

- Image: `dhimanparas20/ddns:latest`
- Uses `.env` for credentials (`FREEDNS_TOKEN` or `FREEDNS_UPDATE_URL`)
- Persists logs/config via volumes `dns-logs` and `dns-config`

Advanced tuning values are set directly in [compose.yml](./compose.yml) (interval/timeouts/retry/force IPv4).

## Prerequisites (Server)

- A Raspberry Pi (or Linux VM/server) reachable from your router
- Docker Engine and Docker Compose v2 plugin (`docker compose ...`)
- Router port-forwarding for:
  - TCP `80` -> server
  - TCP `443` -> server
- A domain name pointing to your public IP
  - If you have a dynamic IP: use the included `ddns` service

## Environment Variables

Create a `.env` file (do not commit it) based on [.env.sample](./.env.sample).

Required:

- `FREEDNS_TOKEN`: FreeDNS token used by the `ddns` container
- `FREEDNS_UPDATE_URL` (optional): alternative to `FREEDNS_TOKEN` (keep only one approach)
- `APP_DOMAIN`: domain for the main app (example: `mst.example.com`)
- `LOGS_DOMAIN`: domain for the LazyDocker UI (example: `logs.example.com`)

Notes:

- The Compose file also passes `APP_DOMAIN` and `LOGS_DOMAIN` into Caddy explicitly.
- If you do not want DDNS, you can leave `FREEDNS_TOKEN` empty and remove/disable the `ddns` service in Compose.

## Domain + DNS Setup (FreeDNS)

This stack is set up to work with FreeDNS-style dynamic DNS via the included `ddns` container.

1. Create a FreeDNS account and a dynamic DNS record/subdomain.
2. Get your FreeDNS dynamic DNS token (or an update URL) from the FreeDNS dashboard.
3. Put the token into `.env` as `FREEDNS_TOKEN`.
4. Set `APP_DOMAIN` and `LOGS_DOMAIN` to the hostnames you want Caddy to serve.
5. Ensure your DNS A/AAAA record(s) point to your public IP (the `ddns` service is meant to keep this current if your IP changes).

If you use a different provider (No-IP, DuckDNS, Cloudflare, etc.), replace/disable the `ddns` service and manage DNS updates separately.

## Run With Docker Compose (Recommended)

1. On the server, clone the repo:
   ```bash
   git clone <YOUR_REPO_URL>
   cd Demo_Home_Page_Raspberry_PI
   ```

2. Create `.env`:
   ```bash
   cp .env.sample .env
   # edit .env and set FREEDNS_TOKEN, APP_DOMAIN, LOGS_DOMAIN
   ```

3. Start the stack:
   ```bash
   sudo docker compose up --build -d
   ```

4. Verify:
   - App health: `curl -fsS https://$APP_DOMAIN/ping`
   - UI: `https://$LOGS_DOMAIN` (prompts for Basic Auth)

Useful ops commands:

```bash
sudo docker compose ps
sudo docker compose logs -f --tail=200
sudo docker compose restart caddy
```

## Local Development (Without Docker)

This repo uses `uv` and targets Python `>=3.14` per [pyproject.toml](./pyproject.toml).

1. Install `uv` (see Astral `uv` docs) and ensure you have Python `3.14+`.
2. Sync dependencies:
   ```bash
   uv sync
   ```
3. Run the app:
   ```bash
   uv run python app.py
   ```
4. Open:
   - `http://localhost:5000/`
   - `http://localhost:5000/ping`

## GitHub Actions CI/CD (Deploy Over SSH)

Workflows live in [.github/workflows](./.github/workflows).

These workflows deploy by SSH-ing into your server and running `git pull` plus Docker Compose commands.

### Required GitHub Repository Secrets

Add these at: `Settings -> Secrets and variables -> Actions -> Repository secrets`

- `SSH_HOST`: server hostname or IP (example: `203.0.113.10`)
- `SSH_USER`: SSH username on the server (example: `pi`)
- `SSH_PASSWORD`: SSH password (used by `sshpass`)
- `WORK_DIR`: absolute path on the server where the repo is checked out (example: `/home/pi/Demo_Home_Page_Raspberry_PI`)
- `MAIN_BRANCH`: branch to deploy (example: `main`)

Notes:

- The workflows use `sudo docker ...` on the remote host. Your `SSH_USER` must be able to run those commands (either passwordless sudo, or configured accordingly).
- The `.env` file is expected to already exist on the server in `WORK_DIR` before deployments (Compose reads it locally on the server).
- Release Drafter uses the built-in `GITHUB_TOKEN` (no extra secret needed).

### What The Workflows Do

- `main.yml`: manual deploy, runs `git checkout $MAIN_BRANCH`, `git pull`, then `docker compose build` and `docker compose up -d`, then prunes images.
- `update_caddy.yml`: manual deploy, pulls latest and restarts only the `caddy` service.
- `clean-deploy.yml` and `rolling-release.yml`: these reference a `docker rollout` command and a `/tmp/drain` mechanism.
  - These workflows require the `docker-rollout` Docker CLI plugin to be installed on the target server: `https://github.com/wowu/docker-rollout`.
  - Install (per-user):
    ```bash
    mkdir -p ~/.docker/cli-plugins
    curl https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout -o ~/.docker/cli-plugins/docker-rollout
    chmod +x ~/.docker/cli-plugins/docker-rollout
    ```
  - If you use Docker with `sudo` (or want it available for all users), install it to `/usr/local/lib/docker/cli-plugins/` instead.
  - If you do not want to install `docker-rollout`, rewrite those workflows to use plain `docker compose up -d` / `docker compose restart` patterns.

### Local Testing Without Domains

Caddy is configured for hostnames (`APP_DOMAIN` and `LOGS_DOMAIN`). For local testing you can:

- Option A: run the Flask app directly (no Caddy):
  - `uv run python app.py` and open `http://localhost:5000`
- Option B: run Docker Compose but bypass Caddy by publishing the app port:
  - In [compose.yml](./compose.yml), uncomment the `ports:` mapping under `app` (`5000:5000`)
  - Then hit `http://localhost:5000`
- Option C: test Caddy locally using hosts file entries:
  - Add two local hostnames (example `app.local` and `logs.local`) mapped to `127.0.0.1`
  - Set `APP_DOMAIN=app.local` and `LOGS_DOMAIN=logs.local` in `.env`
  - Access `http://app.local` and `http://logs.local` (HTTPS locally may require trusting Caddy's local CA depending on how it's configured)

## Security Notes

- Do not commit `.env`. It contains credentials/tokens.
- Exposing `/var/run/docker.sock` (used by LazyDocker) gives the container root-equivalent control over your host. Keep `LOGS_DOMAIN` protected (Basic Auth, and ideally IP allowlisting/VPN).

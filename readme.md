# quake-container

![Personal Project](https://img.shields.io/badge/personal-project-blue)
![License](https://img.shields.io/badge/license-GPL--2.0-green)
![Container](https://img.shields.io/badge/ghcr.io-quake--container-blue?logo=docker)
![AMD64](https://img.shields.io/badge/arch-amd64-informational)
![ARM64](https://img.shields.io/badge/arch-arm64-informational)
![Upstream Sync](https://img.shields.io/github/actions/workflow/status/mmBesar/quake-container/sync-upstream.yml?label=upstream%20sync)
![Image Build](https://img.shields.io/github/actions/workflow/status/mmBesar/quake-container/image-build.yml?label=image%20build)
![Release Build](https://img.shields.io/github/actions/workflow/status/mmBesar/quake-container/release-build.yml?label=client%20build)

> ⚠️ **Personal Project**
> This is a personal project built for my own use. It is not affiliated with, endorsed by, or connected
> in any way to id Software, Bethesda, the vkQuake project, or the Frogbot project.
> Use at your own risk. No warranties are provided.

---

A fully automated, self-updating Quake server stack built on [vkQuake](https://github.com/Novum/vkQuake).
It tracks upstream vkQuake releases daily, builds multi-arch container images automatically,
and ships fixed-port client binaries for Linux AMD64 and ARM64.

---

## What's in this repo

| Component | Description |
|-----------|-------------|
| **Server container** | vkQuake dedicated server with [Frogbot v2](https://github.com/DrLex0/quake-frogbots) bots built in |
| **Client binaries** | vkQuake client with fixed UDP port 57613 for AMD64 and ARM64 |
| **Automation** | Daily upstream sync, automatic image builds, automatic client releases |

---

## Architecture

```
upstream vkQuake (Novum/vkQuake)
         │
         │  daily sync
         ▼
   upstream branch ──────────────────────────────────────────┐
         │                                                    │
         │  new tag detected                                  │  new tag detected
         ▼                                                    ▼
   image-build.yml                                   release-build.yml
   (server container)                                (client binaries)
         │                                                    │
    ┌────┴────┐                                       ┌───────┴───────┐
    │  AMD64  │  ARM64                                │     AMD64     │  ARM64
    └────┬────┘                                       └───────┬───────┘
         │                                                    │
         ▼                                                    ▼
   ghcr.io/mmbesar/quake-container                  GitHub Releases
   :latest  :1.33  :1.33.1                          vkquake-1.33.1-linux-amd64.AppImage
                                                    vkquake-1.33.1-linux-amd64.tar.gz
                                                    vkquake-1.33.1-linux-arm64.tar.gz
```

---

## Server — Quick Start

### Requirements

- Docker and Docker Compose
- Quake game files (you must own a legal copy of Quake)
  - Required: `id1/pak0.pak` and `id1/pak1.pak`

### 1. Prepare game files

Place your Quake game files on the host:

```
/srv/docker/cont/quake/game/
├── id1/
│   ├── pak0.pak      ← required
│   ├── pak1.pak      ← required
│   └── music/        ← optional
├── ctf/              ← optional mods
├── dopa/
├── hipnotic/
├── rogue/
└── ...
```

> **Note:** Do not create a `frogbot/` directory — Frogbot is built into the container image.

### 2. Configure

Copy `.env` and edit to your needs:

```bash
cp .env .env.local
nano .env.local
```

Key settings:

```env
# Host paths
CONTAINER_DIR=/srv/docker/cont

# Server identity
QUAKE_SERVER_NAME="My Quake Server"
QUAKE_MAX_PLAYERS=8
QUAKE_PORT=26000

# Admin (never commit this to git!)
QUAKE_ADMIN_PASSWORD=your_password_here

# Bots
QUAKE_ENABLE_BOTS=1
QUAKE_BOT_COUNT=4
QUAKE_BOT_SKILL=5      # Frogbot scale: 0=easiest, 10=challenging, 20=inhuman
```

### 3. Run

```bash
docker compose up -d
docker compose logs -f
```

### 4. Connect

Open your vkQuake client console with `~` and type:

```
connect <server_ip>:26000
```

---

## Server — Environment Variables

### Server Identity

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_SERVER_NAME` | `vkQuake Docker Server` | Name shown in server browser |
| `QUAKE_MAX_PLAYERS` | `8` | Maximum players (1–16) |
| `QUAKE_PORT` | `26000` | UDP port the server listens on |

### Game Mode

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_DEATHMATCH` | `1` | Deathmatch mode (1=on, 0=off) |
| `QUAKE_COOP` | `0` | Co-op mode (1=on, 0=off) |
| `QUAKE_TEAMPLAY` | `0` | Team play (1=on, 0=off) |
| `QUAKE_SKILL` | `1` | Monster skill 0–3 (coop only, ignored by bots) |

### Match Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_FRAGLIMIT` | `20` | Frags to end map (0=disabled) |
| `QUAKE_TIMELIMIT` | `15` | Minutes to end map (0=disabled) |
| `QUAKE_MAP` | `start` | Starting map |

### Admin

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_ADMIN_PASSWORD` | *(unset)* | RCON password — set at runtime only, never in image |

### Bots (Frogbot v2)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_ENABLE_BOTS` | `1` | Enable Frogbot mod (1=on, 0=off) |
| `QUAKE_BOT_COUNT` | `4` | Number of bots to add at start |
| `QUAKE_BOT_SKILL` | `5` | Bot difficulty: 0=easiest, 5=default, 10=challenging, 20=inhuman |

### Debug

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_CONDEBUG` | `1` | Write console output to `logs/qconsole.log` |

---

## Server — Admin

Use RCON to manage the server remotely from your client console:

```
rcon_password your_password_here
rcon status
rcon changelevel e1m1
rcon kick playername
rcon addbot
rcon removebot
```

---

## Server — Volumes

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `${CONTAINER_DIR}/quake/game/id1` | `/quake/game/id1` | Base game files |
| `${CONTAINER_DIR}/quake/game/ctf` | `/quake/game/ctf` | CTF mod |
| `${CONTAINER_DIR}/quake/game/dopa` | `/quake/game/dopa` | DOPA expansion |
| `${CONTAINER_DIR}/quake/game/hipnotic` | `/quake/game/hipnotic` | Mission Pack 1 |
| `${CONTAINER_DIR}/quake/game/rogue` | `/quake/game/rogue` | Mission Pack 2 |
| `${CONTAINER_DIR}/quake/config` | `/quake/config` | Server config (auto-generated) |
| `${CONTAINER_DIR}/quake/logs` | `/quake/logs` | Server logs |

---

## Client Binaries

Pre-built vkQuake client binaries with a fixed UDP source port (`57613`) are published
with every upstream release.

### Why a fixed port?

By default, vkQuake picks a random UDP port when connecting to a server. This makes
firewall rules hard to manage. The fixed port patch forces the client to always use
`57613` as its source port — one firewall rule, done forever.

### Firewall rule (client machine)

```bash
# Allow outbound UDP on port 57613
ufw allow out 57613/udp
```

### Download

Get the latest release from the [Releases page](https://github.com/mmBesar/quake-container/releases).

| File | Architecture |
|------|-------------|
| `vkquake-X.X.X-linux-amd64.AppImage` | AMD64 — portable, no install needed |
| `vkquake-X.X.X-linux-amd64.tar.gz` | AMD64 — binary archive |
| `vkquake-X.X.X-linux-arm64.tar.gz` | ARM64 — binary archive |

### Usage

```bash
# AppImage (AMD64)
chmod +x vkquake-1.33.1-linux-amd64.AppImage
./vkquake-1.33.1-linux-amd64.AppImage

# tar.gz (any arch)
tar -xzf vkquake-1.33.1-linux-arm64.tar.gz
./vkquake-1.33.1-linux-arm64/vkquake
```

---

## Automation

All automation runs on GitHub Actions with no manual intervention needed.

### Workflows

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `sync-upstream.yml` | Daily at midnight | Syncs upstream vkQuake source, detects new tags |
| `image-build.yml` | New upstream tag / main branch changes | Builds and pushes multi-arch container image |
| `release-build.yml` | New upstream tag (manual trigger) | Builds fixed-port client binaries and creates a GitHub Release |

### Container image tags

| Tag | Meaning |
|-----|---------|
| `latest` | Always points to the newest build |
| `1.33` | Minor version — updated with each patch |
| `1.33.1` | Exact upstream version |

### Pull the image

```bash
docker pull ghcr.io/mmbesar/quake-container:latest
```

---

## Bots — Frogbot v2

The server container ships with [Frogbot v2](https://github.com/DrLex0/quake-frogbots)
by [DrLex0](https://github.com/DrLex0) built in. Frogbot is a classic QuakeC bot mod
originally created by Robert 'Frog' Field in 1997, revived and improved in the v2 fork.

- Bot skill ranges from **0** (easiest) to **20** (inhuman) — much more granular than standard Quake's 0–3
- Supports **96 maps** out of the box with built-in waypoints
- Designed and tested specifically with vkQuake (NetQuake engine)
- Always fetches the **latest Frogbot release** at image build time

To disable bots and run a vanilla server, set `QUAKE_ENABLE_BOTS=0`.

---

## Building Locally

```bash
# Clone
git clone https://github.com/mmBesar/quake-container.git
cd quake-container

# Build image
docker build -t quake-container .

# Run
docker compose up -d
```

---

## Troubleshooting

**Server not visible on LAN**
- Check firewall: `sudo ufw allow 26000/udp`
- Verify Docker network allows UDP: `docker compose ps`

**Game files not found**
- Ensure `pak0.pak` exists at `${CONTAINER_DIR}/quake/game/id1/pak0.pak`
- Check ownership matches `PUID`/`PGID` in `.env`

**No bots in game**
- Verify `QUAKE_ENABLE_BOTS=1` in `.env`
- Check logs: `docker compose logs -f`
- Frogbot only works on supported maps — try `e1m1`, `dm4`, `aerowalk`

**Client can't connect (fixed-port binary)**
- Ensure nothing else is using port `57613`: `ss -uln | grep 57613`
- Allow `57613/udp` outbound on your client firewall

**View server logs**
```bash
docker compose logs -f
# or
tail -f ${CONTAINER_DIR}/quake/logs/qconsole.log
```

---

## Credits

This project stands on the shoulders of these fine people and their work:

| Project | Author(s) | License |
|---------|-----------|---------|
| [Quake](https://github.com/id-Software/Quake) | id Software | GPL-2.0 |
| [vkQuake](https://github.com/Novum/vkQuake) | Dominic Szablewski & contributors | GPL-2.0 |
| [Frogbot v2](https://github.com/DrLex0/quake-frogbots) | DrLex0, original by Robert 'Frog' Field | GPL-2.0 |
| [Frogbot waypoints](https://github.com/DrLex0/quake-frogbots) | Trinca and contributors | GPL-2.0 |

---

## License

This project (Dockerfile, entrypoint.sh, workflows) is released under the
[GNU GPL v2](https://github.com/Novum/vkQuake/blob/master/LICENSE.txt),
consistent with vkQuake and Frogbot.

Quake, id Software, and Bethesda are trademarks of their respective owners.
This project is not affiliated with or endorsed by any of them.

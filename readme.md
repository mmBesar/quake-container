# quake-container

![Build Container](https://github.com/mmBesar/quake-container/actions/workflows/image-build.yml/badge.svg)
![Build Client](https://github.com/mmBesar/quake-container/actions/workflows/release-build.yml/badge.svg)
![Sync Upstream](https://github.com/mmBesar/quake-container/actions/workflows/sync-upstream.yml/badge.svg)
![License](https://img.shields.io/badge/license-GPL--2.0-blue)
![Platform](https://img.shields.io/badge/platform-amd64%20%7C%20arm64%20%7C%20riscv64-lightgrey)

> ⚠️ **Personal Project**
> This repository is for **personal use only**. It is not affiliated with, endorsed by, or connected to id Software, Bethesda, vkQuake, QuakeSpasm, or any official Quake project. All trademarks belong to their respective owners. Use at your own risk. No warranties provided.

---

A personal self-hosted Quake server and client builder, based on [vkQuake](https://github.com/Novum/vkQuake). It automatically tracks upstream vkQuake releases, builds a multi-architecture Docker container image for the dedicated server, and builds patched client binaries for Linux.

## What This Repo Does

```
Upstream vkQuake releases
        ↓
  Syncs daily (sync-upstream.yml)
        ↓
  New tag detected?
        ↓
  ┌─────────────────────────────────┐
  │  Build server container image   │
  │  AMD64 + ARM64 (native runners) │
  │  Includes Frogbot v2 bots       │
  └─────────────────────────────────┘
        +
  ┌─────────────────────────────────┐
  │  Build patched client binaries  │
  │  AMD64 (AppImage + tar.gz)      │
  │  ARM64 (tar.gz, native build)   │
  │  RISC-V 64 (tar.gz, Debian 13)  │
  │  Port fix: client uses UDP 57613│
  └─────────────────────────────────┘
```

## Server Container

### Quick Start

1. Copy `.env.example` to `.env` and edit your settings
2. Place your Quake game files in `${CONTAINER_DIR}/quake/game/id1/`
3. Start the server:

```bash
docker compose up -d
docker logs -f quake
```

### Game Files

You need the original Quake game files (not included). The minimum required:

```
${CONTAINER_DIR}/quake/game/id1/pak0.pak
${CONTAINER_DIR}/quake/game/id1/pak1.pak   # optional but recommended
```

Optional expansion packs (mount as needed in `docker-compose.yml`):

| Directory | Content |
|-----------|---------|
| `hipnotic/` | Mission Pack 1: Scourge of Armagon |
| `rogue/` | Mission Pack 2: Dissolution of Eternity |
| `dopa/` | Episode 5: Dimension of the Past |
| `mg1/` | Quake 2021 re-release content |
| `ctf/` | Capture the Flag |

### Bots (Frogbot v2)

The server includes [Frogbot v2](https://github.com/DrLex0/quake-frogbots) built into the image — no setup needed.

To enable bots, set `QUAKE_ENABLE_BOTS=1` in your `.env`. After connecting to the server, add bots via the console:

```
addbot          // add one bot
addbot          // add another
removebot       // remove one bot
removeallbots   // remove all bots
```

Or via RCON from outside the game:
```
rcon addbot
```

Bot skill uses Frogbot's own 0-20 scale (set via `QUAKE_BOT_SKILL`):

| Value | Difficulty |
|-------|-----------|
| 0 | Easiest |
| 5 | Default |
| 10 | Challenging |
| 15 | Hard |
| 20 | Inhuman |

### Environment Variables

All settings are controlled via environment variables. Copy `.env.example` to `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAKE_SERVER_NAME` | `vkQuake Server` | Server name shown in browser |
| `QUAKE_MAX_PLAYERS` | `16` | Maximum players (including bots) |
| `QUAKE_PORT` | `26000` | Server UDP port |
| `QUAKE_DEATHMATCH` | `1` | Deathmatch mode (1=on, 0=off) |
| `QUAKE_COOP` | `0` | Cooperative mode (1=on, 0=off) |
| `QUAKE_TEAMPLAY` | `0` | Team play (0=off, 1=on, 2=friendly fire) |
| `QUAKE_SKILL` | `1` | Monster skill 0-3 (coop only, ignored by bots) |
| `QUAKE_FRAGLIMIT` | `20` | Frags to end match |
| `QUAKE_TIMELIMIT` | `10` | Minutes per map |
| `QUAKE_MAP` | `start` | Starting map |
| `QUAKE_MAP_ROTATION` | `start,e1m1,...` | Comma-separated map rotation list |
| `QUAKE_ROTATION_MODE` | `1` | Enable map rotation (1=on, 0=off) |
| `QUAKE_ENABLE_BOTS` | `1` | Load Frogbot mod (1=on, 0=vanilla) |
| `QUAKE_BOT_SKILL` | `5` | Bot difficulty 0-20 (Frogbot scale) |
| `QUAKE_MOD` | _(empty)_ | Load a custom mod directory instead |
| `QUAKE_ADMIN_PASSWORD` | _(empty)_ | RCON password (leave empty to disable) |
| `QUAKE_GRAVITY` | `800` | Server gravity |
| `QUAKE_MAX_SPEED` | `320` | Player max speed |
| `QUAKE_FRICTION` | `4` | Surface friction |
| `QUAKE_AIM` | `1` | Auto-aim (1=on, 0=off) |
| `QUAKE_PAUSABLE` | `0` | Allow pausing (1=on, 0=off) |
| `QUAKE_MEMORY` | `64` | RAM in MB allocated to server |
| `QUAKE_CONDEBUG` | `1` | Write console to logs/qconsole.log |
| `PUID` | `1000` | Host user ID for file permissions |
| `PGID` | `1000` | Host group ID for file permissions |

### Admin (RCON)

Set `QUAKE_ADMIN_PASSWORD` in your `.env`, then from any connected client:

```
rcon_password yourpassword
rcon status
rcon changelevel e1m1
rcon kick playername
rcon addbot
```

### Networking

The server uses `network_mode: host` by default for best UDP performance and LAN visibility. To use port mapping instead, edit `docker-compose.yml` (see comments inside).

**Firewall rule for server:**
```
allow udp in port 26000
```

---

## Client Binaries (Fixed Port)

The [Releases](https://github.com/mmBesar/quake-container/releases) page provides vkQuake client binaries with a port fix applied: the client always uses UDP port **57613** instead of a random port.

This makes firewall management easier — you only need one outbound UDP rule on your client machine.

**Firewall rule for client:**
```
allow udp out port 57613
```

### Available Builds

| File | Architecture | Format |
|------|-------------|--------|
| `vkquake-{version}-linux-amd64.AppImage` | AMD64 | Portable AppImage |
| `vkquake-{version}-linux-amd64.tar.gz` | AMD64 | Binary archive |
| `vkquake-{version}-linux-arm64.tar.gz` | ARM64 | Binary archive |
| `vkquake-{version}-linux-riscv64.tar.gz` | RISC-V 64 (rv64gc) | Binary archive |

> **RISC-V note:** Targets generic `rv64gc` — compatible with Orange Pi RV2, VisionFive 2, Milk-V Pioneer, and any modern RISC-V 64-bit board. Vulkan driver support on RISC-V is still maturing; the binary will be ready when drivers land on your board.

### Installation

**AppImage (AMD64):**
```bash
chmod +x vkquake-*-linux-amd64.AppImage
./vkquake-*-linux-amd64.AppImage
```

**tar.gz (all architectures):**
```bash
tar -xzf vkquake-*-linux-{arch}.tar.gz
cd vkquake-*/
./vkquake
```

---

## Repository Structure

```
quake-container/
├── Dockerfile              # Server container image (multi-stage)
├── entrypoint.sh           # Server startup script
├── docker-compose.yml      # Container orchestration
├── .env                    # Your local settings (not committed)
├── .env.example            # Settings template
└── .github/
    ├── dockerfiles/
    │   └── Dockerfile.riscv64   # RISC-V cross-compilation environment
    └── workflows/
        ├── sync-upstream.yml    # Daily upstream sync + trigger
        ├── image-build.yml      # Container image build + push
        └── release-build.yml    # Client binary builds + release
```

---

## How Automation Works

```
sync-upstream.yml (runs daily at 00:00 UTC)
  → fetches all tags from upstream vkQuake
  → compares with tags already in this repo
  → if new tag found:
      → syncs upstream branch
      → pushes new tag (with your workflows preserved)
      → triggers image-build.yml with the new tag

image-build.yml (triggered by sync or manually)
  → builds container image natively on AMD64 + ARM64
  → pushes to ghcr.io/mmbesar/quake-container
  → tags: latest, {version}, {major.minor}

release-build.yml (manual trigger only)
  → builds client binaries with UDP port fix
  → AMD64: upstream Docker build system → AppImage + tar.gz
  → ARM64: native build → tar.gz
  → RISC-V: cross-compiled in Debian 13 → tar.gz
  → creates GitHub Release with all files
```

---

## Credits

This project builds on the work of many others:

| Project | Author | License |
|---------|--------|---------|
| [vkQuake](https://github.com/Novum/vkQuake) | Kristian Duske & contributors | GPL-2.0 |
| [QuakeSpasm](https://sourceforge.net/projects/quakespasm/) | Various | GPL-2.0 |
| [Quake](https://github.com/id-Software/Quake) | id Software | GPL-2.0 |
| [Frogbot v2](https://github.com/DrLex0/quake-frogbots) | DrLex0 & contributors | GPL-2.0 |
| [Frogbot original](https://github.com/mittorn/frogbot) | Robert 'Frog' Field | GPL-2.0 |

### Tools & Services

- [GitHub Actions](https://github.com/features/actions) — CI/CD automation
- [GitHub Container Registry](https://ghcr.io) — Container image hosting
- [Docker Buildx](https://github.com/docker/buildx) — Multi-architecture builds
- [Debian](https://www.debian.org/) — RISC-V cross-compilation environment

---

## License

This repository follows the same license as vkQuake and QuakeSpasm: **GNU GPL v2**.

Quake, id Software, and Bethesda are trademarks of their respective owners.
All rights reserved by their respective parties.

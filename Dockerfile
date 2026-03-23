# =============================================================================
# Stage 1: Build vkQuake
# Source is provided by image-build.yml from the upstream branch
# =============================================================================
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies (from upstream's official docs)
RUN apt-get update && apt-get install -y \
    meson \
    ninja-build \
    gcc \
    g++ \
    pkg-config \
    curl \
    git \
    glslang-tools \
    spirv-tools \
    libsdl2-dev \
    libvulkan-dev \
    libvorbis-dev \
    libmpg123-dev \
    libflac-dev \
    libopusfile-dev \
    libx11-xcb-dev \
    && rm -rf /var/lib/apt/lists/*

# Build vkQuake using meson + ninja (upstream's preferred build system)
WORKDIR /build
COPY . .
RUN meson setup build && \
    ninja -C build && \
    strip build/vkquake

# =============================================================================
# Stage 2: Fetch Frogbot v2 (latest release)
# progs.dat from release archive + configs from repo at same tag
# =============================================================================
FROM ubuntu:24.04 AS frogbot

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /frogbot

RUN \
    # Get latest release info from GitHub API
    RELEASE=$(curl -sf https://api.github.com/repos/DrLex0/quake-frogbots/releases/latest) && \
    TAG=$(echo "$RELEASE" | jq -r '.tag_name') && \
    DOWNLOAD_URL=$(echo "$RELEASE" | jq -r '.assets[0].browser_download_url') && \
    echo "Fetching Frogbot $TAG from $DOWNLOAD_URL" && \
    \
    # Download and extract prebuilt progs.dat
    curl -sL "$DOWNLOAD_URL" -o frogbot-progs.tgz && \
    tar -xzf frogbot-progs.tgz && \
    \
    # Clone repo at same tag for configs, sounds
    git clone --depth 1 --branch "$TAG" https://github.com/DrLex0/quake-frogbots.git repo && \
    \
    # Assemble frogbot game directory
    mkdir -p /frogbot/game && \
    cp Release/quake/progs.dat     /frogbot/game/ && \
    cp repo/frogbot-quake.cfg      /frogbot/game/ && \
    cp -r repo/configs-quake       /frogbot/game/ && \
    cp -r repo/sound               /frogbot/game/ && \
    \
    # autoexec.cfg: loads frogbot config first, then our env-var overrides
    # are injected at runtime by entrypoint.sh
    echo "exec frogbot-quake.cfg" > /frogbot/game/autoexec.cfg

# =============================================================================
# Stage 3: Runtime image
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libsdl2-2.0-0 \
    libvorbis0a \
    libvorbisfile3 \
    libmpg123-0 \
    libflac12t64 \
    libopusfile0 \
    libx11-6 \
    libxcb1 \
    libvulkan1 \
    mesa-vulkan-drivers \
    iproute2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r quake && useradd -r -g quake quake

# Create directory structure
RUN mkdir -p /quake/{bin,game,config,logs} && \
    chown -R quake:quake /quake

# Copy vkQuake binary from builder
COPY --from=builder --chown=quake:quake /build/build/vkquake /quake/bin/vkquake

# Copy Frogbot game directory from frogbot stage
COPY --from=frogbot --chown=quake:quake /frogbot/game /quake/game/frogbot

# Copy entrypoint script
COPY --chown=quake:quake entrypoint.sh /quake/entrypoint.sh
RUN chmod +x /quake/entrypoint.sh

WORKDIR /quake

# Expose Quake server port (UDP)
EXPOSE 26000/udp

# =============================================================================
# Environment variables with defaults
# =============================================================================
ENV \
    # --- Server identity ---
    QUAKE_SERVER_NAME="vkQuake Docker Server" \
    QUAKE_MAX_PLAYERS="8" \
    QUAKE_PORT="26000" \
    \
    # --- Game mode (1=enable, 0=disable) ---
    # Only one of deathmatch/coop should be 1 at a time
    QUAKE_DEATHMATCH="1" \
    QUAKE_COOP="0" \
    QUAKE_TEAMPLAY="0" \
    \
    # --- Skill: standard Quake scale 0-3 ---
    # 0=Easy  1=Normal  2=Hard  3=Nightmare
    # Only relevant in coop/single-player with monsters
    # Has no effect in deathmatch with bots
    QUAKE_SKILL="1" \
    \
    # --- Match settings ---
    QUAKE_FRAGLIMIT="20" \
    QUAKE_TIMELIMIT="15" \
    \
    # --- Map settings ---
    QUAKE_MAP="start" \
    \
    # --- Admin ---
    QUAKE_ADMIN_PASSWORD="" \
    \
    # --- Bots (Frogbot v2) ---
    # Set to 1 to enable Frogbot mod, 0 for vanilla server
    QUAKE_ENABLE_BOTS="1" \
    # Number of bots to add at start (1-16)
    QUAKE_BOT_COUNT="4" \
    # Bot skill: Frogbot scale 0-20
    # 0=Easiest  5=Default  10=Challenging  20=Inhuman
    QUAKE_BOT_SKILL="5" \
    \
    # --- Debug ---
    # Set to 1 to write console output to logs/qconsole.log
    QUAKE_CONDEBUG="1"

# Health check using ss (iproute2) — checks UDP port is open
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD ss -uln | grep ":${QUAKE_PORT}" > /dev/null || exit 1

USER quake

ENTRYPOINT ["/quake/entrypoint.sh"]

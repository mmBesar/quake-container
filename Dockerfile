# =============================================================================
# Stage 1: Build vkQuake
# Source is provided by image-build.yml from the upstream branch
# =============================================================================
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies (from upstream's official build system)
RUN apt-get update && apt-get install -y \
    meson \
    ninja-build \
    gcc \
    g++ \
    pkg-config \
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
# Stage 2: Runtime image
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

# Copy vkQuake binary from builder stage
COPY --from=builder --chown=quake:quake /build/build/vkquake /quake/bin/vkquake

# Copy Frogbot game directory (prepared by image-build.yml before docker build)
COPY --chown=quake:quake frogbot/ /quake/game/frogbot/

# Copy entrypoint script
COPY --chown=quake:quake entrypoint.sh /quake/entrypoint.sh
RUN chmod +x /quake/entrypoint.sh

WORKDIR /quake

# Expose Quake server port (UDP)
EXPOSE 26000/udp

# =============================================================================
# Environment variables with defaults
# Note: QUAKE_ADMIN_PASSWORD is intentionally NOT set here.
#       Always pass it at runtime via .env or docker-compose to avoid
#       baking secrets into the image.
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

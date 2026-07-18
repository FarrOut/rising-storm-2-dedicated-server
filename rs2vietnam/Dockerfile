# ============================================================
# Rising Storm 2: Vietnam Dedicated Server
# App ID: 418480 (Windows-only binary, runs under Wine)
#
# Uses Linux SteamCMD with a platform override config to
# download the Windows depot, then runs it under Wine.
#
# First run — add to .env temporarily:
#   STEAM_USER=your_username
#   STEAM_PASS=your_password
#   STEAM_GUARD=your_guard_code
# Delete those lines after first successful start.
# ============================================================
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Wine, curl, and lib32 dependencies
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        wine \
        wine32 \
        wine64 \
        winbind \
        curl \
        ca-certificates \
        lib32gcc-s1 \
        lib32stdc++6 \
        unzip \
        python3 \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install Linux SteamCMD
RUN set -eux; \
    mkdir -p /home/steam/steamcmd; \
    curl -fsSL -o /tmp/steamcmd_linux.tar.gz \
        "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"; \
    tar -xzf /tmp/steamcmd_linux.tar.gz -C /home/steam/steamcmd; \
    rm /tmp/steamcmd_linux.tar.gz

# Create steam user
RUN useradd -m -u 1000 steam; \
    chown -R steam:steam /home/steam

COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

USER steam
WORKDIR /home/steam

VOLUME ["/home/steam/rs2vietnam"]

EXPOSE 7777/udp
EXPOSE 27015/udp
EXPOSE 8080/tcp

ENTRYPOINT ["/home/steam/entrypoint.sh"]

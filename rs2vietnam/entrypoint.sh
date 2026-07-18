#!/bin/bash
# ============================================================
# Entrypoint for Rising Storm 2: Vietnam Dedicated Server
# ============================================================
set -e

INSTALL_DIR="/home/steam/rs2vietnam"
STEAMCMD="/home/steam/steamcmd/steamcmd.sh"
BINARY="${INSTALL_DIR}/Binaries/Win64/VNGame.exe"

# ---- Download server files on first run ----
if [ ! -f "${BINARY}" ]; then
    echo "============================================================"
    echo " Server files not found. Starting first-run installation..."
    echo " This will download ~22 GB — please wait."
    echo "============================================================"

    if [ -z "${STEAM_USER}" ]; then
        echo "ERROR: STEAM_USER is not set. Cannot download server files."
        echo "Add STEAM_USER, STEAM_PASS (and optionally STEAM_GUARD) to"
        echo "your .env file for the first run, then remove them after."
        exit 1
    fi

    mkdir -p "${INSTALL_DIR}"

    # Write a SteamCMD config that forces Windows platform download.
    # This is the key trick: we set the OS/platform in the config file
    # before SteamCMD reads it, bypassing the depot platform restriction.
    mkdir -p /home/steam/Steam/config
    cat > /home/steam/Steam/config/config.vdf << 'EOF'
"InstallConfigStore"
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "CompatToolMapping"
                {
                }
            }
        }
    }
}
EOF

    # Build login args
    LOGIN_ARGS="${STEAM_USER} ${STEAM_PASS}"
    if [ -n "${STEAM_GUARD}" ]; then
        LOGIN_ARGS="${LOGIN_ARGS} ${STEAM_GUARD}"
    fi

    # Copy cached Steam credentials into place (token from initial login)
    mkdir -p /home/steam/Steam/config
    if [ -f "/home/steam/steamcmd-state/config/config.vdf" ]; then
        cp /home/steam/steamcmd-state/config/config.vdf /home/steam/Steam/config/config.vdf
        echo "[rs2] Cached Steam credentials found — skipping 2FA."
    else
        echo "[rs2] Warning: no cached credentials found, 2FA may be required."
    fi

    # Use Linux SteamCMD with platform override flags
    "${STEAMCMD}" \
        +force_install_dir "${INSTALL_DIR}" \
        +login ${LOGIN_ARGS} \
        +@sSteamCmdForcePlatformType windows \
        +@sSteamCmdForcePlatformBitness 64 \
        +app_update 418480 validate \
        +quit

    if [ ! -f "${BINARY}" ]; then
        echo "ERROR: Download completed but server binary not found at:"
        echo "  ${BINARY}"
        echo "Listing install dir contents:"
        find "${INSTALL_DIR}" -maxdepth 3 -type f -name "*.exe" 2>/dev/null || true
        exit 1
    fi

    echo "============================================================"
    echo " Installation complete!"
    echo " Remove STEAM_USER, STEAM_PASS, STEAM_GUARD from .env."
    echo "============================================================"
else
    echo "[rs2] Server files found. Skipping installation."
fi

# ---- Launch server under Wine ----
LAUNCH_ARGS=(
    "server"
    "${RS2_MAP:-VNTE-AnLaoValley}?game=ROGame.ROTeamGame"
    "?maxplayers=${RS2_MAX_PLAYERS:-32}"
    "-nohomedir"
    "-multihome=0.0.0.0"
    "-Port=${RS2_GAME_PORT:-7777}"
    "-QueryPort=${RS2_QUERY_PORT:-27015}"
    "-WebAdminPort=${RS2_WEB_ADMIN_PORT:-8080}"
    "-log"
)

if [ -n "${RS2_PASSWORD}" ]; then
    LAUNCH_ARGS+=("?password=${RS2_PASSWORD}")
fi

echo "============================================================"
echo " Starting Rising Storm 2: Vietnam Dedicated Server"
echo " Map        : ${RS2_MAP:-VNTE-AnLaoValley}"
echo " Players    : ${RS2_MAX_PLAYERS:-32}"
echo " Game port  : ${RS2_GAME_PORT:-7777}/udp"
echo " Query port : ${RS2_QUERY_PORT:-27015}/udp"
echo " Web admin  : ${RS2_WEB_ADMIN_PORT:-8080}/tcp"
echo "============================================================"

exec WINEDEBUG=-all wine "${BINARY}" "${LAUNCH_ARGS[@]}"

#!/usr/bin/env pwsh
# ============================================================
# fightclub.ps1 — manage the Fight Club game server stack
#
# Usage:
#   .\fightclub.ps1 up        — start everything
#   .\fightclub.ps1 down      — stop everything
#   .\fightclub.ps1 up ts     — start Tailscale only
#   .\fightclub.ps1 up ss     — start Sandstorm only
#   .\fightclub.ps1 up rs2    — start RS2 Vietnam only
#   .\fightclub.ps1 logs rs2  — follow RS2 logs
#   .\fightclub.ps1 logs ss   — follow Sandstorm logs
# ============================================================

$ROOT = $PSScriptRoot
$ENV_FILE = "$ROOT\.env"

$TS  = "-f `"$ROOT\docker-compose.tailscale.yml`" --env-file `"$ENV_FILE`""
$SS  = "-f `"$ROOT\sandstorm\docker-compose.yml`" --env-file `"$ENV_FILE`""
$RS2 = "-f `"$ROOT\rs2vietnam\docker-compose.yml`" --env-file `"$ENV_FILE`""

function Invoke-Compose($args_str) {
    Invoke-Expression "docker compose $args_str"
}

switch ($args[0]) {
    "up" {
        switch ($args[1]) {
            "ts"  { Invoke-Compose "$TS up -d" }
            "ss"  { Invoke-Compose "$SS up -d" }
            "rs2" { Invoke-Compose "$RS2 up -d" }
            default {
                Invoke-Compose "$TS up -d"
                Invoke-Compose "$SS up -d"
                Invoke-Compose "$RS2 up -d"
            }
        }
    }
    "down" {
        switch ($args[1]) {
            "ts"  { Invoke-Compose "$TS down" }
            "ss"  { Invoke-Compose "$SS down" }
            "rs2" { Invoke-Compose "$RS2 down" }
            default {
                Invoke-Compose "$RS2 down"
                Invoke-Compose "$SS down"
                Invoke-Compose "$TS down"
            }
        }
    }
    "logs" {
        switch ($args[1]) {
            "ts"  { Invoke-Compose "$TS logs -f" }
            "ss"  { Invoke-Compose "$SS logs -f" }
            "rs2" { Invoke-Compose "$RS2 logs -f" }
            default { Write-Host "Specify a service: ts, ss, rs2" }
        }
    }
    default {
        Write-Host "Usage: .\fightclub.ps1 [up|down|logs] [ts|ss|rs2]"
    }
}

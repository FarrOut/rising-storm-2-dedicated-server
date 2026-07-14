# Insurgency: Sandstorm — Dedicated Server (Docker)

Runs an **Insurgency: Sandstorm** dedicated server inside a Docker container using [cm2network/steamcmd](https://hub.docker.com/r/cm2network/steamcmd) as the base image.

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / macOS / Linux)
- The two UDP ports below open in your firewall / router if you want the server to be publicly visible

| Port  | Protocol | Purpose                    |
|-------|----------|----------------------------|
| 27102 | UDP      | Game (clients connect here)|
| 27131 | UDP      | Steam query / server list  |

---

## Quick start

```bash
# 1. Pull the image and start the server
#    (first run downloads ~10 GB of server files into ./data — grab a coffee)
docker compose up -d

# 2. Follow the logs
docker compose logs -f
```

> No build step needed. The setup uses the pre-built [`andrewmhub/insurgency-sandstorm:lite`](https://hub.docker.com/r/andrewmhub/insurgency-sandstorm) image, which downloads and stores all game files into the `./data` volume on first start.

The server will be visible in the **Insurgency: Sandstorm** in-game server browser once it finishes loading.

---

## Configuration

All tuneable values live in `docker-compose.yml` under `environment`:

| Variable      | Default                                        | Description                              |
|---------------|------------------------------------------------|------------------------------------------|
| `SERVER_NAME` | `My Sandstorm Server`                          | Name shown in the server browser         |
| `MAP`         | `Farmhouse`                                    | Starting map                             |
| `SCENARIO`    | `Scenario_Farmhouse_Checkpoint_Security`       | Game mode scenario                       |
| `MAX_PLAYERS` | `10`                                           | Maximum concurrent players               |
| `GAME_PORT`   | `27102`                                        | UDP game port                            |
| `QUERY_PORT`  | `27131`                                        | UDP Steam query port                     |
| `GSLT_TOKEN`  | *(empty)*                                      | Optional Steam Game Server Login Token   |
| `EXTRA_ARGS`  | *(empty)*                                      | Any extra launch flags                   |

### Deep configuration (INI files)

Edit the files in `config/` before building:

- `config/Game.ini` — round times, respawn waves, voting, etc.
- `config/Engine.ini` — network bandwidth settings
- `config/Admins.txt` — one Steam64 ID per line for admin access

### Persisted data

Everything under `/home/steam/sandstorm/Insurgency/Saved` is mounted to `./data/` on your host. This includes map downloads, user saves, and any config files the server generates. It survives image rebuilds.

---

## Useful scenarios

```
# Push/Pull checkpoint (Security attacking)
Scenario_Farmhouse_Checkpoint_Security
Scenario_Farmhouse_Checkpoint_Insurgents

# Push
Scenario_Farmhouse_Push_Security

# Skirmish
Scenario_Farmhouse_Skirmish
```

Other maps: `Ministry`, `Precinct`, `Refinery`, `Summit`, `Tell`, `Crossing`, `Hideout`, `Bab`, `Canyon`, `Outskirts`, `Sinjar`, `Tideway`

---

## Updating the server

Because game data lives in `./data` (not the image), updates happen automatically on container restart — the image's entrypoint runs SteamCMD on startup to pull the latest version.

To update the image itself (the wrapper):

```bash
docker compose pull
docker compose up -d
```

---

## Getting a GSLT token (optional but recommended)

1. Go to <https://steamcommunity.com/dev/managegameservers>
2. Create a token for App ID **581330**
3. Set it as `GSLT_TOKEN` in `docker-compose.yml`

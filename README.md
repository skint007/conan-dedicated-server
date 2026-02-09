# Conan Exiles Dedicated Server (Docker)

A Docker image for running a Conan Exiles Dedicated Server on Linux via Wine, using `steamcmd/steamcmd` as the base image.

The game server files are downloaded on first startup and persisted in a Docker volume, keeping the image itself small.

## Quick Start

#### Using `docker compose`:
```yaml
services:
  conan-server:
    image: ghcr.io/skint007/conan-dedicated-server:latest
    ports:
      - "7777:7777/udp"
      - "7778:7778/udp"
      - "27015:27015/udp"
    volumes:
      - conan-data:/home/steam/conan-dedicated
    environment:
      - PUID=1000
      - PGID=1000
      - CONAN_ARGS=-log -nosteam
      # - SERVER_EXE=ConanSandboxServer-Win64-Test.exe
    restart: unless-stopped

volumes:
  conan-data:

```

```bash
docker compose up -d
```

Or with `docker run`:

```bash
docker run -d \
    --name conan-server \
    -p 7777:7777/udp \
    -p 7778:7778/udp \
    -p 27015:27015/udp \
    -v conan-data:/home/steam/conan-dedicated \
    -e PUID=1000 \
    -e PGID=1000 \
    ghcr.io/<your-username>/conan-dedicated-server:latest
```

The first startup will take a while as the game server files (~40GB) are downloaded via SteamCMD.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for the steam user running the server |
| `PGID` | `1000` | Group ID for the steam user |
| `CONAN_ARGS` | `-log -nosteam` | Arguments passed to the Conan server executable |
| `SERVER_EXE` | `ConanSandboxServer-Win64-Test.exe` | Server executable name |
| `STEAMAPPID` | `443030` | Steam App ID for Conan Exiles Dedicated Server |
| `STEAMAPPDIR` | `/home/steam/conan-dedicated` | Game installation directory |

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `7777` | UDP | Game port |
| `7778` | UDP | Game port |
| `27015` | UDP | Steam query port |

## Volumes

| Path | Description |
|------|-------------|
| `/home/steam/conan-dedicated` | Game server files, configuration, and save data |

Server configuration files are located at:
```
/home/steam/conan-dedicated/ConanSandbox/Saved/Config/WindowsServer/
```

Key config files:
- `ServerSettings.ini` — server gameplay settings
- `Engine.ini` — engine/network settings
- `Game.ini` — game rules

## Mod Support

1. Create a `modlist.txt` file in the root of the game volume (`/home/steam/conan-dedicated/modlist.txt`)
2. Add one Steam Workshop mod ID per line:
   ```
   880454836
   1159180273
   ```
3. Restart the container — mods will be downloaded and linked automatically on startup

## Building Locally

```bash
docker build -t conan-dedicated-server .
```

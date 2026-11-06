# RavaLink Eggs

Official [Pterodactyl](https://pterodactyl.io/) and [Pelican](https://pelican.dev/) egg for the native Rust RavaLink server.

The same egg JSON can be imported into either panel.

## Install

1. Open **Nests / Eggs** in Pelican or Pterodactyl and import `egg-ravalink.json`.
2. Create a server with the **RavaLink (official)** Docker image.
3. Allocate the port configured by the egg (default: `2333`).
4. Set a long, unique `RAVALINK_PASSWORD` before the first start.
5. Start the server. Wings pulls the official image from GHCR automatically.

No installation script, startup downloader, or runtime package bootstrap is required. The GHCR package must be set to **Public** so Wings can pull it without registry credentials.

## Official Docker image

`ghcr.io/ravalink-project/ravalink:latest`

The image is built for `linux/amd64` and `linux/arm64`, uses the Pterodactyl Debian yolk's non-root container setup and STARTUP-aware entrypoint, and contains the verified RavaLink release binary. The binary is downloaded and checked against the release's `SHA256SUMS` at image-build time, not when a server starts.

## Updating

Every published GitHub Release automatically triggers a multi-architecture GHCR image build. The workflow publishes both a versioned image (for example `ghcr.io/ravalink-project/ravalink:v1.0.0-rc.1`) and the moving `latest` tag. To force an existing server to pull the updated image, use the panel's reinstall action.

## Configuration

The egg exposes the native RavaLink environment variables, including:

- `RAVALINK_PORT`, `RAVALINK_ADDRESS`, `RAVALINK_PASSWORD`
- `RAVALINK_LOG_LEVEL`, `RAVALINK_PLAYER_UPDATE_INTERVAL`
- Audio buffer, Opus quality, resampling and memory limits
- Prometheus enablement and endpoint

RavaLink uses its built-in defaults when no TOML configuration file is supplied.

## Compatibility and support

This is a deployment egg, not a claim that RavaLink is already a complete drop-in replacement for Lavalink v4. Check the main repository's compatibility notes before using it for production workloads.

- Main project: https://github.com/Ravalink-Project/Ravalink
- Issues: https://github.com/Ravalink-Project/Ravalink-eggs/issues

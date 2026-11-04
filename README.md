# RavaLink Eggs

Official [Pterodactyl](https://pterodactyl.io/) and [Pelican](https://pelican.dev/) egg for the native Rust RavaLink server.

The same egg JSON can be imported into either panel.

## Install

1. Open **Nest / Eggs** in your panel and import `egg-ravalink.json`.
2. Create a server with the RavaLink egg and the Debian yolk image.
3. Allocate the port configured by the egg (default: `2333`).
4. Set a long, unique `RAVALINK_PASSWORD` before the first start.
5. Start the server.

## Always tracks the latest published release

The startup script queries the GitHub Releases API for:

`Ravalink-Project/Ravalink`

It selects GitHub's latest published stable release (not a branch, commit, draft, or prerelease). It downloads the matching binary only when the release tag changes, then starts it. Restarting the server is enough to pick up a newly published release.

Expected release asset names:

| Linux architecture | Asset |
| --- | --- |
| x86_64 / amd64 | `ravalink-linux-x86_64` |
| aarch64 / arm64 | `ravalink-linux-aarch64` |

Assets must be standalone Linux GNU binaries for the matching architecture. The egg deliberately fails with a clear error if no published release or matching asset exists; it never silently falls back to an unstable branch build.

> **First-release note:** the main repository currently has no published GitHub Release. The egg can be imported now, but the first server start will report that no release is available until a release with one of the assets above is published.

## Updating

No manual version variable is needed. On every boot, the script checks the latest release tag and updates the local executable if necessary. If GitHub is temporarily unavailable, the server does not silently run an outdated binary: startup stops with the download/check error.

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

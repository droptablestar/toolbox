# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repo defines a Docker "toolbox" image (`droptablestar/toolbox`) based on Ubuntu 24.04. It includes dev tools (git, gh, Node.js 20, Python 3, Docker CLI, ripgrep, fd), media tools (ffmpeg, yt-dlp, mkvtoolnix, handbrake-cli), Intel GPU drivers, and global npm packages (`claude-code`, `opencode-ai`).

## Commands

**Build:**
```bash
docker build -t toolbox .
docker build -t droptablestar/toolbox:1.0 .
```

**Push to Docker Hub** (builds fresh with `--no-cache --pull`, then pushes):
```bash
./push_to_dockerhub.sh          # pushes :latest
./push_to_dockerhub.sh 1.0      # pushes :latest and :1.0
```

**Run:**
```bash
docker run -it --rm toolbox
docker run -it --rm -v /mnt:/mnt toolbox           # with volume mount
docker run -it --rm --device /dev/dri toolbox      # with Intel GPU
```

## Architecture

Single-stage `Dockerfile` — no build artifacts, no tests. All changes are to the `Dockerfile` itself (apt installs, npm globals, etc.).

### entrypoint.sh

Runs as root on startup, then drops to a non-root user via `gosu`. It:
- Creates a user/group matching `PUID`/`PGID` env vars (default `99`/`100`, matching Unraid's `nobody:users`)
- Detects the Docker socket GID at runtime and adds the toolbox user to that group (enables Docker-in-Docker access without hardcoding a GID)
- Detects Intel GPU device GIDs (`/dev/dri/renderD128`, `/dev/dri/card0`) and adds the user to those groups
- Fixes ownership of `/root` and `/tmp/.cache` for the resolved user
- Execs the CMD as the toolbox user

### Key details

- `fd` is installed as `fdfind` (Debian package name) with a symlink to `fd` at `/usr/local/bin/fd`
- npm global prefix is `/usr/local`, so global packages land in `/usr/local/lib/node_modules` and `/usr/local/bin`; entrypoint chowns these to allow the non-root user to install globals at runtime
- `XDG_CACHE_HOME=/tmp/.cache` keeps cache out of `/root` during image build layers

### Unraid deployment

The container is designed to run persistently (`sleep infinity` post-arg) with these path mappings:

| Container Path | Host Path |
|---|---|
| `/var/run/docker.sock` | `/var/run/docker.sock` |
| `/mnt/user` | `/mnt/user` |
| `/opt/toolbox` | `/mnt/user/appdata/toolbox` |
| `/root` | `/mnt/user/appdata/toolbox/home` |

`/root` → `home/` provides a persistent home directory (claude/opencode configs, shell history, etc.). The `home/` directory is gitignored runtime state and should not be modified as part of this repo.

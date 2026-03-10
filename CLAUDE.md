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

**Push to Docker Hub:**
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

Single-stage `Dockerfile` — no build artifacts, no tests. All changes are to the `Dockerfile` itself (apt installs, npm globals, etc.). The `home/` directory is gitignored runtime state and should not be modified as part of this repo.

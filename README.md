# Toolbox

An Ubuntu 24.04-based Docker build server with a curated set of development and media tools.

## Included Tools

- **Core utilities**: git, curl, wget, jq, tmux, screen, rsync, etc.
- **Editors**: Emacs (no X)
- **Video**: ffmpeg, mediainfo, mkvtoolnix, HandBrake CLI, yt-dlp
- **Python**: python3, pip
- **Network**: net-tools, ping, dig, openssh-client
- **Build**: gcc/make (build-essential), cmake
- **Search**: fd, ripgrep
- **CLI tools**: GitHub CLI (`gh`), Docker CLI + Compose plugin
- **Runtime**: Node.js 20, opencode-ai
- **GPU**: Intel QSV / VA-API support

## Building the Image

```bash
docker build -t toolbox .
```

To tag with a version:

```bash
docker build -t toolbox:1.0 .
```

## Running a Container

```bash
docker run -it --rm toolbox
```

To mount your current directory:

```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace toolbox
```

To enable Intel GPU access for hardware transcoding:

```bash
docker run -it --rm --device /dev/dri:/dev/dri toolbox
```

## Unraid Docker Template Setup

Configure the following path mappings in the Unraid Docker template:

| Container Path | Host Path | Access Mode | Notes |
|----------------|-----------|-------------|-------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | Read/Write | Access host Docker daemon |
| `/mnt/user` | `/mnt/user` | Read/Write | Access Unraid user shares |
| `/opt/toolbox` | `/mnt/user/appdata/toolbox` | Read/Write | Toolbox appdata |
| `/root` | `/mnt/user/appdata/toolbox/home` | Read/Write | Persistent home directory (includes `.config/` for claude, opencode, etc.) |

> **Note:** The `/root` mapping already persists all app configs. Do **not** add a separate `/root/.config` mapping — it creates a split home directory and serves no additional benefit.

**Extra Parameters:**
```
--device /dev/dri:/dev/dri --group-add video --hostname=toolbox
```

**Post Arguments:**
```
sleep infinity
```

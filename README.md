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

To access the host's Docker daemon from inside the container (enabling `docker ps`, `docker logs`, etc. against Unraid containers), add a path mapping in the Unraid Docker template:

| Field | Value |
|-------|-------|
| Container Path | `/var/run/docker.sock` |
| Host Path | `/var/run/docker.sock` |
| Access Mode | Read/Write |

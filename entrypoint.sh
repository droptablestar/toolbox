#!/bin/bash
set -euo pipefail

PUID=${PUID:-99}
PGID=${PGID:-100}

echo "[entrypoint] PUID=${PUID} PGID=${PGID}"

# Group setup: create group with PGID if none exists
if ! getent group "${PGID}" > /dev/null 2>&1; then
    groupadd --gid "${PGID}" toolbox
fi
TOOLBOX_GROUP=$(getent group "${PGID}" | cut -d: -f1)

# User setup: create user with PUID if none exists
if ! getent passwd "${PUID}" > /dev/null 2>&1; then
    useradd --uid "${PUID}" --gid "${PGID}" --home /root \
            --no-create-home --shell /bin/bash toolbox
fi
TOOLBOX_USER=$(getent passwd "${PUID}" | cut -d: -f1)

# Ensure user's primary group and home dir are correct
usermod --gid "${PGID}" "${TOOLBOX_USER}" 2>/dev/null || true
usermod --home /root "${TOOLBOX_USER}" 2>/dev/null || true

# Fix /root ownership (just the dir itself, not recursive)
chown "${PUID}:${PGID}" /root

# XDG cache dir
mkdir -p /tmp/.cache
chown "${PUID}:${PGID}" /tmp/.cache

# Docker socket: add user to the socket's group.
# groupmod is used when the image already has a 'docker' group from docker-ce-cli
# with a different GID than the host socket — groupadd would fail silently in that case.
if [ -S /var/run/docker.sock ]; then
    SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    SOCK_GROUP=$(getent group "${SOCK_GID}" | cut -d: -f1)
    if [ -z "${SOCK_GROUP}" ]; then
        if getent group docker > /dev/null 2>&1; then
            groupmod --gid "${SOCK_GID}" docker 2>/dev/null || true
        else
            groupadd --gid "${SOCK_GID}" docker 2>/dev/null || true
        fi
        SOCK_GROUP=$(getent group "${SOCK_GID}" | cut -d: -f1 || true)
    fi
    [ -n "${SOCK_GROUP}" ] && usermod -aG "${SOCK_GROUP}" "${TOOLBOX_USER}" 2>/dev/null || true
fi

# Intel GPU devices: add user to render/video groups
for dev in /dev/dri/renderD128 /dev/dri/card0; do
    if [ -e "${dev}" ]; then
        DEV_GID=$(stat -c '%g' "${dev}")
        DEV_GROUP=$(getent group "${DEV_GID}" | cut -d: -f1)
        if [ -z "${DEV_GROUP}" ]; then
            if getent group render > /dev/null 2>&1; then
                groupmod --gid "${DEV_GID}" render 2>/dev/null || true
            else
                groupadd --gid "${DEV_GID}" render 2>/dev/null || true
            fi
            DEV_GROUP=$(getent group "${DEV_GID}" | cut -d: -f1 || true)
        fi
        [ -n "${DEV_GROUP}" ] && usermod -aG "${DEV_GROUP}" "${TOOLBOX_USER}" 2>/dev/null || true
    fi
done

# Allow toolbox user to write npm globals
chown -R "${PUID}:${PGID}" /usr/local/lib/node_modules
chown -R "${PUID}:${PGID}" /usr/local/bin

exec gosu "${TOOLBOX_USER}" "$@"

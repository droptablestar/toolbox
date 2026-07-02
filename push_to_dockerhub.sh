#!/bin/bash
set -euo pipefail

IMAGE="droptablestar/toolbox"
EXTRA_TAG="${1:-}"

if [[ -z "${EXTRA_TAG}" ]]; then
  read -rp "Tag this build with today's date and create a GitHub release? [y/N] " REPLY
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    EXTRA_TAG="$(date +%Y-%m-%d)"
  fi
fi

echo "Building ${IMAGE}:latest..."
docker build --pull --no-cache -t "${IMAGE}:latest" .

echo "Pushing ${IMAGE}:latest..."
docker push "${IMAGE}:latest"

if [[ -n "${EXTRA_TAG}" ]]; then
  echo "Tagging ${IMAGE}:latest as ${IMAGE}:${EXTRA_TAG}..."
  docker tag "${IMAGE}:latest" "${IMAGE}:${EXTRA_TAG}"

  echo "Pushing ${IMAGE}:${EXTRA_TAG}..."
  docker push "${IMAGE}:${EXTRA_TAG}"

  echo "Tagging git commit as v${EXTRA_TAG}..."
  git tag "v${EXTRA_TAG}"
  git push origin "v${EXTRA_TAG}"

  echo "Creating GitHub Release v${EXTRA_TAG}..."
  gh release create "v${EXTRA_TAG}" \
    --title "v${EXTRA_TAG}" \
    --generate-notes
fi

echo "Done."

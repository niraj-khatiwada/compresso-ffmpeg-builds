#!/usr/bin/env bash
# Builds CompressO's ffmpeg & ffprobe for Windows or Linux, in BtbN's FFmpeg-Builds image (its
# libraries are already compiled there; see `compile.sh`). Needs Docker. Used by
# `.github/workflows/ffmpeg.yml`; can also run locally.
#
# Usage: scripts/ffmpeg/build.sh <win64|linux64> <ffmpeg version, e.g. 8.0.1> [output folder]
set -euo pipefail

TARGET="$1"
VERSION="$2"
OUT="${3:-$PWD/ffmpeg-out/$TARGET}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
IMAGE="ghcr.io/btbn/ffmpeg-builds/${TARGET}-gpl:latest"

mkdir -p "$OUT"
docker pull --platform linux/amd64 "$IMAGE"
# The exact image used, so a build can be repeated
docker image inspect --format '{{index .RepoDigests 0}}' "$IMAGE" > "$OUT/image.txt"

docker run --rm --platform linux/amd64 \
  -e TARGET="$TARGET" -e VERSION="$VERSION" \
  -v "$SCRIPTS:/scripts:ro" -v "$OUT:/out" \
  "$IMAGE" bash /scripts/compile.sh

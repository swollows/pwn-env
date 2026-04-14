#!/bin/bash
# ============================================================
# build-all.sh
# Ubuntu 18.04 / 20.04 / 22.04 / 24.04 x86_64 포너블 이미지 빌드
#
# 사용법:
#   ./build-all.sh          ← 4개 전부 빌드
#   ./build-all.sh 22.04    ← 22.04만 빌드
# ============================================================

set -e

VERSIONS=("18.04" "20.04" "22.04" "24.04")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "$1" ]; then
  VERSIONS=("$1")
fi

for VER in "${VERSIONS[@]}"; do
  TAG="pwn-x86:${VER}"
  echo ""
  echo "=========================================="
  echo " Building ${TAG}"
  echo "=========================================="
  echo ""

  podman build \
    --platform linux/amd64 \
    --build-arg UBUNTU_VERSION="${VER}" \
    -t "${TAG}" \
    "${SCRIPT_DIR}"

  echo ""
  echo "[OK] ${TAG} 빌드 완료"
done

echo ""
echo "=========================================="
echo " 빌드 완료된 이미지 목록"
echo "=========================================="
podman images | grep pwn-x86

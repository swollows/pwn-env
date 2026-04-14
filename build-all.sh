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
  CONTAINER_NAME="pwn-${VER//\./-}"

  echo ""
  echo "=========================================="
  echo " Building ${TAG}"
  echo "=========================================="
  echo ""

  # 기존 컨테이너 제거
  if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
    echo "[*] 기존 컨테이너 ${CONTAINER_NAME} 제거"
    podman rm -f "${CONTAINER_NAME}"
  fi

  # 기존 이미지 제거
  if podman image exists "${TAG}" 2>/dev/null; then
    echo "[*] 기존 이미지 ${TAG} 제거"
    podman rmi -f "${TAG}"
  fi

  podman build \
    --platform linux/amd64 \
    --no-cache \
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

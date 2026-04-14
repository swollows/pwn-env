#!/bin/bash
# ============================================================
# run.sh
# 포너블 컨테이너 실행/접속 스크립트
#
# 사용법:
#   ./run.sh 22.04          ← Ubuntu 22.04 컨테이너 시작 및 접속
#   ./run.sh 18.04          ← Ubuntu 18.04 컨테이너 시작 및 접속
#   ./run.sh 24.04 stop     ← Ubuntu 24.04 컨테이너 정지
#   ./run.sh 22.04 rm       ← Ubuntu 22.04 컨테이너 삭제
#   ./run.sh list           ← 전체 컨테이너 상태 확인
# ============================================================

set -e

WORKSPACE="${HOME}/pwn-workspace"
mkdir -p "${WORKSPACE}"

# list 명령
if [ "$1" = "list" ]; then
    echo "=== 포너블 컨테이너 상태 ==="
    podman ps -a --filter "name=pwn-" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    exit 0
fi

# 버전 인자 확인
VER="${1:-22.04}"
ACTION="${2:-start}"
CONTAINER_NAME="pwn-${VER//\./-}"
IMAGE_TAG="pwn-x86:${VER}"

case "${ACTION}" in
    start|"")
        # 컨테이너가 이미 존재하는지 확인
        if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
            # 존재하면 상태 확인
            STATE=$(podman inspect "${CONTAINER_NAME}" --format '{{.State.Status}}')
            if [ "${STATE}" = "running" ]; then
                echo "[*] ${CONTAINER_NAME} 실행 중 — 접속합니다"
                podman exec -it "${CONTAINER_NAME}" /bin/bash
            else
                echo "[*] ${CONTAINER_NAME} 정지 상태 — 시작합니다"
                podman start "${CONTAINER_NAME}"
                podman exec -it "${CONTAINER_NAME}" /bin/bash
            fi
        else
            # 이미지 존재 확인
            if ! podman image exists "${IMAGE_TAG}" 2>/dev/null; then
                echo "[!] 이미지 ${IMAGE_TAG}가 없습니다. 먼저 빌드하세요:"
                echo "    ./build-all.sh ${VER}"
                exit 1
            fi

            echo "[*] ${CONTAINER_NAME} 새로 생성합니다"
            podman run -it \
                --platform linux/amd64 \
                --name "${CONTAINER_NAME}" \
                --privileged \
                --hostname "pwn-${VER}" \
                -v "${WORKSPACE}:/pwn" \
                -p "1234:1234" \
                "${IMAGE_TAG}"
        fi
        ;;

    stop)
        echo "[*] ${CONTAINER_NAME} 정지"
        podman stop "${CONTAINER_NAME}" 2>/dev/null || echo "이미 정지 상태"
        ;;

    rm)
        echo "[*] ${CONTAINER_NAME} 삭제"
        podman rm -f "${CONTAINER_NAME}" 2>/dev/null || echo "컨테이너 없음"
        ;;

    *)
        echo "사용법: $0 <버전> [start|stop|rm]"
        echo "  $0 22.04        ← 22.04 시작/접속"
        echo "  $0 18.04 stop   ← 18.04 정지"
        echo "  $0 24.04 rm     ← 24.04 삭제"
        echo "  $0 list         ← 전체 상태"
        exit 1
        ;;
esac

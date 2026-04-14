# pwn-env

Ubuntu 18.04 / 20.04 / 22.04 / 24.04 기반 x86_64 유저랜드 포너블 풀이용 podman 컨테이너 환경.

## 포함 도구

- 컴파일러/디버거: gcc, g++, gdb, gdbserver, nasm, gcc-multilib (32비트)
- 바이너리 분석: binutils, file, ltrace, strace, patchelf, checksec
- 익스플로잇: pwntools, ROPgadget, ropper, one_gadget, seccomp-tools
- libc 디버그 심볼: libc6-dbg
- 네트워크: netcat-openbsd, socat
- 기타: vim, tmux, git, wget, curl

## 요구 사항

- podman 설치
- Apple Silicon인 경우 linux/amd64 에뮬레이션 지원 (Rosetta 또는 QEMU)

## 설치 (이미지 빌드)

빌드 스크립트는 해당 버전의 기존 컨테이너와 이미지를 삭제한 뒤 `--no-cache`로 새로 빌드한다.

전체 버전 빌드:
```
./build-all.sh
```

특정 버전만 빌드:
```
./build-all.sh 22.04
```

지원 버전: 18.04, 20.04, 22.04, 24.04

## 실행

호스트의 `~/pwn-workspace`가 컨테이너의 `/pwn`에 마운트된다. 컨테이너 포트 1234는 호스트 1234로 포워딩된다 (gdbserver 원격 디버깅용).

컨테이너 시작/접속:
```
./run.sh 22.04
```

이미 실행 중이면 exec로 접속하고, 정지 상태면 start 후 접속한다. 존재하지 않으면 새로 생성한다.

컨테이너 정지:
```
./run.sh 22.04 stop
```

컨테이너 삭제:
```
./run.sh 22.04 rm
```

전체 상태 확인:
```
./run.sh list
```

## 원격 디버깅 예시

컨테이너 내부:
```
gdbserver :1234 ./target
```

호스트(IDA, gdb 등)에서 `localhost:1234`로 attach.

## libc 교체

호스트의 `~/pwn-workspace`에 원하는 libc와 ld를 두고 컨테이너 내부에서 patchelf로 바이너리의 interpreter와 rpath를 교체한다.

```
patchelf --set-interpreter ./ld-2.31.so --set-rpath . ./target
```

## 재설치

기존 환경을 지우고 다시 설치하려면 `build-all.sh`를 다시 실행한다. 스크립트가 해당 버전의 컨테이너와 이미지를 먼저 제거한 뒤 빌드한다.

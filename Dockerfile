ARG UBUNTU_VERSION=22.04
FROM --platform=linux/amd64 ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

# ============================================================
# 기본 패키지 (모든 버전 공통)
# ============================================================
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    nasm \
    gdb \
    gdbserver \
    git \
    wget \
    curl \
    netcat-openbsd \
    socat \
    file \
    ltrace \
    strace \
    binutils \
    patchelf \
    vim \
    tmux \
    unzip \
    ca-certificates \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

# ============================================================
# multilib (32비트 지원)
# ============================================================
RUN apt-get update && apt-get install -y \
    gcc-multilib \
    g++-multilib \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# libc debug symbols
# ============================================================
RUN apt-get update && apt-get install -y \
    libc6-dbg \
    && rm -rf /var/lib/apt/lists/* \
    || true

# ============================================================
# Python3 + pip (버전별 분기)
# - 18.04: python3.6, get-pip.py 사용
# - 20.04: python3.8, python3-pip
# - 22.04: python3.10, python3-pip
# - 24.04: python3.12, python3-pip (--break-system-packages)
# ============================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN if echo "${UBUNTU_VERSION}" | grep -q "18.04"; then \
      curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | python3; \
    else \
      apt-get update && apt-get install -y python3-pip && rm -rf /var/lib/apt/lists/*; \
    fi

# 24.04+는 --break-system-packages 필요
RUN if echo "${UBUNTU_VERSION}" | grep -qE "^2[4-9]"; then \
      echo '--break-system-packages' > /tmp/.pipflag; \
    else \
      echo '' > /tmp/.pipflag; \
    fi

# ============================================================
# pwntools + ROPgadget + ropper
# ============================================================
RUN pip3 install --no-cache-dir $(cat /tmp/.pipflag) \
    pwntools \
    ropper \
    ROPgadget

# ============================================================
# Ruby + seccomp-tools + one_gadget
# 18.04 = Ruby 2.5 → seccomp-tools 1.5.0, one_gadget 1.7.3
# 20.04 = Ruby 2.7 → seccomp-tools 1.5.0, one_gadget 1.9.0
# 22.04 = Ruby 3.0 → seccomp-tools 1.5.0, one_gadget 최신
# 24.04 = Ruby 3.2 → 최신 전부 OK
# ============================================================
RUN apt-get update && apt-get install -y \
    ruby \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

RUN RUBY_VER=$(ruby -e 'puts RUBY_VERSION') && echo "Ruby: ${RUBY_VER}" && \
    MAJOR_MINOR=$(echo "${RUBY_VER}" | cut -d. -f1,2) && \
    if ruby -e "exit(Gem::Version.new('${MAJOR_MINOR}') >= Gem::Version.new('3.1') ? 0 : 1)"; then \
      gem install seccomp-tools && \
      gem install one_gadget; \
    elif ruby -e "exit(Gem::Version.new('${MAJOR_MINOR}') >= Gem::Version.new('2.6') ? 0 : 1)"; then \
      gem install seccomp-tools -v 1.5.0 && \
      gem install one_gadget -v 1.9.0; \
    else \
      gem install seccomp-tools -v 1.5.0 && \
      gem install one_gadget -v 1.7.3; \
    fi

# ============================================================
# checksec standalone
# ============================================================
RUN wget -q -O /usr/local/bin/checksec \
    https://raw.githubusercontent.com/slimm609/checksec.sh/master/checksec \
    && chmod +x /usr/local/bin/checksec

# ============================================================
# GDB 기본 설정
# ============================================================
RUN echo "set disassembly-flavor intel" >> /root/.gdbinit \
    && echo "set pagination off" >> /root/.gdbinit

# ============================================================
# 버전 표시
# ============================================================
RUN echo "Ubuntu ${UBUNTU_VERSION} x86_64 PWN Environment" > /etc/pwn-env-version

WORKDIR /pwn
VOLUME ["/pwn"]
CMD ["/bin/bash"]

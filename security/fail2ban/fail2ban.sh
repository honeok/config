#!/usr/bin/env bash
#
# Description: This script is used to install fail2ban based on docker and configure ssh interception rules.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: MIT

# 当前脚本版本号
readonly VERSION='v1.3.2 (2025.06.21)'

# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive
# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# 设置系统UTF-8语言环境
UTF8_LOCALE="$(locale -a 2>/dev/null | grep -iEm1 "UTF-8|utf8")"
[ -n "$UTF8_LOCALE" ] && export LC_ALL="$UTF8_LOCALE" LANG="$UTF8_LOCALE" LANGUAGE="$UTF8_LOCALE"

# 各变量默认值
GITHUB_PROXY='https://ghproxy.badking.pp.ua/'
DOCKER_DIR="/data/docker_data"
FAIL2BAN_DIR="$DOCKER_DIR/fail2ban"
OS_NAME="$(grep '^ID=' /etc/os-release | awk -F'=' '{print $NF}')"

# 自定义彩色字体
_red() { printf "\033[91m%b\033[0m\n" "$*"; }
_green() { printf "\033[92m%b\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%b\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %b\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %b\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %b\n" "$*"; }

# 分割符
separator() { printf "%-25s\n" "-" | sed 's/\s/-/g'; }

# 打印错误信息并退出
die() {
    _err_msg >&2 "$(_red "$@")"; exit 1
}

# 安全清屏函数
clrscr() {
    ([ -t 1 ] && tput clear 2>/dev/null) || echo -e "\033[2J\033[H" || clear
}

reading() {
    local PROMPT
    PROMPT="$1"
    read -rep "$(_yellow "$PROMPT")" "$2"
}

# 用于判断命令是否存在
_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0
    elif which "$_CMD" >/dev/null 2>&1; then return 0
    else return 1
    fi
}

pkg_install() {
    for pkg in "$@"; do
        if _exists apt-get; then
            apt-get update
            apt-get install -y -q "$pkg"
        else
            die "The package manager is not supported."
        fi
    done
}

pkg_uninstall() {
    for pkg in "$@"; do
        if _exists apt-get; then
            apt-get purge -y "$pkg"
        else
            die "The package manager is not supported."
        fi
    done
}

# 确保root用户运行
check_root() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "This script must be run as root!"
    fi
}

check_os() {
    if [ "$OS_NAME" != "almalinux" ] && [ "$OS_NAME" != "alpine" ] \
        && [ "$OS_NAME" != "centos" ] && [ "$OS_NAME" != "debian" ] \
        && [ "$OS_NAME" != "fedora" ] && [ "$OS_NAME" != "rocky" ] \
        && [ "$OS_NAME" != "ubuntu" ]; then
        die "System is not supported."
    fi
}

check_docker() {
    ! _exists docker && die "Please install docker first."
}

cdn_check() {
    local COUNTRY IPV4_ADDRESS IPV6_ADDRESS

    # https://danwin1210.de/github-ipv6-proxy.php
    ipv6_proxy() {
        local -a HOST_ENTRIES
        command cp -f /etc/hosts{,.bak}
        HOST_ENTRIES=(
            "2a01:4f8:c010:d56::2 github.com"
            "2a01:4f8:c010:d56::3 api.github.com"
            "2a01:4f8:c010:d56::4 codeload.github.com"
            "2a01:4f8:c010:d56::5 objects.githubusercontent.com"
            "2a01:4f8:c010:d56::6 ghcr.io"
            "2a01:4f8:c010:d56::7 pkg.github.com npm.pkg.github.com maven.pkg.github.com nuget.pkg.github.com rubygems.pkg.github.com"
            "2a01:4f8:c010:d56::8 uploads.github.com"
        )
        for ENTRY in "${HOST_ENTRIES[@]}"; do
            echo "$ENTRY" >> /etc/hosts
        done
    }
    COUNTRY="$(curl -sL -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | grep .)"
    IPV4_ADDRESS="$(curl -sL -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    IPV6_ADDRESS="$(curl -sL -6 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    if [ "$COUNTRY" != "CN" ] && [ -n "$IPV4_ADDRESS" ]; then
        unset GITHUB_PROXY
    elif [ "$COUNTRY" != "CN" ] && [ -z "$IPV4_ADDRESS" ] && [ -n "$IPV6_ADDRESS" ]; then
        ipv6_proxy
    fi
}

fail2ban_install() {
    local FAIL2BAN_VER

    FAIL2BAN_VER="$(curl --retry 2 --connect-timeout 5 --max-time 5 -sL "https://hub.docker.com/v2/repositories/linuxserver/fail2ban/tags" | grep -Po '"name":"\K[^"]+' | grep -vE 'rc|version|amd|arm|r2|ls|latest' | sort -V | tail -n1)"
    FAIL2BAN_VER="${FAIL2BAN_VER:-latest}"

    echo
    # 卸载本机fail2ban
    _exists fail2ban-client && pkg_uninstall fail2ban && rm -rf /etc/fail2ban >/dev/null 2>&1
    _info_msg "$(_yellow "Installing fail2ban.")"
    mkdir -p "$FAIL2BAN_DIR" >/dev/null 2>&1
    cd "$FAIL2BAN_DIR" >/dev/null 2>&1 || die "No permission or wrong path."
    tee docker-compose.yml >/dev/null <<EOF
services:
  fail2ban:
    image: linuxserver/fail2ban:$FAIL2BAN_VER
    container_name: fail2ban
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - VERBOSITY=-vv
    volumes:
      - \$PWD/config:/config
      - /var/log:/var/log:ro
    cap_add:
      - NET_ADMIN
      - NET_RAW
    network_mode: host
EOF
    docker compose up -d
}

fail2ban_uninstall() {
    echo
    _info_msg "$(_yellow "Uninstalling fail2ban.")"
    cd "${FAIL2BAN_DIR:?}" >/dev/null 2>&1 || die "No permission or wrong path."
    docker compose down -t 0 --rmi all --volumes
    rm -rf "${FAIL2BAN_DIR:?}" >/dev/null 2>&1 && _suc_msg "$(_green "Uninstall fail2ban successfully.")"
}

fail2ban_config() {
    echo
    _info_msg "$(_yellow "configuration fail2ban.")"
    cd "${FAIL2BAN_DIR:?}" || die "No permission or wrong path."
    if [ -f /etc/alpine-release ]; then
        curl --retry 2 -L -o config/fail2ban/filter.d/alpine-sshd.conf "${GITHUB_PROXY}https://github.com/kejilion/config/raw/main/fail2ban/alpine-sshd.conf"
        curl --retry 2 -L -o config/fail2ban/filter.d/alpine-sshd-ddos.conf "${GITHUB_PROXY}https://github.com/kejilion/config/raw/main/fail2ban/alpine-sshd-ddos.conf"
        curl --retry 2 -L -o config/fail2ban/jail.d/alpine-ssh.conf "${GITHUB_PROXY}https://github.com/kejilion/config/raw/main/fail2ban/alpine-ssh.conf"
    elif [ "$OS_NAME" = "almalinux" ] || [ "$OS_NAME" = "centos" ] || [ "$OS_NAME" = "fedora" ] || [ "$OS_NAME" = "rocky" ]; then
        curl --retry 2 -L -o config/fail2ban/jail.d/centos-ssh.conf "${GITHUB_PROXY}https://github.com/kejilion/config/raw/main/fail2ban/centos-ssh.conf"
    elif [ "$OS_NAME" = "debian" ] || [ "$OS_NAME" = "ubuntu" ]; then
        ! dpkg -s rsyslog >/dev/null 2>&1 && pkg_install rsyslog && systemctl enable rsyslog --now \
            && touch /var/log/auth.log && chmod 640 /var/log/auth.log && chown root:adm /var/log/auth.log
        curl --retry 2 -L -o config/fail2ban/jail.d/linux-ssh.conf "${GITHUB_PROXY}https://github.com/honeok/config/raw/master/security/fail2ban/config/linux-ssh.conf"
        systemctl restart rsyslog
    fi
    rm -f config/fail2ban/jail.d/sshd.conf >/dev/null 2>&1

    # 重载配置文件
    until docker exec -it fail2ban fail2ban-client reload >/dev/null 2>&1; do sleep 1; done
    sleep 5s
    separator
    docker exec -it fail2ban fail2ban-client status
    _suc_msg "$(_green "Install and configure fail2ban successfully.")"
}

# 通用发行版24h内ssh爆破记录次数统计
# shellcheck disable=SC2120
ssh_bruteforce() {
    local SSH_SVCNAME
    local SINCE="${1:-today}"

    echo
    if [ "$OS_NAME" = "almalinux" ] || [ "$OS_NAME" = "centos" ] || [ "$OS_NAME" = "fedora" ] || [ "$OS_NAME" = "rocky" ]; then
        SSH_SVCNAME="sshd"
    elif [ "$OS_NAME" = "debian" ] || [ "$OS_NAME" = "ubuntu" ];then
        SSH_SVCNAME="ssh"
    fi

    printf "%-8s %-16s %-7s %-15s %-30s\n" "Attempts" "IP Address" "Country" "Region" "ISP"
    echo "-------- ---------------- ------- --------------- ------------------------------"
    journalctl -u "$SSH_SVCNAME" --since "$SINCE" | grep -i "Failed password" | \
    awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | \
    sort | uniq -c | sort -nr | awk '{$1=$1; print}' | \
    while read -r COUNT IP; do
        # 恶意ip归属地查询
        IPINFO="$(curl -sL --retry 10 "https://ipinfo.io/$IP/json")"
        COUNTRY="$(sed -En 's/.*"country": ?"([^"]+)".*/\1/p' <<< "$IPINFO")"
        REGION="$(sed -En 's/.*"region": ?"([^"]+)".*/\1/p' <<< "$IPINFO")"
        ISP="$(sed -En 's/.*"org": ?"([^"]+)".*/\1/p' <<< "$IPINFO")"
        printf "%-8s %-16s %-7s %-15s %-30s\n" "$COUNT" "$IP" "$COUNTRY" "$REGION" "$ISP"
    done
}

# 查看拦截状态
fail2ban_status() {
    echo
    if [ -f /etc/alpine-release ]; then
        docker exec -it fail2ban fail2ban-client status alpine-sshd
    elif [ "$OS_NAME" = "almalinux" ] || [ "$OS_NAME" = "centos" ] || [ "$OS_NAME" = "debian" ] || [ "$OS_NAME" = "fedora" ] || [ "$OS_NAME" = "rocky" ] || [ "$OS_NAME" = "ubuntu" ]; then
        docker exec -it fail2ban fail2ban-client status sshd
    fi
}

# shellcheck disable=SC2119
fail2ban_menu() {
    local FAIL2BAN_STATE CHOOSE

    docker ps --format '{{.Names}}' 2>/dev/null | grep -qE 'fail2ban' && FAIL2BAN_STATE="$(_green "Installed")" || FAIL2BAN_STATE="$(_yellow "Not Installed")"

    separator
    echo " fail2ban management menu"
    echo "    $VERSION"
    echo
    echo " 1. Install fail2ban ( $FAIL2BAN_STATE )"
    echo " 2. Uninstall fail2ban"
    echo " 3. Show blocked ip list"
    echo " 4. Show ssh login error log"
    separator
    echo
    reading "Please enter your choose: " CHOOSE
    case "$CHOOSE" in
        1 ) cdn_check && fail2ban_install && fail2ban_config ;;
        2 ) fail2ban_uninstall ;;
        3 ) fail2ban_status ;;
        4 ) _exists journalctl && ssh_bruteforce ;;
        * ) die "Wrong parameters." ;;
    esac
}

# 全局参数 (1/2)
clrscr
check_root
check_os
check_docker

# 安装和查看拦截记录选项 (2/2)
fail2ban_menu
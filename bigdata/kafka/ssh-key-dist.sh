#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Description: The script is designed to automatically generate and batch deploy ssh keys to establish passwordless authentication across multiple servers.
# Copyright (c) 2025 Yihao He <i@honeok.com>
# Copyright (c) 2025 zzwsec <zzwsec@163.com>

set -eEu

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive

_red() { printf "\033[31m%b\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %b\n" "$*"; }

# 定义被控服务器
declare -a HOSTS
HOSTS=()
# 秘钥存储路径
SSHKEY_PATH="$HOME/.ssh/id_ed25519"
SSH_PORT="22"
# 主机密码
HOST_PASSWD=""

separator() {
    printf '%.0s-' {1..10}
}

die() {
    _err_msg >&2 "$(_red "$@")"; exit 1
}

_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return;
    elif command -v "$_CMD" >/dev/null 2>&1; then return;
    elif which "$_CMD" >/dev/null 2>&1; then return;
    else return 1;
    fi
}

pkg_install() {
    for pkg in "$@"; do
        if _exists dnf; then
            dnf install -y "$pkg"
        elif _exists yum; then
            yum install -y "$pkg"
        elif _exists apt-get; then
            apt-get update
            apt-get install -y -q "$pkg"
        elif _exists apk; then
            apk add --no-cache "$pkg"
        elif _exists zypper; then
            zypper install -y "$pkg"
        else
            die "The package manager is not supported."
        fi
    done
}

check_root() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "This script must be run as root."
    fi
}

check_cmd() {
    _exists sshpass || pkg_install sshpass
}

check_sshkey() {
    if [ ! -f "$SSHKEY_PATH" ]; then
        ssh-keygen -t ed25519 -f "$SSHKEY_PATH" -P '' >/dev/null 2>&1
    fi
}

send_sshkey() {
    local SSH_OPTS
    SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=30"

    for h in "${HOSTS[@]}"; do
        # shellcheck disable=SC2059
        printf -- "$(separator) $h $(separator)\n"
        eval sshpass -p"$HOST_PASSWD" ssh-copy-id -i "$SSHKEY_PATH" -p "$SSH_PORT" "$SSH_OPTS" root@"$h"
        printf "success\n"
    done
}

check_root
check_cmd
check_sshkey
send_sshkey

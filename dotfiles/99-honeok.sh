#!/usr/bin/env sh
# shellcheck shell=bash
# SPDX-License-Identifier: MIT
#
# Description: This script is used custom motd showing hostname ip address disk usage and system uptime.
# Copyright (c) 2025-2026 honeok <i@honeok.com>

# Usage:
# export DEBIAN_FRONTEND=noninteractive
# apt-get update && apt-get install -y figlet lolcat toilet
# ln -sf /usr/games/lolcat /usr/bin/lolcat
# FASTFETCH_VER="$(wget -qO- https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | cut -d'"' -f4)"
# wget "https://github.com/fastfetch-cli/fastfetch/releases/download/$FASTFETCH_VER/fastfetch-linux-amd64.tar.gz"

unset DISPLAY         # 删除 X11 图形显示地址变量
unset WAYLAND_DISPLAY # 删除 Wayland 图形显示地址变量
unset XAUTHORITY      # 删除 X11 认证文件路径变量

set -eE

# 分隔符
separator() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

get_cmd_path() {
    type -f -p "$1"
}

is_have_cmd() {
    get_cmd_path "$1" > /dev/null 2>&1
}

curl() {
    local rc count
    rc=0
    count=1

    while [ "$count" -le 3 ]; do
        command curl --connect-timeout 10 --fail --insecure "$@"
        rc="$?"

        if [ "$rc" -eq 0 ]; then
            return
        fi
        # 403 404 错误或达到重试次数
        if [ "$rc" -eq 22 ] || [ "$count" -eq 5 ]; then
            return "$rc"
        fi
        count=$((count + 1))
        sleep 0.5
    done
}

# 各变量默认值
IPV4_ADDRESS="$(curl -Ls -4 http://www.qualcomm.cn/cdn-cgi/trace 2> /dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo "Unknown")"
IPV6_ADDRESS="$(curl -Ls -6 http://www.qualcomm.cn/cdn-cgi/trace 2> /dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo "Unknown")"
DISK_USAGE="$(df -h / 2> /dev/null | awk 'NR==2 {print $3 " / " $2}')"

# if is_have_cmd toilet; then
#     toilet -f big -F gay "honeok"
# fi

# https://github.com/fastfetch-cli/fastfetch
if is_have_cmd fastfetch && is_have_cmd lolcat; then
    (env -u DISPLAY -u WAYLAND_DISPLAY -u XAUTHORITY fastfetch | lolcat)
fi

echo " Welcome back honeok! - $(hostname 2> /dev/null) - $(LC_TIME="en_DK.UTF-8" TZ=Asia/Shanghai date 2> /dev/null)"
separator
printf " Uptime: "
uptime
echo " Network address: $IPV4_ADDRESS / $IPV6_ADDRESS"
echo " Disk Usage: $DISK_USAGE"
separator

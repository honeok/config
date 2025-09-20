#!/usr/bin/env sh
#
# Description: This script is used custom motd showing hostname ip address disk usage and system uptime.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

# Usage:
# export DEBIAN_FRONTEND=noninteractive
# apt-get update && apt-get install -y figlet lolcat neofetch toilet
# ln -sf /usr/games/lolcat /usr/bin/lolcat

separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

IPV4_ADDRESS="$(curl -kLs -m3 -4 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo Unknown)"
IPV6_ADDRESS="$(curl -kLs -m3 -6 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo Unknown)"
DISK_USAGE="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2}')"

command -v toilet >/dev/null 2>&1 \
    && toilet -f big -F gay "honeok"

command -v neofetch >/dev/null 2>&1 \
    && command -v lolcat >/dev/null 2>&1 \
    && (neofetch | lolcat)

echo "Welcome back honeok! - $(hostname 2>/dev/null) - $(LC_TIME="en_DK.UTF-8" TZ=Asia/Shanghai date 2>/dev/null)"
separator
printf " Uptime: "
uptime
echo " Network address: $IPV4_ADDRESS / $IPV6_ADDRESS"
echo " Disk Usage: $DISK_USAGE"
separator
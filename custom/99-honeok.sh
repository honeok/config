#!/usr/bin/env sh
#
# Description: This script is used custom MOTD showing hostname ip address disk usage and system uptime.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: MIT

# Usage:
# apt-get update && apt-get install -y figlet toilet neofetch lolcat
# ln -sf /usr/games/lolcat /usr/bin/lolcat

IPV4_ADDRESS="$(curl -Ls --max-time 2 -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo Unknown)"
IPV6_ADDRESS="$(curl -Ls --max-time 2 -6 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo Unknown)"
DISK_USAGE="$(df -h / | awk 'NR==2 {print $3 " / " $2}')"

separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

command -v toilet >/dev/null 2>&1 && toilet -f big -F gay "honeok"
command -v neofetch >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1 && (neofetch | lolcat)

echo "Welcome back honeok! - $(hostname) - $(LC_TIME="en_DK.UTF-8" TZ=Asia/Shanghai date)"
separator
printf " Uptime: "
uptime
echo " Network address: $IPV4_ADDRESS / $IPV6_ADDRESS"
echo " Disk Usage: $DISK_USAGE"
separator
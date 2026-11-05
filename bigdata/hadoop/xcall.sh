#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Description: This script executes commands on all hadoop cluster nodes via ssh.
# Copyright (c) 2021 atguigu https://www.atguigu.com
# Copyright (c) 2025-2026 honeok <i@honeok.com>

set -eEu

: "${SSH_PORT:="22"}"

# 主机清单
HOSTS=("hadoop102" "hadoop103" "hadoop104")

separator() {
    printf '%.0s-' {1..10}
}

main() {
    local host

    for host in "${HOSTS[@]}"; do
        printf "%s %s %s\n" "$(separator)" "$host" "$(separator)"
        ssh -p "$SSH_PORT" "$(id -un)@$host" "$*"
    done
}

main "$*"

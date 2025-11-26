#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Description: This script is a tool for distributing and sync files and scripts across a kafka cluster.
# Copyright (c) 2021 atguigu https://www.atguigu.com
# Copyright (c) 2025 honeok <i@honeok.com>

# Usage:
# curl -Ls https://github.com/honeok/config/raw/master/bigdata/kafka/xsync.sh -o /usr/local/bin/xsync

set -eEu

SSH_PORT="22"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5"

# 若 export FORCE_SYNC=1 则开启delete模式
RSYNC_OPTS="-av"
if [ "${FORCE_SYNC:-0}" -eq 1 ]; then
    RSYNC_OPTS="-av --delete"
fi

# 主机清单
HOSTS=(hadoop102 hadoop103 hadoop104)

separator() {
    printf '%.0s-' {1..10}
}

_exists() {
    command -v "$@" >/dev/null 2>&1
}

die() {
    echo >&2 "Error: $*"; exit 1
}

if [ "$#" -lt 1 ]; then
    die "Not enough arguments."
fi

_exists rsync || die "rsync Command not found."

for h in "${HOSTS[@]}"; do
    printf "%s %s %s\n" "$(separator)" "$h" "$(separator)"

    # 遍历所有提供的文件参数
    for f in "$@"; do
        if [ -e "$f" ]; then
            SRC_DIR="$(cd -P "$(dirname "$f")"; pwd)"
            FILE_NAME="$(basename "$f")"

            # 在远程主机上创建目录
            eval ssh -p "$SSH_PORT" "$SSH_OPTS" "$h" "mkdir -p \"$SRC_DIR\"" || die "Failed to create directory $SRC_DIR on $h"
            # 将文件同步到远程主机
            rsync "$RSYNC_OPTS" -e "ssh -p $SSH_PORT $SSH_OPTS" "$SRC_DIR/$FILE_NAME" "$h:$SRC_DIR"
        else
            die "$f does not exist."
        fi
    done
done

echo "success"

#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Description: This script is a tool for distributing and syncing files and scripts across a hadoop cluster.
# Copyright (c) 2021 atguigu https://www.atguigu.com
# Copyright (c) 2025-2026 honeok <i@honeok.com>

set -eEu

: "${SSH_PORT:="22"}"
: "${RSYNC_OPTS:="-v -a"}"

# 主机清单
HOSTS=("hadoop102" "hadoop103" "hadoop104")

separator() {
    printf '%.0s-' {1..10}
}

die() {
    echo "Error: $*" >&2
    exit 1
}

get_cmd_path() {
    type -f -p "$1"
}

is_have_cmd() {
    get_cmd_path "$1" > /dev/null 2>&1
}

main() {
    local host file src_dir file_name

    for host in "${HOSTS[@]}"; do
        printf "%s %s %s\n" "$(separator)" "$host" "$(separator)"

        # 遍历所有提供的文件参数
        for file in "$@"; do
            if [ -e "$file" ]; then
                # 获取父级目录
                src_dir="$(cd -P "$(dirname "$file")" && pwd)"
                # 获取当前文件名称
                file_name="$(basename "$file")"
                # 在远程主机上创建目录
                eval ssh -p "$SSH_PORT" "$(id -un)@$host" "mkdir -p $src_dir" || die "Failed to create directory $src_dir on $host"
                # 将文件同步到远程主机
                eval "rsync $RSYNC_OPTS -e 'ssh -p $SSH_PORT' '$src_dir/$file_name' '$(id -un)@$host:$src_dir'"
            else
                die "$file does not exist."
            fi
        done
    done
}

if [ "$#" -lt 1 ]; then
    die "Not enough arguments."
fi

is_have_cmd rsync || die "Command not found."

main "$@"

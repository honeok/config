#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Description: This script manages hadoop cluster startup and shutdown.
# Copyright (c) 2021 atguigu https://www.atguigu.com
# Copyright (c) 2026 honeok <i@honeok.com>

set -eEu

: "${SSH_PORT:="22"}"

separator() {
    printf '%.0s-' {1..10}
}

die() {
    echo "Error: $*" >&2
    exit 1
}

if [ "$#" -lt 1 ]; then
    die "Not enough arguments."
fi

case "$1" in
"start")
    echo "$(separator) start hadoop cluster"

    echo "$(separator) start hdfs"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop102" "$HADOOP_HOME/sbin/start-dfs.sh"
    echo "$(separator) start yarn"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop103" "$HADOOP_HOME/sbin/start-yarn.sh"
    echo "$(separator) start historyserver"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop102" "$HADOOP_HOME/bin/mapred --daemon start historyserver"
    ;;
"stop")
    echo "$(separator) stop hadoop cluster"

    echo "$(separator) stop historyserver"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop102" "$HADOOP_HOME/bin/mapred --daemon stop historyserver"
    echo "$(separator) stop yarn"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop103" "$HADOOP_HOME/sbin/stop-yarn.sh"
    echo "$(separator) stop hdfs"
    ssh -p "$SSH_PORT" "$(id -un)@hadoop102" "$HADOOP_HOME/sbin/stop-dfs.sh"
    ;;
*)
    die "Input args error."
    ;;
esac

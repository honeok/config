#!/bin/bash -eEu
# SPDX-License-Identifier: MIT
#
# Description: This script is used to set up the git basic operating environment.
#
# Copyright (c) 2025 honeok <i@honeok.com>

PLATFORM="$(pwd | awk -F'/' '{print $(NF-1)}')"
REMOTE_ORIGIN="$(git config --get remote.origin.url)"
separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

case "$PLATFORM" in
    github*) WORK_PLATFORM="github" ;;
    gitlab*) WORK_PLATFORM="gitlab" ;;
    *) echo "Error: Unknown platform." && exit 1 ;;
esac

# global variable
if ! git config --global --get-regexp url | grep -Fx "url.ssh://git@ssh.github.com:443/.insteadof git@github.com:" >/dev/null 2>&1; then
    git config --global url."ssh://git@ssh.github.com:443/".insteadof git@github.com:
    ssh -T -p 443 git@ssh.github.com
fi

# set user
while true; do
    separator
    echo " 1. honeok"
    echo " 2. havario"
    separator
    read -rep "Please enter user: " USER
    case "$USER" in
        1)
            git config user.name honeok
            [ "$WORK_PLATFORM" = "github" ] && git config user.email "100125733+honeok@users.noreply.github.com"
            git remote set-url origin "$REMOTE_ORIGIN"
            break
        ;;
        2)
            git config user.name havario
            [ "$WORK_PLATFORM" = "github" ] && git config user.email "157877551+havario@users.noreply.github.com"
            git remote set-url origin "$REMOTE_ORIGIN"
            break
        ;;
        *)
            echo "Error: Unknown User"
        ;;
    esac
done

separator
git config --get user.name
git config --get user.email

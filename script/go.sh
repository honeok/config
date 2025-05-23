#!/usr/bin/env bash
#
# Description: This script is used to install or update to the latest go version.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the MIT License.
# This software is provided "as is", without any warranty.

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %s\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %s\n" "$*"; }

# 各变量默认值
GITHUB_PROXY='https://files.m.daocloud.io/'
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36'

_is_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0;
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

error_and_exit() {
    _err_msg "$(_red "$@")" >&2 && exit 1
}

pre_check() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        error_and_exit "This script must be run as root!" && exit 1
    fi
    if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
        cd /root >/dev/null 2>&1 || error_and_exit "Failed to switch directory, Check permissions!"
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        error_and_exit "This script needs to be run with bash, not sh!"
    fi
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ "$(curl --user-agent "$UA_BROWSER" -fsL -m 3 --retry 2 -4 "http://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | grep .)" != "CN" ]; then
        unset GITHUB_PROXY
    fi
}

install_go() {
    local GO_WORKDIR GO_ENV GO_LVER GO_FRAMEWORK

    GO_WORKDIR="/usr/local/go"
    GO_ENV="/etc/profile.d/go.sh"
    GO_LVER="$(curl -fsL --retry 5 "https://go.dev/dl/?mode=json" | awk '/version/ {print $2}' | sed -n '1s/.*"go\(.*\)".*/\1/p')"
    case "$(uname -m)" in
        i*86 | x86)
            GO_FRAMEWORK='386' # 32-bit x86
        ;;
        x86_64 | amd64)
            GO_FRAMEWORK='amd64' # 64-bit x86
        ;;
        armv6*)
            GO_FRAMEWORK='armv6' # ARMv6
        ;;
        arm64 | aarch64)
            GO_FRAMEWORK='arm64' # 64-bit ARM
        ;;
        *)
            error_and_exit "unsupported architecture: $(uname -m)"
        ;;
    esac
    _info_msg "$(_yellow "Start downloading the go install package.")"
    if ! curl -L -O "${GITHUB_PROXY}go.dev/dl/go$GO_LVER.linux-$GO_FRAMEWORK.tar.gz"; then
        error_and_exit "Failed to download go install package, please check the network!"
    fi
    rm -rf "$GO_WORKDIR" >/dev/null 2>&1
    rm -f "$GO_ENV" >/dev/null 2>&1
    tar xzf "go$GO_LVER.linux-$GO_FRAMEWORK.tar.gz" -C /usr/local
    cat >> "$GO_ENV" <<EOF
#!/bin/sh
# GoLang Environment
export GOROOT=/usr/local/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin
EOF
    chmod +x "$GO_ENV"
    # shellcheck source=/dev/null
    . "$GO_ENV"
    rm -f "go$GO_LVER.linux-$GO_FRAMEWORK.tar.gz"
}

install_check() {
    if _is_exists go >/dev/null 2>&1; then
        _suc_msg "$(_green "Go installed successfully!")"
        go version
    else
        error_and_exit "Go installation failed, please check the error message."
    fi
}

pre_check
install_go
install_check
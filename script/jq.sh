#!/usr/bin/env bash
#
# Description: This script is used to install the binary file jq command.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: MIT

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %s\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %s\n" "$*"; }

# 各变量默认值
GITHUB_PROXY='https://ghproxy.honeok.com/'
CF_API='www.qualcomm.cn' # 备用 www.prologis.cn www.autodesk.com.cn www.keysight.com.cn

# curl默认参数
declare -a CURL_OPTS=(--max-time 5 --retry 2 --retry-max-time 10)

clrscr() {
    ( [ -t 1 ] && tput clear 2>/dev/null ) || echo -e "\033[2J\033[H" || clear
}

die() {
    _err_msg "$(_red "$@")" >&2; exit 1
}

_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0;
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

before_script() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "This script must be run as root!"
    fi
    if [ -z "$BASH_VERSION" ] || [ "$(basename "$0")" = "sh" ]; then
        die "This script needs to be run with bash, not sh!"
    fi
}

check_cdn() {
    local COUNTRY IP4 IP6

    # https://danwin1210.de/github-ipv6-proxy.php
    ipv6_proxy() {
        local -a HOST_ENTRIES
        command cp -f /etc/hosts{,.bak}
        HOST_ENTRIES=(
            "2a01:4f8:c010:d56::2 github.com"
            "2a01:4f8:c010:d56::3 api.github.com"
            "2a01:4f8:c010:d56::4 codeload.github.com"
            "2a01:4f8:c010:d56::5 objects.githubusercontent.com"
            "2a01:4f8:c010:d56::6 ghcr.io"
            "2a01:4f8:c010:d56::7 pkg.github.com npm.pkg.github.com maven.pkg.github.com nuget.pkg.github.com rubygems.pkg.github.com"
            "2a01:4f8:c010:d56::8 uploads.github.com"
        )
        for ENTRY in "${HOST_ENTRIES[@]}"; do
            echo "$ENTRY" >> /etc/hosts
        done
    }

    COUNTRY="$(curl "${CURL_OPTS[@]}" -fsL "https://$CF_API/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | grep . || echo "")"
    IP4="$(curl "${CURL_OPTS[@]}" -fsL -4 "https://$CF_API/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo "")"
    IP6="$(curl "${CURL_OPTS[@]}" -fsL -6 "https://$CF_API/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | grep . || echo "")"

    if [[ "$COUNTRY" != "CN" && -n "$IP4" ]]; then
        unset GITHUB_PROXY
    elif [[ "$COUNTRY" != "CN" && -z "$IP4" && -n "$IP6" ]]; then
        ipv6_proxy
    fi
}

check_jq() {
    ( ! _exists jq ) || die "jq already installed."
}

install_jq() {
    local JQ_VER JQ_FRAMEWORK

    _info_msg "$(_yellow "Installing the command!")"
    JQ_VER="$(curl "${CURL_OPTS[@]}" -fsL "https://api.github.com/repos/jqlang/jq/releases/latest" | awk -F'"' '/"tag_name":/{print $4}')"
    JQ_VER="${JQ_VER:-jq-1.8.0}"

    case "$(uname -m)" in
        i*86 ) JQ_FRAMEWORK="i386" ;;
        x86_64 ) JQ_FRAMEWORK="amd64" ;;
        armv6* ) JQ_FRAMEWORK="armel" ;;
        armv7* ) JQ_FRAMEWORK="armhf" ;;
        armv8* | arm64 | aarch64 ) JQ_FRAMEWORK="arm64" ;;
        ppc64le ) JQ_FRAMEWORK="ppc64el" ;;
        s390x ) JQ_FRAMEWORK="s390x" ;;
        * ) die "Unsupported architecture: $(uname -m)" ;;
    esac

    curl --retry 2 -fsL -o /usr/bin/jq "${GITHUB_PROXY}https://github.com/jqlang/jq/releases/download/${JQ_VER}/jq-linux-${JQ_FRAMEWORK}"
    [ ! -x /usr/bin/jq ] && chmod +x /usr/bin/jq
    ( _exists jq && _suc_msg "$(_green "Download jq success!")" ) || die "Download jq failed."
}

main() {
    clrscr
    before_script
    check_jq
    check_cdn
    install_jq
}

main
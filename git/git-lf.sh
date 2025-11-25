#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 honeok <i@honeok.com>

set -e

git config --global core.autocrlf false
git rm --cached -r .
git reset --hard

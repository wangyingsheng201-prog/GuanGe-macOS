#!/bin/bash
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/观格.app"

if [ ! -d "$APP" ]; then
  osascript -e 'display alert "没有找到观格.app" message "请保留“首次运行.command”和“观格.app”在同一文件夹中。"'
  exit 1
fi

xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
open "$APP"

#!/usr/bin/env bash
# WSL 環境のみ: powershell.exe 経由で通知
command -v powershell.exe &>/dev/null || exit 0
ICON=$(wslpath -w "$HOME/.claude/icon/claude-color.png" 2>/dev/null)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'ClaudeCode', '確認が必要です' -Sound Default -AppLogo '$ICON'"

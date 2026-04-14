#!/usr/bin/env bash
# 通知 hook (Stop): 処理完了通知を各プラットフォームで表示する。
# WSL:   stop-hook.ps1 を -EncodedCommand で呼ぶ（日本語の文字化け回避）
# macOS: osascript
# Linux: notify-send

set -u

# --- WSL / Windows interop ---
if command -v powershell.exe &>/dev/null; then
    powershell.exe -NoProfile -Command "exit 0" &>/dev/null || exit 0
    PS1_FILE="$HOME/.claude/scripts/stop-hook.ps1"
    [ -f "$PS1_FILE" ] || exit 0
    # PowerShell -EncodedCommand は UTF-16LE の base64 を要求する。
    # iconv で .ps1 (UTF-8) を UTF-16LE に変換してから base64 化することで、
    # コマンドライン経由での日本語文字化けを根本的に回避する。
    ENCODED=$(iconv -f UTF-8 -t UTF-16LE "$PS1_FILE" | base64 -w0) || exit 0
    powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -EncodedCommand "$ENCODED"
    exit 0
fi

# --- macOS ---
if [ "$(uname)" = "Darwin" ]; then
    osascript -e 'display notification "処理が完了しました" with title "ClaudeCode"' 2>/dev/null
    exit 0
fi

# --- Linux (notify-send) ---
if command -v notify-send &>/dev/null; then
    notify-send "ClaudeCode" "処理が完了しました"
fi

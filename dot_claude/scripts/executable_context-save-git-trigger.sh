#!/usr/bin/env bash
# 直接呼出しの互換入口。判定は Windows と共通の Node.js 実装へ委譲する。
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_DIR/context-save-hooks.js" context-save-git-trigger

#!/usr/bin/env bash
# typecheck-gate.sh - Stop hook（通知型 Feedback Loop / TS のみ）
#
# cwd が「package.json に scripts.typecheck を持つ TS プロジェクト」のとき、
# バックグラウンドで `npm run typecheck` を実行し結果を state に記録する。
# Stop 自体はブロックせず即 exit 0（ターン終了を遅延させない）。
# 失敗の通知は typecheck-reminder.sh が次ターンに <system-reminder> で出す。
#
# state: ~/.claude/state/typecheck-gate/<PWDハッシュ>.errors（失敗時のみ存在）
# 無効化: settings.json の Stop hook を外す、または該当 .errors を消す。

set -uo pipefail

PROJECT_DIR="$PWD"

# TS プロジェクト判定（package.json + scripts.typecheck）。違えば無音・ゼロコスト。
[ -f "$PROJECT_DIR/package.json" ] || exit 0
node -e "const s=(require(process.argv[1]).scripts)||{};process.exit(s.typecheck?0:1)" "$PROJECT_DIR/package.json" 2>/dev/null || exit 0

STATE_DIR="${HOME}/.claude/state/typecheck-gate"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

KEY=$(printf '%s' "$PROJECT_DIR" | cksum | cut -d' ' -f1)
ERR_FILE="$STATE_DIR/${KEY}.errors"
LOCK_DIR="$STATE_DIR/${KEY}.lock"

# 異常終了で残った古いロック（10 分以上）は掃除する
if [ -d "$LOCK_DIR" ] && [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +10 2>/dev/null)" ]; then
  rmdir "$LOCK_DIR" 2>/dev/null || true
fi

# 同プロジェクトで既に走っていれば二重起動しない（mkdir は atomic）
mkdir "$LOCK_DIR" 2>/dev/null || exit 0

# バックグラウンドで typecheck。stdio を /dev/null に切り離し、Stop を待たせない。
(
  trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
  if OUT=$(cd "$PROJECT_DIR" && npm run typecheck 2>&1); then
    rm -f "$ERR_FILE" 2>/dev/null || true
  else
    {
      printf '%s\n' "$PROJECT_DIR"
      printf '%s\n' "$OUT" | tail -n 25
    } > "$ERR_FILE" 2>/dev/null || true
  fi
) >/dev/null 2>&1 &

disown 2>/dev/null || true
exit 0

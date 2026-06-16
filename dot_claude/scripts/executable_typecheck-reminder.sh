#!/usr/bin/env bash
# typecheck-reminder.sh - UserPromptSubmit hook
#
# 現プロジェクト（cwd）に typecheck-gate が記録した型エラーがあれば
# <system-reminder> として Claude に通知する。無ければ無音 exit 0。
#
# state: ~/.claude/state/typecheck-gate/<PWDハッシュ>.errors

set -uo pipefail

STATE_DIR="${HOME}/.claude/state/typecheck-gate"
KEY=$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)
ERR_FILE="$STATE_DIR/${KEY}.errors"

[ -f "$ERR_FILE" ] || exit 0
ERRORS=$(cat "$ERR_FILE" 2>/dev/null)
[ -n "$ERRORS" ] || exit 0

cat <<EOF
<system-reminder>
直近の Stop 後に走らせた \`npm run typecheck\` が型エラーで失敗しています（typecheck-gate による自動検出）。キリの良いところで修正を検討してください。エラーが解消すれば次回 Stop 時にこの通知は自動で消えます。

--- typecheck 出力（1 行目=プロジェクトパス / 以降=末尾 25 行）---
${ERRORS}
---
無効化したい場合: ~/.claude/state/typecheck-gate/ の該当 .errors を削除、または settings.json の Stop hook を外す。
</system-reminder>
EOF

exit 0

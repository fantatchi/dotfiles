#!/usr/bin/env bash
# claude-md-audit-reminder.sh - SessionStart hook
#
# 最後のリマインダー発火から N 日以上経過していたら <system-reminder> を stdout
# 出力し、Claude にユーザーへ CLAUDE.md 監査スキルの実行を提案させる。
# 閾値未満なら無音 exit 0。
#
# state file: ~/.claude/state/claude-md-audit/last-reminder.txt（epoch seconds）
# 閾値: 環境変数 CLAUDE_MD_AUDIT_THRESHOLD_DAYS で上書き可（既定 7）

set -uo pipefail

THRESHOLD_DAYS="${CLAUDE_MD_AUDIT_THRESHOLD_DAYS:-7}"
STATE_DIR="${HOME}/.claude/state/claude-md-audit"
STATE_FILE="${STATE_DIR}/last-reminder.txt"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

NOW=$(date +%s)
LAST=0
if [ -f "$STATE_FILE" ]; then
    LAST=$(cat "$STATE_FILE" 2>/dev/null | tr -cd '0-9' | head -c 20)
fi
[ -z "$LAST" ] && LAST=0

# 初回（state file 無し or 空）: 基準点を今に置いて無音 exit。
# THRESHOLD_DAYS 日後の SessionStart で初発火する。
if [ "$LAST" -eq 0 ]; then
    echo "$NOW" > "$STATE_FILE" 2>/dev/null || true
    exit 0
fi

ELAPSED_DAYS=$(( (NOW - LAST) / 86400 ))
[ "$ELAPSED_DAYS" -ge "$THRESHOLD_DAYS" ] || exit 0

cat <<EOF
<system-reminder>
CLAUDE.md の最終監査リマインダーから ${ELAPSED_DAYS} 日経過しています（閾値: ${THRESHOLD_DAYS} 日）。

このセッションのキリの良いタイミングで、以下のいずれかの audit 実行をユーザーに提案してください:

1. グローバル (~/.claude/CLAUDE.md)
   - 起動方法: \`cd ~/.local/share/chezmoi/dot_claude && /claude-md-management:claude-md-improver\`
   - 編集対象は chezmoi source。完了後ユーザーが \`chezmoi apply\` で target 同期 + 任意で commit

2. 現在プロジェクト (./CLAUDE.md)
   - 起動方法: そのまま \`/claude-md-management:claude-md-improver\`

ユーザーが「やる」と言うまで待つ。すぐ作業に入りたい場合は無視して通常応答へ。
頻度調整: \`export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14\` などで延長可。
</system-reminder>
EOF

echo "$NOW" > "$STATE_FILE" 2>/dev/null || true
exit 0

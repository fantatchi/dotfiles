#!/usr/bin/env bash
# claude-md-audit-reminder.sh - UserPromptSubmit hook
#
# 最後の「監査実施」から N 日以上経過していたら <system-reminder> を stdout
# 出力し、Claude にユーザーへ CLAUDE.md 監査スキルの実行を提案させる。
# 閾値未満なら無音 exit 0。
#
# state を 2 ファイルに分離する（2026-07-07 改訂）:
#   last-audit.txt    = 監査実施時刻（監査完了時にスキル側/モデルが更新する）
#   last-reminder.txt = 最終発火時刻（スヌーズ用、発火時にこのスクリプトが更新）
# 旧設計は発火時刻のみを state にしていたため「発火→無視→7 日沈黙」を繰り返し、
# 監査が実際に行われたかを機構が知れなかった。実施時刻ベースなら overdue の間
# 24h スヌーズ付きで発火し続け、放置が可視化される。
#
# 閾値: 環境変数 CLAUDE_MD_AUDIT_THRESHOLD_DAYS で上書き可（既定 7）

set -uo pipefail

THRESHOLD_DAYS="${CLAUDE_MD_AUDIT_THRESHOLD_DAYS:-7}"
SNOOZE_MIN=1440   # overdue 中の再発火間隔（分）
STATE_DIR="${HOME}/.claude/state/claude-md-audit"
AUDIT_FILE="${STATE_DIR}/last-audit.txt"
SNOOZE_FILE="${STATE_DIR}/last-reminder.txt"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

NOW=$(date +%s)

LAST_AUDIT=0
if [ -f "$AUDIT_FILE" ]; then
    LAST_AUDIT=$(cat "$AUDIT_FILE" 2>/dev/null | tr -cd '0-9' | head -c 20)
fi
[ -z "$LAST_AUDIT" ] && LAST_AUDIT=0

# 移行措置: last-audit.txt が無ければ旧 state（発火時刻）を最終実施時刻とみなして引き継ぐ
if [ "$LAST_AUDIT" -eq 0 ] && [ -f "$SNOOZE_FILE" ]; then
    LAST_AUDIT=$(cat "$SNOOZE_FILE" 2>/dev/null | tr -cd '0-9' | head -c 20)
    [ -z "$LAST_AUDIT" ] && LAST_AUDIT=0
    [ "$LAST_AUDIT" -gt 0 ] && { echo "$LAST_AUDIT" > "$AUDIT_FILE" 2>/dev/null || true; }
fi

# 初回（state 一切無し）: 基準点を今に置いて無音 exit。THRESHOLD_DAYS 日後に初発火する。
if [ "$LAST_AUDIT" -eq 0 ]; then
    echo "$NOW" > "$AUDIT_FILE" 2>/dev/null || true
    exit 0
fi

ELAPSED_DAYS=$(( (NOW - LAST_AUDIT) / 86400 ))
[ "$ELAPSED_DAYS" -ge "$THRESHOLD_DAYS" ] || exit 0

# スヌーズ: 直近の発火から SNOOZE_MIN 未満なら無音（overdue でも毎プロンプトは出さない）
LAST_FIRED=0
if [ -f "$SNOOZE_FILE" ]; then
    LAST_FIRED=$(cat "$SNOOZE_FILE" 2>/dev/null | tr -cd '0-9' | head -c 20)
fi
[ -z "$LAST_FIRED" ] && LAST_FIRED=0
if [ "$LAST_FIRED" -gt 0 ] && [ $(( (NOW - LAST_FIRED) / 60 )) -lt "$SNOOZE_MIN" ]; then
    exit 0
fi

cat <<EOF
<system-reminder>
CLAUDE.md の最終監査から ${ELAPSED_DAYS} 日経過しています（閾値: ${THRESHOLD_DAYS} 日）。

このセッションのキリの良いタイミングで、以下のいずれかの audit 実行をユーザーに提案してください:

1. グローバル (~/.claude/CLAUDE.md)
   - 起動方法: \`cd ~/.local/share/chezmoi/dot_claude && /claude-md-management:claude-md-improver\`
   - 編集対象は chezmoi source。完了後ユーザーが \`chezmoi apply\` で target 同期 + 任意で commit

2. 現在プロジェクト (./CLAUDE.md)
   - 起動方法: そのまま \`/claude-md-management:claude-md-improver\`

ユーザーが「やる」と言うまで待つ。すぐ作業に入りたい場合は無視して通常応答へ
（実施するまで 24h ごとに再通知されます）。
**監査を実施したら必ず** \`date +%s > ~/.claude/state/claude-md-audit/last-audit.txt\` を実行して実施を記録してください。
頻度調整: \`export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14\` などで延長可。
</system-reminder>
EOF

echo "$NOW" > "$SNOOZE_FILE" 2>/dev/null || true
exit 0

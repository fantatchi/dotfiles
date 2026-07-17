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
# 監査実施時刻は Vault 側を正とする（2026-07-17 改訂）:
# CLAUDE.md は chezmoi で全 PC 共通の 1 つの成果物なので「いつ監査したか」はグローバルな事実。
# state をマシンローカルに置くと、1 台で監査しても他の PC は知り得ず誤発火し続ける（実害を観測）。
# state の保存先スコープを事実のスコープに合わせ、last-audit のみ Obsidian Sync 経路へ移した。
# last-reminder（この PC で今日もう通知したか）はマシン固有の UX なのでローカルのまま。
#   Vault 不在 / 未同期 / ファイル欠損 / parse 失敗 → ローカルへフォールバック（従来挙動）。
#   最悪でも「マシンローカルで誤発火」に戻るだけで、監査を黙って飛ばす方向には倒れない。
# サブプロセスは起こさない（file read のみ）。hook のプロセス生成コストは timeout 死の主因
# （2026-07-09 に根治済み）なので、ここに git 等を持ち込まないこと。
#
# 閾値: 環境変数 CLAUDE_MD_AUDIT_THRESHOLD_DAYS で上書き可（既定 7）

set -uo pipefail

THRESHOLD_DAYS="${CLAUDE_MD_AUDIT_THRESHOLD_DAYS:-7}"
SNOOZE_MIN=1440   # overdue 中の再発火間隔（分）
STATE_DIR="${HOME}/.claude/state/claude-md-audit"
AUDIT_FILE="${STATE_DIR}/last-audit.txt"
SNOOZE_FILE="${STATE_DIR}/last-reminder.txt"

# Vault パスは ~/.claude/skills/shared/integrations.md の vault / task_store_probe を SSOT として
# ミラー。Vault を移動したら .sh / .ps1 / run-hook.js の 3 箇所を grep で同時更新すること。
VAULT_PROBE="${HOME}/ObsidianVault/.obsidian"
SHARED_STATE="${HOME}/ObsidianVault/00_meta/claude-state.md"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

NOW=$(date +%s)

# 監査実施時刻の解決: Vault（全 PC 共通の正）→ ローカル（フォールバック）の順。
# frontmatter の `last_audit: <epoch>` のみを読む。`last_audit_at:`（ISO 併記・人間用）は
# キー名がコロンで区切られるため ^last_audit: にはマッチせず、取り違えない。
LAST_AUDIT=0
if [ -d "$VAULT_PROBE" ] && [ -f "$SHARED_STATE" ]; then
    LAST_AUDIT=$(grep -m1 -E '^last_audit:[[:space:]]*[0-9]+' "$SHARED_STATE" 2>/dev/null | tr -cd '0-9' | head -c 20)
    [ -z "$LAST_AUDIT" ] && LAST_AUDIT=0
fi

if [ "$LAST_AUDIT" -eq 0 ]; then
    # --- 以下フォールバック経路: Vault 不在 / 未同期 / 欠損 / parse 失敗（＝従来挙動そのまま） ---
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

**監査を実施したら必ず** \`~/ObsidianVault/00_meta/claude-state.md\` の frontmatter を更新してください
（全 PC 共通の記録。1 台で監査すれば他の PC でも黙る）:
- \`last_audit:\` を \`date +%s\` の出力へ（機械可読の正）
- \`last_audit_at:\` を \`date -Iseconds\` の出力へ（人間が読むための併記）
Vault が無い環境では \`date +%s > ~/.claude/state/claude-md-audit/last-audit.txt\`（このマシンのみ有効）。
頻度調整: \`export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14\` などで延長可。
</system-reminder>
EOF

echo "$NOW" > "$SNOOZE_FILE" 2>/dev/null || true
exit 0

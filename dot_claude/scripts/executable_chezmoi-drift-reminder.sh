#!/usr/bin/env bash
# chezmoi-drift-reminder.sh - UserPromptSubmit hook
#
# `chezmoi status` が非空（= source と target のドリフト）なら <system-reminder> を
# stdout 出力し、Claude に突合（re-add / apply）の提案を促す。差分なしなら無音 exit 0。
#
# 背景: docs/ のローカル消失が 2 週間検知されなかった実例（2026-07-07 監査）。
# ドリフトは参照側が silent fail するため、検知を事後（人力）→即時（機構）に引き上げる。
#
# デバウンス: state に「最終通知 epoch + status 出力ハッシュ」を保持し、
# ハッシュ変化（新しいドリフト）or 24h 経過で再通知。差分解消時は state を消す。
# チェック間隔ゲート: `chezmoi status` は I/O バウンドで 2〜4 秒かかり（2026-07-09 実測）、
# 毎プロンプト実行だとレイテンシ + 負荷時の hook timeout 死の原因になるため、
# 実行そのものを CHECK_INTERVAL_MIN 分に 1 回へ間引く（通知デバウンスとは別レイヤー）。
# last-check は status 実行「前」に書く = timeout で殺されても連続再試行しない。
# 除外: .chezmoiscripts/（run script の再実行 state はドリフトでない）

set -uo pipefail

RENOTIFY_MIN=1440       # 同一ドリフトの再通知間隔（分）
CHECK_INTERVAL_MIN=30   # chezmoi status 実行そのものの間隔（分）
STATE_DIR="${HOME}/.claude/state/chezmoi-drift"
STATE_FILE="${STATE_DIR}/last-notified.txt"
CHECK_FILE="${STATE_DIR}/last-check.txt"

command -v chezmoi >/dev/null 2>&1 || exit 0

NOW_EPOCH=$(date +%s)

# チェック間隔ゲート: 前回チェックから CHECK_INTERVAL_MIN 未満なら status を実行せず無音 exit
if [ -f "$CHECK_FILE" ]; then
    LAST_CHECK=$(tr -cd '0-9' < "$CHECK_FILE" | head -c 20)
    [ -n "$LAST_CHECK" ] || LAST_CHECK=0
    if [ $(( (NOW_EPOCH - LAST_CHECK) / 60 )) -lt "$CHECK_INTERVAL_MIN" ]; then
        exit 0
    fi
fi
mkdir -p "$STATE_DIR" 2>/dev/null || true
{ printf '%s\n' "$NOW_EPOCH" > "$CHECK_FILE"; } 2>/dev/null || true

STATUS=$(chezmoi status 2>/dev/null) || exit 0
DRIFT=$(printf '%s\n' "$STATUS" | grep -v '^\s*$' | grep -v ' \.chezmoiscripts/' || true)

if [ -z "$DRIFT" ]; then
    rm -f "$STATE_FILE" 2>/dev/null || true
    exit 0
fi

HASH=$(printf '%s' "$DRIFT" | md5sum 2>/dev/null | cut -d' ' -f1)
[ -n "$HASH" ] || HASH=$(printf '%s' "$DRIFT" | cksum | cut -d' ' -f1)

LAST_EPOCH=0
LAST_HASH=""
if [ -f "$STATE_FILE" ]; then
    LAST_EPOCH=$(sed -n '1p' "$STATE_FILE" 2>/dev/null | tr -cd '0-9' | head -c 20)
    LAST_HASH=$(sed -n '2p' "$STATE_FILE" 2>/dev/null)
    [ -n "$LAST_EPOCH" ] || LAST_EPOCH=0
fi

if [ "$HASH" = "$LAST_HASH" ] \
    && [ $(( (NOW_EPOCH - LAST_EPOCH) / 60 )) -lt "$RENOTIFY_MIN" ]; then
    exit 0
fi

DRIFT_HEAD=$(printf '%s\n' "$DRIFT" | head -n 15)
DRIFT_COUNT=$(printf '%s\n' "$DRIFT" | wc -l | tr -d ' ')

cat <<EOF
<system-reminder>
chezmoi のドリフト（source と target の差分）が ${DRIFT_COUNT} 件あります:

${DRIFT_HEAD}

キリの良いタイミングでユーザーに突合を提案してください（コード:
MM = 両側変更の要マージ / DA = target 欠損 / M = apply 待ち / A = re-add or apply 待ち）。
live 編集が正なら \`chezmoi re-add <path>\`、source が正なら \`chezmoi diff <path>\` で
確認のうえ \`chezmoi apply <path>\`。MM は両方の diff を見てからマージする。
無関係な作業中なら無視して通常応答へ。
</system-reminder>
EOF

{ printf '%s\n%s\n' "$NOW_EPOCH" "$HASH" > "$STATE_FILE"; } 2>/dev/null || true
exit 0

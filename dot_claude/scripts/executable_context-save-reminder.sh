#!/usr/bin/env bash
# context-save-reminder.sh - UserPromptSubmit hook
#
# .claude/context.md の frontmatter `updated:` と、セッション初回プロンプト時刻の
# どちらか新しい方を基準として、閾値以上経過していたら stdout に system-reminder
# ブロックを出力し、Claude に /context-save の実行を促す。
# 閾値未満なら何も出力せず exit 0（無音）。
#
# Claude Code は UserPromptSubmit hook の stdout を additional context として
# ユーザーの prompt に注入する仕様。
#
# セッション開始基準: 各 session_id ごとに `~/.claude/.session-markers/<session_id>`
# を作成し、その mtime を「このセッションの初回プロンプト時刻」として扱う。

set -uo pipefail

THRESHOLD_MIN=120
MARKER_DIR="${HOME}/.claude/.session-markers"
MARKER_TTL_DAYS=7

# stdin の JSON から session_id を取得（jq があれば優先、なければ sed フォールバック）
SESSION_ID=""
if STDIN_JSON=$(cat); then
    if command -v jq >/dev/null 2>&1; then
        SESSION_ID=$(printf '%s' "$STDIN_JSON" | jq -r '.session_id // empty' 2>/dev/null)
    fi
    if [ -z "$SESSION_ID" ]; then
        # 雑な抽出（jq が無い環境向け）
        SESSION_ID=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    fi
fi

# session_id が取れない場合でも reminder 機能自体は動くようにフォールバック
mkdir -p "$MARKER_DIR" 2>/dev/null || true

# 古いマーカーの掃除（best-effort）
find "$MARKER_DIR" -type f -mtime "+${MARKER_TTL_DAYS}" -delete 2>/dev/null || true

NOW_EPOCH=$(date +%s)

SESSION_START_EPOCH=0
if [ -n "$SESSION_ID" ]; then
    # session_id を安全な文字に制限
    SAFE_ID=$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9._-' '_' | cut -c1-128)
    MARKER_FILE="${MARKER_DIR}/${SAFE_ID}"

    if [ ! -f "$MARKER_FILE" ]; then
        # このセッションの初回プロンプト。マーカーを作って何も出さずに終了。
        : > "$MARKER_FILE" 2>/dev/null || true
        exit 0
    fi

    SESSION_START_EPOCH=$(stat -c '%Y' "$MARKER_FILE" 2>/dev/null \
        || stat -f '%m' "$MARKER_FILE" 2>/dev/null \
        || echo 0)
fi

# git リポジトリ外なら何もしない
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CONTEXT_FILE="${REPO_ROOT}/.claude/context.md"

# context.md が無いプロジェクトでは何もしない（初回は手動 /context-save 前提）
[ -f "$CONTEXT_FILE" ] || exit 0

# frontmatter から updated を抽出（context-save-hook.sh と同様のパターン）
UPDATED=$(awk '
    /^---$/ { fc++; if(fc==1) fm=1; else if(fc==2) { fm=0; exit }; next }
    fm && /^updated:/ {
        sub(/^updated:[[:space:]]*/, "")
        sub(/[[:space:]]+$/, "")
        print
        exit
    }
' "$CONTEXT_FILE")

[ -n "$UPDATED" ] || exit 0

# Unix 時刻に変換（ローカルタイム前提。context-save-hook.sh の書式と揃える）
UPDATED_EPOCH=$(date -d "$UPDATED" +%s 2>/dev/null) || exit 0

# 基準は max(updated, session_start)
BASELINE_EPOCH=$UPDATED_EPOCH
if [ "$SESSION_START_EPOCH" -gt "$BASELINE_EPOCH" ]; then
    BASELINE_EPOCH=$SESSION_START_EPOCH
fi

DIFF_MIN=$(( (NOW_EPOCH - BASELINE_EPOCH) / 60 ))

if [ "$DIFF_MIN" -ge "$THRESHOLD_MIN" ]; then
    cat <<EOF
<system-reminder>
最後の context 保存またはセッション開始から ${DIFF_MIN} 分経過しています（閾値: ${THRESHOLD_MIN} 分）。
このターンの応答に入る前に /context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。
保存が終わったら、続けてユーザーの本来のリクエストに応答してください。
</system-reminder>
EOF
fi

exit 0

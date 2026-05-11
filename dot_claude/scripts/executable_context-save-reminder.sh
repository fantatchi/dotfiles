#!/usr/bin/env bash
# context-save-reminder.sh - UserPromptSubmit hook
#
# .claude/context.md の frontmatter `updated:` を見て、閾値以上経過していたら
# stdout に system-reminder ブロックを出力し、Claude に /context-save の実行を促す。
# 閾値未満なら何も出力せず exit 0（無音）。
#
# Claude Code は UserPromptSubmit hook の stdout を additional context として
# ユーザーの prompt に注入する仕様。

set -uo pipefail

THRESHOLD_MIN=30

# フックは stdin に JSON を受け取るが今回は不要
exec < /dev/null

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
NOW_EPOCH=$(date +%s)
DIFF_MIN=$(( (NOW_EPOCH - UPDATED_EPOCH) / 60 ))

if [ "$DIFF_MIN" -ge "$THRESHOLD_MIN" ]; then
    cat <<EOF
<system-reminder>
最後の context 保存から ${DIFF_MIN} 分経過しています（閾値: ${THRESHOLD_MIN} 分）。
このターンの応答に入る前に /context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。
保存が終わったら、続けてユーザーの本来のリクエストに応答してください。
</system-reminder>
EOF
fi

exit 0

#!/usr/bin/env bash
# context-save-git-trigger.sh - PostToolUse hook (matcher: Bash。Claude は if で git commit / gh pr create に絞る。Codex は if が無いので本スクリプトで絞る)
#
# コミット・PR 作成は作業の区切りとほぼ一致するので、その直後に /context-save を促す。
# PostToolUse は plain stdout を Claude に見せないため、hookSpecificOutput.additionalContext の
# JSON で返す。
#
# - 成否判定: Bash の tool_response に exit code が無いので、git commit は HEAD のコミット時刻が
#   COMMIT_FRESH_SEC 以内なら成功とみなす。gh pr create は成否を判定せず通す
# - デバウンス: context.md の updated が DEBOUNCE_MIN 以内なら無音（連続コミット・保存直後の再発火防止）
# - context.md が無いプロジェクトでは何もしない（初回は手動 /context-save 前提。reminder と同じ）

set -uo pipefail

COMMIT_FRESH_SEC=120
DEBOUNCE_MIN=15

COMMAND=""
if STDIN_JSON=$(cat) && command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null)
fi

git rev-parse --is-inside-work-tree &>/dev/null || exit 0
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CONTEXT_FILE="${REPO_ROOT}/.claude/context.md"
[ -f "$CONTEXT_FILE" ] || exit 0

NOW_EPOCH=$(date +%s)

# コマンドの先頭か区切り（; & |）直後の git commit で、かつ HEAD が新しければコミット成功とみなす。
# gh pr create も同じく先頭か区切り直後のときだけ PR 作成とみなす（コミットメッセージ本文中の文字列に
# 反応しないため）。Codex の hooks には Claude の `if` が無く、全 Bash 実行で呼ばれるのでここで絞る
HEAD_EPOCH=$(git log -1 --format=%ct 2>/dev/null || echo 0)
if printf '%s' "$COMMAND" | grep -qE '(^|[;&|])[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit\b' \
    && [ $(( NOW_EPOCH - HEAD_EPOCH )) -le "$COMMIT_FRESH_SEC" ]; then
    EVENT="コミット"
elif printf '%s' "$COMMAND" | grep -qE '(^|[;&|])[[:space:]]*gh[[:space:]]+pr[[:space:]]+create\b'; then
    EVENT="PR 作成"
else
    exit 0
fi

UPDATED=$(awk '
    /^---$/ { fc++; if(fc==1) fm=1; else if(fc==2) { fm=0; exit }; next }
    fm && /^updated:/ { sub(/^updated:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit }
' "$CONTEXT_FILE")
if [ -n "$UPDATED" ] && UPDATED_EPOCH=$(date -d "$UPDATED" +%s 2>/dev/null); then
    [ $(( (NOW_EPOCH - UPDATED_EPOCH) / 60 )) -ge "$DEBOUNCE_MIN" ] || exit 0
fi

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"${EVENT}が完了し、作業の区切りです。ユーザーへの報告の前に context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。"}}
EOF
exit 0

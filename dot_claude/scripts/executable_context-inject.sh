#!/usr/bin/env bash
# context-inject.sh - SessionStart hook (matcher: startup|compact)
#
# 起動時と compact 直後に、.claude/context.md / tasks.md の要点と「保存後の git 変化」を
# plain stdout で出力する。SessionStart は plain stdout を Claude の文脈に入れる仕様
# （上限 10,000 字。超えるとファイル退避 + 2,000 字プレビューになるため手前で打ち切る）。
# 詳細な復帰（PR 実査・progress.md・handoff.md）は手動の /context-load が担う。
# resume / clear は settings.json の matcher で除外している（resume は会話ログが戻る、
# clear はリセットの意図）。

set -uo pipefail

MAX_CHARS=6000

SOURCE=""
if STDIN_JSON=$(cat); then
    if command -v jq >/dev/null 2>&1; then
        SOURCE=$(printf '%s' "$STDIN_JSON" | jq -r '.source // empty' 2>/dev/null)
    else
        SOURCE=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    fi
fi

git rev-parse --is-inside-work-tree &>/dev/null || exit 0
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CONTEXT_FILE="${REPO_ROOT}/.claude/context.md"
TASKS_FILE="${REPO_ROOT}/.claude/tasks.md"
[ -f "$CONTEXT_FILE" ] || exit 0

# `## <name>` 見出しから次の `## ` 見出しの直前までを出す（見出し行は含めない）
section() {
    awk -v name="$2" '
        /^## / { if (on) exit; if ($0 == "## " name) { on = 1; next } }
        on { print }
    ' "$1" | sed -e '/./,$!d'
}

UPDATED=$(awk '
    /^---$/ { fc++; if(fc==1) fm=1; else if(fc==2) { fm=0; exit }; next }
    fm && /^updated:/ { sub(/^updated:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit }
' "$CONTEXT_FILE")

OUT=$(
    if [ "$SOURCE" = "compact" ]; then
        echo "## compact 後の再注入（.claude/context.md 最終保存: ${UPDATED:-不明}）"
        echo "compact の要約で落ちた作業状態を補うため、保存済みの要点を再掲する。保存後の作業は要約側が正。"
    else
        echo "## 前回の作業状態（.claude/context.md 最終保存: ${UPDATED:-不明}）"
        echo "SessionStart hook による自動注入。PR の実査・progress.md・handoff.md まで見るなら context-load スキル。"
    fi

    if [ -f "$TASKS_FILE" ]; then
        NEXT=$(section "$TASKS_FILE" "Next")
        [ -n "$NEXT" ] && printf '\n### 次にやること（tasks.md の Next）\n%s\n' "$NEXT"
    fi

    WIP=$(section "$CONTEXT_FILE" "進行中の作業")
    [ -n "$WIP" ] && printf '\n### 進行中の作業\n%s\n' "$WIP"

    DECISIONS=$(section "$CONTEXT_FILE" "判断メモ")
    [ -n "$DECISIONS" ] && printf '\n### 判断メモ\n%s\n' "$DECISIONS"

    printf '\n### 保存後の git 変化\n'
    if [ -n "$UPDATED" ]; then
        COMMITS=$(git log --since="$UPDATED" --oneline 2>/dev/null)
        if [ -n "$COMMITS" ]; then
            echo "- 保存後のコミット: $(printf '%s\n' "$COMMITS" | wc -l | tr -d ' ') 件"
            printf '%s\n' "$COMMITS" | head -n 5 | sed 's/^/  - /'
        else
            echo "- 保存後のコミット: なし"
        fi
    fi
    if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- . ':!.claude/context.md' ':!.claude/tasks.md' ':!.claude/handoff.md' ':!.claude/progress.md' 2>/dev/null)" ]; then
        echo "- 未コミットの変更: あり"
    else
        echo "- 未コミットの変更: なし"
    fi
)

if [ "${#OUT}" -gt "$MAX_CHARS" ]; then
    printf '%s\n…（%s 字で打ち切り。全文は .claude/context.md / tasks.md を読む）\n' "${OUT:0:$MAX_CHARS}" "$MAX_CHARS"
else
    printf '%s\n' "$OUT"
fi
exit 0

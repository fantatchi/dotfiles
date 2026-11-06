#!/usr/bin/env bash
# context-inject.sh - SessionStart hook (matcher: startup|compact)
#
# 起動時と compact 直後に、「保存後の git 変化」「handoff.md の要約」と .claude/context.md / tasks.md の要点を
# plain stdout で出力する。SessionStart は plain stdout を Claude の文脈に入れる仕様
# （上限 10,000 字。超えるとファイル退避 + 2,000 字プレビューになるため手前で打ち切る）。
# Codex も同じスクリプトを使い、上限が 6,000 字（~/.codex/hooks.json の additionalContextLimit）なので、
# 打ち切り注記まで含めて収まるよう MAX_CHARS は 5,800 にしている。
# handoff.md は要約（書き手・topic・未解決の先頭 2 行）だけを出す。自分側の自動保存が、相手の引き継ぎを
# 読む前に上書きしないようにするため（2026-11-06 のレビュー）。詳細な復帰は手動の /context-load が担う。
# git 外（ホームワークスペース等）では CWD の .claude/ を読み、git 変化は「git 管理外」と出す。
# resume / clear は settings.json の matcher で除外している（resume は会話ログが戻る、
# clear はリセットの意図）。

set -uo pipefail
# ロケール未設定の起動経路でも ${#OUT} / ${OUT:0:N} を文字単位にする（バイト単位だと多バイト文字を割る）
export LC_ALL=C.UTF-8

MAX_CHARS=5800

SOURCE=""
if STDIN_JSON=$(cat); then
    if command -v jq >/dev/null 2>&1; then
        SOURCE=$(printf '%s' "$STDIN_JSON" | jq -r '.source // empty' 2>/dev/null)
    else
        SOURCE=$(printf '%s' "$STDIN_JSON" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    fi
fi

if REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    IN_GIT=1
else
    REPO_ROOT=$PWD
    IN_GIT=0
fi
CONTEXT_FILE="${REPO_ROOT}/.claude/context.md"
TASKS_FILE="${REPO_ROOT}/.claude/tasks.md"
HANDOFF_FILE="${REPO_ROOT}/.claude/handoff.md"
[ -f "$CONTEXT_FILE" ] || exit 0

# Windows 側の writer が書いた CRLF・BOM 付きのファイルも読めるよう、行末の \r と先頭の BOM を落として読む
clean() {
    sed -e '1s/^\xef\xbb\xbf//' -e 's/\r$//' "$1"
}

# `## <name>` 見出しから次の `## ` 見出しの直前までを出す（見出し行は含めない）
section() {
    clean "$1" | awk -v name="$2" '
        /^## / { if (on) exit; if ($0 == "## " name) { on = 1; next } }
        on { print }
    ' | sed -e '/./,$!d'
}

# 先頭の frontmatter から key の値を出す（引用符は外す）
frontmatter() {
    clean "$1" | awk -v key="$2" '
        NR == 1 && $0 != "---" { exit }
        /^---$/ { fc++; if (fc == 2) exit; next }
        fc == 1 && index($0, key ":") == 1 {
            sub("^" key ":[[:space:]]*", ""); sub(/[[:space:]]+$/, "")
            gsub(/^["\047]|["\047]$/, ""); print; exit
        }
    '
}

UPDATED=$(frontmatter "$CONTEXT_FILE" updated)

OUT=$(
    if [ "$SOURCE" = "compact" ]; then
        echo "## compact 後の再注入（.claude/context.md 最終保存: ${UPDATED:-不明}）"
        echo "compact の要約で落ちた作業状態を補うため、保存済みの要点を再掲する。保存後の作業は要約側が正。"
    else
        echo "## 前回の作業状態（.claude/context.md 最終保存: ${UPDATED:-不明}）"
        echo "SessionStart hook による自動注入。PR の実査・progress.md・handoff.md の全文まで見るなら context-load スキル。"
    fi

    printf '\n### 保存後の git 変化\n'
    if [ "$IN_GIT" = 0 ]; then
        echo "- git 管理外"
    else
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
    fi

    if [ -f "$HANDOFF_FILE" ]; then
        H_FROM=$(frontmatter "$HANDOFF_FILE" from)
        H_AT=$(frontmatter "$HANDOFF_FILE" at)
        H_TOPIC=$(frontmatter "$HANDOFF_FILE" topic)
        # 見出しに「未解決」「未確認」「詰ま」を含むセクションの、なし 以外の先頭 2 行（見出し名は書き手で揺れる）
        H_OPEN=$(clean "$HANDOFF_FILE" | awk '
            /^## / { on = ($0 ~ /未解決|未確認|詰ま/); next }
            on && NF && $0 !~ /^-[[:space:]]*なし[[:space:]]*$/ { print; if (++n >= 2) exit }
        ')
        printf '\n### 引き継ぎメモ（handoff.md）\n'
        echo "- 書き手: ${H_FROM:-不明}（${H_AT:-不明}）／topic: ${H_TOPIC:-不明}"
        if [ -n "$H_OPEN" ]; then
            echo "- 未解決:"
            printf '%s\n' "$H_OPEN" | sed 's/^/  /'
        else
            echo "- 未解決: なし"
        fi
        echo "- 試して駄目だったこと・仮説などの全文は /context-load で読む"
    fi

    if [ -f "$TASKS_FILE" ]; then
        NEXT=$(section "$TASKS_FILE" "Next")
        [ -n "$NEXT" ] && printf '\n### 次にやること（tasks.md の Next）\n%s\n' "$NEXT"
    fi

    WIP=$(section "$CONTEXT_FILE" "進行中の作業")
    [ -n "$WIP" ] && printf '\n### 進行中の作業\n%s\n' "$WIP"

    DECISIONS=$(section "$CONTEXT_FILE" "判断メモ")
    [ -n "$DECISIONS" ] && printf '\n### 判断メモ\n%s\n' "$DECISIONS"
)

if [ "${#OUT}" -gt "$MAX_CHARS" ]; then
    printf '%s\n…（%s 字で打ち切り。全文は .claude/context.md / tasks.md を読む）\n' "${OUT:0:$MAX_CHARS}" "$MAX_CHARS"
else
    printf '%s\n' "$OUT"
fi
exit 0

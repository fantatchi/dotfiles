#!/usr/bin/env bash
# context-save-hook.sh - SessionEnd フックから直接 git 状態を保存する
#
# Claude を介さずシェルスクリプトで実行するため、/clear やセッション終了時にも
# 確実に動作する。セッション知識（判断メモ・次のステップ等）は保存できないため、
# git 由来の機械的な情報（ブランチ・コミット・未コミット変更）のみ更新する。

set -euo pipefail

# フックは stdin に JSON を受け取るが、本スクリプトでは使わないので閉じる
exec < /dev/null

CONTEXT_DIR="${HOME}/.claude/context"

# git リポジトリ外なら何もしない
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# 情報収集
REPO_ROOT=$(git rev-parse --show-toplevel)
PROJECT_ID=$(basename "$REPO_ROOT")
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
STATUS=$(git status --short 2>/dev/null || echo "")
UPDATED=$(date +%Y-%m-%dT%H:%M:%S)

# コミットログ整形
COMMITS=""
while IFS= read -r line; do
    [ -n "$line" ] && COMMITS="${COMMITS}  - \`${line}\`"$'\n'
done < <(git log --oneline -5 2>/dev/null || true)

# 未コミット変更
if [ -z "$STATUS" ]; then
    UNCOMMITTED="なし"
    STATUS_LINES=""
else
    UNCOMMITTED="あり"
    STATUS_LINES=""
    while IFS= read -r line; do
        [ -n "$line" ] && STATUS_LINES="${STATUS_LINES}  - \`${line}\`"$'\n'
    done <<< "$STATUS"
fi

# 「現在の状態」セクションを生成
STATE_SECTION="## 現在の状態

- **ブランチ**: \`${BRANCH}\`
- **直近のコミット**:
${COMMITS}- **未コミットの変更**: ${UNCOMMITTED}"
[ -n "$STATUS_LINES" ] && STATE_SECTION="${STATE_SECTION}"$'\n'"${STATUS_LINES}"

mkdir -p "$CONTEXT_DIR"
CONTEXT_FILE="${CONTEXT_DIR}/${PROJECT_ID}.md"

# --- 既存ファイルの更新 ---
if [ -f "$CONTEXT_FILE" ]; then
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT

    # 「## 現在の状態」セクションの行番号を探す
    STATE_LINE=$(grep -n "^## 現在の状態" "$CONTEXT_FILE" | head -1 | cut -d: -f1 || echo "")

    if [ -n "$STATE_LINE" ]; then
        # 次の ## 見出しの相対行番号（現在の状態の次の行から検索）
        NEXT_OFFSET=$(tail -n +"$((STATE_LINE + 1))" "$CONTEXT_FILE" \
            | grep -n "^## " | head -1 | cut -d: -f1 || echo "")

        # Part 1: 現在の状態の前まで（frontmatter の branch/updated を更新）
        head -n "$((STATE_LINE - 1))" "$CONTEXT_FILE" | awk \
            -v branch="$BRANCH" -v updated="$UPDATED" '
            BEGIN { fm=0; fc=0 }
            /^---$/ { fc++; if(fc==1) fm=1; if(fc==2) fm=0; print; next }
            fm && /^branch:/ { print "branch: " branch; next }
            fm && /^updated:/ { print "updated: " updated; next }
            { print }
        ' > "$TMP"

        # Part 2: 新しい「現在の状態」セクション
        printf '%s\n\n' "$STATE_SECTION" >> "$TMP"

        # Part 3: 残りのセクション
        if [ -n "$NEXT_OFFSET" ]; then
            RESUME=$((STATE_LINE + NEXT_OFFSET))
            tail -n +"$RESUME" "$CONTEXT_FILE" >> "$TMP"
        fi
    else
        # 「現在の状態」セクションがない → frontmatter だけ更新
        awk -v branch="$BRANCH" -v updated="$UPDATED" '
            BEGIN { fm=0; fc=0 }
            /^---$/ { fc++; if(fc==1) fm=1; if(fc==2) fm=0; print; next }
            fm && /^branch:/ { print "branch: " branch; next }
            fm && /^updated:/ { print "updated: " updated; next }
            { print }
        ' "$CONTEXT_FILE" > "$TMP"
    fi

    mv "$TMP" "$CONTEXT_FILE"
    trap - EXIT

# --- 新規作成 ---
else
    cat > "$CONTEXT_FILE" << ENDOFTEMPLATE
---
project: ${PROJECT_ID}
git_remote: ${REMOTE}
branch: ${BRANCH}
updated: ${UPDATED}
tags:
  - claude-context
---

## プロジェクト概要

（自動保存により作成。次回 /context-save で詳細を記録してください）

${STATE_SECTION}

## 次のステップ

- [ ] （未記入）
ENDOFTEMPLATE
fi

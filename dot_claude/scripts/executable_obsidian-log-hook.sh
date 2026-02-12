#!/usr/bin/env bash
# obsidian-log-hook.sh - PreCompact フックから git diff ベースの簡易ログを記録する
#
# Claude のセッション内容は取得できないため、git 由来の情報のみ。
# 手動 /obsidian-log の補完（忘れたとき用のフォールバック）。
# 未コミット変更がなければスキップする。

set -euo pipefail

CONFIG_FILE="${HOME}/.claude/config.json"

# config.json から obsidian_vault を読み取る
if [ ! -f "$CONFIG_FILE" ]; then
    exit 0
fi

VAULT=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('obsidian_vault',''))" "$CONFIG_FILE" 2>/dev/null || echo "")
if [ -z "$VAULT" ]; then
    exit 0
fi

# git リポジトリ外なら何もしない
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# 未コミット変更がなければスキップ
STATUS=$(git status --short 2>/dev/null || echo "")
if [ -z "$STATUS" ]; then
    exit 0
fi

# 情報収集
REPO_ROOT=$(git rev-parse --show-toplevel)
PROJECT=$(basename "$REPO_ROOT")
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DATE=$(date +%Y-%m-%d)
DIFF_STAT=$(git diff --stat 2>/dev/null || echo "")
DIFF_STAGED=$(git diff --cached --stat 2>/dev/null || echo "")

# 変更ファイル数
FILES_CHANGED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')

# 変更ファイル一覧（テーブル行）
FILE_TABLE=""
while IFS= read -r line; do
    [ -z "$line" ] && continue
    OP=$(echo "$line" | awk '{print $1}')
    FILE=$(echo "$line" | awk '{print $2}')
    FILE_TABLE="${FILE_TABLE}| ${OP} | \`${FILE}\` |"$'\n'
done <<< "$STATUS"

# 直近コミット
COMMITS=""
while IFS= read -r line; do
    [ -n "$line" ] && COMMITS="${COMMITS}- \`${line}\`"$'\n'
done < <(git log --oneline -5 2>/dev/null || true)

# 書き出し先
LOG_DIR="${VAULT}/_claude/log"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${TIMESTAMP}_auto-git-diff.md"

cat > "$LOG_FILE" << ENDOFLOG
---
tags:
  - claude-log
  - auto
date: ${DATE}
project: ${PROJECT}
files_changed: ${FILES_CHANGED}
---

## 概要

PreCompact 自動記録（git diff ベース）。セッション中の未コミット変更を記録。

## 変更サマリ

**プロジェクト**: ${PROJECT}
**ブランチ**: \`${BRANCH}\`

### 未コミットの変更

\`\`\`
${STATUS}
\`\`\`

${DIFF_STAT:+### diff --stat

\`\`\`
${DIFF_STAT}
\`\`\`
}
${DIFF_STAGED:+### diff --cached --stat

\`\`\`
${DIFF_STAGED}
\`\`\`
}
### 直近のコミット

${COMMITS}
## 変更ファイル一覧

| 操作 | ファイル |
|------|----------|
${FILE_TABLE}
ENDOFLOG

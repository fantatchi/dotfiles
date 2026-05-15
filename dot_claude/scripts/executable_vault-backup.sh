#!/usr/bin/env bash
# Weekly snapshot backup of ObsidianVault to git remote.
# Register this in Task Scheduler (or cron) on ONE PC only — running on multiple
# PCs simultaneously will cause git push conflicts.
set -euo pipefail

VAULT="${HOME}/ObsidianVault"
LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/vault-backup.log"

mkdir -p "${LOG_DIR}"

{
  echo "=== $(date -Iseconds) vault-backup start ==="
  cd "${VAULT}"
  git add -A
  if git diff --cached --quiet; then
    echo "no changes, skip commit"
  else
    git commit -m "weekly snapshot $(date +%F)"
    git push
    echo "pushed"
  fi
  echo "=== $(date -Iseconds) vault-backup end ==="
} >> "${LOG_FILE}" 2>&1

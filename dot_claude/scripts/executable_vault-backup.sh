#!/usr/bin/env bash
# Snapshot backup of ObsidianVault to git remote(s). Frequency-agnostic
# (run via Task Scheduler/cron; daily recommended for RPO 24h on tasks.md,
# weekly OK for lower frequency / heavier note edits only).
# Backs up two repos: outer vault (obsidian-vault.git) + inner .obsidian (obsidian-config.git).
# Register this in Task Scheduler (or cron) on ONE PC only — running on multiple
# PCs simultaneously will cause git push conflicts.
set -uo pipefail

VAULT="${HOME}/ObsidianVault"
LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/vault-backup.log"

mkdir -p "${LOG_DIR}"

backup_repo() {
  local repo_path="$1"
  local label="$2"
  echo "--- $label ---"
  cd "$repo_path" || { echo "ERROR: cd failed"; return 1; }
  git add -A || { echo "ERROR: git add failed"; return 1; }
  if git diff --cached --quiet; then
    echo "no changes, skip commit"
    return 0
  fi
  git commit -m "snapshot $(date +%F)" || { echo "ERROR: git commit failed"; return 1; }
  git push || { echo "ERROR: git push failed"; return 1; }
  echo "pushed"
}

exit_code=0
{
  echo "=== $(date -Iseconds) vault-backup start ==="
  backup_repo "${VAULT}" "vault" || exit_code=$?
  backup_repo "${VAULT}/.obsidian" ".obsidian" || exit_code=$?
  echo "=== $(date -Iseconds) vault-backup end (rc=${exit_code}) ==="
} >> "${LOG_FILE}" 2>&1

exit "${exit_code}"

#!/usr/bin/env bash
# Manual backup of ObsidianVault (outer Vault only) to git remote.
# 2026-05-22: 自動運用 (Task Scheduler / obsidian-git plugin) を撤去し、本スクリプトは
# **手動起動の DR backup** に降格した。Obsidian Sync が multi-PC 同期の正本で、本スクリプトは
# 重要な節目 (フォルダ刷新・大量編集後等) に手動で 1 snapshot を打つための補助経路。
#
# `.obsidian/` の git backup は本スクリプトでは扱わない。`.obsidian/` は per-PC 固有の config
# (app.json / community-plugins.json 等) を含み、PC をまたいで上書きすると UI 設定が壊れる構造的
# 問題があったため、2026-05-22 に `.obsidian/.git` + GitHub の obsidian-config.git remote を
# 完全撤去した。.obsidian/ の multi-PC 同期は Obsidian Sync の Selective Sync に一本化。
#
# どの PC から実行しても安全になるよう、push 前に fetch + reset --hard で origin に追従し、
# Obsidian Sync 由来の working tree を真実の出典として再 stage する。
#
# 使い方: `wsl ~/.claude/scripts/vault-backup.sh` (Windows から手動起動)
#          `bash ~/.claude/scripts/vault-backup.sh` (WSL/Linux 内から手動起動)
set -uo pipefail

VAULT="${HOME}/ObsidianVault"
LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/vault-backup.log"

mkdir -p "${LOG_DIR}"

backup_vault() {
  echo "--- vault ---"
  cd "${VAULT}" || { echo "ERROR: cd failed"; return 1; }

  # 他 PC が push した差分を取り込み (作業ツリーは Obsidian Sync 管理下なので reset --hard で安全)
  git fetch origin || { echo "ERROR: fetch failed"; return 1; }
  local default_branch
  default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
  default_branch="${default_branch:-master}"
  git reset --hard "origin/${default_branch}" || { echo "ERROR: reset failed"; return 1; }

  git add -A || { echo "ERROR: git add failed"; return 1; }
  if git diff --cached --quiet; then
    echo "no changes, skip commit"
    return 0
  fi
  git commit -m "snapshot $(date +'%Y-%m-%d %H:%M:%S')" || { echo "ERROR: git commit failed"; return 1; }
  git push || { echo "ERROR: git push failed"; return 1; }
  echo "pushed"
}

exit_code=0
{
  echo "=== $(date -Iseconds) vault-backup start ==="
  backup_vault || exit_code=$?
  echo "=== $(date -Iseconds) vault-backup end (rc=${exit_code}) ==="
} >> "${LOG_FILE}" 2>&1

exit "${exit_code}"

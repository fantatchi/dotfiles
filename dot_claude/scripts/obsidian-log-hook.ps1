#!/usr/bin/env pwsh
# obsidian-log-hook.ps1 - PreCompact フックから git diff ベースの簡易ログを記録する
#
# Claude のセッション内容は取得できないため、git 由来の情報のみ。
# 手動 /obsidian-log の補完（忘れたとき用のフォールバック）。
# 未コミット変更がなければスキップする。

$ErrorActionPreference = 'Stop'

# stdin を消費して閉じる（フックが JSON を渡すが本スクリプトでは不要）
try { $null = [Console]::In.ReadToEnd() } catch {}

$Vault = Join-Path $HOME 'ObsidianVault'

# Vault が存在しなければ何もしない（静かに終了）
if (-not (Test-Path $Vault)) { exit 0 }

# git リポジトリ外なら何もしない
# 注: 2>$null だけだと PS が native command stderr を NativeCommandError として拾い、
# 冒頭の $ErrorActionPreference = 'Stop' と合わさって throw されるため、
# 2>&1 で success stream にマージしつつ try/catch で二重防御する。
try {
    $null = git rev-parse --is-inside-work-tree 2>&1
    if ($LASTEXITCODE -ne 0) { exit 0 }
} catch {
    exit 0
}

# 未コミット変更がなければスキップ
$Status = (git status --short 2>$null) -join "`n"
if ([string]::IsNullOrEmpty($Status)) { exit 0 }

# 情報収集
$RepoRoot = git rev-parse --show-toplevel
$Project = Split-Path $RepoRoot -Leaf
$Branch = git branch --show-current 2>$null
if ([string]::IsNullOrEmpty($Branch)) { $Branch = 'detached' }
$Timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$Date = Get-Date -Format 'yyyy-MM-dd'
$DiffStat = (git diff --stat 2>$null) -join "`n"
$DiffStaged = (git diff --cached --stat 2>$null) -join "`n"

# 変更ファイル一覧
$StatusLines = $Status -split "`n" | Where-Object { $_ -ne '' }
$FilesChanged = $StatusLines.Count

# テーブル行を組み立て
$FileTable = ''
foreach ($line in $StatusLines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '') { continue }
    $parts = $trimmed -split '\s+', 2
    $Op = $parts[0]
    $File = $parts[1]
    $FileTable += "| $Op | ``$File`` |`n"
}

# 直近コミット
$Commits = ''
$CommitLines = git log --oneline -5 2>$null
if ($CommitLines) {
    foreach ($line in $CommitLines) {
        if ($line -ne '') { $Commits += "- ``$line```n" }
    }
}

# 書き出し先
$LogDir = Join-Path (Join-Path (Join-Path $Vault '_claude') 'log') $Timestamp.Substring(0, 6)
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "${Timestamp}_auto-git-diff.md"

# DiffStat セクション
$DiffStatSection = ''
if (-not [string]::IsNullOrWhiteSpace($DiffStat)) {
    $DiffStatSection = @"
### diff --stat

``````
$($DiffStat.TrimEnd())
``````

"@
}

# DiffStaged セクション
$DiffStagedSection = ''
if (-not [string]::IsNullOrWhiteSpace($DiffStaged)) {
    $DiffStagedSection = @"
### diff --cached --stat

``````
$($DiffStaged.TrimEnd())
``````

"@
}

$Content = @"
---
tags:
  - claude-log
  - auto
date: $Date
project: $Project
files_changed: $FilesChanged
---

## 概要

PreCompact 自動記録（git diff ベース）。セッション中の未コミット変更を記録。

## 変更サマリ

**プロジェクト**: $Project
**ブランチ**: ``$Branch``

### 未コミットの変更

``````
$Status
``````

${DiffStatSection}${DiffStagedSection}### 直近のコミット

$Commits## 変更ファイル一覧

| 操作 | ファイル |
|------|----------|
$FileTable
"@

Set-Content -Path $LogFile -Value $Content -Encoding UTF8

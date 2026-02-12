#!/usr/bin/env pwsh
# obsidian-log-hook.ps1 - PreCompact フックから git diff ベースの簡易ログを記録する
#
# Claude のセッション内容は取得できないため、git 由来の情報のみ。
# 手動 /obsidian-log の補完（忘れたとき用のフォールバック）。
# 未コミット変更がなければスキップする。

$ErrorActionPreference = 'Stop'

# stdin を消費して閉じる（フックが JSON を渡すが本スクリプトでは不要）
try { $null = [Console]::In.ReadToEnd() } catch {}

$ConfigFile = Join-Path $HOME '.claude' 'config.json'

# config.json から obsidian_vault を読み取る
if (-not (Test-Path $ConfigFile)) { exit 0 }

$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
$Vault = $Config.obsidian_vault
if ([string]::IsNullOrEmpty($Vault)) { exit 0 }

# git リポジトリ外なら何もしない
$null = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) { exit 0 }

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
$LogDir = Join-Path $Vault '_claude' 'log'
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

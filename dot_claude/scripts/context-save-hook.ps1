#!/usr/bin/env pwsh
# context-save-hook.ps1 - SessionEnd フックから直接 git 状態を保存する
#
# Claude を介さずスクリプトで実行するため、/clear やセッション終了時にも
# 確実に動作する。セッション知識（判断メモ・次のステップ等）は保存できないため、
# git 由来の機械的な情報（ブランチ・コミット・未コミット変更）のみ更新する。

$ErrorActionPreference = 'Stop'

# stdin を消費して閉じる（フックが JSON を渡すが本スクリプトでは不要）
try { $null = [Console]::In.ReadToEnd() } catch {}

$ContextDir = Join-Path $HOME '.claude' 'context'

# git リポジトリ外なら何もしない
$null = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) { exit 0 }

# 情報収集
$RepoRoot = git rev-parse --show-toplevel
$ProjectId = Split-Path $RepoRoot -Leaf
$Branch = git branch --show-current 2>$null
if ([string]::IsNullOrEmpty($Branch)) { $Branch = 'detached' }
$Remote = git remote get-url origin 2>$null
if ($null -eq $Remote) { $Remote = '' }
$Status = (git status --short 2>$null) -join "`n"
$Updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

# コミットログ整形
$Commits = ''
$CommitLines = git log --oneline -5 2>$null
if ($CommitLines) {
    foreach ($line in $CommitLines) {
        if ($line -ne '') { $Commits += "  - ``$line```n" }
    }
}

# 未コミット変更
if ([string]::IsNullOrEmpty($Status)) {
    $Uncommitted = 'なし'
    $StatusSection = ''
} else {
    $Uncommitted = 'あり'
    $StatusSection = ''
    foreach ($line in ($Status -split "`n")) {
        if ($line -ne '') { $StatusSection += "  - ``$line```n" }
    }
}

# 「現在の状態」セクションを生成
$StateSection = @"
## 現在の状態

- **ブランチ**: ``$Branch``
- **直近のコミット**:
$Commits- **未コミットの変更**: $Uncommitted
"@
if ($StatusSection -ne '') { $StateSection += "`n$StatusSection" }

if (-not (Test-Path $ContextDir)) { New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null }
$ContextFile = Join-Path $ContextDir "$ProjectId.md"

# --- 既存ファイルの更新 ---
if (Test-Path $ContextFile) {
    $Lines = Get-Content $ContextFile -Encoding UTF8
    $Content = $Lines -join "`n"

    # 「## 現在の状態」セクションの行番号を探す（0-indexed）
    $StateLine = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^## 現在の状態') {
            $StateLine = $i
            break
        }
    }

    if ($StateLine -ge 0) {
        # 次の ## 見出しを探す
        $NextSection = -1
        for ($i = $StateLine + 1; $i -lt $Lines.Count; $i++) {
            if ($Lines[$i] -match '^## ') {
                $NextSection = $i
                break
            }
        }

        # Part 1: 現在の状態の前まで（frontmatter の branch/updated を更新）
        $Before = ($Lines[0..($StateLine - 1)] -join "`n")
        $Before = $Before -replace '(?m)^branch: .+$', "branch: $Branch"
        $Before = $Before -replace '(?m)^updated: .+$', "updated: $Updated"

        # Part 2: 新しい「現在の状態」セクション
        $NewContent = $Before + "`n" + $StateSection + "`n"

        # Part 3: 残りのセクション
        if ($NextSection -ge 0) {
            $NewContent += "`n" + ($Lines[$NextSection..($Lines.Count - 1)] -join "`n")
        }
    } else {
        # 「現在の状態」セクションがない → frontmatter だけ更新
        $NewContent = $Content
        $NewContent = $NewContent -replace '(?m)^branch: .+$', "branch: $Branch"
        $NewContent = $NewContent -replace '(?m)^updated: .+$', "updated: $Updated"
    }

    Set-Content -Path $ContextFile -Value $NewContent -Encoding UTF8

# --- 新規作成 ---
} else {
    $NewContent = @"
---
project: $ProjectId
git_remote: $Remote
branch: $Branch
updated: $Updated
tags:
  - claude-context
---

## プロジェクト概要

（自動保存により作成。次回 /context-save で詳細を記録してください）

$StateSection

## 次のステップ

- [ ] （未記入）
"@
    Set-Content -Path $ContextFile -Value $NewContent -Encoding UTF8
}

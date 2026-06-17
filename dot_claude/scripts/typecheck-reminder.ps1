# typecheck-reminder.ps1 - UserPromptSubmit hook（Windows 版）
#
# 現プロジェクト（cwd）に typecheck-gate が記録した型エラーがあれば
# <system-reminder> として Claude に通知する。無ければ無音 exit 0。
# Windows 実機検証済み（2026-06-17、run-hook.js 経由で system-reminder を stdout に出力・PASS 後は無音を確認）。

$ErrorActionPreference = 'SilentlyContinue'

$proj = (Get-Location).Path
$stateDir = Join-Path $env:USERPROFILE '.claude\state\typecheck-gate'
$md5 = [System.Security.Cryptography.MD5]::Create()
$hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($proj))
$key = ([System.BitConverter]::ToString($hashBytes)) -replace '-', ''
$errFile = Join-Path $stateDir ("$key.errors")

if (-not (Test-Path -LiteralPath $errFile)) { exit 0 }
$errors = Get-Content -LiteralPath $errFile -Raw
if ([string]::IsNullOrWhiteSpace($errors)) { exit 0 }

$msg = @"
<system-reminder>
直近の Stop 後に走らせた ``npm run typecheck`` が型エラーで失敗しています（typecheck-gate による自動検出）。キリの良いところで修正を検討してください。エラーが解消すれば次回 Stop 時にこの通知は自動で消えます。

--- typecheck 出力（1 行目=プロジェクトパス / 以降=末尾 25 行）---
$errors
---
無効化したい場合: ~/.claude/state/typecheck-gate/ の該当 .errors を削除、または settings.json の Stop hook を外す。
</system-reminder>
"@
Write-Output $msg
exit 0

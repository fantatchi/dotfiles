# claude-md-audit-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# 最後の「監査実施」から N 日以上経過していたら <system-reminder> を stdout
# 出力し、Claude にユーザーへ CLAUDE.md 監査スキルの実行を提案させる。
# 閾値未満なら無音 exit 0。
#
# state を 2 ファイルに分離する（2026-07-07 改訂、詳細は .sh 版コメント参照）:
#   last-audit.txt    = 監査実施時刻（監査完了時にスキル側/モデルが更新する）
#   last-reminder.txt = 最終発火時刻（スヌーズ用、24h）

$ErrorActionPreference = 'SilentlyContinue'
# PS 5.1 が stderr に吐く CLIXML progress record を抑止（hook stderr 汚染対策）
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$thresholdDays = 7
if ($env:CLAUDE_MD_AUDIT_THRESHOLD_DAYS) {
    $parsed = 0
    if ([int]::TryParse($env:CLAUDE_MD_AUDIT_THRESHOLD_DAYS, [ref]$parsed) -and $parsed -gt 0) {
        $thresholdDays = $parsed
    }
}
$snoozeMin = 1440

$stateDir = Join-Path $env:USERPROFILE '.claude\state\claude-md-audit'
$auditFile = Join-Path $stateDir 'last-audit.txt'
$snoozeFile = Join-Path $stateDir 'last-reminder.txt'

if (-not (Test-Path $stateDir)) {
    try { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null } catch { exit 0 }
}

function Read-Epoch($path) {
    if (-not (Test-Path $path)) { return 0 }
    try {
        $raw = (Get-Content $path -TotalCount 1 -ErrorAction Stop)
        if ($raw -match '(\d+)') { return [int]$matches[1] }
    } catch {}
    return 0
}

$nowEpoch = [int][double]::Parse((Get-Date -UFormat %s))
$lastAudit = Read-Epoch $auditFile

# 移行措置: last-audit.txt が無ければ旧 state（発火時刻）を最終実施時刻とみなして引き継ぐ
if ($lastAudit -le 0) {
    $lastAudit = Read-Epoch $snoozeFile
    if ($lastAudit -gt 0) {
        try { Set-Content -Path $auditFile -Value $lastAudit -Encoding ASCII -NoNewline } catch {}
    }
}

# 初回（state 一切無し）: 基準点を今に置いて無音 exit。
if ($lastAudit -le 0) {
    try { Set-Content -Path $auditFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
    exit 0
}

$elapsedDays = [int](($nowEpoch - $lastAudit) / 86400)
if ($elapsedDays -lt $thresholdDays) { exit 0 }

# スヌーズ: 直近の発火から snoozeMin 未満なら無音
$lastFired = Read-Epoch $snoozeFile
if ($lastFired -gt 0 -and (($nowEpoch - $lastFired) / 60) -lt $snoozeMin) { exit 0 }

Write-Output @"
<system-reminder>
CLAUDE.md の最終監査から $elapsedDays 日経過しています（閾値: $thresholdDays 日）。

このセッションのキリの良いタイミングで、以下のいずれかの audit 実行をユーザーに提案してください:

1. グローバル (~/.claude/CLAUDE.md)
   - 起動方法: ``cd ~/.local/share/chezmoi/dot_claude && /claude-md-management:claude-md-improver``
   - 編集対象は chezmoi source。完了後ユーザーが ``chezmoi apply`` で target 同期 + 任意で commit

2. 現在プロジェクト (./CLAUDE.md)
   - 起動方法: そのまま ``/claude-md-management:claude-md-improver``

ユーザーが「やる」と言うまで待つ。すぐ作業に入りたい場合は無視して通常応答へ
（実施するまで 24h ごとに再通知されます）。
**監査を実施したら必ず** ``date +%s > ~/.claude/state/claude-md-audit/last-audit.txt`` (WSL/bash) または PowerShell で ``[int][double]::Parse((Get-Date -UFormat %s)) | Set-Content ~\.claude\state\claude-md-audit\last-audit.txt`` を実行して実施を記録してください。
頻度調整: ``export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14`` などで延長可。
</system-reminder>
"@

try { Set-Content -Path $snoozeFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
exit 0

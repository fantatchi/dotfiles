# claude-md-audit-reminder.ps1 - SessionStart hook (Windows)
#
# 最後のリマインダー発火から N 日以上経過していたら <system-reminder> を stdout
# 出力し、Claude にユーザーへ CLAUDE.md 監査スキルの実行を提案させる。
# 閾値未満なら無音 exit 0。
#
# state file: ~\.claude\state\claude-md-audit\last-reminder.txt（epoch seconds）
# 閾値: 環境変数 CLAUDE_MD_AUDIT_THRESHOLD_DAYS で上書き可（既定 7）

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

$stateDir = Join-Path $env:USERPROFILE '.claude\state\claude-md-audit'
$stateFile = Join-Path $stateDir 'last-reminder.txt'

if (-not (Test-Path $stateDir)) {
    try { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null } catch { exit 0 }
}

$nowEpoch = [int][double]::Parse((Get-Date -UFormat %s))
$lastEpoch = 0

if (Test-Path $stateFile) {
    try {
        $raw = (Get-Content $stateFile -TotalCount 1 -ErrorAction Stop)
        if ($raw -match '(\d+)') { $lastEpoch = [int]$matches[1] }
    } catch {}
}

# 初回（state file 無し or 空）: 基準点を今に置いて無音 exit。
if ($lastEpoch -le 0) {
    try { Set-Content -Path $stateFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
    exit 0
}

$elapsedDays = [int](($nowEpoch - $lastEpoch) / 86400)
if ($elapsedDays -lt $thresholdDays) { exit 0 }

Write-Output @"
<system-reminder>
CLAUDE.md の最終監査リマインダーから $elapsedDays 日経過しています（閾値: $thresholdDays 日）。

このセッションのキリの良いタイミングで、以下のいずれかの audit 実行をユーザーに提案してください:

1. グローバル (~/.claude/CLAUDE.md)
   - 起動方法: ``cd ~/.local/share/chezmoi/dot_claude && /claude-md-management:claude-md-improver``
   - 編集対象は chezmoi source。完了後ユーザーが ``chezmoi apply`` で target 同期 + 任意で commit

2. 現在プロジェクト (./CLAUDE.md)
   - 起動方法: そのまま ``/claude-md-management:claude-md-improver``

ユーザーが「やる」と言うまで待つ。すぐ作業に入りたい場合は無視して通常応答へ。
頻度調整: ``export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14`` などで延長可。
</system-reminder>
"@

try { Set-Content -Path $stateFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
exit 0

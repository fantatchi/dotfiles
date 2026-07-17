# claude-md-audit-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# 最後の「監査実施」から N 日以上経過していたら <system-reminder> を stdout
# 出力し、Claude にユーザーへ CLAUDE.md 監査スキルの実行を提案させる。
# 閾値未満なら無音 exit 0。
#
# state を 2 ファイルに分離する（2026-07-07 改訂、詳細は .sh 版コメント参照）:
#   last-audit.txt    = 監査実施時刻（監査完了時にスキル側/モデルが更新する）
#   last-reminder.txt = 最終発火時刻（スヌーズ用、24h）
#
# 監査実施時刻は Vault 側を正とする（2026-07-17 改訂、設計根拠は .sh 版コメント参照）:
# CLAUDE.md は全 PC 共通の 1 つの成果物なので「いつ監査したか」はグローバルな事実。ローカル
# state だと 1 台で監査しても他 PC が知り得ず誤発火する。last-audit のみ Obsidian Sync 経路へ。
# Vault 不在 / 未同期 / 欠損 / parse 失敗 → ローカルへフォールバック（従来挙動＝安全側）。

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

# Vault パスは ~/.claude/skills/shared/integrations.md の vault / task_store_probe を SSOT として
# ミラー。Vault を移動したら .sh / .ps1 / run-hook.js の 3 箇所を grep で同時更新すること。
$vaultProbe = Join-Path $env:USERPROFILE 'ObsidianVault\.obsidian'
$sharedState = Join-Path $env:USERPROFILE 'ObsidianVault\00_meta\claude-state.md'

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

# claude-state.md の frontmatter から `last_audit: <epoch>` のみを読む。
# `last_audit_at:`（ISO 併記・人間用）はキー名がコロンで区切られるため ^last_audit: に
# マッチせず、取り違えない。
function Read-SharedAuditEpoch($probe, $path) {
    if (-not (Test-Path $probe)) { return 0 }
    if (-not (Test-Path $path)) { return 0 }
    try {
        foreach ($line in (Get-Content $path -TotalCount 20 -ErrorAction Stop)) {
            if ($line -match '^last_audit:\s*(\d+)') { return [int]$matches[1] }
        }
    } catch {}
    return 0
}

$nowEpoch = [int][double]::Parse((Get-Date -UFormat %s))

# 監査実施時刻の解決: Vault（全 PC 共通の正）→ ローカル（フォールバック）の順
$lastAudit = Read-SharedAuditEpoch $vaultProbe $sharedState

if ($lastAudit -le 0) {
    # --- 以下フォールバック経路: Vault 不在 / 未同期 / 欠損 / parse 失敗（＝従来挙動そのまま） ---
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

**監査を実施したら必ず** ``$env:USERPROFILE\ObsidianVault\00_meta\claude-state.md`` の frontmatter を更新してください
（全 PC 共通の記録。1 台で監査すれば他の PC でも黙る）:
- ``last_audit:`` を ``[int][double]::Parse((Get-Date -UFormat %s))`` の値へ（機械可読の正）
- ``last_audit_at:`` を ``Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'`` の値へ（人間が読むための併記）
Vault が無い環境では ``[int][double]::Parse((Get-Date -UFormat %s)) | Set-Content ~\.claude\state\claude-md-audit\last-audit.txt``（このマシンのみ有効）。
頻度調整: ``export CLAUDE_MD_AUDIT_THRESHOLD_DAYS=14`` などで延長可。
</system-reminder>
"@

try { Set-Content -Path $snoozeFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
exit 0

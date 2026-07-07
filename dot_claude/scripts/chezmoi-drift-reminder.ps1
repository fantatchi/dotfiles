# chezmoi-drift-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# `chezmoi status` が非空（= source と target のドリフト）なら <system-reminder> を
# stdout 出力し、Claude に突合（re-add / apply）の提案を促す。差分なしなら無音 exit 0。
# デバウンス: state に「最終通知 epoch + status 出力ハッシュ」、ハッシュ変化 or 24h で再通知。
# 除外: .chezmoiscripts/（run script の再実行 state はドリフトでない）

$ErrorActionPreference = 'SilentlyContinue'
# PS 5.1 が stderr に吐く CLIXML progress record を抑止（hook stderr 汚染対策）
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$renotifyMin = 1440

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) { exit 0 }

$statusLines = @()
try { $statusLines = @(chezmoi status 2>&1 | Where-Object { $_ -is [string] -or $_ -is [System.Management.Automation.PSObject] }) } catch { exit 0 }
if ($LASTEXITCODE -ne 0) { exit 0 }

$drift = @($statusLines | ForEach-Object { "$_" } | Where-Object { $_.Trim() -ne '' -and $_ -notmatch ' \.chezmoiscripts/' })

$stateDir = Join-Path $env:USERPROFILE '.claude\state\chezmoi-drift'
$stateFile = Join-Path $stateDir 'last-notified.txt'

if ($drift.Count -eq 0) {
    try { Remove-Item $stateFile -Force -ErrorAction SilentlyContinue } catch {}
    exit 0
}

if (-not (Test-Path $stateDir)) {
    try { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null } catch { exit 0 }
}

$driftText = $drift -join "`n"
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($driftText))).Replace('-', '').ToLower()

$nowEpoch = [int][double]::Parse((Get-Date -UFormat %s))
$lastEpoch = 0
$lastHash = ''
if (Test-Path $stateFile) {
    try {
        $stateRaw = @(Get-Content $stateFile -TotalCount 2 -ErrorAction Stop)
        if ($stateRaw.Count -ge 1 -and $stateRaw[0] -match '(\d+)') { $lastEpoch = [int]$matches[1] }
        if ($stateRaw.Count -ge 2) { $lastHash = $stateRaw[1].Trim() }
    } catch {}
}

if ($hash -eq $lastHash -and (($nowEpoch - $lastEpoch) / 60) -lt $renotifyMin) { exit 0 }

$driftHead = ($drift | Select-Object -First 15) -join "`n"
$driftCount = $drift.Count

Write-Output @"
<system-reminder>
chezmoi のドリフト（source と target の差分）が $driftCount 件あります:

$driftHead

キリの良いタイミングでユーザーに突合を提案してください（コード:
MM = 両側変更の要マージ / DA = target 欠損 / M = apply 待ち / A = re-add or apply 待ち）。
live 編集が正なら ``chezmoi re-add <path>``、source が正なら ``chezmoi diff <path>`` で
確認のうえ ``chezmoi apply <path>``。MM は両方の diff を見てからマージする。
無関係な作業中なら無視して通常応答へ。
</system-reminder>
"@

try { Set-Content -Path $stateFile -Value "$nowEpoch`n$hash" -Encoding ASCII -NoNewline } catch {}
exit 0

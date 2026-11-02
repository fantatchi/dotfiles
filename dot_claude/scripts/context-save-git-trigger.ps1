# context-save-git-trigger.ps1 - PostToolUse hook (Windows, matcher: Bash, if: git commit / gh pr create)
#
# コミット・PR 作成の直後に /context-save を促す。仕様・意図は context-save-git-trigger.sh の
# ヘッダを参照（.sh が SSOT）。定数を変えたら .sh と同時に更新すること。

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$commitFreshSec = 120
$debounceMin = 15

$command = ''
try {
    $reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding($false)))
    $stdinText = $reader.ReadToEnd()
    if ($stdinText) {
        $json = $stdinText | ConvertFrom-Json -ErrorAction Stop
        if ($json.tool_input -and $json.tool_input.command) { $command = [string]$json.tool_input.command }
    }
} catch {}

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { exit 0 }
$contextFile = Join-Path $repoRoot '.claude/context.md'
if (-not (Test-Path -LiteralPath $contextFile)) { exit 0 }

$nowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

if ($command -like '*gh pr create*') {
    $eventLabel = 'PR 作成'
} else {
    $eventLabel = 'コミット'
    $headEpoch = (& git log -1 --format=%ct 2>$null)
    if (-not $headEpoch) { exit 0 }
    if (($nowEpoch - [int64]$headEpoch) -gt $commitFreshSec) { exit 0 }
}

$content = Get-Content -LiteralPath $contextFile -Raw -Encoding UTF8
if ($content -match '(?ms)^---\r?\n(.*?)\r?\n---' -and $matches[1] -match '(?m)^updated:\s*(.+?)\s*$') {
    try {
        $updated = [DateTime]::Parse($matches[1])
        if (((Get-Date) - $updated).TotalMinutes -lt $debounceMin) { exit 0 }
    } catch {}
}

Write-Output ('{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"' + $eventLabel + 'が完了し、作業の区切りです。ユーザーへの報告の前に /context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。"}}')
exit 0

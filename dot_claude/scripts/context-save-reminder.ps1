# context-save-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# .claude/context.md の frontmatter `updated:` と、セッション初回プロンプト時刻の
# どちらか新しい方を基準として、閾値以上経過していたら stdout に system-reminder
# ブロックを出力し、Claude に /context-save の実行を促す。閾値未満なら無音 exit 0。
#
# セッション開始基準: 各 session_id ごとに `~\.claude\.session-markers\<session_id>`
# を作成し、その LastWriteTime を「このセッションの初回プロンプト時刻」として扱う。

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$thresholdMin = 120
$markerDir = Join-Path $env:USERPROFILE '.claude\.session-markers'
$markerTtlDays = 7

# stdin から JSON を読んで session_id を抽出
$sessionId = $null
try {
    $stdinText = [Console]::In.ReadToEnd()
    if ($stdinText) {
        $json = $stdinText | ConvertFrom-Json -ErrorAction Stop
        if ($json.PSObject.Properties.Match('session_id').Count -gt 0) {
            $sessionId = [string]$json.session_id
        }
    }
} catch {
    $sessionId = $null
}

# マーカーディレクトリ作成 & 古いマーカー掃除（best-effort）
if (-not (Test-Path $markerDir)) {
    try { New-Item -ItemType Directory -Path $markerDir -Force | Out-Null } catch {}
}
try {
    $cutoff = (Get-Date).AddDays(-$markerTtlDays)
    Get-ChildItem -Path $markerDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}

$sessionStart = $null
if ($sessionId) {
    # session_id を安全な文字に制限
    $safeId = ($sessionId -replace '[^A-Za-z0-9._-]', '_')
    if ($safeId.Length -gt 128) { $safeId = $safeId.Substring(0, 128) }
    $markerFile = Join-Path $markerDir $safeId

    if (-not (Test-Path $markerFile)) {
        # このセッションの初回プロンプト。マーカーを作って何も出さずに終了。
        try { New-Item -ItemType File -Path $markerFile -Force | Out-Null } catch {}
        exit 0
    }

    try {
        $sessionStart = (Get-Item $markerFile).LastWriteTime
    } catch {
        $sessionStart = $null
    }
}

# git リポジトリ外なら exit 0
$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { exit 0 }

$contextFile = Join-Path $repoRoot '.claude/context.md'
if (-not (Test-Path $contextFile)) { exit 0 }

# frontmatter から updated を抽出
$content = Get-Content $contextFile -Raw -Encoding UTF8
if ($content -notmatch '(?ms)^---\r?\n(.*?)\r?\n---') { exit 0 }
$frontmatter = $matches[1]
if ($frontmatter -notmatch '(?m)^updated:\s*(.+?)\s*$') { exit 0 }
$updatedStr = $matches[1]

try {
    $updated = [DateTime]::Parse($updatedStr)
} catch {
    exit 0
}

# 基準は max(updated, session_start)
$baseline = $updated
if ($sessionStart -and $sessionStart -gt $baseline) {
    $baseline = $sessionStart
}

$diffMin = [int]((Get-Date) - $baseline).TotalMinutes
if ($diffMin -ge $thresholdMin) {
    Write-Output @"
<system-reminder>
最後の context 保存またはセッション開始から $diffMin 分経過しています（閾値: $thresholdMin 分）。
このターンの応答に入る前に /context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。
保存が終わったら、続けてユーザーの本来のリクエストに応答してください。
</system-reminder>
"@
}
exit 0

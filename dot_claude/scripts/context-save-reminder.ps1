# context-save-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# .claude/context.md の frontmatter `updated:`（= 最終 save）と、セッション開始 / 最終
# /context-load 時刻のどちらか新しい方を基準として、閾値以上経過していたら stdout に system-reminder
# ブロックを出力し、Claude に /context-save の実行を促す。閾値未満なら無音 exit 0。
#
# セッション開始基準: 各 session_id ごとに `~\.claude\.session-markers\<session_id>`
# を作成する。マーカーには:
#   - 内容（1 行目）  : そのセッション開始 epoch（fresh で作成 / resume 検出時に更新）
#   - LastWriteTime : 最終プロンプト時刻（毎回更新）
# を保持し、前回プロンプトからの gap が長い場合は resume とみなしてセッション開始を
# リセットする。これにより `claude --continue` / IDE Resume で session_id が再利用
# されても古い「初回プロンプト時刻」を基準にせず済む。
# プロンプトが /context-load のときもセッション開始 epoch を NOW に書き直して無音 exit する
# （load 直後に save を促さない）。
#
# 注意（PS 5.1 の罠、2026-10-08 に実機で確認）:
#   - stdin は既定で OEM コードページ（cp932）で読まれ、日本語を含むプロンプトの JSON が
#     化けて parse に失敗する → session_id が空になり updated だけで判定して起動直後に誤発火
#     していた。stdin は UTF-8 の StreamReader で読む
#   - `Get-Date -UFormat %s` はローカル時刻を UTC 扱いした epoch（JST で +9h）を返す。
#     epoch は [DateTimeOffset] で扱う

$ErrorActionPreference = 'SilentlyContinue'
# PS 5.1 が stderr に吐く CLIXML progress record を抑止（hook stderr 汚染対策）
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$thresholdMin = 240
$resumeDetectMin = 60   # 前回プロンプトからこの分数以上空いていたら resume とみなす
$markerDir = Join-Path $env:USERPROFILE '.claude\.session-markers'
$markerTtlDays = 7

# stdin から JSON を読んで session_id / prompt を抽出（UTF-8 で読む。理由はヘッダ参照）
$sessionId = $null
$prompt = ''
try {
    $reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding($false)))
    $stdinText = $reader.ReadToEnd()
    if ($stdinText) {
        $json = $stdinText | ConvertFrom-Json -ErrorAction Stop
        if ($json.PSObject.Properties.Match('session_id').Count -gt 0) {
            $sessionId = [string]$json.session_id
        }
        if ($json.PSObject.Properties.Match('prompt').Count -gt 0) {
            $prompt = [string]$json.prompt
        }
    }
} catch {
    $sessionId = $null
}
$isContextLoad = $prompt -match '^\s*/context-load\b|<command-name>/context-load</command-name>'

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

    $nowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    if (-not (Test-Path $markerFile)) {
        # このセッションの初回プロンプト。マーカーを作って何も出さずに終了。
        # 1 行目にセッション開始 epoch を書き、LastWriteTime は作成で NOW になる。
        try { Set-Content -Path $markerFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
        exit 0
    }

    # LastWriteTime = 最終プロンプト時刻、内容 1 行目 = セッション開始 epoch
    $lastPrompt = $null
    try { $lastPrompt = (Get-Item $markerFile).LastWriteTime } catch {}

    $sessionStartEpoch = $null
    try {
        $firstLine = (Get-Content $markerFile -TotalCount 1 -ErrorAction Stop)
        if ($firstLine -match '^\s*(\d+)\s*$') { $sessionStartEpoch = [int]$matches[1] }
    } catch {}

    # 旧フォーマット（空ファイル）からの移行: 内容が無ければ mtime を採用
    if (-not $sessionStartEpoch -and $lastPrompt) {
        $sessionStartEpoch = ([DateTimeOffset]$lastPrompt.ToUniversalTime()).ToUnixTimeSeconds()
    }
    # 旧実装（-UFormat %s）が書いた未来の epoch は NOW に丸める
    if ($sessionStartEpoch -and $sessionStartEpoch -gt $nowEpoch) {
        $sessionStartEpoch = $nowEpoch
        try { Set-Content -Path $markerFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
    }
    if ($sessionStartEpoch) {
        $sessionStart = [DateTimeOffset]::FromUnixTimeSeconds($sessionStartEpoch).LocalDateTime
    }

    # 前回プロンプトから resumeDetectMin 以上空いていたら resume とみなし、
    # セッション開始 epoch を NOW に書き直して silent exit。
    if ($lastPrompt) {
        $idleMin = ((Get-Date) - $lastPrompt).TotalMinutes
        if ($idleMin -ge $resumeDetectMin) {
            try { Set-Content -Path $markerFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
            exit 0
        }
    }

    # /context-load: load 直後なので基準を NOW に書き直して silent exit。
    if ($isContextLoad) {
        try { Set-Content -Path $markerFile -Value $nowEpoch -Encoding ASCII -NoNewline } catch {}
        exit 0
    }

    # アクティブなセッションの継続: LastWriteTime を更新して最終プロンプト時刻を記録。
    # セッション開始 epoch（内容）は触らない。
    try { (Get-Item $markerFile).LastWriteTime = Get-Date } catch {}
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

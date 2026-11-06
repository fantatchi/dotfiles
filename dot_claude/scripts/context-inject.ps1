# context-inject.ps1 - SessionStart hook (Windows, matcher: startup|compact)
#
# 起動時と compact 直後に、「保存後の git 変化」と .claude/context.md / tasks.md の要点を
# plain stdout で出力する。仕様・意図は context-inject.sh のヘッダを参照（.sh が SSOT）。
# stdin を UTF-8 で読む理由は context-save-reminder.ps1 のヘッダ参照（PS 5.1 の cp932 罠）。

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$maxChars = 6000

$source = ''
try {
    $reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding($false)))
    $stdinText = $reader.ReadToEnd()
    if ($stdinText) {
        $json = $stdinText | ConvertFrom-Json -ErrorAction Stop
        if ($json.PSObject.Properties.Match('source').Count -gt 0) { $source = [string]$json.source }
    }
} catch {}

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { exit 0 }
$contextFile = Join-Path $repoRoot '.claude/context.md'
$tasksFile = Join-Path $repoRoot '.claude/tasks.md'
if (-not (Test-Path -LiteralPath $contextFile)) { exit 0 }

# `## <name>` 見出しから次の `## ` 見出しの直前までを返す（見出し行は含めない）
function Get-Section([string]$file, [string]$name) {
    $lines = Get-Content -LiteralPath $file -Encoding UTF8
    $on = $false
    $buf = New-Object System.Collections.Generic.List[string]
    foreach ($l in $lines) {
        if ($l -match '^## ') {
            if ($on) { break }
            if ($l -eq "## $name") { $on = $true; continue }
        }
        if ($on) { $buf.Add($l) }
    }
    return ($buf -join "`n").Trim("`r", "`n", ' ')
}

$content = Get-Content -LiteralPath $contextFile -Raw -Encoding UTF8
$updatedStr = ''
if ($content -match '(?ms)^---\r?\n(.*?)\r?\n---' -and $matches[1] -match '(?m)^updated:\s*(.+?)\s*$') {
    $updatedStr = $matches[1]
}
$shownUpdated = if ($updatedStr) { $updatedStr } else { '不明' }

$sb = New-Object System.Text.StringBuilder
if ($source -eq 'compact') {
    [void]$sb.AppendLine("## compact 後の再注入（.claude/context.md 最終保存: $shownUpdated）")
    [void]$sb.AppendLine('compact の要約で落ちた作業状態を補うため、保存済みの要点を再掲する。保存後の作業は要約側が正。')
} else {
    [void]$sb.AppendLine("## 前回の作業状態（.claude/context.md 最終保存: $shownUpdated）")
    [void]$sb.AppendLine('SessionStart hook による自動注入。PR の実査・progress.md・handoff.md まで見るなら context-load スキル。')
}

[void]$sb.AppendLine("`n### 保存後の git 変化")
if ($updatedStr) {
    try {
        $updatedEpoch = ([DateTimeOffset][DateTime]::Parse($updatedStr)).ToUnixTimeSeconds()
        $commits = @(& git -c core.quotepath=false log --since="@$updatedEpoch" --oneline 2>$null)
        if ($commits.Count -gt 0) {
            [void]$sb.AppendLine("- 保存後のコミット: $($commits.Count) 件")
            foreach ($c in ($commits | Select-Object -First 5)) { [void]$sb.AppendLine("  - $c") }
        } else {
            [void]$sb.AppendLine('- 保存後のコミット: なし')
        }
    } catch {}
}
if (& git -C $repoRoot status --porcelain -- . ':!.claude/context.md' ':!.claude/tasks.md' ':!.claude/handoff.md' ':!.claude/progress.md' 2>$null) {
    [void]$sb.AppendLine('- 未コミットの変更: あり')
} else {
    [void]$sb.AppendLine('- 未コミットの変更: なし')
}

if (Test-Path -LiteralPath $tasksFile) {
    $next = Get-Section $tasksFile 'Next'
    if ($next) { [void]$sb.AppendLine("`n### 次にやること（tasks.md の Next）`n$next") }
}
$wip = Get-Section $contextFile '進行中の作業'
if ($wip) { [void]$sb.AppendLine("`n### 進行中の作業`n$wip") }
$decisions = Get-Section $contextFile '判断メモ'
if ($decisions) { [void]$sb.AppendLine("`n### 判断メモ`n$decisions") }

$out = $sb.ToString().TrimEnd()
if ($out.Length -gt $maxChars) {
    $out = $out.Substring(0, $maxChars) + "`n…（$maxChars 字で打ち切り。全文は .claude/context.md / tasks.md を読む）"
}
Write-Output $out
exit 0

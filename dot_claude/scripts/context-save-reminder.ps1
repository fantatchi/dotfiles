# context-save-reminder.ps1 - UserPromptSubmit hook (Windows)
#
# .claude/context.md の frontmatter `updated:` を見て、閾値以上経過していたら
# stdout に system-reminder ブロックを出力し、Claude に /context-save の実行を促す。
# 閾値未満なら何も出力せず exit 0（無音）。

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$thresholdMin = 30

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

$diffMin = [int]((Get-Date) - $updated).TotalMinutes
if ($diffMin -ge $thresholdMin) {
    Write-Output @"
<system-reminder>
最後の context 保存から $diffMin 分経過しています（閾値: $thresholdMin 分）。
このターンの応答に入る前に /context-save スキルを実行して、判断メモ・次のステップを含めた最新状態を .claude/context.md に書き出してください。
保存が終わったら、続けてユーザーの本来のリクエストに応答してください。
</system-reminder>
"@
}
exit 0

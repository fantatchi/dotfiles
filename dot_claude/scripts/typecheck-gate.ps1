# typecheck-gate.ps1 - Stop hook（通知型 Feedback Loop / TS のみ）Windows 版
#
# 役割は typecheck-gate.sh と同じ。バックグラウンドで `npm run typecheck` を実行し
# 結果を ~/.claude/state/typecheck-gate/<ハッシュ>.errors に記録する。
# ※ Windows 実機での検証は未実施（正本の .sh は WSL で smoke test 済み）。

$ErrorActionPreference = 'SilentlyContinue'

$proj = (Get-Location).Path
if (-not (Test-Path -LiteralPath (Join-Path $proj 'package.json'))) { exit 0 }

# scripts.typecheck の有無を node で判定（forward slash に正規化して require）
$pkg = (Join-Path $proj 'package.json') -replace '\\', '/'
& node -e "const s=(require(process.argv[1]).scripts)||{};process.exit(s.typecheck?0:1)" $pkg
if ($LASTEXITCODE -ne 0) { exit 0 }

$stateDir = Join-Path $env:USERPROFILE '.claude\state\typecheck-gate'
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$md5 = [System.Security.Cryptography.MD5]::Create()
$hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($proj))
$key = ([System.BitConverter]::ToString($hashBytes)) -replace '-', ''
$errFile = Join-Path $stateDir ("$key.errors")
$lockDir = Join-Path $stateDir ("$key.lock")

# 古いロック（10 分以上）を掃除
if (Test-Path -LiteralPath $lockDir) {
    $age = (Get-Date) - (Get-Item -LiteralPath $lockDir).LastWriteTime
    if ($age.TotalMinutes -gt 10) { Remove-Item -LiteralPath $lockDir -Recurse -Force }
}
# 二重起動防止（ディレクトリ作成の成否でロック）
try { New-Item -ItemType Directory -Path $lockDir -ErrorAction Stop | Out-Null }
catch { exit 0 }

# バックグラウンドで typecheck を実行（Stop を待たせない）
$work = @"
Set-Location -LiteralPath '$proj'
`$lines = & npm run typecheck 2>&1
if (`$LASTEXITCODE -ne 0) {
    `$tail = (`$lines | Select-Object -Last 25 | ForEach-Object { `$_.ToString() }) -join [Environment]::NewLine
    Set-Content -LiteralPath '$errFile' -Value ('$proj' + [Environment]::NewLine + `$tail) -Encoding UTF8
} else {
    Remove-Item -LiteralPath '$errFile' -ErrorAction SilentlyContinue
}
Remove-Item -LiteralPath '$lockDir' -Recurse -Force -ErrorAction SilentlyContinue
"@
Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $work
exit 0

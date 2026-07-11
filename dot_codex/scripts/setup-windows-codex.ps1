# Windows 側 ~/.codex を WSL と共有する初回 setup スクリプト。
# 認証、セッション、設定、Plugin、cache は Windows ローカルに保持し、
# 人間が管理する静的ファイルだけを SymbolicLink で共有する。

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$Force
)

$includeForLink = @('AGENTS.md', 'skills')
$wslUser = (wsl.exe -d $Distro -e whoami 2>$null | Out-String).Trim()
if (-not $wslUser) {
    throw "WSL ($Distro) のユーザー名を取得できません。"
}

$wslCodexRoot = "\\wsl.localhost\$Distro\home\$wslUser\.codex"
$windowsCodexRoot = Join-Path $env:USERPROFILE '.codex'

if (-not (Test-Path -LiteralPath $wslCodexRoot)) {
    throw "WSL 側の .codex が見つかりません: $wslCodexRoot"
}

$windowsRootItem = Get-Item -LiteralPath $windowsCodexRoot -Force -ErrorAction SilentlyContinue
if ($windowsRootItem -and $windowsRootItem.LinkType -in @('SymbolicLink', 'Junction')) {
    throw "Windows 側 .codex は実ディレクトリである必要があります: $windowsCodexRoot"
}

if (-not $windowsRootItem -and $PSCmdlet.ShouldProcess($windowsCodexRoot, '実ディレクトリを作成')) {
    New-Item -ItemType Directory -Path $windowsCodexRoot -Force | Out-Null
}

foreach ($name in $includeForLink) {
    $source = Join-Path $wslCodexRoot $name
    $linkPath = Join-Path $windowsCodexRoot $name

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warning "共有元がないためスキップします: $source"
        continue
    }

    $existingItem = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
    if ($existingItem) {
        if ($existingItem.LinkType -eq 'SymbolicLink' -and $existingItem.Target -contains $source) {
            Write-Host "既存リンクを維持: $name"
            continue
        }
        if (-not $Force) {
            Write-Warning "既存項目を保護してスキップします: $linkPath"
            continue
        }
        throw "-Force でも既存項目は自動削除しません。退避後に再実行してください: $linkPath"
    }

    if ($PSCmdlet.ShouldProcess($linkPath, "SymbolicLink を作成: $source")) {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $source -ErrorAction Stop | Out-Null
    }
}

Write-Host 'Codex の Windows 共有セットアップが完了しました。'

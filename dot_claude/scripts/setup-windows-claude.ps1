# Windows 側 ~/.claude を WSL ハイブリッド構成にする初回 setup スクリプト
#
# Why: Claude Code plugin システムが known_marketplaces.json 等に Linux 絶対パスを
#      ハードコードする (2026-05-22 判明)。~/.claude 全体を WSL への SymLink にすると
#      Windows 側 Claude Code が plugin パスを解決できずエラー。対処として:
#        - ~/.claude を Windows 側で実ディレクトリ化
#        - chezmoi 管理 + ホームワークスペース系のみ個別 SymLink で WSL に向ける
#        - plugins/ 等 PC-local は Windows ネイティブ管理
#      ~/.claude/scripts/powershell-utf8-profile.ps1 に「欠けている SymLink を毎回起動時に
#      自動補完する」ロジックがあるため、新規 chezmoi 管理ファイル追加時の手動メンテは不要。
#
# 前提:
#   - Windows 10/11 で Developer Mode が有効 (Settings > Privacy & Security > For developers)
#   - WSL に at-kato/fantatchi 等のユーザーで Claude Code が動いている
#   - chezmoi 経由で ~/.claude/scripts/ が WSL 側に配布済み
#
# 使い方:
#   powershell -ExecutionPolicy Bypass -File '\\wsl.localhost\Ubuntu\home\<wsl-user>\.claude\scripts\setup-windows-claude.ps1'
#
#   オプション:
#     -Distro <name>  WSL distro 名を指定 (デフォルト: Ubuntu)
#     -WhatIf         実行内容を表示するだけ (実際の変更なし)
#     -Force          ~/.claude が既に実ディレクトリでも続行 (中身は保持)

[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$Force,
    [switch]$WhatIf
)

# 包含リスト: Windows 側で WSL への SymLink にする項目 (~/.claude 直下の名前のみ)
# それ以外は Windows ネイティブ管理 (plugins/ / cache/ / projects/ / .credentials.json 等)
$includeForLink = @(
    'CLAUDE.md',
    'settings.json',
    'settings.local.json',
    'context.md',
    'agents',
    'docs',
    'scripts',
    'skills'
)

Write-Host "=== setup-windows-claude.ps1 ==="

# 1. WSL username を検出 (whoami を WSL 内で実行)
#    PS 5.1 の native command 引数渡しは \n エスケープが壊れるので、printf を使わず
#    単純な wsl.exe whoami を使う。distro 名は引数 (デフォルト Ubuntu)。
$whoamiOut = wsl.exe -d $Distro -e whoami 2>$null
if (-not $whoamiOut) {
    Write-Error "WSL ($Distro) で whoami の取得に失敗。WSL が起動しているか、-Distro 引数で正しい名前を指定しているか確認してください。"
    exit 1
}
$wslUser = ($whoamiOut | Out-String).Trim()
if (-not $wslUser) {
    Write-Error "WSL username が空。-Distro $Distro で whoami の結果を確認してください。"
    exit 1
}

$wslClaudeRoot = "\\wsl.localhost\${Distro}\home\${wslUser}\.claude"
$winClaudeRoot = "$env:USERPROFILE\.claude"

Write-Host "WSL distro:   $Distro"
Write-Host "WSL user:     $wslUser"
Write-Host "WSL .claude:  $wslClaudeRoot"
Write-Host "Win .claude:  $winClaudeRoot"
Write-Host ""

if (-not (Test-Path -LiteralPath $wslClaudeRoot)) {
    Write-Error "WSL の .claude が見つかりません: $wslClaudeRoot"
    exit 1
}

# 2. 既存の Windows ~/.claude の状態判定
if (Test-Path -LiteralPath $winClaudeRoot) {
    $item = Get-Item -LiteralPath $winClaudeRoot -Force
    if ($item.LinkType -eq 'SymbolicLink' -or $item.LinkType -eq 'Junction') {
        Write-Host "既存 SymLink/Junction を削除: $winClaudeRoot -> $($item.Target)"
        if (-not $WhatIf) {
            # PS 5.1 の Remove-Item -Force だと「子要素がある」確認プロンプトが出るので、
            # .NET API で target を follow せずポインタのみ削除する。
            # 第 2 引数 $false = recursive なし (SymLink/Junction 自体だけ削除、target 無事)
            try {
                [System.IO.Directory]::Delete($winClaudeRoot, $false)
            } catch {
                Write-Error "SymLink/Junction 削除に失敗: $_"
                exit 1
            }
        }
    } elseif (-not $Force) {
        Write-Error "$winClaudeRoot が既に実ディレクトリとして存在します。中身を保持して続行するなら -Force を付けて再実行してください。"
        exit 1
    } else {
        Write-Host "既存実ディレクトリを保持して続行します (-Force)"
    }
}

# 3. 実ディレクトリ作成
if (-not (Test-Path -LiteralPath $winClaudeRoot)) {
    Write-Host "実ディレクトリ作成: $winClaudeRoot"
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $winClaudeRoot -Force | Out-Null
    }
}

# 4. 包含リスト分の SymLink を作成
$linkErrors = @()
foreach ($name in $includeForLink) {
    $source   = Join-Path $wslClaudeRoot $name
    $linkPath = Join-Path $winClaudeRoot $name

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warning "Source not found, skipping: $source"
        continue
    }
    if (Test-Path -LiteralPath $linkPath) {
        Write-Host "Skip (already exists): $name"
        continue
    }
    Write-Host "Link: $name -> $source"
    if (-not $WhatIf) {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $source -ErrorAction Stop | Out-Null
        } catch {
            $linkErrors += "$name : $_"
            Write-Warning "Failed: $name -> $_"
        }
    }
}

if ($linkErrors.Count -gt 0) {
    Write-Host ""
    Write-Error "SymLink 作成中にエラーが発生しました。Windows Developer Mode が有効か確認してください (Settings > Privacy and Security > For developers > Developer Mode を ON)。"
    foreach ($e in $linkErrors) { Write-Host "  - $e" }
    exit 1
}

# 5. WSL .claude のパスをキャッシュ (powershell-utf8-profile.ps1 の自動補完用)
$cacheFile = "$env:USERPROFILE\.claude-wsl-cache.txt"
if (-not $WhatIf) {
    Set-Content -LiteralPath $cacheFile -Value $wslClaudeRoot -Encoding UTF8
    Write-Host ""
    Write-Host "WSL .claude path をキャッシュ: $cacheFile"
}

Write-Host ""
Write-Host "=== setup 完了 ==="
Write-Host ""
Write-Host "次回以降の PowerShell タブ起動時、欠けている SymLink は powershell-utf8-profile.ps1"
Write-Host "が自動補完します。"

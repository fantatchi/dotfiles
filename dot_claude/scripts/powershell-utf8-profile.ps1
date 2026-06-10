# PowerShell の入出力 encoding を UTF-8 (BOM なし) に固定する
#
# Why: Windows デフォルトのコンソール encoding は OEM (日本語環境では CP932/Shift_JIS) で、
#      UTF-8 出力の子プロセス (git log 等) を CP932 として decode してしまい mojibake が発生する。
#      Claude Code の `/context-save` が `git log` 出力をそのまま context.md に書き込む経路で
#      この問題を確認 (2026-05-18 修復)。具体例:
#        OK: "test_screener の _cfg に price_max=5000 固定の理由を注記"
#        NG: "test_screener 縺ｮ _cfg 縺ｫ price_max=5000 蝗ｺ螳壹・逅・罰繧呈ｳｨ險・
# How: Windows 側 $PROFILE から以下のように dot-source して読み込む
#        . "\\wsl.localhost\<distro>\home\fantatchi\.claude\scripts\powershell-utf8-profile.ps1"
#      手順詳細は `~/ObsidianVault/00_meta/setup-checklist.md` の「Windows PowerShell: UTF-8 強制」節

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $Utf8NoBom
[Console]::InputEncoding  = $Utf8NoBom
$OutputEncoding           = $Utf8NoBom

# Out-File / Set-Content / Add-Content も BOM なし UTF-8 をデフォルトに (PS6+ のみ)
# PS5.1 (Windows PowerShell) は 'utf8NoBOM' を認識しないため適用しない
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $PSDefaultParameterValues['Out-File:Encoding']    = 'utf8NoBOM'
    $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8NoBOM'
    $PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8NoBOM'
}

# ----------------------------------------------------------------------
# Windows 側 ~/.claude の SymLink 自動補完
# ----------------------------------------------------------------------
#
# Why: ~/.claude を Windows ↔ WSL の単一 SymLink で共有していると、Claude Code plugin
#      システムが known_marketplaces.json 等に Linux 絶対パスをハードコードする問題で
#      Windows 側 Claude Code がエラーになる (2026-05-22 判明)。対処として:
#        - ~/.claude を Windows 側で実ディレクトリ化 (初回は setup-windows-claude.ps1)
#        - 共有すべきファイル/dir だけ個別 SymLink で WSL に向ける (包含リスト方式)
#        - plugins/ 等 PC-local は Windows ネイティブ管理
#      新規 chezmoi 管理ファイルが ~/.claude/ 直下に追加された時、PowerShell タブ起動時に
#      ここで自動補完される (包含リストへの追加は本ファイル側で必要)。
#
# How: $env:USERPROFILE\.claude-wsl-cache.txt にキャッシュした WSL .claude UNC パスを使う
#      (キャッシュは setup-windows-claude.ps1 が書く)。キャッシュ未作成なら no-op で抜ける。

$claudeWslCacheFile = "$env:USERPROFILE\.claude-wsl-cache.txt"
if (Test-Path -LiteralPath $claudeWslCacheFile) {
    $claudeWslRoot = (Get-Content -LiteralPath $claudeWslCacheFile -Raw -Encoding UTF8).Trim()
    if ($claudeWslRoot -and (Test-Path -LiteralPath $claudeWslRoot)) {
        $claudeWinRoot = "$env:USERPROFILE\.claude"
        $rootItem = Get-Item -LiteralPath $claudeWinRoot -Force -ErrorAction SilentlyContinue
        # ~/.claude が実ディレクトリの場合だけ自動補完 (SymLink/未設定なら setup 未完)
        if ($rootItem -and ($rootItem.LinkType -notin @('SymbolicLink', 'Junction'))) {
            $claudeInclude = @(
                'CLAUDE.md', 'settings.json', 'settings.local.json', 'context.md',
                'agents', 'docs', 'scripts', 'skills', 'commands'
            )
            foreach ($name in $claudeInclude) {
                $source   = Join-Path $claudeWslRoot $name
                $linkPath = Join-Path $claudeWinRoot $name
                if ((Test-Path -LiteralPath $source) -and -not (Test-Path -LiteralPath $linkPath)) {
                    try {
                        New-Item -ItemType SymbolicLink -Path $linkPath -Target $source -ErrorAction Stop | Out-Null
                        Write-Host "claude-symlink: created $name"
                    } catch {
                        Write-Warning "claude-symlink: failed for $name : $_"
                    }
                }
            }
        }
    }
}

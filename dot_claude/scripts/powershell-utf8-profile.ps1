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

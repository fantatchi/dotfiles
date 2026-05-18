# PS 5.1 が stderr に吐く CLIXML progress record を抑止（hook stderr 汚染対策）
$ProgressPreference = 'SilentlyContinue'

Import-Module BurntToast
$icon = Join-Path $env:USERPROFILE '.claude\icon\claude-color.png'
New-BurntToastNotification -Text 'ClaudeCode', '確認が必要です' -Sound Default -AppLogo $icon

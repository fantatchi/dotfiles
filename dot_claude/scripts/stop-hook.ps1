Import-Module BurntToast
$icon = Join-Path $env:USERPROFILE '.claude\icon\claude-color.png'
New-BurntToastNotification -Text 'ClaudeCode', '処理が完了しました' -Sound Default -AppLogo $icon

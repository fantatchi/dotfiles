Set-ExecutionPolicy Bypass -Scope Process -Force
Import-Module BurntToast
$icon = Join-Path $env:USERPROFILE '.claude\icon\claude-color.png'
New-BurntToastNotification -Text 'ClaudeCode', '確認が必要です' -Sound Default -AppLogo $icon

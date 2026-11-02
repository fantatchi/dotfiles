# Compatibility entry point; run-hook.js normally calls Node.js directly.
# Inherit raw stdin/stdout so Windows PowerShell 5.1 never re-encodes UTF-8.
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Join-Path $env:USERPROFILE '.claude\scripts' }
$nodeScript = Join-Path $scriptDir 'context-save-hooks.js'
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = (Get-Command node -ErrorAction Stop).Source
$startInfo.Arguments = '"' + $nodeScript + '" context-save-git-trigger'
$startInfo.UseShellExecute = $false
$process = [System.Diagnostics.Process]::Start($startInfo)
$process.WaitForExit()
exit $process.ExitCode

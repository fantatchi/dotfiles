# Share selected WSL Codex files with Windows.
# Keep auth, sessions, config, plugins, caches, and system skills local.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$Force
)

$sharedRootFiles = @('AGENTS.md')
$sharedSkills = @(
    'context-load',
    'context-save',
    'session-save',
    'obsidian-log',
    'obsidian-resource',
    'session-review',
    'spec-writer'
)
$wslUser = (wsl.exe -d $Distro -e whoami 2>$null | Out-String).Trim()
if (-not $wslUser) {
    throw "Could not resolve the WSL user for distro: $Distro"
}

$wslCodexRoot = "\\wsl.localhost\$Distro\home\$wslUser\.codex"
$wslAgentsRoot = "\\wsl.localhost\$Distro\home\$wslUser\.agents"
$windowsCodexRoot = Join-Path $env:USERPROFILE '.codex'
$windowsAgentsRoot = Join-Path $env:USERPROFILE '.agents'

if (-not (Test-Path -LiteralPath $wslCodexRoot)) {
    throw "WSL .codex was not found: $wslCodexRoot"
}
if (-not (Test-Path -LiteralPath $wslAgentsRoot)) {
    throw "WSL .agents was not found: $wslAgentsRoot"
}

$windowsRootItem = Get-Item -LiteralPath $windowsCodexRoot -Force -ErrorAction SilentlyContinue
if ($windowsRootItem -and $windowsRootItem.LinkType -in @('SymbolicLink', 'Junction')) {
    throw "Windows .codex must be a real directory: $windowsCodexRoot"
}

if (-not $windowsRootItem -and $PSCmdlet.ShouldProcess($windowsCodexRoot, 'Create directory')) {
    New-Item -ItemType Directory -Path $windowsCodexRoot -Force | Out-Null
}

function New-ProtectedSymbolicLink {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$LinkPath,
        [Parameter(Mandatory)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Warning "Source not found; skipping: $Source"
        return
    }

    $existingItem = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
    if ($existingItem) {
        if ($existingItem.LinkType -eq 'SymbolicLink' -and $existingItem.Target -contains $Source) {
            Write-Host "Existing link is valid: $Label"
            return
        }
        if (-not $Force) {
            Write-Warning "Existing item protected; skipping: $LinkPath"
            return
        }
        throw "Existing items are never removed automatically. Move it aside and retry: $LinkPath"
    }

    if ($PSCmdlet.ShouldProcess($LinkPath, "Create SymbolicLink to $Source")) {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Source -ErrorAction Stop | Out-Null
    }
}

foreach ($name in $sharedRootFiles) {
    $source = Join-Path $wslCodexRoot $name
    $linkPath = Join-Path $windowsCodexRoot $name
    New-ProtectedSymbolicLink -Source $source -LinkPath $linkPath -Label $name
}

$windowsAgentsItem = Get-Item -LiteralPath $windowsAgentsRoot -Force -ErrorAction SilentlyContinue
if ($windowsAgentsItem -and $windowsAgentsItem.LinkType -in @('SymbolicLink', 'Junction')) {
    throw "Windows .agents must be a real directory: $windowsAgentsRoot"
}
if (-not $windowsAgentsItem -and $PSCmdlet.ShouldProcess($windowsAgentsRoot, 'Create directory')) {
    New-Item -ItemType Directory -Path $windowsAgentsRoot -Force | Out-Null
}

$windowsSkillsRoot = Join-Path $windowsAgentsRoot 'skills'
if (-not (Test-Path -LiteralPath $windowsSkillsRoot) -and $PSCmdlet.ShouldProcess($windowsSkillsRoot, 'Create skills directory')) {
    New-Item -ItemType Directory -Path $windowsSkillsRoot -Force | Out-Null
}

foreach ($name in $sharedSkills) {
    $source = Join-Path (Join-Path $wslAgentsRoot 'skills') $name
    $linkPath = Join-Path $windowsSkillsRoot $name
    New-ProtectedSymbolicLink -Source $source -LinkPath $linkPath -Label "skills/$name"
}

Write-Host 'Windows Codex sharing setup completed.'

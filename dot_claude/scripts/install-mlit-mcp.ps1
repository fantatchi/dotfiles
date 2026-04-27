#!/usr/bin/env pwsh
# install-mlit-mcp.ps1 - 不動産情報ライブラリ MCP サーバ (chirikuuka/mlit-geospatial-mcp)
# を Windows にセットアップして Claude Code の user スコープに登録する。
#
# 前提:
#   - 環境変数 MLIT_LIBRARY_API_KEY に API キーを設定しておくこと
#       一時設定: $env:MLIT_LIBRARY_API_KEY = 'your-api-key'
#       永続化:   setx MLIT_LIBRARY_API_KEY "your-api-key"  （別ターミナルで）
#   - python (or py launcher), git, claude CLI がインストール済みであること
#
# 冪等: 再実行で git pull + pip install -U + 再登録（既存登録は remove → add）

$ErrorActionPreference = 'Stop'

$RepoUrl    = 'https://github.com/chirikuuka/mlit-geospatial-mcp.git'
$InstallDir = Join-Path $env:LOCALAPPDATA 'mcp-servers\mlit-geospatial-mcp'
$McpName    = 'mlit-geospatial'

# API キーチェック
if (-not $env:MLIT_LIBRARY_API_KEY) {
    Write-Error "MLIT_LIBRARY_API_KEY が未設定です。先に設定してから再実行してください。`n  例: `$env:MLIT_LIBRARY_API_KEY = 'your-api-key'"
    exit 1
}

# Python コマンド決定（py launcher 優先）
$PythonCmd = $null
$PythonArgs = @()
if (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonCmd = 'py'
    $PythonArgs = @('-3')
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonCmd = 'python'
}
if (-not $PythonCmd) {
    Write-Error 'Python が見つかりません。Python 3.10+ をインストールしてください。'
    exit 1
}

# git, claude 確認
foreach ($cmd in @('git', 'claude')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "'$cmd' が見つかりません。インストールしてから再実行してください。"
        exit 1
    }
}

# clone or pull
$ParentDir = Split-Path -Parent $InstallDir
if (-not (Test-Path $ParentDir)) {
    New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
}
if (Test-Path (Join-Path $InstallDir '.git')) {
    Write-Host "[1/3] 既存リポジトリを更新します: $InstallDir"
    git -C $InstallDir pull --ff-only
} else {
    Write-Host "[1/3] リポジトリをクローンします: $InstallDir"
    git clone $RepoUrl $InstallDir
}

# venv セットアップ
$VenvDir = Join-Path $InstallDir '.venv'
$PythonBin = Join-Path $VenvDir 'Scripts\python.exe'
if (-not (Test-Path $PythonBin)) {
    Write-Host "[2/3] venv を作成します: $VenvDir"
    & $PythonCmd @PythonArgs -m venv $VenvDir
}
Write-Host '[2/3] 依存パッケージをインストール (or 更新) します'
& $PythonBin -m pip install --quiet --upgrade pip
& $PythonBin -m pip install --quiet -U -r (Join-Path $InstallDir 'requirements.txt')

# MCP 登録（既存なら remove → add で再登録）
Write-Host "[3/3] Claude Code に MCP を登録します: $McpName"
& claude mcp get $McpName 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    & claude mcp remove $McpName 2>&1 | Out-Null
}
$ServerPy = Join-Path $InstallDir 'src\server.py'
& claude mcp add -s user $McpName `
    -e "LIBRARY_API_KEY=$env:MLIT_LIBRARY_API_KEY" `
    -e 'PYTHONUNBUFFERED=1' `
    -e 'LOG_LEVEL=WARNING' `
    -- $PythonBin $ServerPy

Write-Host ''
Write-Host "完了: $McpName を登録しました。Claude Code を再起動して 'claude mcp list' で確認してください。"

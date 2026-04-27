#!/usr/bin/env bash
# install-mlit-mcp.sh - 不動産情報ライブラリ MCP サーバ (chirikuuka/mlit-geospatial-mcp)
# を WSL/macOS にセットアップして Claude Code の user スコープに登録する。
#
# 前提:
#   - MLIT_LIBRARY_API_KEY 環境変数に API キーを export しておくこと
#   - python3, git, claude CLI がインストール済みであること
#
# 冪等: 再実行で git pull + pip install -U + 再登録（既存登録は remove → add）

set -euo pipefail

REPO_URL="https://github.com/chirikuuka/mlit-geospatial-mcp.git"
INSTALL_DIR="${HOME}/.local/share/mcp-servers/mlit-geospatial-mcp"
MCP_NAME="mlit-geospatial"

# API キーチェック
if [ -z "${MLIT_LIBRARY_API_KEY:-}" ]; then
    echo "ERROR: MLIT_LIBRARY_API_KEY が未設定です。先に export してから再実行してください。" >&2
    echo "  例: export MLIT_LIBRARY_API_KEY='your-api-key'" >&2
    exit 1
fi

# 必要コマンドの確認
for cmd in python3 git claude; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' が見つかりません。インストールしてから再実行してください。" >&2
        exit 1
    fi
done

# clone or pull
mkdir -p "$(dirname "$INSTALL_DIR")"
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "[1/3] 既存リポジトリを更新します: $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
else
    echo "[1/3] リポジトリをクローンします: $INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# venv セットアップ
VENV_DIR="$INSTALL_DIR/.venv"
PYTHON_BIN="$VENV_DIR/bin/python"
if [ ! -x "$PYTHON_BIN" ]; then
    echo "[2/3] venv を作成します: $VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi
echo "[2/3] 依存パッケージをインストール (or 更新) します"
"$PYTHON_BIN" -m pip install --quiet --upgrade pip
"$PYTHON_BIN" -m pip install --quiet -U -r "$INSTALL_DIR/requirements.txt"

# MCP 登録（既存なら remove → add で再登録）
echo "[3/3] Claude Code に MCP を登録します: $MCP_NAME"
if claude mcp get "$MCP_NAME" >/dev/null 2>&1; then
    claude mcp remove "$MCP_NAME" >/dev/null 2>&1 || true
fi
claude mcp add -s user "$MCP_NAME" \
    -e "LIBRARY_API_KEY=$MLIT_LIBRARY_API_KEY" \
    -e "PYTHONUNBUFFERED=1" \
    -e "LOG_LEVEL=WARNING" \
    -- "$PYTHON_BIN" "$INSTALL_DIR/src/server.py"

echo ""
echo "完了: $MCP_NAME を登録しました。Claude Code を再起動して 'claude mcp list' で確認してください。"

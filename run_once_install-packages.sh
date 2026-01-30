#!/bin/bash

set -e

echo "=== dotfiles セットアップを開始します ==="

## === oh-my-zsh のインストール ===
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh をインストール中..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "oh-my-zsh は既にインストール済みです。"
fi

## === TPM (Tmux Plugin Manager) のセットアップ ===
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "TPM をクローン中..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM は既にインストール済みです。"
fi

chmod +x "$TPM_DIR"/bin/* "$TPM_DIR"/scripts/* "$TPM_DIR"/bindings/* || true

command -v dos2unix >/dev/null 2>&1 && {
    dos2unix "$TPM_DIR"/bin/* "$TPM_DIR"/scripts/* "$TPM_DIR"/bindings/* 2>/dev/null || true
}

## === tmux プラグインのインストール ===
if command -v tmux >/dev/null 2>&1; then
    echo "tmux プラグインをインストール中..."
    tmux new-session -d -s _tpm_setup_ "sleep 1"
    "$TPM_DIR/bin/install_plugins" || echo "プラグインインストールに失敗しました（あとで prefix + I を試してください）"
    tmux kill-session -t _tpm_setup_ 2>/dev/null || true
fi

echo "=== セットアップ完了！ ==="

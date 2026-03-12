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

## === Claude Code のインストール ===
if ! command -v claude &> /dev/null; then
    echo "Claude Code をインストール中..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        echo "警告: Claude Code のインストールに失敗しました"
    fi
else
    echo "Claude Code は既にインストール済みです。"
fi

echo "=== セットアップ完了！ ==="

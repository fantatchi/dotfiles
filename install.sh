#!/bin/bash

set -e

echo "🚀 dotfiles セットアップを開始します..."

## === Vim の設定 ===
echo "🔧 Vim の設定リンクを作成中..."
ln -sf ~/dotfiles/.vim ~/.vim
ln -sf ~/dotfiles/.vimrc ~/.vimrc
touch ~/.vimrc.local

## === Zsh の設定 ===
echo "🔧 Zsh の設定リンクを作成中..."
ln -sf ~/dotfiles/.zsh ~/.zsh
ln -sf ~/dotfiles/.zshrc ~/.zshrc
touch ~/.zshrc.local

## === oh-my-zsh のインストール ===
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 oh-my-zsh をインストール中..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "✅ oh-my-zsh は既にインストール済みです。"
fi

## === tmux の設定 ===
echo "🔧 tmux の設定リンクを作成中..."
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf

## === TPM (Tmux Plugin Manager) のセットアップ ===
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
echo "📦 TPM をクローン中..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "✅ TPM は既にインストール済みです。"
fi

# 実行権限を補強（万が一に備える）
chmod +x "$TPM_DIR"/bin/* "$TPM_DIR"/scripts/* "$TPM_DIR"/bindings/* || true

# 改行コード修正（Windows環境でcloneした場合に備える）
command -v dos2unix >/dev/null 2>&1 && {
    dos2unix "$TPM_DIR"/bin/* "$TPM_DIR"/scripts/* "$TPM_DIR"/bindings/* 2>/dev/null || true
}

## === tmux プラグインの自動インストール（仮セッションで） ===
echo "🛠️ tmux プラグインをインストール中..."
tmux new-session -d -s _tpm_setup_ "sleep 1"
"$TPM_DIR/bin/install_plugins" || echo "⚠️ プラグインインストールに失敗しました（あとで prefix + I を試してください）"
tmux kill-session -t _tpm_setup_

echo "🎉 セットアップ完了！再ログイン、または 'source ~/.zshrc' を推奨します。"


# 🛠 dotfiles セットアップ手順

このリポジトリでは、`vim`、`zsh`（oh-my-zsh 使用）、`tmux` の開発環境構築を自動化するための設定を提供しています。

## ✅ 事前準備

- WSL2 または Linux/macOS 環境
- `git`, `curl`, `tmux`, `vim`, `zsh` がインストールされていること

---

## 📦 インストール手順

### 1. このリポジトリを clone

```sh
git clone https://github.com/fantatchi/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. セットアップスクリプトを実行

```sh
chmod +x install.sh
./install.sh
```

---

## 🔧 実行内容（install.sh で行われること）

### ▶ Vim 設定

```sh
ln -sf ~/dotfiles/.vim ~/.vim
ln -sf ~/dotfiles/.vimrc ~/.vimrc
touch ~/.vimrc.local  # 個別設定用
```

### ▶ Zsh 設定（Oh My Zsh）

```sh
ln -sf ~/dotfiles/.zsh ~/.zsh
ln -sf ~/dotfiles/.zshrc ~/.zshrc
touch ~/.zshrc.local  # 個別設定用
```

#### Oh My Zsh のインストール

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

※ `.zshrc` は install.sh で上書きされるので、Oh My Zsh のインストーラで `~/.zshrc` が作られても問題ありません。

---

### ▶ tmux 設定 + TPM（Tmux Plugin Manager）

```sh
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
```

TPM のインストール（自動）：

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

tmux 内で以下の操作をすると、プラグインが自動インストールされます：

```
prefix + I  # 例: Ctrl + q → Shift + i
```

※ `install.sh` は仮セッションを作って自動的にインストールを試みます。

---

## 📁 構成

```
~/dotfiles/
├── .vim
├── .vimrc
├── .zsh
├── .zshrc
├── .tmux.conf
└── install.sh
```

---

## 🧩 補足：各設定ファイルの役割

- `.vimrc.local`, `.zshrc.local` などは個別環境ごとのカスタマイズ用です。
- `.zsh` や `.vim` ディレクトリにテーマ・補完設定などを含めておくと再現性が高まります。

---

## 🚀 おすすめプラグイン

- tmux:
  - `tmux-sensible`: デフォルト設定強化
  - `tmux-yank`: システムクリップボード対応


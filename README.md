# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles。

## 新しい PC でのセットアップ

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi
```

GitHub Personal Access Token の入力を求められるので、入力する。

セットアップ後、tmux 内で `prefix + I` を実行してプラグインをインストールする。

## 管理しているファイル

| 対象 | ファイル |
|------|---------|
| zsh | `.zshrc`, `.zsh/` |
| vim | `.vimrc`, `.vim/` |
| tmux | `.tmux.conf` |
| Claude | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/mcp.json` |

## よく使うコマンド

```bash
# ファイルを管理対象に追加
chezmoi add ~/.some_config

# 変更を確認（適用前の diff）
chezmoi diff

# 変更を適用
chezmoi apply

# ソースディレクトリに移動
chezmoi cd

# 管理中のファイル一覧
chezmoi managed
```

## 変更の流れ

```bash
# 1. 設定ファイルを直接編集した場合
vim ~/.zshrc
chezmoi re-add  # 変更をソースに反映

# 2. ソース側で編集する場合
chezmoi edit ~/.zshrc
chezmoi apply

# 3. コミット & push
chezmoi cd
git add -A && git commit -m "メッセージ"
git push
```

## テンプレート

`.tmpl` 拡張子のファイルはテンプレートとして処理される。
トークンなどの秘密情報は `~/.config/chezmoi/chezmoi.toml` に保存され、git には含まれない。

トークンを再設定したい場合：

```bash
chezmoi init
```

## 作者環境メモ

### Obsidian Vault の同期設定

Vault 本体は Windows の `~/ObsidianVault`（`C:\Users\<username>\ObsidianVault`）に配置。

**PC 間の同期:**
- OneDrive で Vault フォルダを同期
- 拡張機能や設定を変更した場合は `.obsidian` フォルダを各環境にコピー
- メモの同期は Obsidian の git 拡張機能で行う

**WSL からのアクセス:**
```bash
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault
export OBSIDIAN_VAULT="$HOME/ObsidianVault"
```

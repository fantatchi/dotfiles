# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles。

## 新しい PC でのセットアップ

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi
```

初回セットアップ時に以下を聞かれる：
- GitHub Personal Access Token
- Obsidian 連携機能を使うか

セットアップ後、tmux 内で `prefix + I` を実行してプラグインをインストールする。

## 管理しているファイル

| 対象 | ファイル |
|------|---------|
| zsh | `.zshrc`, `.zsh/` |
| vim | `.vimrc`, `.vim/` |
| tmux | `.tmux.conf` |
| Claude | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/mcp.json`, `.claude/commands/` |

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

## Obsidian 連携

Claude Code の作業ログを Obsidian Vault に記録する機能。

**利用可能なコマンド:**
- `/obs-log`: 作業履歴を記録
- `/obs-resource`: 調査結果やリソースをメモ
- 自動ロギング: 一定条件で自動的に作業ログを記録

**セットアップ:**

環境変数 `OBSIDIAN_VAULT` に Vault のパスを設定する。

```bash
export OBSIDIAN_VAULT="/path/to/your/vault"
```

**保存先:**
- `/obs-log` → `$OBSIDIAN_VAULT/_ClaudeLogs/`
- `/obs-resource` → `$OBSIDIAN_VAULT/_ClaudeResources/`

## 作者環境メモ

### Obsidian Vault

Vault 本体は Windows の `C:\Users\<username>\ObsidianVault` に配置。

- OneDrive で Vault フォルダを PC 間で同期
- メモの同期は Obsidian の git 拡張機能で行う
- 拡張機能や設定を変更した場合は `.obsidian` フォルダを各環境にコピー

**WSL からのアクセス:**
```bash
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault
export OBSIDIAN_VAULT="$HOME/ObsidianVault"
```

# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles。

## 新しい PC でのセットアップ

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi
```

初回セットアップ時に以下を聞かれる：
- GitHub Personal Access Token（MCP サーバーで GitHub API を使用するため）
- Obsidian 連携機能を使うか

セットアップ後、tmux 内で `prefix + I` を実行してプラグインをインストールする。

## 管理しているファイル

| 対象 | ファイル |
|------|---------|
| zsh | `.zshrc`, `.zsh/` |
| vim | `.vimrc`, `.vim/` |
| tmux | `.tmux.conf` |
| Claude | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/mcp.json`, `.claude/skills/` |

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

## 環境別設定（local ファイル）

chezmoi で管理しない環境固有の設定は `~/.zshrc.local` に記述する。

```bash
# ~/.zshrc.local の例
export OBSIDIAN_VAULT="~/ObsidianVault"
export MAX_THINKING_TOKENS=31999
```

このファイルは `.zshrc` から自動的に読み込まれる。マシンごとに異なる設定（パス、トークン等）はここに書く。

### NVM（Node Version Manager）

NVM を使用する場合は、公式の手順でインストール：

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

`.zshrc` に NVM のロード処理が含まれているため、インストール後は自動で読み込まれる。

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

## Claude Code 設定

### デフォルトモデル・Extended Thinking

`settings.json` で以下を設定済み：

| 設定 | 値 | 説明 |
|------|-----|------|
| `model` | `opus` | デフォルトで Opus 4.5 を使用 |
| `alwaysThinkingEnabled` | `true` | Extended Thinking を常に有効化 |

### MAX_THINKING_TOKENS（環境ごとに設定）

Extended Thinking のトークン上限を設定する環境変数。`~/.zshrc.local` に追記：

```bash
export MAX_THINKING_TOKENS=31999
```

| 値 | 相当するプロンプト | 用途 |
|----|-------------------|------|
| 設定なし | `think` | 簡単なタスク（デフォルト） |
| 中程度 | `think hard` | 中程度の複雑さ |
| `31999` | `ultrathink` | 最大の思考深度 |

セッション中にモデルを切り替える場合は `/model sonnet` などを使用。

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

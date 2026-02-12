# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles。

**対象環境:** Linux / macOS / WSL

## クイックスタート

**前提条件:** git がインストールされていること

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi
```

初回セットアップ時に以下を聞かれる（Enter でスキップ可）：

| 質問 | 説明 |
|------|------|
| GitHub MCP を使うか | Claude Code から GitHub API を使う場合は y → PAT を入力 |
| Obsidian 連携を使うか | 作業ログを Obsidian に記録する場合は y |

セットアップ後、tmux 内で `prefix + I` を実行してプラグインをインストール。

## 含まれるもの

| 対象 | ファイル | 備考 |
|------|---------|------|
| zsh | `.zshrc`, `.zsh/` | oh-my-zsh（プラグイン: git のみ） |
| vim | `.vimrc`, `.vim/` | プラグインレス |
| tmux | `.tmux.conf` | TPM でプラグイン管理 |
| Claude Code | `.claude/` | 設定・スキル |

## 環境別設定

マシンごとに異なる設定は `~/.zshrc.local` に記述する（chezmoi 管理外）。

```bash
# ~/.zshrc.local の例
export OBSIDIAN_VAULT="~/ObsidianVault"
export MAX_THINKING_TOKENS=31999

# Volta（Node.js バージョン管理）
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
```

このファイルは `.zshrc` から自動的に読み込まれる。

## オプション機能

### Claude Code

`settings.json` で以下を設定済み：

| 設定 | 値 | 説明 |
|------|-----|------|
| `model` | `opus` | デフォルトで Opus を使用 |
| `alwaysThinkingEnabled` | `true` | Extended Thinking を常に有効化 |

**ultrathink（最大の思考深度）を使う場合:**

```bash
# ~/.zshrc.local に追記
export MAX_THINKING_TOKENS=31999
```

セッション中のモデル切り替えは `/model sonnet` などを使用。

**スキル一覧:**

| コマンド | 説明 |
|----------|------|
| `/obsidian-log` | 作業履歴を Obsidian に記録（自動記録にも対応） |
| `/obsidian-resource` | 調査結果・参考リンクを Obsidian に保存 |
| `/obsidian-blog` | 技術ブログのドラフトを作成 |
| `/knowledge-search` | Obsidian 内のナレッジを横断検索 |
| `/context-save` | プロジェクトの作業状態を保存 |
| `/context-load` | 保存済みコンテキストを読み込み復帰 |
| `/context-list` | プロジェクトとコンテキストの一覧表示 |
| `/workspace-init` | ワークスペースを初期化し `CLAUDE.local.md` を生成 |
| `/review` | コーディング規約に基づくコードレビュー |
| `/naming` | 日本語から識別子名（変数・クラス等）を生成 |

### Obsidian 連携

Claude Code の作業ログを Obsidian Vault に記録する機能。

**セットアップ:**

```bash
# ~/.zshrc.local に追記
export OBSIDIAN_VAULT="/path/to/your/vault"
```

**保存先フォルダ:**

| フォルダ | 内容 |
|----------|------|
| `$OBSIDIAN_VAULT/_claude/log/` | 作業履歴 |
| `$OBSIDIAN_VAULT/_claude/resource/` | 調査結果・参考資料 |
| `$OBSIDIAN_VAULT/_claude/blog/` | ブログドラフト |

## chezmoi の使い方

### 他の環境で更新を取り込む

```bash
chezmoi update
```

リモートから最新を取得して適用する。

### 日常操作

```bash
chezmoi diff          # 変更を確認
chezmoi apply         # 変更を適用
chezmoi add ~/.file   # ファイルを管理対象に追加
chezmoi cd            # ソースディレクトリに移動
```

### 設定ファイルを編集したとき

```bash
# ホームの設定を直接編集した場合
chezmoi re-add

# ソース側で編集する場合
chezmoi edit ~/.zshrc
chezmoi apply
```

### トークンを再設定したいとき

```bash
chezmoi init
```

秘密情報は `~/.config/chezmoi/chezmoi.toml` に保存され、git には含まれない。

## 作者環境メモ

### Obsidian Vault

Vault 本体は Windows の `C:\Users\<username>\ObsidianVault` に配置。

- OneDrive で PC 間同期
- メモの同期は Obsidian の git 拡張機能
- `.obsidian` フォルダは各環境にコピー

**WSL からのアクセス:**

```bash
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault
export OBSIDIAN_VAULT="$HOME/ObsidianVault"
```

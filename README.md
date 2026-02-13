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
| Obsidian Vault のパス | 作業ログを Obsidian に記録する場合はパスを入力 |

セットアップ後、tmux 内で `prefix + I` を実行してプラグインをインストール。

## 含まれるもの

| 対象 | ファイル | 備考 |
|------|---------|------|
| zsh | `.zshrc`, `.zsh/` | oh-my-zsh（プラグイン: git のみ） |
| vim | `.vimrc`, `.vim/` | プラグインレス |
| tmux | `.tmux.conf` | TPM でプラグイン管理 |
| Claude Code | `.claude/` | 設定・スキル・config.json |

## 環境別設定

マシンごとに異なる環境変数は、シェルの設定ファイルに記述する（chezmoi 管理外）。
zsh の場合は `~/.zshrc.local`（`.zshrc` から自動読み込み）が使える。

```bash
# 環境変数の設定例
export MAX_THINKING_TOKENS=31999
```

Obsidian Vault のパスは `~/.claude/config.json` で管理する（`chezmoi init` で設定）。

## オプション機能

### Claude Code

`settings.json` で以下を設定済み：

| 設定 | 値 | 説明 |
|------|-----|------|
| `model` | `opus` | デフォルトで Opus を使用 |
| `alwaysThinkingEnabled` | `true` | Extended Thinking を常に有効化 |

**ultrathink（最大の思考深度）を使う場合:**

```bash
export MAX_THINKING_TOKENS=31999
```

セッション中のモデル切り替えは `/model sonnet` などを使用。

**スキル一覧:**

| コマンド | 説明 |
|----------|------|
| `/obsidian-log` | 作業履歴を Obsidian に記録（自動記録にも対応） |
| `/obsidian-resource` | 調査結果・参考リンクを Obsidian に保存 |
| `/obsidian-blog` | ブログ記事のドラフトを作成 |
| `/context-save` | プロジェクトの作業状態を `.claude/context.md` に保存 |
| `/context-load` | `.claude/context.md` からコンテキストを読み込み復帰 |
| `/session-save` | 作業ログ記録とコンテキスト保存をまとめて実行 |
| `/ks-review` | KS-Value 向け：コーディング規約に基づくコードレビュー |
| `/ks-naming` | KS-Value 向け：日本語から識別子名を生成 |

### Obsidian 連携

Claude Code の作業内容を Obsidian Vault に自動・手動で記録する機能。
作業ログ、調査メモ、ブログドラフトを Vault 内に Markdown で保存し、Obsidian のタグやリンク機能で後から振り返れる。

**セットアップ:**

`chezmoi init` で「Obsidian Vault のパス」を入力する（既に設定済みなら不要）。
設定は `~/.claude/config.json` に保存される。

chezmoi を使わない場合は、手動で `~/.claude/config.json` を作成する：

```json
{
  "obsidian_vault": "/path/to/your/vault"
}
```

WSL から Windows 側の Vault を使う場合はシンボリックリンク経由のパスを指定：

```bash
# シンボリックリンクを作成
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault
```

```json
{
  "obsidian_vault": "/home/<username>/ObsidianVault"
}
```

**使い方:**

| コマンド | 説明 | 使いどころ |
|----------|------|------------|
| `/obsidian-log` | 作業履歴を記録 | セッションの区切りに。「今日の作業を記録して」でも OK |
| `/obsidian-resource` | 調査結果・参考リンクを保存 | 「この調査結果をメモして」 |
| `/obsidian-blog` | ブログ記事のドラフトを作成 | テーマ指定 or `auto` でセッション内容から自動生成 |

**自動記録:**

コンテキストが圧縮される直前に、Claude が未記録の作業内容を自動で `/obsidian-log` に記録する。長いセッションでもログが漏れない。

**保存先フォルダ（自動作成される）:**

| フォルダ | 内容 |
|----------|------|
| `_claude/log/` | 作業履歴 |
| `_claude/resource/` | 調査結果・参考資料 |
| `_claude/blog/` | ブログドラフト |

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

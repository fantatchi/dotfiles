# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles。

**対象環境:** Linux (Ubuntu) / macOS / WSL

macOS では事前に [Homebrew](https://brew.sh/) が必要（hook 依存の `jq` を `brew install` で入れるため）。

## クイックスタート

**前提条件:** git がインストールされていること

**前提:** `~/ObsidianVault` が存在すること（Obsidian 連携スキルが参照する固定パス）。
WSL では Windows 側の Vault へのシンボリックリンクでも可。

```bash
# Vault を用意（Windows 側 Vault を WSL から使う例）
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault

# chezmoi 初期化
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi
```

`~/ObsidianVault` が存在しない状態で `chezmoi apply` を実行すると、
`.chezmoiscripts/run_before_check-obsidian-vault.sh.tmpl` がエラーで中断する。

## 含まれるもの

| 対象 | ファイル | 備考 |
|------|---------|------|
| zsh | `.zshrc`, `.zsh/` | oh-my-zsh（プラグイン: git のみ） |
| vim | `.vimrc`, `.vim/` | プラグインレス |
| Claude Code | `.claude/` | 設定・スキル・スクリプト |

## 環境別設定

マシンごとに異なる環境変数は、シェルの設定ファイルに記述する（chezmoi 管理外）。
zsh の場合は `~/.zshrc.local`（`.zshrc` から自動読み込み）が使える。

Obsidian Vault のパスは `~/ObsidianVault` 固定（設定ファイル不要）。

## オプション機能

### Claude Code

`settings.json` で以下を設定済み：

| 設定 | 値 | 説明 |
|------|-----|------|
| `alwaysThinkingEnabled` | `true` | Extended Thinking を常に有効化 |
| `autoUpdatesChannel` | `"latest"` | Claude Code の自動更新チャンネル |

**有効化済みプラグイン:**

| プラグイン | 説明 |
|-----------|------|
| `document-skills@anthropic-agent-skills` | ドキュメント作成系スキル集 |
| `context7@claude-plugins-official` | ライブラリドキュメント参照 |
| `feature-dev@claude-plugins-official` | ガイド付き機能開発 |
| `claude-md-management@claude-plugins-official` | CLAUDE.md の監査・改善 |
| `dotnet@dotnet-agent-skills` | .NET 開発支援 |
| `dotnet-aspnet@dotnet-agent-skills` | ASP.NET Core 開発支援 |
| `microsoft-docs@claude-plugins-official` | Microsoft Learn ドキュメント参照 |

セッション中のモデル切り替えは `/model sonnet` などを使用。

**スキル一覧:**

| コマンド | 説明 |
|----------|------|
| `/cloud-solution-architect` | Azure Architecture Center ベースの設計・レビュー |
| `/consistency-check` | CLAUDE.md・テンプレート・設定ファイル間の整合性チェック |
| `/context-load` | `.claude/context.md` からコンテキストを読み込み復帰 |
| `/context-save` | プロジェクトの作業状態を `.claude/context.md` に保存 |
| `/gtd-add` | `~/.claude/tasks.md` の Inbox にタスクを追加 |
| `/gtd-done` | 指定タスクを完了にし Done セクションへ移動 |
| `/gtd-list` | `~/.claude/tasks.md` からタスクを表示 |
| `/ks-naming` | 土木業界向け：日本語から識別子名を生成 |
| `/m365-agents-ts` | Microsoft 365 Agents SDK (TypeScript) の実装ガイド |
| `/obsidian-blog` | ブログ記事のドラフトを作成 |
| `/obsidian-daily` | GitHub アクティビティと作業ログからデイリーサマリーを生成 |
| `/obsidian-log` | 作業履歴を Obsidian に記録（自動記録にも対応） |
| `/obsidian-resource` | 調査結果・参考リンクを Obsidian に保存 |
| `/session-review` | セッション振り返り（権限・CLAUDE.md・スキルの整理） |
| `/session-save` | 作業ログ記録とコンテキスト保存をまとめて実行 |

### Obsidian 連携

Claude Code の作業内容を Obsidian Vault に自動・手動で記録する機能。
作業ログ、調査メモ、ブログドラフトを Vault 内に Markdown で保存し、Obsidian のタグやリンク機能で後から振り返れる。

**セットアップ:**

Vault パスは `~/ObsidianVault` 固定。ユーザーホーム直下に Vault を配置するか、
Windows 側 Vault へのシンボリックリンクを作成する：

```bash
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault
```

`chezmoi apply` 時に `.chezmoiscripts/run_before_check-obsidian-vault.sh.tmpl` が
Vault の存在を検証する。未配置の場合は apply が中断されるので、先に上記の
シンボリックリンク作成または Vault 配置を済ませておくこと。

**使い方:**

| コマンド | 説明 | 使いどころ |
|----------|------|------------|
| `/obsidian-log` | 作業履歴を記録 | セッションの区切りに。「今日の作業を記録して」でも OK |
| `/obsidian-resource` | 調査結果・参考リンクを保存 | 「この調査結果をメモして」 |
| `/obsidian-blog` | ブログ記事のドラフトを作成 | テーマ指定 or `auto` でセッション内容から自動生成 |
| `/obsidian-daily` | デイリーサマリーを生成 | 「今日のまとめ」「デイリーサマリー」 |

**自動記録:**

コンテキストが圧縮される直前に、Claude が未記録の作業内容を自動で `/obsidian-log` に記録する。長いセッションでもログが漏れない。

**保存先フォルダ（自動作成される）:**

| フォルダ | 内容 |
|----------|------|
| `_claude/log/` | 作業履歴 |
| `_claude/resource/` | 調査結果・参考資料 |
| `_claude/blog/` | ブログドラフト |
| `_daily/` | デイリーサマリー（`/obsidian-daily` で生成） |

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

## 作者環境メモ

### Obsidian Vault

Vault 本体は Windows の `C:\Users\<username>\ObsidianVault` に配置。

- OneDrive で PC 間同期
- メモの同期は Obsidian の git 拡張機能
- `.obsidian` フォルダは各環境にコピー

### WSL / Windows 共有構成

`.claude` は Windows 側から WSL 側へのシンボリックリンクで共有している
（`C:\Users\<username>\.claude` → `\\wsl.localhost\Ubuntu\home\<username>\.claude`）。
そのため **chezmoi は WSL 側からのみ実行する**こと。Windows 側で
`chezmoi apply` を走らせるとシンボリックリンクを実体ディレクトリに
置き換えてしまい、共有構成が壊れる。

### Windows セットアップ時の注意

新しい Windows 環境では、CurrentUser の PowerShell 実行ポリシーを
`RemoteSigned` に変更しておくこと。デフォルトの `Restricted` のままだと
Claude Code の Stop hook（BurntToast トースト通知）が起動しない。

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

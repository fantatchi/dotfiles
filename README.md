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
| `/consistency-check` | CLAUDE.md・テンプレート・設定ファイル間の整合性チェック |
| `/context-load` | `.claude/context.md` からコンテキストを読み込み復帰 |
| `/context-save` | プロジェクトの作業状態を `.claude/context.md` に保存 |
| `/gtd-add` | `~/.claude/tasks.md` の Inbox にタスクを追加 |
| `/gtd-done` | 指定タスクを完了にし Done セクションへ移動 |
| `/gtd-list` | `~/.claude/tasks.md` からタスクを表示 |
| `/ks-naming` | 土木業界向け：日本語から識別子名を生成 |
| `/obsidian-blog` | ブログ記事のドラフトを作成 |
| `/obsidian-daily` | GitHub アクティビティと作業ログからデイリーサマリーを生成 |
| `/obsidian-log` | 作業履歴を Obsidian に記録（自動記録にも対応） |
| `/obsidian-resource` | 調査結果・参考リンクを Obsidian に保存 |
| `/session-review` | セッション振り返り（権限・CLAUDE.md・スキルの整理） |
| `/session-save` | 作業ログ記録とコンテキスト保存をまとめて実行 |

### GTD タスク管理

`~/.claude/tasks.md` を GTD（Getting Things Done）ベースのタスクストアとして運用する機能。
`/gtd-add` / `/gtd-list` / `/gtd-done` で Claude 経由の読み書きができる。

**場所と同期:**

- 正本: `~/.claude/tasks.md`
- **chezmoi 管理外**（`.gitignore` 済み）。各 PC ローカルで持ち、他 PC とは同期しない
- フォーマット仕様の正本は `~/.claude/skills/shared/tasks-format.md`

**セクション構造（固定）:**

```markdown
# Tasks

## Inbox      # 未分類の新規タスク
## Next       # 次に着手するアクション
## Waiting    # 他者/外部待ち
## Someday    # いつかやる、保留
## Done       # 完了済み（新しいものが上）
```

**タスク行のフォーマット:**

```
- [ ] #project/<name> タイトル [@key:value]
```

- `#project/<name>` は必須。`<name>` はリポジトリのディレクトリ名（`basename $(git rev-parse --show-toplevel)`）
- ユーザーホーム（`$HOME` 完全一致）で gtd-* を実行した場合は `#project/global` が自動付与される
- Done に移す際はタイトル先頭に完了日（`YYYY-MM-DD`）を付加：`- [x] 2026-04-09 #project/... タイトル`
- 任意メタデータ: `@since:2026-04-08`（Waiting 開始日）、`@due:2026-04-15`（期限）など

**運用ルール:**

- Done は 1 ヶ月保持。`/gtd-list` 実行時に古いものが自動剪定される
- 「やらない」と決めたタスクは Done に送らず、素の Edit で削除する
- `/gtd-list` のデフォルトは「現在プロジェクトの Inbox + Next」のフィルタビュー

**使いどころ:**

| コマンド | 使う場面 |
|----------|----------|
| `/gtd-add` | 「このタスク追加して」「TODO として残して」 |
| `/gtd-list` | 「タスク一覧」「今やること」「TODO を見せて」 |
| `/gtd-done` | 「あれ終わった」「タスク完了」 |

### プロジェクトコンテキスト

プロジェクトの作業状態を `.claude/context.md` に保存し、次回セッションで復帰できるようにする機能。
`/context-save` で保存、`/context-load` で復帰。`/session-save` は `/obsidian-log` と `/context-save` をまとめて実行する。

**場所:**

- プロジェクトルート配下 `<project-root>/.claude/context.md`（プロジェクトごとに作成）
  - プロジェクトルートは `git rev-parse --show-toplevel`。git 外なら CWD
- ホームワークスペース用途としては `~/.claude/context.md` も同じ仕組みで運用できる
- `.claude/` が無ければ自動作成される

**ファイル構造:**

```markdown
---
project: <リポジトリ名>
git_remote: <origin URL>
branch: <current branch>
updated: YYYY-MM-DDTHH:mm:ss
tags:
  - claude-context
---

## プロジェクト概要
## 現在の状態        # ブランチ / 直近コミット / 未コミット変更
## 進行中の作業
## 判断メモ          # セッション中の重要な判断と理由
## 関連リポジトリ    # 任意（dotfiles などを併走する場合）
## 重要ファイル      # 相対パス
## メモ              # 任意
```

**tasks.md との役割分担:**

- **`context.md`**: そのプロジェクトの「**状態**」（進行中の作業、判断メモ、重要ファイル）
- **`tasks.md`** の `## Next`: そのプロジェクトの「**次にやること**」（`#project/<name>` タグで絞り込み）
- `/context-save` は「次のステップ」を `context.md` に書かず、必ず `tasks.md` の `## Next` に `#project/<name>` 付きで追記する

**使いどころ:**

| コマンド | 使う場面 |
|----------|----------|
| `/context-save` | セッションの区切り、作業中断前 |
| `/context-load` | プロジェクト再開時。直近の状態・判断を思い出したいとき |
| `/session-save` | 区切りをまとめて：作業ログ（Obsidian） + コンテキスト保存 + ブログ/リソース提案 |

**注意点:**

- 相対パスで記録する（マシン非依存にするため）
- PR 番号・Issue 番号だけでは次回誤認しやすいので、ブランチ名・タイトル・最終確認日もセットで記録する

### ホームワークスペース運用

ユーザーホーム (`~/`) は「**ホームワークスペース**」として扱う。プロジェクト単位で完結しない作業（スキル編集・tasks 管理・Obsidian 書き込み・個人 TODO 等）をここで行う場として位置付けている。

**CWD = `$HOME` のときの挙動:**

- `/gtd-*` はプロジェクトタグに **`#project/global`** を自動付与する（`$HOME` 完全一致で判定）
  - プロジェクト非依存のタスク（個人 TODO、環境整備、PC 固有の設定作業など）を集約する予約タグ
- コンテキストは `~/.claude/context.md` に保存される（通常プロジェクトと同じ `/context-save` / `/context-load` で扱える）

**dotfiles 作業との関心事分離:**

`~/` と `~/.local/share/chezmoi`（chezmoi source dir）は**別リポジトリ扱い**で、作業の起点を使い分ける。

| 作業対象 | CWD | git 履歴の正本 |
|---------|-----|---------------|
| スキル編集・tasks 管理・Obsidian 書き込みなど | `~/` | （tasks.md は非 git、それ以外は chezmoi source） |
| `.chezmoiroot` / テンプレート / hook スクリプトなど dotfiles 本体 | `~/` のまま | `~/.local/share/chezmoi` |

- **`cd` は使わず `git -C ~/.local/share/chezmoi ...` で操作する**。CWD は `~/` のまま維持する
- `~/.claude/context.md` の `## 関連リポジトリ` セクションに chezmoi 側の直近コミットを埋め込むことで、ホームワークスペース側から dotfiles の履歴も追えるようにしている

**`~/.claude` の live 編集ルール:**

- `~/.claude/` 配下は chezmoi 管理下だが **live 編集してよい**（スキル修正・`settings.json` 更新など）
- 反映は同一セッション内で一気通貫: live 編集 → `chezmoi re-add` → `git -C ~/.local/share/chezmoi commit/push`
- `~/.claude/tasks.md` と `~/.claude/settings.local.json` は **chezmoi 非管理**（前者は各 PC ローカル、後者はローカル権限/実験 env）

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

- メモの同期は Obsidian の git 拡張機能（obsidian-git プラグイン）
- `.obsidian` フォルダは別リポジトリ（`fantatchi/obsidian-config`）で管理・同期

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

# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理する個人 dotfiles。zsh/vim の設定に加え、Claude Code のスキル群（GTD タスク管理・コンテキスト保存・Obsidian 連携）を含む。

**対象環境:** Linux (Ubuntu) / macOS / WSL

macOS では事前に [Homebrew](https://brew.sh/) が必要（hook 依存の `jq` を `brew install` で入れるため）。

## 目次

- [クイックスタート](#クイックスタート)
- [含まれるもの](#含まれるもの)
- [環境別設定](#環境別設定)
- [chezmoi の日常操作](#chezmoi-の日常操作)
- [Claude Code 設定](#claude-code-設定)
- [タスクを Claude 経由で管理する (/gtd-*)](#タスクを-claude-経由で管理する-gtd-)
- [セッションをまたいで作業状態を引き継ぐ (/context-save, /context-load)](#セッションをまたいで作業状態を引き継ぐ-context-save-context-load)
- [作業ログ・メモを Obsidian に記録・配信する (/obsidian-*)](#作業ログメモを-obsidian-に記録配信する-obsidian-)
- [環境セットアップの注意点（Windows / WSL）](#環境セットアップの注意点windows--wsl)
- [Codex 設定を他 PC に展開する](#codex-設定を他-pc-に展開する)

## クイックスタート

**前提条件:**

- git がインストールされていること

```bash
# chezmoi 未導入の場合（インストールと init を同時実行）
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fantatchi

# chezmoi 導入済みの場合（2 台目以降の展開など）
chezmoi init --apply fantatchi
```

`/obsidian-*` 系スキルを使う場合は別途 `~/ObsidianVault` の配置が必要（[作業ログ・メモを Obsidian に記録・配信する](#作業ログメモを-obsidian-に記録配信する-obsidian-) を参照）。Vault 未配置でも `chezmoi apply` は警告を出して継続する（他の依存 — macOS の Homebrew など — が未解決の場合は apply が中断する）。

## 含まれるもの

| 対象 | ファイル | 備考 |
|------|---------|------|
| zsh | `.zshrc`, `.zsh/` | oh-my-zsh（プラグイン: git のみ） |
| vim | `.vimrc`, `.vim/` | プラグインレス |
| Claude Code | `.claude/` | 設定・スキル・スクリプト |

## 環境別設定

マシンごとに異なる環境変数は、シェルの設定ファイルに記述する（chezmoi 管理外）。
zsh の場合は `~/.zshrc.local`（`.zshrc` から自動読み込み）が使える。

## chezmoi の日常操作

chezmoi の基本操作と、`~/.claude` を chezmoi 管理下で live 編集するときの関心事分離ルール。

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

### `~/.claude` の live 編集と関心事分離

`~/` と `~/.local/share/chezmoi`（chezmoi source dir）は**別リポジトリ扱い**で、作業の起点を使い分ける。

| 作業対象 | CWD | git 履歴の正本 |
|---------|-----|---------------|
| スキル編集・tasks 管理・Obsidian 書き込みなど | `~/` | chezmoi source |
| `.chezmoiroot` / テンプレート / hook スクリプトなど dotfiles 本体 | `~/` のまま | `~/.local/share/chezmoi` |

※ `~/ObsidianVault/00_meta/tasks.md` は Obsidian Sync 同期下で全 PC 共通（chezmoi 非管理、Vault 配下）。その他の `~/.claude/` 配下は chezmoi source が正本。

- `~/.claude/` 配下は chezmoi 管理下だが **live 編集してよい**（スキル修正・`settings.json` 更新など）
- 反映は同一セッション内で一気通貫: live 編集 → `chezmoi re-add` → `git -C ~/.local/share/chezmoi commit/push`
- **`cd` は使わず `git -C ~/.local/share/chezmoi ...` で操作する**。CWD は `~/` のまま維持する
- `~/ObsidianVault/00_meta/tasks.md` と `~/.claude/settings.local.json` は **chezmoi 非管理**（前者は Vault 配下で Obsidian Sync 経由全 PC 共通、後者はローカル権限/実験 env）

## Claude Code 設定

Claude Code の `settings.json`・有効化済みプラグイン・このリポジトリに含まれる自作スキル一覧。

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
| `skill-creator@claude-plugins-official` | スキルのひな形生成・eval によるトリガー精度測定 |
| `codex@openai-codex` | Codex CLI 連携（`/codex:review` / `/codex:adversarial-review` / `/codex:rescue`） |
| `modern-web-guidance@googlechrome` | モダン Web（HTML/CSS/クライアント JS）のベストプラクティス参照 |
| `claude-code-setup@claude-plugins-official` | Claude Code の自動化（hooks / subagents / skills）推奨構成の提案 |
| `superpowers@claude-plugins-official` | 実装フローのプロセススキル群（brainstorming / writing-plans / systematic-debugging 等） |
| `code-simplifier@claude-plugins-official` | 変更済みコードの整理・簡素化 |

セッション中のモデル切り替えは `/model sonnet` などを使用。

**スキル一覧:**

| コマンド | 説明 |
|----------|------|
| `/baseline-ui` † | Tailwind プロジェクトの UI ベースライン検証（アニメーション時間・タイポスケール・アクセシビリティ） |
| `/cloud-solution-architect` † | Azure Architecture Center ベストプラクティスに基づくクラウドアーキテクト・ロール変換 |
| `/context-load` † | `.claude/context.md` からコンテキストを復帰、同じプロジェクトの `.claude/tasks.md` の Next / Someday と `.claude/handoff.md`（他エージェントからの引き継ぎ）も提示 |
| `/context-save` | プロジェクトの作業状態を `.claude/context.md` に保存（進行中は 14 日ローテ + 完了 entry を 300 字以内へ圧縮 + 12KB サイズアラート）、次アクションを `tasks.md` の `## Next` に吸い上げ、`.claude/handoff.md` に Claude ↔ Codex の引き継ぎメモを書き出し |
| `/discernment-nudge` | 見積もり・助言・計画・データ解釈など「ユーザーが信じて行動しそうな回答」の末尾に、見直す価値のある具体的な問いを 2〜3 個だけ添える（1 会話 1 回・調べ物や実行するコードには付けない）。Anthropic 公式スキルの日本語化 fork（Apache 2.0） |
| `/eli5` † | 難解な概念・未知のコードベースを「大きな図と最小の言葉」だけの自己完結 HTML に変換し、scratchpad へ保存して `wslview` でブラウザ表示。外部リソース参照ゼロ・ブロック 3〜7 個・全体 300 字程度の制約付き。使い捨ての理解用で、残す文書は `/spec-writer` の担当 |
| `/gtd-add` | `~/ObsidianVault/00_meta/tasks.md` の Inbox にタスクを追加 |
| `/gtd-done` | 指定タスクを完了にし Done セクションへ移動 |
| `/gtd-list` | `~/ObsidianVault/00_meta/tasks.md` からタスクを表示 |
| `japanese-doc-style` | 論証を積む日本語文書（書籍の章・仕様書・設計ドキュメント）のスタイル規約（ロール変換型、執筆・推敲時に自動発動） |
| `japanese-article-style` | 一人称の記事（体験記・ブログ・Obsidian 記事ノート）のスタイル規約。AI 味の原因を構造（定型骨格・箇条書き過多・1 文段落・公平な比較の型・失敗の削除）と捉えて崩し、観測範囲の明示と引用の扱いも定める（ロール変換型、自動発動。Codex 側 `~/.agents/skills/` にミラーあり） |
| `/m365-agents-ts` † | Microsoft 365 Agents SDK (TypeScript) の開発支援リファレンス |
| `/multi-persona-review` | 3〜5 人の専門ペルソナを並列 Agent で起動して読取専用レビューを行い、見落とし・別仮説・推奨アクションを統合 |
| `/obsidian-daily` | GitHub アクティビティと作業ログからデイリーサマリーを生成（KPI 行・リポ別コミットグルーピング・作業ログ折り畳み callout の構成）。**複数 GH アカウント (`fantatchi` + `kentem-at-kato`) 対応**。Obsidian Core Daily notes テンプレ (`90_config/templates/daily_notes.md`) を SSOT として動的読み込み、Thino プラグインとの共存を考慮した `# Journal` セクション前提 |
| `/obsidian-log` | 作業ログを Obsidian に記録（自動記録についてはセクション参照） |
| `/obsidian-mail` † | デイリーサマリーを Gmail SMTP でメール送信（日報・週報。`/obsidian-mail daily\|weekly [YYYY-MM-DD]` で明示呼び出し、または火〜土 8:00 / 月 8:00 のローカル routine 経由） |
| `/obsidian-resource` † | 調査メモ・参考リンク・ブログドラフトを Obsidian Vault に保存（`/obsidian-resource auto` でセッション内容から自動ドラフト化） |
| `/pr-review` | GitHub PR の URL または番号を渡すと、ブランチ切替・最新化、Copilot/discussion コメント取得、3-5 体のペルソナ並列レビュー、メインでの実コード裏取り、`.claude/reviews/pr-{NNN}-{branch-key}-{YYYY-MM-DD}.md` への所見草稿出力までを一気通貫で実施。投稿はしない（草稿のみ）。公式 `/code-review ultra` と棲み分け（本スキル=ローカル草稿・ペルソナ並列・MEMORY 運用ルール遵守、公式=inline 投稿）。投稿要否判断が残る所見はそのリポジトリの `.claude/tasks.md` への起票を提案（起票自体は `/context-save` の担当） |
| `/session-review` † | セッション振り返り（権限・CLAUDE.md・スキル・判断メモ圧縮の整理） |
| `/session-save` | 作業ログ記録とコンテキスト保存をまとめて実行し、アウトプット提案（ブログ・リソース候補）も行う |
| `/spec-writer` | 仕様書（specification / 設計ドキュメント / requirements / architecture / ADR / C4 / 用語集）の設計・作成・レビューを担うロール変換型スキル（旧 spec-design + dashboard-design を 2026-06 に統合）。読み手別入口・図種選択・ADR 形式・要件レベル語・Diátaxis 4 分類・テンプレ集を内蔵。HTML 補足ページは DADS v2.0.1 準拠（key-color = Blue 固定で JIS X 8341-3 AA 自動充足） |

† = `disable-model-invocation: true`（自動発動しない手動呼び出し専用。コンテキスト注入削減のため、低頻度スキルに適用 2026-07-07）。japanese-doc-style と japanese-article-style はロール変換型のためコマンドでなく文脈で自動発動する（前者は論証を積む文書、後者は一人称の記事）。

2026-07-07 の剪定で `frontend-patterns`（モデル既知の汎用知識）と `documentation-writer`（spec-writer と重複、Diátaxis 判断軸は `spec-writer/references/diataxis.md` へ吸収）を削除。

## タスクを Claude 経由で管理する (/gtd-*)

Claude に話しかけてタスクを追加・一覧・完了させる GTD ベースの仕組み。`~/ObsidianVault/00_meta/tasks.md` を正本として、`/gtd-add` / `/gtd-list` / `/gtd-done` の 3 コマンドで読み書きする。

**場所と同期:**

- 保存先: `~/ObsidianVault/00_meta/tasks.md`
- **chezmoi 管理外**（`.gitignore` 済み）。各 PC ローカルで持ち、他 PC とは同期しない
- フォーマット仕様は `~/.claude/skills/shared/tasks-format.md` を参照

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

- `#project/<name>` は**任意**。振り分け先が決まっているなら書く（後でその作業キューへ移すときの目印になる）。決まっていなければ付けない。`gtd-*` は **CWD からのプロジェクト推定をしない**（捕捉箱は CWD と無関係な思いつきの置き場のため）
- Done に移す際はタイトル先頭に完了日（`YYYY-MM-DD`）を付加：`- [x] 2026-04-09 #project/... タイトル`
- 任意メタデータ: `@since:2026-04-08`（Waiting 開始日）、`@due:2026-04-15`（期限）など

**運用ルール:**

- Done は **1 週間**保持（1 週間以上前のエントリを `/gtd-list` 実行時に自動剪定する。2026-07-27 に 2 週間から短縮。削除前に各日の Daily Note `## Done アーカイブ` へ転記される）
- 「やらない」と決めたタスクは Done に送らず、素の Edit で削除する
- `/gtd-list` のデフォルトは **Inbox + Next** の表示（CWD によるプロジェクトフィルタはしない）

**使いどころ:**

| コマンド | 使う場面 |
|----------|----------|
| `/gtd-add` | 「このタスク追加して」「TODO として残して」 |
| `/gtd-list` | 「タスク一覧」「今やること」「TODO を見せて」 |
| `/gtd-done` | 「あれ終わった」「タスク完了」 |

### CWD = `$HOME` のときの挙動（ホームワークスペース）

ユーザーホーム (`~/`) は「**ホームワークスペース**」として扱う。プロジェクト単位で完結しない作業（スキル編集・tasks 管理・Obsidian 書き込み・個人 TODO 等）をここで行う場として位置付けている。

- `/gtd-*` の書き先は **CWD によらず常に捕捉箱**（`~/ObsidianVault/00_meta/tasks.md`）。ホームワークスペースでも特別扱いはしない
- ホームワークスペース自身の**作業キュー**は `~/.claude/tasks.md`（`/context-save` が書き `/context-load` が表示する。`~/` も 1 プロジェクトとして扱う）

## セッションをまたいで作業状態を引き継ぐ (/context-save, /context-load)

セッションを閉じても次回すぐ再開できるように、プロジェクトの作業状態を `.claude/context.md` に保存する仕組み。`/context-save` で保存、`/context-load` で復帰。`/session-save` は `/obsidian-log` と `/context-save` をまとめて実行する。

**場所:**

- プロジェクトルート配下 `<project-root>/.claude/context.md`（プロジェクトごとに作成）
  - プロジェクトルートは `git rev-parse --show-toplevel`。git 外なら CWD
- ホームワークスペース（`~/`）では `~/.claude/context.md` を同じ仕組みで使える
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

- **`context.md`**: そのプロジェクトの「**状態**」（進行中の作業、判断メモ、重要ファイル）。プロジェクトルート毎に独立
- **`<project>/.claude/tasks.md`** の `## Next`: そのプロジェクトの「**次にやること**」（プロジェクトごとに独立した**作業キュー**。2026-07-27 に思いつきの捕捉箱と分離した）
- `/context-save` は「次のステップ」を `context.md` に書かず、必ず同じプロジェクトの `.claude/tasks.md` の `## Next` に追記する。`#project/<name>` タグは**付けない**（ファイルの場所がプロジェクトを表すため冗長）
- `context.md` の `## 進行中の作業` は **日付プレフィックス付き entry** で時系列ログとして記録され、`/context-save` 実行時に **14 日より古い entry が自動削除** される（最低 3 件は保証）。永続的な保存ではないため、長く残したいものは別途 obsidian-log 等の外部ログに逃がす

**handoff.md（Claude ↔ Codex の引き継ぎ）:**

Claude で行き詰まったら Codex へ、Codex で行き詰まったら Claude へ渡す往復のために、`/context-save` は `<project-root>/.claude/handoff.md` を**毎回**書き出す（`/context-load` が読んで冒頭に提示する）。両者は同じ working tree を共有しているため転送は発生せず、操作は「片方で save → もう片方で load」の 2 つだけで済む。

- **なぜ context.md と分けるか**: `## 進行中の作業` は「何を成したか」の完了要約で、引き継ぎで相手が本当に必要とする「**試して駄目だったこと**（negative results）・現在の仮説・再現手順」を置く場所がない。かつこれらは揮発情報なので、恒久ファイルに混ぜるとローテーション対象の判断が増える
- **1 件だけを保持する揮発ファイル**（毎回 全面上書き）。相手 writer の handoff を上書きする場合は、末尾に `> 前の引き継ぎ（from: ..., at: ...）` の 1 行だけ痕跡を残す
- `from` / `at` / `topic` の frontmatter を持ち、読み手は `from` で「自分が書いたもの」と「相手からの引き継ぎ」を区別する。消化状態（`status`）は**持たない**（読み手の `/context-load` は読取専用で書き戻せず、状態を持たせると必ず腐るため）
- `.chezmoiignore` 対象（`context.md` / `tasks.md` と同じく高頻度更新のため chezmoi 管理外）

**ホームワークスペースでの使い方:**

`~/.claude/context.md` の `## 関連リポジトリ` セクションに chezmoi 側の直近コミットを埋め込むことで、ホームワークスペース側から dotfiles の履歴も追えるようにしている。

**使いどころ:**

| コマンド | 使う場面 |
|----------|----------|
| `/context-save` | セッションの区切り、作業中断前 |
| `/context-load` | プロジェクト再開時。直近の状態・判断を思い出したいとき |
| `/session-save` | 区切りをまとめて：作業ログ（Obsidian） + コンテキスト保存 + ブログ/リソース提案 |

**注意点:**

- 相対パスで記録する（マシン非依存にするため）
- PR 番号・Issue 番号だけでは次回誤認しやすいので、ブランチ名・タイトル・最終確認日もセットで記録する

## 作業ログ・メモを Obsidian に記録・配信する (/obsidian-*)

Claude Code の作業内容を Obsidian Vault に自動・手動で記録する仕組み。作業ログ（`/obsidian-log`）、調査メモ・参考リンク・ブログドラフト（`/obsidian-resource`）、デイリーサマリー生成（`/obsidian-daily`）を Vault 内に Markdown で保存し、Obsidian のタグやリンク機能で後から振り返れる。さらに生成済みデイリーサマリーを Gmail で日報・週報として配信する `/obsidian-mail` も用意している。

**セットアップ:**

Vault パスは `~/ObsidianVault` 固定。WSL では Windows 側の Vault へのシンボリックリンクでも可。

```bash
# WSL: Windows 側の Vault を使う例
ln -s /mnt/c/Users/<username>/ObsidianVault ~/ObsidianVault

# macOS: iCloud Drive の Vault を使う例
ln -s "/Users/<username>/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault" ~/ObsidianVault
```

Vault が未配置でも `chezmoi apply` は警告を出して継続するが、`/obsidian-*` スキルは実行時に Vault 不在を検出して中断する。

**使いどころ:**

| コマンド | 使う場面 |
|----------|----------|
| `/obsidian-log` | 作業履歴を記録。セッションの区切りに。「今日の作業を記録して」 |
| `/obsidian-resource` | 調査メモ・参考リンク・ブログドラフトを保存。「この調査結果をメモして」「ブログ書いて」。引数 `auto` でセッション内容から自動ドラフト化 |
| `/obsidian-daily` | デイリーサマリーを生成（KPI 行・リポ別コミットグルーピング・作業ログ折り畳み callout）。複数 GH アカウント (`fantatchi` + `kentem-at-kato`) 対応。Obsidian Core Daily notes テンプレを SSOT として動的読み込み、Thino との共存に `# Journal` セクション前提。「今日のまとめ」「デイリーサマリー」 |
| `/obsidian-mail` | デイリーサマリーをメール送信（Gmail SMTP）。「日報メールして」「週報メール送って」。`disable-model-invocation: true` で自動発火しないため `/obsidian-mail daily\|weekly [YYYY-MM-DD]` で明示呼び出し。火〜土 8:00（daily）/ 月 8:00（weekly）の **ローカル routine** から呼ぶ前提（リモート routine は Vault に到達できない） |

**自動記録:**

コンテキストが圧縮される直前に、Claude が未記録の作業内容を自動で `/obsidian-log` に記録する。長いセッションでもログが漏れない。

**保存先フォルダ（自動作成される）:**

| フォルダ | 内容 |
|----------|------|
| `20_log/` | 作業履歴 |
| `30_resource/` | 調査メモ・参考リンク・ブログドラフト |
| `10_daily/` | デイリーサマリー（`/obsidian-daily` で生成） |

## 環境セットアップの注意点（Windows / WSL）

新しい PC（特に Windows / WSL 環境）に dotfiles を展開する際に踏みやすい落とし穴と回避策。

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

`.chezmoiscripts/*.ps1.tmpl` は `.chezmoi.os == "windows"` の分岐で
Windows 側で chezmoi を実行したときのみ評価されるため、上記の WSL 実行
前提では発火しない（別環境・将来の拡張用）。

## Codex 設定を他 PC に展開する

Codex は、設定全体を共有せず、作業規約とユーザー Skill だけを chezmoi で共有する。認証情報やセッションなどの PC 固有データを誤って持ち込まないためである。

### 共有するもの・しないもの

| 区分 | 対象 | 扱い |
| --- | --- | --- |
| 共有 | `~/.codex/AGENTS.md` | chezmoi で配備 |
| 共有 | `~/.agents/skills/` の全ユーザー Skill | chezmoi で配備。Codex のユーザー Skill 正規探索先 |
| 共有 | `~/.codex/scripts/setup-windows-codex.ps1` | Windows 側リンク作成用 |
| ローカル | `~/.codex/config*`、認証情報、セッション、ログ、キャッシュ、SQLite | chezmoi 管理外 |
| ローカル | `~/.codex/skills/.system/` | Codex が OS ごとに提供・管理するため共有しない |

### WSL または Linux の初期化

1. [クイックスタート](#クイックスタート) の手順で chezmoi を初期化する。
2. Codex をインストールして一度起動し、PC 固有の `.codex` を作成する。
3. `~/.agents/skills/` と `~/.codex/AGENTS.md` が存在することを確認する。

```bash
test -f ~/.codex/AGENTS.md
find ~/.agents/skills -name SKILL.md -print
```

以降、共有設定を更新したら WSL/Linux 側で `chezmoi update` を実行する。

### Windows の初期化（WSL と同じ設定を利用する場合）

Windows 版 Codex も使う場合は、まず WSL 側の初期化を完了してから、**Windows PowerShell** で次を実行する。管理者権限または Windows の開発者モードが必要になる場合がある。

```powershell
& "\\wsl.localhost\Ubuntu\home\<wsl-user>\.codex\scripts\setup-windows-codex.ps1"
```

`Ubuntu` と `<wsl-user>` は実際のディストリビューション名・WSL ユーザー名に置き換える。別のディストリビューションを使う場合は、引数でも指定できる。

```powershell
& "\\wsl.localhost\<distro>\home\<wsl-user>\.codex\scripts\setup-windows-codex.ps1" -Distro <distro>
```

このスクリプトは Windows 側の `.codex` と `.agents` を実体ディレクトリのまま維持し、次だけを WSL 側へ個別シンボリックリンクとして作成する。

- `%USERPROFILE%\.codex\AGENTS.md`
- `%USERPROFILE%\.agents\skills\` 配下の全ユーザー Skill ディレクトリ（`SKILL.md` があるものを自動検出）

既存のファイルやリンク先が期待と異なる場合、スクリプトは削除・上書きせず停止する。必要なら対象を手動で退避してから、再実行する。

Windows 側では `chezmoi apply` を実行しない。共有ファイルの更新・配備は WSL 側の chezmoi だけで行い、Windows 側は上記のリンクを通じて参照する。

### Windows セットアップ時の注意

新しい Windows 環境では、CurrentUser の PowerShell 実行ポリシーを
`RemoteSigned` に変更しておくこと。デフォルトの `Restricted` のままだと
Claude Code の Stop hook（BurntToast トースト通知）が起動しない。

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---
name: obsidian-resource
description: 調査メモ・参考リンク・ブログドラフトを Obsidian Vault に保存する。「調査結果をメモして」「参考リンクを記録」「ブログ書いて」「記事のドラフト作って」「この作業をブログにまとめて」といった依頼で使う。セッション内容からの自動ドラフト化（引数 `auto`）にも対応。
argument-hint: [タグ... | auto]
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Bash(echo:*), Bash(mkdir:*), Bash(date:*)
---

# リソース・ブログドラフトの記録

Claude との作業内容・調べた内容・参考リソースを Obsidian Vault に記録する。
frontmatter を Hugo 公開可能な形にしてあるため、後からそのままブログ化しやすい。

## 書き出し先・ファイル名

`~/.claude/skills/shared/vault-init.md` の手順に従うこと（サブディレクトリ名は `30_resource`）。タイトル部分は内容を簡潔に表す名前にする。

## 引数の扱い

$ARGUMENTS で分岐する。

### 引数が `auto` の場合 — セッション内容から自動ドラフト化

1. セッションの作業内容を振り返る
2. 記事・メモになりそうなトピックを特定する
3. 対話なしにドラフトを生成して保存する
4. 「ドラフトを作成しました: （ファイル名）」と通知する

### 引数がタグ指定の場合 — タグを付与して記録

- スペース区切りでそれぞれを tags に追加する
- 例: `/obsidian-resource api auth` → tags: claude-resource, api, auth, ...
- 記録する内容がセッション内に明確にある場合はそのまま保存、不明確な場合は内容・タイトル案を提示して確認を取る

### 引数なしの場合 — 内容をもとに自動タグで記録

- `claude-resource` と自動生成タグのみで記録する（「タグの自動生成」ルールに従い、`claude-resource` を除いて最大 5 個）
- 引数に `auto` を指定するとセッション内容からドラフトを自動生成できる旨を 1 行案内する

## 出力フォーマット

`./template.md` のフォーマットに従う。

### frontmatter

- `title`: 記事タイトル（内容から生成）
- `date`: 作成日
- `tags`: 3〜5 個。引数タグ＋自動生成タグ（`claude-resource` は常に含める、5 個カウントには含めない）
- `categories`: 1 つ。`~/.claude/skills/obsidian-resource/references/categories.md` から選ぶ。該当なしなら新規追加して一覧も更新する
- `draft: true`: 常に付与（Hugo 公開時に手動で false に切り替える）
- `source` / `generation` / `summary_of`: 再帰要約劣化対策メタ。引数モードで出し分ける:
  - **手動 / 引数あり / 引数なし**: `source: claude-resource`, `generation: 0`（一次資料相当）。`summary_of` は付けない
  - **`auto` モード**: `source: claude-summary`, `generation: 1`, `summary_of: ["[[元 session-log の wiki-link]]", ...]`（セッションログの要約なので要約扱い）。元 session-log が `~/ObsidianVault/20_log/` に存在する場合はその basename を `[[...]]` で並べる。存在しない場合は `summary_of: ["session"]` のような汎用ラベル 1 件で OK

### タグの自動生成

引数タグに加え、内容から関連タグを自動生成して追加する。

- 技術領域（例: typescript, react, aws, docker）
- 情報の種類（例: tutorial, reference, comparison, troubleshooting）
- 対象トピック（例: api, database, security, performance）

ルール:
- `claude-resource` は常に含める（5 個カウントに含めない）
- 引数タグ＋自動生成タグの合計が最大 5 個になるようにする
- 引数タグを優先し、残り枠を自動生成で埋める

### 本文の書き方

- 後から読み返して（または Hugo で公開して）理解できるよう、文脈を含めて書く
- コード例は言語指定付きのコードブロックを使う
- 長い内容は見出しで構造化する
- 公式ドキュメント・URL 等の情報源は参考リンクに記載
- トーン: カジュアルで読みやすい。幅広いエンジニアを読者に想定
- Hugo 用なので標準 Markdown のみ（ショートコードは使わない）

推奨構成（内容に応じて調整可）:
- 概要: 1〜2 行で何についての情報か
- 内容: 調査結果・解説・コード例・手順
- 参考リンク: 情報源があれば
- 関連メモ: Vault 内の関連ノートへのリンクがあれば

## 注意事項

- ユーザーが記録を依頼した内容を整理して書くこと
- 書き出し先ディレクトリが存在しない場合は作成すること
- 既存ファイルがある場合は上書きせず確認する
- ファイル書き込みは Write ツールで直書きする（書き出し用の補助スクリプトは持たない。テンプレ展開・frontmatter 組み立てを Claude 自身が行う設計）
- Hugo 公開は別途 Hugo リポジトリへのコピー・リンク設定が必要。本スキルは ObsidianVault への下書き保存のみを担う
- すべてのリソースは `30_resource/` に保存する。過去のブログドラフト 15 件は `30_resource/blog/` サブフォルダに集約（旧 `_claude/blog/` を移動）
- 既存 resource ファイル 39 件は旧形式（`title` / `categories` / `draft` なし）と混在する。Dataview 等でクエリする場合は `WHERE file.frontmatter.categories != null` のようにガードを入れる

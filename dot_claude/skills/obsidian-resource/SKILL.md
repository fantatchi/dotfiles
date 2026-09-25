---
name: obsidian-resource
description: '調査メモ・参考リンク・ブログドラフトを Obsidian Vault に保存する。「調査結果をメモして」「参考リンクを記録」「ブログ書いて」「記事のドラフト作って」「この作業をブログにまとめて」といった依頼で使う。セッション内容からの自動ドラフト化（引数 `auto`）にも対応。'
argument-hint: '[タグ... | auto]'
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Bash(echo:*), Bash(mkdir:*), Bash(date:*)
---

# リソース・ブログドラフトの記録

frontmatter を Hugo 公開可能な形にしてあるため、後からそのままブログ化しやすい。

**主資源と連携**: Vault パスは resolver `~/.claude/skills/shared/integrations.md` の `vault` から `vault-init.md` 経由で解決する。Vault が無い環境では `vault-init.md` 1 節の案内で終了する（standalone フォールバックは無い）。

## 書き出し先・ファイル名

`~/.claude/skills/shared/vault-init.md` の手順に従うこと（サブディレクトリ名は resolver `vault_dirs.resource`、既定 `30_resource`）。タイトル部分は内容を簡潔に表す名前にする。

## 引数の扱い

$ARGUMENTS で分岐する。

### 引数が `auto` の場合 — セッション内容から自動ドラフト化

セッション内容から記事・メモになりそうなトピックを特定し、対話なしにドラフトを生成・保存して「ドラフトを作成しました: （ファイル名）」と通知する。

### 引数がタグ指定の場合 — タグを付与して記録

- スペース区切りでそれぞれを tags に追加する
- 例: `/obsidian-resource api auth` → tags: claude-resource, api, auth, ...
- 記録する内容がセッション内に明確にある場合はそのまま保存、不明確な場合は内容・タイトル案を提示して確認を取る

### 引数なしの場合 — 内容をもとに自動タグで記録

- `claude-resource` と自動生成タグのみで記録する
- 引数に `auto` を指定するとセッション内容からドラフトを自動生成できる旨を 1 行案内する

## 出力フォーマット

`./template.md` のフォーマットに従う。

### frontmatter

- `title`: 記事タイトル（内容から生成）
- `date`: 作成日
- `tags`: 「タグの自動生成」のルールに従う
- `categories`: 1 つ。`~/.claude/skills/obsidian-resource/references/categories.md` から選ぶ。該当なしなら新規追加して一覧も更新する
- `draft: true`: 常に付与（Hugo 公開時に手動で false に切り替える）
- `source` / `generation` / `summary_of`: 再帰要約劣化対策メタ。引数モードで出し分ける:
  - **手動 / 引数あり / 引数なし**: `source: claude-resource`, `generation: 0`（一次資料相当）。`summary_of` は付けない
  - **`auto` モード**: `source: claude-summary`, `generation: 1`, `summary_of: ["[[元 session-log の wiki-link]]", ...]`（セッションログの要約なので要約扱い）。元 session-log が `<vault>/<vault_dirs.log>/` に存在する場合はその basename を `[[...]]` で並べる。存在しない場合は `summary_of: ["session"]` のような汎用ラベル 1 件で OK

### タグの自動生成

`claude-resource` は常に含め（数に入れない）、引数タグ＋自動生成タグの合計を最大 5 個にする。引数タグを優先し、残り枠を技術領域・情報の種類・対象トピックから自動生成で埋める。

### 本文の書き方

- トーン: カジュアルで読みやすい。幅広いエンジニアを読者に想定
- Hugo 用なので標準 Markdown のみ（ショートコードは使わない）
- **文章規範は `japanese-article-style` スキルに従う**。本文の見出しは記事ごとに決め、定型の骨格（「概要 / 内容」）を持たない。末尾の `参考リンク` と `関連メモ` だけは、あれば付ける

## 注意事項

- 既存ファイルがある場合は上書きせず確認する
- Hugo 公開は別途 Hugo リポジトリへのコピー・リンク設定が必要。本スキルは Vault への下書き保存のみを担う
- ブログドラフトと通常リソースを物理的に分離せず、frontmatter の `categories` / `tags` で区別する
- 既存 resource ファイルには旧形式（`title` / `categories` / `draft` なし）が混在する。Dataview 等でクエリする場合は `WHERE file.frontmatter.categories != null` のようにガードを入れる

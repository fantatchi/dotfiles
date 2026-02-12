---
name: knowledge-search
description: Obsidian Vault内のClaudeナレッジ（ログ・リソース・コンテキスト・ブログ下書き）を横断検索する。
argument-hint: <query>
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(echo *), Bash(ls *)
---

# ナレッジ検索

Obsidian Vault 内の Claude ナレッジを横断検索する。

## 検索対象ディレクトリ

`$OBSIDIAN_VAULT/` 配下の以下のディレクトリを検索する：

- `_Claude/log/` — 作業ログ
- `_Claude/resource/` — 調査・参考資料
- `_Claude/blog/` — ブログ下書き

※ **必ず `echo "${OBSIDIAN_VAULT/#\~/$HOME}"` で実パスを取得**すること（チルダが `$HOME` に展開される）。

## クエリの解釈

`$ARGUMENTS` をクエリとして受け取る。以下の種別を判定して処理する：

### キーワード検索

通常のテキスト（例: `typescript`, `認証`, `API設計`）

→ Grep でファイル内容を検索 + Glob でファイル名を検索

### タグ検索

`#` で始まるクエリ（例: `#bugfix`, `#react`）

→ frontmatter の `tags:` セクションと本文中の `#tag` をGrepで検索

### プロジェクト検索

`project:` で始まるクエリ（例: `project:ict-pf`）

→ frontmatter の `project:` フィールドを Grep で検索

### 日付検索

`since:` で始まるクエリ（例: `since:2025-01-01`）

→ frontmatter の `date:` / `updated:` フィールドとファイル名のタイムスタンプで絞り込み

### 複合検索

上記を組み合わせたクエリ（例: `typescript project:ict-pf since:2025-06-01`）

→ 各条件を AND で結合

## 検索の実装

1. まず Grep で `files_with_matches` モードを使い、マッチするファイルを特定
2. 複合条件の場合は、各条件の結果の共通部分を取る
3. マッチしたファイルの frontmatter と周辺コンテキストを Read で取得

## 結果の提示

上位 10 件を以下の形式で整理して提示する：

```
## 検索結果: {query}

{N} 件見つかりました（対象: _Claude/log, _Claude/resource, _Claude/blog）

### 1. {ファイル名}
- **種別**: ログ / リソース / ブログ
- **日付**: YYYY-MM-DD
- **タグ**: #tag1, #tag2
- **概要**: （ファイルの概要セクションまたはマッチ箇所の抜粋）

---

### 2. {ファイル名}
...
```

### 並び順

- 関連性が高い順（マッチ箇所が多いもの優先）
- 同程度の場合は新しいもの優先（タイムスタンプ降順）

## クエリが空の場合

引数がない場合は、使い方を案内する：

```
使い方:
  /knowledge-search <キーワード>       — キーワードで検索
  /knowledge-search #tag              — タグで検索
  /knowledge-search project:name      — プロジェクトで検索
  /knowledge-search since:YYYY-MM-DD  — 日付で絞り込み
  /knowledge-search keyword #tag project:name  — 複合検索
```

## 注意事項

- 大量のファイルを一度に Read しないこと（上位 10 件まで）
- 検索結果が 0 件の場合は、類似のキーワードや別の検索方法を提案する
- ファイルの全文を表示しない。概要とマッチ箇所の抜粋に留める

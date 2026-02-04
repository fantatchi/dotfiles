---
name: obs-resource
description: リソース・調査結果の記録
---

# リソース・調査結果の記録

Claude に調べてもらった内容や、参考になるリソースを Obsidian Vault に記録してください。

## 書き出し先

`$OBSIDIAN_VAULT/_ClaudeResources/`

※ 環境変数 `OBSIDIAN_VAULT` が設定されていない場合はエラーを表示し、設定方法を案内すること。

## ファイル名

`YYYY-MM-DD_HHmm_簡潔なタイトル.md`（日本語OK、スペースはハイフンに置換）

## 引数の扱い

$ARGUMENTS が渡される。

- スペース区切りでそれぞれを tags に追加する
- 例: `/obs-resource api auth` → tags: claude-resource, api, auth, ...
- 引数が空の場合は `claude-resource` のみ＋自動生成タグ

## タグの自動生成

引数のタグに加え、内容から関連タグを自動生成して追加する。

- 技術領域（例: typescript, react, aws, docker）
- 情報の種類（例: tutorial, reference, comparison, troubleshooting）
- 対象トピック（例: api, database, security, performance）

ルール：
- `claude-resource` は常に含める
- 引数タグ＋自動生成タグの合計が最大5個になるようにする（claude-resource は数に含めない）
- 引数タグを優先し、残り枠を自動生成で埋める

## 出力フォーマット

以下のフォーマットで書き出すこと：

```
---
tags:
  - claude-resource
  - （自動生成タグ・引数タグをここに追加）
date: YYYY-MM-DD
source: claude
---

## 概要

（1-2行で何についての情報か）

## 内容

（調査結果・説明をここに記載）

## 参考リンク

- （あれば。なければこのセクションごと省略）

## 関連メモ

- （Vault 内の関連メモがあれば。なければこのセクションごと省略）
```

### 内容の書き方ルール

- 後から読み返して理解できるよう、文脈を含めて書く
- コード例がある場合は適切な言語でコードブロックを使用
- 長い内容は見出しで構造化する
- 情報源（公式ドキュメント、URL等）があれば参考リンクに記載

## 注意事項

- ユーザーが記録を依頼した内容を整理して書くこと
- 書き出し先ディレクトリが存在しない場合は作成すること

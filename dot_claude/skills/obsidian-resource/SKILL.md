---
name: obsidian-resource
description: 調べた内容・参考リンク・技術メモなどをObsidian Vaultに保存する。「調査結果をメモして」「この情報を保存して」「参考リンクを記録」といった依頼で使う。
argument-hint: [タグ...]
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Bash(mkdir *)
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
- 例: `/obsidian-resource api auth` → tags: claude-resource, api, auth, ...
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

`./template.md` のフォーマットに従って書き出すこと。

### 内容の書き方ルール

- 後から読み返して理解できるよう、文脈を含めて書く
- コード例がある場合は適切な言語でコードブロックを使用
- 長い内容は見出しで構造化する
- 情報源（公式ドキュメント、URL等）があれば参考リンクに記載

## 注意事項

- ユーザーが記録を依頼した内容を整理して書くこと
- 書き出し先ディレクトリが存在しない場合は作成すること

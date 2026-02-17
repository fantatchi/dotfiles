---
name: obsidian-log
description: セッション中の作業内容をObsidian Vaultに記録する。「作業ログを書いて」「今日の作業を記録」といった依頼で使う。
argument-hint: [タグ...]
allowed-tools: Read, Write, Glob, Bash(echo *), Bash(mkdir *), Bash(date *)
---

# 作業履歴の記録

今回のセッションで行った作業を振り返り、Obsidian Vaultに記録を残してください。

## 書き出し先

設定ファイル `$HOME/.claude/config.json` の `obsidian_vault` の値を Vault パスとして使う。

パスの取得手順:
1. `$HOME/.claude/config.json` を Read ツールで読み込む
2. JSON から `obsidian_vault` の値を取得する（値は絶対パス）
3. `{obsidian_vault}/_claude/log/YYYYMM/` に書き出す（YYYYMM は現在の年月、例: 202602）

※ `obsidian_vault` キーが存在しない場合は以下を案内して終了：

```
obsidian_vault が設定されていません。
~/.claude/config.json に以下を追加してください：

  "obsidian_vault": "/path/to/vault"

chezmoi を使っている場合は `chezmoi init` で設定できます。
```

※ パスの推測・ハードコード禁止。
※ ディレクトリが存在しなければ `mkdir -p` で作成すること。

## ファイル名

`YYYYMMDDHHmmss_簡潔な作業概要.md`

※ タイムスタンプは **`date +%Y%m%d%H%M%S` で取得**すること（`HHmmss` まで必須）。
（日本語OK、スペースはハイフンに置換）

## 引数の扱い

$ARGUMENTS が渡される。

- スペース区切りでそれぞれを tags に追加する
- 例: `/obsidian-log backend auth` → tags: claude-log, backend, auth, ...
- 引数が空の場合は `claude-log` のみ＋自動生成タグ

## タグの自動生成

引数のタグに加え、作業内容から関連タグを自動生成して追加する。

- 使用した言語・フレームワーク（例: typescript, react, python）
- 作業の種類（例: bugfix, refactor, feature, docs, config）
- 対象領域（例: api, ui, db, auth, test）

ルール：
- `claude-log` は常に含める
- 引数タグ＋自動生成タグの合計が最大5個になるようにする（claude-log は数に含めない）
- 引数タグを優先し、残り枠を自動生成で埋める

## 出力フォーマット

`./template.md` のフォーマットに従って書き出すこと。

### 対話記録の書き方ルール

- ユーザーの指示は `> **指示**:` で始め、ブロック引用で囲む
- 指示は正確な原文でなくてよい。意図が伝わる要約で十分
- 1つの指示とそれに対する対応を1つの `### #N` にまとめる
- 各ペアのタイトルは「何についてのやり取りか」を簡潔に
- 「方針」は判断を伴う場合のみ。単純作業では省略可
- 「判断メモ」は後から読んで理由がわかるように書く
- ペア間は水平線（---）で区切る
- 雑談や短い確認のやり取りは1つのペアにまとめてよい
- ファイルパスはバッククォートで囲む
- エラーや試行錯誤もそのまま書く

## 注意事項

- セッション全体を振り返ってから書くこと
- diffの羅列ではなく、人間が後から読んで文脈がわかるように書くこと
- 書き出し先ディレクトリが存在しない場合は作成すること
- frontmatter の `files_changed` はセッション中に変更したファイル数を数えて記入すること（`git status --short | wc -l` 等で取得）

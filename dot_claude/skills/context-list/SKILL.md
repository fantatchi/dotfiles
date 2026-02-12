---
name: context-list
description: 保存済みコンテキストの一覧を表示する。
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(ls *)
---

# コンテキスト一覧

保存済みコンテキストの一覧を表示する。

## データソース

`$HOME/.claude/context/*.md`

## 処理フロー

### 1. コンテキストファイルの取得

`$HOME/.claude/context/` 内の `.md` ファイルを Glob で取得する。
ファイルが 0 件の場合は「保存済みコンテキストがありません」と案内して終了。

### 2. frontmatter の読み取り

各ファイルの frontmatter から以下を読み取る：

- `project`: プロジェクト識別子
- `updated`: 最終更新日時
- `branch`: ブランチ名

### 3. 一覧の表示

`updated` の新しい順に以下の形式で表示する：

```
## コンテキスト一覧

| プロジェクト | 最終更新 | ブランチ |
|---|---|---|
| dotfiles | 2026-02-12 11:11 | master |
| ict-pf | 2026-02-10 15:41 | — |
```

## 注意事項

- 読み込み専用。ファイルを変更しない

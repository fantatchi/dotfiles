---
name: context-list
description: 管理中のプロジェクトとコンテキストの保存状態を一覧表示する。
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(printenv *), Bash(ls *)
---

# コンテキスト一覧

管理中のプロジェクトとコンテキストの保存状態を一覧表示する。

## データソース

1. **プロジェクト一覧**: `~/CLAUDE.local.md` のプロジェクト一覧テーブル
2. **コンテキストファイル**: `$OBSIDIAN_VAULT/_ClaudeContext/*.md`

※ **必ず `printenv OBSIDIAN_VAULT` で実パスを取得**すること。

## 処理フロー

### 1. プロジェクト一覧の取得

`~/CLAUDE.local.md` を読み込み、プロジェクト一覧テーブルをパースする。
ファイルが存在しない場合は「`~/CLAUDE.local.md` が見つかりません。`/workspace-init` で初期化してください」と案内して終了。

### 2. コンテキストファイルの照合

各プロジェクトについて `_ClaudeContext/{project-name}.md` の存在を確認する。
存在する場合は frontmatter から以下を読み取る：

- `updated`: 最終更新日時
- `branch`: ブランチ名

### 3. 一覧の表示

以下の形式で表示する：

```
## コンテキスト一覧

| プロジェクト | コンテキスト | 最終更新 | ブランチ |
|---|---|---|---|
| ict-pf | ✓ | 2025-02-10 15:30 | feature/xxx |
| cloud-education-syllabus | — | — | — |
```

## 注意事項

- 読み込み専用。ファイルを変更しない
- `OBSIDIAN_VAULT` が未設定の場合は案内して終了

---
name: session-review
description: セッション完了時に振り返りを行い、権限追加・CLAUDE.md更新・スキル洗練を一括で行う。**手動で `/session-review` を実行して発動**（`disable-model-invocation: true` で自動起動しない）。
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Glob, Grep
---

# Session Review: セッション完了時の一括整理

タスク完了時にセッション中の作業を振り返り、3つの観点で環境を整理する。
各フェーズはセッション内容に応じて必要なものだけ実行する。

## 実行手順

### Step 1: 全フェーズの判定と提案の収集

会話コンテキスト全体を振り返り、以下の3フェーズそれぞれについて実行要否を判定する。
該当するフェーズは `references/` の詳細手順を `Read` で読み込み、提案内容を収集する。

| フェーズ | 実行条件 | 詳細手順 |
|---------|---------|---------|
| 1. 権限レビュー | 手動で承認/拒否したツール呼び出しが1件以上 | `references/permission-review.md` |
| 2. CLAUDE.md更新 | コマンド・パターン・設定の発見やgotchaがあった | `references/claude-md-update.md`（実作業は `/claude-md-management:revise-claude-md` スキルに委譲する） |
| 3. スキル洗練 | 既存スキルの不備発見、繰り返しワークフロー、新スキル候補 | `references/skill-refine.md` |

### Step 2: 提案の一括提示

全フェーズの提案をまとめて1回で提示する:

```
Session Review

Phase 1: 権限レビュー
  - "Edit" を permissions.allow に追加
  - "Bash(gh:*)" を permissions.allow に追加

Phase 2: CLAUDE.md更新 → スキップ（新しい知見なし）

Phase 3: スキル洗練
  - session-save の description に「振り返り」を追加

適用する項目を選んでください（全部 / 一部 / スキップ）
```

### Step 3: 適用

ユーザーの選択に従い、承認された項目のみ適用する。

## 共通ルール

- **確認は1回だけ**。フェーズごとに個別確認しない
- ユーザー確認なしに変更を適用しない
- 「スキップ」の判断理由を簡潔に説明する
- セッション中にユーザーが明示的に「これは一時的」と述べた承認は権限追加候補から除外する
- 機密情報（APIキー、パスワード等）をCLAUDE.mdやスキルに含めない
- ユーザーが「不要」と言った項目は即座にスキップする

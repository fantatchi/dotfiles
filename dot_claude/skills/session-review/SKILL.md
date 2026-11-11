---
name: session-review
description: 'セッション完了時に振り返り、CLAUDE.md 更新・スキル洗練を一括で提案・適用する。手動 `/session-review` 専用（自動起動しない）。権限・判断メモ・memory・スキルの棚卸しは週次点検 `/harness-audit` の担当。'
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Glob, Grep
---

# Session Review: セッション完了時の振り返り

タスク完了時にセッション中の作業を振り返り、そのセッションで得たものを環境へ戻す。
周期で回す点検（CLAUDE.md 全体の監査・memory の陳腐化・スキルの利用実績・判断メモ圧縮）は `/harness-audit` の担当で、ここでは扱わない。判断メモの肥大警告が出ているなら `/harness-audit memo` を案内する。

2026-11-11 に権限レビュー（auto mode と `/fewer-permission-prompts` で足りる）と判断メモ圧縮（harness-audit へ移して自動適用化）を外した。

## 実行手順

### Step 1: フェーズの判定と提案の収集

会話全体を振り返り、次の 2 フェーズそれぞれの要否を判定する。
該当するフェーズは `references/` の詳細手順を `Read` で読み込み、提案内容を集める。

| フェーズ | 実行条件 | 詳細手順 |
|---------|---------|---------|
| 1. CLAUDE.md 更新 | コマンド・パターン・設定の発見や gotcha があった | `references/claude-md-update.md`（実作業は `/claude-md-management:revise-claude-md` スキルに委譲する） |
| 2. スキル洗練 | 既存スキルの不備発見、繰り返しワークフロー、新スキル候補 | `references/skill-refine.md` |

### Step 2: 提案の一括提示

両フェーズの提案をまとめて 1 回で提示する:

```
Session Review

Phase 1: CLAUDE.md 更新 → スキップ（新しい知見なし）

Phase 2: スキル洗練
  - session-save の description に「振り返り」を追加

適用する項目を選んでください（全部 / 一部 / スキップ）
```

### Step 3: 適用

ユーザーの選択に従い、承認された項目だけを適用する。

## 共通ルール

- **確認は 1 回だけ**。フェーズごとに個別に確認しない

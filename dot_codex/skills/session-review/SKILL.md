---
name: session-review
description: セッション完了時に Codex の承認・AGENTS.md・ユーザー作成 Skill・共有 context.md を振り返り、改善案を一括提示する。「セッションレビュー」「今回の作業を振り返って」「設定や Skill の改善点を確認して」と明示されたときに使う。変更は提案に留め、ユーザーが選んだ項目だけ適用する。
---

# Session Review: セッション完了時の一括整理

タスク完了時にセッション中の作業を振り返り、3つの観点で環境を整理する。
各フェーズはセッション内容に応じて必要なものだけ実行する。

## 実行手順

### Step 1: 全フェーズの判定と提案の収集

会話コンテキスト全体を振り返り、以下の4フェーズそれぞれについて実行要否を判定する。
該当するフェーズは `references/` の詳細手順を読み込み、提案内容を収集する。

| フェーズ | 実行条件 | 詳細手順 |
|---------|---------|---------|
| 1. 権限レビュー | 手動で承認/拒否したツール呼び出しが1件以上 | `references/permission-review.md` |
| 2. AGENTS.md 更新 | コマンド・パターン・設定の発見や gotcha があった | `references/claude-md-update.md` |
| 3. スキル洗練 | 既存スキルの不備発見、繰り返しワークフロー、新スキル候補 | `references/skill-refine.md` |
| 4. 判断メモ圧縮 | resolver `memory_promotion` が `on`（既定）かつ、context.md の `## 判断メモ` が肥大（context-save が「15件超」とアラート）/ セッションで普遍知見が生まれた | `references/memo-compaction.md` |

**連携 gate（判断メモ圧縮）**: Phase 4 は MEMORY.md への昇格が本体なので、resolver `~/.claude/skills/shared/integrations.md` の bool キー `memory_promotion` で gate する（context-save の連携3 と同じキー）。`memory_promotion` が `off` / 未設定 / resolver 不在なら Phase 4 を判定せず skip し、Step 2 で「Phase 4: 判断メモ圧縮 → スキップ（memory_promotion off）」と明示する。Phase 1〜3 は外部依存のない project-local / 環境整備なので gate しない（常に判定する）。

### Step 2: 提案の一括提示

全フェーズの提案をまとめて1回で提示する:

```
Session Review

Phase 1: 権限レビュー
  - 一時承認だったネットワーク操作は恒久許可にしない
  - 読取コマンドの承認範囲を対象サブコマンドまでに限定する

Phase 2: AGENTS.md 更新 → スキップ（新しい知見なし）

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
- 機密情報（API key、token、password 等）を AGENTS.md や Skill に含めない
- ユーザーが「不要」と言った項目は即座にスキップする
- `.claude/context.md` を編集する Phase 4 は `~/.claude/skills/shared/multi-writer.md` に従い、書込み直前の再読込、競合停止、最小編集、書込み後検証を行う

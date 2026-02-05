---
name: reviewing-skills
description: スキル（SKILL.md）を公式ベストプラクティスに基づいてレビューし、改善提案を行う。「スキルをレビューして」「SKILL.mdをチェックして」といった依頼で使う。
argument-hint: [スキル名またはパス]
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

# スキルレビュー

公式ベストプラクティスに基づいてスキルをレビューし、具体的な改善提案を行う。

## レビューワークフロー

### ステップ1: 対象スキルの特定

レビュー対象の SKILL.md ファイルを特定する：

- $ARGUMENTS でパスまたはスキル名が指定された場合はそれを使う
- 指定がなければ `.claude/skills/` 配下の全スキルを一覧し、ユーザーに確認
- 複数スキルの一括レビューも可能

### ステップ2: 読み込みと分析

1. 対象の SKILL.md ファイルを完全に読み込む
2. サポートファイル（template.md, examples/, references/ 等）があれば確認
3. [best-practices.md](references/best-practices.md) のチェックリストをロード
4. YAML フロントマターを解析
5. ボディコンテンツの構造を分析

### ステップ3: ベストプラクティスとの照合

`references/best-practices.md` の全チェック項目を評価し、各項目を Critical / Warning / Info に分類する。

### ステップ4: レビューレポート生成

以下の形式で出力：

```
# スキルレビューレポート: {skill-name}

## サマリー
- 総合評価: {PASS | NEEDS_IMPROVEMENT | CRITICAL_ISSUES}
- Critical: {件数}
- Warning: {件数}
- Info: {件数}

## Critical（必須修正）

| 項目 | 内容 |
|:---|:---|
| ... | ... |

## Warning（推奨修正）

| 項目 | 内容 |
|:---|:---|
| ... | ... |

## Info（改善提案）

| 項目 | 内容 |
|:---|:---|
| ... | ... |

## 優先度順アクションリスト

1. ...
2. ...
```

### ステップ5: インタラクティブな改善

レポート提示後：

1. ユーザーに修正を希望するか確認
2. Critical 問題を優先的に修正
3. 段階的に修正を適用
4. 各修正後にチェックリストで再検証

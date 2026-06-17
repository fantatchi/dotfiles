---
name: pr-review
description: GitHub プルリクエストのコードレビューを実行するスキル。「/pr-review {number}」コマンドで指定されたPRをチェックアウトし、ultrathinkモードで変更点を詳細にレビューする。PRの差分確認、コード品質チェック、潜在的な問題の指摘を行う。オプションで --post フラグを付けるとレビュー結果をGitHubにコメントとして投稿する。
---

# PR Review スキル

GitHub プルリクエストをチェックアウトしてコードレビューを実行する。

## トリガー

- `/pr-review {number}` - ローカルでレビュー結果を表示
- `/pr-review {number} --post` - レビュー結果をGitHubにコメントとして投稿
- `/pr-review {number} --post --request-changes` - 変更要求付きでレビューを投稿

## ワークフロー

### 1. PRをチェックアウト
```bash
gh pr checkout {number}
```

### 2. PR情報を取得
```bash
gh pr view {number} --json title,body,baseRefName,headRefName,files,additions,deletions,author
```

### 3. 差分を取得
```bash
gh pr diff {number}
```

### 4. ultrathinkでレビュー実行

以下の観点でレビューを行う:
- **変更の概要**: PRの目的と変更内容の要約
- **コード品質**: 可読性、保守性、設計パターン
- **潜在的なバグ**: エッジケース、null参照、型の問題
- **セキュリティ**: 入力検証、認証、機密情報の露出
- **パフォーマンス**: 非効率なアルゴリズム、N+1問題
- **テスト**: テストカバレッジ、テストケースの妥当性
- **ドキュメント**: コメント、README更新の必要性

### 5. レビュー結果を投稿（--post フラグ指定時）

#### 5a. PRコメントとして投稿（総合レビュー）
```bash
gh pr review {number} --body "{レビュー本文}" [--request-changes|--comment]
```

#### 5b. 特定行へのインラインコメント（オプション）
```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --method POST \
  -f body="{コメント内容}" \
  -f commit_id="{head_commit_sha}" \
  -f path="{ファイルパス}" \
  -f line={行番号} \
  -f side="RIGHT"
```

## 出力フォーマット
```markdown
## PR #{number}: {title}

### 概要
{PRの目的と変更内容の簡潔な説明}

### 良い点 ✅
- {ポジティブなフィードバック}

### 改善提案 💡
- {改善すべき点と具体的な提案}

### 要確認事項 ⚠️
- {確認が必要な問題や質問}

### 総評
{全体的な評価とマージ可否の判断}

---
🤖 *このレビューはClaude AIによって生成されました*
```

## インラインコメント用フォーマット

特定のコード行に対するコメントが必要な場合:
```json
{
  "inline_comments": [
    {
      "path": "src/example.ts",
      "line": 42,
      "body": "この条件分岐でnullチェックが漏れている可能性があります。\n\n```suggestion\nif (value != null && value.length > 0) {\n```"
    }
  ]
}
```

## レビューステータスの選択基準

| ステータス | 条件 |
|-----------|------|
| `--comment` | 通常のレビュー（デフォルト） |
| `--request-changes` | 修正必須の問題あり、再レビュー必要 |

## 使用例
```bash
# ローカルでレビュー結果を確認
/pr-review 123

# レビューコメントを投稿（コメントのみ）
/pr-review 123 --post

# 変更要求付きでレビューを投稿
/pr-review 123 --post --request-changes
```

## 注意事項

- `gh` CLI が認証済みであることを前提とする
- 大きなPRの場合はファイル単位でレビューを分割
- `--post` なしの場合はローカル表示のみ（GitHub に影響なし）
- インラインコメントは重要な指摘がある場合のみ使用
- レビュー投稿前に必ずユーザーに確認を取る

## 投稿前確認プロンプト

`--post` フラグ指定時は、投稿前に以下を表示して確認:
```
📝 以下の内容でGitHubにレビューを投稿します:
- ステータス: {COMMENT|REQUEST_CHANGES}
- インラインコメント: {件数}件

投稿してよろしいですか？ (y/N)
```
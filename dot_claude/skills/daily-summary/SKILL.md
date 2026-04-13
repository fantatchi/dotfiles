---
name: daily-summary
description: GitHub アクティビティと作業ログからデイリーサマリーを生成し、Obsidian デイリーノートに追記する。「今日のまとめ」「デイリーサマリー」といった依頼で使う。
argument-hint: [YYYY-MM-DD]
allowed-tools: Read, Bash(gh:*), Bash(date:*), Bash(python3:*), Bash(cat:*), Bash(ls:*), Bash(echo:*)
---

# デイリーサマリーの生成

その日の GitHub アクティビティと Obsidian 作業ログ（context-log）を収集し、デイリーノートにサマリーを追記する。

## 1. 対象日の決定

- `$ARGUMENTS` が `YYYY-MM-DD` 形式で指定されていればその日を対象とする
- 空の場合は `date +%Y-%m-%d` で今日の日付を取得する

以降、対象日を `TARGET_DATE`（例: `2026-03-31`）として参照する。
対象日から以下の変数も導出する:

- `YYYYMM` = `20260331` の先頭6文字 → `202603`
- `YYYYMMDD` = `20260331`

## 2. Vault パスの決定

Vault パスはユーザーホーム直下の `~/ObsidianVault` 固定。
WSL / Windows (Git Bash) いずれからも同じ相対パスで解決される。

1. `ls ~/ObsidianVault` で存在確認
2. 存在しなければ以下を案内して終了:

```
~/ObsidianVault が見つかりません。
ユーザーホーム直下に ObsidianVault を配置してください（WSL ではシンボリックリンクでも可）。
```

## 3. GitHub データ収集

`gh api` で以下の4つを取得する。それぞれ jq フィルターで必要なフィールドのみ抽出すること。

### 3a. コミット

```bash
gh api '/search/commits?q=author:kentem-at-kato+committer-date:TARGET_DATE&sort=committer-date&order=asc&per_page=100' \
  --header 'Accept: application/vnd.github.cloak-preview+json'
```

抽出: sha（先頭7文字）、コミットメッセージ（1行目のみ）、リポジトリ名（full_name）

※ `order=asc` で時系列順（古い→新しい）にソートする。

### 3b. PR（作成）

```bash
gh api '/search/issues?q=author:kentem-at-kato+type:pr+created:TARGET_DATE&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名、状態

### 3c. PR（マージ）

```bash
gh api '/search/issues?q=author:kentem-at-kato+type:pr+merged:TARGET_DATE&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名

### 3d. レビュー

```bash
gh api '/search/issues?q=reviewed-by:kentem-at-kato+type:pr+updated:TARGET_DATE&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名、状態

### エラー処理

- API がエラー（403 rate limit 等）を返した場合、該当セクションに「取得エラー」と記載してスキップする
- `total_count` が 0 の場合は「なし」と記載する

### PR の重複排除

同じ PR が作成・マージ・レビューの複数カテゴリに出る場合は、1つにまとめて labels にカテゴリを列挙する。

例: `labels: ["作成", "マージ"]`

## 4. context-log の収集

Bash の ls コマンドでファイル一覧を取得し、各ファイルを Read ツールで読む:

```bash
ls ~/ObsidianVault/_claude/log/{YYYYMM}/{YYYYMMDD}*.md 2>/dev/null
```

各ファイルから以下を抽出する:
1. frontmatter の `project` を取得
2. `## 概要` セクションのテキスト（1-2行）を取得

context-log が 0 件の場合は「作業ログの記録なし」とする。

## 4b. tasks.md からの予定タスク収集

`~/.claude/tasks.md` を Read で読み、`## Next` と `## Waiting` セクションのタスクを抽出する。

### 抽出ルール

- タスク行のフォーマット: `- [ ] #project/<name> タイトル [メタデータ]`
- 各タスクから以下を取り出す:
  - `section`: `"Next"` または `"Waiting"`
  - `project`: `#project/<name>` の `<name>` 部分（タグなしなら空文字）
  - `title`: タグとチェックボックスを除いた本文
- 全プロジェクト横断で収集する（フィルタなし）
- タスクが 0 件の場合、または tasks.md が存在しない場合は空配列 `[]` とする

### 注意

- **ユーザーに確認を求めない**。このスキルは自動実行される前提なので、収集結果をそのまま JSON に詰めて進む
- 読み込み専用。tasks.md は変更しない

## 5. サマリーデータの組み立て

収集したデータを以下の JSON 形式に組み立てる:

```json
{
  "vault": "/home/at-kato/ObsidianVault",
  "target_date": "2026-03-31",
  "commits": [
    {"sha": "a3d1f9f", "message": "コミットメッセージ", "repo": "owner/repo"}
  ],
  "prs": [
    {"title": "PR タイトル", "url": "https://...", "labels": ["作成", "マージ"]}
  ],
  "logs": [
    {"project": "project-name", "summary": "作業概要"}
  ],
  "upcoming_tasks": [
    {"section": "Next", "project": "claude-config", "title": "gtd-list スキルの実装"},
    {"section": "Waiting", "project": "mlit", "title": "APIキー発行待ち @since:2026-04-08"}
  ],
  "summary_text": "GitHub アクティビティと作業ログを総合した 1-3 行の自然言語サマリー"
}
```

- `commits`, `prs`, `logs`, `upcoming_tasks` が 0 件の場合は空配列 `[]` にする
- `summary_text` は全データを総合して LLM が生成する

## 6. デイリーノートへの書き込み

`~/.claude/skills/daily-summary/write-daily.py` を使ってデイリーノートに書き込む。
このスクリプトは stdin から JSON を受け取り、以下を自動判定して処理する:

- ファイルが存在しない → 新規作成（frontmatter + サマリー）
- `## デイリーサマリー` がない → 末尾に追記
- `## デイリーサマリー` がある → そのセクションを上書き

実行:

```bash
echo -n "$JSON_DATA" | python3 ~/.claude/skills/daily-summary/write-daily.py
```

JSON にバッククォートやダブルクォートが含まれる場合、シェルエスケープを避けるため
ヒアドキュメントか base64 経由で渡す:

```bash
echo -n "$JSON_DATA" | base64 -w0 | base64 -d | python3 ~/.claude/skills/daily-summary/write-daily.py
```

## 7. 完了報告

書き込んだファイルのパスと、サマリーの概要（コミット数、PR数、ログ数）を報告する。

## 注意事項

- GitHub API の日付は UTC ベースだが、`committer-date` はコミッターのローカルタイムで評価されるため通常は問題ない
- context-log のファイル名はタイムスタンプ（JST）ベースなので、`YYYYMMDD` の前方一致で正しくフィルタできる
- Obsidian のリンク記法（`[[]]`）やコールアウト（`> [!info]`）を活用する
- Windows 環境で `python3` が無い場合は Python 3 をインストールしてから実行すること

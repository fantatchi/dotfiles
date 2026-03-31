---
name: daily-summary
description: GitHub アクティビティと作業ログからデイリーサマリーを生成し、Obsidian デイリーノートに追記する。「今日のまとめ」「デイリーサマリー」といった依頼で使う。
argument-hint: [YYYY-MM-DD]
allowed-tools: Read, Bash(gh:*), Bash(date:*), Bash(uname:*), Bash(wsl:*), Bash(python3:*), Bash(cat:*), Bash(ls:*), Bash(echo:*)
---

# デイリーサマリーの生成

その日の GitHub アクティビティと Obsidian 作業ログ（context-log）を収集し、デイリーノートにサマリーを追記する。

## 0. 実行環境の検出

`uname -o` で実行環境を判定する:

```bash
uname -o
```

| 結果 | 環境 | Vault アクセス方法 |
|---|---|---|
| `Msys` または `Cygwin` | Windows (Git Bash) | `wsl` コマンド経由 |
| `GNU/Linux` | WSL / Linux ネイティブ | 直接アクセス |

以降、Windows 環境では Vault 内のファイル操作を全て `wsl` コマンド経由で行う。

### Windows 環境での注意事項（重要）

Git Bash は `/home/...` のようなパスを自動的に `C:/Program Files/Git/home/...` に変換する（MSYS パス変換）。
これを回避するため、**Vault パスを `wsl` に渡す際は必ず `bash -c "..."` で囲む**こと:

```bash
# NG: Git Bash がパスを変換してしまう
wsl -d Ubuntu -- ls /home/at-kato/ObsidianVault/

# OK: bash -c 内のパスは変換されない
wsl -d Ubuntu -- bash -c "ls /home/at-kato/ObsidianVault/"
```

## 1. 対象日の決定

- `$ARGUMENTS` が `YYYY-MM-DD` 形式で指定されていればその日を対象とする
- 空の場合は `date +%Y-%m-%d` で今日の日付を取得する

以降、対象日を `TARGET_DATE`（例: `2026-03-31`）として参照する。
対象日から以下の変数も導出する:

- `YYYYMM` = `20260331` の先頭6文字 → `202603`
- `YYYYMMDD` = `20260331`

## 2. 設定の取得

`$HOME/.claude/config.json` を Read で読み込み、以下の値を取得する:

- `obsidian_vault`: Vault の絶対パス（WSL Linux パス形式）
- `wsl_distro`: WSL ディストリビューション名（Windows 環境でのみ使用）

いずれのキーが存在しない場合は以下を案内して終了:

```
必要な設定が見つかりません。
~/.claude/config.json に以下を追加してください：
  "obsidian_vault": "/path/to/vault",
  "wsl_distro": "Ubuntu"
```

※ パスのハードコード禁止。

以降、WSL ディストリビューション名を `DISTRO` として参照する。

## 3. GitHub データ収集

`gh api` で以下の4つを取得する。それぞれ jq フィルターで必要なフィールドのみ抽出すること。

### 3a. コミット

```bash
gh api '/search/commits?q=author:kentem-at-kato+committer-date:TARGET_DATE&sort=committer-date&order=desc&per_page=100' \
  --header 'Accept: application/vnd.github.cloak-preview+json'
```

抽出: sha（先頭7文字）、コミットメッセージ（1行目のみ）、リポジトリ名（full_name）

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

### Windows 環境

`wsl` コマンドでファイル一覧を取得し、各ファイルの内容を読む:

```bash
wsl -d $DISTRO -- bash -c "ls {vault}/_claude/log/{YYYYMM}/{YYYYMMDD}*.md 2>/dev/null"
```

ファイルが見つかった場合、各ファイルに対して:

```bash
wsl -d $DISTRO -- bash -c "head -30 '{file_path}'"
```

### WSL / Linux 環境

Bash の ls コマンドでファイル一覧を取得し、各ファイルを Read で読む:

```bash
ls {vault}/_claude/log/{YYYYMM}/{YYYYMMDD}*.md 2>/dev/null
```

### 共通

各ファイルから以下を抽出する:
1. frontmatter の `project` を取得
2. `## 概要` セクションのテキスト（1-2行）を取得

context-log が 0 件の場合は「作業ログの記録なし」とする。

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
  "summary_text": "GitHub アクティビティと作業ログを総合した 1-3 行の自然言語サマリー"
}
```

- `commits`, `prs`, `logs` が 0 件の場合は空配列 `[]` にする
- `summary_text` は全データを総合して LLM が生成する

## 6. デイリーノートへの書き込み

`./write-daily.py` を使ってデイリーノートに書き込む。
このスクリプトは stdin から JSON を受け取り、以下を自動判定して処理する:

- ファイルが存在しない → 新規作成（frontmatter + サマリー）
- `## デイリーサマリー` がない → 末尾に追記
- `## デイリーサマリー` がある → そのセクションを上書き

### Windows 環境

`.claude` ディレクトリは WSL ファイルシステムへのシンボリックリンクであるため、
スキルファイルは WSL ネイティブパスで直接アクセスできる:

```
Windows: C:\Users\at-kato\.claude\...
  → シンボリックリンク → \\wsl.localhost\Ubuntu\home\at-kato\.claude\...
  → WSL ネイティブ: /home/at-kato/.claude/...
```

スクリプトの実行パス:

```bash
SKILL_DIR="/home/at-kato/.claude/skills/daily-summary"

wsl -d $DISTRO -- bash -c "... | python3 $SKILL_DIR/write-daily.py"
```

**注意**: `/mnt/c` 経由では `.claude` シンボリックリンクが解決できず I/O エラーになる。
必ず WSL ネイティブパス（`/home/...`）を使うこと。

### WSL / Linux 環境

直接 Python で実行:

```bash
echo '$JSON_DATA' | python3 ./write-daily.py
```

### JSON の渡し方（重要）

JSON をシェルに渡す際、バッククォートやダブルクォートのエスケープ問題が発生しうる。
**base64 エンコードで渡す**のが最も安全:

```bash
SKILL_DIR="/home/at-kato/.claude/skills/daily-summary"

# Windows
B64=$(echo -n "$JSON_DATA" | base64 -w0)
echo "$B64" | wsl -d $DISTRO -- bash -c "base64 -d | python3 $SKILL_DIR/write-daily.py"

# WSL / Linux
echo -n "$JSON_DATA" | python3 $SKILL_DIR/write-daily.py
```

WSL / Linux 環境では JSON にシェル特殊文字が含まれないため、直接パイプで渡してよい。

## 7. 完了報告

書き込んだファイルのパスと、サマリーの概要（コミット数、PR数、ログ数）を報告する。

## 注意事項

- GitHub API の日付は UTC ベースだが、`committer-date` はコミッターのローカルタイムで評価されるため通常は問題ない
- context-log のファイル名はタイムスタンプ（JST）ベースなので、`YYYYMMDD` の前方一致で正しくフィルタできる
- Obsidian のリンク記法（`[[]]`）やコールアウト（`> [!info]`）を活用する
- Read/Write/Edit/Glob ツールは WSL ファイルシステムに直接アクセスできないため、Windows 環境では使用しない
- `wsl` コマンドにパスを直接渡す場合は Git Bash の MSYS パス変換に注意すること（セクション 0 参照）
- `.claude` ディレクトリは `C:\Users\at-kato\.claude` → `\\wsl.localhost\Ubuntu\home\at-kato\.claude` のシンボリックリンク。`/mnt/c` 経由ではアクセスできないため、WSL 内では `/home/at-kato/.claude/...` を使う
- `config.json` の `wsl_distro` が未設定の場合は `Ubuntu` をフォールバックとしてよいが、ユーザーに設定を促すメッセージを出力する

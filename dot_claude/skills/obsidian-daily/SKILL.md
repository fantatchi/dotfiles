---
name: obsidian-daily
description: GitHub アクティビティと作業ログから Obsidian デイリーノートの「## デイリーサマリー」セクションを生成・追記する。冒頭 KPI 行（commits / PRs / logs 件数）・「今日の要約」上配置・コミットのリポ別グルーピング・作業ログ折り畳み callout の構成。複数 GH アカウント（`fantatchi` + `kentem-at-kato`）の活動を `gh auth switch` で順次切替しながら集約。「今日のまとめ」「デイリーサマリー」「KPI」「リポ別コミット」「概況」「複数アカウント」「両アカウント集約」「個人と業務を合算」「fantatchi の commit も含めて」といった依頼で使う。
argument-hint: [YYYY-MM-DD]
allowed-tools: Read, Bash(gh:*), Bash(date:*), Bash(python:*), Bash(cat:*), Bash(ls:*), Bash(echo:*)
---

# デイリーサマリーの生成

その日の GitHub アクティビティと Obsidian 作業ログ（作業ログ）を収集し、デイリーノートにサマリーを追記する。

## 1. 対象日の決定

- `$ARGUMENTS` が `YYYY-MM-DD` 形式で指定されていればその日を対象とする
- 空の場合は `date +%Y-%m-%d` で今日の日付を取得する

以降、対象日を `TARGET_DATE`（例: `2026-03-31`）として参照する。
対象日から以下の変数も導出する:

- `YYYYMM` = `20260331` の先頭6文字 → `202603`
- `YYYYMMDD` = `20260331`

## 2. Vault パスの決定

`~/.claude/skills/shared/vault-init.md` の **§1「Vault 存在確認」を実行** する（`~/ObsidianVault` の存在チェックと、未配置時の案内メッセージ）。WSL / Windows (Git Bash) いずれからも同じ相対パスで解決される前提も shared 側に集約済み。

本スキルは Vault 内へのファイル書き出しを `write-daily.py` が `~/ObsidianVault/_daily/YYYYMM/YYYY-MM-DD.md` に直接行う設計のため、shared/vault-init.md の §2「書き出し先ディレクトリ」/ §3「ファイル名」規約は使用しない（その 2 つは obsidian-log / obsidian-resource 用）。

## 3. GitHub データ収集

`gh api` で各アカウントごとに 4 種類（commits / PR 作成 / PR マージ / レビュー）を収集する。

### 対象アカウント

複数 GitHub アカウントの活動を集約する。Bash 配列でループ:

```bash
accounts=("fantatchi" "kentem-at-kato")
```

各アカウントについて以下 4 クエリを **逐次実行**（並列化禁止: search 専用 rate limit 枠を一気に使い切らないため）し、結果を 1 つの JSON に統合する。
クエリ文字列の `<ACCOUNT>` は `${acc}`、`<TARGET_DATE>` はステップ 1 で決めた日付（例: `2026-05-14`）に置換して叩く。

コール数: 4 × N アカウント（2 アカウントなら 8 回 / 1 デイリー実行）。
GitHub Search API の rate limit は **search 専用枠 30 req/min（user/token 単位）**。
core の 5000/h とは別枠で干渉しない。weekly 連続実行（7 日 × 2 アカウント × 4 = 56 コール）も逐次なら問題ないが、他スキル併用時は search 枠が共有される点に注意。

### アカウント切替（致命的、必須）

`gh api` は **アクティブな `gh` user の token** で API を叩く。`fantatchi` token で `q=author:kentem-at-kato` を叩いても、**kentem-at-kato のみが visibility を持つ private repo の commit/PR は 0 件で返る**（search index は ACL で post-filter される）。

過去事例: 2026-05-13 の `/obsidian-daily` 実行で kentem-at-kato の活動が完全に欠落した事故の有力な真因候補。当時は leading slash 罠を疑ったが、leading slash と auth 不一致は同時に効きうるので両方を塞ぐ。

各アカウントのクエリを叩く前に **アクティブアカウントを切り替える**:

```bash
for acc in "${accounts[@]}"; do
  gh auth switch -u "$acc" >/dev/null 2>&1 || {
    echo "WARN: auth switch failed for $acc, skipping" >&2
    continue
  }
  # 3a〜3d を $acc + $TARGET_DATE で実行（後述）
done
```

切替に失敗（未認証 / token 失効）したアカウントは **スキップ**し、§7 完了報告で **必ず明示** する。

### gh api endpoint の罠（必須）

Git Bash 環境では `gh api '/search/...'` の **先頭スラッシュ** が Windows パス
（`C:/Program Files/Git/search/...`）に書き換えられて `invalid API endpoint` で失敗する。
**必ず先頭スラッシュを外す**こと（CLAUDE.md「Git Bash で `gh api` のエンドポイント先頭スラッシュ」参照）。

### 日付絞り込みの TZ（必須）

ユーザーは JST 帯で運用するため、各クエリの日付絞り込みは **必ず JST offset 付き range 構文** を使う:

```
<FIELD>:<TARGET_DATE>T00:00:00+09:00..<TARGET_DATE>T23:59:59+09:00
```

TZ offset を省くと GitHub Search は **UTC として解釈** するため、JST 0:00〜9:00 の commit が前日扱いになって漏れ、JST 翌 0:00〜9:00 の commit が当日に混入する。

### 3a. コミット

```bash
gh api 'search/commits?q=author:<ACCOUNT>+committer-date:<TARGET_DATE>T00:00:00+09:00..<TARGET_DATE>T23:59:59+09:00&sort=committer-date&order=asc&per_page=100' \
  --header 'Accept: application/vnd.github.cloak-preview+json'
```

抽出: sha（先頭7文字）、コミットメッセージ（1行目のみ）、リポジトリ名（full_name）、`commit.committer.date`（ISO-8601 文字列、マージソート用）

※ `order=asc` で時系列順。`cloak-preview` header は commits search のみ必須（issues search では不要）。

### 3b. PR（作成）

```bash
gh api 'search/issues?q=author:<ACCOUNT>+type:pr+created:<TARGET_DATE>T00:00:00+09:00..<TARGET_DATE>T23:59:59+09:00&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名、状態

### 3c. PR（マージ）

```bash
gh api 'search/issues?q=author:<ACCOUNT>+type:pr+merged:<TARGET_DATE>T00:00:00+09:00..<TARGET_DATE>T23:59:59+09:00&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名

### 3d. レビュー

```bash
gh api 'search/issues?q=reviewed-by:<ACCOUNT>+type:pr+updated:<TARGET_DATE>T00:00:00+09:00..<TARGET_DATE>T23:59:59+09:00&per_page=100'
```

抽出: タイトル、URL（html_url）、リポジトリ名、状態

注意: `reviewed-by` × `updated` は **当日他人がコメント等で PR を更新した場合**にも反応する（精度より再現を優先する割り切り）。誤検出は §5 の summary_text 生成段で人間目線でフィルタする運用。

### マージと重複排除

複数アカウント / 複数カテゴリで同じ commit / PR が出た場合の扱い:

- **commits**: **`(sha, repo)` 複合キー** で重複排除。`sha` 単独だと同 commit が複数 repo に index されている（fork / PR base+head 両方）ケースで片方の repo 表示が消える。マージ後は `commit.committer.date` 昇順でソート（古→新）。**write-daily.py は入力順を保持する**ため、ソートは LLM 側の責務
- **PR**: `html_url` をキーに重複排除。**labels は union**: 同 PR が複数カテゴリ（作成 / マージ / レビュー）に出るケース、複数アカウントで違うカテゴリに出るケースの両方とも labels に列挙する（例: fantatchi が作成 + kentem-at-kato がレビューした PR → `labels: ["作成", "レビュー"]`）。**`_PR_LABEL_ORDER` の `("作成", "マージ", "レビュー")` の語を使う** こと（write-daily.py の KPI 行が分解カウントする）

### エラー処理

- API エラー（403 rate limit / 401 認証 / 422 等）: 該当アカウント・該当セクションのみスキップし、他は継続
- スキップが発生した場合は §7 完了報告で **「N アカウント中 X 件取得失敗（理由）」を必ず明示**（旧版の「取得エラー」ノート表示の代替。write-daily.py 側にはエラー表示機構がないため、報告で可視化する）
- 全アカウント・全セクションが 0 件: 空配列 `[]` のまま JSON に詰める（write-daily.py が「なし」と表示）

## 4. 作業ログ の収集

Bash の ls コマンドでファイル一覧を取得し、各ファイルを Read ツールで読む:

```bash
ls ~/ObsidianVault/_claude/log/{YYYYMM}/{YYYYMMDD}*.md 2>/dev/null
```

各ファイルから以下を抽出する:
1. ファイルパス（vault 相対、例: `_claude/log/202604/20260423-foo.md`）
2. frontmatter の `project` を取得（`"[[xxx]]"` の wiki-link 形式の場合は `xxx` を取り出してプレーン文字列として扱う。例: `"[[u-veil]]"` → `u-veil`。スラッシュ区切りなど内部に複数値が入る場合もそのまま 1 つの文字列として保持）
3. `## 概要` セクションのテキスト（1-2行）を取得

作業ログ が 0 件の場合は「作業ログの記録なし」とする。

`path` は `summary_of`（再帰要約劣化対策の一次情報源リンク）に使うため、必ず含める。

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
  "vault": "~/ObsidianVault",
  "target_date": "2026-03-31",
  "commits": [
    {"sha": "a3d1f9f", "message": "コミットメッセージ", "repo": "owner/repo", "date": "2026-03-31T09:12:00+09:00"}
  ],
  "prs": [
    {"title": "PR タイトル", "url": "https://...", "labels": ["作成", "マージ"]}
  ],
  "logs": [
    {"path": "_claude/log/202604/20260423-foo.md", "project": "project-name", "summary": "作業概要"}
  ],
  "upcoming_tasks": [
    {"section": "Next", "project": "claude-config", "title": "gtd-list スキルの実装"},
    {"section": "Waiting", "project": "mlit", "title": "APIキー発行待ち @since:2026-04-08"}
  ],
  "summary_text": "- toto-predictor: Phase 2.2 完走 (Brier 0.7761)\n- kabuto: Phase 6-α ゲート 2/10 達成\n- cloud-dsc: PR #38-42 を 5 本作成・4 本マージ"
}
```

- `commits`, `prs`, `logs`, `upcoming_tasks` が 0 件の場合は空配列 `[]` にする
- `commits[].date` は §3a で抽出した `commit.committer.date`（ISO-8601）。`write-daily.py` 自体は使わない（入力順を保持してそのまま出力する）が、§3 マージ規約のソートで使うため **必ず含めて出力**。例 schema からこのフィールドを削ると LLM が捨てる → ソートが空打ちになる過去事例あり
- `prs[].labels` は `("作成", "マージ", "レビュー")` の **語固定**。write-daily.py の KPI 行が **label 別に分解カウント** する仕様（同 PR が `["作成", "マージ"]` を持つと breakdown で `作成 1・マージ 1`、ただし PR 件数自体は **1**）。LLM 側で labels を「代表 1 件に畳む」「順序を変える」「別語に置換」しないこと（畳むと breakdown が消える）
- `summary_text` は全データを総合して LLM が**プロジェクト軸の箇条書き 2-4 行**で生成する
  - 形式: `- <project>: <その日の核心 1 行>`
  - プロジェクトは作業ログ / commits / PRs を総合して「動いたプロジェクト」を抽出
  - 1 プロジェクト 1 行、長文ベタ書きは避ける（ジャンプ率を KPI 行と揃え、認知負荷を抑える）
  - 全プロジェクトを羅列するのではなく、その日の **核心 2-4 件** に絞る
  - 活動なし日（commits / PRs / logs すべて空）の場合のみ「特筆事項なし」を 1 行で出す
- `logs[].path` は vault 相対パス。`write-daily.py` がこれを wiki-link 化して `summary_of` に展開する（再帰要約劣化対策）

## 6. デイリーノートへの書き込み

`~/.claude/skills/obsidian-daily/write-daily.py` を使ってデイリーノートに書き込む。
スクリプトは以下を自動判定して処理する:

- ファイルが存在しない → 新規作成（frontmatter + サマリー）
- `## デイリーサマリー` がない → 末尾に追記
- `## デイリーサマリー` がある → そのセクションを上書き

### 実行手順（必ずファイル経由）

JSON をシェル経由（`echo` / `cat <<EOF` / 環境変数展開）で Python に流すと、
Windows の Git Bash 環境では locale が cp932 のため Python に届く前に
日本語が Shift-JIS 化けする。`sys.stdin.reconfigure` では救えない。
したがって **必ず UTF-8 で一時ファイルに書き出してからパス引数で渡す**。

```bash
python - <<'PY'
import json, os
data = { ... }  # ステップ 5 で組み立てた JSON 構造
path = os.path.expanduser('~/tmp_daily_summary.json')
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)
print(path)
PY

python ~/.claude/skills/obsidian-daily/write-daily.py ~/tmp_daily_summary.json
```

**`python3` ではなく `python` を使う**: Windows (Git Bash) の `python3` は
Microsoft Store のスタブランチャー (`AppData\Local\Microsoft\WindowsApps\python3`)
に解決されることがあり、非対話実行で exit code 49 + 出力なしで黙って落ちる。
`python` (`C:\Python313\python.exe` 等) を経由すれば安定動作する。WSL/macOS では
`python` で Python 3 系が解決される前提（必要なら `alias python=python3`）。

**一時ファイルのクリーンアップ**: `write-daily.py` が書き込み成功後に
自身で `os.remove(sys.argv[1])` する仕様。シェル側で `rm` を呼ばないので
`Bash(rm:*)` 権限を要求しない。

**一時ファイルはホーム直下に置く**: `/tmp/` は Git Bash と WSL でパス解釈が
異なるため避ける。`~/tmp_daily_summary.json` 固定名で運用する（このスキルは
単発対話で呼ばれる前提なので同時実行の競合は考慮しない）。

**出力フォーマットの SSOT（Single Source of Truth）**: 「## デイリーサマリー」セクションの
具体的な構造（KPI 行・collapsible meta callout・「今日の要約」配置・コミットのリポ別
グルーピング・作業ログのフラット件数 + callout）は `write-daily.py` の `SUMMARY_TEMPLATE`
および `build_kpi_line` / `build_grouped_commits` / `build_logs_section` が実装上の唯一の正本。
出力規約は `obsidian-mail` の reader 契約（`obsidian-mail/SKILL.md §2-b`）にも反映されているため、
出力フォーマットを変更する際は reader 側の `_BULLET_RE` 等の依存を必ず確認すること。

## 7. 完了報告

以下を**必ず**報告する:

- 書き込んだファイルのパス
- サマリーの概要: コミット数（× 何 repo）、PR 数（作成 / マージ / レビュー の breakdown）、ログ数、予定タスク件数
- **アカウント別の取得件数**: 例 `fantatchi: commits 5 / PR 1` / `kentem-at-kato: commits 12 / PR 3`
- **取得失敗があった場合は必ず明示**: §3「エラー処理」でスキップしたアカウント・セクションと理由（rate limit / auth / 422 等）。write-daily.py は失敗をノート上で可視化しないため、ここで報告しないと **静かな 0 件** として埋もれる（2026-05-13 事故の再発防止）

## 注意事項

- GitHub Search API の日付絞り込みは **TZ 省略時 UTC 解釈**。JST 帯運用では §3「日付絞り込みの TZ」に従い `+09:00` offset 付き range 構文を使う
- 作業ログ のファイル名はタイムスタンプ（JST）ベースなので、`YYYYMMDD` の前方一致で正しくフィルタできる
- Obsidian のリンク記法（`[[]]`）やコールアウト（`> [!info]`）を活用する
- Windows 環境で `python` が無い場合は Python 3 をインストールしてから実行すること（`python3` は MS Store スタブの可能性があるので避ける）
- **JSON は必ずファイル経由で渡す**: `echo "$JSON" | python3 ...` / `cat <<EOF | python3 ...` / シェル変数展開は Windows (Git Bash) で cp932 化けを起こす。`sys.stdin.reconfigure` では救えない（Python 到達前にシェルが bytes 化しているため）。ステップ 6 の手順（Python ヒアドキュメントで UTF-8 ファイルに書き出し → パス引数）を必ず踏むこと
- **`vault` の `~` 展開**: Python は `~` を自動展開しないため、`write-daily.py` 側で `os.path.expanduser()` を通している。JSON の `vault` には `~/ObsidianVault` のようなチルダ込みパスをそのまま渡してよい（渡さないと literal `~` ディレクトリが作られるバグを過去に踏んだ）

# デイリーサマリー wire format（obsidian-daily ↔ obsidian-mail の契約）

**shared ライブラリ**: `~/.claude/skills/shared/` 配下、`name:` 付きスキルではない（自動起動対象外）。`obsidian-daily`（producer）が書き、`obsidian-mail`（consumer）が読む「## デイリーサマリー」セクションの構造契約を 1 か所に集約する。両スキルが互いの SKILL.md を直接読み合う密結合を、この名前付き契約に置き換えるためのドキュメント。

> **真の SSOT はコード**: 構造の正本は producer 側 `obsidian-daily/write-daily.py`（`SUMMARY_TEMPLATE` / `build_kpi_line` / `build_grouped_commits` / `build_logs_section`）と consumer 側 `obsidian-mail/extract-summary.py`（`_BULLET_RE` 等）。本ファイルは**両者が合意している契約の人間可読な要約**であり、コードと食い違ったらコードが優先。フォーマットを変えるときは必ず両コードを同時に直す（二重 SSOT を作らない）。

## セクション構造（producer が書く順）

「## デイリーサマリー」直下に、以下の規約セクションがこの順で並ぶ:

1. **冒頭 KPI 行**: `**今日の活動**: commits N (M repos) / PRs N (作成 X, マージ Y, レビュー Z) / logs N`
2. **メタ callout**: `> [!info]- 自動生成（メタデータ）`（内部リンク `[[...]]` を含む）
3. **`### 今日の要約`**: プロジェクト軸の箇条書き 2-4 行（`- <project>: <核心 1 行>`）
4. **`### 作業ログ`**: `> [!note]- 詳細（作業ログ N 件）` callout 配下に `> - **project**: body` bullet
5. **`### GitHub アクティビティ`**: `#### コミット`（`##### owner/repo (N)` でグルーピング） / `#### PR`
6. **`### 明日以降のタスク`**: `- [ ] #project body`

## consumer の読み出し規約（要点）

- KPI 行・メタ callout は**除去**（メールは独自の `## GitHub` 集計を持つ）
- `### 今日の要約` → `## 今日のひとこと`（`.tldr` ボックス、複数段落なら最初の 1 段落のみ）
- `### 作業ログ` の `- **project**: body` → `## ハイライト`（1 行圧縮）。**この形式以外の bullet は静かに捨てる**
- `### GitHub アクティビティ` → `## GitHub`（リポ別小見出しは無視してフラット集計）
- `### 明日以降のタスク` の `- [ ] #project body` → `## 明日のタスク`（件数＋内訳＋抜粋）
- 規約 4 セクション以外の `### xxx`・`## デイリーサマリー` 外のコンテンツは**意図的に捨てる**

## ラベル語の固定

PR の `labels` は `("作成", "マージ", "レビュー")` の**語固定**。producer の KPI 行が label 別に分解カウントするため、consumer・LLM 側で畳む／順序変更／別語置換をしない。

詳細な振る舞いは各スキルの SKILL.md（`obsidian-daily` §5/§6、`obsidian-mail` §2-b/§2-c）とコードを参照。

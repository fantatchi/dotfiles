# デイリーサマリー wire format（obsidian-daily ↔ obsidian-mail の契約）

`obsidian-daily`（producer）が書き、`obsidian-mail`（consumer）が読む「## デイリーサマリー」セクションの構造契約。

> **真の SSOT はコード**: 構造の正本は producer 側 `obsidian-daily/write-daily.py`（`SUMMARY_TEMPLATE` / `build_kpi_line` / `build_grouped_commits` / `build_logs_section`）と consumer 側 `obsidian-mail/extract-summary.py`（`_BULLET_RE` 等）。本ファイルは**両者が合意している契約の人間可読な要約**であり、コードと食い違ったらコードが優先。フォーマットを変えるときは必ず両コードを同時に直す（二重 SSOT を作らない）。

## セクション構造（producer が書く順）

「## デイリーサマリー」直下に、以下の規約セクションがこの順で並ぶ:

1. **冒頭 KPI 行**: `**今日の活動**: commits N (M repos) / PRs N (作成 X, マージ Y, レビュー Z) / logs N`
2. **メタ callout**: `> [!info]- 自動生成（メタデータ）`（内部リンク `[[...]]` を含む）
3. **`### 今日の要約`**: ラベル付き箇条書き 3-6 行（`- [済|決定|残] <project>: <body>`）。空行を含まない 1 段落（2026-10-08〜。それ以前はラベルなしの `- <project>: <核心 1 行>`）
4. **`### GitHub アクティビティ`**: `#### コミット` 見出しの下に `> [!note]- コミット N 件（M repos）` callout、その中に `> ##### owner/repo (N)` と `> - msg (`sha`)`（2026-10-08〜。それ以前は callout なし） / `#### PR`
5. **`### 作業ログ`**: `> [!note]- 詳細（作業ログ N 件）` callout 配下に `> - **project**: body` bullet。1 プロジェクト 1 行で、同じプロジェクトのログは ` ／ ` で連結（2026-10-08〜）
6. **`### 明日以降のタスク`**: 旧形式のみ（`- [ ] #project body`）。現行の producer はタスクストアを読まないので出力しない

## consumer の読み出し規約（要点）

- KPI 行・メタ callout は**除去**（メールは独自の `## GitHub` 集計を持つ）
- `### 今日の要約` → `## 今日のひとこと`（`.tldr` ボックス、複数段落なら最初の 1 段落のみ）。週報は `[済]` / `[決定]` / `[残]` を「終わったこと / 決めたこと / 持ち越し（週の最終日の分のみ）」に集計し、ラベル付きの日が無い週は作業ログのプロジェクト別ハイライトにフォールバック
- `### 作業ログ` の `- **project**: body` → `## ハイライト`（1 行圧縮）。**この形式以外の bullet は静かに捨てる**
- `### GitHub アクティビティ` → `## GitHub`（行頭の `> ` を剥がし、リポ別小見出しは無視してフラット集計）
- `### 明日以降のタスク` の `- [ ] #project body` → `## 明日のタスク`（件数＋内訳＋抜粋）
- 規約 4 セクション以外の `### xxx`・`## デイリーサマリー` 外のコンテンツは**意図的に捨てる**

## ラベル語の固定

PR の `labels` は `("作成", "マージ", "レビュー")` の**語固定**。今日の要約のラベルも `済` / `決定` / `残` の語固定（consumer の `TLDR_LABELS` が集計に使う）。producer の KPI 行が label 別に分解カウントするため、consumer・LLM 側で畳む／順序変更／別語置換をしない。

詳細な振る舞いは `obsidian-daily` SKILL.md 5 節/6 節と両コードを参照。手書きで追加した情報をメールに届けたい場合は Obsidian で直接見るか、consumer の拡張（未参照セクションを「その他」として末尾追加）を検討する。

---
name: daily-view
description: 保存済みの Obsidian デイリーノートを読み込み、デイリーサマリーを Claude Code 上に表示する。「昨日のサマリー」「今日のまとめ見せて」といった依頼で使う。
argument-hint: [YYYY-MM-DD|yesterday|today]
allowed-tools: Read, Bash(date:+%Y-%m-%d), Bash(date:-d yesterday +%Y-%m-%d)
---

# デイリーサマリーの表示

保存済みの Obsidian デイリーノートからデイリーサマリーを読み込み、Claude Code 上に表示する（読み取り専用）。

## 1. 対象日の決定

- `$ARGUMENTS` が `YYYY-MM-DD` 形式 → その日
- `today` → 今日
- `yesterday` または空 → 昨日（**デフォルト**）
- 日付の取得: `date -d "yesterday" +%Y-%m-%d`（空の場合）、`date +%Y-%m-%d`（today の場合）

## 2. ファイルパスの組み立て

```
~/ObsidianVault/_daily/{YYYYMM}/{YYYY-MM-DD}.md
```

- `YYYYMM` = 対象日の先頭 6 文字（ハイフン除去）。例: `2026-04-15` → `202604`

## 3. ファイルの読み込みと表示

1. Read ツールでファイルを読む
2. ファイルが存在しない場合:
   ```
   {YYYY-MM-DD} のデイリーノートが見つかりません。
   `/daily-summary {YYYY-MM-DD}` で生成できます。
   ```
3. `## デイリーサマリー` セクションが存在すればその内容を表示
4. セクションがない場合は「デイリーサマリーが未生成です」と案内

## 注意事項

- 読み取り専用。ファイルを変更しない
- Vault パスは `~/ObsidianVault` 固定

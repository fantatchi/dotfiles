---
name: gtd-done
description: タスクストア（tasks.md）の指定タスクを **完了** にし Done セクションへ移動する操作型スキル。動詞は「完了」専用（追加は gtd-add、表示は gtd-list）。「タスク完了」「あれ終わった」「完了マーク」「終わった」「タスク消化」といった依頼、または他スキルからのタスク完了要求で使う。tasks.md の場所は shared/integrations.md の task_store で解決し、無ければ既定 ~/ObsidianVault/00_meta/tasks.md。
argument-hint: <タスクタイトルの部分一致文字列>
allowed-tools: Read, Write, Edit, Bash(date:*)
---

# タスク完了

指定したタスクをタスクストア（tasks.md）の `## Done` セクションに移動する。

**単独動作**: このスキルはタスクストア（tasks.md）1 つだけに依存し、Obsidian や兄弟スキルが無くても動く。tasks.md の場所は resolver `~/.claude/skills/shared/integrations.md` の `task_store` で解決する（無ければ既定 `~/ObsidianVault/00_meta/tasks.md`）。連携なし。

## フォーマット仕様

`~/.claude/skills/shared/tasks-format.md` を参照すること。

## 手順

### 1. 引数の確認

- `$ARGUMENTS` が空の場合はユーザーに「完了するタスクの部分一致文字列」を質問する

### 2. タスクストアの解決と読み込み

1. resolver `~/.claude/skills/shared/integrations.md` を Read し `task_store` を取得する（resolver が無い / `task_store` が空なら既定 `~/ObsidianVault/00_meta/tasks.md`）。以降この解決済みパスを「tasks.md」と呼ぶ
2. tasks.md を Read で読む。存在しない場合は「タスクが登録されていません。」と案内して終了

### 3. タスク検索

Done 以外の全セクション（Inbox / Next / Waiting / Someday）から、`$ARGUMENTS` を**部分一致**で検索する（大文字小文字を区別しない）。

検索対象はタスク行全体（プロジェクトタグも含む）。

### 4. 結果の分岐

#### 0 件の場合

```
❌ 「<検索文字列>」に一致するタスクが見つかりません
```

とエラー表示して終了。

#### 1 件の場合

確認なしで Done に移動する（ステップ 5 へ）。

#### 複数件の場合

候補を番号付きで提示し、ユーザーに選ばせる：

```
複数のタスクが一致しました。番号で指定してください：

1. [Next] #project/mlit APIキー取得
2. [Waiting] #project/mlit APIキー発行待ち @since:2026-04-08

番号を入力してください:
```

ユーザーの回答を待ってから次のステップへ進む。

### 5. Done への移動

#### 移動処理

1. 元のセクションから該当タスク行を削除（Edit ツール）
2. タスク行を `Done` フォーマットに変換：
   - `- [ ] #project/xxx タイトル` → `- [x] YYYY-MM-DD #project/xxx タイトル`
   - 日付は `date +%Y-%m-%d` で取得
3. `## Done` セクションの**直後**に新しい行として挿入（Done の最新が一番上に来る）

#### Edit の順序

a. まず元の行を削除する（`old_string`: 該当行, `new_string`: 空文字）
b. 次に Done セクションに追加する（`old_string`: `## Done\n`, `new_string`: `## Done\n\n- [x] YYYY-MM-DD ...\n`）

空行の扱いに注意：削除時に空行が連続しないよう調整する。

### 6. 完了報告

```
✓ タスクを完了にしました
- [x] YYYY-MM-DD #project/xxx タイトル
```

## 注意事項

- tasks.md の場所は resolver の `task_store` が出典（既定 `~/ObsidianVault/00_meta/tasks.md`）
- 既に Done のタスクは検索対象外（二重完了を防ぐ）
- Done への挿入位置は Done セクションの先頭（新しい完了が上）

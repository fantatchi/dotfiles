---
name: gtd-add
description: タスクをタスクストア（tasks.md）の Inbox セクションに **追加** する操作型スキル。動詞は「追加」専用（完了は gtd-done、表示は gtd-list）。「タスクを追加」「TODO として残して」「思いつき記録」「Inbox にメモ」「タスク登録」といった依頼、または他スキルからのタスク追加要求で使う。tasks.md の場所は shared/integrations.md の task_store で解決し、無ければ既定 ~/ObsidianVault/00_meta/tasks.md。
argument-hint: [タスクタイトル]
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(basename:*), Bash(pwd)
---

# タスク追加

新規タスクをタスクストア（tasks.md）の `## Inbox` セクションに追加する。

**単独動作**: このスキルはタスクストア（tasks.md）1 つだけに依存し、Obsidian や兄弟スキルが無くても動く。tasks.md の場所は resolver `~/.claude/skills/shared/integrations.md` の `task_store` で解決する（無ければ既定 `~/ObsidianVault/00_meta/tasks.md`）。連携なし。

## フォーマット仕様

`~/.claude/skills/shared/tasks-format.md` を参照すること。

## 手順

### 1. 引数の確認

- `$ARGUMENTS` が空の場合はユーザーにタスクタイトルを質問する
- `$ARGUMENTS` にタイトルがあればそれを使う

### 2. プロジェクトタグの決定

引数に既に `#project/xxx` が含まれている場合はそれを使う。含まれていない場合は CWD から推定する：

1. **ホーム判定**: `[ "$(pwd -P)" = "$HOME" ]` が真なら `#project/global` を使う（プロジェクト非依存タスク）。以降の手順はスキップ
2. `git rev-parse --show-toplevel` でリポジトリルートを取得
3. 取得できた場合: `basename` でディレクトリ名を取り、`#project/<name>` を作る
4. git リポジトリ外の場合: `basename "$(pwd)"` を使う
5. どれも取れない場合: `#project/unknown` とし、ユーザーに後で修正するよう伝える

### 3. タスクストアの解決と読み込み

1. resolver `~/.claude/skills/shared/integrations.md` を Read し `task_store` を取得する（resolver が無い / `task_store` が空なら既定 `~/ObsidianVault/00_meta/tasks.md`）。以降この解決済みパスを「tasks.md」と呼ぶ
2. tasks.md を Read で読む

#### ファイルが存在しない場合の分岐

- **同期ガード（task_store が Obsidian Vault 内のときのみ）**: `task_store_probe`（resolver、既定 `~/ObsidianVault/.obsidian/`）が**設定されていて不在**なら、Vault が未同期とみなし以下を案内して**中止する**（初期テンプレートの自動生成は Sync コンフリクトでデータロスのリスクがあるため）:
  ```
  Vault が未同期/未配置です。Obsidian Sync の同期完了を待つか、
  ~/ObsidianVault/ を配置してください。
  ```
- **それ以外**（standalone で probe 未設定、または Vault 同期済みで tasks.md だけ無い）: 初回セットアップとみなし、`~/.claude/skills/shared/tasks-format.md` の「初期テンプレート」セクションに従って task_store のパスに作成してよい（親ディレクトリが無い場合はユーザーに作成を案内する）

### 4. タイトル文字数チェック (MUST、書き込み前)

タイトル本体（プロジェクトタグを除いた部分）の文字数を数える。

- **60-100 文字**: そのまま書き込み OK
- **101-150 文字**: そのまま書き込み可だが、短縮の余地がないかユーザーに 1 度だけ提案 (拒否されたらそのまま進む)
- **151 文字以上**: **書き込み禁止**。短縮版をユーザーに提案し、承認された短縮版で再チェック。ユーザーが原文維持を強く望む場合のみ例外として書き込み

詳細は `~/.claude/skills/shared/tasks-format.md` の「タスク行のフォーマット」規則参照。

### 5. Inbox セクションに追記

`## Inbox` セクションの末尾（次のセクション `## Next` の直前）にタスク行を追加する：

```
- [ ] #project/<name> <タイトル>
```

Edit ツールで `## Inbox\n\n## Next` のように空セクションの場合は、`## Inbox` の直後に挿入する。既存タスクがある場合は最後のタスク行の直後に挿入する。

### 6. 完了報告

追加したタスク行を表示して完了を報告する：

```
✓ タスクを追加しました
- [ ] #project/xxx タスクタイトル
```

## 注意事項

- **タイトルは短く保つ** (60-100 文字中心、**150 文字絶対上限**)。ステップ 4 で文字数チェック必須。詳細・進捗・コミット ID・判断メモは context.md / Obsidian ノート / コミットメッセージへ逃がす（フォーマット詳細は `~/.claude/skills/shared/tasks-format.md` 参照）
- tasks.md の場所は resolver の `task_store` が出典（既定 `~/ObsidianVault/00_meta/tasks.md`）。プロジェクトごとのファイルは作らない
- セクション見出しの表記（`## Inbox`）は変更しない
- 既存のタスク行は一切変更しない

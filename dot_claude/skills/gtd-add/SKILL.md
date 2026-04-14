---
name: gtd-add
description: タスクを ~/.claude/tasks.md の Inbox セクションに追加する。「タスクを追加」「TODO として残して」といった依頼、または他スキルからのタスク追加要求で使う。
argument-hint: [タスクタイトル]
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(basename:*), Bash(pwd)
---

# タスク追加

新規タスクを `~/.claude/tasks.md` の `## Inbox` セクションに追加する。

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

### 3. tasks.md の読み込み

`~/.claude/tasks.md` を Read で読む。ファイルが存在しない場合は `~/.claude/skills/shared/tasks-format.md` の「初期テンプレート」セクションに従って作成する。

### 4. Inbox セクションに追記

`## Inbox` セクションの末尾（次のセクション `## Next` の直前）にタスク行を追加する：

```
- [ ] #project/<name> <タイトル>
```

Edit ツールで `## Inbox\n\n## Next` のように空セクションの場合は、`## Inbox` の直後に挿入する。既存タスクがある場合は最後のタスク行の直後に挿入する。

### 5. 完了報告

追加したタスク行を表示して完了を報告する：

```
✓ タスクを追加しました
- [ ] #project/xxx タスクタイトル
```

## 注意事項

- tasks.md は `~/.claude/tasks.md`（グローバル固定）。プロジェクトごとのファイルは作らない
- セクション見出しの表記（`## Inbox`）は変更しない
- 既存のタスク行は一切変更しない

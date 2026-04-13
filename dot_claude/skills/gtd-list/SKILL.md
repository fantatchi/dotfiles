---
name: gtd-list
description: ~/.claude/tasks.md からタスクを読み込み、指定条件で表示する。「タスク一覧」「TODO を見せて」といった依頼、または他スキルからのタスク参照で使う。
argument-hint: [--all|--inbox|--next|--waiting|--someday|--done [N]|--project <name>]
allowed-tools: Read, Bash(git *), Bash(basename *), Bash(pwd)
---

# タスク一覧表示

`~/.claude/tasks.md` からタスクを読み込み、条件に応じて表示する。

## フォーマット仕様

`~/.claude/skills/shared/tasks-format.md` を参照すること。

## 引数

| 引数 | 動作 |
|---|---|
| （なし） | **現在プロジェクトの Inbox + Next** を表示 |
| `--all` | Inbox / Next / Waiting / Someday を全て表示（Done は除く、全プロジェクト） |
| `--inbox` | Inbox のみ |
| `--next` | Next のみ（全プロジェクト） |
| `--waiting` | Waiting のみ |
| `--someday` | Someday のみ |
| `--done [N]` | 直近 N 件の Done（デフォルト 10） |
| `--project <name>` | 指定プロジェクトのタスクのみ（Done 除く） |

## 手順

### 1. tasks.md の読み込み

`~/.claude/tasks.md` を Read で読む。存在しない場合は「タスクが登録されていません。`/gtd-add` で追加してください。」と案内して終了。

### 2. 現在プロジェクトの推定（引数なしの場合）

1. **ホーム判定**: `[ "$(pwd -P)" = "$HOME" ]` が真なら `<name>` を `global` とする（プロジェクト非依存タスク）。以降の手順はスキップ
2. `git rev-parse --show-toplevel` でリポジトリルートを取得
3. 取得できた場合: `basename` でディレクトリ名を取り `<name>` とする
4. git リポジトリ外の場合: `basename "$(pwd)"` を使う
5. タグ `#project/<name>` でフィルタリング

### 3. フィルタリングと表示

引数に応じて該当セクションからタスク行を抽出し、整形して表示する。

**引数なしの場合**（現在プロジェクトの Inbox + Next）:

```
## Inbox — #project/claude-config

- [ ] 新しい思いつきタスク

## Next — #project/claude-config

- [ ] gtd-list スキルの実装
- [ ] gtd-done スキルの実装

（Inbox 1 件 / Next 2 件）
```

**`--all` の場合**（全プロジェクト横断）:

- Inbox / Next / Waiting / Someday の順に表示
- 各タスク行にプロジェクトタグを付けたまま表示
- 末尾に合計件数を表示

### 表示ルール

- 引数なし・`--project` では該当プロジェクトのタグは省略してよい（セクション見出しに表示済みなので重複回避）
- `--all` やプロジェクト横断の表示ではプロジェクトタグを残す
- 空セクションの場合は「（該当タスクなし）」と表示
- `--done` の場合、Done セクションの**末尾から N 件**を表示（新しいものが下にある想定なので反転して表示）

### 4. 現在プロジェクトのタスクが 0 件の場合（引数なし）

Inbox と Next の両方が 0 件の場合は「現在プロジェクト `<name>` に Inbox / Next のタスクはありません。`/gtd-list --all` で全体を表示できます。」と案内する。

## 注意事項

- 読み込み専用。tasks.md は変更しない
- tasks.md は `~/.claude/tasks.md`（グローバル固定）

---
name: gtd-add
description: 思いつきタスクを捕捉箱（tasks.md）の Inbox セクションに **追加** する操作型スキル。動詞は「追加」専用（完了は gtd-done、表示は gtd-list）。「タスクを追加」「TODO として残して」「思いつき記録」「Inbox にメモ」「タスク登録」といった依頼で使う。書き込み先は常に捕捉箱（shared/integrations.md の task_store、既定 ~/ObsidianVault/00_meta/tasks.md）で、CWD による切り替えはしない。プロジェクトの作業キュー（.claude/tasks.md）は context-save の担当なので本スキルは触らない。
argument-hint: [タスクタイトル]
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(basename:*), Bash(pwd)
---

# タスク追加

思いつき・未分類のタスクを捕捉箱（tasks.md）の `## Inbox` セクションに追加する。

**単独動作**: このスキルは捕捉箱 1 ファイルだけに依存し、兄弟スキルが無くても動く。場所は resolver `~/.claude/skills/shared/integrations.md` の `task_store` で解決する（無ければ既定 `~/ObsidianVault/00_meta/tasks.md`）。連携なし。

**書き込み先は CWD で変わらない**（常に捕捉箱）。プロジェクト固有の「次にやること」は `/context-save` が各プロジェクトの `.claude/tasks.md` に保存するので、本スキルの守備範囲外。捕捉箱に落ちた思いつきを各プロジェクトへ振り分けるのは人の作業。

## フォーマット仕様

`~/.claude/skills/shared/tasks-format.md` を参照すること。

## 手順

### 1. 引数の確認

- `$ARGUMENTS` が空の場合はユーザーにタスクタイトルを質問する
- `$ARGUMENTS` にタイトルがあればそれを使う

### 2. プロジェクトタグ（任意）

- 引数に `#project/xxx` が含まれていればそれをそのまま使う（後で振り分ける先が決まっている場合の目印）
- 含まれていなければ**タグを付けない**。CWD からの推定はしない（捕捉箱は「どのプロジェクトか決まっていない思いつき」の置き場であり、CWD が振り分け先とは限らないため）
- ユーザーが「これは <プロジェクト> の話」と明示したときだけ、その名前で `#project/<name>` を付ける

### 3. 捕捉箱の解決と読み込み

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

**書込みは `~/.claude/skills/shared/tasks-format.md` の「書き込みプロトコル（複数 writer・MUST）」に従う**: 書き込み直前に tasks.md を再 Read し、重複見出し（同名セクション 2 回以上 → 自動編集停止）・重複タスク（同内容が既存 → 追加スキップ）をチェックする。書き戻し後はセクション見出しが各 1 回のままかだけ確認する。

`## Inbox` セクションの末尾（次のセクション `## Next` の直前）にタスク行を追加する：

```
- [ ] <タイトル>              ← 通常
- [ ] #project/<name> <タイトル>  ← 振り分け先が決まっている場合
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
- 捕捉箱の場所は resolver の `task_store` が出典（既定 `~/ObsidianVault/00_meta/tasks.md`）。本スキルはプロジェクト側の `.claude/tasks.md` を作らない・書かない（それは `context-save` の責務）
- セクション見出しの表記（`## Inbox`）は変更しない
- 既存のタスク行は一切変更しない

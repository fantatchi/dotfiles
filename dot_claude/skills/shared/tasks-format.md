# tasks.md フォーマット仕様

タスク管理スキル（`gtd-add`, `gtd-list`, `gtd-done`）および `context-save`, `context-load`, `obsidian-daily` が共通で参照するフォーマット定義。

## 場所

- **正本**: `~/ObsidianVault/_claude/tasks.md`（グローバル、Vault 配下）
- **同期**: Obsidian Sync で全 PC リアルタイム共通（モバイル含む）

## セクション構造

```markdown
# Tasks

## Inbox
（未分類の新規タスク）

## Next
（次に着手するアクション）

## Waiting
（他者/外部待ちのタスク）

## Someday
（いつかやる、保留中）

## Done
（完了済み）
```

セクションの順序と名称は固定。いずれかが欠けている場合、スキルは該当セクションを自動的に追加してよい。

## タスク行のフォーマット

```
- [ ] #project/<name> タイトル [任意メタデータ]
```

### 規則

- 先頭は `- [ ]`（未完了）または `- [x]`（完了）
- `#project/<name>` は**必須**のプロジェクトタグ
  - `<name>` はリポジトリのディレクトリ名（`basename $(git rev-parse --show-toplevel)`）が基本
  - `#project/global` は予約タグで、**プロジェクト非依存のタスク**（個人 TODO、環境整備など）を表す。ユーザーホームディレクトリ（`$HOME` 完全一致）で gtd-* を実行した場合に自動で割り当てられる
  - タグなしのタスクをスキルが検出した場合、警告する
- タイトルは自由記述
- 任意メタデータ（`@key:value` 形式）を末尾に追加してよい
  - `@since:2026-04-08` — Waiting 開始日
  - `@due:2026-04-15` — 期限
  - その他は用途に応じて

### Done の特別ルール

Done に移動する際、タイトル先頭に完了日（`YYYY-MM-DD`）を付加する：

```markdown
- [x] 2026-04-09 #project/claude-config タスク管理設計の合意
```

## 例

```markdown
# Tasks

## Inbox
- [ ] #project/mlit 地理空間 MCP の APIキー取得

## Next
- [ ] #project/claude-config gtd-list スキルの実装
- [ ] #project/blog Obsidian ブログ記事の下書き

## Waiting
- [ ] #project/mlit APIキー発行待ち @since:2026-04-08

## Someday
- [ ] GTD Weekly Review の自動化検討

## Done
- [x] 2026-04-09 #project/claude-config タスク管理の設計合意
```

## 初期テンプレート

ファイルが存在しない場合、スキルは以下の初期テンプレートを作成してよい：

```markdown
# Tasks

GTD ベースのタスクストア。Obsidian Sync で全 PC 共通同期。

## Inbox

## Next

## Waiting

## Someday

## Done
```

## パース・書き込み時の注意

- スキルは tasks.md を読み込み → 編集 → 書き戻す、の手順で操作する
- ファイルが存在しない場合は `gtd-add` / `context-save` が初期テンプレートを生成してよい
- セクション見出し（`## Inbox` 等）の前後の空行は保持する
- Done セクションは追記のみ（並び順は新しいものが上）

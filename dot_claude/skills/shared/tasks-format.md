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
- **タイトルは短く保つ** (1 行 80-150 文字目安、長くても 200 文字以内)
  - tasks.md は**タスク管理用**であり、進捗ログ / 判断メモ / コミット履歴を書く場所ではない
  - 詳細は別場所に逃がす:
    - 進行中の作業状態・判断メモ → 各プロジェクトの `.claude/context.md` / `.claude/progress.md`
    - 完了内容・コミット ID → git log / コミットメッセージ
    - 調査記録 → Obsidian Vault のノート (`_claude/log/`, `_claude/resource/` 等)
  - 補足が必要なら短い修飾語のみ追加可（例: `(現 5/10、5/22 まで)`、`(plan: docs/xxx.md)` 等）
- 任意メタデータ（`@key:value` 形式）を末尾に追加してよい
  - `@since:2026-04-08` — Waiting 開始日
  - `@due:2026-04-15` — 期限
  - その他は用途に応じて

### Done の特別ルール

Done に移動する際、タイトル先頭に完了日（`YYYY-MM-DD`）を付加する：

```markdown
- [x] 2026-04-09 #project/claude-config タスク管理設計の合意
```

## モバイル運用

### Obsidian モバイルアプリからのクイック追加

QuickAdd プラグインの `Quick Task` choice を Capture format `- [ ] #project/global {{VALUE}}` で設定し、`## Inbox` 直後に追記する。iOS では Advanced URI 経由でショートカット.app から 1 タップ起動可能：

```
obsidian://adv-uri?vault=<iOS の Vault 名>&filepath=_claude%2Ftasks.md&commandid=quickadd%3Achoice%3A<choice-id>
```

モバイル追加分は `#project/global` 固定（プロジェクト非依存タスク扱い）。業務系プロジェクト等のタスクはモバイル追加せず PC で `gtd-add` を使う。

### モバイルでの完了

タスク行先頭の `- [ ]` を `- [x]` にチェックするだけで完了扱い。日付付与は不要。次に PC で `gtd-list` を実行すると **自動的に Done セクションへ移動** する（完了日は gtd-list 実行日）。

### QuickAdd Capture format の改行必須

QuickAdd の Capture choice では `format.format` の末尾に **改行を必ず含める** こと（例: `- [ ] #project/global {{VALUE}}\n`）。改行がないと挿入位置直後の既存行と連結する（QuickAdd の `insertTextAfterPositionInBody` は `text` の後ろに改行を補わない仕様、連続追加で 1 行に複数タスクが連結する事故が起きる）。

UI 上では Capture format テキスト欄の末尾に **半角スペース 2 つ + Enter** で改行を入れる。半角スペースを置くと UI 側の trim 処理を回避でき、改行が `data.json` に保存される（参考: QuickAdd Issue #712）。

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

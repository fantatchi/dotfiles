---
name: gtd-list
description: ~/ObsidianVault/_claude/tasks.md からタスクを読み込み、指定条件で **表示** する操作型スキル。動詞は「表示」専用（追加は gtd-add、完了は gtd-done）。「タスク一覧」「TODO を見せて」「Inbox 確認」「進捗確認」「タスク表示」といった依頼、または他スキルからのタスク参照で使う。
argument-hint: [--all|--inbox|--next|--waiting|--someday|--done [N]|--project <name>]
allowed-tools: Read, Edit, Bash(git:*), Bash(basename:*), Bash(pwd), Bash(date:*)
---

# タスク一覧表示

`~/ObsidianVault/_claude/tasks.md` からタスクを読み込み、条件に応じて表示する。

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

`~/ObsidianVault/_claude/tasks.md` を Read で読む。存在しない場合は「タスクが登録されていません。`/gtd-add` で追加してください。」と案内して終了。

### 1.4. チェック済みエントリの Done 昇格（副作用）

モバイル（Obsidian モバイルアプリ）やエディタで `- [ ]` を `- [x]` にチェックしただけのエントリを Done セクションに自動移動する。

#### 手順

1. Done 以外の全セクション（Inbox / Next / Waiting / Someday）を走査
2. `- [x]` で始まる行を検出（行頭スペース・タブのバラつきは正規化して比較してよい）
3. 各検出行を Done フォーマットに正規化（**冪等性保証**、Sync 並列実行で重複日付付与を防ぐ）:
   - **既に日付付きパターン** (`- \[x\] \d{4}-\d{2}-\d{2} ` の厳密前方一致): そのまま使う（日付重複付与をしない）
   - **日付なしパターン** (`- [x] #project/xxx ...` または `- [x] xxx`): 今日の日付（`date +%Y-%m-%d`）を付与して `- [x] YYYY-MM-DD #project/xxx ...` の形にする
4. **`## Done` セクション未存在チェック**: ファイル内に `## Done` 見出しが無い場合、`## Someday` の後（または末尾）に `## Done\n\n` を生成してから挿入処理に進む
5. **複数昇格時の処理**（`Edit` ツールの `old_string` 一意性を確保するため、検出 → 削除 → Done 挿入 を 1 件ずつ反復する。検出した行を全件抽出した後にまとめて Edit せず、必ず逐次処理）:
   - 検出行を元のセクションから削除（Edit ツール）
   - 削除後、連続する空行を `\n\n` 1 つに正規化（空行 3 連続以上にしない）
   - Done セクションの**直後**（`## Done\n\n` の直後、先頭）に正規化済み行を挿入
6. 全件処理後、tasks.md の Read を再実行して構造を確認

#### 表示への反映

昇格した件数があれば通常の表示の末尾に 1 行で報告する：

```
（チェック済みの N 件を Done に昇格しました）
```

昇格 0 件なら何も報告しない。

### 1.5. Done セクションの剪定（副作用 + Daily Note への補完転記）

表示処理の前に、`## Done` セクションから**2 週間以上前のエントリを削除**する。tasks.md は直近の Done だけを保持する運用（古い完了タスクは明示的にアーカイブせず捨てる）が、月次/年次振り返り耐性のため、**削除前に Daily Note の該当日 `## Done アーカイブ` セクションへ転記**する。

#### 手順

1. しきい値日付を取得: `date -d "2 weeks ago" +%Y-%m-%d`（Linux / WSL）または `date -v-2w +%Y-%m-%d`（macOS / BSD）。どちらも失敗した場合は剪定をスキップして通常の表示処理に進む
2. `## Done` セクションの各行を走査し、`- [x] YYYY-MM-DD` 形式で始まる行の日付部分を抽出
3. 抽出した日付がしきい値日付より**厳密に前**（`< threshold`）の行を削除対象とする
4. **削除前に Daily Note へ転記**:
   - Daily Note のパス規約は `~/ObsidianVault/.obsidian/daily-notes.json` の `folder` と `format` から動的に組み立てる（例: `folder="日刊"` + `format="YYYY-MM-DD"` → `~/ObsidianVault/日刊/<YYYY-MM-DD>.md`）。設定ファイル不在時は obsidian-daily/SKILL.md の規約に従う
   - 該当日 Daily Note が存在しなければ最小限のテンプレ（`# YYYY-MM-DD` ヘッダだけ）で生成
   - Daily Note 内に `## Done アーカイブ` セクションが存在しなければ末尾に作成
   - 削除対象行を `## Done アーカイブ` セクション末尾に追記（同内容が既存なら重複追加しない、部分一致で判定）
5. tasks.md から削除対象行を Edit で削除する（空行連続化を回避するため 1 件ずつ処理し、削除後に連続空行を 1 行に正規化）
6. 日付が付いていない行・日付を抽出できない行はスキップ（削除も転記もしない）
7. 削除件数 + 転記件数を記憶

#### 表示への反映

剪定で 1 件以上削除した場合、通常の表示の末尾に 1 行で報告する：

```
（Done から N 件の古いエントリを剪定 / Daily Note へ転記しました）
```

削除が 0 件なら何も報告しない。

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

### モバイル捕捉タスクの滞留可視化

Inbox 内のタスクで `@captured-on-mobile` メタを持つものを件数集計し、表示の末尾に注意喚起を 1 行で出す（GTD の「収集」フェーズから「整理」フェーズへの移行漏れを検出）:

```
（Inbox にモバイル捕捉タスクが N 件滞留中、プロジェクトタグ振り直しが推奨されます）
```

該当が 0 件の場合は表示しない。`@captured-on-mobile` メタは QuickAdd choice の format で自動付与される想定（`shared/tasks-format.md` のモバイル運用セクション参照）。

### 4. 現在プロジェクトのタスクが 0 件の場合（引数なし）

Inbox と Next の両方が 0 件の場合は「現在プロジェクト `<name>` に Inbox / Next のタスクはありません。`/gtd-list --all` で全体を表示できます。」と案内する。

## 注意事項

- 基本は読み込み専用だが、**ステップ 1.4（Done 昇格）/ 1.5（Done 剪定）の副作用で書き込みがある**
- 上記副作用以外の目的で tasks.md を変更しない（タスクの並び替え・修正は `gtd-add` / `gtd-done` の役割）
- tasks.md は `~/ObsidianVault/_claude/tasks.md`（グローバル固定）

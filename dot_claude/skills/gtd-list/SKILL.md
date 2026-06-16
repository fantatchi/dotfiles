---
name: gtd-list
description: タスクストア（tasks.md）からタスクを読み込み、指定条件で **表示** する操作型スキル。動詞は「表示」専用（追加は gtd-add、完了は gtd-done）。「タスク一覧」「TODO を見せて」「Inbox 確認」「進捗確認」「タスク表示」といった依頼、または他スキルからのタスク参照で使う。tasks.md の場所は shared/integrations.md の task_store で解決し、無ければ既定 ~/ObsidianVault/00_meta/tasks.md。
argument-hint: [--all|--inbox|--next|--waiting|--someday|--done [N]|--project <name>]
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(basename:*), Bash(pwd), Bash(date:*)
---

# タスク一覧表示

タスクストア（tasks.md）からタスクを読み込み、条件に応じて表示する。

**単独動作と連携**: タスクストア（tasks.md）1 つだけで表示・Done 昇格・剪定まで動く（Obsidian や兄弟スキル不要）。tasks.md の場所は resolver `~/.claude/skills/shared/integrations.md` の `task_store` で解決する（無ければ既定 `~/ObsidianVault/00_meta/tasks.md`）。**連携は Done 剪定時の Daily Note 転記（`vault` があるときのみ）** だけ。

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

## コア（単独完結・連携なしで動く）

### 1. タスクストアの解決と読み込み

1. resolver `~/.claude/skills/shared/integrations.md` を Read し `task_store` を取得する（resolver が無い / `task_store` が空なら既定 `~/ObsidianVault/00_meta/tasks.md`）。以降この解決済みパスを「tasks.md」と呼ぶ
2. tasks.md を Read で読む。存在しない場合は「タスクが登録されていません。`/gtd-add` で追加してください。」と案内して終了

### 2. チェック済みエントリの Done 昇格（副作用）

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

### 3. Done セクションの剪定（副作用）

表示処理の前に、`## Done` セクションから**2 週間以上前のエントリを削除**する。tasks.md は直近の Done だけを保持する運用（古い完了タスクは明示的にアーカイブせず捨てる）。月次/年次振り返り耐性が欲しい環境では、削除前に Daily Note へ転記する（連携1、`vault` があるときのみ）。

#### 手順

1. しきい値日付を取得: `date -d "2 weeks ago" +%Y-%m-%d`（Linux / WSL）または `date -v-2w +%Y-%m-%d`（macOS / BSD）。どちらも失敗した場合は剪定をスキップして通常の表示処理に進む
2. `## Done` セクションの各行を走査し、`- [x] YYYY-MM-DD` 形式で始まる行の日付部分を抽出
3. 抽出した日付がしきい値日付より**厳密に前**（`< threshold`）の行を削除対象とする
4. **削除前に、連携1（Daily Note 転記）を実行する** — `vault` が有効なときのみ転記される。無効（standalone 等）なら転記せずそのまま削除する（古い Done は捨てる base 運用）
5. tasks.md から削除対象行を Edit で削除する（空行連続化を回避するため 1 件ずつ処理し、削除後に連続空行を 1 行に正規化）
6. 日付が付いていない行・日付を抽出できない行はスキップ（削除も転記もしない）
7. 削除件数（+ 転記できた件数）を記憶

#### 表示への反映

剪定で 1 件以上削除した場合、通常の表示の末尾に 1 行で報告する（転記の有無で文言を分ける）：

```
（Done から N 件の古いエントリを剪定しました）            ← vault 無効時
（Done から N 件の古いエントリを剪定 / Daily Note へ転記しました） ← vault 有効時
```

削除が 0 件なら何も報告しない。

### 4. 現在プロジェクトの推定（引数なしの場合）

1. **ホーム判定**: `[ "$(pwd -P)" = "$HOME" ]` が真なら `<name>` を `global` とする（プロジェクト非依存タスク）。以降の手順はスキップ
2. `git rev-parse --show-toplevel` でリポジトリルートを取得
3. 取得できた場合: `basename` でディレクトリ名を取り `<name>` とする
4. git リポジトリ外の場合: `basename "$(pwd)"` を使う
5. タグ `#project/<name>` でフィルタリング

### 5. フィルタリングと表示

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

#### 表示ルール

- 引数なし・`--project` では該当プロジェクトのタグは省略してよい（セクション見出しに表示済みなので重複回避）
- `--all` やプロジェクト横断の表示ではプロジェクトタグを残す
- 空セクションの場合は「（該当タスクなし）」と表示
- `--done` の場合、Done セクションの**末尾から N 件**を表示（新しいものが下にある想定なので反転して表示）

#### モバイル捕捉タスクの滞留可視化

Inbox 内のタスクで `@captured-on-mobile` メタを持つものを件数集計し、表示の末尾に注意喚起を 1 行で出す（GTD の「収集」フェーズから「整理」フェーズへの移行漏れを検出）:

```
（Inbox にモバイル捕捉タスクが N 件滞留中、プロジェクトタグ振り直しが推奨されます）
```

該当が 0 件の場合は表示しない。`@captured-on-mobile` メタは QuickAdd choice の format で自動付与される想定（`shared/tasks-format.md` のモバイル運用セクション参照）。

### 6. 現在プロジェクトのタスクが 0 件の場合（引数なし）

Inbox と Next の両方が 0 件の場合は「現在プロジェクト `<name>` に Inbox / Next のタスクはありません。`/gtd-list --all` で全体を表示できます。」と案内する。

## 連携（任意・対象があれば実行）

**連携の前提確認**: `~/.claude/skills/shared/integrations.md` を Read する（無ければ全キー未設定とみなす）。各連携の ［参照キー］ を resolver の「参照規約」で判定する。**(a)→(b)→(c) を上から評価し最初に真の分岐を採る**:
- **path 系キー**（vault 等）: (a) 空/未設定 → skip / (b) パスあり＋`*_probe`（無ければキー自身）存在 → 実行 / (c) パスあるが probe 不在 → skip

連携が skip されても「## コア」の表示・昇格・剪定は完走する（剪定の削除はコア側で実行される）。

### 連携1: Done 剪定エントリの Daily Note 転記 ［参照キー: vault］

コアの「Done セクションの剪定」（ステップ 3）で削除対象になった行を、**削除前に** 該当日の Daily Note の `## Done アーカイブ` セクションへ転記する。月次/年次振り返り時に古い完了タスクを辿れるようにする保険。

- `vault` が空/未設定 → 連携1 を skip（コアの剪定は転記なしで削除を続行）

#### 手順

1. Daily Note のパス規約を決める（**`daily-notes.json` を真の出典とする**）:
   - `<vault>/.obsidian/daily-notes.json` の `folder` と `format` から組み立てる（例: `folder="日刊"` + `format="YYYY-MM-DD"` → `<vault>/日刊/<YYYY-MM-DD>.md`）
   - `daily-notes.json` が読めない場合は resolver の `vault_dirs.daily`（既定 `10_daily`）を fallback とし、`<vault>/<vault_dirs.daily>/YYYYMM/<YYYY-MM-DD>.md` 等の obsidian-daily 規約に従う
2. 該当日 Daily Note が存在しなければ最小限のテンプレ（`# YYYY-MM-DD` ヘッダだけ）で生成
3. Daily Note 内に `## Done アーカイブ` セクションが存在しなければ末尾に作成
4. 削除対象行を `## Done アーカイブ` セクション末尾に追記（同内容が既存なら重複追加しない、部分一致で判定）

## 注意事項

- 基本は読み込み専用だが、**ステップ 2（Done 昇格）/ 3（Done 剪定）の副作用で書き込みがある**
- 上記副作用以外の目的で tasks.md を変更しない（タスクの並び替え・修正は `gtd-add` / `gtd-done` の役割）
- tasks.md の場所は resolver の `task_store` が出典（既定 `~/ObsidianVault/00_meta/tasks.md`）

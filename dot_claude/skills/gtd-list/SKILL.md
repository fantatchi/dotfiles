---
name: gtd-list
description: '捕捉箱（`~/ObsidianVault/00_meta/tasks.md`）のタスクを表示する（--all / --done [N]）。「タスク一覧」「TODO を見せて」「Inbox 確認」といった依頼で使う。追加は gtd-add、完了は gtd-done。プロジェクトの作業キュー（`.claude/tasks.md`）は表示しない（そちらは /context-load）。'
argument-hint: '[--all|--done [N]]'
allowed-tools: Read, Write, Edit, Bash(date:*)
---

# タスク一覧表示

**単独動作と連携**: 捕捉箱 1 ファイルだけで表示・Done 昇格・剪定まで動く（兄弟スキル不要）。場所は resolver `~/.claude/skills/shared/integrations.md` の `task_store` で解決する（無ければ既定 `~/ObsidianVault/00_meta/tasks.md`）。**連携は Done 剪定時の Daily Note 転記（`vault` があるときのみ）** だけ。

**対象は捕捉箱のみ**。プロジェクトの作業キュー（`<project>/.claude/tasks.md`）は本スキルの守備範囲外で、`/context-load` が表示する。「このプロジェクトの残タスクは？」と聞かれたら `/context-load` を案内する。

## フォーマット仕様

`~/.claude/skills/shared/tasks-format.md` を参照すること。

## 引数

| 引数 | 動作 |
|---|---|
| （なし） | **Inbox + Next** を表示（捕捉箱の主役は Inbox） |
| `--all` | Inbox / Next / Waiting / Someday を全て表示（Done は除く） |
| `--done [N]` | 直近 N 件の Done（デフォルト 10） |

セクション単位・`--project` の絞り込みオプションは廃止済み（捕捉箱が十数件に収まり不要になった）。**捕捉箱が再び肥大したら復活を検討する**（その時は絞り込みより Inbox の振り分けが滞っている疑いを先に見る）。

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
5. 検出 → 元セクションから削除 → `## Done` 直後（先頭）へ挿入、を 1 件ずつ逐次処理する（連続空行は 1 つに正規化）
6. 全件処理後、セクション見出しが各 1 回のままか確認

#### 表示への反映

昇格した件数があれば通常の表示の末尾に 1 行で報告する：

```
（チェック済みの N 件を Done に昇格しました）
```

昇格 0 件なら何も報告しない。

### 3. Done セクションの剪定（副作用）

表示処理の前に、`## Done` セクションから tasks-format.md の捕捉箱の保持期間より古いエントリ（しきい値日付より厳密に前）を削除する。**削除前に連携1（Daily Note 転記）を実行する**。`vault` が無効なら転記せず削除するので、その環境では削除が不可逆になる。

- しきい値日付は `date -d`（Linux / WSL）か `date -v`（macOS / BSD）で取得し、どちらも失敗したら剪定をスキップする
- 日付が付いていない行・抽出できない行はスキップ（削除も転記もしない）
- 削除は 1 件ずつ Edit し、連続空行を 1 行に正規化する

#### 表示への反映

剪定で 1 件以上削除した場合、通常の表示の末尾に 1 行で報告する（転記の有無で文言を分ける）：

```
（Done から N 件の古いエントリを剪定しました）            ← vault 無効時
（Done から N 件の古いエントリを剪定 / Daily Note へ転記しました） ← vault 有効時
```

削除が 0 件なら何も報告しない。

### 4. フィルタリングと表示

引数に応じて該当セクションからタスク行を抽出し、整形して表示する。**CWD によるプロジェクト推定はしない**（捕捉箱は CWD と無関係な思いつきの置き場のため）。

**引数なしの場合**（Inbox + Next）:

```
## Inbox

- [ ] 新しい思いつきタスク
- [ ] #project/asla ログ解析の改善案

## Next

- [ ] ドメイン移管の手続き

（Inbox 2 件 / Next 1 件）
```

**`--all` の場合**:

- Inbox / Next / Waiting / Someday の順に表示
- 末尾に合計件数を表示

#### 表示ルール

- `#project/<name>` タグは付いていればそのまま表示する（振り分け先の目印）
- 空セクションの場合は「（該当タスクなし）」と表示
- `--done` の場合、Done セクションの**先頭から N 件**を表示（新しい完了が上に挿入される）

#### モバイル捕捉タスクの滞留可視化

Inbox 内のタスクで `@captured-on-mobile` メタを持つものを件数集計し、表示の末尾に注意喚起を 1 行で出す（GTD の「収集」フェーズから「整理」フェーズへの移行漏れを検出）:

```
（Inbox にモバイル捕捉タスクが N 件滞留中、各プロジェクトへの振り分けが推奨されます）
```

該当が 0 件の場合は表示しない。`@captured-on-mobile` メタは QuickAdd choice の format で自動付与される想定（`shared/tasks-format.md` のモバイル運用セクション参照）。

### 5. タスクが 0 件の場合（引数なし）

Inbox と Next の両方が 0 件の場合は「捕捉箱は空です。`/gtd-add` で追加できます（プロジェクトの残タスクは `/context-load`）。」と案内する。

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

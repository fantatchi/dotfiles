---
name: consistency-check
description: プロジェクトの CLAUDE.md・テンプレート・設定ファイル間の整合性をチェックする。
argument-hint: [カテゴリ...]
allowed-tools: Read, Glob, Grep, Bash(date *), Bash(wc *)
---

# 整合性チェック

プロジェクトのマニフェスト（`.claude/consistency.json`）に基づいて、CLAUDE.md・テンプレート・設定ファイル間の整合性を検証する。

## 引数の扱い

$ARGUMENTS にカテゴリ名がスペース区切りで渡される。

- 引数なし → 全 6 カテゴリ実行
- 引数あり → 指定カテゴリのみ実行（manifest は常に暗黙実行）
- 有効なカテゴリ: `manifest`, `structure`, `photorealistic`, `identity`, `content`, `size`

## 実行手順

### フェーズ 1: マニフェスト読み込み + ファイル発見

1. `.claude/consistency.json` を Read で読み込む（存在しなければエラー終了）
2. 全サブプロジェクトの JSON ファイルを Glob で並列取得:
   - `{subproject}/*.json`（output/, history/ 配下は除外）
   - `{subproject}/styles/*.json`（styles がある場合）
3. Glob 結果とマニフェストのファイルリストを突合用に保持

### フェーズ 2: カテゴリ別チェック

実行順序: manifest → structure → photorealistic → identity → content → size

各チェックで検出した問題を重大度（CRITICAL / WARNING / INFO）付きで記録する。

---

## チェックカテゴリ詳細

### 1. manifest — マニフェスト自体の整合性

| ID | チェック | 手法 | 重大度 |
|----|---------|------|--------|
| M1 | templates の全ファイルが実在 | Glob 結果と突合 | CRITICAL |
| M2 | utilities の全ファイルが実在 | 同上 | CRITICAL |
| M3 | styles の全ファイルが実在 | 同上 | CRITICAL |
| M4 | claude_md が実在 | 同上 | CRITICAL |
| M5 | config_files が実在 | 同上 | WARNING |
| M6 | ディスク上にあるがマニフェスト未記載の JSON | Glob結果 - (templates+utilities+styles) の差分 | WARNING |
| M7 | members の id に重複がない | JSON 解析 | CRITICAL |

**M6 のスコープ**: `{subproject}/*.json` と `{subproject}/styles/*.json`。`output/`, `history/`, `members/` は除外。

### 2. structure — ファイル参照チェーン

| ID | チェック | 手法 | 重大度 |
|----|---------|------|--------|
| S1 | ルート CLAUDE.md が全サブプロジェクト名を言及 | Grep | WARNING |
| S2 | 各サブ CLAUDE.md がテンプレートの basename を言及 | Grep | WARNING |
| S3 | 各サブ CLAUDE.md がユーティリティの basename を言及 | Grep（basename 検索） | INFO |
| S4 | config_files が対応する CLAUDE.md から参照されている | Grep（basename 検索） | WARNING |

### 3. photorealistic — 画像生成ルール

対象: `type: "image-generation"` のサブプロジェクトの **templates のみ**（utilities, styles は除外）。

| ID | チェック | 条件 | 手法 | 重大度 |
|----|---------|------|------|--------|
| P1 | `global_style` セクションが存在 | require_global_style=true | Grep | CRITICAL |
| P2 | `render_style` に "photorealistic" を含む | require_global_style=true | Grep | CRITICAL |
| P3 | `negative_prompt` が存在 | require_global_style=true | Grep | CRITICAL |
| P4 | negative_prompt に anime, cartoon, illustration を含む | require_global_style=true | Grep | WARNING |
| P5 | description_prefix 指示がテンプレート内にある | description_prefix が非 null | Grep | INFO |

**require_global_style=false の場合**: P1-P4 をスキップし、INFO で「このプロジェクトは global_style を使用しない設計です」と表示。

### 4. identity — メンバー識別

**members が null の場合**: 全スキップし INFO で「固定メンバーなし」と表示。

| ID | チェック | 手法 | 重大度 |
|----|---------|------|--------|
| I1 | マルチメンバーテンプレートに `visual_identity` がある | Grep | CRITICAL |
| I2 | ソロテンプレートに `visual_identity` がある | Grep | INFO |
| I3 | 各メンバーの age がテンプレート間で一致 | Grep content → マニフェスト定義と比較 | CRITICAL |
| I4 | 各メンバーの height がテンプレート間で一致 | 同上 | CRITICAL |
| I5 | description 内の髪記述がメンバー定義と矛盾しない | hair_negative で Grep | CRITICAL |

**I1 判定**: `members` 配列（2 名以上）または `member_configurations` 配列がある = マルチメンバーテンプレート。
**I5 注意**: hair_negative の Grep ヒットが `visual_identity` 定義行自体や他メンバーの正当な記述でないかを確認する。ヒット行の周辺コンテキスト (-C 2) を取得して判断する。

### 5. content — コンテンツ品質

| ID | チェック | 手法 | 重大度 |
|----|---------|------|--------|
| C1 | `reference_image.source` が `__IMAGE__` のまま | Grep content | CRITICAL |
| C2 | 日本語テキストに連続文字重複がない | Grep: `(.)\1{2,}` で候補抽出 → 判断 | WARNING |
| C3 | プレースホルダー形式が統一されている | Grep: `__[A-Z]+__` と `\[AI generates` の分布確認 | INFO |

### 6. size — CLAUDE.md 肥大化チェック

| ID | チェック | 手法 | 重大度 |
|----|---------|------|--------|
| Z1 | 各 CLAUDE.md の行数・文字数 | Bash `wc -l -c` で全 CLAUDE.md を計測 | INFO（一覧表示のみ、閾値判定なし） |
| Z2 | ルートとサブで重複するフレーズ | ルート CLAUDE.md からキーフレーズを抽出し、各サブ CLAUDE.md に同一フレーズが存在するか Grep | WARNING |

**Z1 の出力**: 全 CLAUDE.md の行数・文字数の一覧テーブルを表示する。判定はユーザーに委ねる。

**Z2 の手法**:
1. ルート CLAUDE.md を Read で取得（size カテゴリ実行時のみ）
2. 主要な指示文のキーフレーズ（15文字以上の特徴的なフレーズ）を抽出
3. 各サブ CLAUDE.md に対して Grep で突合
4. ヒットしたフレーズと該当ファイルを WARNING として報告
5. 「ルートに書いてあるのでサブからは削除可能」と提案

---

## 実行戦略（コンテキスト節約）

- **Grep > Read**: ファイル全文は読まない。Grep の content / files_with_matches モードで必要な情報だけ取得
- **並列ツール呼び出し**: 独立したチェックは同一メッセージで並列実行
- **フェーズ分割**: マニフェスト読み込み → ファイル発見 → カテゴリ別チェック

## レポート出力

`./report-template.md` のフォーマットに従い、インラインで出力する。ファイル保存はしない。

最終行のメッセージ:
- CRITICAL がある → `CRITICAL な問題が見つかりました。修正を推奨します。`
- WARNING のみ → `WARNING があります。確認を推奨します。`
- 全 PASS → `全チェックをパスしました。`

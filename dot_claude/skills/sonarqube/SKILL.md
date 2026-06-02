---
name: sonarqube
description: SonarQube の新規違反（New Code Period）対応ワークフロー。API で違反を棚卸し → スコープ合意 → 指摘 1 件 1 コミット → typecheck/lint/test → テンプレ準拠 PR ドラフトまでを定型化する。「SonarQube 対応」「Quality Gate を直す」「新規違反をつぶす」「sonar の指摘対応」「issue #NNN の SonarQube」等で使う。
argument-hint: [issue番号]
disable-model-invocation: false
---

# SonarQube 新規違反対応ワークフロー

SonarQube の新規違反（Quality Gate 対象）を、スコープ合意 → 段階的修正 → PR まで定型手順で対応する。#314 / #325 で確立した流れを再現する。

## 前提知識（MEMORY 参照）

実行前に以下の auto memory を前提とする（cloud-cmp の `~/.claude/projects/.../memory/`）。矛盾する指示があればユーザー確認を優先。

- `reference_sonarqube_api` — REST API の直叩き手順（token / issues / hotspots / project_status のエンドポイント）
- `reference_sonarqube_new_code_period` — Quality Gate は **新コード期間基準**。overall の違反は Gate に効かない
- `feedback_commit_one_per_sonarqube_finding` — 指摘 1 件 = 1 コミット
- `feedback_pr_review_verify_before_severity` — 「複雑度 N」が新コードか既存債務かを git diff で裏取り
- `feedback_pr_review_screen_reader` — a11y/SR 系は制限事項として原則放置（SonarQube の a11y ルール S6847/S6848/S6819/S1082 等もこの方針）
- `reference_prettier_crlf_format_check` — Windows で `format:check` が一律 fail するのは CRLF×LF の環境依存事象

## 手順

### 1. 棚卸し

`reference_sonarqube_api` の手順で、Quality Gate 状況 + `inNewCodePeriod=true` の OPEN issue / TO_REVIEW hotspot を取得し、**重大度別・ルール別・ファイル別**に集計して提示する（PowerShell `Group-Object`）。CRITICAL / Security Hotspot は個別に内訳を出す。

### 2. スコープ合意（AskUserQuestion）

棚卸し結果をもとに対応範囲をユーザーと合意する。デフォルトの除外候補と確認軸:

- **対象パス**: フロントは `Ks.Web.CMP.Service/` 配下が基本。`features/`・submodule（`ks-react-components` 等）・C#（API / API.Test）は都度確認で除外しがち
- **a11y 系ルール**（S6847 / S6848 / S6819 / S1082 ほか）は原則放置（制限事項）。`feedback_pr_review_screen_reader` 準拠
- **既知のリファクタ予定ファイル**（例: `deg-formatters.ts`）は別対応として除外
- **重大度**: 「中（MAJOR）から」等の優先度をユーザーに確認

ブランチは原則 `release` 等の base から新規作成（`pr/<user>/sonarqube-<issue>`）。issue 番号は引数 or ユーザーに確認。

### 3. 修正（指摘 1 件 1 コミット）

- `feedback_commit_one_per_sonarqube_finding` に従い 1 指摘 = 1 コミット。同一ルールの機械的多数（例: ゼロ端数除去 ×5）は 1 コミットにまとめてよいが、ユーザーに粒度を確認する
- 既存コードは必ず Read してから Edit。挙動を変えないリファクタを基本とし、等価性（条件分岐・optional chain・Set 化など）を確認する
- 大きな JSX ブロックのネスト三項解消は、ブロックを動かさず `&&` ガード分解 or 関数抽出で**再インデントを避ける**と diff が最小化する
- コミットメッセージは `refactor: <何を> (SonarQube #<issue>)` + 本文に「何を・なぜ・ルール ID」。末尾に Co-Authored-By

### 4. 検証

- `npm run typecheck`（`.next` の stale 型エラーが出たら `.next/dev/types` 削除で解消）
- `npm run lint` / `npm run test`
- `format:check` が repo 全体で fail する場合は `reference_prettier_crlf_format_check` を参照（環境依存。`git diff --stat` が実変更行のみかで切り分け、安易に `--write` しない）

### 5. PR ドラフト

リポジトリに `.github/pull_request_template.md` があれば**それに準拠**して `.claude/reviews/pr-sonarqube-<issue>-description.md` に出力する（`.claude/reviews/` は gitignore 対象）。記載必須:

- 関連タスク（`fix #<issue>`。スコープ外を残す場合は自動 close 回避のため `fix` を外す注記）
- 対応内容（コミット表・重大度は「重要度：高/中/低」表記）
- 確認のポイント（「何を → どう等価か」を平易に）
- その他（**スコープ外と理由**を明示: a11y 放置 / 別リファクタ予定 / C# 対象外 等）
- チェックリストは**実際に実行したものだけ**チェック

### 6. push / PR 発行

push・PR 発行は CLAUDE.md global の方針に従う（push は明示指示が必要。PR 発行はユーザーが行う運用なら文章ドラフトまでで止める）。

## 注意

- token・認証情報の値は出力・記録しない（キー名のみ）。`reference_sonarqube_api` 準拠
- 複雑度（S3776）・a11y はローカルで測れない場合があるため、マージ後の再解析で消滅確認を次アクションに残す
- スコープ外にした項目は「Quality Gate 緑化には別途必要」と申し送る

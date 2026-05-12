---
name: spec-writing
description: 仕様書（specification / 設計ドキュメント / requirements / architecture）を書く・レビュー・改善する時に呼ばれるロール変換型スキル。読み手別の入口設計、図種の判断軸（UML / C4 / BPMN）、ADR で意思決定を分離、用語集を「唯一の出典」に格上げ、要件レベル語（MUST/SHOULD/MAY）の統一を提供する。「仕様書」「specification」「設計ドキュメント」「ドキュメントレビュー」「ADR」「アーキテクチャ図」等、仕様書・設計ドキュメント文脈の語で自動起動。単発の図描画（コードレビュー補助図・スケッチ用途）には起動しない。
---

# 仕様書作成・レビューロール

わかりやすい仕様書を **書く / レビューする / 改善する** ためのロール変換スキル。

## 基本姿勢

1. **仕様書は読み手のために存在する**。読み手別に最短ルートを提供する
2. **図は「テキストの錨」**。テキストで言える内容を図にしない、図でしか言えない「関係や遷移を一覧する」役割に絞る
3. **意思決定の根拠は ADR に分離**。本文では「何を決めたか」だけ書く
4. **用語は用語集が唯一の出典**。本文で再定義しない（IETF RFC スタイル）
5. **要件レベル語を統一**（MUST / SHOULD / MAY 相当）。QA の AC 抽出が機械的になる

## 行動指針

### 図種の判断軸（サマリ）

| 目的 | 図 | テキスト/表で十分なケース |
|---|---|---|
| システム全体の俯瞰・外部関係 | **C4 Context / Container** | 構成要素が 3 つ以下なら箇条書きで足る |
| 業務プロセス・人と組織のまたぎ | **BPMN（プール/レーン）** または簡易フロー | 1 アクター完結なら手順書で足る |
| 振る舞い・時系列の API/サービス間呼び出し | **シーケンス図** | 1 呼び出し完結なら表で足る |
| エンティティのライフサイクル | **状態遷移マトリクス（From×To）** | 状態が 3 つ以下なら表で足る |
| データ構造・関係 | **ER 図 / 軽量クラス図** | フィールド列挙だけなら表で足る |
| 意思決定の根拠 | 図は不要 | **ADR** で十分 |

詳細（UML 取捨選択 / 各図種の典型例 / テキストソース化ツール）は [references/diagram-selection.md](references/diagram-selection.md) を参照。

### テキストと図のバランス

- 各セクション冒頭に **TL;DR（2-3 行）** を必ず置く
- 図には必ず **「この図で何が言いたいか」キャプション 1 行** を付ける（図単体で意味が伝わるならテキストを削れる合図）
- **Why（背景）→ What（決めたこと）→ How（実装方法）** の三層で書く。How は省略・後回し可能

### ADR で意思決定を分離

意思決定は本文に書かず、Nygard 形式 ADR ファイルに切り出す（**1 ファイル 1 決定** で運用）。フォーマット・Status 遷移ルール・骨格・置き場は [references/adr-format.md](references/adr-format.md) を参照。

### 用語の扱い

用語集（Glossary）を **「公式語彙の唯一の出典」** と位置付ける:

- 同義語のうち 1 つを「公式語」と確定
- 他ドキュメントは用語集にリンクし、本文で別語を使わない
- 略語は初出時にフルスペル + 用語集リンク

### 要件レベル語（サマリ）

| レベル | 英語 | 日本語 | 用途 |
|---|---|---|---|
| 必須 | **MUST** / MUST NOT / SHALL | しなければならない / してはならない | 違反は仕様違反 |
| 推奨 | **SHOULD** / SHOULD NOT | 推奨する / 推奨しない | 例外時は理由を残す |
| 任意 | **MAY** / OPTIONAL | してよい | 自由選択 |

「〜する」「〜できる」「基本的に〜」のような曖昧表現は避ける。各レベルの詳細・置換表・QA への効果は [references/requirement-levels.md](references/requirement-levels.md) を参照。

## 仕様書ファイルの生成手順（新規 / 改訂）

仕様書ファイルを新規作成・改訂する時、**専用テンプレファイルは使わず**、プロジェクトの既存仕様書からスタイルを読み取って踏襲する。章立ては本スキルの判断軸に従って生成する。

### Step 1: プロジェクトの conventions を把握

プロジェクトに既存仕様書があれば、**最も近いカテゴリの 1 ファイル** を読んで以下を把握する:

- 形式（md / html / 両方）と source of truth
- パス構造（例: `docs/<category>/NN-<topic>.md` / `docs/_html/<category>/NN-<topic>.html`）
- スタイル（CSS の `:root` 変数、breadcrumb 形式、`<header class="page">`、footer 形式、`<nav class="page-nav">`）
- 命名規約（`NN-asciiname-kebab` 等）
- 用語集・README・前後ナビへのリンク方式

短く「あなたのプロジェクトは `docs/_html/architecture/NN-*.html` 形式で、CSS は `:root --bg/--surface/--accent` パターンを使っているようです。これに合わせます」と確認すると良い。

### Step 2: 章立てを当てはめる

以下をデフォルト（arc42 + Google Design Doc に基づく）とする:

1. **TL;DR** — 2-3 行の結論
2. **想定読者 / 読了時間 / Status** — 多忙な読み手はここで離脱可
3. **Context（背景）** — 何を解こうとしているか、現状の課題
4. **Goals / Non-Goals** — やること / あえてやらないこと（範囲画定）
5. **Design（設計）** — 何を決めたか
6. **Trade-offs** — 採用しなかった案と理由
7. **Open Issues** — 未確定事項（任意）
8. **改訂履歴** — 版 / 日付 / 変更

文書の性格に応じて省略・並べ替え可（ただし **TL;DR と Context は必須**）。

### Step 3: スタイルを既存に合わせる

Step 1 で把握したスタイルを踏襲して生成。CSS / breadcrumb / footer / page-nav は **既存ファイルからほぼコピー** し、色変数（`--accent` 等）だけトピックに応じて選び直す。

新規プロジェクトで既存が無い場合は [references/skeletons.md](references/skeletons.md) の最小汎用骨格（HTML / Markdown / 用語集エントリ）を fallback として使う。

### Step 4: 関連ファイルの整合性チェック

- 用語集に新規用語があれば追加（用語集は唯一の出典）
- 関連 ADR があればリンク（無ければ「関連 ADR: なし」と明示）
- 前後ナビ・README リンクを更新（プロジェクトの構造に従う）
- 改訂履歴に初版を追記

## レビューチェックリスト

書く前 / 書いた後で確認:

**構造**
- [ ] TL;DR が冒頭に置かれている（2-3 行）
- [ ] Context（背景）セクションが存在する
- [ ] 想定読者・読了時間が明示されている
- [ ] 役割別の入口（誰がどこから読むか）が示されている
- [ ] セクション順が Context → Goals/Non-Goals → Design → Trade-offs に近い

**図と本文**
- [ ] 各図にキャプション 1 行が付いている
- [ ] 図が「関係や遷移を一覧する」役割を果たしている（テキストの代替ではない）
- [ ] 図と本文の内容が一致している（古い図が残っていない）
- [ ] 図はテキストソース可能な形式（SVG / Mermaid / PlantUML、PNG 直貼り回避）

**用語・語彙**
- [ ] 用語は用語集にリンクし、本文で再定義していない
- [ ] 「〜する / できる / してよい」が要件レベル語で統一されている
- [ ] 略語は初出でフルスペル + 用語集リンク

**意思決定**
- [ ] 決定の根拠（なぜ）が本文に混ざらず ADR に分離されている
- [ ] 「Non-Goals（やらないこと）」が明示されている
- [ ] トレードオフが議論されている（採用しなかった案も）

**運用**
- [ ] Status（Draft / Reviewed / Approved）が明示されている
- [ ] 改訂履歴がある（版 / 日付 / 変更内容）

## アンチパターン

避けるべき書き方:

1. **詳細すぎる UML 病**: 全属性・全メソッドを書き、誰も読まなくなる → 関心ドメインだけ残す
2. **図と本文の不整合**: 図が古く本文が新しい → レビュー時に「図のキャプション」を必ず読み合わせる
3. **更新されない図**: PNG をコピペした PowerPoint 図が放置 → Mermaid / SVG / PlantUML / draw.io（XML）でテキストソース化
4. **用語のブレ**: 「現場 / 受注者 / 元請」が混在 → 用語集 1 つに集約
5. **「全部書く」病**: 完璧主義で永遠に未公開 → Status: Draft で先に公開し、ADR で意思決定だけ確定
6. **目次が機能しない構造**: 「設計」「仕様」など総称的ファイル名 → 「05-state-machine.md」のように番号 + 主題で物理順序を強制
7. **役割別入口の欠如**: 1 本の長大 README に全員を流し込み、誰も自分の章を見つけられない

## プロジェクト固有の設定

以下はプロジェクトの **CLAUDE.md** で指定される（スキル本体は判断軸を提供、出力形式はプロジェクト方針に従う）:

- 主出力形式（md / html / 両方）
- ADR の置き場（例: `docs/adr/`）
- 用語集の場所（例: `docs/requirements/02-glossary.md`）
- 既存仕様書のスタイル参照先（Step 1 で読むファイル）

プロジェクト個別の運用（html 主出力 / md 主出力 / ナビ規約 / ADR 連番のスタート値など）は各プロジェクトの CLAUDE.md に書き、本スキルはそれを参照する設計。

## 参考

- [arc42 Template Overview](https://arc42.org/overview) — 12 セクション固定のテンプレート
- [C4 model FAQ](https://c4model.com/faq) — Context / Container / Component / Code の 4 階層
- [ADR GitHub Organization](https://adr.github.io/) — Nygard / MADR 形式
- [Martin Fowler: ArchitectureDecisionRecord](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html)
- [Design Docs at Google (Industrial Empathy)](https://www.industrialempathy.com/posts/design-docs-at-google/)
- [RFC 7322 - RFC Style Guide](https://datatracker.ietf.org/doc/html/rfc7322)
- [Stripe API Reference](https://docs.stripe.com/api) — 3 カラム DX の参考

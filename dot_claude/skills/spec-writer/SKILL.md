---
name: spec-writer
description: '仕様書（specification / 設計ドキュメント / requirements / architecture / ADR / C4 / 用語集）の設計・作成・レビューを担うロール変換型スキル。読み手別入口・図種選択・ADR 形式・要件レベル語・テンプレ集を内蔵し、出力は md がメイン、視覚情報が主役のページのみ HTML 補足（デジタル庁デザインシステム DADS 準拠）。「仕様書」「設計ドキュメント」「ドキュメントレビュー」「ADR」「アーキテクチャ図」「C4 図」「README を充実」「オンボーディング資料」「HTML 補足ページ」「カラーパレット選定」「DADS」「文書の配色・タイポグラフィ」等で使う。単発の図解は eli5、対話的な文章共著は doc-coauthoring。'
---

# 仕様書設計ロール

## スキルの狙い

**読者が詰まる 3 つのポイント**（全体像 / なぜそうなっているか / 用語）を手厚くカバーし、それ以外は薄くする。詳細仕様はコードを読めば追えるため薄くて構わない。本文の文章規範は `japanese-doc-style` に従い、構造化（表・リスト）できる箇所は構造化を優先する。

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

上表はシステムの構造・振る舞いを描く図。詳細（UML 取捨選択 / 各図種の典型例 / テキストソース化ツール）と、対比・ツリー・ベン図・ステップ・サイクルといった**説明用の論理図パターン**（比較ページや概要ページで使う）は [references/diagram-selection.md](references/diagram-selection.md) を参照。C4 / シーケンス / 状態遷移などの **PlantUML / Mermaid 具体テンプレ** は [references/templates.md](references/templates.md) を参照。

### テキストと図のバランス

- 各セクション冒頭に **TL;DR（2-3 行）** を必ず置く
- 図には必ず **「この図で何が言いたいか」キャプション 1 行** を付ける（図単体で意味が伝わるならテキストを削れる合図）
- **Why（背景）→ What（決めたこと）→ How（実装方法）** の三層で書く。How は省略・後回し可能

### 本文の構造化（表・リスト）

構造化できるなら常に構造化する。散文としての流れが多少損なわれても構造化を優先する。フォーマットは要素間の関係で選び、**上位から順に適用できないか**を検討する（比較軸も順序も無いのに上位を無理に使う必要はない）:

| 優先 | フォーマット | 適用基準 |
|---|---|---|
| 1 | **表** | 複数の項目に共通の比較軸・属性がある |
| 2 | **ラベル付きリスト** | 抽象度や粒度が異なり、単純な並列にできない |
| 3 | **番号付きリスト** | 手順・時系列・優先順位など順序に意味がある（並べ替えても意味が通るなら番号を付けない） |
| 4 | **箇条書き** | 粒度が揃っており、単に並列に列挙できる |

記号は意味で使い分ける。`-` は順序のない並列、`1.` は手順・順序または「2 番目の項目ですが」と指し示して議論したいとき、`A.` `B.` は読み手に比較・選択を促す選択肢に使う。

リスト・表の記述ルール: 同じ階層は視点と品詞を揃える / 抽象度の違うものを同列に置かず下位概念はネストする / リスト・表の直前に導入文を置く / 各項目は指示語なしで単体で意味が通るように書く / 因果をネストで表現しない（階層は包含関係に限る）。視覚面は [references/communicative-design.md](references/communicative-design.md) の原則 10・11 を参照。

### ADR で意思決定を分離

意思決定は本文に書かず、ADR ファイルに切り出す（**1 ファイル 1 決定** で運用）。形式（Nygard / MADR）の選択基準・骨格・Status 遷移ルール・置き場は [references/adr-format.md](references/adr-format.md) を参照。

### 用語の扱い

用語集（Glossary）を **「公式語彙の唯一の出典」** と位置付ける:

- 同義語のうち 1 つを「公式語」と確定
- 他ドキュメントは用語集にリンクし、本文で別語を使わない
- 略語は初出時にフルスペル + 用語集リンク。略語を使うのは、短縮効果が大きく、かつ文書中の出現回数が多いときに限る（濫用は正確性を損ね認知負荷を上げる）

公式語は正確性・一貫性・適合性で選ぶ。**顧客向けは顧客社内で通じる語を優先**し、開発者向けは業界標準語を優先する。多義的な用語は、**それが何でないか（What it is NOT）を併記**して境界を決める。

用語集の具体テンプレ（ビジネス用語 / 技術用語 / 略語のカテゴリ分け例）は [references/templates.md](references/templates.md) を参照。

### 要件レベル語（サマリ）

| レベル | 英語 | 日本語 | 用途 |
|---|---|---|---|
| 必須 | **MUST** / MUST NOT / SHALL | しなければならない / してはならない | 違反は仕様違反 |
| 推奨 | **SHOULD** / SHOULD NOT | 推奨する / 推奨しない | 例外時は理由を残す |
| 任意 | **MAY** / OPTIONAL | してよい | 自由選択 |

「〜する」「〜できる」「基本的に〜」のような曖昧表現は避ける。各レベルの詳細・置換表・QA への効果は [references/requirement-levels.md](references/requirement-levels.md) を参照。

## 採用するドキュメント手法

| 手法 | 使う場面 |
|---|---|
| **C4 モデル + ADR**（既定） | ほとんどのプロジェクト。C4 は Level 1（Context）と Level 2（Container）で価値の大半が出る |
| **arc42** | 規制業界・大規模で網羅性が要る（12 章固定で書く側が迷わない） |
| **Docs as Code** | 運用方式として常に（md + Git、HTML / PDF は自動ビルド） |
| **LLM 可読仕様書（LRS）** | AI エージェントによる自動実装前提の API 仕様など、ピンポイントで（OpenAPI 3.1 / Protobuf を強制） |
| **Diátaxis** | 「README 充実」「ドキュメント整備」のようにどの種類の文書を書くべきか自体が曖昧な依頼。判断軸は [references/diataxis.md](references/diataxis.md) |

## 出力フォーマットのすみ分け

**md がメイン、HTML が補足** の使い分けを基本とする:

| フォーマット | 担うコンテンツ |
|---|---|
| **Markdown（メイン）** | 仕様本文、API リスト、ADR、用語集、ガイドライン、章立て構造、コードブロック、Mermaid / PlantUML の簡易図。GitHub 管理の Docs as Code |
| **HTML（補足）** | サマリーページ / 概況ランディング / システム概要 / 比較・対比ページ / 配色で意味を伝える表 / 「ぱっと見で構造を伝えたい」もの。視覚情報が主役のページに限定 |

**HTML 補足ページを書くときの視覚設計は [references/visual-encoding.md](references/visual-encoding.md) を必ず参照** する。デジタル庁ダッシュボードデザインガイドブック由来の設計原則（配色 1〜5 色、コントラスト比 3:1 以上、装飾排除、図表タイトル命名、アクセシビリティ）が直接適用できる。

### 視覚デザイン全般: 「伝わるデザイン」原則を意識する

HTML / PDF / md いずれの媒体でも、配色以外のデザイン原則は **「伝わるデザイン」(<https://tsutawarudesign.com/>)** の考え方を意識して作成する。整列・近接・反復・ジャンプ率・余白・タイポグラフィ・箇条書き・表・図解など、誰が読んでも伝わりやすい視覚整理の 12 原則 + 約物ルールは [references/communicative-design.md](references/communicative-design.md) に集約しており、新規 HTML / PDF 出力時の設計判断・レビューチェックリストとして使う。配色は [references/visual-encoding.md](references/visual-encoding.md) を参照する役割分担とする。

### デフォルト CSS テンプレートと配色（DADS 準拠）

HTML 補足ページを新規に生成する際の **既定のスタイルは デジタル庁デザインシステム (DADS) v2.0.1 準拠** とする（key-color = Blue 固定）。

| 項目 | デフォルト値 | 出典・参照 |
|---|---|---|
| `--accent-deep` (本文リンク) | `#0017c1` (Blue 900) | `references/dads-tokens.md` 1 節 |
| `--accent` (UI primary = key-color) | `#264af4` (Blue 700) | 同上 |
| `--accent-bg` (badge 背景) | `#e8f1fe` (Blue 50) | 同上 |
| `--accent-ink` (本文・濃文字) | `#1a1a1a` (Solid Gray 900) | `references/dads-tokens.md` 3 節 |
| 日本語フォント | Noto Sans JP | `references/dads-tokens.md` 5 節 |
| 等幅フォント | Noto Sans Mono | 同上 |
| UD 保険 fallback | BIZ UDPGothic / BIZ UDGothic | `references/communicative-design.md` 原則 7 |

優先順位:

1. **プロジェクト固有指定がある場合**（CLAUDE.md / 既存仕様書のスタイル / ブランドガイド等）→ それを最優先で踏襲
2. **指定がない・新規プロジェクト・既存スタイル無し** → DADS 準拠（key-color Blue）をデフォルト採用

**ベースカラーは Blue 固定**（spec-writer のデフォルト）。プロジェクトのブランド要請等で別色を採用する場合は [`references/dads-tokens.md`](references/dads-tokens.md) 2 節の DADS プリミティブ 10 色族（Blue / Light Blue / Cyan / Green / Lime / Yellow / Orange / Red / Magenta / Purple）から選び、選定 ADR を残す（テンプレは [references/adr-format.md](references/adr-format.md) の「## カラー選定 ADR テンプレ」）。**HEX 値の正本は `references/dads-tokens.md` のみ**、他ファイルで再掲する場合は出典として「dads-tokens.md N 節」を明示する（drift 防止）。

### HTML 補足ページの CSS 集約方針（複数ページ作成時 SHOULD）

集約は **ソース管理レベル（SSOT）** の話であり、**配布物（生成された HTML）は常に self-contained** とする（社内に静的ホスティング場が無く、共有は「リポジトリ管理 + HTML 単体ファイル配布」で行う運用判断に基づく）。

HTML 補足ページの本数に応じて要件レベルを切り替える:

| 状況 | 要件レベル | 採用パターン |
|---|---|---|
| 補足ページが **2 本以上 or 増える見込み** | **SHOULD**（強く推奨） | SSOT 共通 CSS + 生成時インライン展開（下記ルール） |
| 補足ページが **1 本のみ**（単発） | **MAY** | `<style>` 内に最小装飾を直書きしてよい（もともと self-contained、[references/templates.md](references/templates.md) の骨格） |

**SSOT + 生成時インライン展開のルール**（SHOULD 採用時）:

- 共通 CSS は `_shared/spec-page.css` 等に SSOT として置く。**スタイル編集は必ず SSOT 側で行う（MUST）**
- 各 HTML へは `<link>` 参照ではなく、生成・更新時に SSOT 全文を `<style data-shared-source="...">` ブロックへインライン展開する（先頭に「SSOT の生成時コピー・直接編集禁止」コメント必須）
- SSOT を変更したら同プロジェクトの全 HTML 補足ページへ再展開して伝播する（対象は `grep -rl 'data-shared-source'` で列挙）。**展開・検証は TS スクリプト雛形 [`references/expand-shared-css.ts`](references/expand-shared-css.ts) を各リポジトリへコピーして機械化する（SHOULD）**。「SSOT 編集 → 展開 → 1 コミット」が MUST、`--check` を pre-commit / CI に組み込む（例は [references/html-css-centralization.md](references/html-css-centralization.md)）
- self-contained を壊さないため外部資産を埋め込まない（MUST）。図はインライン SVG / data URI、`<img src>` や外部 `.svg` 参照は不可。Google Fonts CDN `<link>` のみ例外で残す
- 各 HTML の固有 `<style>` は `:root` 固有変数のみ（10-30 行程度）。`html, body { ... }` や `.toc { ... }` などのレイアウトは書かない
- 各 HTML の `<body>` に `class="page-X"`（X はファイル名 kebab-case）を付与し、各ページ固有レイアウトは SSOT 側で `body.page-X .selector { ... }` の scope を付けて集約

旧 `<link>` 参照型は HTML 単体で開けないため採らない。共通 CSS の最小骨格・移行手順・`:root` 変数命名規則・ページ別 scope は [references/html-css-centralization.md](references/html-css-centralization.md)、`docs/` の配置パターンは [references/docs-tree.md](references/docs-tree.md) を参照。

## 仕様書ファイルの生成手順（新規 / 改訂）

**専用テンプレファイルは使わず**、プロジェクトの既存仕様書（最も近いカテゴリの 1 ファイル）からスタイル・パス構造・命名・ナビ方式を読み取って踏襲する。章立ては本スキルの判断軸に従って生成する。

### Step 1: 読み手を確認

誰が読むか / 何のために読むか / プロジェクトの規模と段階 / 既存ドキュメントの状態（ゼロから・改善・部分追加）を確認する。

### Step 2: 章立てを当てはめる

以下をデフォルト（arc42 + Google Design Doc に基づく）とする:

1. **TL;DR** — 2-3 行の結論
2. **想定読者 / 読了時間 / Status** — 多忙な読み手はここで離脱可
3. **Context（背景）** — 何を解こうとしているか、現状の課題
4. **Goals / Non-Goals** — やること / あえてやらないこと（範囲画定）
5. **Design（設計）** — 何を決めたか
6. **Trade-offs** — 採用しなかった案と理由
7. **Open Issues** — 未確定事項（任意）
8. **Appendix（付録）** — 全項目の比較表・性能試験の生データ・検討の過程など、判断には要らないが参照されうる詳細（任意）
9. **改訂履歴** — 版 / 日付 / 変更

文書の性格に応じて省略・並べ替え可（ただし **TL;DR と Context は必須**）。本文には読み手の関心事（コスト・リスク・期間）に直結するロジックだけを残し、それ以外は Appendix に分離する。

**現実的な着手手順**: 一度に全部書こうとせず、**README → 用語集 → C4 Level 1（System Context）→ ADR** から始めて骨格を作る。機能仕様は実装と並行して書く（事前に書きすぎない）。

推奨 `docs/` ディレクトリ構成と各ファイルの役割は [references/docs-tree.md](references/docs-tree.md) を参照。

### Step 3: スタイル

既存スタイルがあれば踏襲し、無ければ「デフォルト CSS テンプレートと配色（DADS 準拠）」節の値を採用する。骨格の fallback は [references/skeletons.md](references/skeletons.md)（最小汎用骨格）と [references/templates.md](references/templates.md)（README / ADR / C4 PlantUML / 用語集の具体テンプレ）。

### Step 4: 関連ファイルの整合性チェック

- 用語集に新規用語があれば追加（用語集は唯一の出典）
- 関連 ADR があればリンク（無ければ「関連 ADR: なし」と明示）
- 前後ナビ・README リンクを更新（プロジェクトの構造に従う）
- 改訂履歴に初版を追記

ワークフロー全体（新規 / 既存改善 / HTML 補足ページ作成）の詳細は [references/workflow.md](references/workflow.md) を参照。

## レビューの要点

読者の 3 つの詰まりポイントを最優先で確認する: 全体像が掴める入口（README / C4 Level 1）があるか / なぜそうなっているかが ADR に残っているか / 用語が用語集で定義され本文で再定義されていないか。

加えて避ける書き方: 時間に依存する表現（「最新」「現在」はバージョン・日付・条件で書く）/ 指示語のリンクテキスト（「こちら」）/ コードブロックへのプロンプト記号・説明文の混入 / テキストを画像で貼る・GUI を位置だけで説明する。

## プロジェクト固有の設定

主出力形式（md / html / 両方）・ADR の置き場と形式・用語集の場所・既存仕様書のスタイル参照先・ナビ規約・ADR 連番の開始値はプロジェクトの **CLAUDE.md** で指定され、本スキルはそれを参照する。

## 参考

- [テクニカルライティングガイドライン（フューチャー株式会社）](https://future-architect.github.io/arch-guidelines/documents/forTechnicalWriting/technical_writing_guidelines.html) — 本文の構造化・用語選定の出典
- [デジタル庁デザインシステム DADS](https://design.digital.go.jp/dads/) / [@digital-go-jp/design-tokens](https://github.com/digital-go-jp/design-tokens) — 取込版は v2.0.1、`references/dads-tokens.md` に静的転記

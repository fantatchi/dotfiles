---
name: spec-writer
description: >-
  仕様書 (specification / 設計ドキュメント / requirements / architecture / ADR / C4 / 用語集) の設計・作成・レビューを担うロール変換型スキル。読み手別入口・図種選択 (UML/C4/BPMN)・ADR Nygard/MADR・MUST/SHOULD/MAY 要件レベル語・テンプレ集を内蔵。出力は md がメイン (Docs as Code)、視覚情報が主役のページのみ HTML 補足 (デフォルトはデジタル庁デザインシステム DADS v2.0.1 準拠、key-color = Blue 固定で JIS X 8341-3 AA を自動充足)。「仕様書」「specification」「設計ドキュメント」「ドキュメントレビュー」「ADR」「アーキテクチャ図」「C4 図」「READMEを充実」「オンボーディング資料」「HTML 補足ページ」「HTML 補足ページの CSS 集約」「カラーパレット選定」「DADS」「デジタル庁デザインシステム」「key-color」「文書の配色・タイポグラフィ」等で自動起動。棲み分け: 対話的な文章共著は doc-coauthoring、単発の図描画 (コードレビュー補助図・スケッチ) には起動しない。
---

# 仕様書設計ロール

わかりやすい仕様書を **書く / レビューする / 改善する** ためのロール変換スキル。

## スキルの狙い

仕様書の最大の失敗は「書きすぎ」と「書かなさすぎ」の両極端である。本スキルは、**読者が詰まる 3 つのポイント**を手厚くカバーし、それ以外は薄くするという塩梅を実現する。

読者が詰まる 3 つのポイント:

1. **全体像** — システム全体が何をしているのか俯瞰できない
2. **なぜそうなっているか** — 過去の意思決定の背景が不明
3. **用語** — プロジェクト固有の言葉が定義されていない

詳細仕様はコードを読めば追えるため、薄くて構わない。

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

上表はシステムの構造・振る舞いを描く図。詳細（UML 取捨選択 / 各図種の典型例 / テキストソース化ツール）は [references/diagram-selection.md](references/diagram-selection.md) を参照。C4 / シーケンス / 状態遷移などの **PlantUML / Mermaid 具体テンプレ** は [references/templates.md](references/templates.md) を参照。

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

リスト・表の記述ルール:

1. **粒度を揃える** — 同じ階層の要素は視点（主語）と品詞（文末）を統一する。ユーザー操作の手順に「ログイン完了画面が表示される」（システム視点）を混ぜない
2. **MECE を保つ** — 抽象度の違うものを同列に置かない。「可用性 / セキュリティ強化 / SQL インジェクション対策 / 性能要件」は 3 つ目だけ具体で 2 つ目とダブっている。下位概念はネストする
3. **リスト・表の直前に導入文を置く** — 読み手は、これが前提条件なのか作業手順なのかを知ってから読み始められる（例:「本作業を開始する前に、以下の前提条件を満たしているか確認する」）
4. **項目単体で意味が通じるように書く** — 「これを適用する」「前述の構成図を参照」のような指示語・省略を使わない。「セキュリティパッチを本番環境へ適用する」「システム構成図（2-1 節）を確認する」と書く
5. **因果をネストで表現しない** — 階層は包含関係（分類）に限って使う。「原因 → 結果」はインデントで示さず、1 文にまとめるか【原因】【結果】のラベルを付けて同列に並べる

視覚面（行頭・ぶら下げ・階層記号の統一、罫線の最小化）は [references/communicative-design.md](references/communicative-design.md) の原則 10・11 を参照。

### 具体例の使い方

具体例は抽象概念と読み手の認識を一致させる手段だが、過剰だとノイズになり伝達効率を下げる。

**書くべき場面**

- **境界値・異常系の振る舞い** — 正常系は直感で読めるが、エッジケースは解釈が割れる。「有効期限が 3 月 31 日の場合、3 月 31 日 23:59:59 の決済完了までを適用対象とし、4 月 1 日 00:00:00 以降は適用外とする」
- **定性的な表現の水準合わせ** — 「重大なインシデント（例: 顧客情報の誤送信、認証情報の漏洩）」。ただし数値化できるなら例示より数値化が原則（「大容量」→「10MB 以上」）

**書かない方がよい場面**

- **読み手と共通認識が取れている概念** — 一部だけ例示すると「なぜこれだけ挙がっているのか」という不要な推測を生む
- **条件分岐が複雑な場合** — 散文での例示ではなく決定表・状態遷移表に切り替える

**例示は網羅性を保証しない**。認識の漏れを許さない場面では、中途半端な例示ではなく (a) 定義済みドキュメントへの参照に一本化、(b) 全量列挙、(c) 包含・除外条件の明示（「〜を含む全項目」「〜を除く全データ」）のいずれかを選ぶ。

### ADR で意思決定を分離

意思決定は本文に書かず、ADR ファイルに切り出す（**1 ファイル 1 決定** で運用）。形式（Nygard / MADR）の選択基準・骨格・Status 遷移ルール・置き場は [references/adr-format.md](references/adr-format.md) を参照。

ADR で最も価値があるのは **Consequences（結果）** セクション。デメリットやトレードオフを正直に書くことが将来の保守者への最大の贈り物になる。

### 用語の扱い

用語集（Glossary）を **「公式語彙の唯一の出典」** と位置付ける:

- 同義語のうち 1 つを「公式語」と確定
- 他ドキュメントは用語集にリンクし、本文で別語を使わない
- 略語は初出時にフルスペル + 用語集リンク。略語を使うのは、短縮効果が大きく、かつ文書中の出現回数が多いときに限る（濫用は正確性を損ね認知負荷を上げる）

どの語を公式語に選ぶかは 3 基準で判断する:

- **正確性** — 公式ドキュメントの定義と乖離していないか（「ロールを認証する」ではなく「ロールを認可する」）
- **一貫性** — 1 概念に 1 用語が対応しているか。「ユーザー / アカウント / お客様」が同じ対象を指して混在していないか
- **適合性** — 読み手の語彙に合っているか。**顧客向けは顧客社内で通じる語を優先**し（業界標準の「データスチュワード」より顧客が使う「データ管理者」）、開発者向けは業界標準語を優先して曖昧さを排除する。技術とビジネスの翻訳は書き手の責務で、読み手に押し付けない

多義的な用語は、**それが何でないか（What it is NOT）を併記**して境界を決める。「本計画書の『性能』はオンラインレスポンス時間を指し、夜間バッチの処理時間は含まない」。「トランザクション」「バックログ」のようにビジネス側とエンジニア側で定義がずれる語は設計漏れの温床になるため、用語集に対象外まで書く。

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
| `--link` (本文リンク) | `#0017c1` (Blue 900) | `references/dads-tokens.md` 1 節 |
| `--key-color` (UI primary) | `#264af4` (Blue 700) | 同上 |
| `--accent-bg` (badge 背景) | `#e8f1fe` (Blue 50) | 同上 |
| `--accent-ink` (本文・濃文字) | `#1a1a1a` (Solid Gray 900) | `references/dads-tokens.md` 3 節 |
| 日本語フォント | Noto Sans JP | `references/dads-tokens.md` 5 節 |
| 等幅フォント | Noto Sans Mono | 同上 |
| UD 保険 fallback | BIZ UDPGothic / BIZ UDGothic | `references/communicative-design.md` 原則 7 |

採用理由: DADS は **JIS X 8341-3:2016 AA 準拠** を担保する公的標準で、配色・タイポ・コントラスト体系がアクセシビリティ要件を自動充足する。Noto Sans JP は DADS 採用フォントで OS 横断の高い可読性を提供し、Noto Sans Mono は CJK + Latin 等幅で技術文書のコード / 数値表示にも対応する。「なぜこの色 / フォントか」の説明コストが消え、プロジェクトを跨いだ一貫性が得られる。

優先順位:

1. **プロジェクト固有指定がある場合**（AGENTS.md / 既存仕様書のスタイル / ブランドガイド等）→ それを最優先で踏襲
2. **指定がない・新規プロジェクト・既存スタイル無し** → DADS 準拠（key-color Blue）をデフォルト採用

**ベースカラーは Blue 固定**（spec-writer のデフォルト）。プロジェクトのブランド要請等で別色を採用する場合は [`references/dads-tokens.md`](references/dads-tokens.md) 2 節の DADS プリミティブ 10 色族（Blue / Light Blue / Cyan / Green / Lime / Yellow / Orange / Red / Magenta / Purple）から選び、選定 ADR を残す（テンプレは [references/adr-format.md](references/adr-format.md) の「## カラー選定 ADR テンプレ」）。**HEX 値の正本は `references/dads-tokens.md` のみ**、他ファイルで再掲する場合は出典として「dads-tokens.md N 節」を明示する（drift 防止）。

### HTML 補足ページの CSS 集約方針（複数ページ作成時 SHOULD）

集約は **ソース管理レベル（SSOT）** の話であり、**配布物（生成された HTML）は常に self-contained** とする（2026-06-10 再定義。社内に静的ホスティング場が無く、共有は「リポジトリ管理 + HTML 単体ファイル配布」で行う運用判断に基づく）。

HTML 補足ページの本数に応じて要件レベルを切り替える:

| 状況 | 要件レベル | 採用パターン |
|---|---|---|
| 補足ページが **2 本以上 or 増える見込み** | **SHOULD**（強く推奨） | SSOT 共通 CSS + 生成時インライン展開（下記ルール） |
| 補足ページが **1 本のみ**（単発） | **MAY** | `<style>` 内に最小装飾を直書きしてよい（もともと self-contained、[references/templates.md](references/templates.md) の骨格） |

**SSOT + 生成時インライン展開のルール**（SHOULD 採用時）:

- 共通 CSS は `_shared/spec-page.css` 等に SSOT として置く。**スタイル編集は必ず SSOT 側で行う（MUST）**
- 各 HTML へは `<link>` 参照ではなく、生成・更新時に SSOT 全文を `<style data-shared-source="...">` ブロックへインライン展開する（先頭に「SSOT の生成時コピー・直接編集禁止」コメント必須。**全文を省略・要約・畳み込みせず転記する**）
- SSOT を変更したら同プロジェクトの全 HTML 補足ページへ再展開して伝播する（対象は `grep -rl 'data-shared-source'` で列挙）。**展開・検証は TS スクリプト雛形 [`references/expand-shared-css.ts`](references/expand-shared-css.ts) を各リポジトリへコピーして機械化する（SHOULD）**。スクリプト導入時は「SSOT 編集 → 展開 → 1 コミット」が MUST、`--check` を pre-commit / CI に組み込めば drift 放置を防げる
- **pre-commit 統合例（推奨）**: リポ root に `.git/hooks/pre-commit` を作成し以下を入れる:
  ```bash
  #!/bin/sh
  npx tsx scripts/expand-shared-css.ts --check || {
    echo "ERROR: SSOT と HTML のインライン展開に drift があります。"
    echo "  npx tsx scripts/expand-shared-css.ts で再展開してから commit してください。"
    exit 1
  }
  ```
  GitHub Actions なら CI の lint ジョブで同じコマンドを走らせる。コストはほぼゼロで、SSOT 編集を忘れて HTML 直編集する事故を構造的に防げる
- self-contained を壊さないため外部資産を埋め込まない（MUST）。図はインライン SVG / data URI、`<img src>` や外部 `.svg` 参照は不可。Google Fonts CDN `<link>` のみ例外で残す
- 各 HTML の固有 `<style>` は `:root` 固有変数のみ（10-30 行程度）。`html, body { ... }` や `.toc { ... }` などのレイアウトは書かない
- 各 HTML の `<body>` に `class="page-X"`（X はファイル名 kebab-case）を付与し、各ページ固有レイアウトは SSOT 側で `body.page-X .selector { ... }` の scope を付けて集約

**理由**: (1) 個別ファイル内 `<style>` で共通 CSS を上書きしてしまう事故を防ぎ、複数ファイルでの視覚一貫性（フォント・h1 サイズ・配色）を保証する。「伝わるデザイン」原則 3（反復）の最終的な担保（[references/communicative-design.md](references/communicative-design.md) 参照）。(2) **HTML 1 ファイル単体で共有・閲覧できる**（リポジトリ checkout 不要、ダウンロード・チャット添付でそのまま開ける）。旧 `<link>` 参照型は (2) が成立しないため採らない。

**実証例（規模）**: 共通 CSS を単一ファイルで 3000 行規模まで運用し、ファイル別 scope で全レイアウトを統合できる（各 HTML の固有 `<style>` は 10-30 行、`:root` 固有変数のみ）。スタイル骨格の出典は **DADS v2.0.1**。

具体的な共通 CSS の最小骨格・移行手順・`:root` 変数命名規則・ページ別 scope の書き方は [references/html-css-centralization.md](references/html-css-centralization.md) を参照。

ファイル配置パターン例:

```
docs/
├── *.md                  # 仕様本文・ADR・用語集（メイン）
└── _html/
    ├── overview.html     # システム概要ランディング
    ├── summary/          # サマリー・概況ページ
    └── compare/          # 比較・対比ページ
```

詳細な配置パターン・推奨ツリーは [references/docs-tree.md](references/docs-tree.md) を参照。

## 仕様書ファイルの生成手順（新規 / 改訂）

仕様書ファイルを新規作成・改訂する時、**専用テンプレファイルは使わず**、プロジェクトの既存仕様書からスタイルを読み取って踏襲する。章立ては本スキルの判断軸に従って生成する。

### Step 1: 読み手と既存状態を確認

実装に入る前に必ず以下を確認する:

1. **誰が読むか** — 発注者 / 開発者 / 新規参画者 / 運用担当者 / 自分（将来の）
2. **何のために読むか** — 合意形成 / 実装の指針 / オンボーディング / 障害対応
3. **プロジェクトの規模と段階** — スタートアップ初期 / 成長期 / エンタープライズ / 規制対象
4. **既存ドキュメントの状態** — ゼロから / 改善 / 部分追加

これらが不明な場合、簡潔に質問してから着手する。

次に、プロジェクトに既存仕様書があれば **最も近いカテゴリの 1 ファイル** を読んで以下を把握する:

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
8. **Appendix（付録）** — 全項目の比較表・性能試験の生データ・検討の過程など、判断には要らないが参照されうる詳細（任意）
9. **改訂履歴** — 版 / 日付 / 変更

文書の性格に応じて省略・並べ替え可（ただし **TL;DR と Context は必須**）。本文には読み手の関心事（コスト・リスク・期間）に直結するロジックだけを残し、それ以外は Appendix に分離する。

**現実的な着手手順**: 一度に全部書こうとせず、**README → 用語集 → C4 Level 1（System Context）→ ADR** から始めて骨格を作る。機能仕様は実装と並行して書く（事前に書きすぎない）。

推奨 `docs/` ディレクトリ構成と各ファイルの役割は [references/docs-tree.md](references/docs-tree.md) を参照。

### Step 3: スタイルを既存に合わせる

Step 1 で把握したスタイルを踏襲して生成。CSS / breadcrumb / footer / page-nav は **既存ファイルからほぼコピー** し、色変数（`--accent` 等）だけトピックに応じて選び直す。新規プロジェクトや既存スタイルが無い場合、`--accent` は DADS key-color = Blue 700 (`#264af4`)、`--accent-deep` は Blue 900 (`#0017c1`、本文リンク用)、フォントは Noto Sans JP + Noto Sans Mono を採用（「デフォルト CSS テンプレートと配色（DADS 準拠）」節および `references/html-css-centralization.md` 参照）。別系統 (Light Blue / Green 等) を採用したい場合は [`references/dads-tokens.md`](references/dads-tokens.md) 2 節の DADS プリミティブ 10 色族から HEX を引いて差し替え、選定 ADR を残す（[`references/adr-format.md`](references/adr-format.md) カラー選定 ADR）。

新規プロジェクトで既存が無い場合は [references/skeletons.md](references/skeletons.md) の最小汎用骨格（HTML / Markdown / 用語集エントリ）、あるいは [references/templates.md](references/templates.md) の具体テンプレ（README / ADR Nygard・MADR / C4 PlantUML / 用語集）を fallback として使う。

**HTML 補足ページの視覚設計**（配色パレット選定 / コントラスト比 / 色数制約 / 装飾排除 / 図表タイトル命名 / アクセシビリティ）は [`references/visual-encoding.md`](references/visual-encoding.md) を参照。デジタル庁ダッシュボードデザインガイドブックの設計原則のうち、チャート種選択以外のほぼ全てが仕様書文書にも転用可能。

役割分担:
- **構造**（何を書くか・どう構造化するか）: 章立て、用語集、ADR、要件レベル語、図種選択、md/HTML 配置判断
- **視覚**（どう見せるか）: HTML 補足ページの配色・タイポ・装飾・アクセシビリティ → [`references/visual-encoding.md`](references/visual-encoding.md) / [`references/communicative-design.md`](references/communicative-design.md)

### Step 4: 関連ファイルの整合性チェック

- 用語集に新規用語があれば追加（用語集は唯一の出典）
- 関連 ADR があればリンク（無ければ「関連 ADR: なし」と明示）
- 前後ナビ・README リンクを更新（プロジェクトの構造に従う）
- 改訂履歴に初版を追記

ワークフロー全体（新規 / 既存改善 / HTML 補足ページ作成）の詳細は [references/workflow.md](references/workflow.md) を参照。

## レビューチェックリスト

書く前 / 書いた後で確認:

**読者の 3 つの詰まりポイント（最重要）**
- [ ] **全体像** が掴める入口（README / C4 Level 1）があるか
- [ ] **なぜそうなっているか**（過去の意思決定の背景）が ADR に残っているか
- [ ] **用語** が用語集で定義され、本文で再定義されていないか

**構造**
- [ ] TL;DR が冒頭に置かれている（2-3 行）
- [ ] Context（背景）セクションが存在する
- [ ] 想定読者・読了時間が明示されている
- [ ] 役割別の入口（誰がどこから読むか）が示されている
- [ ] セクション順が Context → Goals/Non-Goals → Design → Trade-offs に近い
- [ ] 表・リストの直前に導入文があり、各項目が単体で意味を持つ（指示語で前を読み返させていない）
- [ ] 同列に並ぶ項目の粒度（視点・品詞・抽象度）が揃い、下位概念はネストされている

**図と本文**
- [ ] 各図にキャプション 1 行が付いている
- [ ] 図が「関係や遷移を一覧する」役割を果たしている（テキストの代替ではない）
- [ ] 図と本文の内容が一致している（古い図が残っていない）
- [ ] 図はテキストソース可能な形式（SVG / Mermaid / PlantUML、PNG 直貼り回避）

**用語・語彙**
- [ ] 用語は用語集にリンクし、本文で再定義していない
- [ ] 「〜する / できる / してよい」が要件レベル語で統一されている
- [ ] 略語は初出でフルスペル + 用語集リンク
- [ ] 多義的な用語は対象外（What it is NOT）まで書かれている
- [ ] 用語が読み手の語彙に合っている（顧客向けは顧客の語、開発者向けは業界標準語）

**意思決定**
- [ ] 決定の根拠（なぜ）が本文に混ざらず ADR に分離されている
- [ ] 「Non-Goals（やらないこと）」が明示されている
- [ ] トレードオフが議論されている（採用しなかった案も）

**運用**
- [ ] Status（Draft / Reviewed / Approved）が明示されている
- [ ] 改訂履歴がある（版 / 日付 / 変更内容）
- [ ] 「最新」「現在」など時間に依存する表現がバージョン・日付・条件に置き換わっている
- [ ] リンクテキストが対象を示している（「こちら」になっていない）
- [ ] コードブロックにプロンプト記号・説明文が混ざっていない（入力と出力が分かれている）

**md / HTML 配置**
- [ ] サマリー・概況・比較系の視覚情報が主役のページのみ HTML、それ以外は md
- [ ] HTML 補足ページは [references/visual-encoding.md](references/visual-encoding.md) の視覚設計原則を満たしている

## アンチパターン

避けるべき書き方:

1. **詳細すぎる UML 病**: 全属性・全メソッドを書き、誰も読まなくなる → 関心ドメインだけ残す
2. **図と本文の不整合**: 図が古く本文が新しい → レビュー時に「図のキャプション」を必ず読み合わせる
3. **更新されない図**: PNG をコピペした PowerPoint 図が放置 → Mermaid / SVG / PlantUML / draw.io（XML）でテキストソース化
4. **用語のブレ**: 「現場 / 受注者 / 元請」が混在 → 用語集 1 つに集約
5. **「全部書く」病**: 完璧主義で永遠に未公開 → Status: Draft で先に公開し、ADR で意思決定だけ確定
6. **目次が機能しない構造**: 「設計」「仕様」など総称的ファイル名 → 「05-state-machine.md」のように番号 + 主題で物理順序を強制
7. **役割別入口の欠如**: 1 本の長大 README に全員を流し込み、誰も自分の章を見つけられない
8. **自動生成できる情報を手で書く**: API エンドポイント、DB スキーマなど → OpenAPI / ツールで生成
9. **HTML 化しすぎ**: md で済む情報まで HTML にしてメンテコストが増大 → 視覚情報が主役のページに限定
10. **時間に依存する表現**: 「最新バージョンをインストール」「現在の構成では」は時間の経過で意味が変わる → 「Node.js 20 系で動作確認済み」のようにバージョン・日付・条件で書く
11. **指示語のリンク**: 「詳細は[こちら](...)」はリンク先が分からず、ページ内検索にも掛からない → 「詳細は [API 認証の設定手順](...) を参照」とリンクテキストに対象を書く
12. **コードブロックに実行に不要な情報を混ぜる**: `$` `#` `>` のプロンプト記号や説明文が混ざるとコピー & ペーストできない → ブロックにはコマンドだけを入れ、説明はブロック外、実行結果は別ブロックに分ける
13. **テキストを画像で貼る / GUI を位置だけで説明する**: CLI 出力のスクリーンショットはコピーもページ内検索もできない（フォントの見た目自体が主題の場合を除く）。「右上のボタン」ではなく「右上の Create Project ボタン」と、UI 変更に強い名前を併記する

## 長さの目安

- **README**: 1 ページに収まる程度（スクロール 3 回以内）
- **ADR**: 1〜2 ページ。長くなったら粒度を分割
- **C4 図**: 1 図あたり要素 7±2 個まで。それ以上は粒度を下げる
- **機能仕様**: 1 機能 1 ドキュメント。横断的な内容は別ファイルに

## プロジェクト固有の設定

以下はプロジェクトの **AGENTS.md** で指定される（スキル本体は判断軸を提供、出力形式はプロジェクト方針に従う）:

- 主出力形式（md / html / 両方）
- ADR の置き場（例: `docs/adr/`）と形式（Nygard / MADR）
- 用語集の場所（例: `docs/requirements/02-glossary.md`）
- 既存仕様書のスタイル参照先（Step 1 で読むファイル）

プロジェクト個別の運用（html 主出力 / md 主出力 / ナビ規約 / ADR 連番のスタート値など）は各プロジェクトの AGENTS.md に書き、本スキルはそれを参照する設計。

## 参考

- [arc42 Template Overview](https://arc42.org/overview) — 12 セクション固定のテンプレート
- [テクニカルライティングガイドライン（フューチャー株式会社）](https://future-architect.github.io/arch-guidelines/documents/forTechnicalWriting/technical_writing_guidelines.html) — 本文の構造化・用語選定・具体例の使い分け・実運用アンチパターンの出典
- [C4 model FAQ](https://c4model.com/faq) — Context / Container / Component / Code の 4 階層
- [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) — C4 図の PlantUML 実装
- [ADR GitHub Organization](https://adr.github.io/) — Nygard / MADR 形式
- [MADR (Markdown Architectural Decision Records)](https://adr.github.io/madr/) — MADR テンプレート
- [Martin Fowler: ArchitectureDecisionRecord](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html)
- [Design Docs at Google (Industrial Empathy)](https://www.industrialempathy.com/posts/design-docs-at-google/)
- [RFC 7322 - RFC Style Guide](https://datatracker.ietf.org/doc/html/rfc7322)
- [Stripe API Reference](https://docs.stripe.com/api) — 3 カラム DX の参考
- [Docs as Code (Write the Docs)](https://www.writethedocs.org/guide/docs-as-code/) — Docs as Code 方法論
- [デジタル庁デザインシステム DADS](https://design.digital.go.jp/dads/) — HTML 補足ページの視覚設計が準拠する公的標準
- [@digital-go-jp/design-tokens (GitHub)](https://github.com/digital-go-jp/design-tokens) — DADS デザイントークンの配布元（取込版は v2.0.1、本スキルでは `references/dads-tokens.md` に静的転記）

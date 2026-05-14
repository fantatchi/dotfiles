# HTML 補足ページの CSS 集約

複数の HTML 補足ページを作る時、装飾 CSS を **共通スタイルシート 1 ファイル** に集約するための具体手順・最小骨格・命名規則・移行手順を集めたリファレンス。SKILL.md「### HTML 補足ページの CSS 集約方針（複数ページ作成時は必須）」から呼び出される。

## 採用判断

| 状況 | 採用するか |
|---|---|
| HTML 補足ページが **1 本のみ** | 共通 CSS は作らない。[`templates.md`](./templates.md) の最小骨格を `<style>` 内に直書き |
| HTML 補足ページが **2 本以上ある or 将来増える見込み** | **共通 CSS 集約を必須採用**。本ファイルの手順に従う |
| 既存プロジェクトに HTML 補足ページが分散して内部 `<style>` で書かれている | [§段階的移行手順](#段階的移行手順) で順次集約 |

「単一 HTML を作ってから後で増やす」展開は頻発するので、**最初から複数想定で共通 CSS を作ってもよい**（共通 CSS 1 ファイル + 個別 HTML が `<link>` 参照する構成）。

## ファイル構成

```
docs/_html/
├── _shared/
│   └── spec-page.css          # 共通スタイルシート（本ファイルの最小骨格）
├── overview.html              # body class="page-overview"
├── architecture/
│   └── context.html           # body class="page-context"
└── specs/
    ├── backend.html           # body class="page-backend"
    └── frontend.html          # body class="page-frontend"
```

- 共通 CSS は `_shared/` に置く（プロジェクトの慣習があればそれを優先）
- 各 HTML から `<link rel="stylesheet" href="../_shared/spec-page.css">` で参照（パスは配置に応じて調整）
- 各 HTML の `<body>` に `class="page-X"`（X はファイル名 kebab-case）を付与

## 個別 HTML 側の最小構造

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>[ページタイトル]</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Noto+Sans+JP:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap">
  <link rel="stylesheet" href="../_shared/spec-page.css">
  <style>
    /* ===== {page-name}.html 固有 CSS 変数のみ =====
     * その他のスタイルは ../_shared/spec-page.css の body.page-{page-name} scope に集約。
     */
    :root {
      --feature: #6d28d9;
      --feature-bg: #ede9fe;
    }
  </style>
</head>
<body class="page-{page-name}">
  <header class="page">...</header>
  <main>...</main>
  <footer class="page">...</footer>
</body>
</html>
```

個別 HTML の `<style>` は **10〜30 行**（`:root` 固有変数のみ）に収める。`html, body { ... }` や `.toc { ... }` などのレイアウトは絶対に書かない（共通 CSS を上書きする事故の温床）。

## 共通 CSS の最小骨格

cloud-dsc プロジェクトの `_shared/spec-page.css`（約 3000 行）から主要パターンを抽出。プロジェクトに合わせて値を調整する。

```css
/* ========== :root 変数（共通） ========== */
:root {
  /* 基本色 */
  --bg: #fafaf9;
  --bg-elev: #ffffff;
  --surface: #ffffff;
  --surface-soft: #fcfbfa;
  --text: #0c0a09;
  --text-soft: #1c1917;
  --muted: #57534e;
  --muted-soft: #78716c;
  --border: #e7e5e4;
  --border-strong: #a8a29e;

  /* アクセント色（ベースカラー Blue 系列、shared/base-color-mapping.md 参照） */
  --accent: #1d4ed8;          /* Blue 700 */
  --accent-bg: #dbeafe;       /* Blue 100 */

  /* 状態色（Negative=Red 固定） */
  --status-pass: #15803d;
  --status-pass-bg: #dcfce7;
  --status-fail: #b91c1c;
  --status-fail-bg: #fee2e2;
  --status-pending: #78716c;
  --status-pending-bg: #f5f5f4;

  /* タイポグラフィ（UD フォント優先、communicative-design.md 原則 7） */
  --font-sans: 'Inter', 'Noto Sans JP', 'BIZ UDPGothic', 'Hiragino Sans',
               'Yu Gothic UI', 'Segoe UI', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', Menlo, Consolas, monospace;

  /* 行長（communicative-design.md 原則 8） */
  --reading-width: 70ch;

  /* シャドウ */
  --shadow-xs: 0 1px 2px 0 rgba(15, 12, 9, 0.04);
  --shadow-sm: 0 1px 3px 0 rgba(15, 12, 9, 0.06), 0 1px 2px -1px rgba(15, 12, 9, 0.04);
}

/* ========== リセット・基本タイポ ========== */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-feature-settings: 'palt', 'pwid';
  font-size: 15px;
  line-height: 1.78;          /* 原則 8: 1.5〜1.75 倍 */
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

main {
  max-width: 1120px;
  margin: 0 auto;
  padding: 64px 32px 128px;
}

:target { scroll-margin-top: 16px; }

@media (max-width: 768px) {
  main { padding: 40px 20px 96px; }
}

/* ========== header.page ========== */
header.page {
  border-bottom: 1px solid var(--border);
  padding-bottom: 36px;
  margin-bottom: 56px;
}

header.page .breadcrumb {
  color: var(--muted);
  font-size: 11px;
  margin: 0 0 12px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-weight: 500;
}

header.page h1 {
  font-size: 38px;           /* 原則 4: 視覚的階層 3 段、十分なジャンプ率 */
  font-weight: 700;
  margin: 0 0 10px;
  letter-spacing: -0.02em;
  line-height: 1.2;
}

header.page .subtitle {
  color: var(--muted);
  font-size: 16px;
  margin: 0 0 24px;
  max-width: 760px;
}

/* ========== .meta-grid（想定読者・読了時間・Status グリッド） ========== */
.meta-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1px;
  margin: 0 0 28px;
  background: var(--border);
  border: 1px solid var(--border);
  border-radius: 10px;
  overflow: hidden;
  box-shadow: var(--shadow-xs);
}

.meta-grid .item {
  background: var(--surface);
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.meta-grid .item .label {
  font-size: 10px;
  font-weight: 600;
  color: var(--muted-soft);
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

@media (max-width: 768px) {
  .meta-grid { grid-template-columns: repeat(2, 1fr); }
}

/* ========== .tldr（TL;DR 装飾） ========== */
.tldr {
  background: linear-gradient(135deg, var(--surface) 0%, var(--surface-soft) 100%);
  border: 1px solid var(--border);
  border-left: 4px solid var(--accent);
  border-radius: 10px;
  padding: 22px 26px;
  font-size: 15px;
  line-height: 1.85;
  box-shadow: var(--shadow-sm);
}

.tldr .label {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  color: var(--accent);
  background: var(--accent-bg);
  padding: 3px 10px;
  border-radius: 4px;
  letter-spacing: 0.1em;
  margin-bottom: 12px;
}

/* ========== section ========== */
section { margin: 72px 0; }

section > h2 {
  font-size: 26px;             /* 原則 4: h1=38 / h2=26 / h3=18 で 3 段階層 */
  font-weight: 700;
  margin: 0 0 10px;
  padding-bottom: 14px;
  border-bottom: 2px solid var(--border);
  letter-spacing: -0.01em;
}

section > p,
section > ul,
section > ol {
  max-width: var(--reading-width);   /* 原則 8: 行長制約 */
}

/* ========== table（標準テーブル、横罫主体） ========== */
table {
  border-collapse: collapse;
  font-size: 13px;
}

table th, table td {
  padding: 10px 12px;
  text-align: left;
  border-bottom: 1px solid var(--border);
  vertical-align: top;
}

table thead th {
  background: var(--surface-soft);
  font-weight: 600;
  font-size: 12px;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

/* 原則 11: 5 行以上 × 4 列以上の表に zebra stripe */
table.zebra tbody tr:nth-child(even) {
  background: #f5f5f4;
}

table td.num, table th.num {
  text-align: right;
  font-family: var(--font-mono);
}

/* ========== .note-box / callout 系 ========== */
.note-box {
  background: #fafaf9;
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 12px 16px;
  font-size: 13px;
  color: var(--muted);
  margin: 12px 0;
}

.callout-negative {
  background: var(--status-fail-bg);
  border-left: 4px solid var(--status-fail);
  border-radius: 6px;
  padding: 10px 14px;
  font-size: 13px;
  margin: 12px 0;
}

/* ========== .svg-wrap（SVG 図のラッパー） ========== */
.svg-wrap {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 16px;
  overflow-x: auto;
  margin: 12px 0;
}

.svg-wrap svg { display: block; max-width: 100%; height: auto; }

.figure-caption {
  font-size: 12px;
  color: var(--muted);
  margin: 6px 0 16px;
  text-align: center;
}

/* ========== .page-nav（前後ナビ） ========== */
.page-nav {
  margin-top: 40px;
  padding: 16px 18px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  font-size: 13px;
}

.page-nav .label-row {
  font-size: 11px;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 4px;
}

.page-nav a {
  color: inherit;
  text-decoration: none;
  border-bottom: 1px dashed transparent;
  font-weight: 600;
}

.page-nav a:hover { border-bottom-color: currentColor; }

/* ========== footer.page ========== */
footer.page {
  margin-top: 64px;
  padding-top: 32px;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-size: 13px;
}

footer.page table.history {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

footer.page table.history th {
  font-weight: 600;
  color: var(--muted);
  background: var(--surface-soft);
}

/* ========== body.page-X scope の例 ========== */
/* ページ固有レイアウトは必ず body.page-X scope を付ける */

body.page-context .layer-flow {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin: 20px 0;
}

body.page-glossary .term-grid {
  display: grid;
  grid-template-columns: 200px 1fr;
  gap: 12px 24px;
  align-items: baseline;
}

body.page-frontend pre.code-block {
  background: #1c1917;
  color: #fafaf9;
  border-radius: 6px;
  padding: 12px 16px;
  overflow-x: auto;
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.65;
}

/* ========== @media print ========== */
@media print {
  body { background: white; }
  main { max-width: 100%; padding: 0; }
  .svg-wrap, .note-box, .callout-negative { break-inside: avoid; }
  a { color: var(--text); text-decoration: underline; }
  .page-nav, footer.page { display: none; }
}
```

このコア骨格（約 250 行）で「複数 HTML ページ + 視覚的一貫性 + 印刷対応」の必要最低限が揃う。プロジェクト固有のレイアウト（`.tree` / `.decision-grid` / `.pillars` など）は `body.page-X` scope で追加していく。

## ページ別 scope の書き方

ページ固有のレイアウトクラスは **必ず `body.page-X` scope を付ける**。理由は (1) 別ページからの誤適用を防ぐ、(2) 同名クラスを別ページで違う実装にできる、(3) どのページ専用か CSS 側で一目で分かる。

```css
/* OK: scope 付き */
body.page-context .layer-flow { ... }
body.page-glossary .term-grid { ... }

/* NG: scope なし（複数ページで衝突するリスク） */
.layer-flow { ... }
.term-grid { ... }
```

**例外**: 全ページ共通の汎用クラス（`.note-box`, `.tldr`, `table.zebra`, `.figure-caption` など）は scope なしで OK。汎用 vs 固有の境界は「**2 ページ以上で同じ用途に使うか**」で判断する。

## `:root` 変数の命名規則

- **kebab-case** で `--` プレフィックス（CSS Custom Property 標準）
- **共通 CSS の `:root`**: 機能カテゴリ別の prefix を付ける
  - 基本色: `--bg`, `--surface`, `--text`, `--muted`, `--border`
  - 状態色: `--status-pass`, `--status-fail`, `--status-pending`
  - アクター色: `--actor-contractor`, `--actor-orderer`
  - スコープ: `--scope-in`, `--scope-out`
  - タイポ: `--font-sans`, `--font-mono`, `--reading-width`
  - 配色アクセント: `--accent`, `--accent-bg`
- **個別 HTML の `:root`**: ページ固有の意味を持つ色だけ
  - 例: `--feature` / `--feature-bg`（特定機能ページ専用）
  - 例: `--tier-server`, `--tier-client`（アーキテクチャ層分けページ）
- 同じ意味でも別名にしない（`--accent` と `--primary-color` を混在させない）

## 段階的移行手順（既存プロジェクト向け）

cloud-dsc Phase 7a〜7c の実例。既に分散して書かれている HTML 補足ページを共通 CSS 化する手順:

### Phase 1: 共通 CSS 雛形作成

1. `_shared/spec-page.css` を本ファイルの最小骨格で新規作成
2. 1 ファイルだけ選んで `<link>` を追加し、内部 `<style>` を残したまま動作確認
3. 内部 `<style>` で **同名クラスの衝突** がないか確認（共通 CSS の `header.page h1` を内部 `<style>` の `header.page h1` が上書きしていないか）

### Phase 2: 個別 HTML の `<style>` 縮小

ファイルごとに以下を実施:

1. `<body>` に `class="page-X"` を付与
2. 内部 `<style>` から共通 CSS と重複する定義を削除
3. ページ固有レイアウトは共通 CSS 側に `body.page-X` scope 付きで移動
4. 内部 `<style>` を `:root` 固有変数のみに縮小（10-30 行目安）
5. ブラウザで visual diff を取って意図しない変化がないか確認

### Phase 3: 共通 CSS の整理

1. 共通 CSS 全体を読み返し、scope なしで定義されている要素が「本当に汎用か」を判定
2. 汎用でなければ `body.page-X` scope を後付けで追加
3. `:root` 変数の命名が `--accent` / `--primary-color` のような重複になっていないか確認
4. 不要になった内部 `<style>` 由来のクラスを削除

### Phase 4: レビュー観点の確認

- フォント・h1 サイズ・配色が全 HTML で揃っているか
- 共通 CSS 1 ファイル変更で全ページに反映されるか試す（テスト用に `--accent` を別色に変えてみる）
- 印刷プレビューで `.svg-wrap` などが切れていないか（`@media print` scope の確認）

## 期待される効果（cloud-dsc 実証）

- フォント・h1 サイズ・配色が全 HTML で完全に揃う（個別 `<style>` の上書き事故ゼロ）
- 共通 CSS 1 ファイル変更で全 HTML に反映可能（ベースカラー切り替え等）
- レビューポイントが集中する（共通 CSS だけ見れば視覚設計の全体像が分かる）
- 新規 HTML 追加コストが下がる（`<body class="page-X">` + `:root` 固有変数のみで完了）

## 規模の許容

共通 CSS は規模が大きくなる（cloud-dsc は約 3000 行）。これは **許容する**。代わりに以下のメリットが得られる:

- 個別ファイル変更コストはほぼゼロ（`:root` 固有変数のみ）
- 一括変更が可能（配色・タイポ・余白の全体刷新が共通 CSS 1 ファイルで完結）
- レビュー時の見落としが減る（CSS の全体像が 1 ファイルに集約）

3000 行を超えてきたら、`_shared/spec-page.css` を機能別に分割するのは選択肢:

```
_shared/
├── spec-page.css         # 集約 import 用
├── _base.css             # :root / リセット / タイポ
├── _layout.css           # header.page / section / footer / page-nav
├── _components.css       # .tldr / .meta-grid / .note-box / .svg-wrap / table
└── _pages/
    ├── context.css       # body.page-context 専用
    ├── glossary.css      # body.page-glossary 専用
    └── ...
```

ただし分割するとファイル間の関係性が見えづらくなるため、**3000 行までは 1 ファイルで運用するのが推奨**（cloud-dsc は単一ファイル運用で問題なし）。

## 関連参照

- 視覚一貫性の原則的な裏付け → [`communicative-design.md`](./communicative-design.md) 原則 3「反復」
- ベースカラー（`--accent` 値）の選定 → [`../../shared/base-color-mapping.md`](../../shared/base-color-mapping.md)
- HTML 単体テンプレ（共通 CSS なしの最小骨格）→ [`templates.md`](./templates.md) §HTML 補足テンプレート
- 配色パレット HEX 値（7 系統 × 6 階調）→ [`../../dashboard-design/references/visual-encoding.md`](../../dashboard-design/references/visual-encoding.md)

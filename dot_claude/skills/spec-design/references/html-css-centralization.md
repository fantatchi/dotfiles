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
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Noto+Sans+JP:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap">
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

**スタイル骨格の出典**: 本テンプレートは [Vercel DESIGN.md](https://getdesign.md/vercel/design-md) を起点に、仕様書 HTML 補足ページ用途へ転写したものを採用する。Vercel の calm-technical aesthetic（stark monochrome + ink-blue link + stacked shadow）が技術ドキュメントと相性が良いため。各セクション冒頭にコメントで **用途** を明記しているので、不要なセクションは丸ごと削れる。

**規模・運用パターンの実証例**: cloud-dsc プロジェクトの `_shared/spec-page.css`（**3072 行、2026-05-14 時点**）。**配色は Vercel ではなく Blue 900 ベース** (本変更前のレガシー値) で運用されているが、ファイル別 scope での全レイアウト統合パターン・3000 行規模の単一ファイル運用は本テンプレ採用時の参考になる。プロジェクトに合わせて値を調整する。

**`--accent` の値について**: 下記サンプルは Vercel link blue `#0070f3` を `--accent` に採用（リンク・ハイライト用途）。`#d3e5ff` を `--accent-bg`（背景アクセント）、`#171717` を `--accent-ink`（CTA black bar）として 3 トークン体制。デジタル庁ガイドの Blue 系列（`#0017C1` = Blue 900 等）を採用したい場合は [`../../shared/base-color-mapping.md`](../../shared/base-color-mapping.md) §3 の階調表から対応する HEX を引いて差し替える。Green / Orange / Light Blue / Cyan など別系統に切り替える場合も同じ手順。

**フォントの選定について**: 日本語フォントは Noto Sans JP（Google Fonts、日本語コミュニティの事実上の標準）を採用。Latin の Inter とペアリングして calm-tech な雰囲気を作る。等幅は JetBrains Mono（Latin 専用、CJK glyph を持たないため CJK は別 fallback を明示）。UD フォント原則（[`./communicative-design.md`](./communicative-design.md) 原則 7）の保険として `BIZ UDPGothic` / `Hiragino Sans` を sans fallback に、`BIZ UDGothic` / `Hiragino Sans` を mono fallback に含める。**運用則**: 平時は Noto Sans JP で表示し、Google Fonts CDN が遮断される環境（社内 LAN proxy 等）では BIZ UDPGothic に落ちて UD 保険が発動する。

```css
/* ========== :root 変数（全ページ共通） ==========
 * 用途: Vercel-inspired (https://getdesign.md/vercel/design-md) の配色・タイポ・
 *       角丸・影を仕様書 HTML へ転写した単一出典。ベースは canvas-soft #fafafa /
 *       ink #171717 のモノクロ、リンクには Vercel link blue #0070f3 を採用。
 *       ページ固有色（--feature 等）は個別 HTML の <style> :root に置く。 */
:root {
  /* 基本色 — Vercel canvas/ink ladder */
  --bg: #fafafa;              /* canvas-soft = ページ背景 */
  --bg-elev: #ffffff;
  --surface: #ffffff;         /* canvas = カード */
  --surface-soft: #f5f5f5;    /* canvas-soft-2 = inset surface */
  --text: #171717;            /* ink */
  --text-soft: #4d4d4d;       /* body */
  --muted: #4d4d4d;
  --muted-soft: #888888;      /* mute = placeholder/低優先 */
  --border: #ebebeb;          /* hairline */
  --border-strong: #a1a1a1;   /* hairline-strong */

  /* アクセント色 — Vercel link blue (技術ドキュメント向け) */
  --accent: #0070f3;          /* link = リンク/ハイライト */
  --accent-deep: #0761d1;     /* link-deep = pressed/visited */
  --accent-bg: #d3e5ff;       /* link-bg-soft = 背景アクセント */
  --accent-ink: #171717;      /* CTA black ink (Vercel signature) */
  --accent-on-ink: #ffffff;

  /* 状態色 — Vercel パレットから引用 (green が無いので teal を pass に充当)。
   * WCAG AA 4.5:1 に通すため、Vercel オリジナル値より暗いトーンへ調整済み。
   * 11px の badge は通常テキスト扱い (Large 例外不可) のため、AA 4.5 を確実に上回る値を選定:
   *   --status-pass: #29bc9b → #0b6b56 (on #aaffec で 5.58)
   *   --status-fail: #c50000 → #a30000 (on #f7d4d6 で 6.00)
   *   --status-pending #ab570a (on #ffefcf で 4.51, AA 通過マージン薄) */
  --status-pass: #0b6b56;       /* darker teal for WCAG AA 5.58 */
  --status-pass-bg: #aaffec;    /* cyan-soft */
  --status-fail: #a30000;       /* darker red for WCAG AA 6.00 */
  --status-fail-bg: #f7d4d6;    /* error-soft */
  --status-pending: #ab570a;    /* warning-deep (on #ffefcf で 4.51, AA 通過) */
  --status-pending-bg: #ffefcf; /* warning-soft */

  /* タイポグラフィ — Inter (Latin) + Noto Sans JP (JP) ペア。
   * Noto Sans JP は日本語コミュニティの事実上の標準で OS 横断の可読性を担保する。
   * 並び順は **Latin 系を先に置く**: CSS Fonts 3 の character-by-character matching
   * では各 glyph ごとに先頭順でマッチするフォントを選ぶ。Inter / Segoe UI が
   * 英数字を担い、Noto Sans JP が JP glyph を担うという subset 分業が成立する。
   * Google Fonts CDN 遮断時の冗長 fallback としても並び順が機能し、
   * BIZ UDPGothic に落ちて UD 保険が発動する (communicative-design.md 原則 7)。
   * JetBrains Mono は Latin 専用 (CJK glyph なし) のため、CJK 等幅 fallback として
   * BIZ UDGothic / Hiragino Sans を明示する。これを怠ると Windows で
   * Consolas → MS Gothic にフォールバックして行高が肥大化する。 */
  --font-sans: 'Inter', 'Segoe UI', 'Noto Sans JP', 'BIZ UDPGothic',
               'Hiragino Sans', 'Yu Gothic UI', system-ui, sans-serif;
  --font-mono: ui-monospace, 'JetBrains Mono', 'BIZ UDGothic', 'Hiragino Sans',
               Menlo, Consolas, monospace;

  /* 行長 (communicative-design.md 原則 8) */
  --reading-width: 70ch;

  /* シャドウ — Vercel stacked shadow (Level 1〜4)
   * 単段ではなく多段 drop + inset hairline で「カードがページに乗っている」効果。 */
  --shadow-xs: 0 0 0 1px rgba(0, 0, 0, 0.06) inset;
  --shadow-sm: 0 1px 1px rgba(0,0,0,0.02), 0 2px 2px rgba(0,0,0,0.04),
               0 0 0 1px rgba(0,0,0,0.04) inset;
  --shadow-md: 0 2px 2px rgba(0,0,0,0.04), 0 8px 8px -8px rgba(0,0,0,0.04),
               0 0 0 1px rgba(0,0,0,0.04) inset;
  --shadow-lg: 0 2px 2px rgba(0,0,0,0.04), 0 8px 16px -4px rgba(0,0,0,0.04),
               0 0 0 1px rgba(0,0,0,0.04) inset;

  /* 角丸 — Vercel rounded scale */
  --radius-sm: 6px;            /* in-app: ボタン・フォーム */
  --radius-md: 8px;            /* marketing: カード */
  --radius-lg: 12px;
  --radius-pill: 100px;        /* marketing CTA pill */
}

/* ========== リセット・基本タイポ ==========
 * 用途: ブラウザ既定値の差を吸収し、Inter + Noto Sans JP の組み合わせを全ページへ。
 *       font-feature-settings の pwid で約物の詰めを、ss01/ss02 で Inter の
 *       geometric alternates を有効化。Noto Sans JP は palt 未実装のため pwid のみ。 */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-feature-settings: 'pwid', 'ss01', 'ss02';
  font-size: 15px;
  line-height: 1.78;          /* 原則 8: 1.5〜1.75 倍 */
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

::selection { background: var(--text); color: #f2f2f2; }

main {
  max-width: 1120px;
  margin: 0 auto;
  padding: 64px 32px 128px;
}

:target { scroll-margin-top: 16px; }

@media (max-width: 768px) {
  main { padding: 40px 20px 96px; }
}

/* ========== インラインリンク・コード ==========
 * 用途: a 要素は Vercel link-deep (#0761d1) を採用。Vercel オリジナルの link blue #0070f3 は
 *       本文背景 #fafafa 上で 4.36 (WCAG AA 1.4.3 未達) のため、deep tone (5.63) に切替。
 *       WCAG 1.4.1 (色のみで情報伝達禁止) 対応のため **平常時から underline を付ける**。
 *       :focus-visible で keyboard navigation の可視性も担保 (WCAG 2.4.7)。
 *       code は surface-soft 上のグレー背景、pre は ink 背景の code-editor-mockup 風。 */
a {
  color: var(--accent-deep);   /* #0761d1 on #fafafa で 5.63 AA pass */
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 2px;
  transition: text-decoration-thickness 0.15s;
}
a:hover { text-decoration-thickness: 2px; }
a:visited { color: #4c2889; }   /* Vercel violet-deep, 伝統的な visited 紫で識別 */
a:focus-visible,
button:focus-visible,
[tabindex]:focus-visible {
  outline: 2px solid var(--accent-deep);   /* #0761d1 on #fafafa で 5.63 AA pass、link 色と整合 */
  outline-offset: 2px;
}

code {
  font-family: var(--font-mono);
  font-size: 0.875em;
  background: var(--surface-soft);
  padding: 2px 6px;
  border-radius: 4px;
  color: var(--text);
}

pre {
  background: var(--text);             /* Vercel code-editor-mockup = ink #171717 */
  color: var(--accent-on-ink);
  padding: 20px 24px;
  border-radius: var(--radius-md);
  overflow-x: auto;
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.65;
  box-shadow: var(--shadow-md);
  margin: 16px 0;
}

pre code {
  background: transparent;
  padding: 0;
  color: inherit;
  font-size: inherit;
}

/* ========== header.page ==========
 * 用途: 各ページ最上部の見出しエリア。breadcrumb / h1 / subtitle を含む。
 *       breadcrumb は mono eyebrow (Vercel signature)、h1 は 48px / 600 / -0.05em。 */
header.page {
  border-bottom: 1px solid var(--border);
  padding-bottom: 40px;
  margin-bottom: 64px;
}

header.page .breadcrumb {
  font-family: var(--font-mono);
  color: var(--muted-soft);
  font-size: 12px;
  margin: 0 0 16px;
  font-weight: 400;
}

header.page h1 {
  font-size: 48px;             /* Vercel display-xl */
  font-weight: 600;            /* Vercel display ceiling = 600 (700 へ昇格しない) */
  margin: 0 0 14px;
  letter-spacing: -0.025em;    /* Vercel オリジナル -0.05em は和文見出しで漢字接触リスク。
                                * 日本語見出しと混在する仕様書では半分の値に抑える。 */
  line-height: 1.0;
}

/* lang="ja" の見出しは tracking を完全に 0 へ (BIZ UDPGothic 等 fallback 時の保険)。
 * 仕様書 HTML は <html lang="ja"> 前提なので、実質的にこの値が適用される。 */
header.page h1:lang(ja) {
  letter-spacing: 0;
}

header.page .subtitle {
  color: var(--muted);
  font-size: 18px;
  margin: 14px 0 28px;
  max-width: 760px;
  line-height: 1.55;
}

/* ========== .meta-grid（想定読者・読了時間・Status グリッド） ==========
 * 用途: ページ冒頭の「想定読者 / 読了時間 / Status / 関連 ADR」4 セルグリッド。
 *       label は mono eyebrow で技術ドキュメント voice を出す。 */
.meta-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1px;
  margin: 0 0 32px;
  background: var(--border);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.meta-grid .item {
  background: var(--surface);
  padding: 16px 18px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.meta-grid .item .label {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 400;
  color: var(--muted-soft);
}

.meta-grid .item .value {
  font-size: 14px;
  color: var(--text);
  font-weight: 500;
}

@media (max-width: 768px) {
  .meta-grid { grid-template-columns: repeat(2, 1fr); }
}

/* ========== .tldr（TL;DR 装飾） ==========
 * 用途: 各ページ冒頭の TL;DR ブロック。左ボーダーを ink (黒) にして Vercel
 *       signature な「sober で技術的」な印象に。label のみアクセントブルー。 */
.tldr {
  background: var(--surface);
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent-ink);   /* Vercel signature: black bar */
  border-radius: var(--radius-md);
  padding: 24px 28px;
  font-size: 15px;
  line-height: 1.85;
  box-shadow: var(--shadow-md);
  margin: 0 0 32px;
}

.tldr .label {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 400;
  color: var(--accent-deep);   /* #0070f3 だと #d3e5ff 上で 3.06 (WCAG NG)、
                                  #0761d1 (accent-deep) なら 4.59 で AA pass */
  background: var(--accent-bg);
  padding: 3px 12px;
  border-radius: var(--radius-pill);
  margin-bottom: 12px;
}

/* ========== section ==========
 * 用途: ページ内のセクション区切り。h2/h3 + 本文の基本レイアウト、行長制約も適用。
 *       Vercel display-lg/sm を踏襲 (32px/20px、weight 600、ネガティブトラッキング)。 */
section { margin: 96px 0; }

section > h2 {
  font-size: 32px;             /* Vercel display-lg */
  font-weight: 600;
  margin: 0 0 14px;
  padding-bottom: 14px;
  letter-spacing: -0.04em;     /* -1.28px / 32px */
  line-height: 1.25;
}

section > h3 {
  font-size: 20px;             /* Vercel display-sm */
  font-weight: 600;
  margin: 48px 0 12px;
  letter-spacing: -0.03em;
}

section > p,
section > ul,
section > ol {
  max-width: var(--reading-width);   /* 原則 8: 行長制約 */
}

/* ========== table（標準テーブル、横罫主体） ==========
 * 用途: 仕様一覧・比較・要件表など全般のテーブル基本スタイル。
 *       原則 11（罫線最小化・横罫主体）に従う。thead は mono eyebrow。 */
table {
  border-collapse: collapse;
  font-size: 14px;
  margin: 16px 0;
}

table th, table td {
  padding: 12px 14px;
  text-align: left;
  border-bottom: 1px solid var(--border);
  vertical-align: top;
}

table thead th {
  background: var(--surface-soft);
  font-family: var(--font-mono);     /* Vercel data-table-cell の mono eyebrow */
  font-weight: 400;
  font-size: 12px;
  color: var(--muted-soft);
  letter-spacing: 0;
  text-transform: none;
}

/* 原則 11: 5 行以上 × 4 列以上の表に zebra stripe */
table.zebra tbody tr:nth-child(even) {
  background: var(--surface-soft);
}

table td.num, table th.num {
  text-align: right;
  font-family: var(--font-mono);
}

/* ========== badge (Vercel badge-secondary + status バリアント) ==========
 * 用途: ステータス・ラベル表示。`.pass / .fail / .pending / .accent` を切り替え。
 * **運用規約 (MUST)**: `.pass / .fail / .pending` を使う時は **必ずテキストラベル**
 *   (例: 「合格」「失敗」「保留」「PASS」「FAIL」) を含めること。色のみでの情報伝達は
 *   WCAG 1.4.1 違反 + 色覚多様性 (P 型 / D 型) で判別困難になるため。 */
.badge {
  display: inline-flex;
  align-items: center;
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--surface-soft);
  color: var(--muted);
  padding: 2px 10px;
  border-radius: var(--radius-pill);
}

.badge.pass    { background: var(--status-pass-bg);    color: var(--status-pass); }
.badge.fail    { background: var(--status-fail-bg);    color: var(--status-fail); }
.badge.pending { background: var(--status-pending-bg); color: var(--status-pending); }
.badge.accent  { background: var(--accent-bg);         color: var(--accent-deep); }  /* #0070f3 だと #d3e5ff 上で 3.56 (NG)、#0761d1 で 4.51 (AA pass) */

/* ========== .note-box / callout 系 ==========
 * 用途: 注記・補足の囲み。.callout-negative は警告（Red 固定で二重符号化）。 */
.note-box {
  background: var(--surface-soft);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: 14px 18px;
  font-size: 13px;
  color: var(--muted);
  margin: 16px 0;
}

.callout-negative {
  background: var(--status-fail-bg);
  border-left: 3px solid var(--status-fail);
  border-radius: var(--radius-md);
  padding: 12px 16px;
  font-size: 13px;
  margin: 16px 0;
}

/* ========== .svg-wrap（SVG 図のラッパー） ==========
 * 用途: インライン SVG / Mermaid 出力の囲み + キャプション。横スクロール許容。
 *       figure-caption は mono にして技術ドキュメント voice を統一。 */
.svg-wrap {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: 20px;
  overflow-x: auto;
  margin: 16px 0;
  box-shadow: var(--shadow-sm);
}

.svg-wrap svg { display: block; max-width: 100%; height: auto; }

.figure-caption {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--muted-soft);
  margin: 8px 0 24px;
  text-align: center;
}

/* ========== .page-nav（前後ナビ） ==========
 * 用途: ページ末の前/次ナビ。label-row は mono eyebrow、リンクは hover で accent。 */
.page-nav {
  margin-top: 48px;
  padding: 18px 22px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  font-size: 13px;
  box-shadow: var(--shadow-sm);
}

.page-nav .label-row {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--muted-soft);
  margin-bottom: 4px;
}

.page-nav a {
  color: inherit;
  text-decoration: none;
  font-weight: 500;
  border: none;
}

.page-nav a:hover { color: var(--accent); }

/* ========== footer.page ==========
 * 用途: ページ末の改訂履歴 / メタ情報。table.history で履歴を表示。 */
footer.page {
  margin-top: 80px;
  padding-top: 32px;
  border-top: 1px solid var(--border);
  color: var(--muted-soft);
  font-size: 13px;
}

footer.page table.history { width: 100%; border-collapse: collapse; font-size: 12px; }
footer.page table.history th {
  font-family: var(--font-mono);
  font-weight: 400;
  color: var(--muted-soft);
  background: var(--surface-soft);
}

/* ========== Vercel signature: hero mesh-gradient（任意） ==========
 * 用途: 仕様書トップなど「掴み」が欲しいページ専用。情報密度が高いページでは
 *       積極的に使わない（Vercel Do's and Don'ts: 装飾は hero スケールのみ）。 */
.hero-mesh {
  position: relative;
  padding: 96px 32px 64px;
  overflow: hidden;
  isolation: isolate;
}

.hero-mesh::before {
  content: '';
  position: absolute;
  inset: -10%;
  background:
    radial-gradient(ellipse at 20% 30%, #007cf055 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, #ff008033 0%, transparent 50%),
    radial-gradient(ellipse at 50% 80%, #f9cb2833 0%, transparent 60%);
  filter: blur(60px);
  z-index: -1;
}

/* ========== body.page-X scope の例 ==========
 * 用途: ページ固有レイアウト。必ず body.page-X scope を付けて衝突を避ける。
 * 命名規則: page-X の X は HTML ファイル名から拡張子を除いた kebab-case。 */

/* 例 1: アーキテクチャ context ページ専用の階層フロー */
body.page-context .layer-flow {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin: 20px 0;
}

/* 例 2: 用語集ページの 2 カラム用語表 (term は mono / accent) */
body.page-glossary .term-grid {
  display: grid;
  grid-template-columns: 200px 1fr;
  gap: 12px 24px;
  align-items: baseline;
}

body.page-glossary .term-grid dt {
  font-family: var(--font-mono);
  font-size: 13px;
  color: var(--accent);
  font-weight: 500;
}

body.page-glossary .term-grid dd { margin: 0; color: var(--text); }

/* ========== @page / @media print ==========
 * 用途: 印刷時に図・callout・pre が途中で切れないように break-inside: avoid。
 *       pre は ink 背景のままだとインク消費が多いので surface-soft へ反転。
 *       Chromium は印刷時に box-shadow を描画しないので、カード境界を border で補強。
 *       @page で A4 マージン (18mm × 16mm) を明示し、業務 PDF 配布の安定性を確保。 */
@page {
  size: A4;
  margin: 18mm 16mm;
}

@media print {
  body { background: white; }
  main { max-width: 100%; padding: 0; }
  .svg-wrap, .note-box, .callout-negative, .tldr, pre { break-inside: avoid; }
  a { color: var(--text); text-decoration: underline; outline: none; }
  .page-nav, footer.page, .hero-mesh::before { display: none; }
  /* Chromium 印刷で box-shadow は出ない → inset hairline も消えるためカード境界が
   * 飛ぶ。border で明示補強し「白いカードが背景に溶ける」事故を防ぐ。 */
  .meta-grid, .tldr, .svg-wrap, .page-nav {
    box-shadow: none;
    border: 1px solid #ccc;
  }
  pre {
    background: var(--surface-soft);
    color: var(--text);
    box-shadow: none;
    border: 1px solid var(--border);
  }
}
```

各 HTML の `<head>` に Google Fonts の読み込みを追加する:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Noto+Sans+JP:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap">
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

cloud-dsc Phase 7a〜7c の実例。既に分散して書かれている HTML 補足ページを共通 CSS 化する手順。各 Phase の **遷移条件**（次に進んでよい判定）をチェックリストで明示する。

### Phase 1: 共通 CSS 雛形作成

- [ ] `_shared/spec-page.css` を本ファイル「§共通 CSS の最小骨格」を雛形に新規作成
- [ ] 1 ファイルだけ選んで `<link rel="stylesheet" href="...">` を追加（内部 `<style>` はまだ残す）
- [ ] ブラウザで開いて表示崩れがないか確認
- [ ] 内部 `<style>` で **同名クラスの衝突** がないか目視チェック（共通 CSS の `header.page h1` を内部 `<style>` の `header.page h1` が上書きしていないか）

**遷移条件**: 1 ファイルで共通 CSS の link が機能し、上書き事故が起きないことを確認できたら Phase 2。

### Phase 2: 個別 HTML の `<style>` 縮小（ファイル単位で繰り返す）

各 HTML ファイルについて:

- [ ] `<body>` に `class="page-X"` を付与（X は HTML ファイル名の kebab-case）
- [ ] 内部 `<style>` から共通 CSS と重複する定義（`html, body`, `header.page h1`, `.tldr` 等）を削除
- [ ] ページ固有レイアウト（`.layer-flow` 等）は共通 CSS 側に `body.page-X` scope 付きで移動
- [ ] 内部 `<style>` を **`:root` 固有変数のみ**（10-30 行目安）に縮小
- [ ] ブラウザで visual diff を取り、意図しない変化がないことを確認

**遷移条件**: 全 HTML ファイルでこのリストが完了したら Phase 3。

### Phase 3: 共通 CSS の整理

- [ ] 共通 CSS 全体を読み返し、scope なしで定義されている要素が「本当に汎用か」を判定
- [ ] 汎用でなければ `body.page-X` scope を後付けで追加
- [ ] `:root` 変数の命名が `--accent` / `--primary-color` のような重複になっていないか確認
- [ ] 不要になった内部 `<style>` 由来のクラスを削除
- [ ] `--accent` 値がベースカラー方針と整合しているか確認:
  - **デフォルト (Vercel inspired, `#0070f3`) を採用する場合**: 本チェックはスキップ可 (Vercel link blue は `base-color-mapping.md` の階調表に存在しない HEX のため、整合確認は適用外)
  - **別系統 (Blue 900 / Green / Orange / Light Blue / Cyan / Red) に切り替えた場合**: [`../../shared/base-color-mapping.md`](../../shared/base-color-mapping.md) §3 階調表と HEX 整合を確認

**遷移条件**: 共通 CSS が「scope 付き = ページ固有 / scope なし = 汎用」で綺麗に分離されたら Phase 4。

### Phase 4: 視覚一貫性のレビュー観点

- [ ] フォント・h1 サイズ・配色が全 HTML で揃っているか（ページを順次開いて目視）
- [ ] 共通 CSS 1 ファイル変更で全ページに反映されるか試す（テスト用に `--accent` を別色に変えて確認、終わったら元に戻す）
- [ ] 印刷プレビューで `.svg-wrap` などが切れていないか（`@media print` scope の確認）
- [ ] 「伝わるデザイン」レビューチェックリスト（[`communicative-design.md`](./communicative-design.md) 末尾）を新規 HTML に適用してパスするか

**完了条件**: 上記すべてパスしたら共通 CSS 集約は完了。以降の新規 HTML 追加は「`<body class="page-X">` + `:root` 固有変数のみ」のみで作れる。

## 期待される効果（cloud-dsc 実証）

- フォント・h1 サイズ・配色が全 HTML で完全に揃う（個別 `<style>` の上書き事故ゼロ）
- 共通 CSS 1 ファイル変更で全 HTML に反映可能（ベースカラー切り替え等）
- レビューポイントが集中する（共通 CSS だけ見れば視覚設計の全体像が分かる）
- 新規 HTML 追加コストが下がる（`<body class="page-X">` + `:root` 固有変数のみで完了）

## 規模の許容

共通 CSS は規模が大きくなる（cloud-dsc は 3072 行、2026-05-14 時点）。これは **許容する**。代わりに以下のメリットが得られる:

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

# HTML 補足ページの CSS 集約

複数の HTML 補足ページを作る時、装飾 CSS を **共通スタイルシート 1 ファイル（SSOT）** に集約しつつ、**各 HTML へは生成時にインライン展開して self-contained を保つ** ための具体手順・最小骨格・命名規則・移行手順を集めたリファレンス。SKILL.md「### HTML 補足ページの CSS 集約方針（複数ページ作成時 SHOULD）」から呼び出される。

> **方針の再定義（2026-06-10）**: 集約は **ソース管理レベル**（編集する場所を 1 つにする）の話であり、**配布物（生成された HTML）は self-contained** とする。従来の `<link rel="stylesheet">` 参照型は「リポジトリを checkout してローカルで開く」前提でしか表示できず、HTML ファイル単体での共有（ダウンロード閲覧・チャット添付）で表示が崩れるため、**生成時インライン展開型** へ移行した。SSOT による drift 防止と単体配布可能性を両立する。

### なぜこの方針か（背景・採用案・再検討トリガー）

**背景**: 仕様書の HTML 補足ページを社内共有したいが、**社内に静的 HTML をホスティングする場が無い**。検討の結果、(a) GitHub Organization は **Team プラン**（Enterprise ではない、API で確認）のため private リポジトリの Pages にアクセス制御をかけられず公開状態になってしまう、(b) Azure Static Web Apps は自社テナント限定認証だと Standard プラン必須でコスト過剰、と判明。結論として「**仕様書 HTML はホスティングせず、リポジトリ管理 + HTML 単体ファイル配布で共有する**」運用に決めた。この運用には配布物が self-contained である必要がある。

**採用案の比較**:

| 案 | 内容 | 判定 |
|---|---|---|
| **A（採用）** | SSOT 共通 CSS を残し、各 HTML へ生成時インライン展開 | スタイルの一元管理（drift 防止）と単体配布を両立。生成 1 ステップ増のみ |
| B（不採用） | self-contained をデフォルト化し SSOT を廃止、各 HTML に直書き | 単体配布は満たすが、ページ増でスタイル修正が全ファイル横断になり、集約で防ぎたかった drift が復活 |
| C（不採用） | 旧 `<link>` 参照型を維持し、共有時だけ都度手動インライン化 | 今すぐの変更ゼロだが、共有のたびに手間 + インライン化した瞬間に SSOT から切り離れて drift |

**再検討トリガー**（前提が変われば見直す。該当したらこの方針を再評価する）:

- **静的ホスティングが確保できたら**（認証付き Pages が使える Enterprise への移行 / SWA Standard 導入 / 社内に閲覧サーバが立つ 等）→ `<link>` 参照型へ戻すことを検討してよい（**MAY**）。単体配布の必要性が消えるため
- **HTML が md を超えて主役化したら**（インタラクティブな仕様書を常用し始めた 等）→ ホスティング前提の運用へ方針ごと再評価
- **再展開漏れが事故化したら** → drift 検査を MAY から CI 強制（SHOULD 以上）へ昇格

## 採用判断

| 状況 | 採用するか |
|---|---|
| HTML 補足ページが **1 本のみ** | 共通 CSS は作らない。[`templates.md`](./templates.md) の最小骨格を `<style>` 内に直書き（もともと self-contained） |
| HTML 補足ページが **2 本以上ある or 将来増える見込み** | **SSOT 共通 CSS + 生成時インライン展開を採用（SHOULD）**。本ファイルの手順に従う |
| 既存プロジェクトに HTML 補足ページが分散 `<style>` 直書き or 旧 `<link>` 参照型で書かれている | [段階的移行手順](#段階的移行手順既存プロジェクト向け) で順次移行 |

「単一 HTML を作ってから後で増やす」展開は頻発するので、**最初から複数想定で SSOT 共通 CSS を作ってもよい**（SSOT 1 ファイル + 各 HTML へ生成時インライン展開する構成）。

## ファイル構成

```
docs/_html/
├── _shared/
│   └── spec-page.css          # 共通スタイルシート SSOT（編集はここ。HTML へは生成時インライン展開）
├── overview.html              # body class="page-overview"
├── architecture/
│   └── context.html           # body class="page-context"
└── specs/
    ├── backend.html           # body class="page-backend"
    └── frontend.html          # body class="page-frontend"
```

- 共通 CSS（SSOT）は `_shared/` に置く（プロジェクトの慣習があればそれを優先）。**スタイル編集は必ずこのファイルで行う**
- 各 HTML は `<link>` で参照**しない**。生成・更新時に SSOT 全文を `<style data-shared-source="...">` へインライン展開する（[生成時インライン展開の運用ルール](#生成時インライン展開の運用ルール)）
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
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&family=Noto+Sans+Mono:wght@400;700&display=swap">
  <style data-shared-source="../_shared/spec-page.css">
    /* ===== 共通 CSS（SSOT: _shared/spec-page.css の生成時コピー） =====
     * このブロックを直接編集しない。スタイル変更は SSOT 側で行い、
     * HTML へ再展開して反映する（直接編集すると次回再展開で消える）。
     */
    /* ↓↓↓ ここに SSOT (_shared/spec-page.css) の【全文】が入る ↓↓↓
     * このテンプレ上は紙面の都合でプレースホルダだが、実際の生成物では
     * 省略・要約・畳み込みを一切せず SSOT を 1 バイト残らず展開する。
     * この placeholder コメント自体を出力に残してはならない（不完全コピーの温床）。 */
  </style>
  <style>
    /* ===== {page-name}.html 固有 CSS 変数のみ =====
     * その他のスタイルは SSOT（_shared/spec-page.css）の body.page-{page-name} scope に集約。
     */
    :root {
      --feature: #6d28d9;
      --feature-bg: #ede9fe;
    }
  </style>
</head>
<body class="page-{page-name}">
  <!-- 節が 4 つ以上: 左に目次を固定する形 -->
  <div class="layout">
    <nav class="toc" aria-label="目次">
      <p class="toc-title">目次</p>
      <ol>
        <li><a href="#overview" class="current">1. 全体構成</a></li>
        <li><a href="#components">2. コンポーネント一覧</a></li>
        ...
      </ol>
    </nav>
    <main>
      <header class="page">...</header>
      <div class="tldr">...</div>
      <section id="overview">...</section>
      ...
      <footer class="page">...</footer>
    </main>
  </div>
</body>
</html>
```

節が 3 つ以下のページは `.layout` と `nav.toc` を省き、`<body>` 直下を `<main>` だけにする（本文 1 カラムで中央寄せになる）。`header.page` と `footer.page` はどちらの形でも `<main>` の中に置く。

個別 HTML の **固有 `<style>`（2 つ目のブロック）** は **10〜30 行**（`:root` 固有変数のみ）に収める。`html, body { ... }` や `.toc { ... }` などのレイアウトは絶対に書かない（共通 CSS を上書きする事故の温床）。

## 生成時インライン展開の運用ルール

SSOT と配布物の関係を壊さないための規約:

- **編集は必ず SSOT（`_shared/spec-page.css`）側で行う（MUST）**。HTML 内のインラインコピーを直接編集しない（次回再展開で消える）
- HTML の新規生成・更新時、SSOT を読み込んで `<style data-shared-source="<SSOT への相対パス>">` ブロックへ全文展開する。`data-shared-source` 属性が「このブロックは生成コピーである」ことの機械可読マーカーを兼ねる
- インラインコピーの先頭に「SSOT の生成時コピー・直接編集禁止」コメントを必ず入れる
- **SSOT を変更したら、同プロジェクトの全 HTML 補足ページへ再展開して伝播する**。対象は `grep -rl 'data-shared-source' docs/` で機械的に列挙できる。要件レベルは展開手段で変わる:
  - **展開スクリプトを導入しているプロジェクト（[展開・検証スクリプト](#展開検証スクリプト)）**: SSOT 編集とコミットは全 HTML 再展開とセットでなければならない（**MUST**、1 コミット完結）。手作業より遥かに安全なため強制できる
  - **スクリプト未導入（LLM 手作業で展開）**: 全 HTML 再展開は **SHOULD**。ただし「SSOT だけ直して HTML は後で」は drift 未収束コミットを生むため、可能な限り同一セッションで再展開する
- **外部資産を埋め込まない（MUST）**: self-contained を壊さないため、`<img src="...">`・外部 `.svg` ファイル参照・`@import`・相対パスのローカル資産を HTML に入れない。図は **インライン SVG または data URI** で埋め込む（`.svg-wrap` は「インライン SVG 前提」）。Google Fonts の `<link>`（CDN 参照）だけは例外として残してよい — CDN 遮断環境では `--font-sans` の fallback（BIZ UDPGothic 等）に落ちる設計で、単体配布性を実用上損なわないため
- drift 検査: インラインコピー（`<style data-shared-source>` の中身）を抽出し SSOT と正規化 diff すれば再展開漏れを検出できる。スクリプト導入時は `--check` で自動化（[展開・検証スクリプト](#展開検証スクリプト)）、未導入時は MAY
- **git diff ノイズの緩和（任意）**: SSOT 1 行変更が全 HTML の `<style>` ブロックに伝播し diff が肥大化する。レビューでシグナルが埋もれるのが気になるなら、`.gitattributes` に該当 HTML への `linguist-generated` 付与や `*.html -diff`（差分非表示）を検討する。ただし HTML 本文の実変更も隠れるため、CSS 専用ディレクトリを分けない限り副作用に注意

## 展開・検証スクリプト

LLM の手作業展開は「全文コピー漏れ・相対パスズレ・再展開忘れ」を生むため、**展開と drift 検査をスクリプトに寄せる（SHOULD、特に HTML が 3 本以上 or 更新頻度が高いプロジェクト）**。雛形を [`expand-shared-css.ts`](./expand-shared-css.ts) に置いている。これを各リポジトリへコピーして使う（配置例 `scripts/expand-shared-css.ts`）。

- **言語**: TypeScript（`tsx` / `ts-node` で実行）。Node 標準ライブラリのみで外部 npm 依存なし。cloud-dsc / cloud-cmp 等の TS リポジトリと馴染む。Python 主体のリポジトリでも `npx tsx` で単発実行できる
- **やること**: SSOT を読み、`docs/` 以下で `data-shared-source` を持つ全 HTML を発見し、各 HTML の `<style data-shared-source>` ブロックを SSOT 全文で置換する。`data-shared-source` の相対パスは各 HTML の階層から自動算出するため、パスズレが構造的に起きない
- **2 モード**:
  - 展開: `npx tsx scripts/expand-shared-css.ts` — 全対象 HTML を SSOT 最新で上書き
  - 検証: `npx tsx scripts/expand-shared-css.ts --check` — drift があれば非ゼロ終了。**pre-commit hook / CI に組み込めば再展開漏れを無症状放置させない**
- スクリプト導入時、SSOT 編集とコミットは「展開して 1 コミット」が **MUST**（[生成時インライン展開の運用ルール](#生成時インライン展開の運用ルール)）。`--check` を CI ゲートにすると規約を機械的に担保できる

スクリプトを導入しない（手作業展開の）場合は、移行手順 [Phase 2 の踏み外し防御](#phase-2-個別-html-の-style-縮小ファイル単位で繰り返す)に従い、全文転記・相対パス・Google Fonts link 保持を人手で守る。

## 共通 CSS の最小骨格

> **配色・タイポトークンは デジタル庁デザインシステム (DADS) v2.0.1 由来**（MIT, Copyright (c) 2023 デジタル庁）。HEX 値の正本（SSOT）は [`dads-tokens.md`](./dads-tokens.md)。本ファイルで再掲する HEX は同ファイルからの引用であり、本ファイルでは値を変更しない（drift 防止）。

**スタイル骨格の出典**: 本テンプレートは **DADS v2.0.1 準拠**（key-color = Blue 固定）。配色・タイポ・角丸は DADS トークンから引いている。見た目の方針は「影と角丸カードを使わず、罫線 1 本と余白で区切る」「h1 は 32px に抑える」「アクセント色（Blue）の面は要点（`.tldr`）だけにする」の 3 点（2026-10-06 に現行 + 4 案を比較して採用）。各セクション冒頭にコメントで **用途** を明記しているので、不要なセクションは丸ごと削れる。

**規模・運用パターンの実証例**: cloud-dsc プロジェクトの `_shared/spec-page.css`（**3072 行、2026-05-14 時点**）。**配色は旧版 Blue 900 ベース** で運用されてきたが、現在は本テンプレ準拠（DADS）への移行対象。ファイル別 scope での全レイアウト統合パターン・3000 行規模の単一ファイル運用は本テンプレ採用時の参考になる。

**`--accent` の値について**: 下記サンプルは DADS key-color (Blue 700 `#264af4`) を `--accent` に、Blue 900 `#0017c1` を `--accent-deep`（本文リンクで AAA pass）、Blue 50 `#e8f1fe` を `--accent-bg`、Blue 200 `#c5d7fb` を `--accent-line`（要点の枠線）として採用。**ベースカラーは Blue 固定**（spec-writer デフォルト）。ブランド要請等で別色を採用する場合は [`dads-tokens.md`](./dads-tokens.md) 2 節の DADS プリミティブ 10 色族（Light Blue / Cyan / Green / Lime / Yellow / Orange / Red / Magenta / Purple）から階調を選び、選定 ADR を残す（[`adr-format.md`](./adr-format.md) カラー選定 ADR）。

**フォントの選定について**: 日本語・等幅とも DADS 採用フォントを使う。日本語は `Noto Sans JP`（Google Fonts、SIL OFL 1.1）、等幅は `Noto Sans Mono`（CJK + Latin 対応）。UD フォント原則（[`./communicative-design.md`](./communicative-design.md) 原則 7）の保険として `BIZ UDPGothic` / `BIZ UDGothic` を fallback に並べ、Google Fonts CDN 遮断環境（社内 LAN proxy 等）では UD 保険へ自動 fallback する。ウェイトは DADS 採用の `400 (Normal) / 700 (Bold)` の 2 段階のみ。

```css
/* ========== :root 変数（全ページ共通） ==========
 * 用途: DADS v2.0.1 準拠 (key-color = Blue) の配色・タイポ・角丸を仕様書 HTML へ
 *       単一出典化。基本色は Solid Gray ladder、リンクは Blue 900 (AAA pass)、
 *       状態色は DADS セマンティック (Green/Red/Yellow)。
 *       影 (box-shadow) は使わない。区切りは罫線 1 本と余白で表す。
 *       ページ固有色 (--feature 等) は個別 HTML の <style> :root に置く。
 *       HEX 値の出典は references/dads-tokens.md。 */
:root {
  /* 基本色 — DADS Neutral Solid Gray ladder */
  --bg: #ffffff;              /* white = ページ背景 */
  --surface: #f2f2f2;         /* Solid Gray 50 = code / pre / 表見出し背景 */
  --text: #1a1a1a;            /* Solid Gray 900 = 本文 */
  --text-soft: #4d4d4d;       /* Solid Gray 700 = 補助本文 */
  --muted: #666666;           /* Solid Gray 600 = ラベル・キャプション (on #ffffff で 約 5.7:1 AA) */
  --border: #e6e6e6;          /* Solid Gray 100 = 罫線 */
  --border-strong: #cccccc;   /* Solid Gray 200 = 表見出し下・強めの罫線 */

  /* アクセント色 — DADS key-color = Blue */
  --accent: #264af4;          /* Blue 700 = key-color (目次の現在位置・UI primary) */
  --accent-deep: #0017c1;     /* Blue 900 = 本文リンク (on #ffffff で 約 13.7:1 AAA) */
  --accent-bg: #e8f1fe;       /* Blue 50 = TL;DR / badge 背景 */
  --accent-line: #c5d7fb;     /* Blue 200 = TL;DR の枠線 */

  /* 状態色 — DADS セマンティック (success/error/warning)
   * badge は 12px の通常テキスト扱いのため、濃い階調をテキスト色に、
   * 対応する 50 階調を背景に採用して 4.5:1 以上を担保。 */
  --status-pass: #197a4b;       /* Green 800 (on #e6f5ec で AA pass) */
  --status-pass-bg: #e6f5ec;    /* Green 50 */
  --status-fail: #ce0000;       /* Red 900 (on #fdeeee で AA pass) */
  --status-fail-bg: #fdeeee;    /* Red 50 */
  --status-fail-line: #ffbbbb;  /* Red 200 = 警告 callout の枠線 */
  --status-pending: #927200;    /* Yellow 900 (on #fbf5e0 で AA pass) */
  --status-pending-bg: #fbf5e0; /* Yellow 50 */

  /* タイポグラフィ — DADS 採用フォント (Noto Sans JP + Noto Sans Mono)
   * Google Fonts CDN 遮断時は UD フォント (BIZ UDPGothic / BIZ UDGothic) へ
   * fallback する (communicative-design.md 原則 7)。 */
  --font-sans: 'Noto Sans JP', 'BIZ UDPGothic', system-ui, sans-serif;
  --font-mono: 'Noto Sans Mono', ui-monospace, 'BIZ UDGothic', monospace;

  /* 行長 (communicative-design.md 原則 8) */
  --reading-width: 70ch;

  /* 角丸 — DADS radius スケールから採用 */
  --radius-sm: 4px;            /* badge / inline code */
  --radius-md: 8px;            /* TL;DR・図・pre・callout */
  --radius-pill: 9999px;       /* DADS full */

  /* 旧骨格との互換 alias — 既存ページの固有 CSS が参照していても壊れないよう残す。新規には使わない */
  --bg-elev: var(--bg);
  --surface-soft: var(--surface);
  --muted-soft: var(--muted);
  --accent-ink: var(--text);
  --accent-on-ink: #ffffff;
  --radius-lg: 12px;
}

/* ========== リセット・基本タイポ ==========
 * 用途: ブラウザ既定値の差を吸収し、Noto Sans JP を全ページへ。
 *       font-feature-settings の pwid で約物の詰めを行う (Noto Sans JP は palt 未実装)。 */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-feature-settings: 'pwid';
  font-size: 16px;                 /* DADS 本文標準 */
  line-height: 1.8;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

::selection { background: var(--accent-bg); color: var(--text); }

main {
  min-width: 0;
  max-width: 880px;
  margin: 0 auto;
  padding: 56px 32px 120px;
}

:target { scroll-margin-top: 24px; }

@media (max-width: 900px) {
  main { padding: 32px 20px 80px; }
}

/* ========== .layout + nav.toc（左の固定目次） ==========
 * 用途: ページ内の節が 4 つ以上あるページで、左に目次を固定する。
 *       <body> 直下に <div class="layout"><nav class="toc">…</nav><main>…</main></div>。
 *       節が少ないページは .layout を使わず <main> だけにする (1 カラム中央寄せ)。
 *       900px 以下では目次を隠して本文 1 カラムにする。
 *       現在位置は a.current で示す (静的 HTML なので、ページ先頭の節に付けておく)。 */
.layout {
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  gap: 64px;
  max-width: 1120px;
  margin: 0 auto;
  padding-inline: 32px;
}

.layout > main { max-width: 780px; margin: 0; padding-inline: 0; }

nav.toc {
  position: sticky;
  top: 0;
  align-self: start;
  padding-block: 56px;
  font-size: 13px;
}

nav.toc .toc-title {
  margin: 0 0 12px;
  font-size: 12px;
  font-weight: 700;
  color: var(--muted);
}

nav.toc ol {
  list-style: none;
  margin: 0;
  padding: 0;
  border-left: 1px solid var(--border);
}

nav.toc a {
  display: block;
  padding: 6px 0 6px 16px;
  margin-left: -1px;
  border-left: 2px solid transparent;
  color: var(--text-soft);
  text-decoration: none;
  line-height: 1.5;
}

nav.toc a:hover { color: var(--accent-deep); }
nav.toc a.current { color: var(--accent-deep); border-left-color: var(--accent); font-weight: 700; }

@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr); gap: 0; padding-inline: 0; }
  .layout > main { padding-inline: 20px; }
  nav.toc { display: none; }
}

/* ========== インラインリンク・コード ==========
 * 用途: a 要素は DADS Blue 900 (#0017c1)。key-color の Blue 700 は本文リンクには
 *       4.5:1 を下回るため使わない。WCAG 1.4.1 (色のみで情報伝達禁止) 対応のため
 *       平常時から underline を付ける。:focus-visible でキーボード操作の位置を示す (WCAG 2.4.7)。
 *       code / pre は薄いグレー地。黒地のコードブロックはページ内で最も重い面になり
 *       要点より目立つため使わない。 */
a {
  color: var(--accent-deep);
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 3px;
}
a:hover { text-decoration-thickness: 2px; }
a:visited { color: #5109ad; }   /* DADS Purple 900 = visited 識別 (on #ffffff で 約 9.3:1 AAA) */
nav.toc a:visited { color: var(--text-soft); }
a:focus-visible,
button:focus-visible,
[tabindex]:focus-visible {
  outline: 2px solid var(--accent-deep);
  outline-offset: 2px;
}

code {
  font-family: var(--font-mono);
  font-size: 0.86em;
  background: var(--surface);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

pre {
  margin: 16px 0;
  padding: 16px 20px;
  overflow-x: auto;
  background: var(--surface);
  border-radius: var(--radius-md);
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.7;
}

pre code { background: none; padding: 0; font-size: inherit; }

/* ========== header.page ==========
 * 用途: 各ページ最上部。breadcrumb / h1 / subtitle / .meta-grid を含む。
 *       h1 は 32px に抑え、本文との差は太さと余白で付ける。 */
header.page { margin-bottom: 32px; }

header.page .breadcrumb {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0 0 12px;
  font-size: 13px;
  color: var(--muted);
}

/* パンくずは <span> または <a> を並べる。区切りの「/」は CSS で入れる */
header.page .breadcrumb > * + *::before { content: "/"; margin-right: 6px; color: var(--border-strong); }

header.page h1 {
  margin: 0;
  font-size: 32px;
  font-weight: 700;            /* DADS は 400 / 700 の 2 段階 */
  line-height: 1.4;
  text-wrap: balance;
}

header.page .subtitle {
  margin: 12px 0 24px;
  font-size: 17px;
  color: var(--text-soft);
  max-width: 40em;
}

/* ========== .meta-grid（想定読者・読了時間・Status・関連 ADR） ==========
 * 用途: ページ冒頭のメタ情報。カードにせず、上下の罫線で挟んだ横並びにする。 */
.meta-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 40px;
  padding-block: 14px;
  border-block: 1px solid var(--border);
}

.meta-grid .item { display: flex; flex-direction: column; gap: 2px; }
.meta-grid .label { font-size: 12px; color: var(--muted); }
.meta-grid .value { font-size: 14px; }

/* ========== .tiles（概況ページ用の集計タイル） ==========
 * 用途: 概況ランディング・サマリーページの冒頭で、件数や状態の集計を並べる。
 *       数値そのものがページの主題のときだけ使う (説明ページの飾りにしない)。
 *       .tile に .pass / .pending / .fail / .accent を付けるとラベル前に色の点が付く。
 *       色の点は補助で、ラベル文字 (「稼働中」等) を必ず書く (WCAG 1.4.1)。 */
.tiles {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 12px;
  margin: 24px 0 0;
}

.tile {
  display: flex;
  flex-direction: column;
  padding: 14px 18px;
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
}

.tile .t-label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text-soft); }
.tile .t-value { font-size: 32px; font-weight: 700; line-height: 1.3; font-variant-numeric: tabular-nums; }
.tile .t-note { font-size: 12px; color: var(--muted); }

.tile.pass .t-label::before,
.tile.pending .t-label::before,
.tile.fail .t-label::before,
.tile.accent .t-label::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}
.tile.pass .t-label::before    { color: var(--status-pass); }
.tile.pending .t-label::before { color: var(--status-pending); }
.tile.fail .t-label::before    { color: var(--status-fail); }
.tile.accent .t-label::before  { color: var(--accent); }

/* ========== .tldr（要点） ==========
 * 用途: 各ページ冒頭の要点。ページ内で唯一の色付きの面にして、最初に目が行くようにする。 */
.tldr {
  margin: 0 0 8px;
  padding: 18px 24px;
  background: var(--accent-bg);
  border: 1px solid var(--accent-line);
  border-radius: var(--radius-md);
}

.tldr .label {
  display: block;
  margin-bottom: 4px;
  font-size: 13px;
  font-weight: 700;
  color: var(--accent-deep);   /* Blue 900 on Blue 50 で約 12.5:1 AAA */
}

.tldr ul, .tldr ol { margin: 0; padding-left: 1.2em; }
.tldr p { margin: 0; }

/* ========== section ==========
 * 用途: ページ内の節。h2 は下罫線付き 24px、h3 は 18px。本文は行長を制約する。 */
section { margin-top: 64px; }

section > h2 {
  margin: 0 0 16px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border);
  font-size: 24px;
  font-weight: 700;
  line-height: 1.4;
  text-wrap: balance;
}

section > h3 {
  margin: 40px 0 8px;
  font-size: 18px;
  font-weight: 700;
  line-height: 1.5;
}

section > p,
section > ul,
section > ol {
  max-width: var(--reading-width);   /* 原則 8: 行長制約 */
  margin-block: 0 16px;
}

/* ========== table（標準テーブル、横罫のみ） ==========
 * 用途: 仕様一覧・比較・要件表など。原則 11（罫線最小化・横罫主体）に従う。
 *       列が多い表は <div class="table-wrap"> で包み、狭い画面では表の中だけ横スクロールさせる。 */
.table-wrap { overflow-x: auto; margin: 16px 0; }
.table-wrap > table { margin: 0; }

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
  line-height: 1.6;
  margin: 16px 0;
}

table th, table td {
  padding: 10px 12px;
  text-align: left;
  vertical-align: top;
  border-bottom: 1px solid var(--border);
}

table thead th {
  font-size: 13px;
  font-weight: 700;
  color: var(--text-soft);
  border-bottom-color: var(--border-strong);
  white-space: nowrap;
}

/* 原則 11: 5 行以上 × 4 列以上の表に zebra stripe */
table.zebra tbody tr:nth-child(even) { background: #f8f8f8; }   /* Solid Gray 50 と白の中間 */

table td.num, table th.num {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

/* ========== badge / .level ==========
 * 用途: 状態ラベル。`.pass / .fail / .pending / .accent` を切り替える。先頭に色の点が付く。
 * **運用規約 (MUST)**: 状態バリアントには必ずテキストラベル (「稼働中」「失敗」「保留」等) を
 *   含める。色のみでの情報伝達は WCAG 1.4.1 違反 + 色覚多様性で判別困難になるため。
 * .level は要件レベル語 (MUST / SHOULD / MAY) の表示用。MUST だけ赤で強調する。 */
.badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 2px 10px;
  border-radius: var(--radius-sm);
  background: var(--surface);
  color: var(--text-soft);
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
}

.badge.pass::before, .badge.fail::before, .badge.pending::before, .badge.accent::before {
  content: "";
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
}

.badge.pass    { background: var(--status-pass-bg);    color: var(--status-pass); }
.badge.fail    { background: var(--status-fail-bg);    color: var(--status-fail); }
.badge.pending { background: var(--status-pending-bg); color: var(--status-pending); }
.badge.accent  { background: var(--accent-bg);         color: var(--accent-deep); }

.level { font-family: var(--font-mono); font-size: 12px; font-weight: 700; color: var(--text-soft); }
.level.must { color: var(--status-fail); }

/* ========== .note-box / .callout-negative ==========
 * 用途: .note-box は補足 (左に細い罫線だけ)。.callout-negative は警告 (Red の地 + 枠)。
 *       警告は先頭の <strong> に結論を書く (色と太字の二重符号化)。 */
.note-box {
  margin: 16px 0;
  padding-left: 14px;
  border-left: 2px solid var(--border-strong);
  font-size: 14px;
  color: var(--text-soft);
}

.callout-negative {
  margin: 16px 0;
  padding: 14px 18px;
  background: var(--status-fail-bg);
  border: 1px solid var(--status-fail-line);
  border-radius: var(--radius-md);
  font-size: 15px;
}

.callout-negative strong:first-child { display: block; color: var(--status-fail); }

/* ========== .svg-wrap（図のラッパー） ==========
 * 用途: インライン SVG / Mermaid 出力の囲み + キャプション。狭い画面では図の中だけ横スクロール。
 *       【self-contained 必須】図は必ず **インライン <svg>** か data URI で埋め込む。
 *       <img src="diagram.svg"> のような外部ファイル参照は単体配布で壊れる。 */
.svg-wrap {
  margin: 16px 0 0;
  padding: 24px;
  overflow-x: auto;
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
}

.svg-wrap svg { display: block; max-width: 100%; height: auto; font-family: var(--font-sans); }

.figure-caption {
  margin: 8px 0 24px;
  font-size: 13px;
  color: var(--muted);
}

/* ========== .page-nav（前後ナビ） ==========
 * 用途: ページ末の前 / 次ナビ。罫線で挟み、左右に振り分ける。 */
.page-nav {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 64px;
  padding-block: 16px;
  border-block: 1px solid var(--border);
  font-size: 14px;
}

.page-nav > :last-child { text-align: right; }
.page-nav .label-row { display: block; font-size: 12px; color: var(--muted); }
.page-nav a { font-weight: 700; text-decoration: none; }
.page-nav a:hover { text-decoration: underline; }

/* ========== footer.page ==========
 * 用途: ページ末の改訂履歴 / メタ情報。table.history で履歴を表示。 */
footer.page {
  margin-top: 80px;
  padding-top: 24px;
  border-top: 1px solid var(--border);
  font-size: 13px;
  color: var(--text-soft);
}

footer.page table.history { font-size: 13px; }

/* ========== body.page-X scope の例 ==========
 * 用途: ページ固有レイアウト。必ず body.page-X scope を付けて衝突を避ける。
 * 命名規則: page-X の X は HTML ファイル名から拡張子を除いた kebab-case。 */

/* 例 1: アーキテクチャ context ページ専用の階層フロー */
body.page-context .layer-flow {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin: 20px 0;
}

/* 例 2: 用語集ページの 2 カラム用語表 */
body.page-glossary .term-grid {
  display: grid;
  grid-template-columns: 10em minmax(0, 1fr);
  gap: 12px 24px;
  margin: 0;
}

body.page-glossary .term-grid dt { font-weight: 700; }
body.page-glossary .term-grid dd { margin: 0; color: var(--text-soft); }

@media (max-width: 900px) {
  body.page-glossary .term-grid { grid-template-columns: minmax(0, 1fr); gap: 2px; }
  body.page-glossary .term-grid dd { margin-bottom: 12px; }
}

/* ========== @page / @media print ==========
 * 用途: 印刷時に図・callout・pre が途中で切れないように break-inside: avoid。
 *       目次と前後ナビは紙では使えないので消し、本文を全幅にする。
 *       @page で A4 マージン (18mm × 16mm) を明示し、業務 PDF 配布の安定性を確保。 */
@page {
  size: A4;
  margin: 18mm 16mm;
}

@media print {
  .layout { display: block; padding: 0; }
  main, .layout > main { max-width: 100%; padding: 0; }
  nav.toc, .page-nav { display: none; }
  .svg-wrap, .note-box, .callout-negative, .tldr, .tile, pre, table { break-inside: avoid; }
  a { color: var(--text); }
}
```

各 HTML の `<head>` に Google Fonts の読み込みを追加する:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&family=Noto+Sans+Mono:wght@400;700&display=swap">
```

このコア骨格（約 500 行）で「複数 HTML ページ + 視覚的一貫性 + 印刷対応」の必要最低限が揃う。節が 4 つ以上のページは `.layout` + `nav.toc` で左に目次を出し、概況ページは `.tiles` で集計を冒頭に並べる。プロジェクト固有のレイアウト（`.tree` / `.decision-grid` / `.pillars` など）は `body.page-X` scope で追加していく。

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

既存 HTML 補足ページを SSOT + 生成時インライン展開型へ移行する手順。起点は 2 通り: **(a) 分散直書き型**（各 HTML が独自の `<style>` を持つ。cloud-dsc Phase 7a〜7c はこの起点の実例）と **(b) 旧 `<link>` 参照型**（2026-06-10 の方針再定義以前に集約済みのプロジェクト）。(b) 起点の場合 Phase 1 の SSOT 整備は済んでいるため Phase 2 から着手する。各 Phase の **遷移条件**（次に進んでよい判定）をチェックリストで明示する。

### Phase 1: 共通 CSS 雛形作成

- [ ] `_shared/spec-page.css` を本ファイル「共通 CSS の最小骨格」を雛形に新規作成
- [ ] 1 ファイルだけ選んで SSOT を `<style data-shared-source="...">` へインライン展開（既存の内部 `<style>` はまだ残す）
- [ ] ブラウザで開いて表示崩れがないか確認
- [ ] 既存の内部 `<style>` で **同名クラスの衝突** がないか目視チェック（展開した共通 CSS の `header.page h1` を内部 `<style>` の `header.page h1` が上書きしていないか）

**遷移条件**: 1 ファイルで展開した共通 CSS が機能し、上書き事故が起きないことを確認できたら Phase 2。

### Phase 2: 個別 HTML の `<style>` 縮小（ファイル単位で繰り返す）

各 HTML ファイルについて:

- [ ] `<body>` に `class="page-X"` を付与（X は HTML ファイル名の kebab-case）
- [ ] 旧 `<link rel="stylesheet" href=".../_shared/spec-page.css">` があれば削除し、`<style data-shared-source="...">` へのインライン展開に置き換え
- [ ] 内部 `<style>` から共通 CSS と重複する定義（`html, body`, `header.page h1`, `.tldr` 等）を削除
- [ ] ページ固有レイアウト（`.layer-flow` 等）は SSOT 側に `body.page-X` scope 付きで移動し、HTML へ再展開
- [ ] 固有 `<style>` を **`:root` 固有変数のみ**（10-30 行目安）に縮小
- [ ] ブラウザで visual diff を取り、意図しない変化がないことを確認

**LLM 手作業で移行するときの踏み外し防御**（スクリプト未導入時に特に注意。エージェントが踏みやすい罠）:

- **SSOT は全文を省略せず転記する**: 3072 行規模を Read → そのまま展開する。`/* … */` での畳み込み・要約・「以下同様」は厳禁。転記後に SSOT と行数・バイト数が一致するか確認する（一致しなければ不完全コピー）
- **`data-shared-source` の相対パスは階層ごとに算出する**: `docs/_html/overview.html` なら `../_shared/spec-page.css`、`docs/_html/architecture/context.html` なら `../../_shared/spec-page.css`。固定例をそのまま貼らない（深さでズレる）
- **Google Fonts の `<link>` は消さない**: CSS の `<link>` を削除するのは旧 `_shared/spec-page.css` への参照だけ。`fonts.googleapis.com` への `<link>`（preconnect 2 本 + stylesheet 1 本）は残す。「重複 link」と誤認して消すと Web フォントが効かなくなる

**遷移条件**: 全 HTML ファイルでこのリストが完了したら Phase 3。

### Phase 3: 共通 CSS の整理

- [ ] 共通 CSS 全体を読み返し、scope なしで定義されている要素が「本当に汎用か」を判定
- [ ] 汎用でなければ `body.page-X` scope を後付けで追加
- [ ] `:root` 変数の命名が `--accent` / `--primary-color` のような重複になっていないか確認
- [ ] 不要になった内部 `<style>` 由来のクラスを削除
- [ ] `--accent` / `--accent-deep` の値が DADS Blue 系列と整合しているか確認:
  - **デフォルト (DADS key-color = Blue) を採用する場合**: `--accent` = Blue 700 (`#264af4`)、`--accent-deep` = Blue 900 (`#0017c1`)、`--accent-bg` = Blue 50 (`#e8f1fe`) が [`dads-tokens.md`](./dads-tokens.md) 1 節と一致するか確認
  - **別系統 (DADS Light Blue / Green / Orange 等) を採用した場合**: [`dads-tokens.md`](./dads-tokens.md) 2 節の該当色族の階調と HEX 整合を確認し、選定 ADR が残っているか確認

**遷移条件**: 共通 CSS が「scope 付き = ページ固有 / scope なし = 汎用」で綺麗に分離されたら Phase 4。

### Phase 4: 視覚一貫性のレビュー観点

- [ ] フォント・h1 サイズ・配色が全 HTML で揃っているか（ページを順次開いて目視）
- [ ] SSOT 変更 → 全 HTML 再展開で全ページに反映されるか試す（テスト用に `--accent` を別色に変えて再展開して確認、終わったら元に戻して再展開）
- [ ] **単体配布テスト**: HTML を 1 ファイルだけリポジトリ外（一時フォルダ等）へコピーして開き、表示が崩れないことを確認（self-contained の実証）
- [ ] 印刷プレビューで `.svg-wrap` などが切れていないか（`@media print` scope の確認）
- [ ] 「伝わるデザイン」レビューチェックリスト（[`communicative-design.md`](./communicative-design.md) 末尾）を新規 HTML に適用してパスするか

**完了条件**: 上記すべてパスしたら共通 CSS 集約は完了。以降の新規 HTML 追加は「`<body class="page-X">` + `:root` 固有変数のみ」のみで作れる。

## 期待される効果（cloud-dsc 実証）

- フォント・h1 サイズ・配色が全 HTML で完全に揃う（個別 `<style>` の上書き事故ゼロ）
- 共通 CSS（SSOT）1 ファイル変更 + 全 HTML 再展開で一括反映可能（ベースカラー切り替え等）
- レビューポイントが集中する（SSOT だけ見れば視覚設計の全体像が分かる）
- 新規 HTML 追加コストが下がる（SSOT 展開 + `<body class="page-X">` + `:root` 固有変数のみで完了）
- **HTML 1 ファイル単体で共有・閲覧できる**（リポジトリ checkout 不要。ダウンロード・チャット添付でそのまま開ける）

## 規模の許容

共通 CSS は規模が大きくなる（cloud-dsc は 3072 行、2026-05-14 時点）。これは **許容する**。代わりに以下のメリットが得られる:

- 個別ファイル変更コストはほぼゼロ（`:root` 固有変数のみ）
- 一括変更が可能（配色・タイポ・余白の全体刷新が SSOT 1 ファイル編集 + 全 HTML 再展開で完結）
- レビュー時の見落としが減る（CSS の全体像が 1 ファイルに集約）

**インライン展開のトレードオフ**: 各 HTML に共通 CSS 全文が埋め込まれるためファイルサイズは増える（3000 行 ≈ 100KB 弱/ページ）。単体配布可能性を優先してこれを許容する。

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

ただし分割するとファイル間の関係性が見えづらくなるため、**3000 行までは 1 ファイルで運用するのが推奨**（cloud-dsc は単一ファイル運用で問題なし）。分割した場合も、HTML への展開時は import を解決して全文を結合インライン化する（配布物の self-contained 性は変わらない）。

## 関連参照

- 既存プロジェクトを本方針へ移行する起動プロンプト → [`migration-prompt.md`](./migration-prompt.md)
- 展開・検証スクリプト雛形 → [`expand-shared-css.ts`](./expand-shared-css.ts)
- 視覚一貫性の原則的な裏付け → [`communicative-design.md`](./communicative-design.md) 原則 3「反復」
- DADS デザイントークン正本（HEX 全量・タイポ・角丸・影）→ [`dads-tokens.md`](./dads-tokens.md)
- HTML 単体テンプレ（共通 CSS なしの最小骨格）→ [`templates.md`](./templates.md) HTML 補足テンプレート
- 用途別配色・図表タイトル命名 → [`visual-encoding.md`](./visual-encoding.md)

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
| 既存プロジェクトに HTML 補足ページが分散 `<style>` 直書き or 旧 `<link>` 参照型で書かれている | [§段階的移行手順](#段階的移行手順) で順次移行 |

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
- 各 HTML は `<link>` で参照**しない**。生成・更新時に SSOT 全文を `<style data-shared-source="...">` へインライン展開する（[§生成時インライン展開の運用ルール](#生成時インライン展開の運用ルール)）
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
  <header class="page">...</header>
  <main>...</main>
  <footer class="page">...</footer>
</body>
</html>
```

個別 HTML の **固有 `<style>`（2 つ目のブロック）** は **10〜30 行**（`:root` 固有変数のみ）に収める。`html, body { ... }` や `.toc { ... }` などのレイアウトは絶対に書かない（共通 CSS を上書きする事故の温床）。

## 生成時インライン展開の運用ルール

SSOT と配布物の関係を壊さないための規約:

- **編集は必ず SSOT（`_shared/spec-page.css`）側で行う（MUST）**。HTML 内のインラインコピーを直接編集しない（次回再展開で消える）
- HTML の新規生成・更新時、SSOT を読み込んで `<style data-shared-source="<SSOT への相対パス>">` ブロックへ全文展開する。`data-shared-source` 属性が「このブロックは生成コピーである」ことの機械可読マーカーを兼ねる
- インラインコピーの先頭に「SSOT の生成時コピー・直接編集禁止」コメントを必ず入れる
- **SSOT を変更したら、同プロジェクトの全 HTML 補足ページへ再展開して伝播する**。対象は `grep -rl 'data-shared-source' docs/` で機械的に列挙できる。要件レベルは展開手段で変わる:
  - **展開スクリプトを導入しているプロジェクト（[§展開・検証スクリプト](#展開検証スクリプト)）**: SSOT 編集とコミットは全 HTML 再展開とセットでなければならない（**MUST**、1 コミット完結）。手作業より遥かに安全なため強制できる
  - **スクリプト未導入（LLM 手作業で展開）**: 全 HTML 再展開は **SHOULD**。ただし「SSOT だけ直して HTML は後で」は drift 未収束コミットを生むため、可能な限り同一セッションで再展開する
- **外部資産を埋め込まない（MUST）**: self-contained を壊さないため、`<img src="...">`・外部 `.svg` ファイル参照・`@import`・相対パスのローカル資産を HTML に入れない。図は **インライン SVG または data URI** で埋め込む（`.svg-wrap` は「インライン SVG 前提」）。Google Fonts の `<link>`（CDN 参照）だけは例外として残してよい — CDN 遮断環境では `--font-sans` の fallback（BIZ UDPGothic 等）に落ちる設計で、単体配布性を実用上損なわないため
- drift 検査: インラインコピー（`<style data-shared-source>` の中身）を抽出し SSOT と正規化 diff すれば再展開漏れを検出できる。スクリプト導入時は `--check` で自動化（[§展開・検証スクリプト](#展開検証スクリプト)）、未導入時は MAY
- **git diff ノイズの緩和（任意）**: SSOT 1 行変更が全 HTML の `<style>` ブロックに伝播し diff が肥大化する。レビューでシグナルが埋もれるのが気になるなら、`.gitattributes` に該当 HTML への `linguist-generated` 付与や `*.html -diff`（差分非表示）を検討する。ただし HTML 本文の実変更も隠れるため、CSS 専用ディレクトリを分けない限り副作用に注意

## 展開・検証スクリプト

LLM の手作業展開は「全文コピー漏れ・相対パスズレ・再展開忘れ」を生むため、**展開と drift 検査をスクリプトに寄せる（SHOULD、特に HTML が 3 本以上 or 更新頻度が高いプロジェクト）**。雛形を [`expand-shared-css.ts`](./expand-shared-css.ts) に置いている。これを各リポジトリへコピーして使う（配置例 `scripts/expand-shared-css.ts`）。

- **言語**: TypeScript（`tsx` / `ts-node` で実行）。Node 標準ライブラリのみで外部 npm 依存なし。cloud-dsc / cloud-cmp 等の TS リポジトリと馴染む。Python 主体のリポジトリでも `npx tsx` で単発実行できる
- **やること**: SSOT を読み、`docs/` 以下で `data-shared-source` を持つ全 HTML を発見し、各 HTML の `<style data-shared-source>` ブロックを SSOT 全文で置換する。`data-shared-source` の相対パスは各 HTML の階層から自動算出するため、パスズレが構造的に起きない
- **2 モード**:
  - 展開: `npx tsx scripts/expand-shared-css.ts` — 全対象 HTML を SSOT 最新で上書き
  - 検証: `npx tsx scripts/expand-shared-css.ts --check` — drift があれば非ゼロ終了。**pre-commit hook / CI に組み込めば再展開漏れを無症状放置させない**
- スクリプト導入時、SSOT 編集とコミットは「展開して 1 コミット」が **MUST**（[§生成時インライン展開の運用ルール](#生成時インライン展開の運用ルール)）。`--check` を CI ゲートにすると規約を機械的に担保できる

スクリプトを導入しない（手作業展開の）場合は、移行手順 [§Phase 2 の踏み外し防御](#phase-2-個別-html-の-style-縮小ファイル単位で繰り返す)に従い、全文転記・相対パス・Google Fonts link 保持を人手で守る。

## 共通 CSS の最小骨格

> **配色・タイポトークンは デジタル庁デザインシステム (DADS) v2.0.1 由来**（MIT, Copyright (c) 2023 デジタル庁）。HEX 値の正本（SSOT）は [`dads-tokens.md`](./dads-tokens.md)。本ファイルで再掲する HEX は同ファイルからの引用であり、本ファイルでは値を変更しない（drift 防止）。

**スタイル骨格の出典**: 本テンプレートは **DADS v2.0.1 準拠**（key-color = Blue 固定）。配色・タイポ・角丸・影は DADS トークンから引いている。各セクション冒頭にコメントで **用途** を明記しているので、不要なセクションは丸ごと削れる。

**規模・運用パターンの実証例**: cloud-dsc プロジェクトの `_shared/spec-page.css`（**3072 行、2026-05-14 時点**）。**配色は旧版 Blue 900 ベース** で運用されてきたが、現在は本テンプレ準拠（DADS）への移行対象。ファイル別 scope での全レイアウト統合パターン・3000 行規模の単一ファイル運用は本テンプレ採用時の参考になる。

**`--accent` の値について**: 下記サンプルは DADS key-color (Blue 700 `#264af4`) を `--accent` に、Blue 900 `#0017c1` を `--accent-deep`（本文リンクで AAA pass）、Blue 50 `#e8f1fe` を `--accent-bg`、Solid Gray 900 `#1a1a1a` を `--accent-ink` として採用。**ベースカラーは Blue 固定**（spec-writer デフォルト）。ブランド要請等で別色を採用する場合は [`dads-tokens.md`](./dads-tokens.md) §2 の DADS プリミティブ 10 色族（Light Blue / Cyan / Green / Lime / Yellow / Orange / Red / Magenta / Purple）から階調を選び、選定 ADR を残す（[`adr-format.md`](./adr-format.md) §カラー選定 ADR）。

**フォントの選定について**: 日本語・等幅とも DADS 採用フォントを使う。日本語は `Noto Sans JP`（Google Fonts、SIL OFL 1.1）、等幅は `Noto Sans Mono`（CJK + Latin 対応）。UD フォント原則（[`./communicative-design.md`](./communicative-design.md) 原則 7）の保険として `BIZ UDPGothic` / `BIZ UDGothic` を fallback に並べ、Google Fonts CDN 遮断環境（社内 LAN proxy 等）では UD 保険へ自動 fallback する。ウェイトは DADS 採用の `400 (Normal) / 700 (Bold)` の 2 段階のみ。

```css
/* ========== :root 変数（全ページ共通） ==========
 * 用途: DADS v2.0.1 準拠 (key-color = Blue) の配色・タイポ・角丸・影を仕様書 HTML
 *       へ単一出典化。基本色は Solid Gray ladder、リンクは Blue 900 (AAA pass)、
 *       状態色は DADS セマンティック (Green/Red/Yellow)。
 *       ページ固有色 (--feature 等) は個別 HTML の <style> :root に置く。
 *       HEX 値の出典は references/dads-tokens.md。 */
:root {
  /* 基本色 — DADS Neutral Solid Gray ladder */
  --bg: #ffffff;              /* white = ページ背景 */
  --bg-elev: #ffffff;
  --surface: #f2f2f2;         /* Solid Gray 50 = card / inset surface */
  --surface-soft: #f2f2f2;    /* Solid Gray 50 = code 背景等 */
  --text: #1a1a1a;            /* Solid Gray 900 = 本文 */
  --text-soft: #4d4d4d;       /* Solid Gray 700 = 補助本文 */
  --muted: #4d4d4d;           /* Solid Gray 700 */
  --muted-soft: #7f7f7f;      /* Solid Gray 500 = placeholder / mono eyebrow */
  --border: #e6e6e6;          /* Solid Gray 100 = hairline */
  --border-strong: #b3b3b3;   /* Solid Gray 300 = hairline-strong */

  /* アクセント色 — DADS key-color = Blue */
  --accent: #264af4;          /* Blue 700 = key-color (UI primary、3:1 担保) */
  --accent-deep: #0017c1;     /* Blue 900 = 本文リンク (on #ffffff で 約 13.7:1 AAA) */
  --accent-bg: #e8f1fe;       /* Blue 50 = badge / pill 背景 */
  --accent-ink: #1a1a1a;      /* Solid Gray 900 = CTA black ink */
  --accent-on-ink: #ffffff;

  /* 状態色 — DADS セマンティック (success/error/warning)
   * 11px の badge は通常テキスト扱い (Large 例外不可) のため、各 -2 階調 (濃いめ) を
   * テキスト色に、対応 50 階調を背景に採用して 4.5:1 以上を担保。 */
  --status-pass: #197a4b;       /* Green 800 (on #e6f5ec で AA pass) */
  --status-pass-bg: #e6f5ec;    /* Green 50 */
  --status-fail: #ce0000;       /* Red 900 (on #fdeeee で AA pass) */
  --status-fail-bg: #fdeeee;    /* Red 50 */
  --status-pending: #927200;    /* Yellow 900 (on #fbf5e0 で AA pass) */
  --status-pending-bg: #fbf5e0; /* Yellow 50 */

  /* タイポグラフィ — DADS 採用フォント (Noto Sans JP + Noto Sans Mono)
   * 並び順: DADS 採用フォントを先頭に、Google Fonts CDN 遮断時の UD 保険として
   * BIZ UDPGothic / BIZ UDGothic を 2 番目に並べる。これにより平時は Noto Sans JP、
   * CDN 遮断環境では UD フォントへ自動 fallback (communicative-design.md 原則 7)。
   * Noto Sans Mono は CJK + Latin 等幅対応のため、CJK 等幅 fallback も同フォントで
   * 賄えるが、念のため BIZ UDGothic を保険として明示する。 */
  --font-sans: 'Noto Sans JP', 'BIZ UDPGothic', system-ui, sans-serif;
  --font-mono: 'Noto Sans Mono', ui-monospace, 'BIZ UDGothic', monospace;

  /* 行長 (communicative-design.md 原則 8) */
  --reading-width: 70ch;

  /* シャドウ — DADS elevation 8 段階を 3 段階 (1/3/5) に間引いて採用
   * 単段ではなく多段 drop で「カードがページに乗っている」効果。
   * xs は inset hairline のみ (DADS には該当なし、独自定義)。 */
  --shadow-xs: 0 0 0 1px rgba(0, 0, 0, 0.06) inset;
  --shadow-sm: 0 2px 8px 1px rgba(0,0,0,0.1), 0 1px 5px 0 rgba(0,0,0,0.3);   /* DADS elevation-1 */
  --shadow-md: 0 4px 16px 3px rgba(0,0,0,0.1), 0 1px 6px 0 rgba(0,0,0,0.3);  /* DADS elevation-3 */
  --shadow-lg: 0 8px 24px 5px rgba(0,0,0,0.1), 0 2px 10px 0 rgba(0,0,0,0.3); /* DADS elevation-5 */

  /* 角丸 — DADS radius スケール (4/6/8/12/16/24/32/full) から採用 */
  --radius-sm: 4px;            /* badge / chip */
  --radius-md: 8px;            /* ボタン・フォーム */
  --radius-lg: 12px;           /* カード */
  --radius-pill: 9999px;       /* DADS full = 完全な円弧 */
}

/* ========== リセット・基本タイポ ==========
 * 用途: ブラウザ既定値の差を吸収し、Noto Sans JP の組み合わせを全ページへ。
 *       font-feature-settings の pwid で約物の詰めを行う (Noto Sans JP は palt 未実装)。 */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-feature-settings: 'pwid';   /* Noto Sans JP は palt 未実装 */
  font-size: 16px;                 /* DADS 本文標準 */
  line-height: 1.7;                /* DADS 本文推奨 (170%) */
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
 * 用途: a 要素は DADS Blue 900 (#0017c1) を採用。本文背景 #ffffff 上で約 13.7:1 で
 *       WCAG AAA pass。key-color = Blue 700 (#264af4) は本文リンクには 4.5:1 を
 *       下回るため、本文には Blue 900 を使う (UI primary としての key-color は別途)。
 *       WCAG 1.4.1 (色のみで情報伝達禁止) 対応のため **平常時から underline を付ける**。
 *       :focus-visible で keyboard navigation の可視性も担保 (WCAG 2.4.7)。
 *       code は surface 上のグレー背景、pre は ink 背景の code-editor-mockup 風。 */
a {
  color: var(--accent-deep);   /* Blue 900 #0017c1 on #ffffff で 約 13.7:1 AAA */
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 2px;
  transition: text-decoration-thickness 0.15s;
}
a:hover { text-decoration-thickness: 2px; }
a:visited { color: #5109ad; }   /* DADS Purple 900 = visited 識別 (on #ffffff で 約 9.3:1 AAA) */
a:focus-visible,
button:focus-visible,
[tabindex]:focus-visible {
  outline: 2px solid var(--accent-deep);   /* Blue 900 = link 色と整合 */
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
  background: var(--text);             /* Solid Gray 900 #1a1a1a = code-editor-mockup */
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
 *       breadcrumb は mono eyebrow、h1 は DADS heading scale 45px (display-md)、
 *       weight 700 (DADS は 400 / 700 の 2 段階のみ)。 */
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
  font-size: 45px;             /* DADS heading scale */
  font-weight: 700;            /* DADS は 400 / 700 の 2 段階 */
  margin: 0 0 14px;
  letter-spacing: -0.025em;    /* 和文見出しと混在する仕様書では弱めに抑える
                                * (DADS 字詰めは 0 / 1% / 2% を提供するが、和欧混在では
                                * 0 〜 -0.025em を選ぶ) */
  line-height: 1.3;            /* DADS 見出し推奨 (130%) */
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
 * 用途: 各ページ冒頭の TL;DR ブロック。左ボーダーを ink (黒) にして
 *       「sober で技術的」な印象に。label のみアクセントブルー。 */
.tldr {
  background: var(--surface);
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent-ink);   /* black bar */
  border-radius: var(--radius-md);
  padding: 24px 28px;
  font-size: 16px;             /* DADS 本文標準 */
  line-height: 1.75;           /* DADS 本文 (175%) */
  box-shadow: var(--shadow-md);
  margin: 0 0 32px;
}

.tldr .label {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 400;
  color: var(--accent-deep);   /* Blue 900 on Blue 50 で AA pass */
  background: var(--accent-bg);
  padding: 3px 12px;
  border-radius: var(--radius-pill);
  margin-bottom: 12px;
}

/* ========== section ==========
 * 用途: ページ内のセクション区切り。h2/h3 + 本文の基本レイアウト、行長制約も適用。
 *       DADS heading scale から h2=32px / h3=20px を採用、weight は 700 (DADS 2 段階)。 */
section { margin: 96px 0; }

section > h2 {
  font-size: 32px;             /* DADS heading */
  font-weight: 700;
  margin: 0 0 14px;
  padding-bottom: 14px;
  letter-spacing: -0.02em;
  line-height: 1.3;            /* DADS 見出し (130%) */
}

section > h3 {
  font-size: 20px;             /* DADS heading */
  font-weight: 700;
  margin: 48px 0 12px;
  letter-spacing: -0.01em;
  line-height: 1.4;            /* DADS 見出し (140%) */
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
  font-family: var(--font-mono);     /* data-table-cell の mono eyebrow */
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

/* ========== badge (secondary + status バリアント) ==========
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
.badge.accent  { background: var(--accent-bg);         color: var(--accent-deep); }  /* Blue 900 on Blue 50 で約 12.5:1 AAA */

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
 *       【self-contained 必須】図は必ず **インライン <svg>** か data URI で埋め込む。
 *       <img src="diagram.svg"> のような外部ファイル参照は単体配布で壊れる。
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
  .page-nav, footer.page { display: none; }
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
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&family=Noto+Sans+Mono:wght@400;700&display=swap">
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

既存 HTML 補足ページを SSOT + 生成時インライン展開型へ移行する手順。起点は 2 通り: **(a) 分散直書き型**（各 HTML が独自の `<style>` を持つ。cloud-dsc Phase 7a〜7c はこの起点の実例）と **(b) 旧 `<link>` 参照型**（2026-06-10 の方針再定義以前に集約済みのプロジェクト）。(b) 起点の場合 Phase 1 の SSOT 整備は済んでいるため Phase 2 から着手する。各 Phase の **遷移条件**（次に進んでよい判定）をチェックリストで明示する。

### Phase 1: 共通 CSS 雛形作成

- [ ] `_shared/spec-page.css` を本ファイル「§共通 CSS の最小骨格」を雛形に新規作成
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
  - **デフォルト (DADS key-color = Blue) を採用する場合**: `--accent` = Blue 700 (`#264af4`)、`--accent-deep` = Blue 900 (`#0017c1`)、`--accent-bg` = Blue 50 (`#e8f1fe`) が [`dads-tokens.md`](./dads-tokens.md) §1 と一致するか確認
  - **別系統 (DADS Light Blue / Green / Orange 等) を採用した場合**: [`dads-tokens.md`](./dads-tokens.md) §2 の該当色族の階調と HEX 整合を確認し、選定 ADR が残っているか確認

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
- HTML 単体テンプレ（共通 CSS なしの最小骨格）→ [`templates.md`](./templates.md) §HTML 補足テンプレート
- 用途別配色・図表タイトル命名 → [`visual-encoding.md`](./visual-encoding.md)

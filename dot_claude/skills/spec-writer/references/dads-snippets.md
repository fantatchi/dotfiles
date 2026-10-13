# DADS HTML 版コードスニペットの参照先

HTML 補足ページの部品を足す・直すときに、DADS 公式の実装のどこを見るかの対応表。色の値の正本は [`dads-tokens.md`](./dads-tokens.md)。ここには部品の構造と、写すべき点だけを置く。

- リポジトリ: https://github.com/digital-go-jp/design-system-example-components-html （MIT、Copyright (c) デジタル庁）
- Storybook（動く見本と解説）: https://design.digital.go.jp/dads/html/
- 取込時に見たコミット: `af8b665`（2026-09-09）
- 各部品の CSS は `src/components/<name>/<name>.css`、マークアップの例は同じディレクトリの `*.html`。トークンと共通のフォーカス表示は `src/global.css`

取得は `gh api repos/digital-go-jp/design-system-example-components-html/contents/src/components/<name>/<name>.css --jq .content | base64 -d` か、浅い clone で行う。

## 使い方の規則

- `dads-` のクラスや `calc(N / 16 * 1rem)` の書き方はそのまま持ち込まない。値と構造だけを、spec-writer の共通 CSS のクラス（[`html-css-centralization.md`](./html-css-centralization.md)）に写す。共通 CSS が DADS の全部品を抱えると、仕様書には不要な部品の分だけ重くなるため
- 次の 3 つは写すときに削らない。DADS の必須要件で、見た目の好みで外してよいものではない
  - フォーカス表示（黒 4px + Yellow 300 の縁取り。ガイダンスで変更不可とされている）
  - WAI-ARIA の指定（`aria-label`・`aria-current` など）と、ネイティブ要素（`<details>`・`<nav>`・`<ol>`）の選び方
  - `@media (forced-colors: active)` の分岐（Windows のハイコントラスト表示で、背景色で描いた印が消えるのを防ぐ）
- 文字は 14px 未満にしない。DADS の部品は本文 16px が基準で、最小は 14px
- 公式は最新版を追い続けない。値を写し直すのは、DADS のメジャー更新か、部品を新しく足すときだけにする（[`dads-tokens.md`](./dads-tokens.md) 10 節の運用と同じ）

## 部品の対応表

| spec-writer の部品 | 公式のコンポーネント | 写す点 |
|---|---|---|
| `a` | `link` | 通常 Blue 1000、hover で Blue 900 + 下線 3px、訪問済み Magenta 900、押下中 Orange 800。hover は `@media (hover: hover)` の中 |
| フォーカス全般 | `global.css` の `:focus-visible` | 共通 CSS に写し済み。ページ固有 CSS で上書きしない |
| `table` | `table` | 罫線 Solid Gray 420、見出し行の下線は黒、縞模様の表は罫線を Solid Gray 500 にして縞は Solid Gray 50。キャプションは 17px 太字。見出し行の灰色背景は spec-writer では付けない（2026-10-13 に罫線だけ揃えると決めた） |
| `nav.toc` | `toc` | 入れ子の目次は親を太字、子を通常の太さにする。リンク色は本文と同じ色を継承させる |
| 用語集 `.term-grid` | `description-list` | `<dl>` を使い、`dt` を太字、`dd` を 32px 字下げ。長い英字は `overflow-wrap: anywhere` で折り返す |
| `.callout-negative` | `notification-banner` | 種類ごとの枠の色: error は Red 800、warning は Yellow 900、success は Green 800、info は Blue 900。見出しは 17〜20px 太字。アイコンだけで種類を伝えず見出しの文字で書く |
| `.note-box`・引用 | `blockquote` | 左に 8px の罫線（Solid Gray 536）。中の最初と最後の要素の余白を 0 にする |
| `.badge` | `chip-label` | 枠の色と文字の色を同じ系統にし、塗りは 50 階調。角丸 8px。文字は 14px 以上 |
| `section > h2` | `heading` | 下罫線を付けるなら key-color 900、太さ 2〜8px。見出しの左に色の帯を付ける版は、強制カラーで `CanvasText` に切り替える |
| `.breadcrumb` | `breadcrumb` | `<nav aria-label="パンくずリスト">` の中に `<ol>` で並べ、現在のページに `aria-current="page"` を付ける |
| `details` | `disclosure` / `accordion` | 標準の三角を消して独自のアイコンにするなら、`summary` のフォーカス表示を必ず付ける。開閉アイコンは key-color 1000 |

ほかの部品（ボタン・フォーム・モーダルなど）は仕様書の補足ページでは使わない想定なので、対応表に入れていない。必要になったら同じ形で行を足す。

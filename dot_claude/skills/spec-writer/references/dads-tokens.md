# DADS デザイントークン正本（v2.0.1）

spec-writer の HTML 補足ページが採用するデザイントークンの **唯一の出典 (SSOT)**。他の `references/*.md`・HTML 補足ページの `<style>`・各プロジェクトの `_shared/spec-page.css` は本ファイルの値を引用する。**HEX 値を再掲する場合は出典として「dads-tokens.md §...」を併記**して drift を防ぐ。

DADS は **デジタル庁デザインシステム (Digital Agency Design System)**。アクセシビリティ標準 (JIS X 8341-3:2016 AA) 準拠を担保した公的標準で、配色・タイポ・角丸・影の体系を提供する。

- 取込版: **v2.0.1**（リリース 2026-05-28）
- 取込日: 2026-06-18
- 出典: https://github.com/digital-go-jp/design-tokens
- 公式サイト: https://design.digital.go.jp/dads/
- ライセンス: 末尾「## ライセンス・出典」参照

---

## 1. key-color（spec-writer のデフォルト = Blue 固定）

spec-writer は **key-color = Blue 固定**。ベースカラー切替機構は廃止（2026-06-18 改定）。ブランド理由で別色を採用する場合は本ファイルの「## 2. プリミティブカラー」から選び、選定 ADR を残す（手順は `adr-format.md`）。

key-color の各階調は Blue プリミティブを参照する:

| Level | 参照 | HEX |
|---|---|---|
| 50 | Blue-50 | `#e8f1fe` |
| 100 | Blue-100 | `#d9e6ff` |
| 200 | Blue-200 | `#c5d7fb` |
| 300 | Blue-300 | `#9db7f9` |
| 400 | Blue-400 | `#7096f8` |
| 500 | Blue-500 | `#4979f5` |
| 600 | Blue-600 | `#3460fb` |
| 700 | Blue-700 | `#264af4` |
| 800 | Blue-800 | `#0031d8` |
| 900 | Blue-900 | `#0017c1` |
| 1000 | Blue-1000 | `#00118f` |
| 1100 | Blue-1100 | `#000071` |
| 1200 | Blue-1200 | `#000060` |

**spec-writer の用途別マッピング**（白背景 `#ffffff` 前提、WCAG AA 4.5:1 担保）:

| 用途 | 推奨 Level | HEX | 備考 |
|---|---|---|---|
| 本文リンク (`a`) | Blue-900 | `#0017c1` | 白背景でコントラスト約 13.7:1 (AAA) |
| 訪問済リンク (`a:visited`) | Purple-900 | `#5109ad` | 白背景でコントラスト約 9.3:1 (AAA) |
| 強調・アクセント深 | Blue-1000 | `#00118f` | hover 等 |
| アクセント面（badge 等の背景） | Blue-50 | `#e8f1fe` | text は Blue-1000 と組合せ |
| key-color (UI primary) | Blue-700 | `#264af4` | 非テキスト UI で 3:1 担保 |

---

## 2. プリミティブカラー（10 色族 × 13 階調）

各色族 `50 / 100 / 200 / 300 / 400 / 500 / 600 / 700 / 800 / 900 / 1000 / 1100 / 1200`。

### Blue

| Level | HEX |
|---|---|
| 50 | `#e8f1fe` |
| 100 | `#d9e6ff` |
| 200 | `#c5d7fb` |
| 300 | `#9db7f9` |
| 400 | `#7096f8` |
| 500 | `#4979f5` |
| 600 | `#3460fb` |
| 700 | `#264af4` |
| 800 | `#0031d8` |
| 900 | `#0017c1` |
| 1000 | `#00118f` |
| 1100 | `#000071` |
| 1200 | `#000060` |

### Light Blue

| Level | HEX |
|---|---|
| 50 | `#f0f9ff` |
| 100 | `#dcf0ff` |
| 200 | `#c0e4ff` |
| 300 | `#97d3ff` |
| 400 | `#57b8ff` |
| 500 | `#39abff` |
| 600 | `#008bf2` |
| 700 | `#0877d7` |
| 800 | `#0066be` |
| 900 | `#0055ad` |
| 1000 | `#00428c` |
| 1100 | `#00316a` |
| 1200 | `#00234b` |

### Cyan

| Level | HEX |
|---|---|
| 50 | `#e9f7f9` |
| 100 | `#c8f8ff` |
| 200 | `#99f2ff` |
| 300 | `#79e2f2` |
| 400 | `#2bc8e4` |
| 500 | `#01b7d6` |
| 600 | `#00a3bf` |
| 700 | `#008da6` |
| 800 | `#008299` |
| 900 | `#006f83` |
| 1000 | `#006173` |
| 1100 | `#004c59` |
| 1200 | `#003741` |

### Green

| Level | HEX |
|---|---|
| 50 | `#e6f5ec` |
| 100 | `#c2e5d1` |
| 200 | `#9bd4b5` |
| 300 | `#71c598` |
| 400 | `#51b883` |
| 500 | `#2cac6e` |
| 600 | `#259d63` |
| 700 | `#1d8b56` |
| 800 | `#197a4b` |
| 900 | `#115a36` |
| 1000 | `#0c472a` |
| 1100 | `#08351f` |
| 1200 | `#032213` |

### Lime

| Level | HEX |
|---|---|
| 50 | `#ebfad9` |
| 100 | `#d0f5a2` |
| 200 | `#c0f354` |
| 300 | `#ade830` |
| 400 | `#9ddd15` |
| 500 | `#8cc80c` |
| 600 | `#7eb40d` |
| 700 | `#6fa104` |
| 800 | `#618e00` |
| 900 | `#507500` |
| 1000 | `#3e5a00` |
| 1100 | `#2c4100` |
| 1200 | `#1e2d00` |

### Yellow

| Level | HEX |
|---|---|
| 50 | `#fbf5e0` |
| 100 | `#fff0b3` |
| 200 | `#ffe380` |
| 300 | `#ffd43d` |
| 400 | `#ffc700` |
| 500 | `#ebb700` |
| 600 | `#d2a400` |
| 700 | `#b78f00` |
| 800 | `#a58000` |
| 900 | `#927200` |
| 1000 | `#806300` |
| 1100 | `#6e5600` |
| 1200 | `#604b00` |

### Orange

| Level | HEX |
|---|---|
| 50 | `#ffeee2` |
| 100 | `#ffdfca` |
| 200 | `#ffc199` |
| 300 | `#ffa66d` |
| 400 | `#ff8d44` |
| 500 | `#ff7628` |
| 600 | `#fb5b01` |
| 700 | `#e25100` |
| 800 | `#c74700` |
| 900 | `#ac3e00` |
| 1000 | `#8b3200` |
| 1100 | `#6d2700` |
| 1200 | `#541e00` |

### Red

| Level | HEX |
|---|---|
| 50 | `#fdeeee` |
| 100 | `#ffdada` |
| 200 | `#ffbbbb` |
| 300 | `#ff9696` |
| 400 | `#ff7171` |
| 500 | `#ff5454` |
| 600 | `#fe3939` |
| 700 | `#fa0000` |
| 800 | `#ec0000` |
| 900 | `#ce0000` |
| 1000 | `#a90000` |
| 1100 | `#850000` |
| 1200 | `#620000` |

### Magenta

| Level | HEX |
|---|---|
| 50 | `#f3e5f4` |
| 100 | `#ffd0ff` |
| 200 | `#ffaeff` |
| 300 | `#ff8eff` |
| 400 | `#f661f6` |
| 500 | `#f137f1` |
| 600 | `#db00db` |
| 700 | `#c000c0` |
| 800 | `#aa00aa` |
| 900 | `#8b008b` |
| 1000 | `#6c006c` |
| 1100 | `#500050` |
| 1200 | `#3b003b` |

### Purple

| Level | HEX |
|---|---|
| 50 | `#f1eafa` |
| 100 | `#ecddff` |
| 200 | `#ddc2ff` |
| 300 | `#cda6ff` |
| 400 | `#bb87ff` |
| 500 | `#a565f8` |
| 600 | `#8843e1` |
| 700 | `#6f23d0` |
| 800 | `#5c10be` |
| 900 | `#5109ad` |
| 1000 | `#41048e` |
| 1100 | `#30016c` |
| 1200 | `#21004b` |

---

## 3. ニュートラルカラー

### Solid Gray（10 階調）

| Level | HEX |
|---|---|
| 50 | `#f2f2f2` |
| 100 | `#e6e6e6` |
| 200 | `#cccccc` |
| 300 | `#b3b3b3` |
| 400 | `#999999` |
| 500 | `#7f7f7f` |
| 600 | `#666666` |
| 700 | `#4d4d4d` |
| 800 | `#333333` |
| 900 | `#1a1a1a` |

### White / Black

| 名称 | HEX |
|---|---|
| White | `#ffffff` |
| Black | `#000000` |

### Opacity Gray（10 階調、rgba）

| Level | 値 |
|---|---|
| 50 | `rgba(0,0,0,0.05)` |
| 100 | `rgba(0,0,0,0.1)` |
| 200 | `rgba(0,0,0,0.2)` |
| 300 | `rgba(0,0,0,0.3)` |
| 400 | `rgba(0,0,0,0.4)` |
| 500 | `rgba(0,0,0,0.5)` |
| 600 | `rgba(0,0,0,0.6)` |
| 700 | `rgba(0,0,0,0.7)` |
| 800 | `rgba(0,0,0,0.8)` |
| 900 | `rgba(0,0,0,0.9)` |

---

## 4. セマンティックカラー

JSON 上は 2 階調ペアで定義（`-1` = 軽め、`-2` = 濃いめ）。spec-writer は **白背景 `#ffffff` 上でテキスト用に使う想定で `-2` を採用**（コントラスト 4.5:1 を担保しやすい）。背景塗りに使う場合は `-1` を選ぶ。

| セマンティック | レベル | 参照 | HEX |
|---|---|---|---|
| success | 1 | Green-600 | `#259d63` |
| success | 2 | Green-800 | `#197a4b` |
| error | 1 | Red-800 | `#ec0000` |
| error | 2 | Red-900 | `#ce0000` |
| warning-yellow | 1 | Yellow-700 | `#b78f00` |
| warning-yellow | 2 | Yellow-900 | `#927200` |
| warning-orange | 1 | Orange-600 | `#fb5b01` |
| warning-orange | 2 | Orange-800 | `#c74700` |

> **未定義**: link / link-visited / focus / hover / border / background のセマンティックは DADS JSON に定義なし。spec-writer 側で「## 1. key-color」の用途別マッピングを採用する。

---

## 5. タイポグラフィ

### フォントファミリ（CSS 宣言まま）

```css
--font-sans: 'Noto Sans JP', 'BIZ UDPGothic', system-ui, sans-serif;
--font-mono: 'Noto Sans Mono', ui-monospace, 'BIZ UDGothic', monospace;
```

- DADS 採用: 和文 `Noto Sans JP` (SIL OFL 1.1) / 等幅 `Noto Sans Mono`
- UD 保険 fallback: `BIZ UDPGothic` / `BIZ UDGothic`（Google Fonts CDN 遮断環境で発動）
- ウェイトは **400 (Normal) / 700 (Bold)** の 2 段階のみ採用

### font-size スケール（px、15 段階）

DADS は `14, 16, 17, 18, 20, 22, 24, 26, 28, 32, 36, 45, 48, 57, 64` を提供。spec-writer の HTML 補足ページでの推奨選択:

| 用途 | 推奨 px |
|---|---|
| 本文 | 16 |
| 補助テキスト・キャプション | 14 |
| h3 | 20 |
| h2 | 32 |
| h1 (ページタイトル) | 45 |
| Display (hero) | 57 / 64 |

### line-height スケール（%、8 段階）

DADS は `100, 120, 130, 140, 150, 160, 170, 175` を提供。spec-writer での推奨:

| 用途 | 推奨 % |
|---|---|
| UI 単行 | 100–120 |
| 見出し | 130–140 |
| 本文（長文可読性優先） | 170 |

CSS では `line-height: 1.7` のように unitless 推奨。

---

## 6. 角丸（border-radius、px）

DADS スケール: `4 / 6 / 8 / 12 / 16 / 24 / 32 / full(9999px = 完全な円弧)`。spec-writer での推奨:

| 用途 | 推奨 px |
|---|---|
| バッジ・チップ | 4 |
| ボタン・入力 | 8 |
| カード・コードブロック | 12 |
| ダイアログ・モーダル | 16 |
| 円形アバター・トグル | full |

---

## 7. 影（elevation、box-shadow CSS）

DADS は 8 段階。spec-writer は drop-shadow を多用しない方針のため、`2 / 4 / 6` の 3 段階を主に採用（hover / focus / modal）。

| Level | box-shadow |
|---|---|
| 1 | `0 2px 8px 1px rgba(0,0,0,0.1), 0 1px 5px 0 rgba(0,0,0,0.3)` |
| 2 | `0 2px 12px 2px rgba(0,0,0,0.1), 0 1px 6px 0 rgba(0,0,0,0.3)` |
| 3 | `0 4px 16px 3px rgba(0,0,0,0.1), 0 1px 6px 0 rgba(0,0,0,0.3)` |
| 4 | `0 6px 20px 4px rgba(0,0,0,0.1), 0 2px 6px 0 rgba(0,0,0,0.3)` |
| 5 | `0 8px 24px 5px rgba(0,0,0,0.1), 0 2px 10px 0 rgba(0,0,0,0.3)` |
| 6 | `0 10px 30px 6px rgba(0,0,0,0.1), 0 3px 12px 0 rgba(0,0,0,0.3)` |
| 7 | `0 12px 36px 7px rgba(0,0,0,0.1), 0 3px 14px 0 rgba(0,0,0,0.3)` |
| 8 | `0 14px 40px 7px rgba(0,0,0,0.1), 0 3px 16px 0 rgba(0,0,0,0.3)` |

---

## 8. スペーシング（spec-writer 独自、8px グリッド）

DADS は「8px グリッド原則」を明示しているが、spacing トークンの数値定義は公開していない（取得不可）。spec-writer は 8px グリッド原則に整合する独自スケールを以下で定義:

| 名称 | px | 主な用途 |
|---|---|---|
| `--space-1` | 8 | 細かい余白、icon と text のギャップ |
| `--space-2` | 16 | 本文段落間、card 内 padding |
| `--space-3` | 24 | section 内ブロック間 |
| `--space-4` | 32 | section 間 |
| `--space-5` | 48 | 大セクション間 |
| `--space-6` | 64 | hero / ページ最大余白 |

> **注**: 上記は DADS 公式トークンではなく **spec-writer 独自定義**。DADS が将来 spacing トークンを公開した場合は再評価する（リスク欄参照）。

---

## 9. アクセシビリティ準拠

- **準拠標準**: JIS X 8341-3:2016 適合レベル AA（DADS 必須要件）
- **追加対応**: WCAG 2.1 / 2.2 A / AA を順次追加予定
- **コントラスト比**:
  - テキスト（本文・リンク等）: **4.5:1** 以上
  - UI 非テキスト要素（ボタン枠等）: **3:1** 以上
- **色覚多様性**: 色だけで意味を伝えない、形・テキスト・パターンを併用

検証ツール推奨:
- Chrome DevTools の Inspect → Accessibility → Contrast 表示
- `@adobe/leonardo-contrast-colors` 系 CLI
- WebAIM Contrast Checker（手動）

---

## 10. リスクと運用ルール

| リスク | 緩和策 |
|---|---|
| DADS minor/major update でトークン値変動 | 本ファイル冒頭の **取込版 v2.0.1 固定**を維持。半年に 1 回 GitHub releases を確認、breaking change があれば spec-writer 側に **カラー選定 ADR** を起票して移行判断 |
| 各 references / 配布 CSS との HEX drift | **HEX 全量は本ファイルのみ** に書く。他は引用 + 参照リンクに留める（drift 検出は grep ベース） |
| Noto Sans JP CDN 遮断環境 | `BIZ UDPGothic` を Latin 系直後 3 位以内に並べ、fallback chain を担保 |
| Noto Sans Mono の CJK glyph 不足 | `BIZ UDGothic` を mono fallback に残す |

---

## ライセンス・出典

本ファイルが転記する HEX 値・スペック値は以下に由来する:

```
MIT License

Copyright (c) 2023 デジタル庁
```

- **配布**: npm `@digital-go-jp/design-tokens` v2.0.1
- **ソース**: https://github.com/digital-go-jp/design-tokens
- **取込元 JSON**: https://raw.githubusercontent.com/digital-go-jp/design-tokens/main/figma/tokens.json
- **スキーマ**: Design Tokens Community Group format (`$type` / `$value`)
- **取込日**: 2026-06-18
- **取込担当**: spec-writer スキル（旧 spec-design、2026-06-18 改名）

spec-writer が独自に追加した内容（spacing スケール、用途別マッピング、UD fallback 等）はライセンスの再配布対象外（spec-writer 側の判断）。

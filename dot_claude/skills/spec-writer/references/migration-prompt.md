# 移行プロンプト（各プロジェクトで使う起動文）

既存の HTML 補足ページを **spec-writer 最新仕様**（SSOT + 生成時インライン展開型・DADS v2.0.1 準拠）へ移行するとき、対象リポジトリでセッションを開き、以下を貼り付けて使う。

方針・手順の正本:
- **構造方針** (SSOT + インライン展開) → [`html-css-centralization.md`](./html-css-centralization.md)
- **配色・タイポ方針** (DADS v2.0.1 準拠) → [`dads-tokens.md`](./dads-tokens.md) + [`html-css-centralization.md`](./html-css-centralization.md) §共通 CSS の最小骨格

> このプロンプト自体も `data-shared-source` 方針に従い、スキル更新時はここを SSOT として保つ。

## 移行種別の判定

対象リポの状態に応じて 2 種類の移行が独立に発生する。両方必要なら **構造移行（Part A）→ 配色移行（Part B）の順** で実施する。

| 起点 | Part A (構造) | Part B (配色) |
|---|---|---|
| 分散 `<style>` 直書き + 旧 Vercel 配色 | 必要 | 必要 |
| 旧 `<link>` 参照型 + 旧 Vercel 配色 | 必要 (Phase 2 から) | 必要 |
| インライン展開済み + 旧 Vercel 配色 | 不要 | 必要 |
| インライン展開済み + DADS 配色 | 不要 | 不要 (移行済み) |

---

## Part A: 構造移行プロンプト（SSOT + 生成時インライン展開型）

```
仕様書 HTML 補足ページの CSS を「SSOT + 生成時インライン展開型」へ移行して。
方針と手順は ~/.claude/skills/spec-writer/references/html-css-centralization.md
（2026-06-10 再定義版）に従う。配布物は self-contained（HTML 1 ファイル単体で
表示できる）を保つこと。

手順:
1. 対象の洗い出し:
   - リポジトリ内の HTML 補足ページと共通 CSS（_shared/spec-page.css 等）を検出し、
     旧 <link> 参照型 / 分散 <style> 直書き型 / 移行済み（data-shared-source あり）に
     分類して一覧提示。対象 0 件ならそう報告して終了
   - SSOT がまだ無い（分散直書き型のみ）の場合は html-css-centralization.md の
     「段階的移行手順」Phase 1 から、SSOT があるなら Phase 2 から着手

2. 展開スクリプトの導入を優先（HTML 3 本以上 or 更新頻度が高いなら SHOULD）:
   - ~/.claude/skills/spec-writer/references/expand-shared-css.ts をリポジトリの
     scripts/ 配下へコピーし、--ssot / --root をプロジェクト構成に合わせる
   - `npx tsx scripts/expand-shared-css.ts` で全 HTML へ SSOT を一括インライン展開
   - 相対パス（data-shared-source）はスクリプトが階層別に自動算出するので手で書かない
   - スクリプトを入れない場合のみ、下記 3 の手作業防御を厳守する

3. 手作業展開する場合の踏み外し防御（スクリプト未導入時）:
   - 各 HTML の旧 <link rel="stylesheet" href=".../_shared/spec-page.css"> を削除し、
     <style data-shared-source="<SSOT への相対パス>"> へ SSOT の【全文】を展開する
   - 全文は省略・要約・畳み込み禁止。転記後に SSOT と行数・バイト数が一致するか確認
   - data-shared-source の相対パスは HTML の階層ごとに算出（docs/_html/overview.html は
     ../_shared、docs/_html/architecture/context.html は ../../_shared）。固定値を貼らない
   - Google Fonts の <link>（fonts.googleapis.com、preconnect 2 本 + stylesheet 1 本）は
     消さない。削除対象は旧 spec-page.css への <link> だけ
   - 各 HTML の固有 <style> は :root 固有変数のみ（10-30 行）に縮小、<body class="page-X"> 付与

4. self-contained 維持（MUST）:
   - 図は必ずインライン <svg> か data URI。<img src> や外部 .svg 参照、@import、
     ローカル資産の相対参照は入れない（単体配布で壊れる）

5. 検証:
   - 移行後の HTML を 1 つリポジトリ外の一時フォルダへコピーして開き、表示が
     崩れないこと（self-contained）を確認
   - スクリプト導入時は `npx tsx scripts/expand-shared-css.ts --check` で drift 0 を確認。
     可能なら pre-commit / CI に --check を組み込む
   - grep -rl 'data-shared-source' で全対象が移行済み、ローカル CSS への <link> 参照が
     残っていないことを確認

6. プロジェクト側ドキュメント（CLAUDE.md・README 等）に旧 <link> 参照型の記述があれば
   同時更新する

7. 完了したら 1 コミットにまとめる（push はしない）。コミットメッセージに
   「何を・なぜ（HTML 単体配布を可能にするため）」を書く。スクリプトを導入したなら
   それも同コミットに含める
```

---

## Part B: 配色・タイポ移行プロンプト（Vercel inspired → DADS v2.0.1 準拠）

```
仕様書 HTML 補足ページの配色・タイポを spec-writer 最新仕様（DADS v2.0.1 準拠、
key-color = Blue 固定）へ移行して。HEX 全量・タイポ・角丸・影の SSOT は
~/.claude/skills/spec-writer/references/dads-tokens.md。共通 CSS の最小骨格は
~/.claude/skills/spec-writer/references/html-css-centralization.md
「## 共通 CSS の最小骨格」（DADS トークンで全置換済み）。

前提:
- DADS は MIT License (Copyright (c) 2023 デジタル庁) で配布されている公的標準
- spec-writer のデフォルトは key-color = Blue 固定。ベースカラー切替機構（旧
  base-color-mapping.md）は 2026-06-18 廃止
- 配布物は self-contained（HTML 1 ファイル単体で表示できる）を維持

手順:
1. 残存値の洗い出し:
   - 以下を grep で検出して一覧提示（リポ内の HTML / CSS / md 全て）:
     - 旧アクセント色: #0070f3 (Vercel link blue) / #d3e5ff (background) /
       #171717 (ink) / #0761d1 (link-deep) / #4c2889 (Vercel violet)
     - 旧 fonts: 'Inter' / 'JetBrains Mono' / 'Segoe UI'（Latin 先頭指定として）
     - 旧背景: #fafafa (canvas-soft, Vercel) → 新 #ffffff
     - 旧 hero-mesh-gradient セクション（CSS 内）
   - 検出ゼロなら「移行不要」と報告して終了

2. SSOT の置換 (_shared/spec-page.css 等の共通 CSS):
   - html-css-centralization.md「## 共通 CSS の最小骨格」のサンプル CSS を新 SSOT として
     差し替える。:root 変数 / リセット・基本タイポ / a 要素 / pre / header.page / table /
     badge / .tldr / @media print の各セクションが DADS 値で揃っているか確認
   - 主要 DADS 値:
     - --bg: #ffffff (white)
     - --surface: #f2f2f2 (Solid Gray 50)
     - --text: #1a1a1a (Solid Gray 900)
     - --accent: #264af4 (Blue 700, key-color)
     - --accent-deep: #0017c1 (Blue 900, 本文リンク AAA)
     - --accent-bg: #e8f1fe (Blue 50)
     - --font-sans: 'Noto Sans JP', 'BIZ UDPGothic', system-ui, sans-serif
     - --font-mono: 'Noto Sans Mono', ui-monospace, 'BIZ UDGothic', monospace
     - a:visited: #5109ad (Purple 900, AAA)
   - hero-mesh-gradient セクションが残っていたら削除（spec-writer の装飾排除原則と矛盾）

3. 各 HTML の Google Fonts <link> を DADS 採用フォントに更新:
   - 旧: https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Noto+Sans+JP:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap
   - 新: https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&family=Noto+Sans+Mono:wght@400;700&display=swap
   - DADS は font-weight 400 / 700 の 2 段階のみ採用

4. 各 HTML の固有 <style> :root 変数を点検:
   - --feature / --feature-bg などページ固有色も DADS プリミティブから選び直す
     （dads-tokens.md §2 の 10 色族から HEX を引用、出典コメント追記）
   - --accent / --link / --accent-bg が SSOT と一致しているか確認、不要な上書きを削除

5. インライン展開 (Part A 完了後の通常運用):
   - `npx tsx scripts/expand-shared-css.ts` で全 HTML に新 SSOT を再展開
   - スクリプト未導入なら手作業で全 HTML の <style data-shared-source> ブロックを SSOT
     全文で置換（省略・要約・畳み込み禁止、行数・バイト数一致を確認）

6. コントラスト比検証 (DADS / JIS X 8341-3 AA 準拠):
   - Chrome DevTools → Elements → Accessibility → Contrast 表示で本文リンク / badge /
     状態色を点検
   - 本文リンク (Blue 900 on #ffffff) は約 13.7:1 (AAA pass) を確認
   - .badge.accent / .success / .error / .warning が各 4.5:1 以上を確認
   - 失敗があれば dads-tokens.md §1 の用途別マッピングを参照して階調を上げる

7. ライセンス・出典の表記:
   - _shared/spec-page.css の冒頭コメントに以下を追記:
     `/* 配色・タイポトークンは DADS v2.0.1 (MIT, Copyright (c) 2023 デジタル庁) 由来。
        SSOT は ~/.claude/skills/spec-writer/references/dads-tokens.md */`

8. 既存 ADR の確認:
   - docs/architecture/decisions/ や ADR ディレクトリに「Vercel inspired」「ベースカラー」
     関連の Accepted ADR があれば、Superseded に降格 + 新 ADR「カラー選定 (DADS Blue)」を
     起票するか判断。判断材料は adr-format.md「## カラー選定 ADR テンプレ」
   - 単純な Vercel → DADS の置き換えで業種固有事情がなければ ADR 不要

9. プロジェクト側ドキュメントの更新:
   - CLAUDE.md / README 等に「Vercel inspired」「base-color-mapping」言及があれば
     同時更新（DADS 準拠 / dads-tokens.md 参照）

10. 自己検証:
    - grep -rni 'vercel\|\bInter\b\|jetbrains\|#0070f3\|#d3e5ff\|hero-mesh' で残存ゼロを確認
      （変更履歴・git log 参照などの史実記述は残してよい）
    - HTML を 1 つリポ外の一時フォルダへコピーして開き、self-contained 表示が崩れないこと

11. 完了したら 1 コミットにまとめる（push はしない）。コミットメッセージ例:
    `refactor(docs): migrate HTML supplementary pages CSS from Vercel to DADS v2.0.1`
    本文に「何を・なぜ（DADS は公的標準 + JIS X 8341-3 AA 自動充足）」を書く
```

---

## 他リポへの横展開（再利用方法）

本プロンプトは spec-writer スキルの一部として配布されているので、各リポでセッションを開いて以下を投げるだけで再利用できる:

1. `/spec-writer` を起動（または自然文で「DADS 移行をやって」）
2. 「`~/.claude/skills/spec-writer/references/migration-prompt.md` の Part A / Part B を実施して」と指示
3. エージェントが上記手順を順番に進める

リポごとの注意点:
- **大規模リポ（HTML が 10 本以上）**: Part A の展開スクリプト導入を必須化（手作業転記の事故防止）。CI に `--check` を組み込んで drift を防ぐ
- **ブランド要請がある場合**: Part B の Step 2 で `--accent` を DADS Blue 以外（Light Blue / Cyan / Green 等）に差し替え、Step 8 で必ず ADR「カラー選定 (DADS xxx)」を起票
- **既存 ADR との整合**: Part B の Step 8 で Superseded 降格を必ず判断する

実証済リポ: **yoroi** (2026-06-18、commit ハッシュは作業ログ参照)。yoroi での実証手順・所要時間・落とし穴は context.md「進行中の作業」セクションに記録。

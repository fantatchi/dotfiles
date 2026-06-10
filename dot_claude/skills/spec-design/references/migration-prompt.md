# 移行プロンプト（各プロジェクトで使う起動文）

既存の HTML 補足ページを「SSOT + 生成時インライン展開型」へ移行するとき、対象リポジトリで
セッションを開き、以下を貼り付けて使う。方針・手順の正本は [`html-css-centralization.md`](./html-css-centralization.md)。

> このプロンプト自体も `data-shared-source` 方針に従い、スキル更新時はここを SSOT として保つ。

## 起動プロンプト

```
仕様書 HTML 補足ページの CSS を「SSOT + 生成時インライン展開型」へ移行して。
方針と手順は ~/.claude/skills/spec-design/references/html-css-centralization.md
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
   - ~/.claude/skills/spec-design/references/expand-shared-css.ts をリポジトリの
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

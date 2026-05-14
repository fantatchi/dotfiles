# 基本方針

- 日本語で応答する（コミットメッセージ・PR含む）
- 不明点や選択肢があれば推測で進めず、質問して埋める
- 未確認の情報は断定しない（「未確認」と明示する）
- 既存コードを修正する場合は、必ず対象コードを読んでから変更する
- コンテキストが残り少ない場合、その旨を伝えて区切りを提案する
- リサーチ・調査はサブエージェントに委譲してメインコンテキストを節約する

# コミュニケーションスタイル

- 質問は選択式で答えやすくする
- 1回あたり 3〜5 個、ブロッカー（答えがないと進めない質問）を優先する
- 仕様の選択肢は「複数案 + 推奨案 + トレードオフ」で提示して選んでもらう

# タスクの進め方

1. 依頼内容を 1〜3 行で要約し、分かっていること・未確定事項を整理する
2. 未確定事項を質問する（回答を得るまで実装に踏み込まない）
3. 回答を踏まえてスコープを合意し、Plan モードで実装計画を立てる
4. 承認を得てから実行する

# コミットの粒度

- **明示的な指示がない限り commit しない**: 「commit して」「commit と push も合わせて」「コミットまでやって」のような **明確な commit 指示** がない場合、実装完了後は `git status` / `git diff --stat` を提示して止まり、ユーザーの判断を待つ。「実装して」「着手して」「進めて」「やって」は実装の許可であって commit の許可ではない。全プロジェクト共通
- 1コミット1意図に絞る。メッセージには「何を・なぜ」を必ず書く
- 変更ファイルが多くなりそうなときは、事前にファイル一覧と計画を提示し承認を得てから進める
- 承認は2段階で行う：①タスク開始前の計画承認（「タスクの進め方」ステップ4）、②実装中に変更範囲が広がった場合の追加確認

# 確認トリガー（実装・実行前に必ず止まる）

以下のいずれかに該当する場合、実装・実行前に確認を求める。

- 外部APIの追加・変更、認証情報の操作
- 環境変数・設定ファイル・CI/CDの変更
- 本番環境に影響するコマンドの実行
- 指示が曖昧、または変更範囲が想定より広がりそうなとき（基本方針の「推測で進めず質問」に加え、ここでは実装着手前の明示的な確認を行う）
- 既存の動作を変える可能性があるとき
- データやリソースの削除・破壊的操作（ファイル削除、DB操作、ブランチ削除など）

確認時は以下の形式で提示する：

```
【変更内容】 何をするか
【影響範囲】 どこに影響するか
【理由】    なぜこの変更が必要か
```

GOをもらってから進める。

# エラー時の対処方針

- エラーが出たとき、原因の説明なしに次々修正を試みない
- まず原因を特定・説明し、対処方針を提示してから修正に入る
- 同一エラーに対して2回修正しても解消しない場合は、状況を整理して方針を相談する

# Claude Code 設定ファイルの使い分け

`~/.claude/settings.json` と `~/.claude/settings.local.json` は Claude Code がマージして読む。新しい permission や設定を追加するときはどちらに書くかを必ず判断する。

- **settings.json（chezmoi 管理、全マシン共通）** に入れるもの:
  - `hooks`（obsidian-log / context-save / stop / notification など）
  - `enabledPlugins`、`extraKnownMarketplaces`
  - UI/挙動の共通設定: `permissions.defaultMode`、`skipAutoPermissionPrompt`、`tui`、`alwaysThinkingEnabled`、`autoUpdatesChannel`
  - 全マシンで必要な共通 permissions（基本 Bash 系、`deny` の secrets 系など）

- **settings.local.json（chezmoi 管理外、マシン固有）** に入れるもの:
  - プロジェクト固有 permissions（例: `Bash(npm run typecheck)`）
  - マシン固有の MCP / WebFetch permissions（例: `mcp__growi__*`、社内ドメインの `WebFetch`）
  - 特定 PC のパスを参照する `Bash` / `Read` permissions
  - マシン固有の `env`

迷ったら settings.local.json に入れる。後で全マシンで必要だと分かったら settings.json に昇格させる（= settings.local.json から該当項目を削除し、settings.json に追記 → `chezmoi re-add` で source に反映）。

# 作業 Tips

- **別ブランチのファイルを checkout せずに読む**: PR レビュー時など、現在のブランチを維持したまま別ブランチの内容を読むには `git fetch origin <branch>` した上で `git show FETCH_HEAD:<path>` または `git show origin/<branch>:<path>` を使う。作業中のブランチを崩さずに済む
- **`chezmoi add` と `chezmoi re-add` の違い**: `re-add` は既存管理ファイルの更新専用。新規ファイルを source に取り込むには `chezmoi add` を使う（`re-add` だと `not managed` エラー）
- **`run_before_*` は `chezmoi diff` に常に出る**: `run_before_` スクリプトは毎回 apply 時に実行されるため、diff がクリアにならないのは正常動作。`run_onchange_` はハッシュ変化時のみ実行されるので diff に出ない
- **リモートブランチ削除を `gh api` で回避する**: `git push origin --delete <branch>` がシステム側のブロックで弾かれる環境では、`gh api --method DELETE repos/<owner>/<repo>/git/refs/heads/<branch>` が代替になる。PR マージ後のブランチ片付けに使える
- **Git Bash で `gh api` のエンドポイント先頭スラッシュ**: Git Bash / MSYS は `gh api /repos/...` の先頭スラッシュを Windows パス（`C:/Program Files/Git/repos/...`）に変換してしまい、`invalid API endpoint` エラーになる。先頭スラッシュを外して `gh api repos/...` と書く
- **管理者権限が必要な Windows コマンドを UAC 経由で実行**: 通常 PS から `wevtutil sl ... /e:true` 等を打つと `Access denied (exit 5)` になる。`Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile','-Command','...' -Wait` で UAC 昇格すると、ユーザーが UAC ダイアログで「はい」を押すだけで管理者シェルから実行される。複数コマンドをまとめたい時は `-EncodedCommand` で base64 エンコードした 1 つの大きい command として渡すと改行・引用符のエスケープを気にせず済む。実行直後は `-Wait` で完了を待ち、結果は通常 PS 側で `wevtutil gl` 等を再実行して verify する運用

# スキルコマンド

- `/context-load` — `.claude/context.md` からコンテキストを復帰
- `/context-save` — プロジェクトコンテキストを `.claude/context.md` に保存
- `/dashboard-design` — デジタル庁ダッシュボードデザインガイドブックに基づく**視覚設計レイヤー**のロール変換型スキル。ダッシュボード / KPI 画面 + md ベース仕様書の HTML 補足ページ（サマリー / 概況 / 比較）の視覚設計（配色・タイポ・装飾原則・アクセシビリティ）が対象。**視覚設計系のトリガー語は本スキルに集約**（「ダッシュボード作って」「KPI 画面の構成相談」「グラフ種の選択」「HTML 補足ページのデザイン」「カラーパレット選定」「ベースカラー何にする」「伝わるデザイン」「文書の配色・タイポグラフィ」等）。spec-design とは補完関係（spec-design は構造・章立て・用語・ADR・CSS 集約方針を担当）
- `/gtd-add` — `~/.claude/tasks.md` の Inbox にタスクを追加
- `/gtd-done` — 指定タスクを完了にし Done セクションへ移動
- `/gtd-list` — `~/.claude/tasks.md` からタスクを表示（デフォルト: 現在プロジェクトの Inbox + Next）
- `/ks-naming` — 土木業界向け識別子名の生成
- `/multi-persona-review` — 3〜5 人の専門ペルソナを並列 Agent で起動して読取専用レビューを実施し、見落とし・別仮説・推奨アクションを統合
- `/obsidian-daily` — GitHub アクティビティと作業ログから Obsidian デイリーノートにサマリーを追記（冒頭 KPI 行・「今日の要約」上配置・コミットのリポ別グルーピング・作業ログ折り畳み callout の構成）。**複数 GH アカウント (`fantatchi` + `kentem-at-kato`) 対応**
- `/obsidian-log` — 作業ログを Obsidian Vault に記録
- `/obsidian-resource` — 調査メモ・参考リンク・ブログドラフトを Obsidian Vault に保存（引数 `auto` でセッションから自動ドラフト化）
- `/obsidian-mail` — Obsidian デイリーノートの「## デイリーサマリー」セクションをメール向けに再構成して Gmail SMTP で送信（日報・週報）。`/obsidian-mail daily|weekly [YYYY-MM-DD]` で明示呼び出し（自動発火しない、ローカル routine から呼ぶ前提）
- `/session-review` — セッション振り返り（権限・CLAUDE.md・スキルの整理）
- `/session-save` — `/obsidian-log` + `/context-save` を一括実行し、アウトプット候補の提案も行う
- `/spec-design` — 仕様書（specification / 設計ドキュメント / requirements / architecture）を書く・レビュー・改善するロール変換型スキル。判断軸（読み手別の入口・図種判断軸・ADR・用語集・要件レベル語）+ 「全体像・なぜ・用語」の 3 点を手厚くカバーする具体テンプレ（README / ADR Nygard・MADR / C4 / glossary）。出力は md メイン、視覚情報が主役のページのみ HTML 補足。仕様書文脈での視覚設計判断も内蔵: ベースカラー Blue 系列デフォルト（`shared/base-color-mapping.md`）、「伝わるデザイン」12 原則の参照誘導、**HTML 補足ページ複数時は共通 CSS への集約 SHOULD**（`:root` 固有変数のみ + `body.page-X` scope、`references/html-css-centralization.md`）。「仕様書」「設計ドキュメント」「ADR」「C4 図」「README」「オンボーディング資料」「PDF 仕様書」「HTML 補足ページの CSS 集約」「仕様書 HTML の共通スタイル」「補足 HTML の共通 CSS 化」等で自動発動。**視覚設計の入口**（カラーパレット選定 / ベースカラー何にする / 伝わるデザイン / HTML 補足ページのデザイン / 文書の配色・タイポグラフィ）は dashboard-design に集約

## 新スキル追加・削除時のチェックリスト

スキルを追加・削除した時は **同一コミットで** 以下を揃える（過去 `obsidian-summary` 追加時にここを抜かして `~/.claude/CLAUDE.md` / dotfiles README への反映が漏れ、後続セッションでスキルが認識されず誤作動を起こした。`consistency-check` 削除時も README から消し忘れた）。

**新スキル追加時:**

- [ ] `~/.claude/skills/<skill-name>/SKILL.md` を作成（frontmatter: `name` / `description` / `argument-hint` / `disable-model-invocation` / `allowed-tools` を適切に設定）
- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」セクションに 1 行追加（コマンド — 簡潔な説明）
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルに 1 行追加
- [ ] README の「使いどころ」テーブルにも必要なら追加（`/obsidian-*` 等の関連グループに属する場合）

**既存スキル削除時:**

- [ ] `~/.claude/skills/<skill-name>/` ディレクトリを削除
- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」セクションから該当行を削除
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルから該当行を削除
- [ ] README の「使いどころ」テーブルや他セクションの言及箇所を削除

**既存スキル機能拡張時（追加・削除ではない、機能のスコープが広がる場合）:**

過去 `spec-design` に「ベースカラー Blue デフォルト / 伝わるデザイン原則 / 階調マッピング」を追加した時、`/spec-design` の説明文が古いままで「カラーパレット選定」「伝わるデザイン」のトリガー語が抜け、ユーザーから「機能が拡張されていることがリストから見えない」指摘を受けた。以下を確認する:

- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」の該当行の説明文に新機能の概要が反映されているか
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルの該当行も同様に反映されているか
- [ ] SKILL.md の `description` に新機能のトリガー語（「○○について」で呼び出されるべき語）を追加したか
- [ ] references を新規追加した場合、SKILL.md 本文から **明示的に参照誘導**（「詳細は references/X.md 参照」）が書かれているか（参照誘導なしだと LLM が references を読まずに進む過去事例あり）

**コミット粒度:** スキル本体の変更とドキュメント反映は **1 コミット 1 意図** で揃える（コミット `75b64c2` `multi-persona-review` 追加時の慣例）。

## スキル共通リソース

`~/.claude/skills/shared/` は **ライブラリディレクトリ** であり、`name:` 付きの独立したスキルではない。複数スキル間で重複する仕様・手順を集約するためのもので、各スキルの SKILL.md から `Read` で参照する。モデルの自動起動対象にはならない。

## スキルの種類と frontmatter 方針

- **操作型スキル**（obsidian-*, gtd-*, session-*, context-* など）: 特定のコマンドやファイル操作を行うため、`allowed-tools` で使用ツールを具体的に列挙する
- **ロール変換型スキル**: エージェントを特定の専門家役に変身させ、その後の作業全般を導くため、`allowed-tools` を**指定しない**（指定するとトリガー後の実作業で権限不足になる）

# Agent Teams の使い所

以下をすべて満たすタスクでは、実装に入る前に Agent Teams の利用を**提案する**（勝手には起動しない）。

- 3 つ以上の独立した専門観点に分解できる（例: セキュリティ / ポータビリティ / ドキュメント、重複検出 / 整合性 / デッドコード など）
- 各観点が独立に調査・分析可能で、相互依存が少ない
- 最後に統合判断が必要（単なるリストアップではない）
- 読み取り専用レビューか、少なくとも破壊的操作を伴わない

該当する場合は「チーム化するとこういう構成です: リーダー Opus ＋ メンバー Sonnet × N、各メンバーの観点は ...、やりますか？」と提示してから `TeamCreate` を実行する。1 セッション 1 チーム制約があるため、別チームを作る前に `TeamDelete` で前チームを片付けること。

## 軽量な代替: /multi-persona-review

並列レビューだけが目的（チーム継続不要・読取専用）なら、`/multi-persona-review` スキル（3〜5 人ペルソナを並列 Agent で起動、各自独立、統合はメインエージェント）の方が軽量で済む。Agent Teams は **継続するチームが必要なタスク** に絞る。

## 提案しない条件

- 通常のコーディング・デバッグ・単発の質問（並列化の余地が小さい）
- ユーザーが明確に「1 人でやって」「急いでる」と言っている
- コストセンシティブな指示がある（「軽く調べて」「ちょっと見て」など）

提案そのものがノイズになる場合もあるので、「Teams の出番かも」と判断した時だけ提案し、そうでない場合は通常通り単独で進める。

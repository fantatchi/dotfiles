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

# 日本語表記ルール

ドキュメント・コミットメッセージ・コメントなど、ユーザーが読む日本語テキスト全般に適用する。

- **「プロジェクト」は `Pjt` で略さない**。フル表記「プロジェクト」が原則、文字数を切り詰めたいときのみ `Pj`
- **節（section）参照は `N 節` / `N-M 節`**（例: `4 節`、`8-3 節`）。`§` のようなフォント依存しやすい ASCII 特殊記号（`‡` / `¶` / `‰` 等含む）は避ける

# タスクの進め方

1. 依頼内容を 1〜3 行で要約し、分かっていること・未確定事項を整理する
2. 未確定事項を質問する（回答を得るまで実装に踏み込まない）
3. 回答を踏まえてスコープを合意し、Plan モードで実装計画を立てる
4. 承認を得てから実行する

# コミットの粒度

- **明示的な commit 指示がない限り commit しない**: 「実装して」「進めて」等は実装の許可であって commit の許可ではない。実装完了後は `git status` / `git diff --stat` を提示して止まり、ユーザー判断を待つ。全プロジェクト共通
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
- `/dashboard-design` — デジタル庁ガイドブック準拠の視覚設計レイヤー（配色・タイポ・チャート選択・アクセシビリティ）。視覚設計系トリガー語（ダッシュボード / KPI / グラフ種 / カラーパレット / 伝わるデザイン / HTML 補足ページのデザイン等）はここに集約。spec-design とは補完関係
- `/gtd-add` — `~/.claude/tasks.md` の Inbox にタスクを追加
- `/gtd-done` — 指定タスクを完了にし Done セクションへ移動
- `/gtd-list` — `~/.claude/tasks.md` からタスクを表示（デフォルト: 現在プロジェクトの Inbox + Next）
- `/ks-naming` — 土木業界向け識別子名の生成
- `/multi-persona-review` — 3〜5 人の専門ペルソナを並列 Agent で起動して読取専用レビューを実施し、見落とし・別仮説・推奨アクションを統合
- `/obsidian-daily` — GitHub アクティビティと作業ログから Obsidian デイリーノートにサマリーを追記。**複数 GH アカウント (`fantatchi` + `kentem-at-kato`) 対応**
- `/obsidian-log` — 作業ログを Obsidian Vault に記録
- `/obsidian-resource` — 調査メモ・参考リンク・ブログドラフトを Obsidian Vault に保存（引数 `auto` でセッションから自動ドラフト化）
- `/obsidian-mail` — Obsidian デイリーノートのサマリーをメール向けに再構成して Gmail SMTP で送信（日報・週報、ローカル routine から呼ぶ前提）
- `/session-review` — セッション振り返り（権限・CLAUDE.md・スキルの整理）
- `/session-save` — `/obsidian-log` + `/context-save` を一括実行し、アウトプット候補の提案も行う
- `/spec-design` — 仕様書・設計ドキュメント・ADR・C4 図・README 等の作成/レビュー/改善を担うロール変換型スキル。視覚設計が主役の入口は `/dashboard-design` 側に集約

## 新スキルの追加・削除・拡張

スキルの新規追加・削除・機能拡張時の手順とチェックリスト、共通リソース（`shared/`）、frontmatter 方針（操作型 vs ロール変換型）は [`~/.claude/docs/skill-management.md`](docs/skill-management.md) を参照。

# Agent Teams の使い所

「3 つ以上の独立した専門観点に分解」+「相互依存が少なく独立調査可能」+「統合判断必要」+「読取専用 or 非破壊」を**すべて満たす**タスクのみ、`TeamCreate` を提案（勝手には起動しない）。1 セッション 1 チーム制約あり、別チーム作る前に `TeamDelete`。

並列レビューだけが目的なら `/multi-persona-review` の方が軽量で済む（チーム継続不要・読取専用）。通常のコーディング・デバッグ・単発質問では提案しない。

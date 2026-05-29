# 基本方針

- 日本語で応答する（コミットメッセージ・PR含む）
- 不明点や選択肢があれば推測で進めず、質問して埋める
- 未確認の情報は断定しない（「未確認」と明示する）
- 既存コードを修正する場合は、必ず対象コードを読んでから変更する
- コンテキストが残り少ない場合、その旨を伝えて区切りを提案する
- リサーチ・調査はサブエージェントに委譲してメインコンテキストを節約する
- 動作する最小限の実装から始め、段階的に拡張する

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

# コミット・プッシュの粒度

- **commit は自律で進めてよい**: 実装完了後にそのまま commit してよい。「実装して」「進めて」等の指示には commit までを含む。全プロジェクト共通
- **push は明示指示が必要**: 「push して」「push まで」「commit と push を合わせて」等の **明示的な push 指示** がない限り push しない。リモートは共有 state を変える操作なので必ず止まる
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

# 禁止パターン（コード実装・設定ファイル記述時）

以下は実装時に絶対に行わない。違反しそうになったら踏みとどまり、「# 確認トリガー」に従ってユーザーに相談する。

「# 確認トリガー」が **操作の実行可否レベル**（実行前に止まる）を扱うのに対し、こちらは **コード・ノート・コミットメッセージなどに書く内容レベル**（書かない）を扱う。

- **環境変数値を出力・記録しない**: `console.log(process.env)` / `printenv` 出力をそのまま貼り付け / Obsidian ノート・コミットメッセージへの埋め込みは禁止。デバッグ時はキー名のみ言及する
- **認証情報をソースコードにハードコードしない**: API key / token / password は `.env` に分離（`~/.claude/settings.json` の `permissions.deny` で `Read(**/.env*)` ブロック済の前提）。サンプル値が必要なときは `<YOUR_API_KEY>` のようなプレースホルダにする
- **個人情報をログ・テストデータ・ノートに埋め込まない**: メールアドレス / 電話番号 / 口座情報 / 医療データ等。テスト用ダミーは `user1@example.com` 等の予約ドメインを使う
- **破壊的 SQL の具体パターンを無確認実行しない**: `DELETE FROM ...`（WHERE 句なし） / `DROP TABLE` / `TRUNCATE` はステージング検証 → ユーザー確認の順で進める（「# 確認トリガー」と接続）
- **`NODE_ENV=production` 切替を無確認で行わない**: 本番判定切替・本番向け命令はユーザー確認必須
- **HTTP 認証情報を生埋め込みしない**: `Authorization: Basic <base64>` ヘッダや `https://user:pass@host/` 形式の URL をコード内にリテラル記述しない。環境変数経由で読む
- **API key / アプリパスワードを会話・履歴に貼らない**: `~/.claude/projects/*/history.jsonl` に残留する。ユーザー自身に `~/.claude/settings.local.json` 等へ直接書いてもらう運用（過去判断メモ準拠）

# エラー時の対処方針

- エラーが出たとき、原因の説明なしに次々修正を試みない
- まず原因を特定・説明し、対処方針を提示してから修正に入る
- 同一エラーに対して2回修正しても解消しない場合は、状況を整理して方針を相談する

# コード品質基準

- 責務分離・依存方向・置換可能性などの設計原則（OOP では SOLID）を意識する
- 関数は 50 行以内を目安にする
- ネストは 3 階層以内に抑える（早期リターン・ガード節を活用）
- 上記の行数・ネスト深さは機械的な上限ではなく、超えたら分割を検討するサイン
- マジックナンバーは定数化して意味を明示する
- DRY: 重複は共通化する
- 型は**公開 API・関数シグネチャ・モジュール境界では明示**する。内部の局所変数は言語慣習に従う（TS / C# の `var`・`const` 推論など）
- トリッキーな実装より平易で理解しやすいコードを優先する

# コメント・ドキュメント

- **公開 API**（外部から利用される関数・型・モジュール境界）には doc を書く（目的・責務・パラメータ・戻り値・例外、複雑なら使用例）。自明な内部ヘルパ・単純な DTO プロパティは省略可
- 複雑なアルゴリズム・ビジネスロジックは事前にコメントで説明する
- TODO / FIXME で既知の課題を明示する
- 「何をしているか」ではなく「なぜそうしているか」を書く

# 既存スタイルの踏襲

- 同じディレクトリ・モジュールの実装スタイルを確認してから書く
- 既存スタイルに合わせるのが基本。ただしセキュリティ・パフォーマンス・保守性で明らかに問題があれば改善案を提示する
- 改善提案の伝え方:
  - 「周辺は 〇〇 のパターンですが、△△ の理由で □□ を提案します」
  - 「既存に合わせますか？それとも 〇〇 の観点でこちらにしますか？」と選択肢で出す
- プロジェクト固有規約は最優先、不明点は確認する

# 命名規則

- 省略形は避ける（HTTP / URL / ID など広く認知された略語は除く）
- スコープが広いほど詳細な名前にする
- boolean は `is` / `has` / `can` などの接頭辞を付ける
- ファイル / クラス / メソッド / 変数のケース指定は **言語・プロジェクト固有の慣習を優先**（具体は各 repo の CLAUDE.md で定義）

# レビュー時の Prefix

レビュー（コードレビュー、PR レビュー）の指摘コメントには重要度 Prefix を必ず付ける。

| Prefix | 意味 |
|---|---|
| **CRITICAL:** | セキュリティリスク、データ損失、本番障害につながる致命的な問題 |
| **HIGH:** | 機能不全、パフォーマンス重大問題、設計上の大きな問題 |
| **MIDDLE:** | 保守性の問題、潜在的バグ、ベストプラクティス違反、ドキュメント欠如 |
| **LOW:** | コードスタイル、軽微な改善提案、推奨事項 |

例:

```
CRITICAL: SQL インジェクションの脆弱性があります。パラメータ化クエリを使用してください。
LOW: 変数名 `d` を `deliveryDate` に変えると可読性が上がります。
```

# Claude Code 設定ファイルの使い分け

`~/.claude/settings.json` と `~/.claude/settings.local.json` は Claude Code がマージして読む。新しい permission や設定を追加するときはどちらに書くかを必ず判断する。

- **settings.json（chezmoi 管理、全マシン共通）** に入れるもの:
  - `hooks`（context-save / claude-md-audit-reminder / notification など）
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

- `/context-load` — `.claude/context.md` からコンテキストを復帰し、`tasks.md` の該当プロジェクト Next / Waiting も併せて提示
- `/context-save` — プロジェクトコンテキストを `.claude/context.md` に保存。`## 進行中の作業` は日付プレフィックス付き entry で記録し 14 日でローテーション。セッションで生まれた次アクションを `tasks.md` の `## Next` に吸い上げ、`.claude/progress.md` があれば更新する
- `/dashboard-design` — デジタル庁ガイドブック準拠の視覚設計レイヤー（配色・タイポ・チャート選択・アクセシビリティ）。視覚設計系トリガー語（ダッシュボード / KPI / グラフ種 / カラーパレット / 伝わるデザイン / HTML 補足ページのデザイン等）はここに集約。spec-design とは補完関係
- `/gtd-add` — `~/ObsidianVault/00_meta/tasks.md` の Inbox にタスクを追加（Obsidian Sync で全 PC 共通）
- `/gtd-done` — 指定タスクを完了にし Done セクションへ移動
- `/gtd-list` — `~/ObsidianVault/00_meta/tasks.md` からタスクを表示（デフォルト: 現在プロジェクトの Inbox + Next）
- `/ks-naming` — 土木業界向け識別子名の生成
- `/multi-persona-review` — 3〜5 人の専門ペルソナを並列 Agent で起動して読取専用レビューを実施し、見落とし・別仮説・推奨アクションを統合
- `/obsidian-daily` — GitHub アクティビティと作業ログから Obsidian デイリーノートにサマリーを追記。**複数 GH アカウント (`fantatchi` + `kentem-at-kato`) 対応**。Obsidian Core Daily notes テンプレ (`90_config/templates/daily_notes.md`) を SSOT として動的読み込み、Thino プラグインとの共存を考慮した `# Journal` セクション前提
- `/obsidian-log` — 作業ログを Obsidian Vault に記録
- `/obsidian-resource` — 調査メモ・参考リンク・記事ドラフトを Obsidian Vault `30_resource/YYYYMM/` 配下に保存（引数 `auto` でセッションから自動ドラフト化）
- `/obsidian-mail` — Obsidian デイリーノートのサマリーをメール向けに再構成して Gmail SMTP で送信（日報・週報、ローカル routine から呼ぶ前提）
- `/session-review` — セッション振り返り（権限・CLAUDE.md・スキルの整理）
- `/session-save` — `/obsidian-log` + `/context-save` を一括実行し、アウトプット候補の提案も行う
- `/spec-design` — 仕様書・設計ドキュメント・ADR・C4 図・README 等の作成/レビュー/改善を担うロール変換型スキル。視覚設計が主役の入口は `/dashboard-design` 側に集約

## 新スキルの追加・削除・拡張

スキルの新規追加・削除・機能拡張時の手順とチェックリスト、共通リソース（`shared/`）、frontmatter 方針（操作型 vs ロール変換型）は [`~/.claude/docs/skill-management.md`](docs/skill-management.md) を参照。

# Agent Teams の使い所

「3 つ以上の独立した専門観点に分解」+「相互依存が少なく独立調査可能」+「統合判断必要」+「読取専用 or 非破壊」を**すべて満たす**タスクのみ、`TeamCreate` を提案（勝手には起動しない）。1 セッション 1 チーム制約あり、別チーム作る前に `TeamDelete`。

並列レビューだけが目的なら `/multi-persona-review` の方が軽量で済む（チーム継続不要・読取専用）。通常のコーディング・デバッグ・単発質問では提案しない。

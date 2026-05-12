---
name: obsidian-mail
description: Obsidian デイリーノートの「## デイリーサマリー」セクションをメール向けに再構成して Gmail SMTP で送信する。日報・週報 2 モード。**自動発火しない設計**（`disable-model-invocation: true`）のため、Claude.app ローカルルーティーンまたは `/obsidian-mail daily|weekly [YYYY-MM-DD]` の明示呼び出しが必要。利用シーン: 日報メール送信、週報メール送信、サマリーをメールで配信（「日報メールして」「週報メール送って」「サマリーをメールで」等の依頼で想起）。
argument-hint: daily|weekly [YYYY-MM-DD]
disable-model-invocation: true
allowed-tools: Read, Bash(date:*), Bash(python3:*), Bash(ls:*), Bash(test:*), Bash(printenv:*)
---

# obsidian-mail — デイリーサマリーをメール送信

Obsidian デイリーノートの「## デイリーサマリー」セクションを **構造化パース → メール向けに再構成**して Gmail SMTP で送信する。Obsidian ノート形式をそのまま流すのではなく、「今日のひとこと → ハイライト → GitHub → 明日のタスク」の読み物形式にする。

## 引数仕様

```
$ARGUMENTS:
  daily              → 昨日の日報を送信（routine 用デフォルト）
  daily YYYY-MM-DD   → 指定日の日報を送信（手動再送）
  weekly             → 直前の月曜を含む週の週報を送信（routine 用デフォルト）
  weekly YYYY-MM-DD  → 指定日を含む週（月〜日）の週報を送信（手動再送）
```

## 前提セットアップ（初回のみユーザー操作）

### 1. Gmail アプリパスワードの取得

1. https://myaccount.google.com/security で **2 段階認証プロセス**が有効であることを確認
2. https://myaccount.google.com/apppasswords にアクセス
3. アプリ名: `obsidian-mail` 等の任意名 → 「作成」
4. 表示された 16 文字のパスワード（スペースなし）を控える

### 2. ~/.claude/settings.local.json への env 設定

`settings.local.json` の `env` セクションに以下を追加（chezmoi 非管理＝マシンローカル）:

```json
{
  "env": {
    "OBSIDIAN_SUMMARY_SMTP_USER": "fantatchi@gmail.com",
    "OBSIDIAN_SUMMARY_SMTP_PASS": "xxxxxxxxxxxxxxxx"
  }
}
```

オプション:
- `OBSIDIAN_SUMMARY_MAIL_TO`: 送信先アドレス（デフォルト: `SMTP_USER` と同じ）
- `OBSIDIAN_SUMMARY_MAIL_FROM`: 送信元アドレス（デフォルト: `SMTP_USER` と同じ）

> **env 変数名の命名について（重要）**: スキル名は `obsidian-mail` だが env 変数 prefix は `OBSIDIAN_SUMMARY_*` のまま据置している。これは旧スキル名 `obsidian-summary` 時代の命名で、settings.local.json が chezmoi 非管理（各マシンで個別設定）のため、リネームに合わせて env 名も変えると **全マシンで既存値の再設定が必要** になる移行コストを避けるための backward compat 措置。新規セットアップでも `OBSIDIAN_SUMMARY_*` で設定すること。将来統一する場合は send-summary.py 側で新旧両方の名前を check → 旧名を deprecated 扱いに、という段階移行が必要。

### 3. Python 依存

`markdown` ライブラリが必要（`pip3 install --user markdown`）。

## 動作

### 1. 引数解析と対象日決定

- 1 トークン目: `daily` / `weekly` 以外なら **エラー終了**（使い方を案内）
- 2 トークン目（日付）:
  - 省略時:
    - `daily` → `date -d 'yesterday' +%Y-%m-%d`（routine が翌朝に動く前提）
    - `weekly` → `date -d 'last monday' +%Y-%m-%d`（routine が月曜朝に動く前提で、その時点での「先週月曜」を渡す）
  - 指定時: `YYYY-MM-DD` 形式バリデーション。不正なら エラー終了

### 2. 送信スクリプト実行

```bash
python3 ~/.claude/skills/obsidian-mail/send-summary.py "$MODE" "$TARGET_DATE"
```

`send-summary.py` は内部で:

1. `extract-summary.py` を呼んでサマリーを抽出 → 構造化パース → メール向けに再構成（plain Markdown + HTML 両方生成）
2. `empty: true` の場合: 送信せず `{"sent": false, "reason": "empty"}` を返す
3. それ以外: multipart/alternative メッセージを構築 → `smtp.gmail.com:465`（SSL）でログイン → 送信
4. 結果 JSON を stdout に出力

### 2-b. メール本文の構成（再構成ロジック）

`extract-summary.py` は「## デイリーサマリー」セクションを以下の規約セクションに分解してパースし、メール向けに再構成する:

| 入力（規約セクション） | 出力（メール） |
|---|---|
| `> [!info] 自動生成` callout | **除去**（メタ情報、内部リンク `[[...]]` も除去） |
| `### 今日の要約` | `## 今日のひとこと`（青ボックス `.tldr`、複数段落なら最初の 1 段落のみ） |
| `### 作業ログ` の `- **project**: body` bullet | `## ハイライト` — 各 bullet を 1 行に圧縮（body の最初の句のみ） |
| `### GitHub アクティビティ` の `#### コミット` / `#### PR` | `## GitHub` — 集計行（コミット N / PR M（作成 X, マージ Y, レビュー Z））+ PR リンク一覧 |
| `### 明日以降のタスク` の `- [ ] #project body` | `## 明日のタスク` — 件数 + プロジェクト別内訳 + 抜粋 5 件 + `…ほか N 件` + `_待ち N 件は省略_` |

### 2-c. 規約縛り（手書き追加コンテンツは静かに捨てる）

このスキルは **obsidian-daily が出力する規約フォーマット** に依存する。以下は意図的に捨てる:

- `## デイリーサマリー` セクションの **外** にあるもの（先頭の手書きメモ、別 h2 セクション）
- `## デイリーサマリー` 内の **規約 4 セクション以外の `### xxx`**（手書きで追加した雑記など）
- `### 作業ログ` 内の `- **project**: body` 形式以外の bullet
- `### 明日以降のタスク` 内の `- [ ] #project body` 形式以外の bullet
- `### GitHub アクティビティ` 内の `#### コミット` / `#### PR` 以外の小見出し

手書きで追加した情報をメールに届けたい場合は Obsidian で直接見るか、本スキルの拡張（未参照セクションを「その他」として末尾追加）を検討する。

### 3. 「対象なし」スキップ判定

`{"sent": false, "reason": "empty"}` が返った場合:

- **routine 起動時（引数で日付が省略された場合）** → 「サマリー未生成のためスキップ」と 1 行報告して正常終了
- **手動起動時（日付が指定された場合）** → 「対象が見つからない。再生成が必要なら `/obsidian-daily YYYY-MM-DD` を実行してください」と案内

### 4. 完了報告

`{"sent": true, ...}` が返ったら以下を 1〜3 行で報告:

```
✓ 送信完了
  件名: <subject>
  宛先: <to>
  対象: <available_dates の件数>/<期待件数> 日分
  欠落: <missing_dates>（あれば）
```

### 5. 週報の構成

`weekly` モードは各日の構造化パース結果を **プロジェクト軸で集約** する（日別の縦並びは取らない）:

```
# YYYY-MM-DD 〜 YYYY-MM-DD 週報

取得済み: N/7 日分（欠落: ...）

## 週次集計
- 動いたプロジェクト: N
- GitHub: コミット N / PR M
- 明日タスク累計: N 件

## プロジェクト別ハイライト

### {プロジェクト名} · N 件
- [MM-DD] worklog の最初の句
- [MM-DD] ...
- …ほか N 件（1 プロジェクト最大 3 件表示、残りは件数のみ）
```

プロジェクトの並び順は活動件数の多い順 → アルファベット。各プロジェクトの bullet は worklog の `- **proj**: body` を `first_sentence(body)` で 1 行に圧縮し、日付付きで列挙する（最大 `PROJECT_TOP_N=3` 件、残りは件数表示）。週報では TL;DR / 個別タスクは出さない（俯瞰のための圧縮優先）。

## エラー処理

- `~/ObsidianVault` が存在しない → `extract-summary.py` 内の存在チェックで対象なし扱い
- `python3` または `markdown` ライブラリが無い → エラー報告（`pip3 install --user markdown` を案内）
- SMTP 認証失敗（exit 3） → アプリパスワードが正しいか / 2 段階認証が有効か確認を案内
- SMTP 接続失敗（exit 3） → ネットワーク・ファイアウォール（465 ポート）を確認

## ルーティーン登録例（claude.app UI 側）

| 名前 | スケジュール | プロンプト |
|---|---|---|
| Daily summary mail | 火〜土 8:00 | `/obsidian-mail daily` |
| Weekly summary mail | 月 8:00 | `/obsidian-mail weekly` |

注: 既存「Daily summary」（平日 18:00 の `/obsidian-daily`）はそのまま残す。本スキルは送信専用で、書き込みは触らない。

> **リネーム時のルーティーン書き換え必須（重要）**: スキル名やプロンプトを変更した場合、Claude.app の **ローカルルーティーン側は自動更新されない**。旧プロンプト（例: `/obsidian-summary daily`）を登録したままだと次回発火時に「コマンド不明」で **サイレント失敗**（メールが来ない以外にエラー通知がない）する。スキルリネーム時は必ず Claude.app UI でルーティーンの slash command 文字列も書き換えること。気付くのは「メール来ないな」と能動的に思い出した時のみ、というのが地雷。

## 実装メモ

- このスキルは Claude.app の **ローカルルーティーン**から呼ばれる前提。`disable-model-invocation: true` で自動発火しないため、routine プロンプトに `/obsidian-mail daily` のように明示記述する
- `obsidian-daily` 側のハングで対象が無い場合は単純スキップする（ユーザー判断）。気付くためには `_daily/` を時々目視するか、週報で欠落日表示を確認する
- 週報は欠落日があっても残った日数（例: `5/7 日分`）で送信する。本文冒頭に欠落日を明記する
- HTML レンダリングは `markdown` ライブラリの `extra` + `sane_lists` 拡張を使用（`nl2br` は外した。再構成後の本文は段落ベースなので `<br>` が増えすぎるとレイアウトが崩れる）。`### 今日の要約` 直下の `<p>` は HTML 後処理で `.tldr` 青ボックスに包む
- TL;DR が複数段落の場合、メールでは **最初の段落のみ** 採用する（残りは Obsidian で見る前提）。全文を残すと `.tldr` ボックス外にこぼれてレイアウトが崩れる
- アプリパスワードは Google 側でいつでも revoke できる。漏洩した場合は `https://myaccount.google.com/apppasswords` で削除し、settings.local.json も更新する
- **Message-ID の domain は `obsidian-mail.local`**。リネーム前は `@obsidian-summary.local` だったため、Gmail で `from:` や `rfc822msgid:` の domain ベースのフィルタを組んでいる場合は **filter rule の更新が必要**。スレッディングは日次/週次の独立メールで連続性が薄いため副作用は軽微だが、Gmail 検索（`from:obsidian-summary.local`）が効かなくなる点に注意

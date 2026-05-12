---
name: obsidian-summary
description: Obsidian デイリーノートの「## デイリーサマリー」セクションを抽出して Gmail SMTP で送信する。日報（指定日 1 日分）・週報（指定日を含む月〜日 7 日分）の 2 モード。「日報メールして」「週報メール送って」「サマリーをメールで」といった依頼で使う。
argument-hint: daily|weekly [YYYY-MM-DD]
disable-model-invocation: true
allowed-tools: Read, Bash(date:*), Bash(python3:*), Bash(ls:*), Bash(test:*), Bash(printenv:*)
---

# obsidian-summary — デイリーサマリーをメール送信

Obsidian デイリーノートに既に書き込まれた「## デイリーサマリー」セクションを抽出し、HTML 整形して Gmail SMTP で指定アドレスに送信する。

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
3. アプリ名: `obsidian-summary` 等の任意名 → 「作成」
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
python3 ~/.claude/skills/obsidian-summary/send-summary.py "$MODE" "$TARGET_DATE"
```

`send-summary.py` は内部で:

1. `extract-summary.py` を呼んでサマリーを抽出（plain Markdown + HTML 両方生成）
2. `empty: true` の場合: 送信せず `{"sent": false, "reason": "empty"}` を返す
3. それ以外: multipart/alternative メッセージを構築 → `smtp.gmail.com:465`（SSL）でログイン → 送信
4. 結果 JSON を stdout に出力

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

## エラー処理

- `~/ObsidianVault` が存在しない → `extract-summary.py` 内の存在チェックで対象なし扱い
- `python3` または `markdown` ライブラリが無い → エラー報告（`pip3 install --user markdown` を案内）
- SMTP 認証失敗（exit 3） → アプリパスワードが正しいか / 2 段階認証が有効か確認を案内
- SMTP 接続失敗（exit 3） → ネットワーク・ファイアウォール（465 ポート）を確認

## ルーティーン登録例（claude.app UI 側）

| 名前 | スケジュール | プロンプト |
|---|---|---|
| Daily summary mail | 火〜土 8:00 | `/obsidian-summary daily` |
| Weekly summary mail | 月 8:00 | `/obsidian-summary weekly` |

注: 既存「Daily summary」（平日 18:00 の `/obsidian-daily`）はそのまま残す。本スキルは送信専用で、書き込みは触らない。

## 実装メモ

- このスキルは Claude.app の **ローカルルーティーン**から呼ばれる前提。`disable-model-invocation: true` で自動発火しないため、routine プロンプトに `/obsidian-summary daily` のように明示記述する
- `obsidian-daily` 側のハングで対象が無い場合は単純スキップする（ユーザー判断）。気付くためには `_daily/` を時々目視するか、週報で欠落日表示を確認する
- 週報は欠落日があっても残った日数（例: `5/7 日分`）で送信する。本文冒頭に欠落日を明記する
- HTML レンダリングは `markdown` ライブラリの `extra` + `sane_lists` + `nl2br` 拡張を使用。Obsidian の `> [!info]` callout は前処理で `> **ℹ️ Info**` に変換してから markdown 化
- アプリパスワードは Google 側でいつでも revoke できる。漏洩した場合は `https://myaccount.google.com/apppasswords` で削除し、settings.local.json も更新する

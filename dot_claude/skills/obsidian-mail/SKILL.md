---
name: obsidian-mail
description: 'Obsidian デイリーノートの「## デイリーサマリー」をメール向けに再構成して Gmail SMTP で送信する。日報・週報の 2 モード。「日報メールして」「週報メール送って」「サマリーをメールで」といった依頼、または Claude.app ローカルルーティーンから `/obsidian-mail daily|weekly [YYYY-MM-DD]` で明示呼び出しする（自動発火しない）。'
argument-hint: 'daily|weekly [YYYY-MM-DD]'
disable-model-invocation: true
allowed-tools: Read, Bash(date:*), Bash(python3:*), Bash(ls:*), Bash(test:*), Bash(printenv:*)
---

# obsidian-mail — デイリーサマリーをメール送信

Obsidian デイリーノートの「## デイリーサマリー」セクションを **構造化パース → メール向けに再構成**して Gmail SMTP で送信する。Obsidian ノート形式をそのまま流すのではなく、「今日のひとこと → ハイライト → GitHub → 明日のタスク」の読み物形式にする。

**主資源と連携**: 送信の on/off は resolver `~/.claude/skills/shared/integrations.md` の bool キー `daily_mail` で判定する。Vault パスは **`extract-summary.py` が `~/ObsidianVault` を直書きで持ち、resolver の `vault` は読まない**。読み取るサマリーの構造は `obsidian-daily` の出力との契約で `~/.claude/skills/shared/daily-summary-format.md` に要約がある（真の SSOT は両者のコード）。

## 引数仕様

```
$ARGUMENTS:
  daily              → 昨日の日報を送信（routine 用デフォルト）
  daily YYYY-MM-DD   → 指定日の日報を送信（手動再送）
  weekly             → 直前の月曜を含む週の週報を送信（routine 用デフォルト）
  weekly YYYY-MM-DD  → 指定日を含む週（月〜日）の週報を送信（手動再送）
```

## 前提セットアップ（初回のみユーザー操作）

Gmail の 2 段階認証と 16 文字のアプリパスワード（https://myaccount.google.com/apppasswords）が前提。

### keyring に資格情報を登録（各 PC で 1 回ずつ）

`send-summary.py` は Python `keyring` ライブラリ経由で OS 資格情報マネージャから SMTP 認証情報を取得する。**平文ファイルは持たない設計**。

**Windows** — claude.app ローカルルーティーンの本番経路:

```powershell
python -m keyring set obsidian-mail OBSIDIAN_SUMMARY_SMTP_USER
# プロンプトで Gmail アドレスを入力（echo されない）
python -m keyring set obsidian-mail OBSIDIAN_SUMMARY_SMTP_PASS
# プロンプトで 16 文字のアプリパスワードを入力（echo されない）
```

バックエンド: **Windows Credential Manager**（DPAPI per-user 暗号化、unattended アクセス可）。

**WSL / Linux** — 手動テスト用途のみ（本番 routine は Windows 側で発火）:

WSL の default backend (`fail.Keyring`) は無効化されているため、最も簡単なのは **環境変数で渡す**:

```bash
OBSIDIAN_SUMMARY_SMTP_USER='...' OBSIDIAN_SUMMARY_SMTP_PASS='...' \
    python3 ~/.claude/skills/obsidian-mail/send-summary.py daily 2026-05-19
```

### env 変数名（重要）

スキル名は `obsidian-mail` だが env 変数 prefix と keyring username は旧名由来の **`OBSIDIAN_SUMMARY_*` のまま**（変えると全マシンで keyring 再登録になる）。新規セットアップでも `OBSIDIAN_SUMMARY_*` で登録する。オプション: `OBSIDIAN_SUMMARY_MAIL_TO` / `OBSIDIAN_SUMMARY_MAIL_FROM`（既定は `SMTP_USER`）。

Python 依存: `keyring`、`markdown`。

## 動作

### 0. 連携 gate の確認（daily_mail）

`daily_mail` が `off` / 未設定 / resolver 不在 → 「メール連携が無効（daily_mail off）のため送信をスキップします」と 1 行報告して **正常終了**。

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

`send-summary.py` が抽出・再構成・SMTP 送信まで行い、結果 JSON を stdout に出す。対象が無ければ `{"sent": false, "reason": "empty"}`。メール本文の再構成規約（何を採り、手書き追加を静かに捨てるか）は `shared/daily-summary-format.md` を参照。

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

週報はプロジェクト軸で集約し、欠落日があっても残った日数で送信する（本文冒頭に欠落日を明記）。

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

> **リネーム時はルーティーンも書き換える**: Claude.app のローカルルーティーンは自動更新されず、旧プロンプトのままだと「コマンド不明」で**サイレント失敗**する（メールが来ない以外に通知がない）。

## 実装メモ

- `obsidian-daily` 側のハングで対象が無い場合は単純スキップする（ユーザー判断）。気付くためには `10_daily/` を時々目視するか、週報で欠落日表示を確認する
- Message-ID の domain は `obsidian-mail.local`（Gmail のフィルタを domain で組むならこの値）

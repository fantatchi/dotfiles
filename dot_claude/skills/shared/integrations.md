---
# shared/integrations.md — 能力検出 resolver（capability resolver）
#
# スキル間・外部リソース連携の「配線」だけを宣言する単一の出典（葉ノード。他ファイルを参照しない）。
# 各スキルはこのファイルを Read し、該当キーが空/未設定なら「## 連携」セクションを skip して
# 「## コア」だけで完結する（= standalone 動作）。このファイル自体が無い場合も全キー未設定とみなす。
#
# 値の三状態:
#   - キー欠落 / 空           … その連携は無効（standalone）
#   - off (bool)             … 明示的に無効
#   - パス / on / 配列        … 有効（連携実行）
task_store: ~/ObsidianVault/00_meta/tasks.md   # タスクストア tasks.md の絶対パス。空 → タスク連携を全 skip
task_store_probe: ~/ObsidianVault/.obsidian    # 「配備済み」判定に使う存在チェック対象（Vault 同期ガード）
vault: ~/ObsidianVault                          # Obsidian Vault ルート。空 → log/resource/daily/mail は案内終了
vault_dirs:                                     # Vault サブディレクトリ名
  log: 20_log
  resource: 30_resource
  daily: 10_daily
  meta: 00_meta
memory_promotion: on      # MEMORY.md 昇格提案の有効/無効（context-save の判断メモ昇格）
progress_map: on          # .claude/progress.md 連携（project-local・外部依存なしなので既定 on）
daily_mail: on            # obsidian-mail 連携（daily サマリーのメール送信）
gh_accounts:              # obsidian-daily が集約する GitHub アカウント。空 → アクティブ 1 アカウントのみ
  - fantatchi
  - kentem-at-kato
---

# Integrations resolver

各スキルの「連携」が **どこを指すか・有効か** を 1 か所で宣言する。スキル本体は連携対象のパスや
存在チェックを直書きせず、ここを参照する。これにより:

- **単独動作 (standalone)**: このファイルや該当キーが無い環境でも、各スキルは「## コア」だけで完結する
- **自動連携 (composable)**: 同じ環境に連携対象（tasks.md / Vault / 関連スキル）が揃っていれば、
  各スキルがここを見て自動で噛み合う

## 参照規約（各スキルの「## 連携」冒頭で行う三分岐）

1. このファイルを Read する（無ければ全キー未設定とみなす）
2. そのスキルが使うキー（例: `task_store`）を見て分岐:
   - **(a)** ファイルが無い / キーが空・未設定 → 「## 連携」を丸ごと skip し「## コア」のみで完了
   - **(b)** キーにパスがあり、対応する `*_probe`（無ければキー自身）の存在が確認できる → 連携を実行
   - **(c)** キーにパスがあるが probe が不在 → 未同期とみなし skip（データロス防止のため初期生成しない）

## キー一覧

| キー | 用途 | 主な参照スキル | 未設定時（standalone） |
|---|---|---|---|
| `task_store` | tasks.md の絶対パス | gtd-add/done/list, context-save/load, obsidian-daily | タスク連携を全 skip |
| `task_store_probe` | tasks.md 配備済み判定 | 同上 | `task_store` 自身の存在で代用 |
| `vault` | Obsidian Vault ルート | obsidian-log/daily/resource/mail, gtd-list(転記) | Vault 連携を案内して終了 |
| `vault_dirs` | Vault サブディレクトリ名 | obsidian-* | 既定値（20_log / 30_resource / 10_daily / 00_meta） |
| `memory_promotion` | 判断メモの MEMORY.md 昇格提案 | context-save, session-review | off（提案しない） |
| `progress_map` | `.claude/progress.md` 連携 | context-save/load | on（project-local で完結） |
| `daily_mail` | デイリーサマリーのメール送信 | obsidian-mail | off |
| `gh_accounts` | 集約対象 GitHub アカウント | obsidian-daily | アクティブ 1 アカウントのみ |

## 関連 shared ファイルとの役割分担

- **integrations.md（本ファイル）** = 配線（パスと on/off）。他ファイルを参照しない
- **vault-init.md** = Vault への書き方（ディレクトリ作成・ファイル名・frontmatter 規約）。Vault パスは本ファイルの `vault` を参照
- **tasks-format.md** = tasks.md の中身フォーマット（行形式・文字数・セクション）。場所は本ファイルの `task_store` を参照

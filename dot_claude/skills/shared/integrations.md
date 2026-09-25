---
# shared/integrations.md — 能力検出 resolver（capability resolver）
#
# スキル間・外部リソース連携の「配線」だけを宣言する単一の出典（葉ノード。他ファイルを参照しない）。
# 各スキルはこのファイルを Read し、該当キーが空/未設定なら「## 連携」セクションを skip して
# 「## コア」だけで完結する（= standalone 動作）。このファイル自体が無い場合も全キー未設定とみなす。
#
# キーは2種類あり判定が異なる:
#   - path 系キー (task_store / task_store_probe / vault / vault_dirs / gh_accounts):
#       値は「空 / パス・配列」の二状態（off は取らない）。空 → その連携は無効（standalone）
#   - bool 系キー (memory_promotion / progress_map / daily_mail):
#       値は「on / off / 未設定」。on のみ有効、off・未設定は無効。probe 判定はしない
#   ※ progress_map / project_task_store は外部資源でなく各リポジトリ内 .claude/ を見るだけの
#     project-local キーだが、連携の on/off をここで集中管理するため同居させている
task_store: ~/ObsidianVault/00_meta/tasks.md   # 捕捉箱（gtd-* 専用）の絶対パス。空 → gtd-* は既定パス（この値）へフォールバック
task_store_probe: ~/ObsidianVault/.obsidian    # 「配備済み」判定に使う存在チェック対象（Vault 同期ガード）
project_task_store: .claude/tasks.md           # プロジェクトの作業キュー（context-* 専用・プロジェクトルートからの相対パス）。空 → context-* はタスク欄を出さずコアのみで完結
vault: ~/ObsidianVault                          # Obsidian Vault ルート。空 → 既定 ~/ObsidianVault へフォールバックし、それも不在なら obsidian-* は案内終了、gtd-list / session-save の連携は skip
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

各スキルの「連携」が **どこを指すか・有効か** を 1 か所で宣言する。このファイルや該当キーが無い環境でも各スキルは「## コア」だけで完結し（standalone）、揃っていれば自動で噛み合う（composable）。

## 参照規約（各スキルの「## 連携」冒頭で行う三分岐）

1. このファイルを Read する（無ければ全キー未設定とみなす）
2. そのスキルが使うキーを見て、**(a)→(b)→(c) の順に上から評価し、最初に真になった分岐を採用する**。

**path 系キー**（task_store / vault 等）の場合:
   - **(a)** ファイルが無い / キーが空・未設定 → その連携を skip し「## コア」のみで完了
   - **(b)** キーにパスがあり、対応する `*_probe`（無ければキー自身）の存在が確認できる → 連携を実行
   - **(c)** キーにパスがあるが probe が不在 → 未同期とみなし skip（データロス防止のため初期生成しない）

なお `*_probe` キーが定義されていないキー（`vault` など）はキー自身を probe とするため、パスがあれば必ず (b)、無ければ (a) になり、**(c) は発生しない**。

**skip 理由は (a) と (c) を区別して報告する**: 同じ skip でも (a) は「**未設定**（連携を使わない／設定漏れ）」、(c) は「**未同期**（パスは設定済みだが probe 不在＝同期待ち）」で、ユーザーの対処が逆になる（(a) は値を設定、(c) は同期完了を待つ／設定はそのまま）。skip を報告するスキルは、可能なら `skip（未設定）` / `skip（未同期: probe 不在）` のように理由を添える。

**bool 系キー**（memory_promotion / progress_map / daily_mail）の場合は probe 判定をせず:
   - キーが `on` → 実行 / `off`・未設定 → skip

各キーの用途・参照スキル・未設定時の挙動は frontmatter のインラインコメントが正本。`obsidian-mail` は `daily_mail` だけを見て、Vault パスはコード側の直書き（resolver を読まない）。

## 関連 shared ファイルとの役割分担

- **integrations.md（本ファイル）** = 配線（パスと on/off）。他ファイルを参照しない
- **vault-init.md** = Vault への書き方。Vault パスは本ファイルの `vault` を参照
- **tasks-format.md** = 2 つの tasks.md の中身フォーマット。場所は本ファイルの `task_store` / `project_task_store` を参照

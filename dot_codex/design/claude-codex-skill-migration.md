# Claude・Codex Skill 共有設計

## 対象

Codex へ移行する Skill は `context-load`、`context-save`、`session-save`、`obsidian-log`、`obsidian-resource`、`session-review`、`spec-writer`、`multi-persona-review`、`pr-review` の 9 個とする。`obsidian-daily` と `obsidian-mail` は Claude 専用で維持する。Windows 配備では固定リストを持たず、`~/.agents/skills/*/SKILL.md` を自動検出する。

## 状態共有

`.claude/context.md`、`.claude/progress.md`、`.claude/tasks.md`（プロジェクトの作業キュー）、`.claude/handoff.md`（引き継ぎメモ）を Claude・Codex 共通の正本とする。Codex は `~/.claude/skills/shared/multi-writer.md` と `tasks-format.md` に従い、再読込、競合停止、最小編集、書込み後検証を行う。

タスクストアは 2 系統に分離されている（2026-07-27）。思いつきの**捕捉箱** `~/ObsidianVault/00_meta/tasks.md` は `gtd-*` 専用で、`context-load` / `context-save` は触らない。プロジェクトの**作業キュー**は `<project-root>/.claude/tasks.md` で、`context-save` が書き `context-load` が読む。

`handoff.md` は Claude ↔ Codex の行き詰まり引き継ぎ用（2026-08-25 新設）。`context-save` が毎回全面上書きし、`context-load` が冒頭に提示する。1 件だけを保持する揮発ファイルなので multi-writer プロトコルの「全体 Write は新規作成時のみ」の対象外。`from` フィールドで書き手を識別する（**この識別子を持つのは handoff.md だけ**で、context.md 側に writer 識別フィールドを足さない規約は維持する）。

## Obsidian 連携

Codex の作業ログは Claude と同じ `20_log/YYYYMM/`、リソースは `30_resource/YYYYMM/` に保存する。ログ frontmatter は `source: codex-log`、`generation: 0` とする。Claude の `obsidian-daily` は日付ファイルを列挙して集約し、source では絞らないため Codex ログも対象になる。

## 2 系統を symlink で 1 本化しない理由（2026-08-25 検証）

`~/.agents/skills/<name>` を `~/.claude/skills/<name>` へのシンボリックリンクにすれば二重メンテを構造的に止められる、という案を検証して**不採用**とした。

**技術的には動く**（実機確認済み）。`~/.agents/skills/` に Claude 版へのシンボリックリンクを置いて `codex exec` でスキル一覧を出したところ、認識された。Codex はリンクを辿り、`allowed-tools` のような未知の frontmatter キーがあっても壊れず、スキル名はディレクトリ名でなく frontmatter の `name` が使われる。

**それでも採らないのは、中身が harness 依存だから**。9 スキルの diff を全数確認したところ、次の 7 種の差分が「意図的な適応」として存在し、リンク化すると壊れる:

| # | 差分 | リンク化したときの実害 |
|---|---|---|
| 1 | frontmatter の `allowed-tools` / `argument-hint` / `disable-model-invocation` | Codex に存在しないキー（実害は無いが無意味） |
| 2 | `Skill` ツールが Codex に無い | `session-save` が存在しないツールを呼ぶ。Codex 版は「SKILL.md を読み手順を実行」に書き換え済み |
| 3 | `$ARGUMENTS` が Codex に無い | `obsidian-log` / `obsidian-resource` が引数を取れない |
| 4 | `CLAUDE.md` → `AGENTS.md` | Codex が読まないファイルを参照する（`spec-writer` / `session-review`） |
| 5 | `source: claude-*` → `codex-*` | Obsidian ログの writer 識別が壊れ、Codex のログが claude 由来として記録される |
| 6 | `/skill-name` → `$skill-name` | 起動記法。ユーザーに誤ったコマンドを案内する |
| 7 | 主語の「Claude」→「Codex」 | 「Claude との作業内容」等。両者を列挙している箇所は変換対象外。「Codex 等の他 writer」のように**相手を指す語**は「Claude 等の他 writer」へ反転する |
| 8 | Claude のツール名（`Read` / `Edit` / `Write`） | Codex に同名ツールが無い。ただし出現数が多く（`context-save` で 21 箇所）個別置換すると Claude 版との差分が膨らんで次回の追従が困難になるため、**本文は変えず冒頭に読み替え表を 1 つ置く**。要点は「Edit = 部分置換 / Write = 全体上書き」という**操作の指定**であってツール名ではないこと |

なお `~/.claude/skills/shared/*.md` のパス参照は**変換しない**。shared/ は両 harness が同じ実体を読む共有リソースで、Codex 版もこのパスを参照する。

**副次的な利点**: リンク化しないので、Windows 配備スクリプト `setup-windows-codex.ps1` の `Get-ChildItem -Directory` が reparse point を落とし、一部スキルがサイレントに配布されなくなる失敗モードに踏み込まずに済む（同スクリプトの唯一のガードは「0 件なら throw」で、部分欠落は検出できない）。

## fork の drift 管理

2 系統を保つ以上 drift は必ず起きる。問題は「2 つあること」ではなく「**staleness と adaptation が混ざって区別できないこと**」である。実際、2026-08-25 時点で Codex 側は 7/13 版のまま 26 コミット分遅れ、`context-save` / `context-load` が 2 ストア分離前の仕様で共有正本を書く状態になっていた。

- **Claude 側スキルを編集したら、上表の 7 種に該当しない変更かどうかを判断する**。該当しなければ（＝ harness 非依存の内容なら）Codex 側にも同じ変更が要る。判断は `~/.claude/docs/skill-management.md` のチェックリストに組み込む
- **追従は「Claude 版から作り直して 7 種の適応を再適用」が確実**。差分を拾い直す方式は取りこぼす（12 コミット分の追従で実証）
- **Codex 版にあって Claude 版にない記述**を見つけたら、adaptation（残す）か staleness（捨てる）かを必ず判定する。判断がつかないものは残す（誤削除より誤残存を選ぶ）

### 9 種目の適応: terse リライト（2026-08-28 追記）

`multi-persona-review` / `pr-review` の Codex 版は、上表 8 種に加えて**文体そのものが terse な命令形に全面リライトされている**（前置き・「このスキルが解く問題」・「よくある失敗と回避策」表・「関連スキル / 参考」節を持たない）。Claude 版の半分〜1/3 のサイズになるのはこのため。

したがって**追従は「規範だけを Codex 文体で移植する」**。Claude 側で増えた解説・バイアス論・失敗表は移植しない。移植対象は、出力形式の固定・判定基準・参照する SSOT のような**実行時に守らせる規則**に限る。

この方針だと 2 版の diff が「適応のみ」に収束しないため、**diff の行数を drift の指標に使えない**。次回の追従は、Claude 側の変更コミットを読んで規範か解説かを判定する方式で行う。

2026-08-28 に上記方針で追従した内容（Claude 側 8/25〜8/28 分）:

| スキル | 移植した規範 |
|---|---|
| `multi-persona-review` | 所見 4 項目固定（場所 / 何が起きる / 再現手順 / 根拠）、再現手順の層判定、`shared/review-output-style.md` と `shared/review-false-positives.md` の参照、提示構造（結論 3 行 → 直すなら効く順 → 指摘表 → 各 6 行 → 詳細を聞けば出せる項目 → 進め方案） |
| `pr-review` | 上記に加え、子エージェントへの `shared/security-review-exclusions.md` 逐語貼付、3 値 verdict（CONFIRMED / PLAUSIBLE / REFUTED、既定 PLAUSIBLE、REFUTED に立証責任）、ギャップ掃討フェーズ（新 5 節）、草稿テンプレの刷新 |
| `spec-writer` | 本文の構造化（表・リスト）、具体例の使い方、公式語選定の 3 基準と What it is NOT、Appendix 節、アンチパターン 10〜13、`references/diagram-selection.md` の論理図パターン表 |

## chezmoi と Windows

ユーザー管理対象は `dot_codex/AGENTS.md`、`dot_agents/skills/`、`dot_codex/scripts/`、`dot_codex/design/` とする。認証、config、セッション、Plugin、cache、ログ、SQLite は管理しない。Codex がユーザー Skill を探索する正規の場所は `~/.agents/skills/` とする。Windows の `.codex` と `.agents` は実ディレクトリを維持し、`AGENTS.md` と `~/.agents/skills/*/SKILL.md` で検出した各 Skill ディレクトリだけを WSL 側へ SymbolicLink で共有する。Windows の `.codex/skills/.system` は OS ローカルのまま保持する。

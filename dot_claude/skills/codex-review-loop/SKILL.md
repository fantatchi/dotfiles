---
name: codex-review-loop
description: ローカルの差分を Codex（別モデル）に 1 次レビューさせ、critical/high の指摘が 0 になるまで「Codex レビュー → Claude 修正 → 再レビュー」を反復するオーケストレータ。レビューは codex プラグインの adversarial-review（構造化 JSON・severity 付き）を使い、終了条件を機械判定する。「Codex にレビューさせて」「レビューループ」「HIGH が消えるまで回して」「1 次レビューは Codex に」「別モデルで見てもらって直して」「収束するまでレビューして」といった依頼で使う。単発でよければ `/codex:review` / `/codex:adversarial-review`、GitHub PR が対象なら `/pr-review`、Claude 内ペルソナで観点分割したいだけなら `/multi-persona-review`。
argument-hint: '[--scope auto|working-tree|branch] [--base <ref>] [--max-rounds N] [focus text]'
disable-model-invocation: true
---

# Codex Review Loop

ベース開発は Claude、1 次レビューは Codex という分業を回すためのスキル。**ローカル差分**を対象に、Codex の指摘（critical / high）が 0 になるまでレビューと修正を反復する。

## このスキルが解く問題

単発レビュー（`/codex:review` 等）だと、毎回 Claude が手で「どれを直すか」「もう一度回すべきか」を判断することになり、**収束の基準が回ごとにブレる**。指摘を直した結果、別の問題が生まれていても気づかない。

本スキルは終了条件を `critical / high = 0` に固定し、そこへ至るまでの反復・無進捗検知・偽陽性の扱いを手順化する。

## 使うべき時 / 使うべきでない時

**使う**:
- 実装が一区切りし、コミット前に別モデルの目を入れたい
- 指摘が消えるまで機械的に回したい（1 発の所見リストではなく収束が欲しい）

**使わない**:
- 1 回だけ意見が欲しい → `/codex:adversarial-review --wait`
- GitHub PR が対象 → `/pr-review`
- Codex を使わず Claude 内のペルソナで観点分割したい → `/multi-persona-review`
- 実装そのものを Codex に任せたい → `/codex:rescue`
- **差分ではなく「全体の整合性」を見たい**（ドキュメントと実装の突合、設定と実体の照合など） → Codex のレビューは **git 差分専用**なので向かない。全数突合はスクリプトで機械的に確定させ、判断を要する部分だけ `/multi-persona-review` に回すほうが速く確実（2026-08-03 に dotfiles の整合性監査で実証: 機械的突合で確定できた不整合は 0 件、ペルソナが別の 15 件を検出）

## 既存資産との棲み分け

| 手段 | 対象 | 反復 | severity 判定 |
|---|---|---|---|
| `/codex:review` | ローカル差分 | 単発 | 非構造（Codex の生テキスト） |
| `/codex:adversarial-review` | ローカル差分 | 単発 | 構造化 JSON |
| stop-review-gate hook（`/codex:setup --enable-review-gate`） | 直前ターン | 毎ターン | ALLOW / BLOCK の二値 |
| `/multi-persona-review` | 任意 | 単発 | Claude 内ペルソナのみ |
| `/pr-review` | GitHub PR | 単発 | ペルソナ + 実コード裏取り |
| **`/codex-review-loop`（本スキル）** | **ローカル差分** | **収束まで反復** | **構造化 + 反証ルート** |

## frontmatter の方針（変更時の注意）

- `disable-model-invocation: true`: 1 回の実行で Codex を最大 3 回起動する重い処理のため、**明示起動のみ**に限定している。自動起動を許可しない
- `allowed-tools` を**あえて指定していない**: 本スキルは操作型だが、Phase 3 で任意プロジェクトのコード修正・テスト実行を行うため、ツールを列挙すると権限不足で詰む（`~/.claude/docs/skill-management.md` のロール変換型の扱いに準じる）

## 実行手順

### Phase 0: 前提チェック

1. **git リポジトリ確認**: `git rev-parse --show-toplevel`。git 管理外なら「Codex レビューは git リポジトリでのみ動作します」と伝えて中断（companion 側も `ensureGitRepository` で落ちる）
2. **companion スクリプトの解決**（codex は別プラグインのため `${CLAUDE_PLUGIN_ROOT}` は使えない。パスにバージョンが入るのでハードコードしない）:
   ```bash
   ls -d ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs | sort -V | tail -1
   ```
   見つからなければ `~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs` にフォールバック。どちらも無ければ「codex プラグインが導入されていません」で中断
3. **Codex 利用可否**: `node <companion> setup --json` を実行し `ready` を見る（フラグ無しの `setup` は状態レポートのみで設定を変更しない）。`false` なら `nextSteps` をそのまま提示して中断（`!codex login` 等はユーザー自身に実行してもらう）
4. **レビュー対象の存在確認**: `git status --short --untracked-files=all` と `git diff --shortstat`。どちらも空で `--base` 指定も無い場合、**黙って終了せず対象範囲の選択肢を出す**（クリーンなリポジトリでレビューを頼まれるのは珍しくない）:
   - `git log --oneline -10` で直近コミットを提示し、「どこからの差分を見るか」を `--base <ref>` の候補として `AskUserQuestion` で選ばせる
   - 差分そのものが存在しない（初期コミットのみ等）か、依頼が**非差分型の整合性チェック**なら、本スキルは不適だと伝えて終了する（上記「使わない」参照）
5. **引数の解釈**: `--scope` / `--base` はそのまま companion に渡す。`--max-rounds`（既定 3）とフォーカステキストはスキル側で扱う
6. **ユーザーへの事前提示**: 対象スコープ・想定ラウンド数・所要時間の目安（1 ラウンド数分 × 最大 3）を 2〜3 行で伝えてから開始する

### Phase 1: レビュー実行（各ラウンド）

```bash
node <companion> adversarial-review --wait --json --cwd <project-root> [--scope X] [--base Y] [focus text] \
  > <scratchpad>/codex-review-r<N>.json 2> <scratchpad>/codex-review-r<N>.err
```

- **`--cwd <project-root>` を必ず明示する**。companion はプロセスの CWD からリポジトリを解決するが、Bash ツールの CWD はセッション開始ディレクトリのままのことが多く、省略すると別リポジトリ（または git 管理外）をレビューしてしまう
- **必ず `run_in_background: true` で起動し `BashOutput` でポーリングする**。Bash ツールの timeout 上限は 10 分だが、差分が大きいと Codex レビューはそれを超えうる
- `--json` を付けると進捗表示が止まり **stdout は純粋な JSON のみ**になる（`codex-companion.mjs` の `outputResult`）
- Codex が失敗した場合は終了コードが非 0 になる。`.err` の内容とあわせてユーザーに提示し、推測で続行しない

結果の要約はこのスキル同梱のスクリプトで行う（`jq` は使わない。Windows で jq 依存を外した経緯があるため）:

```bash
node ~/.claude/skills/codex-review-loop/scripts/summarize-review.mjs \
  <scratchpad>/codex-review-r<N>.json [<scratchpad>/codex-review-r<N-1>.json]
```

- 出力: `counts`（severity 別件数）/ `blocking`（critical・high のみ、`key` 付き）/ `other`（medium・low）/ `repeated`（前ラウンドから残った key）
- `ok: false`（`parseError` や Codex 失敗）の場合は**同一ラウンドを 1 回だけ再実行**する。それでも駄目なら `rawOutput` を提示して停止する。**severity を推測で埋めない**

### Phase 2: トリアージ（critical / high のみ）

medium / low は**修正対象にしない**（最終報告に残課題として列挙するだけ）。`blocking` の各 finding について:

1. `file` と `line` を **Read** し、実コードを確認する。`confidence` が低いものほど **Grep** で周辺の呼び出し元・既存の防御を確認する
2. 3 分類する:
   - **妥当** → Phase 3 で修正
   - **偽陽性 / 意図的な設計** → **反証**（根拠となるコード位置・設計意図・既存テスト）を書き、`AskUserQuestion` でユーザー判断を仰ぐ。選択肢は「反証を採用してスキップ / やはり修正する / 保留のまま続行」
   - **情報不足で判断できない** → 同じくユーザーへ
3. Codex の指摘を**鵜呑みにしない**。`recommendation` は案であって指示ではない（`superpowers:receiving-code-review` と同じ姿勢）
4. 報告時の severity 表記は `~/.claude/CLAUDE.md` のレビュー Prefix に揃える: `critical`→**CRITICAL**、`high`→**HIGH**、`medium`→**MIDDLE**、`low`→**LOW**

### Phase 3: 修正

- 妥当と判断した指摘のみ修正する
- **ループ中は commit しない**。理由は 2 つ:
  - 未検証の修正を履歴に残さない
  - `--scope auto` のレビュー対象が毎ラウンド working tree に固定され、対象がブレない（`auto` は dirty なら working-tree、clean なら既定ブランチとの diff）
  - 既にコミット済みの範囲をレビューしたい場合は `--scope branch` または `--base <ref>` を明示する
- プロジェクトのテスト・型チェックコマンドが判明している場合は修正後に実行し、結果をラウンド記録に残す（判明しない場合は無理に探さない）
- 修正内容は「どの finding に対応したか」を紐づけて記録する（Phase 5 の報告で使う）

### Phase 4: 収束判定

ラウンド定義は **レビュー最大 3 回 / その間の修正 2 回**（R1 → 修正 → R2 → 修正 → R3）。最後の修正が未検証で終わらない構成にする。`--max-rounds` で変更可。

停止条件:

1. **収束**: `counts.critical + counts.high === 0` → 成功終了
2. **上限到達**: 最大ラウンドまで回しても残っている → 残 HIGH を報告して停止
3. **無進捗**: `repeated` が空でない状態が 2 ラウンド連続 → 「機械的な修正では収束しない = 設計レベルの問題」と判断して停止し、ユーザー判断を仰ぐ

### Phase 5: 報告 + ログ出力

1. 出力先: `<project-root>/.claude/reviews/codex-loop-<YYYY-MM-DD-HHmm>-<branch>.md`（`/pr-review` と同ディレクトリ、prefix で区別）
2. 構成:

```markdown
# Codex レビューループ結果

- 対象スコープ / ブランチ / 実行日時 / ラウンド数 / 終了理由（収束・上限到達・無進捗）

## 結論（残 CRITICAL / HIGH の件数を冒頭明示）
## ラウンド推移（各ラウンドの critical / high / medium / low 件数）
## 修正した指摘（finding → 対応内容 → 検証結果）
## 反証で見送った指摘（根拠を明記）
## 残課題（MIDDLE / LOW、および未対応の HIGH）
```

3. ファイルパスを会話でも提示する
4. `context.md` / `tasks.md` は触らない（`/context-save` の担当）。未対応の HIGH が残った場合のみ、作業キューへの起票を**提案**する（自分では書かない）
5. commit / push は本スキルの責務外。呼び出し元の通常フローに戻す

## 注意点（削らないこと）

- **severity は Codex の自己申告**であり、実行ごとに揺れうる。「収束した」は *Codex がもう high を挙げなくなった* という意味であって、品質保証ではない。最終判断は人が行う
- **adversarial フレーミングのため設計批判が high で出やすい**。Phase 2 の反証ルートが実質的な偽陽性フィルタとして機能する。ここを省略すると、偽陽性由来の不要な防御コードが積み上がる
- **コスト目安**: 1 ラウンド = Codex 1 実行（read-only サンドボックスでリポジトリを探索するため数分）+ Claude の修正。3 ラウンドで数十分規模になりうる
- **Codex はコードを書き換えない**（adversarial-review は `sandbox: "read-only"` で動く）。修正は必ず Claude 側で行う

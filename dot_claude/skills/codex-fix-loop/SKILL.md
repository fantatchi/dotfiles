---
name: codex-fix-loop
description: 指定した対象（既定はプロジェクト全体）を Codex（別モデル）に 1 次レビューさせ、critical/high の指摘が 0 になるまで「Codex レビュー → Claude 修正 → 再レビュー」を反復して**実際にコードを直す**オーケストレータ。git 差分ではなくコード全体が対象で、git 管理外のディレクトリでも動く。「コードベース全体をレビューして直して」「Codex にレビューさせて直して」「全体チェックして課題を潰して」「指摘が消えるまで直して」「HIGH が消えるまで回して」「1 次レビューは Codex に」「別モデルで見てもらって直して」といった依頼で使う。**コードを書き換える点でレビュー系 3 スキルと異なる**（`/multi-persona-review` と `/pr-review` は読取専用）。所見だけ欲しいなら書き換えないスキルを選ぶこと。**git 差分**のレビューだけなら `/codex:adversarial-review`、GitHub PR なら `/pr-review`、Claude 内ペルソナで観点分割したいだけなら `/multi-persona-review`。
argument-hint: '[--target <path...>] [--max-rounds N] [focus text]'
disable-model-invocation: true
---

# Codex Fix Loop

ベース開発は Claude、1 次レビューは Codex という分業を回すためのスキル。**指定した対象のコード全体**を対象に、Codex の指摘（critical / high）が 0 になるまでレビューと修正を反復する。

> **名前に `review` を含めていないのは意図的**（2026-08-05 改名。旧 `codex-review-loop`）。`/multi-persona-review` と `/pr-review` が読取専用なのに対し、本スキルは**実際にコードを書き換える**。read-only の仲間だと誤解されると、危険な側に倒れるため名前で区別している。

## このスキルが解く問題

単発レビューだと、毎回 Claude が手で「どれを直すか」「もう一度回すべきか」を判断することになり、**収束の基準が回ごとにブレる**。指摘を直した結果、別の問題が生まれていても気づかない。

さらに差分ベースのレビュー（`/codex:review` 等）は**コミット済みで差分が無い状態だと何もできない**。「今あるコードは大丈夫か」という問いに答えられるのは全体レビューだけ。

本スキルは終了条件を `critical / high = 0` に固定し、そこへ至るまでの反復・無進捗検知・偽陽性の扱いを手順化する。

## 使うべき時 / 使うべきでない時

**使う**:
- 今あるコードベース（or その一部）に潜んでいる問題を洗い出して直したい
- 差分が無い / git 管理外でもレビューしたい
- 指摘が消えるまで機械的に回したい（1 発の所見リストではなく収束が欲しい）

**使わない**:
- **git 差分**をレビューしたい（直前の変更だけ見たい） → `/codex:adversarial-review --wait`。プラグイン側が差分収集・大差分時のフォールバックまで面倒を見てくれる
- GitHub PR が対象 → `/pr-review`
- Codex を使わず Claude 内のペルソナで観点分割したい → `/multi-persona-review`
- 実装そのものを Codex に任せたい → `/codex:rescue`
- **ドキュメントと実装の突合のように、照合ルールを機械的に書けるもの** → 先にスクリプトで全数突合したほうが速く確実。判断を要する部分だけレビューに回す（memory `[[mechanical-crosscheck-vs-persona]]`）

## 既存資産との棲み分け

| 手段 | 対象 | 反復 | severity 判定 |
|---|---|---|---|
| `/codex:review` | git 差分 | 単発 | 非構造（Codex の生テキスト） |
| `/codex:adversarial-review` | git 差分 | 単発 | 構造化 JSON |
| stop-review-gate hook（`/codex:setup --enable-review-gate`） | 直前ターン | 毎ターン | ALLOW / BLOCK の二値 |
| `/multi-persona-review` | 任意 | 単発 | Claude 内ペルソナのみ |
| `/pr-review` | GitHub PR | 単発 | ペルソナ + 実コード裏取り |
| **`/codex-fix-loop`（本スキル）** | **指定した対象の全体（git 不要）** | **収束まで反復** | **構造化 + 反証ルート** |

## frontmatter の方針（変更時の注意）

- `disable-model-invocation: true`: 1 回の実行で Codex を最大 3 回起動する重い処理のため、**明示起動のみ**に限定している。自動起動を許可しない
- `allowed-tools` を**あえて指定していない**: 本スキルは操作型だが、Phase 3 で任意プロジェクトのコード修正・テスト実行を行うため、ツールを列挙すると権限不足で詰む（`~/.claude/docs/skill-management.md` の「オーケストレータ型」の扱いに従う）

## 実行手順

### Phase 0: 前提チェック

1. **Codex の存在確認**: `codex --version`。無ければ「Codex CLI が見つかりません（`npm install -g @openai/codex`）」で中断。認証エラーが出る場合は `!codex login` をユーザー自身に実行してもらう
2. **対象の解決**:
   - `--target <path...>` があればそれを使う
   - 無ければ CWD を起点に、git リポジトリなら `git rev-parse --show-toplevel`、そうでなければ CWD 自体を対象にする
   - `codex exec` に渡す作業ルート（`-C`）は対象を含む最上位ディレクトリ。個別ファイル / サブディレクトリを絞る場合はプロンプトの `{{TARGET}}` 側で指定する
3. **git 管理下かの判定**: `git -C <root> rev-parse --show-toplevel`。**管理外なら記録しておく**（Phase 3 の安全弁 B で使う）
4. **規模の実測**（差分と違い上限が自然には決まらないので必ず測る）:
   ```bash
   # .git / node_modules / バイナリを除いたファイル数と総バイト数
   find <target> -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -size -1M | wc -l
   ```
   目安として **500 ファイル or 5MB** を超えたら、そのまま回さずサブディレクトリ単位の分割案を提示してユーザーに選ばせる。Codex は自分でファイルを読みに行くので、対象が広いほど探索が浅くなる
5. **ユーザーへの事前提示**: 対象パス・実測した規模・想定ラウンド数・所要時間の目安（1 ラウンド数分 × 最大 3）を 2〜3 行で伝えてから開始する

### Phase 1: レビュー実行（各ラウンド）

```bash
codex exec --skip-git-repo-check -C <root> -s read-only \
  --output-schema ~/.claude/skills/codex-fix-loop/schemas/review-output.schema.json \
  -o <scratchpad>/codex-review-r<N>.json \
  "<prompts/review.md を {{TARGET}} / {{USER_FOCUS}} 展開したもの>" \
  > <scratchpad>/codex-review-r<N>.log 2>&1
```

- プロンプトは `~/.claude/skills/codex-fix-loop/prompts/review.md` を **Read** し、`{{TARGET}}`（対象パスと、絞り込みがあればその範囲）と `{{USER_FOCUS}}`（引数の focus text。無ければ `(none)`）を差し替えて渡す
- **`-o` で書かせたファイルだけを読む。stdout / ログを結果として使わない**。`codex exec` は中間ターンでも同じスキーマ形状の JSON を出力するが、そちらは `findings` が空のことがあり、拾うと「指摘なし」と誤判定する（2026-08-05 の実測で確認）
- **`-s read-only` を必ず付ける**。Codex はこのサンドボックス内で自律的にシェルを実行して裏取りするが（構文チェック等）、書き込みはできない。修正は Claude 側の責務
- **`run_in_background: true` で起動し `BashOutput` でポーリングする**。Bash ツールの timeout 上限は 10 分だが、対象が広いとレビューはそれを超えうる
- 終了コードが非 0 ならログの内容とあわせてユーザーに提示し、推測で続行しない

結果の要約は同梱スクリプトで行う（`jq` は使わない。Windows で jq 依存を外した経緯があるため）:

```bash
node ~/.claude/skills/codex-fix-loop/scripts/summarize-review.mjs \
  <scratchpad>/codex-review-r<N>.json [<scratchpad>/codex-review-r<N-1>.json]
```

- 出力: `counts`（severity 別件数）/ `blocking`（critical・high のみ、`key` 付き）/ `other`（medium・low）/ `repeated`（前ラウンドから残った key）
- `ok: false` の場合は**同一ラウンドを 1 回だけ再実行**する。それでも駄目なら `rawOutput` を提示して停止する。**severity を推測で埋めない**

### Phase 2: トリアージ（critical / high のみ）

medium / low は**修正対象にしない**（最終報告に残課題として列挙するだけ）。

**安全弁 A: 初回ラウンドで `blocking` が 10 件を超えたら、修正に入る前に停止する。** 全体レビューは差分レビューと違い、今回の作業と無関係な既存問題まで拾う。全部直すと意図しない大規模改修になるので、一覧（severity / ファイル / 一行要約）を提示し、`AskUserQuestion` で着手範囲を選ばせる（例: 「critical のみ」「全部」「ファイルを指定」）。選ばれなかった finding は最終報告の残課題へ回し、収束判定の対象からも外す。

`blocking` の各 finding について:

1. `file` と `line` を **Read** し、実コードを確認する。`confidence` が低いものほど **Grep** で周辺の呼び出し元・既存の防御を確認する
2. 3 分類する:
   - **妥当** → Phase 3 で修正
   - **偽陽性 / 意図的な設計** → **反証**（根拠となるコード位置・設計意図・既存テスト）を書き、`AskUserQuestion` でユーザー判断を仰ぐ。選択肢は「反証を採用してスキップ / やはり修正する / 保留のまま続行」
   - **情報不足で判断できない** → 同じくユーザーへ
3. Codex の指摘を**鵜呑みにしない**。`recommendation` は案であって指示ではない（`superpowers:receiving-code-review` と同じ姿勢）。既存のスキーマ・命名・設計に合わない提案はそのまま採らず、意図に合わせて置き換える
4. 報告時の severity 表記は `~/.claude/CLAUDE.md` のレビュー Prefix に揃える: `critical`→**CRITICAL**、`high`→**HIGH**、`medium`→**MIDDLE**、`low`→**LOW**

### Phase 3: 修正

**安全弁 B: 対象が git 管理外なら、最初の修正に入る前に必ず確認を取る。** git 配下なら修正は revert できるが、管理外では**巻き戻せない**（CLAUDE.md「確認トリガー」の破壊的操作に該当）。「【変更内容】【影響範囲】【理由】」の形式で提示し、GO をもらってから修正する。ユーザーが望むならバックアップの作成を先に提案する。

- 妥当と判断した指摘のみ修正する
- **ループ中は commit しない**。未検証の修正を履歴に残さないため（git 配下の場合）
- プロジェクトのテスト・型チェックコマンドが判明している場合は修正後に実行し、結果をラウンド記録に残す（判明しない場合は無理に探さない）
- 修正内容は「どの finding に対応したか」を紐づけて記録する（Phase 5 の報告で使う）

### Phase 4: 収束判定

ラウンド定義は **レビュー最大 3 回 / その間の修正 2 回**（R1 → 修正 → R2 → 修正 → R3）。最後の修正が未検証で終わらない構成にする。`--max-rounds` で変更可。

停止条件:

1. **収束**: 着手対象とした範囲の critical / high が 0 件 → 成功終了
2. **上限到達**: 最大ラウンドまで回しても残っている → 残 HIGH を報告して停止
3. **無進捗**: `repeated` が空でない状態が 2 ラウンド連続 → 「機械的な修正では収束しない = 設計レベルの問題」と判断して停止し、ユーザー判断を仰ぐ

### Phase 5: 報告 + ログ出力

1. 出力先: `<project-root>/.claude/reviews/codex-loop-<YYYY-MM-DD-HHmm>-<対象名>.md`（`/pr-review` と同ディレクトリ、prefix で区別）。git 管理外の対象で `.claude/` が無ければ作成するか、scratchpad に置いてパスを提示する
2. 構成:

```markdown
# Codex レビューループ結果

- 対象 / 規模（ファイル数・バイト数）/ 実行日時 / ラウンド数 / 終了理由（収束・上限到達・無進捗）

## 結論（残 CRITICAL / HIGH の件数を冒頭明示）
## ラウンド推移（各ラウンドの critical / high / medium / low 件数）
## 修正した指摘（finding → 対応内容 → 検証結果）
## 反証で見送った指摘（根拠を明記）
## 着手範囲から外した指摘（安全弁 A で除外したもの）
## 残課題（MIDDLE / LOW、および未対応の HIGH）
```

3. ファイルパスを会話でも提示する
4. `context.md` / `tasks.md` は触らない（`/context-save` の担当）。未対応の HIGH が残った場合のみ、作業キューへの起票を**提案**する（自分では書かない）
5. commit / push は本スキルの責務外。呼び出し元の通常フローに戻す

## 注意点（削らないこと）

- **severity は Codex の自己申告**であり、実行ごとに揺れうる。「収束した」は *Codex がもう high を挙げなくなった* という意味であって、品質保証ではない。最終判断は人が行う
- **全体レビューは既存問題を掘り起こす**。差分レビューのつもりで使うと、直す気のなかったコードまで指摘が飛んでくる。安全弁 A を省略しない
- **偽陽性フィルタは Phase 2 の反証ルート**。ここを省略すると、偽陽性由来の不要な防御コードが積み上がる
- **コスト目安**: 対象規模に比例する。実測値として、3 ファイル（約 3KB）の非 git ディレクトリで 27,178 tokens / 数分だった。実プロジェクトはこの数十倍を見込む
- **Codex はコードを書き換えない**（`-s read-only`）。修正は必ず Claude 側で行う

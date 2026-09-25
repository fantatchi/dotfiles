---
name: context-load
description: '保存済みのプロジェクトコンテキスト（`.claude/context.md` / `progress.md` / `tasks.md` / `handoff.md`）を読み込み、git 状態と比較して前回の作業状態を復帰する。セッション開始時や Codex から作業を引き継ぐときに使う。読み込み専用（PR 状態の実査に gh を使う）。'
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(gh pr view:*), Bash(echo:*), Bash(basename:*), Bash(pwd)
---

# コンテキスト読み込み

`.claude/` 配下（context.md / progress.md / tasks.md / handoff.md）だけを読む project-local スキル。参照先パスの配線のみ `~/.claude/skills/shared/integrations.md`（resolver）で解決する。

## 手順

プロジェクトルートは `git rev-parse --show-toplevel`、git 外なら CWD。`{project-root}/.claude/context.md` が無ければ「コンテキストが保存されていません。`/context-save` で保存してください。」と案内して終了。

### 1. コンテキストファイルの読み込み

### 2. 現在の git 状態との比較

保存時と現在の状態を比較し、差分があれば警告する：

- ブランチが異なる場合: 「保存時のブランチ: `xxx` → 現在: `yyy`」
- 未コミットの変更がある場合: 注意喚起
- 保存時以降に新しいコミットがある場合: その旨を表示
- **context.md に PR 番号が出てくる場合は、提示前に `gh pr view <番号> --json state,isDraft,reviewDecision,mergeable` で実査する**（PR の状態は他人の操作で変わる）。実査できない場合は「保存時点の記述」と明示して提示する
  - **実査するのは OPEN / 未決と読める PR だけに絞る**。「MERGED」「クローズ済み」と明記された PR は再実査しない（PR 番号が 20 件以上出るプロジェクトがある）

### 3. 進捗マップの読み込み

`{project-root}/.claude/progress.md` を読み込み、進捗マップとして扱う（project-local のため外部依存なし）。

- ファイルが存在しない場合はスキップ
- 抽出した内容は提示（ステップ 6）に含める
- **8KB を超える場合は全文を出さない**。`最終更新` の最新 1 行と `## 現在地` の要点だけを要約して提示し、`⚠️ progress.md が N KB あります（全文は省略）。最終更新行の積み上がり・完了済み経緯の滞留を確認してください` を 1 行添える。**省略したことを必ず明示する**
- 後方互換: `.claude/progress.md` がなく、かつ `{project-root}/CLAUDE.md` に `## 進捗マップ` セクションがある場合は、そこから抽出する（旧形式）

### 4. 作業キューの読み込み

resolver の `project_task_store`（既定 `<project-root>/.claude/tasks.md`）を読み、`## Next` / `## Someday` のタスクを抽出する。これは `context-save` が前回セッションで保存した「次にやること」で、セッション開始時に即座に見えるようにするのが目的。

- `project_task_store` が空 / ファイルが存在しない場合はスキップし、提示の「次のステップ」セクションごと省略する
- `## Someday`（条件待ち・保留）のタスクには 💤 マーカーを付けて Next と区別する
- ファイルはあるが Next / Someday が 0 件の場合は「次のステップなし」と表示する
- **Next が tasks-format.md の件数目安を超える場合は全件を並べず、上位 8 件 + 総件数を出す**（`（ほか N 件）`）。Someday は件数だけでよい。**間引いたことを必ず明示する**。あわせて `⚠️ Next が N 件あります。タスクでない行が混ざっていないか棚卸しを検討してください` を 1 行添える
- フォーマット規約は `~/.claude/skills/shared/tasks-format.md`（context-save と同じ SSOT）

### 5. 引き継ぎメモの読み込み（handoff.md）

`{project-root}/.claude/handoff.md` を読む。これは `context-save` が毎回書き出す「他のエージェントへ作業を渡すとしたら何を伝えるか」のメモで、Claude ↔ Codex の往復（agent handoff）の受け取り口にあたる。

- ファイルが存在しない場合はスキップし、提示の該当セクションごと省略する
- **`from` が自分と異なる場合**（Claude が読んでいて `from: codex` 等）は「**⚠️ codex からの引き継ぎ**」として提示の**冒頭**に出す。相手が残した negative results を読まずに作業を始めると同じ轍を踏むため、他のどのセクションより先に見せる
- **`from` が自分と同じ場合**は「自分が書いた引き継ぎ（相手が未消化）」と明示する。自分の書いたメモを相手からの指示と誤読させない
- `## 未解決・詰まっている点` が `なし` 以外なら強調表示する
- **`at` が 7 日より古い場合**は `（N 日前の引き継ぎです）` と添える。揮発情報なので古いものは前提が変わっている可能性が高い
- **整合チェック**: `handoff.md` の `at` が `context.md` の `updated` より**新しい**場合、`⚠️ context.md が引き継ぎメモより古いため、進行中の作業の記述が実態とずれている可能性があります` と 1 行添える。両者は本来 `context-save` が同時に書くので、ずれているのは handoff.md だけが手で書かれた場合など

### 6. コンテキストの提示

読み込んだ情報を整理して提示する：

```
## 前回のコンテキスト

**最終更新**: YYYY-MM-DD HH:mm
**ブランチ**: feature/xxx

### ⚠️ codex からの引き継ぎ（.claude/handoff.md より・handoff がある場合のみ・最上部に出す）
**topic**: （topic）／**書き手**: codex（YYYY-MM-DD HH:mm）
- **未解決・詰まっている点**: （内容）
- **試して駄目だったこと**: （内容）
- **現在の仮説** / **再現手順** / **次の一手**: （内容）

### プロジェクト概要
（概要）

### 現在の状態（context.md に `## 現在の状態` がある場合のみ）
- **直近のコミット**: （保存時のコミット）
- **未コミットの変更**: （あれば）
- **オープン PR 等**: （あれば）

### 進捗マップ（.claude/progress.md より）
（progress.md の内容をそのまま表示。8KB 超なら要約 + 省略の明示 + 警告 1 行）

### 進行中の作業
（作業内容）

### 次のステップ（.claude/tasks.md より）
- [ ] （Next のタスク）
- [ ] （Someday のタスク） 💤 保留

### 関連リポジトリ（context.md に該当セクションがある場合のみ）
- **dotfiles (chezmoi)**: `<git remote URL>`
  - 直近のコミット: `<コミットサマリ>`

### 状態の変化（差分がある場合のみ）
（差分の詳細）

```

## 注意事項

- **読み込み専用**。context.md・progress.md・tasks.md・handoff.md を変更しない（タスクの追加・`[x]` の整理・引き継ぎメモの更新はいずれも `/context-save` の担当）
- **handoff.md の消化状態は記録しない**。読んだことを示す `status: consumed` のようなフィールドは持たない設計で、次に `/context-save` が走ったときの上書きで自然に入れ替わる（読み込み専用の本スキルは書き戻せないため、状態を持たせると必ず腐る）
- **複数 writer 前提で読む**（`~/.claude/skills/shared/multi-writer.md`）。未知の frontmatter キー・見出しは提示から黙って落とさず、末尾で「その他のセクション」として言及する。`tags: claude-context` が無いファイルも正常として読む

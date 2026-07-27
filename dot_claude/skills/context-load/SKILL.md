---
name: context-load
description: 保存済みのプロジェクトコンテキストを読み込み、前回の作業状態を復帰する。セッション開始時に使う。`.claude/context.md`・`.claude/progress.md`・`.claude/tasks.md`（作業キュー）の読み込みと git 状態比較・提示を行い、すべて project-local で完結する（Obsidian 等の外部依存なし）。
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(echo:*), Bash(basename:*), Bash(pwd)
---

# コンテキスト読み込み

保存済みのプロジェクトコンテキストを読み込み、前回の作業状態を復帰する。

このスキルは **`.claude/` 配下（context.md / progress.md / tasks.md）だけを読む project-local スキル**で、外部連携を持たない。Obsidian や他スキルが無い環境でもそのまま動く。参照先パスの配線のみ `~/.claude/skills/shared/integrations.md`（resolver）で解決する。

## 手順

### 読み込み元

プロジェクトルートの `.claude/context.md`

#### プロジェクトルートの決定

1. `git rev-parse --show-toplevel` でリポジトリルートを取得
2. git リポジトリ外の場合は CWD をプロジェクトルートとする

#### ファイルが存在しない場合

「コンテキストが保存されていません。`/context-save` で保存してください。」と案内して終了。

### 1. コンテキストファイルの読み込み

`{project-root}/.claude/context.md` を読み込み、内容を把握する。

### 2. 現在の git 状態との比較

保存時と現在の状態を比較し、差分があれば警告する：

- ブランチが異なる場合: 「保存時のブランチ: `xxx` → 現在: `yyy`」
- 未コミットの変更がある場合: 注意喚起
- 保存時以降に新しいコミットがある場合: その旨を表示
- **context.md に PR 番号が出てくる場合は、提示前に `gh pr view <番号> --json state,isDraft,reviewDecision,mergeable` で実査する**（読み込み専用の原則には反しない。context.md は書き換えない）。PR の状態は他人の操作で変わるため保存時点の記述をそのまま提示すると、古い前提のまま作業方針を立ててしまう。実査できない場合（gh 未認証・ネットワーク不通）は「保存時点の記述」と明示して提示する

### 3. 進捗マップの読み込み

`{project-root}/.claude/progress.md` を読み込み、進捗マップとして扱う（project-local のため外部依存なし）。

- ファイルが存在しない場合はスキップ
- 抽出した内容は提示（ステップ 4）に含める
- 後方互換: `.claude/progress.md` がなく、かつ `{project-root}/CLAUDE.md` に `## 進捗マップ` セクションがある場合は、そこから抽出する（旧形式）

### 4. 作業キューの読み込み

resolver の `project_task_store`（既定 `<project-root>/.claude/tasks.md`）を読み、`## Next` / `## Someday` のタスクを抽出する。これは `context-save` が前回セッションで保存した「次にやること」で、セッション開始時に即座に見えるようにするのが目的。

- `project_task_store` が空 / ファイルが存在しない場合はスキップし、提示の「次のステップ」セクションごと省略する
- `## Someday`（条件待ち・保留）のタスクには 💤 マーカーを付けて Next と区別する
- ファイルはあるが Next / Someday が 0 件の場合は「次のステップなし」と表示する
- フォーマット規約は `~/.claude/skills/shared/tasks-format.md`（context-save と同じ SSOT）

### 5. コンテキストの提示

読み込んだ情報を整理して提示する：

```
## 前回のコンテキスト

**最終更新**: YYYY-MM-DD HH:mm
**ブランチ**: feature/xxx

### プロジェクト概要
（概要）

### 現在の状態（context.md に `## 現在の状態` がある場合のみ）
- **直近のコミット**: （保存時のコミット）
- **未コミットの変更**: （あれば）
- **オープン PR 等**: （あれば）

### 進捗マップ（.claude/progress.md より）
（progress.md の内容をそのまま表示）

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

- 「現在の状態」は context.md に `## 現在の状態` がある場合のみ表示する。git 管理外（ホームワークスペース等）でセクションが無ければ省略する（ブランチは冒頭の `**ブランチ**` で出すため重複させない）
- 「進捗マップ」は `.claude/progress.md`（優先）または CLAUDE.md の `## 進捗マップ` セクション（後方互換）がある場合のみ表示する。どちらもない場合はセクションごと省略する
- 「次のステップ」は `.claude/tasks.md` がある場合のみ表示する。無ければセクションごと省略する
- 「関連リポジトリ」は context.md に `## 関連リポジトリ` セクションがある場合のみ表示する。ない場合はセクションごと省略する

## 注意事項

- **読み込み専用**。context.md・progress.md・tasks.md を変更しない（タスクの追加・`[x]` の整理は `/context-save` の担当）
- **Obsidian Vault は参照しない**。捕捉箱（`~/ObsidianVault/00_meta/tasks.md`）は `gtd-*` の担当で、本スキルとは無関係
- **複数 writer 前提で読む**: 3 ファイルとも Claude・Codex 等が共有する正本であり（`~/.claude/skills/shared/multi-writer.md` 参照）、Claude 固有の記述だけが存在する前提にしない
  - 未知の frontmatter キー・見出し・フィールドがあっても**エラーにせず有効データとして扱う**（保持対象。提示から黙って落とさず、未知セクションは提示の末尾で「その他のセクション」として言及する）
  - Claude 固有の目印（frontmatter の `tags: claude-context` 等）が無いファイルも正常として読み込む
- パスはプロジェクトルートからの相対パスで記録されているため、現在のマシンのパスと異なる場合がある

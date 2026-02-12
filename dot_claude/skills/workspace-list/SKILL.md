---
name: workspace-list
description: ワークスペース内のプロジェクト一覧と状態を表示する。
disable-model-invocation: true
allowed-tools: Read, Bash(git *, readlink *, ls *, test *), Glob
---

# ワークスペース一覧

ワークスペース内のプロジェクトを一覧し、git の状態を表示する。読み取り専用。

## 前提条件

設定ファイル `$HOME/.claude/config.json` の `workspace_dir` の値をワークスペースパスとして使う。

パスの取得手順:
1. `$HOME/.claude/config.json` を Read ツールで読み込む
2. JSON から `workspace_dir` の値を取得する（値は絶対パス）

※ `workspace_dir` キーが存在しない場合は以下を案内して終了：

```
workspace_dir が設定されていません。
~/.claude/config.json に以下を追加してください：

  "workspace_dir": "/path/to/workspace"

chezmoi を使っている場合は `chezmoi init` で設定できます。
```

## 処理フロー

### 1. プロジェクトの列挙

`{workspace_dir}/` 直下のディレクトリを `ls` で取得する。
0 件の場合は「プロジェクトがありません」と案内して終了。

### 2. 各プロジェクトの情報取得

各ディレクトリについて以下を取得する：

| 項目 | 取得方法 | 非該当時 |
|------|----------|----------|
| プロジェクト名 | ディレクトリ名 | — |
| リンク先 | symlink の場合 `readlink` で取得 | 実体の場合は表示しない |
| ブランチ | `git branch --show-current` | git リポジトリでなければ `—` |
| 未コミット変更 | `git status --short` の行数 | 0 件なら `—` |
| 最終コミット | `git log -1 --format=%cd --date=short` | git リポジトリでなければ `—` |
| コンテキスト | `$HOME/.claude/context/{name}.md` の有無 | なければ `—` |

**エッジケース:**

- symlink 先が存在しない → プロジェクト名の後に「（リンク切れ）」と表示し、他の項目は `—`
- git リポジトリでないディレクトリ → ブランチ・変更・最終コミットは `—`

### 3. 一覧の表示

以下の形式で表示する：

```
## ワークスペース

| プロジェクト | ブランチ | 変更 | 最終コミット | コンテキスト |
|---|---|---|---|---|
| ict-pf → /mnt/c/.../ict-pf | feature/xxx | 3 files | 2026-02-11 | ✓ |
| cloud-education-syllabus | main | — | 2026-02-10 | — |
| notes（リンク切れ） | — | — | — | — |
| data-archive | — | — | — | — |
```

**表示ルール:**

- symlink の場合：`プロジェクト名 → リンク先` の形式
- 実体の場合：プロジェクト名のみ
- 未コミット変更がある場合：`N files` の形式
- コンテキストファイルがある場合：`✓`

## 注意事項

- 読み取り専用。ファイルやリポジトリの状態を変更しない
- `git status` に `-uall` フラグを使用しない

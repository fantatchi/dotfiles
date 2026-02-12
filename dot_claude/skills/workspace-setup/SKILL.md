---
name: workspace-setup
description: プロジェクトをワークスペースに登録する。workspace_dir 未設定時は設定を案内する。
allowed-tools: Read, Bash(git rev-parse *, ln -s *, readlink *, test *, mkdir -p *, basename *), Glob
---

# ワークスペースセットアップ

カレントディレクトリのプロジェクトをワークスペースに symlink で登録する。

## ワークスペースパスの取得

設定ファイル `$HOME/.claude/config.json` の `workspace_dir` の値をワークスペースパスとして使う。

パスの取得手順:
1. `$HOME/.claude/config.json` を Read ツールで読み込む
2. JSON から `workspace_dir` の値を取得する（値は絶対パス）

## 処理フロー

```
workspace_dir 未設定?
  ├─ YES → プロジェクトディレクトリを検出 → 親ディレクトリを workspace_dir として設定方法を案内
  └─ NO  → プロジェクトディレクトリを検出 → workspace_dir に symlink を作成して登録
```

## 1. プロジェクトディレクトリの検出

| 状況 | 検出方法 | 結果 |
|------|----------|------|
| git リポジトリ内 | `git rev-parse --show-toplevel` | git root |
| git リポジトリ外 | カレントディレクトリ | カレントディレクトリ |

## 2-A. workspace_dir 未設定時（案内モード）

検出したプロジェクトディレクトリの**親ディレクトリ**を `workspace_dir` 候補として、以下を表示する：

```
workspace_dir が設定されていません。
~/.claude/config.json に以下を追加してください：

  "workspace_dir": "{親ディレクトリのパス}"

chezmoi を使っている場合は `chezmoi init` で設定できます。

設定後、再度 /workspace-setup を実行するとプロジェクトを登録できます。
```

## 2-B. workspace_dir 設定済み時（登録モード）

### 登録処理

1. プロジェクト名 = プロジェクトディレクトリの `basename`
2. symlink パス = `{workspace_dir}/{プロジェクト名}`

### エッジケース

以下の順で判定し、最初に該当した処理を実行する：

| ケース | 判定方法 | 対応 |
|--------|----------|------|
| プロジェクトディレクトリが workspace_dir 直下にある | プロジェクトディレクトリの親が workspace_dir と一致 | 「既にワークスペース内にあります」と案内して終了 |
| 同名の symlink が既に存在し、同じリンク先 | `readlink` でリンク先を比較 | 「既に登録されています」と案内して終了 |
| 同名の symlink/ディレクトリが既に存在し、別物 | パスが異なる | 上書きせず警告して終了 |
| workspace_dir 自体が存在しない | `test -d` | `mkdir -p` で作成 |

### symlink の作成

```bash
ln -s {プロジェクトディレクトリ} {workspace_dir}/{プロジェクト名}
```

### 成功時の出力

```
✓ プロジェクトを登録しました

  {プロジェクト名} → {プロジェクトディレクトリ}

/workspace-list で一覧を確認できます。
```

## 注意事項

- 既存のファイルやディレクトリを上書き・削除しない
- symlink の作成のみ行い、ファイルのコピーや移動はしない

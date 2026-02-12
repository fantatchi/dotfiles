---
name: workspace-setup
description: プロジェクトをワークスペースに登録する。WORKSPACE_DIR 未設定時は設定を案内する。
allowed-tools: Bash(git rev-parse *, ln -s *, readlink *, test *, mkdir -p *, basename *), Glob
---

# ワークスペースセットアップ

カレントディレクトリのプロジェクトを `WORKSPACE_DIR` に symlink で登録する。

## 処理フロー

```
WORKSPACE_DIR 未設定?
  ├─ YES → プロジェクトディレクトリを検出 → 親ディレクトリを WORKSPACE_DIR として export コマンドを案内
  └─ NO  → プロジェクトディレクトリを検出 → WORKSPACE_DIR に symlink を作成して登録
```

## 1. プロジェクトディレクトリの検出

| 状況 | 検出方法 | 結果 |
|------|----------|------|
| git リポジトリ内 | `git rev-parse --show-toplevel` | git root |
| git リポジトリ外 | カレントディレクトリ | カレントディレクトリ |

## 2-A. WORKSPACE_DIR 未設定時（案内モード）

検出したプロジェクトディレクトリの**親ディレクトリ**を `WORKSPACE_DIR` 候補として、以下を表示する：

```
WORKSPACE_DIR が設定されていません。
以下を環境変数に追加してください：

  export WORKSPACE_DIR="{親ディレクトリのパス}"

設定後、再度 /workspace-setup を実行するとプロジェクトを登録できます。
```

## 2-B. WORKSPACE_DIR 設定済み時（登録モード）

### チルダ展開

```bash
WORKSPACE_DIR="${WORKSPACE_DIR/#\~/$HOME}"
```

### 登録処理

1. プロジェクト名 = プロジェクトディレクトリの `basename`
2. symlink パス = `$WORKSPACE_DIR/{プロジェクト名}`

### エッジケース

以下の順で判定し、最初に該当した処理を実行する：

| ケース | 判定方法 | 対応 |
|--------|----------|------|
| プロジェクトディレクトリが WORKSPACE_DIR 直下にある | プロジェクトディレクトリの親が WORKSPACE_DIR と一致 | 「既にワークスペース内にあります」と案内して終了 |
| 同名の symlink が既に存在し、同じリンク先 | `readlink` でリンク先を比較 | 「既に登録されています」と案内して終了 |
| 同名の symlink/ディレクトリが既に存在し、別物 | パスが異なる | 上書きせず警告して終了 |
| WORKSPACE_DIR 自体が存在しない | `test -d` | `mkdir -p` で作成 |

### symlink の作成

```bash
ln -s {プロジェクトディレクトリ} $WORKSPACE_DIR/{プロジェクト名}
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

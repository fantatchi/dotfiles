# Obsidian Vault 初期化手順

`obsidian-log` / `obsidian-resource` 等、Obsidian Vault へ書き出すスキルが共通で参照する手順。

## 前提

呼び出し元スキルは **サブディレクトリ名** を決めておくこと（例: `log` / `resource`）。以降の手順では `<サブ>` と表記する。

## 1. Vault 存在確認

Vault パスはユーザーホーム直下の `~/ObsidianVault` 固定。

1. `~/ObsidianVault` が存在することを確認する（`ls ~/ObsidianVault` 等）
2. 存在しなければ以下を案内して終了：

```
~/ObsidianVault が見つかりません。
ユーザーホーム直下に ObsidianVault を配置してください（WSL ではシンボリックリンクでも可）。
```

## 2. 書き出し先ディレクトリ

`~/ObsidianVault/_claude/<サブ>/YYYYMM/` に書き出す（YYYYMM は現在の年月、例: `202602`）。ディレクトリが存在しなければ `mkdir -p` で作成する。

## 3. ファイル名

`YYYYMMDDHHmmss_簡潔なタイトル.md`

- タイムスタンプは **`date +%Y%m%d%H%M%S` で取得** する（`HHmmss` まで必須）
- 日本語 OK、スペースはハイフンに置換

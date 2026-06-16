# Obsidian Vault 初期化手順

**shared ライブラリ**: `~/.claude/skills/shared/` 配下、`name:` 付きスキルではない（自動起動対象外）。Obsidian Vault へ書き出すスキル（`obsidian-log` / `obsidian-resource` / `obsidian-daily`）が共通で参照する手順。Vault パス決定・サブディレクトリ作成・frontmatter 規約を集約。Vault パスの**出典は resolver `~/.claude/skills/shared/integrations.md` の `vault`**（このファイルは「書き方」、resolver は「どこに」を持つ役割分担）。

## 前提

呼び出し元スキルは **サブディレクトリ名** を決めておくこと（例: `20_log` / `30_resource`）。以降の手順では `<サブ>` と表記する。

## 1. Vault パスの解決と存在確認

Vault パスは resolver `~/.claude/skills/shared/integrations.md` の `vault` で解決する（無ければ既定 `~/ObsidianVault`）。

1. resolver を Read し `vault` を取得する（resolver が無い / `vault` が空なら既定 `~/ObsidianVault`）。以降この解決済みパスを `<vault>` と呼ぶ
2. `<vault>` が存在することを確認する（`ls <vault>` 等）
3. 存在しなければ以下を案内して終了：

```
<vault>（Obsidian Vault）が見つかりません。
Vault を配置するか、shared/integrations.md の vault を実在パスに設定してください
（WSL ではシンボリックリンクでも可）。
```

obsidian-* は Vault を主資源とする「Vault 連携専用」スキルなので、Vault 不在時は **standalone フォールバックを持たず案内して終了**する（gtd-* / context-* のような連携 skip ＋コア続行とは扱いが異なる）。

## 2. 書き出し先ディレクトリ

`<vault>/<サブ>/YYYYMM/` に書き出す（YYYYMM は現在の年月、例: `202602`）。ディレクトリが存在しなければ `mkdir -p` で作成する。

## 3. ファイル名

`YYYYMMDDHHmmss_簡潔なタイトル.md`

- タイムスタンプは **`date +%Y%m%d%H%M%S` で取得** する（`HHmmss` まで必須）
- 日本語 OK、スペースはハイフンに置換

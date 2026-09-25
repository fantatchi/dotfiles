# Obsidian Vault 初期化手順

Obsidian Vault へ書き出すスキル（`obsidian-log` / `obsidian-resource` / `obsidian-daily`）が共通で参照する手順。呼び出し元スキルはサブディレクトリ名（resolver `vault_dirs.*`）を決めておくこと。以降 `<サブ>` と表記する。

## 1. Vault パスの解決と存在確認

1. resolver `~/.claude/skills/shared/integrations.md` の `vault` を取得する（resolver が無い / `vault` が空なら既定 `~/ObsidianVault`）。以降この解決済みパスを `<vault>` と呼ぶ
2. `<vault>` が存在しなければ以下を案内して終了：

```
<vault>（Obsidian Vault）が見つかりません。
Vault を配置するか、shared/integrations.md の vault を実在パスに設定してください
（WSL ではシンボリックリンクでも可）。
```

obsidian-* は Vault を主資源とする「Vault 連携専用」スキルなので、Vault 不在時は **standalone フォールバックを持たず案内して終了**する（gtd-* / context-* のような連携 skip ＋コア続行とは扱いが異なる）。

## 2. 書き出し先ディレクトリ

`<vault>/<サブ>/YYYYMM/` に書き出す（YYYYMM は現在の年月）。

## 3. ファイル名

`YYYYMMDDHHmmss_簡潔なタイトル.md`

- タイムスタンプは **`date +%Y%m%d%H%M%S` で取得** する（`HHmmss` まで必須）
- 日本語 OK、スペースはハイフンに置換

# Phase 5: 許可の摩擦

組み込みの `/fewer-permission-prompts` で、許可を求められがちな読取専用のコマンドを洗い出し、allowlist に足す案を出す。提案のみ。

## 呼び方

`Skill(fewer-permission-prompts)` を、次の引数で呼ぶ:

> 手順 7 の一覧表を出したところで止め、手順 8（`.claude/settings.json` への書き込み）と手順 9 は行わない

このスキルは、手順 8 でプロジェクトの `.claude/settings.json` に直接書き込む。ホームで実行すると、それは `~/.claude/settings.json`（chezmoi 管理・全マシン共通）になり、CLAUDE.md の「迷ったら settings.local.json」が効かない。そのため書き込みはさせず、置き場所はこちらで決める。

## 振り分け

一覧表の各行について、次の順に処理する。

1. `~/.claude/settings.json` と `~/.claude/settings.local.json` の `permissions.allow` に、同じものや、それを含む広いパターンがすでにあれば落とす
2. 置き場所を CLAUDE.md の「Claude Code 設定ファイルの使い分け」で決める
   - 全マシンで使う基本の Bash 系 → `settings.json`
   - 特定 PC のパスを含むもの、MCP・WebFetch、特定プロジェクトでしか使わないもの → `settings.local.json`
   - 迷ったら `settings.local.json`

提示の形式: `Phase 5` の下に `- Bash(foo *)（N 回）→ settings.local.json` のように並べる。0 件なら `- 追加の候補なし` と書く。

## 適用

選ばれたものだけを、該当するファイルの `permissions.allow` に追記する（既存の項目は消さない・並べ替えない）。`settings.json` に書いたら `chezmoi re-add ~/.claude/settings.json` で反映する。re-add の前に `chezmoi diff` を読み、auto mode が書いた業務プロファイル（内部ホスト名など）が混ざっていないか確かめる（memory `reference_automode-writes-work-profile`）。

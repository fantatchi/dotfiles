---
name: harness-audit
description: 共有 `.claude/context.md` の `## 判断メモ` を仕分け（昇格・統合・退避・残置）し、確認なしで自動適用する。context-save の判断メモ肥大アラートが出たとき、または「判断メモを圧縮して」「harness-audit を実行して」と明示されたときに使う。Claude 版の週次点検のうち、harness に依存しない判断メモ圧縮だけを持つ。
---

# Harness Audit（Codex 版）: 判断メモ圧縮

Claude 版 `~/.claude/skills/harness-audit/` は週次点検（CLAUDE.md 監査・memory の陳腐化・スキルの利用実績・判断メモ圧縮）を持つ。このうち Codex 版が持つのは **判断メモ圧縮だけ**。ほかの 3 つは Claude のプラグイン（claude-md-improver）・Claude の memory ディレクトリ・Claude の transcript に依存するため移していない。

## 手順

1. resolver `~/.claude/skills/shared/integrations.md` の `memory_promotion` を見る。`on` でなければ「判断メモ圧縮 → スキップ（memory_promotion off）」と報告して終了する
2. `references/memo-compaction.md` の手順に従って仕分けし、**確認を取らずに適用する**（理由と安全策は同ファイル冒頭）
3. 結果を 1 行で報告する: `昇格 N（ファイル名）/ 統合 M / 退避 K / 残置 L → 退避先: <ログのパス>`

`.claude/context.md` は Claude と共有する正本なので、書き込みは `~/.claude/skills/shared/multi-writer.md` の手順（書く直前に読み直す・競合したら止める・最小の部分置換・書いた後の確認）に従う。

---
name: harness-audit
description: '週次点検。CLAUDE.md 監査・memory の陳腐化・スキルの利用実績・判断メモ圧縮（自動適用）を 1 回で回す。`/harness-audit memo` で判断メモ圧縮だけを単独実行。手動 `/harness-audit` 専用（自動起動しない。週次の通知は claude-md-audit-reminder hook が出す）。'
disable-model-invocation: true
argument-hint: "[memo]"
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Skill
---

# Harness Audit: 週次点検

周期で回す点検をまとめたもの。セッション単位の振り返り（CLAUDE.md への知見の追記・スキルの洗練）は `/session-review` が担当する。

## 起動と実行範囲

| 起動 | 実行するフェーズ | `last_audit` 更新 |
|---|---|---|
| `/harness-audit` | 1〜4 すべて | する（最後に） |
| `/harness-audit memo` | 4 だけ | しない |

引数が `memo` 以外なら、全フェーズで実行してよいか一言確認する。

## 実行順

1. **Phase 4 を先に実行して自動適用し、結果を報告する**（確認は取らない。理由と安全策は `references/memo-compaction.md`）
2. `memo` 指定ならここで終了
3. Phase 1〜3 の提案を集め、**1 回にまとめて提示**して、適用する項目を選んでもらう（全部 / 一部 / スキップ）
4. 選ばれた項目を適用し、`last_audit` を更新する

## フェーズ

### Phase 1: CLAUDE.md 監査

`/claude-md-management:claude-md-improver` に委譲する。対象は 2 つ:

- グローバル: chezmoi source の `~/.local/share/chezmoi/dot_claude/CLAUDE.md`（live の `~/.claude/CLAUDE.md` は編集しない）。適用後は `chezmoi apply ~/.claude/CLAUDE.md` で live に反映する
- 今いるプロジェクトの `./CLAUDE.md`（あれば）

監査の基準は memory `feedback_claude-md-audit-cant-know`（モデルが知り得ないことだけ残す）。

### Phase 2: memory の陳腐化

手順は `references/memory-staleness.md`。提案のみで、適用は手順 3 の選択に従う。

### Phase 3: スキルの利用実績

手順は `references/skill-usage.md`。`node ~/.claude/scripts/skill-usage.js` の出力から撤去候補を出す。提案のみ。

### Phase 4: 判断メモ圧縮（自動適用）

手順は `references/memo-compaction.md`。resolver `~/.claude/skills/shared/integrations.md` の `memory_promotion` が `on` でなければ skip し、「Phase 4 → スキップ（memory_promotion off）」と明示する。

## 一括提示の形式

```
Harness Audit

Phase 4: 判断メモ圧縮（適用済み）
  昇格 1（feedback_xxx.md）/ 統合 1 / 退避 2 / 残置 5 → 退避先: 20_log/202611/....md

Phase 1: CLAUDE.md 監査
  - （claude-md-improver の提案）

Phase 2: memory の陳腐化
  - reference_xxx.md: 本文の `scripts/foo.sh` が存在しない → 削除 or 更新

Phase 3: スキルの利用実績（観測 N 日・M 台分）
  - image-prompt: 0 回 → 撤去候補（参考）

適用する項目を選んでください（全部 / 一部 / スキップ）
```

## last_audit の更新（全フェーズ実行時のみ）

適用が終わったら（全部スキップでも点検自体は済んだので更新する）、`~/ObsidianVault/00_meta/claude-state.md` の frontmatter を Edit で更新する:

- `last_audit:` を `date +%s` の出力に
- `last_audit_at:` を `date -Iseconds` の出力に

Windows（PowerShell）では `[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()` と `Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'` を使う。Vault が無ければ `date +%s > ~/.claude/state/claude-md-audit/last-audit.txt`（そのマシンでだけ有効）。これで claude-md-audit-reminder hook の週次通知が止まる。

## 編集後の反映（MUST）

`~/.claude/` 配下（CLAUDE.md・skills・docs・scripts）を編集したら `chezmoi re-add <path>`（新規ファイルは `chezmoi add`）で source に反映し、`chezmoi diff` で残りが無いことを確かめる。memory ディレクトリ（`~/.claude/projects/*/memory/`）は chezmoi の管理外なので反映は不要。

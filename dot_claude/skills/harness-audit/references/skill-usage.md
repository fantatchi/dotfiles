# Phase 3: スキルの利用実績

`node ~/.claude/scripts/skill-usage.js` を実行し、その出力から撤去候補と見直し候補を出す。提案のみ。

## スクリプトがすること

- `~/.claude/projects/**/*.jsonl`（transcript）から、`Skill` ツールの呼び出し（自動起動とモデルからの起動）と `<command-name>/x</command-name>`（手動起動）を拾う
- transcript は Claude Code の自動削除で約 30 日分しか残らない。そのため、集計結果を台帳 `~/ObsidianVault/00_meta/skill-usage.json` に統合して残す。キーはスキル名とセッション ID で、同じセッションを 2 回数えないので、何度実行しても数は増えない。Vault が同期されていれば、各 PC の分もこの台帳にまとまる（Vault が無ければ `~/.claude/state/skill-usage.json`）
- 対象は `~/.claude/skills/*/SKILL.md` を持つスキル。`shared`・`synced`・`*-workspace`・Mod（`.claude-plugin/` を持つもの）は除く
- 出力: スキルごとのセッション数と最終使用日、台帳の観測開始日、記録した PC の数

## 判断の目安

- **撤去候補**: 観測期間中に 0 回のもの。ただし**観測期間が 90 日未満なら「参考」と明記**し、撤去は勧めない（台帳の観測開始は 2026-11-11）
- **手動専用化の候補**: 自動発動できる（`disable-model-invocation` が無い）のに、手動起動しかされていないもの。description が毎セッション注入されるぶん、手動専用にすれば軽くなる
- 撤去を提案するときは、ks-name の撤去（2026-09-02）と同じく、他のスキル・CLAUDE.md・Codex ミラー（`~/.agents/skills/`）からの参照が無いことも grep で確かめる
- **ルーティンや他スキルの中から使われるスキル**（`obsidian-mail` はルーティン経由、`obsidian-log` / `context-save` は `session-save` の中から）は、transcript に残らなかったり、親スキルの中で Read されるだけで `Skill` 呼び出しにならなかったりする。0 回でも撤去候補にせず、起動経路を 1 行添える
- **用途が季節的なスキル**（例: 案件の実装期だけ使うもの）は、0 回でも撤去せず、再検討トリガーを context.md の判断メモに残す案を出す

## 撤去・手動専用化を適用するとき

`~/.claude/docs/skill-management.md` の「既存スキル削除時」のチェックリスト（CLAUDE.md の「# スキルコマンド」、chezmoi の README のスキル一覧、chezmoi source 側の削除）に従う。

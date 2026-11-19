# Phase 3: スキルの利用実績

`node ~/.claude/scripts/skill-usage.js` を実行し、その出力から撤去候補と見直し候補を出す。提案のみ。

## スクリプトがすること

- `~/.claude/projects/**/*.jsonl`（transcript）から、`Skill` ツールの呼び出し（自動起動とモデルからの起動）と `<command-name>/x</command-name>`（手動起動）を拾う
- transcript は Claude Code の自動削除で約 30 日分しか残らない。そのため、集計結果を台帳 `~/ObsidianVault/00_meta/skill-usage.json` に統合して残す。キーはスキル名とセッション ID で、同じセッションを 2 回数えないので、何度実行しても数は増えない。Vault が同期されていれば、各 PC の分もこの台帳にまとまる（Vault が無ければ `~/.claude/state/skill-usage.json`）
- 対象は `~/.claude/skills/*/SKILL.md` を持つスキル。`shared`・`synced`・`*-workspace`・Mod（`.claude-plugin/` を持つもの）は除く
- 出力: スキルごとのセッション数と最終使用日、台帳の観測開始日、記録した PC の数

## 判断の目安

- **撤去候補**: 観測期間中に 0 回のもの。ただし**観測期間が 90 日未満なら「参考」と明記**し、撤去は勧めない（台帳の観測開始は 2026-10-13。スクリプト出力の「観測: ... から N 日」が正）
- **手動専用化の候補**: 自動発動できる（`disable-model-invocation` が無い）のに、手動起動しかされていないもの。description が毎セッション注入されるぶん、手動専用にすれば軽くなる
- 撤去を提案するときは、ks-name の撤去（2026-09-02）と同じく、他のスキル・CLAUDE.md・Codex ミラー（`~/.agents/skills/`）からの参照が無いことも grep で確かめる。Codex ミラーに同名スキルがあれば、それも一緒に撤去する（正本は Claude 側。利用実績は Claude 側だけで測る）
- **ルーティンや他スキルの中から使われるスキル**（`obsidian-mail` はルーティン経由、`obsidian-log` / `context-save` は `session-save` の中から）は、transcript に残らなかったり、親スキルの中で Read されるだけで `Skill` 呼び出しにならなかったりする。0 回でも撤去候補にせず、起動経路を 1 行添える
- **用途が季節的なスキル**（例: 案件の実装期だけ使うもの）は、0 回でも撤去せず、再検討トリガーを context.md の判断メモに残す案を出す

## 消し残しと Codex ミラーのずれ

chezmoi は source から消しただけでは live を消さない。2026-11-19 に、07-07 に削除した `documentation-writer` / `frontend-patterns` が live に残り、description が毎セッション注入されていた。次の 2 つを確かめ、見つかったものを提案に出す（削除は選択後。live の消去は `.chezmoiremove` に登録して `chezmoi apply`）。

1. **live にだけ残っているスキル**: `~/.claude/skills/*` と `~/.agents/skills/*` のうち `chezmoi managed` に出てこないもの
   ```bash
   for d in ~/.claude/skills/*/ ~/.agents/skills/*/; do r=${d#$HOME/}; r=${r%/}; chezmoi managed | grep -qx "$r" || echo "$r"; done
   ```
   除外（意図して chezmoi の外に置いている）: `install-moomoo-opend` / `moomooapi`（moomoo のインストーラーが置く外部スキル）、`synced`（同期データの置き場）
2. **Codex 側にしかないスキル**: Codex 専用スキルは置かない方針（`~/.claude/docs/skill-management.md`）なので、出てきたら Claude 側で削除した写しの消し残し
   ```bash
   comm -13 <(ls ~/.claude/skills | sort) <(ls ~/.agents/skills | sort)
   ```

提示の形式: `Phase 3` の下に `- 消し残し: <パス> → 削除` のように並べる。

## 撤去・手動専用化を適用するとき

`~/.claude/docs/skill-management.md` の「既存スキル削除時」のチェックリスト（CLAUDE.md の「# スキルコマンド」、chezmoi の README のスキル一覧、chezmoi source 側の削除）に従う。

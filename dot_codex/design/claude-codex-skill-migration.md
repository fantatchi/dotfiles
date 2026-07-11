# Claude・Codex Skill 共有設計

## 対象

Codex へ移行する Skill は `context-load`、`context-save`、`session-save`、`obsidian-log`、`obsidian-resource`、`session-review`、`spec-writer` の 7 個とする。`obsidian-daily` と `obsidian-mail` は Claude 専用で維持する。

## 状態共有

`.claude/context.md`、`.claude/progress.md`、Obsidian の `00_meta/tasks.md` を Claude・Codex 共通の正本とする。Codex は `~/.claude/skills/shared/multi-writer.md` と `tasks-format.md` に従い、再読込、競合停止、最小編集、書込み後検証を行う。

## Obsidian 連携

Codex の作業ログは Claude と同じ `20_log/YYYYMM/`、リソースは `30_resource/YYYYMM/` に保存する。ログ frontmatter は `source: codex-log`、`generation: 0` とする。Claude の `obsidian-daily` は日付ファイルを列挙して集約し、source では絞らないため Codex ログも対象になる。

## chezmoi と Windows

ユーザー管理対象は `dot_codex/AGENTS.md`、`skills/`、`scripts/`、`design/` とする。認証、config、セッション、Plugin、cache、ログ、SQLite は管理しない。Windows の `.codex` は実ディレクトリを維持し、`AGENTS.md` と `skills` だけを WSL 側へ SymbolicLink で共有する。

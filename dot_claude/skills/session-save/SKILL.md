---
name: session-save
description: セッションの作業ログ記録とコンテキスト保存をまとめて実行する。「作業を保存して」「セッション終わり」「まとめて保存」といった依頼で使う。
argument-hint: [project-id]
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Bash(git *), Bash(echo *), Bash(mkdir *), Bash(basename *), Bash(date *), Bash(ls *)
---

# セッション保存

作業ログの記録（obsidian-log）とコンテキスト保存（context-save）をまとめて実行する。

## 実行順序

### ステップ 1: 作業ログの記録

`../obsidian-log/SKILL.md` の手順に従って作業ログを記録する。

- 書き出し先: `{obsidian_vault}/_claude/log/`
- フォーマット: `../obsidian-log/template.md` に従う
- タグ: `claude-log` + 自動生成タグ
- 引数が渡された場合でも、ログのタグには使わない（引数は context-save の project-id として扱う）

### ステップ 2: コンテキスト保存

`../context-save/SKILL.md` の手順に従ってコンテキストを保存する。

- 引数（`$ARGUMENTS`）があればプロジェクト識別子として使う
- 引数がなければ context-save の「引数なし」フローに従う
- 書き出し先: `$HOME/.claude/context/{project-id}.md`
- フォーマット: `../context-save/template.md` に従う

### ステップ 3: 完了報告

両方の結果をまとめて報告する：

```
セッションを保存しました:
- 作業ログ: {ログファイル名}
- コンテキスト: {project-id}
```

## 注意事項

- ステップ 1 が失敗しても（obsidian_vault 未設定など）、ステップ 2 は実行する
- 各ステップの詳細な仕様は個別のスキル定義を参照すること

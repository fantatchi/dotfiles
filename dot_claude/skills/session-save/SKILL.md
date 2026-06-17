---
name: session-save
description: セッションの作業ログ記録とコンテキスト保存をまとめて実行し、アウトプット候補の提案も行う。「作業を保存して」「セッション終わり」「まとめて保存」といった依頼で使う。
allowed-tools: Read, Skill, Write, Edit, Glob, Bash(git:*), Bash(echo:*), Bash(mkdir:*), Bash(basename:*), Bash(date:*), Bash(pwd), Bash(chezmoi source-path)
---

# セッション保存

作業ログの記録（obsidian-log）とコンテキスト保存（context-save）をまとめて実行する **orchestrator**。

**設計（orchestrator）**: 各処理の手順は持たず、`Skill` ツールでサブスキルを順に起動するだけ。書き出し先・フォーマット・ローテーション等の詳細はサブスキル側 SKILL.md が唯一の正本で、本ファイルでは再記述しない（齟齬防止）。**degradation（連携先が無いときの skip / フォールバック）は各サブスキルが内部で持つため、orchestrator は基本無条件で起動する**。例外は「起動自体が無意味になるキー」を持つサブスキルだけで、その場合のみ resolver を先読みして skip する（ここでは obsidian-log に対する `vault`）。

> `allowed-tools` はこの orchestrator 自身が使う `Read` / `Skill` に加え、**サブスキル（obsidian-log / context-save）が要求するツールの和集合**を明示している。Claude Code の `allowed-tools` は「リスト内をプロンプトなしで許可」する宣言であって**リスト外を禁止しない**（リスト外ツールは通常の permission 設定に従う）ため、宣言漏れがあってもサブスキルが**無言で保存失敗することはなく**、最悪でも権限プロンプトが出るだけ。和集合を宣言しておくのは、その**プロンプトを抑制してサブの書き込みを滑らかに通すための保険**である。`Skill` 経由起動はメイン会話への SKILL.md 注入で別権限スコープを作らない（公式ドキュメント確認済み）が、入れ子時に親の `allowed-tools` へ絞られるかはドキュメント非明示のため、保険として和集合宣言を維持する。

## 実行順序

### ステップ 1: 作業ログの記録（obsidian-log）

obsidian-log は Vault を主資源とする「Vault 連携専用」スキルで、Vault が無いと起動しても案内終了するだけなので、ここだけ先読み skip 判定をする:

1. resolver `~/.claude/skills/shared/integrations.md` を Read し `vault` を確認する（path 系キー：`vault` が空・未設定、または指すパスが不在 → 無効）
2. `vault` が有効 → `Skill` ツールで **obsidian-log** を起動する（引数はユーザー指定のタグがあれば渡す）
3. `vault` が無効 → このステップを skip し、完了報告で「作業ログ: skip（Vault 未設定/未配置）」と明示する

### ステップ 2: コンテキスト保存（context-save）

`Skill` ツールで **context-save** を起動する（無条件。context-save 自身がコア＝`.claude/context.md` 保存で完結し、tasks.md 吸い上げ・progress.md 更新・MEMORY 昇格提案などの連携は内部で resolver を見て自己 degradation する）。session-save から起動しても context-save のコア＋有効な連携がすべて実行される。詳細は context-save SKILL.md 側が正本（本ファイルでは再記述しない）。

### ステップ 3: アウトプット提案

セッション全体を振り返り、アウトプットできそうなトピックがないか確認する。

#### 提案の判断基準

以下のいずれかに該当する技術的内容があれば、候補として挙げる：

- 技術の比較・検証、ツールの使い方、トラブルシューティング、設計判断
- 公式ドキュメントの要約、API 仕様の調査、設定方法のまとめ
- 他のエンジニアや将来の自分が参照して役立ちそうな知見

以下の場合は提案しない：

- 単純なバグ修正・設定変更のみ
- 既にアウトプットを作成済み
- 雑談のみで技術的な内容がない

#### 提案の出し方

該当するトピックがあれば、完了報告の後に以下の形式で提案する：

```
アウトプットできそうなトピックがあります:
- {トピックの概要}（理由: {なぜ残す価値があるか}）
- {トピックの概要}（理由: ...）

作成する場合は `/obsidian-resource` を実行してください（引数 `auto` でセッション内容から自動ドラフト化）。
```

該当なしの場合は何も出力しない（提案がないことを報告する必要はない）。

### ステップ 4: 完了報告

各サブスキルの結果をまとめ、skip があれば内訳も明示して報告する：

```
セッションを保存しました:
- 作業ログ: {ログファイル名}        ← skip した場合は「skip（Vault 未設定/未配置）」
- コンテキスト: .claude/context.md
```

※ ステップ 3 の提案がある場合は、完了報告の後に続けて出力する。

## 注意事項

- **orchestrator はサブスキルを順に起動するだけ**。ステップ 1（obsidian-log）が skip / 失敗しても、ステップ 2（context-save）以降は実行する
- 各ステップの詳細な仕様・degradation は個別のサブスキル定義（`obsidian-log` / `context-save`）が正本。本ファイルでは再記述しない
- 同セッションの作業ログが既に存在する場合に新規作成せず上書き更新するかどうかは obsidian-log 側の責務（本 orchestrator は関与しない）

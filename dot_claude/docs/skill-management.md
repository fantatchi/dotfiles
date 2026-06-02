# スキル管理（追加・削除・拡張）

`~/.claude/CLAUDE.md` から外出ししたスキル運用の詳細。スキルの追加・削除・拡張時にだけ必要な情報のため、毎セッションで読み込まれる CLAUDE.md からは外している。

## 新スキル追加・削除時のチェックリスト

スキルを追加・削除した時は **同一コミットで** 以下を揃える（過去 `obsidian-summary` 追加時にここを抜かして `~/.claude/CLAUDE.md` / dotfiles README への反映が漏れ、後続セッションでスキルが認識されず誤作動を起こした。`consistency-check` 削除時も README から消し忘れた）。

### 新スキル追加時

- [ ] `~/.claude/skills/<skill-name>/SKILL.md` を作成（frontmatter: `name` / `description` / `argument-hint` / `disable-model-invocation` / `allowed-tools` を適切に設定）
- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」セクションに 1 行追加（コマンド — 簡潔な説明）
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルに 1 行追加
- [ ] README の「使いどころ」テーブルにも必要なら追加（`/obsidian-*` 等の関連グループに属する場合）

### 既存スキル削除時

- [ ] `~/.claude/skills/<skill-name>/` ディレクトリを削除
- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」セクションから該当行を削除
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルから該当行を削除
- [ ] README の「使いどころ」テーブルや他セクションの言及箇所を削除

### 既存スキル機能拡張時（追加・削除ではない、機能のスコープが広がる場合）

過去 `spec-design` に「ベースカラー Blue デフォルト / 伝わるデザイン原則 / 階調マッピング」を追加した時、`/spec-design` の説明文が古いままで「カラーパレット選定」「伝わるデザイン」のトリガー語が抜け、ユーザーから「機能が拡張されていることがリストから見えない」指摘を受けた。以下を確認する:

- [ ] `~/.claude/CLAUDE.md` の「# スキルコマンド」の該当行の説明文に新機能の概要が反映されているか
- [ ] `~/.local/share/chezmoi/README.md` の「**スキル一覧:**」テーブルの該当行も同様に反映されているか
- [ ] SKILL.md の `description` に新機能のトリガー語（「○○について」で呼び出されるべき語）を追加したか
- [ ] references を新規追加した場合、SKILL.md 本文から **明示的に参照誘導**（「詳細は references/X.md 参照」）が書かれているか（参照誘導なしだと LLM が references を読まずに進む過去事例あり）

### コミット粒度

スキル本体の変更とドキュメント反映は **1 コミット 1 意図** で揃える（コミット `75b64c2` `multi-persona-review` 追加時の慣例）。

## スキル共通リソース

`~/.claude/skills/shared/` は **ライブラリディレクトリ** であり、`name:` 付きの独立したスキルではない。複数スキル間で重複する仕様・手順を集約するためのもので、各スキルの SKILL.md から `Read` で参照する。モデルの自動起動対象にはならない。

## スキル設計の判断軸（責務分担・入口・単一出典）

複数スキルが共通ドメインを扱う時の構造判断。2026-05-13〜14 の視覚設計スキル群（spec-design / dashboard-design）整理で確立し、context.md の判断メモから昇格した。

- **入口（トリガー語）の集約 vs 中身の参照誘導を分ける**: 複数スキルが共通ドメインを扱う場合、トリガー語は 1 つのスキルに集約しつつ、機能本体は references で相互参照させると、トリガー精度を保ったまま機能カバレッジを失わない（例: 視覚設計の入口は dashboard-design に集約し、spec-design は references から配色データを引く）
- **複合スキルと単体スキルの棲み分けは単体側 description に明記する**: 複合 ⊃ 単体 の内包関係（例: session-save ⊃ context-save）は、単体側の description で「複合スキルが内包する旨」を書かないと、複合側を使うメリットが利用者から見えなくなる
- **配色は dashboard-design / 配色以外の判断軸は spec-design に置いて二重化しない**: カラーパレット HEX の正本は dashboard-design（`visual-encoding.md`）、伝わるデザイン原則・図種選択などの判断軸は spec-design 側に置き、互いに内製で重複させない。共通部分は `shared/` に単一出典化する
- **共通リソースの「真の単一出典化」は責務軸で切る**: 「何の単一出典か」を軸にすると、マッピングルール（判断軸）/ パレット HEX（データ）/ 原則集（判断軸）と責務がきれいに分かれ、どれをどこへ置くか迷わない

## スキルの種類と frontmatter 方針

- **操作型スキル**（obsidian-*, gtd-*, session-*, context-* など）: 特定のコマンドやファイル操作を行うため、`allowed-tools` で使用ツールを具体的に列挙する
- **ロール変換型スキル**: エージェントを特定の専門家役に変身させ、その後の作業全般を導くため、`allowed-tools` を**指定しない**（指定するとトリガー後の実作業で権限不足になる）

## MEMORY.md（auto memory）への昇格運用

`~/.claude/projects/<project>/memory/` 配下の **auto memory** システムは、ユーザー指示や Claude の自律判断で `feedback_*.md` / `user_*.md` / `project_*.md` / `reference_*.md` を保存し、`MEMORY.md` 索引から全セッションで参照される仕組み。

context.md の判断メモが時間経過で肥大化するため、再利用性の高い知見は MEMORY.md に昇格させる運用ガイドを設ける（context-save SKILL.md からも参照する）。

### 昇格判断の基準

context.md の `## 判断メモ` に書いた項目のうち、以下のいずれかに該当するものは MEMORY.md への昇格を検討する：

- **プロジェクト横断で再利用される**: 1 プロジェクトで得た知見が他プロジェクトでも有効（コミット粒度ルール、ツール固有の罠、ライブラリ選定基準、CLI フラグの落とし穴 etc.）
- **2 回以上参照されている**: 同じ判断を別セッションで再度引用したことがある（再現性のあるパターン）
- **環境前提が普遍的**: WSL ↔ Windows、Bash の罠、PowerShell の挙動など特定環境に依存しない知見
- **ユーザー嗜好・運用ルール**: コミット/push の粒度ルール、Agent Teams を使う条件、レビュー粒度の好み等

逆に **昇格しない（context.md に留める）** もの：

- **特定プロジェクトのアーキテクチャ判断**: そのプロジェクト固有の設計理由（kabuto の Phase 6 戦略、cloud-dsc の認証フロー等）
- **一過性のバグ修正経緯**: 特定 commit 由来の問題で再発しないもの
- **作業の時系列ログ**: 「2026-MM-DD に X した」は context.md の進行中の作業セクション側

### 昇格の手順

1. context.md `## 判断メモ` で再利用候補を抽出
2. memory 種別を判定（feedback / user / project / reference）
3. `~/.claude/projects/<project>/memory/<type>_<slug>.md` を frontmatter 付き（`name` / `description` / `metadata.type`）で書く。本文は **Why** と **How to apply** を明示
4. `~/.claude/projects/<project>/memory/MEMORY.md` 索引に 1 行追加（150 文字以内）
5. context.md 側の元エントリは削除（移行完了）、または「→ MEMORY.md `<name>` 参照」と短縮

### 注意

- MEMORY.md は **`~/.claude/CLAUDE.md`** から auto memory システム指示で読み込まれる（claude code 起動時自動）。グローバル CLAUDE.md の指示と矛盾する内容は書かない
- 「保存しない」とユーザーが言うものは保存しない（明示拒否を優先）
- 機密・認証情報は絶対に書かない（CLAUDE.md「# 禁止パターン」準拠）
